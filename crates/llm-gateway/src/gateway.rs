use std::{
    collections::{BTreeMap, BTreeSet},
    sync::Arc,
    time::Duration,
};

use anyhow::{Context, Result};
use axum::http::{HeaderValue, StatusCode};

use crate::{
    api::Api,
    config::{Config, read_secret},
    keys::{Key, Keys, RunningRequest},
    ledger::Ledger,
    price::{MicroUsd, ModelPrices},
    refusal::Refusal,
    store::Store,
    usage::Usage,
};

const OPENCODE_STREAM_CHUNK_TIMEOUT: Duration = Duration::from_secs(15 * 60);

pub struct Gateway {
    pub client: reqwest::Client,
    pub store: Store,
    pub ledger: Ledger,
    pub keys: Keys,
    providers: BTreeMap<String, Arc<Provider>>,
    models: BTreeMap<String, Arc<Model>>,
}

pub struct Provider {
    pub name: String,
    pub base_url: String,
    pub bearer: HeaderValue,
    pub api_key: HeaderValue,
    apis: BTreeSet<Api>,
}

pub struct Model {
    pub name: Arc<str>,
    pub provider: Arc<Provider>,
    prices: ModelPrices,
}

impl Gateway {
    pub fn new(config: Config) -> Result<Self> {
        let client = reqwest::Client::builder()
            .user_agent(concat!("llm-gateway/", env!("CARGO_PKG_VERSION")))
            .connect_timeout(Duration::from_secs(10))
            .read_timeout(OPENCODE_STREAM_CHUNK_TIMEOUT)
            .redirect(reqwest::redirect::Policy::none())
            .tcp_nodelay(true)
            .http2_adaptive_window(true)
            .http2_keep_alive_interval(Duration::from_secs(30))
            .http2_keep_alive_timeout(Duration::from_secs(10))
            .http2_keep_alive_while_idle(true)
            .build()
            .context("building the HTTP client")?;

        let mut providers = BTreeMap::new();
        for (name, provider) in config.providers {
            let secret = read_secret(&provider.key_file)?;
            let header = |value: String| {
                let mut value = HeaderValue::try_from(value)
                    .with_context(|| format!("the key of provider {name} is not a header value"))?;
                value.set_sensitive(true);
                anyhow::Ok(value)
            };
            let provider = Provider {
                base_url: provider.base_url.trim_end_matches('/').to_owned(),
                bearer: header(format!("Bearer {secret}"))?,
                api_key: header(secret)?,
                apis: provider.apis,
                name: name.clone(),
            };
            providers.insert(name, Arc::new(provider));
        }
        let models = config
            .models
            .into_iter()
            .map(|(name, prices)| {
                let provider = name
                    .split_once('/')
                    .and_then(|(name, _)| providers.get(name));
                let model = Model {
                    name: name.as_str().into(),
                    provider: provider
                        .with_context(|| format!("model {name:?} has no configured provider"))?
                        .clone(),
                    prices,
                };
                Ok((name, Arc::new(model)))
            })
            .collect::<Result<_>>()?;

        let store = Store::open(&config.store_file)?;
        Ok(Self {
            client,
            ledger: Ledger::load(store.clone())?,
            keys: Keys::load(store.clone())?,
            store,
            providers,
            models,
        })
    }

    pub fn providers(&self) -> impl Iterator<Item = &str> {
        self.providers.keys().map(String::as_str)
    }

    pub fn models(&self) -> impl Iterator<Item = &Model> {
        self.models.values().map(|model| &**model)
    }

    pub fn run_request(&self, key: &Key) -> Result<RunningRequest, Refusal> {
        let (spent, limit) = (self.ledger.spent(&key.name), key.limit());
        if spent >= limit {
            return Err(spent_limit(&key.name, spent, limit, "this month"));
        }
        key.run_request().ok_or_else(|| {
            Refusal::new(
                StatusCode::TOO_MANY_REQUESTS,
                "rate_limit_error",
                "rate_limit_exceeded",
                format!(
                    "The key {} runs as many requests as it may at once.",
                    key.name
                ),
            )
            .retry_after_seconds(1)
        })
    }

    pub fn model_served(&self, key: &Key, api: Api, name: &str) -> Result<Arc<Model>, Refusal> {
        let model = self
            .models
            .get(name)
            .filter(|model| model.provider.apis.contains(&api));
        let Some(model) = model else {
            return Err(Refusal::new(
                StatusCode::NOT_FOUND,
                "not_found_error",
                "model_not_found",
                "This API serves no such model; GET /v1/models lists the configured models.",
            ));
        };
        if !key.may_use(&model.provider.name) {
            return Err(Refusal::new(
                StatusCode::FORBIDDEN,
                "permission_error",
                "provider_not_allowed",
                format!(
                    "The key {} may not use the provider {}.",
                    key.name, model.provider.name
                ),
            ));
        }
        let spent_on_model = self.ledger.spent_on(&key.name, name);
        match key.limit_of_model(name) {
            Some(limit) if spent_on_model >= limit => {
                let on_model = format!("on {name} this month");
                Err(spent_limit(&key.name, spent_on_model, limit, &on_model))
            }
            _ => Ok(model.clone()),
        }
    }
}

impl Model {
    pub fn cost(&self, usage: &Usage) -> MicroUsd {
        self.prices.cost(usage)
    }
}

fn spent_limit(key: &str, spent: MicroUsd, limit: MicroUsd, scope: &str) -> Refusal {
    Refusal::new(
        StatusCode::TOO_MANY_REQUESTS,
        "insufficient_quota",
        "insufficient_quota",
        format!(
            "The key {key} has spent {:.2} USD of its {:.2} USD {scope}.",
            spent.usd(),
            limit.usd()
        ),
    )
}
