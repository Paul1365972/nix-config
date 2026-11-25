use axum::http::{HeaderName, HeaderValue, header::AUTHORIZATION};
use serde::{Deserialize, Serialize};

use crate::gateway::Provider;

pub const X_API_KEY: HeaderName = HeaderName::from_static("x-api-key");
pub const ANTHROPIC_BETA: HeaderName = HeaderName::from_static("anthropic-beta");
static MESSAGES_HEADERS: [HeaderName; 2] =
    [HeaderName::from_static("anthropic-version"), ANTHROPIC_BETA];

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Deserialize, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum Api {
    ChatCompletions,
    Messages,
    Responses,
}

pub struct Fields {
    pub passed_as_given: &'static [&'static str],
    pub passed_only_as: &'static [FixedField],
    pub passed_only_stated_as: &'static [FixedField],
    pub conversation: &'static str,
}

pub struct FixedField {
    pub name: &'static str,
    pub json: &'static str,
}

const CHAT_COMPLETIONS_FIELDS: Fields = Fields {
    passed_as_given: &[
        "model",
        "messages",
        "stream",
        "stream_options",
        "tools",
        "tool_choice",
        "parallel_tool_calls",
        "max_tokens",
        "max_completion_tokens",
        "reasoning_effort",
        "verbosity",
        "response_format",
        "temperature",
        "top_p",
        "frequency_penalty",
        "presence_penalty",
        "logit_bias",
        "logprobs",
        "top_logprobs",
        "seed",
        "stop",
        "n",
        "user",
        "safety_identifier",
        "metadata",
        "prompt_cache_key",
        "prompt_cache_retention",
        "prompt_cache_options",
    ],
    passed_only_as: &[DEFAULT_TIER, NOTHING_STORED],
    passed_only_stated_as: &[],
    conversation: "messages",
};

const MESSAGES_FIELDS: Fields = Fields {
    passed_as_given: &[
        "model",
        "messages",
        "system",
        "stream",
        "tools",
        "tool_choice",
        "max_tokens",
        "thinking",
        "output_config",
        "context_management",
        "cache_control",
        "temperature",
        "top_p",
        "top_k",
        "stop_sequences",
        "metadata",
    ],
    passed_only_as: &[
        FixedField {
            name: "service_tier",
            json: "\"standard_only\"",
        },
        FixedField {
            name: "inference_geo",
            json: "\"global\"",
        },
        FixedField {
            name: "speed",
            json: "\"standard\"",
        },
    ],
    passed_only_stated_as: &[],
    conversation: "messages",
};

const RESPONSES_FIELDS: Fields = Fields {
    passed_as_given: &[
        "model",
        "input",
        "instructions",
        "stream",
        "stream_options",
        "tools",
        "tool_choice",
        "parallel_tool_calls",
        "max_tool_calls",
        "max_output_tokens",
        "reasoning",
        "text",
        "include",
        "context_management",
        "truncation",
        "temperature",
        "top_p",
        "top_logprobs",
        "user",
        "safety_identifier",
        "metadata",
        "prompt_cache_key",
        "prompt_cache_retention",
        "prompt_cache_options",
    ],
    passed_only_as: &[
        DEFAULT_TIER,
        FixedField {
            name: "background",
            json: "false",
        },
    ],
    passed_only_stated_as: &[NOTHING_STORED],
    conversation: "input",
};

const DEFAULT_TIER: FixedField = FixedField {
    name: "service_tier",
    json: "\"default\"",
};
const NOTHING_STORED: FixedField = FixedField {
    name: "store",
    json: "false",
};

const MESSAGES_BETAS: [&str; 5] = [
    "interleaved-thinking-2025-05-14",
    "thinking-binding-controls-2026-08-01",
    "compact-2026-01-12",
    "mid-conversation-output-config-2026-07-01",
    "inline-tools-2026-09-15",
];
const MESSAGES_WEB_SEARCH_TOOL_KINDS: &str = "web_search_";

impl Api {
    pub fn path(self) -> &'static str {
        match self {
            Self::ChatCompletions => "/chat/completions",
            Self::Messages => "/messages",
            Self::Responses => "/responses",
        }
    }

    pub fn credentials(self, provider: &Provider) -> (HeaderName, HeaderValue) {
        match self {
            Self::Messages => (X_API_KEY, provider.api_key.clone()),
            Self::ChatCompletions | Self::Responses => (AUTHORIZATION, provider.bearer.clone()),
        }
    }

    pub fn fields(self) -> &'static Fields {
        match self {
            Self::ChatCompletions => &CHAT_COMPLETIONS_FIELDS,
            Self::Messages => &MESSAGES_FIELDS,
            Self::Responses => &RESPONSES_FIELDS,
        }
    }

    pub fn passes_tool_on(self, kind: Option<&str>) -> bool {
        match (self, kind) {
            (Self::Messages, None | Some("custom")) => true,
            (Self::Messages, Some(kind)) => kind.starts_with(MESSAGES_WEB_SEARCH_TOOL_KINDS),
            (Self::Responses, Some("function" | "custom" | "namespace" | "web_search")) => true,
            (Self::ChatCompletions, Some("function" | "custom")) => true,
            (Self::Responses | Self::ChatCompletions, _) => false,
        }
    }

    pub fn passes_query_on(self, query: &str) -> bool {
        query.is_empty() || (self == Self::Messages && query == "beta=true")
    }

    pub fn headers_passed_on(self) -> &'static [HeaderName] {
        match self {
            Self::Messages => &MESSAGES_HEADERS,
            Self::ChatCompletions | Self::Responses => &[],
        }
    }

    pub fn passes_beta_on(self, beta: &str) -> bool {
        self == Self::Messages && MESSAGES_BETAS.contains(&beta)
    }
}
