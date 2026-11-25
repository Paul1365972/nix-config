use std::ops::Add;

use serde::{Deserialize, de::IgnoredAny};

use crate::{
    api::Api,
    usage::{CacheLifetime, Usage},
};

pub const CHAT_COMPLETIONS_STREAM_END: &[u8] = b"[DONE]";
const OPENAI_WEB_SEARCH: &str = "web_search_call";

pub struct UsageReport {
    pub usage: Usage,
    pub is_last: bool,
}

impl UsageReport {
    pub fn read(api: Api, response_or_stream_event: &[u8]) -> Option<Self> {
        let json = response_or_stream_event;
        match api {
            Api::ChatCompletions => {
                let document = serde_json::from_slice::<ChatDocument>(json).ok()?;
                let is_closing_chunk_of_openai =
                    document.choices.is_some_and(|choices| choices.is_empty());
                Some(Self {
                    usage: document.usage?.into(),
                    is_last: is_closing_chunk_of_openai,
                })
            }
            Api::Messages => {
                let document = serde_json::from_slice::<MessagesDocument>(json).ok()?;
                let usage_of_opening_event = document.message.and_then(|message| message.usage);
                let usage_of_closing_event_or_whole_response = document.usage;
                let is_last = usage_of_closing_event_or_whole_response.is_some();
                Some(Self {
                    usage: usage_of_closing_event_or_whole_response
                        .or(usage_of_opening_event)?
                        .into(),
                    is_last,
                })
            }
            Api::Responses => {
                let mut document = serde_json::from_slice::<ResponsesDocument>(json).ok()?;
                let whole_response = match document.response.take() {
                    Some(response_of_closing_event) => *response_of_closing_event,
                    None => document,
                };
                let output = whole_response.output.unwrap_or_default();
                let web_searches = output
                    .iter()
                    .filter(|item| item.kind.as_deref() == Some(OPENAI_WEB_SEARCH));
                Some(Self {
                    usage: Usage {
                        web_searches: web_searches.count() as u64,
                        ..whole_response.usage?.into()
                    },
                    is_last: true,
                })
            }
        }
    }
}

#[derive(Deserialize)]
struct MessagesDocument {
    usage: Option<MessagesUsage>,
    message: Option<MessagesMessage>,
}

#[derive(Deserialize)]
struct MessagesMessage {
    usage: Option<MessagesUsage>,
}

#[derive(Deserialize)]
struct MessagesUsage {
    input_tokens: Option<u64>,
    cache_read_input_tokens: Option<u64>,
    cache_creation_input_tokens: Option<u64>,
    cache_creation: Option<MessagesCacheCreation>,
    output_tokens: Option<u64>,
    server_tool_use: Option<MessagesServerToolUse>,
    #[serde(rename = "iterations")]
    billed_attempts_and_compactions: Option<Vec<MessagesUsage>>,
}

#[derive(Deserialize, Default)]
struct MessagesCacheCreation {
    ephemeral_5m_input_tokens: Option<u64>,
    ephemeral_1h_input_tokens: Option<u64>,
}

#[derive(Deserialize, Default)]
struct MessagesServerToolUse {
    web_search_requests: Option<u64>,
}

impl From<MessagesUsage> for Usage {
    fn from(usage: MessagesUsage) -> Self {
        let written = usage.cache_creation.unwrap_or_default();
        let one_hour = written.ephemeral_1h_input_tokens.unwrap_or(0);
        let all_lifetimes = usage.cache_creation_input_tokens.unwrap_or(0);
        let five_minutes = written
            .ephemeral_5m_input_tokens
            .unwrap_or(0)
            .max(all_lifetimes.saturating_sub(one_hour));
        let server_tool_use = usage.server_tool_use.unwrap_or_default();
        let usage_of_returned_message = Self {
            uncached_input_tokens: usage.input_tokens.unwrap_or(0),
            cache_read_tokens: usage.cache_read_input_tokens.unwrap_or(0),
            cache_write_tokens: [
                (CacheLifetime::FiveMinutes, five_minutes),
                (CacheLifetime::OneHour, one_hour),
            ]
            .into_iter()
            .collect(),
            output_tokens: usage.output_tokens.unwrap_or(0),
            web_searches: server_tool_use.web_search_requests.unwrap_or(0),
        };
        let billed = usage.billed_attempts_and_compactions.unwrap_or_default();
        let billed_tokens = billed.into_iter().map(Self::from).reduce(Add::add);
        Self {
            web_searches: usage_of_returned_message.web_searches,
            ..billed_tokens.unwrap_or(usage_of_returned_message)
        }
    }
}

#[derive(Deserialize)]
struct ResponsesDocument {
    usage: Option<ResponsesUsage>,
    output: Option<Vec<ResponsesOutputItem>>,
    response: Option<Box<ResponsesDocument>>,
}

#[derive(Deserialize)]
struct ResponsesOutputItem {
    #[serde(rename = "type")]
    kind: Option<String>,
}

#[derive(Deserialize)]
struct ResponsesUsage {
    input_tokens: u64,
    output_tokens: u64,
    input_tokens_details: Option<OpenAiCacheDetails>,
}

impl From<ResponsesUsage> for Usage {
    fn from(usage: ResponsesUsage) -> Self {
        let cache = usage.input_tokens_details.unwrap_or_default();
        cache.usage(usage.input_tokens, usage.output_tokens)
    }
}

#[derive(Deserialize)]
struct ChatDocument {
    usage: Option<ChatUsage>,
    choices: Option<Vec<IgnoredAny>>,
}

#[derive(Deserialize)]
struct ChatUsage {
    prompt_tokens: u64,
    completion_tokens: Option<u64>,
    total_tokens: Option<u64>,
    prompt_tokens_details: Option<OpenAiCacheDetails>,
}

impl From<ChatUsage> for Usage {
    fn from(usage: ChatUsage) -> Self {
        // Gemini counts its thinking only in the total, and bills it as output.
        let total_tokens = usage.total_tokens.unwrap_or(0);
        let output_tokens_by_total = total_tokens.saturating_sub(usage.prompt_tokens);
        let output_tokens = usage
            .completion_tokens
            .unwrap_or(0)
            .max(output_tokens_by_total);
        let cache = usage.prompt_tokens_details.unwrap_or_default();
        cache.usage(usage.prompt_tokens, output_tokens)
    }
}

#[derive(Deserialize, Default)]
struct OpenAiCacheDetails {
    cached_tokens: Option<u64>,
    cache_write_tokens: Option<u64>,
    cache_write_tokens_details: Option<OpenAiCacheWriteDetails>,
}

#[derive(Deserialize, Default)]
struct OpenAiCacheWriteDetails {
    ttl_12h_tokens: Option<u64>,
}

impl OpenAiCacheDetails {
    fn usage(self, input_tokens: u64, output_tokens: u64) -> Usage {
        let cache_read_tokens = self.cached_tokens.unwrap_or(0);
        let written = self.cache_write_tokens_details.unwrap_or_default();
        let twelve_hours = written.ttl_12h_tokens.unwrap_or(0);
        let all_lifetimes = self.cache_write_tokens.unwrap_or(0);
        let thirty_minutes = all_lifetimes.saturating_sub(twelve_hours);
        let cached_input_tokens = cache_read_tokens + thirty_minutes + twelve_hours;
        Usage {
            uncached_input_tokens: input_tokens.saturating_sub(cached_input_tokens),
            cache_read_tokens,
            cache_write_tokens: [
                (CacheLifetime::ThirtyMinutes, thirty_minutes),
                (CacheLifetime::TwelveHours, twelve_hours),
            ]
            .into_iter()
            .collect(),
            output_tokens,
            web_searches: 0,
        }
    }
}
