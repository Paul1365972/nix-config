use std::borrow::Cow;

use axum::http::{
    HeaderMap, HeaderName, HeaderValue, StatusCode,
    header::{AUTHORIZATION, InvalidHeaderValue},
};
use serde::{Deserialize, Serialize};
use serde_json::{Value, json};

use crate::refusal::Refusal;

pub const X_API_KEY: HeaderName = HeaderName::from_static("x-api-key");
pub const X_GOOG_API_KEY: HeaderName = HeaderName::from_static("x-goog-api-key");
const ANTHROPIC_BETA: HeaderName = HeaderName::from_static("anthropic-beta");
static MESSAGES_HEADERS: [HeaderName; 2] =
    [HeaderName::from_static("anthropic-version"), ANTHROPIC_BETA];

#[derive(Debug, Clone, Copy, PartialEq, Eq, Deserialize, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum Api {
    GenerateContent,
    Messages,
    Responses,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Work {
    Answer,
    CountTokens,
}

#[derive(Clone, Copy)]
pub enum Endpoint<'path> {
    BodyModel {
        api: Api,
        work: Work,
        path: &'static str,
    },
    PathModel {
        model: &'path str,
        method: GenerateContentMethod,
    },
}

impl Endpoint<'_> {
    pub fn api(self) -> Api {
        match self {
            Self::BodyModel { api, .. } => api,
            Self::PathModel { .. } => Api::GenerateContent,
        }
    }

    pub fn work(self) -> Work {
        match self {
            Self::BodyModel { work, .. } => work,
            Self::PathModel { method, .. } => method.work(),
        }
    }

    pub fn path(self) -> Cow<'static, str> {
        match self {
            Self::BodyModel { path, .. } => Cow::Borrowed(path),
            Self::PathModel { model, method, .. } => {
                format!("/models/{model}:{}", method.name()).into()
            }
        }
    }

    pub fn query_to_forward(self, query: Option<&str>) -> Result<&str, Refusal> {
        let text = query.unwrap_or_default();
        match self {
            Self::BodyModel { api, .. }
                if text.is_empty() || (api == Api::Messages && text == "beta=true") =>
            {
                Ok(text)
            }
            Self::BodyModel { .. } => Err(Refusal::invalid_request(
                "query_unsupported",
                format!("The gateway does not pass on the query {text:?}."),
            )),
            Self::PathModel { method, .. } => {
                check_generate_content_query(query, method.query())?;
                Ok(text)
            }
        }
    }
}

pub fn check_generate_content_query(
    query: Option<&str>,
    expected: Option<&str>,
) -> Result<(), Refusal> {
    if query == expected {
        return Ok(());
    }
    Err(Refusal::invalid_request(
        "query_unsupported",
        "The gateway requires alt=sse for streamGenerateContent and accepts no other query.",
    ))
}

#[derive(Clone, Copy)]
pub enum GenerateContentMethod {
    GenerateContent,
    StreamGenerateContent,
    CountTokens,
}

impl GenerateContentMethod {
    pub fn named(method: &str) -> Option<Self> {
        match method {
            "generateContent" => Some(Self::GenerateContent),
            "streamGenerateContent" => Some(Self::StreamGenerateContent),
            "countTokens" => Some(Self::CountTokens),
            _ => None,
        }
    }

    pub fn name(self) -> &'static str {
        match self {
            Self::GenerateContent => "generateContent",
            Self::StreamGenerateContent => "streamGenerateContent",
            Self::CountTokens => "countTokens",
        }
    }

    pub fn work(self) -> Work {
        match self {
            Self::GenerateContent | Self::StreamGenerateContent => Work::Answer,
            Self::CountTokens => Work::CountTokens,
        }
    }

    pub fn query(self) -> Option<&'static str> {
        match self {
            Self::StreamGenerateContent => Some("alt=sse"),
            Self::GenerateContent | Self::CountTokens => None,
        }
    }
}

pub struct Fields {
    pub passed_as_given: &'static [&'static str],
    pub passed_only_as: &'static [FixedField],
    pub conversation: &'static str,
}

pub struct FixedField {
    pub name: &'static str,
    pub json: &'static str,
}

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
        "client_metadata",
        "prompt_cache_key",
        "prompt_cache_retention",
        "prompt_cache_options",
    ],
    passed_only_as: &[
        DEFAULT_TIER,
        NOTHING_STORED,
        FixedField {
            name: "background",
            json: "false",
        },
    ],
    conversation: "input",
};

const GENERATE_CONTENT_FIELDS: Fields = Fields {
    passed_as_given: &[
        "contents",
        "systemInstruction",
        "system_instruction",
        "tools",
        "toolConfig",
        "tool_config",
        "generationConfig",
        "generation_config",
        "safetySettings",
        "safety_settings",
    ],
    passed_only_as: &[],
    conversation: "contents",
};

pub const GENERATE_CONTENT_REQUEST_FIELDS: [&str; 2] =
    ["generateContentRequest", "generate_content_request"];
pub const FIELDS_OF_WRAPPED_GENERATE_CONTENT_REQUEST: [&str; 1] = ["model"];
const REFUSED_BETA: &[u8] = b"server-side-fallback-";

const DEFAULT_TIER: FixedField = FixedField {
    name: "service_tier",
    json: "\"default\"",
};
pub const NOTHING_STORED: FixedField = FixedField {
    name: "store",
    json: "false",
};

impl Api {
    pub const ROUTES_WITH_MODEL_IN_BODY: [(Self, Work, &str); 4] = [
        (Self::Messages, Work::Answer, "/messages"),
        (Self::Responses, Work::Answer, "/responses"),
        (Self::Messages, Work::CountTokens, "/messages/count_tokens"),
        (
            Self::Responses,
            Work::CountTokens,
            "/responses/input_tokens",
        ),
    ];

    pub fn credential(
        self,
        secret: String,
    ) -> Result<(HeaderName, HeaderValue), InvalidHeaderValue> {
        let (name, value) = match self {
            Self::Messages => (X_API_KEY, secret),
            Self::GenerateContent => (X_GOOG_API_KEY, secret),
            Self::Responses => (AUTHORIZATION, format!("Bearer {secret}")),
        };
        let mut value = HeaderValue::try_from(value)?;
        value.set_sensitive(true);
        Ok((name, value))
    }

    pub fn version(self) -> &'static str {
        match self {
            Self::GenerateContent => "v1beta",
            Self::Messages | Self::Responses => "v1",
        }
    }

    pub fn name_and_answering_route(self, provider: &str) -> String {
        let version = self.version();
        match self {
            Self::GenerateContent => format!(
                "the Gemini API at POST /{provider}/{version}/models/{{model}}:generateContent"
            ),
            Self::Messages => format!("the Messages API at POST /{provider}/{version}/messages"),
            Self::Responses => format!("the Responses API at POST /{provider}/{version}/responses"),
        }
    }

    pub fn model_list<'name>(
        self,
        provider: &str,
        names: impl Iterator<Item = &'name str>,
    ) -> Value {
        let models: Vec<Value> = names
            .map(|name| match self {
                Self::GenerateContent => json!({
                    "name": format!("models/{name}"),
                    "displayName": name,
                    "supportedGenerationMethods": ["generateContent", "countTokens"],
                }),
                Self::Messages => json!({
                    "type": "model",
                    "id": name,
                    "display_name": name,
                    "created_at": "1970-01-01T00:00:00Z",
                }),
                Self::Responses => {
                    json!({ "id": name, "object": "model", "created": 0, "owned_by": provider })
                }
            })
            .collect();
        let id = |model: Option<&Value>| model.map(|model| model["id"].clone());
        match self {
            Self::GenerateContent => json!({ "models": models }),
            Self::Messages => json!({
                "has_more": false,
                "first_id": id(models.first()),
                "last_id": id(models.last()),
                "data": models,
            }),
            Self::Responses => json!({ "object": "list", "data": models }),
        }
    }

    pub fn model_not_found(self) -> Refusal {
        let version = self.version();
        Refusal::new(
            StatusCode::NOT_FOUND,
            "not_found_error",
            "model_not_found",
            format!(
                "This API serves no such model; GET /{{provider}}/{version}/models lists the configured models."
            ),
        )
    }

    pub fn fields(self) -> &'static Fields {
        match self {
            Self::GenerateContent => &GENERATE_CONTENT_FIELDS,
            Self::Messages => &MESSAGES_FIELDS,
            Self::Responses => &RESPONSES_FIELDS,
        }
    }

    pub fn refused_tool(self, tool: &Value) -> Option<&str> {
        let kind = tool["type"].as_str();
        match self {
            Self::GenerateContent => tool.as_object()?.keys().map(String::as_str).find(|name| {
                matches!(
                    name.replace('_', "").to_ascii_lowercase().as_str(),
                    "googlesearch"
                        | "googlesearchretrieval"
                        | "googlemaps"
                        | "enterprisewebsearch"
                        | "filesearch"
                )
            }),
            Self::Messages => kind
                .filter(|kind| kind.starts_with("code_execution_") || kind.starts_with("advisor_")),
            Self::Responses => kind.filter(|kind| match *kind {
                "code_interpreter"
                | "file_search"
                | "image_generation"
                | "web_search_preview"
                | "programmatic_tool_calling" => true,
                "shell" => tool["environment"]["type"] != "local",
                _ => false,
            }),
        }
    }

    pub fn headers_passed_on(self, given: &HeaderMap) -> Result<HeaderMap, Refusal> {
        let names: &[HeaderName] = match self {
            Self::Messages => &MESSAGES_HEADERS,
            Self::GenerateContent | Self::Responses => &[],
        };
        let mut passed_on = HeaderMap::new();
        for name in names {
            for value in given.get_all(name) {
                if *name == ANTHROPIC_BETA
                    && let Some(beta) = value
                        .as_bytes()
                        .split(|&byte| byte == b',')
                        .map(<[u8]>::trim_ascii)
                        .find(|beta| {
                            let flag_length = REFUSED_BETA.len().min(beta.len());
                            beta[..flag_length].eq_ignore_ascii_case(REFUSED_BETA)
                        })
                {
                    return Err(Refusal::invalid_request(
                        "beta_unsupported",
                        format!(
                            "The gateway does not pass on the beta {:?}.",
                            String::from_utf8_lossy(beta)
                        ),
                    ));
                }
                passed_on.append(name.clone(), value.clone());
            }
        }
        Ok(passed_on)
    }
}
