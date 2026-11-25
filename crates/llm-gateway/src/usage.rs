use std::{ops::Add, time::Duration};

use serde::Deserialize;

const INPUT_TOKEN_ESTIMATE_BYTES: u64 = 4;
const OUTPUT_ESTIMATE_TOKENS_PER_SECOND: u64 = 100;

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Deserialize)]
pub enum CacheLifetime {
    #[serde(rename = "5m")]
    FiveMinutes,
    #[serde(rename = "30m")]
    ThirtyMinutes,
    #[serde(rename = "1h")]
    OneHour,
    #[serde(rename = "12h")]
    TwelveHours,
}

impl CacheLifetime {
    const ALL: [Self; 4] = [
        Self::FiveMinutes,
        Self::ThirtyMinutes,
        Self::OneHour,
        Self::TwelveHours,
    ];
}

#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub struct CacheWriteTokens([u64; CacheLifetime::ALL.len()]);

impl CacheWriteTokens {
    pub fn by_lifetime(&self) -> impl Iterator<Item = (CacheLifetime, u64)> {
        CacheLifetime::ALL.into_iter().zip(self.0)
    }

    pub fn total(&self) -> u64 {
        self.0.iter().sum()
    }
}

impl FromIterator<(CacheLifetime, u64)> for CacheWriteTokens {
    fn from_iter<I: IntoIterator<Item = (CacheLifetime, u64)>>(tokens_by_lifetime: I) -> Self {
        let mut written = Self::default();
        for (lifetime, tokens) in tokens_by_lifetime {
            written.0[lifetime as usize] += tokens;
        }
        written
    }
}

impl Add for CacheWriteTokens {
    type Output = Self;

    fn add(self, other: Self) -> Self {
        Self(std::array::from_fn(|lifetime| {
            self.0[lifetime].saturating_add(other.0[lifetime])
        }))
    }
}

#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub struct Usage {
    pub uncached_input_tokens: u64,
    pub cache_read_tokens: u64,
    pub cache_write_tokens: CacheWriteTokens,
    pub output_tokens: u64,
    pub web_searches: u64,
}

impl Usage {
    pub fn estimate(request_bytes: usize, duration: Duration) -> Self {
        Self {
            uncached_input_tokens: request_bytes as u64 / INPUT_TOKEN_ESTIMATE_BYTES,
            output_tokens: duration.as_secs() * OUTPUT_ESTIMATE_TOKENS_PER_SECOND,
            ..Self::default()
        }
    }

    pub fn input_tokens(&self) -> u64 {
        self.uncached_input_tokens + self.cache_read_tokens + self.cache_write_tokens.total()
    }

    pub fn with_later_running_counts(self, later: Self) -> Self {
        let later_repeats_writes_without_lifetimes =
            later.cache_write_tokens.total() <= self.cache_write_tokens.total();
        Self {
            uncached_input_tokens: self.uncached_input_tokens.max(later.uncached_input_tokens),
            cache_read_tokens: self.cache_read_tokens.max(later.cache_read_tokens),
            cache_write_tokens: match later_repeats_writes_without_lifetimes {
                true => self.cache_write_tokens,
                false => later.cache_write_tokens,
            },
            output_tokens: self.output_tokens.max(later.output_tokens),
            web_searches: self.web_searches.max(later.web_searches),
        }
    }
}

impl Add for Usage {
    type Output = Self;

    fn add(self, other: Self) -> Self {
        Self {
            uncached_input_tokens: self
                .uncached_input_tokens
                .saturating_add(other.uncached_input_tokens),
            cache_read_tokens: self
                .cache_read_tokens
                .saturating_add(other.cache_read_tokens),
            cache_write_tokens: self.cache_write_tokens + other.cache_write_tokens,
            output_tokens: self.output_tokens.saturating_add(other.output_tokens),
            web_searches: self.web_searches.saturating_add(other.web_searches),
        }
    }
}
