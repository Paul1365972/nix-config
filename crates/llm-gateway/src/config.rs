use std::{
    collections::{BTreeMap, BTreeSet},
    net::SocketAddr,
    path::{Path, PathBuf},
};

use anyhow::{Context, Result, bail};
use serde::Deserialize;

use crate::{api::Api, price::ModelPrices};

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Config {
    pub listen: SocketAddr,
    pub dashboard_listen: SocketAddr,
    pub store_file: PathBuf,
    pub providers: BTreeMap<String, ProviderConfig>,
    pub models: BTreeMap<String, ModelPrices>,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct ProviderConfig {
    pub base_url: String,
    pub key_file: PathBuf,
    pub apis: BTreeSet<Api>,
}

impl Config {
    pub fn load(path: &Path) -> Result<Self> {
        let text = std::fs::read_to_string(path)
            .with_context(|| format!("reading config {}", path.display()))?;
        let config: Self =
            toml::from_str(&text).with_context(|| format!("config {}", path.display()))?;
        config
            .check()
            .with_context(|| format!("config {}", path.display()))?;
        Ok(config)
    }

    fn check(&self) -> Result<()> {
        for (name, prices) in &self.models {
            let Some((provider, _)) = name.split_once('/') else {
                bail!("model {name:?} is not named provider/model");
            };
            if !self.providers.contains_key(provider) {
                bail!("model {name:?} has no configured provider");
            }
            if !prices.are_amounts() {
                bail!("model {name:?} has a price that is not an amount");
            }
        }
        Ok(())
    }
}

pub fn read_secret(path: &Path) -> Result<String> {
    let secret = std::fs::read_to_string(path)
        .with_context(|| format!("reading secret {}", path.display()))?;
    let secret = secret.trim();
    if secret.is_empty() {
        bail!("secret {} is empty", path.display());
    }
    Ok(secret.to_owned())
}
