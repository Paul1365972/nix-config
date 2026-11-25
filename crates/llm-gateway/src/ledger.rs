use std::{
    collections::{BTreeMap, BTreeSet},
    fmt,
    str::FromStr,
    sync::{Arc, Mutex, MutexGuard},
};

use anyhow::{Context, Result};
use chrono::{Datelike, Utc};
use serde::Serialize;

use crate::{
    price::MicroUsd,
    store::{Store, Write},
    usage::Usage,
};

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub struct Month(i32);

impl Month {
    pub fn from_index(index: i32) -> Self {
        Self(index)
    }

    pub fn index(self) -> i32 {
        self.0
    }

    fn now() -> Self {
        let today = Utc::now();
        Self(today.year() * 12 + today.month0() as i32)
    }
}

impl fmt::Display for Month {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        let (year, month) = (self.0.div_euclid(12), self.0.rem_euclid(12) + 1);
        write!(formatter, "{year}-{month:02}")
    }
}

impl FromStr for Month {
    type Err = anyhow::Error;

    fn from_str(text: &str) -> Result<Self> {
        let (year, month) = text.split_once('-').context("a month reads YYYY-MM")?;
        let (year, month): (i32, i32) = (year.parse()?, month.parse()?);
        anyhow::ensure!((1..=12).contains(&month), "a month reads YYYY-MM");
        Ok(Self(year * 12 + month - 1))
    }
}

pub struct Charge {
    pub usage: Usage,
    pub cost: MicroUsd,
    pub is_estimated: bool,
}

#[derive(Debug, Clone, Copy, Default, Serialize)]
pub struct Tally {
    requests: u64,
    estimated_requests: u64,
    uncached_input_tokens: u64,
    cache_read_tokens: u64,
    cache_write_tokens: u64,
    output_tokens: u64,
    web_searches: u64,
    #[serde(rename = "cost_usd")]
    cost: MicroUsd,
}

pub type TallyRow = (u64, u64, u64, u64, u64, u64, u64, i64);
pub type Tallies = BTreeMap<Arc<str>, BTreeMap<Arc<str>, Tally>>;

impl Tally {
    pub fn from_row(row: TallyRow) -> Self {
        let (
            requests,
            estimated_requests,
            uncached_input_tokens,
            cache_read_tokens,
            cache_write_tokens,
            output_tokens,
            web_searches,
            cost,
        ) = row;
        Self {
            requests,
            estimated_requests,
            uncached_input_tokens,
            cache_read_tokens,
            cache_write_tokens,
            output_tokens,
            web_searches,
            cost: MicroUsd(cost),
        }
    }

    pub fn row(&self) -> TallyRow {
        (
            self.requests,
            self.estimated_requests,
            self.uncached_input_tokens,
            self.cache_read_tokens,
            self.cache_write_tokens,
            self.output_tokens,
            self.web_searches,
            self.cost.0,
        )
    }

    fn add(&mut self, charge: &Charge) {
        self.requests += 1;
        self.estimated_requests += u64::from(charge.is_estimated);
        self.uncached_input_tokens += charge.usage.uncached_input_tokens;
        self.cache_read_tokens += charge.usage.cache_read_tokens;
        self.cache_write_tokens += charge.usage.cache_write_tokens.total();
        self.output_tokens += charge.usage.output_tokens;
        self.web_searches += charge.usage.web_searches;
        self.cost += charge.cost;
    }
}

pub struct Ledger {
    store: Store,
    this_month: Mutex<ThisMonth>,
}

struct ThisMonth {
    month: Month,
    tallies: Tallies,
}

impl Ledger {
    pub fn load(store: Store) -> Result<Self> {
        let month = Month::now();
        let tallies = store.tallies(month).context("reading the tallies")?;
        Ok(Self {
            store,
            this_month: Mutex::new(ThisMonth { month, tallies }),
        })
    }

    pub fn record(&self, key: &Arc<str>, model: &Arc<str>, charge: &Charge) {
        let mut this_month = self.lock_this_month();
        let month = this_month.month;
        let key_tallies = this_month.tallies.entry(key.clone()).or_default();
        let tally = key_tallies.entry(model.clone()).or_default();
        tally.add(charge);
        // Sent under the lock, so the store gets a tally's values in the order they were reached.
        self.store.write(Write::Tally {
            month,
            key: key.clone(),
            model: model.clone(),
            tally: *tally,
        });
    }

    pub fn spent(&self, key: &str) -> MicroUsd {
        let this_month = self.lock_this_month();
        let mut spent = MicroUsd(0);
        for tally in this_month.tallies.get(key).into_iter().flatten() {
            spent += tally.1.cost;
        }
        spent
    }

    pub fn spent_on(&self, key: &str, model: &str) -> MicroUsd {
        let this_month = self.lock_this_month();
        let models = this_month.tallies.get(key);
        let tally = models.and_then(|models| models.get(model));
        tally.map_or(MicroUsd(0), |tally| tally.cost)
    }

    pub fn this_month(&self) -> (Month, Tallies) {
        let this_month = self.lock_this_month();
        (this_month.month, this_month.tallies.clone())
    }

    pub fn month(&self, month: Month) -> Result<Tallies> {
        let (this_month, tallies) = self.this_month();
        if month == this_month {
            return Ok(tallies);
        }
        self.store.tallies(month)
    }

    pub fn months(&self) -> Result<BTreeSet<Month>> {
        let mut months = self.store.months()?;
        months.insert(self.lock_this_month().month);
        Ok(months)
    }

    fn lock_this_month(&self) -> MutexGuard<'_, ThisMonth> {
        let mut this_month = self
            .this_month
            .lock()
            .expect("the ledger lock is never poisoned");
        let now = Month::now();
        if now > this_month.month {
            this_month.month = now;
            this_month.tallies.clear();
        }
        this_month
    }
}
