use axum::http::{HeaderName, HeaderValue, header::AUTHORIZATION};
use serde::{Deserialize, Serialize};

use crate::gateway::Provider;

pub const X_API_KEY: HeaderName = HeaderName::from_static("x-api-key");

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Deserialize, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum Api {
    ChatCompletions,
    Messages,
    Responses,
}

pub struct ListPriceChoice {
    pub field: &'static str,
    pub value: &'static str,
}

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

    pub fn list_price_choices(self) -> &'static [ListPriceChoice] {
        const STANDARD_TIER: ListPriceChoice = ListPriceChoice {
            field: "service_tier",
            value: "standard_only",
        };
        const GLOBAL_REGION: ListPriceChoice = ListPriceChoice {
            field: "inference_geo",
            value: "global",
        };
        const STANDARD_SPEED: ListPriceChoice = ListPriceChoice {
            field: "speed",
            value: "standard",
        };
        const DEFAULT_TIER: ListPriceChoice = ListPriceChoice {
            field: "service_tier",
            value: "default",
        };
        match self {
            Self::Messages => &[STANDARD_TIER, GLOBAL_REGION, STANDARD_SPEED],
            Self::ChatCompletions | Self::Responses => &[DEFAULT_TIER],
        }
    }
}
