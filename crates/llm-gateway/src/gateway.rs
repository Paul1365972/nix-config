use std::{collections::BTreeMap, sync::Arc, time::Duration};

use anyhow::{Context, Result};
use axum::http::{HeaderValue, StatusCode};
use tokio::sync::watch;

use crate::{
    api::Api,
    config::{Config, read_secret},
    keys::{Key, Keys, RunningRequest},
    ledger::{Ledger, SpentByProvider},
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
    pub public_url: String,
    pub client_provider_prefix: String,
    pub responses_running: watch::Sender<usize>,
    providers: BTreeMap<String, Arc<Provider>>,
    models: BTreeMap<String, Arc<Model>>,
}

pub struct Provider {
    pub name: String,
    pub bearer: HeaderValue,
    pub api_key: HeaderValue,
    base_urls: BTreeMap<Api, String>,
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
                bearer: header(format!("Bearer {secret}"))?,
                api_key: header(secret)?,
                base_urls: provider
                    .base_urls
                    .into_iter()
                    .map(|(api, url)| (api, url.trim_end_matches('/').to_owned()))
                    .collect(),
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
            keys: Keys::load(store.clone(), config.key_prefix)?,
            public_url: format!("https://{}", config.public_host),
            client_provider_prefix: config.client_provider_prefix,
            responses_running: watch::Sender::new(0),
            store,
            providers,
            models,
        })
    }

    pub fn providers(&self) -> impl Iterator<Item = &str> {
        self.providers.keys().map(String::as_str)
    }

    pub fn provider_serves(&self, name: &str, api: Api) -> bool {
        self.providers
            .get(name)
            .is_some_and(|provider| provider.serves(api))
    }

    pub fn apis_by_provider(&self) -> BTreeMap<&str, Vec<Api>> {
        let providers = self.providers.values();
        providers
            .map(|provider| {
                (
                    provider.name.as_str(),
                    provider.base_urls.keys().copied().collect(),
                )
            })
            .collect()
    }

    pub fn models_by_provider(&self) -> BTreeMap<&str, Vec<&str>> {
        let mut models_by_provider = BTreeMap::<&str, Vec<&str>>::new();
        for model in self.models.values() {
            let name_without_provider = model
                .name
                .split_once('/')
                .map_or(&*model.name, |(_, name)| name);
            let models = models_by_provider.entry(&model.provider.name).or_default();
            models.push(name_without_provider);
        }
        models_by_provider
    }

    pub fn models(&self) -> impl Iterator<Item = &Model> {
        self.models.values().map(|model| &**model)
    }

    pub fn spent_by_provider(&self, key: &Key) -> SpentByProvider {
        self.ledger.spent_by_provider(&key.name, key.period_start())
    }

    pub fn spent_on_every_provider(&self, key: &Key) -> SpentByProvider {
        let mut spent = self.spent_by_provider(key);
        for provider in self.providers() {
            spent.entry(provider.to_owned()).or_default();
        }
        spent
    }

    pub fn run_request(&self, key: &Key) -> Result<RunningRequest, Refusal> {
        let spent = self.spent_by_provider(key).into_values().sum();
        let (limit, period) = (key.limit(), key.settings.limit_resets.period());
        if spent >= limit {
            return Err(spent_limit(&key.name, spent, limit, period));
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
            .filter(|model| model.provider.serves(api));
        let Some(model) = model else {
            let message = match api {
                Api::GenerateContent => {
                    "This API serves no such model; GET /{provider}/v1beta/models lists the configured models."
                }
                _ => "This API serves no such model; GET /v1/models lists the configured models.",
            };
            return Err(Refusal::new(
                StatusCode::NOT_FOUND,
                "not_found_error",
                "model_not_found",
                message,
            ));
        };
        let provider = &model.provider.name;
        let spent_by_provider = self.spent_by_provider(key);
        let spent = spent_by_provider.get(provider).copied().unwrap_or_default();
        match key.limit_of_provider(provider) {
            Some(limit) if spent >= limit => {
                let on_provider = format!("on {provider} {}", key.settings.limit_resets.period());
                Err(spent_limit(&key.name, spent, limit, &on_provider))
            }
            _ => Ok(model.clone()),
        }
    }
}

impl Provider {
    pub fn serves(&self, api: Api) -> bool {
        self.base_urls.contains_key(&api)
    }

    pub fn base_url(&self, api: Api) -> &str {
        &self.base_urls[&api]
    }
}

impl Model {
    pub fn cost(&self, usage: &Usage) -> MicroUsd {
        self.prices.cost(usage)
    }
}

fn spent_limit(key: &str, spent: MicroUsd, limit: MicroUsd, period: &str) -> Refusal {
    Refusal::new(
        StatusCode::TOO_MANY_REQUESTS,
        "insufficient_quota",
        "insufficient_quota",
        format!(
            "The key {key} has spent {:.2} USD of its {:.2} USD {period}.",
            spent.usd(),
            limit.usd()
        ),
    )
}
