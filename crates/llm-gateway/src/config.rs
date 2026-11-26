use std::{
    collections::BTreeMap,
    net::SocketAddr,
    path::{Path, PathBuf},
};

use anyhow::{Context, Result, bail};
use serde::Deserialize;

use crate::{api::Api, price::ModelPrices};

const PREFIX_LENGTH_LIMIT: usize = 12;

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Config {
    pub listen: SocketAddr,
    pub dashboard_listen: SocketAddr,
    pub public_host: String,
    pub key_prefix: String,
    pub client_provider_prefix: String,
    pub store_file: PathBuf,
    pub providers: BTreeMap<String, ProviderConfig>,
    pub models: BTreeMap<String, ModelPrices>,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct ProviderConfig {
    pub key_file: PathBuf,
    pub api: Api,
    pub base_url: String,
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
        let is_host_character = |byte: u8| byte.is_ascii_alphanumeric() || b"-.".contains(&byte);
        if self.public_host.is_empty() || !self.public_host.bytes().all(is_host_character) {
            bail!("public_host {:?} is not a host name", self.public_host);
        }
        let prefixes = [
            ("key_prefix", &self.key_prefix),
            ("client_provider_prefix", &self.client_provider_prefix),
        ];
        for (setting, prefix) in prefixes {
            let is_prefix_character = |byte: u8| byte.is_ascii_lowercase() || byte.is_ascii_digit();
            let is_short_word = (1..=PREFIX_LENGTH_LIMIT).contains(&prefix.len())
                && prefix.bytes().all(is_prefix_character);
            if !is_short_word {
                bail!(
                    "{setting} {prefix:?} is not 1 to {PREFIX_LENGTH_LIMIT} lower-case letters and digits"
                );
            }
        }
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
