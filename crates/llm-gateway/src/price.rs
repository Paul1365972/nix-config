use std::{collections::BTreeMap, iter::Sum, ops::AddAssign};

use serde::{Deserialize, Serialize, Serializer};

use crate::usage::{CacheLifetime, Usage};

#[derive(Debug, Clone, Copy, Default, PartialEq, Eq, PartialOrd, Ord)]
pub struct MicroUsd(pub i64);

impl MicroUsd {
    pub fn from_usd(usd: f64) -> Self {
        Self((usd * 1e6).round() as i64)
    }

    pub fn usd(self) -> f64 {
        self.0 as f64 / 1e6
    }
}

impl AddAssign for MicroUsd {
    fn add_assign(&mut self, other: Self) {
        self.0 = self.0.saturating_add(other.0);
    }
}

impl Sum for MicroUsd {
    fn sum<I: Iterator<Item = Self>>(amounts: I) -> Self {
        amounts.fold(Self(0), |mut sum, amount| {
            sum += amount;
            sum
        })
    }
}

impl Serialize for MicroUsd {
    fn serialize<S: Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        serializer.serialize_f64(self.usd())
    }
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct ModelPrices {
    standard: TokenPrices,
    #[serde(default)]
    long_context: Option<LongContextPrices>,
    #[serde(default)]
    web_search_usd_per_thousand: Option<f64>,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
struct LongContextPrices {
    above_input_tokens: u64,
    prices: TokenPrices,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
struct TokenPrices {
    input_usd_per_million_tokens: f64,
    output_usd_per_million_tokens: f64,
    #[serde(default)]
    cache_read_usd_per_million_tokens: Option<f64>,
    #[serde(default)]
    cache_write_usd_per_million_tokens: BTreeMap<CacheLifetime, f64>,
}

impl ModelPrices {
    pub fn cost(&self, usage: &Usage) -> MicroUsd {
        let tokens = match &self.long_context {
            Some(long) if usage.input_tokens() > long.above_input_tokens => &long.prices,
            _ => &self.standard,
        };
        let micro_usd_per_web_search = self.web_search_usd_per_thousand.unwrap_or(0.0) * 1e3;
        let micro_usd =
            tokens.micro_usd(usage) + usage.web_searches as f64 * micro_usd_per_web_search;
        MicroUsd(micro_usd.ceil() as i64)
    }

    pub fn are_amounts(&self) -> bool {
        let long_context = self
            .long_context
            .iter()
            .flat_map(|long| long.prices.amounts());
        let mut amounts = self
            .standard
            .amounts()
            .chain(long_context)
            .chain(self.web_search_usd_per_thousand);
        amounts.all(|usd| usd.is_finite() && usd >= 0.0)
    }
}

impl TokenPrices {
    fn micro_usd(&self, usage: &Usage) -> f64 {
        let input = self.input_usd_per_million_tokens;
        let cache_read = self.cache_read_usd_per_million_tokens.unwrap_or(input);
        let cache_writes: f64 = usage
            .cache_write_tokens
            .by_lifetime()
            .map(|(lifetime, tokens)| {
                let price = self.cache_write_usd_per_million_tokens.get(&lifetime);
                tokens as f64 * price.unwrap_or(&input)
            })
            .sum();
        usage.uncached_input_tokens as f64 * input
            + usage.cache_read_tokens as f64 * cache_read
            + cache_writes
            + usage.output_tokens as f64 * self.output_usd_per_million_tokens
    }

    fn amounts(&self) -> impl Iterator<Item = f64> {
        [
            self.input_usd_per_million_tokens,
            self.output_usd_per_million_tokens,
        ]
        .into_iter()
        .chain(self.cache_read_usd_per_million_tokens)
        .chain(self.cache_write_usd_per_million_tokens.values().copied())
    }
}
