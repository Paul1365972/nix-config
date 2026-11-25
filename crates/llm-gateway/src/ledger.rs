use std::{
    collections::{BTreeMap, BTreeSet},
    fmt,
    ops::{AddAssign, Range, RangeBounds},
    str::FromStr,
    sync::{Arc, Mutex, MutexGuard},
};

use anyhow::{Context, Result};
use chrono::{Datelike, Months, NaiveDate, Utc};
use serde::Serialize;

use crate::{
    price::MicroUsd,
    store::{Store, Write},
    usage::Usage,
};

pub fn today() -> NaiveDate {
    Utc::now().date_naive()
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub struct Month {
    first_day: NaiveDate,
}

impl Month {
    pub fn now() -> Self {
        Self::of(today())
    }

    pub fn days(self) -> Range<NaiveDate> {
        let next_month = self.first_day.checked_add_months(Months::new(1));
        self.first_day..next_month.unwrap_or(NaiveDate::MAX)
    }

    fn of(day: NaiveDate) -> Self {
        Self {
            first_day: day.with_day(1).expect("every month has a first day"),
        }
    }
}

impl fmt::Display for Month {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(formatter, "{}", self.first_day.format("%Y-%m"))
    }
}

impl FromStr for Month {
    type Err = chrono::ParseError;

    fn from_str(text: &str) -> Result<Self, Self::Err> {
        NaiveDate::parse_from_str(&format!("{text}-01"), "%Y-%m-%d").map(Self::of)
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

impl AddAssign for Tally {
    fn add_assign(&mut self, other: Self) {
        self.requests += other.requests;
        self.estimated_requests += other.estimated_requests;
        self.uncached_input_tokens += other.uncached_input_tokens;
        self.cache_read_tokens += other.cache_read_tokens;
        self.cache_write_tokens += other.cache_write_tokens;
        self.output_tokens += other.output_tokens;
        self.web_searches += other.web_searches;
        self.cost += other.cost;
    }
}

pub type TalliesByModel = BTreeMap<Arc<str>, Tally>;
pub type TalliesByKey = BTreeMap<Arc<str>, TalliesByModel>;
pub type DaysByKey = BTreeMap<Arc<str>, BTreeMap<NaiveDate, TalliesByModel>>;
pub type SpentByProvider = BTreeMap<String, MicroUsd>;

pub struct Ledger {
    store: Store,
    days_by_key: Mutex<DaysByKey>,
}

impl Ledger {
    pub fn load(store: Store) -> Result<Self> {
        let days_by_key = store.tallies().context("reading the tallies")?;
        Ok(Self {
            store,
            days_by_key: Mutex::new(days_by_key),
        })
    }

    pub fn record(&self, key: &Arc<str>, model: &Arc<str>, charge: &Charge) {
        let day = today();
        let mut days_by_key = self.lock();
        let days = days_by_key.entry(key.clone()).or_default();
        let tally = days
            .entry(day)
            .or_default()
            .entry(model.clone())
            .or_default();
        tally.add(charge);
        // Sent under the lock, so the store gets a tally's values in the order they were reached.
        self.store.write(Write::Tally {
            day,
            key: key.clone(),
            model: model.clone(),
            tally: *tally,
        });
    }

    pub fn spent_by_provider(&self, key: &str, since: NaiveDate) -> SpentByProvider {
        let days_by_key = self.lock();
        let mut spent = SpentByProvider::new();
        for (model, tally) in tallies_since(&days_by_key, key, since) {
            add_to_provider_of(model, tally, &mut spent);
        }
        spent
    }

    pub fn spent_by_day(
        &self,
        only_key: Option<&str>,
        days: impl RangeBounds<NaiveDate> + Clone,
    ) -> BTreeMap<NaiveDate, SpentByProvider> {
        let days_by_key = self.lock();
        let mut spent_by_day = BTreeMap::<NaiveDate, SpentByProvider>::new();
        let keys = days_by_key
            .iter()
            .filter(|(key, _)| only_key.is_none_or(|only_key| ***key == *only_key));
        for (day, tallies) in keys.flat_map(|(_, key_days)| key_days.range(days.clone())) {
            let spent = spent_by_day.entry(*day).or_default();
            for (model, tally) in tallies {
                add_to_provider_of(model, tally, spent);
            }
        }
        spent_by_day
    }

    pub fn models_since(&self, key: &str, since: NaiveDate) -> TalliesByModel {
        let days_by_key = self.lock();
        let mut tallies_by_model = TalliesByModel::new();
        for (model, tally) in tallies_since(&days_by_key, key, since) {
            *tallies_by_model.entry(model.clone()).or_default() += *tally;
        }
        tallies_by_model
    }

    pub fn month(&self, month: Month) -> TalliesByKey {
        let days_by_key = self.lock();
        let mut tallies_by_key = TalliesByKey::new();
        for (key, days) in &*days_by_key {
            let tallies = days.range(month.days()).flat_map(|(_, tallies)| tallies);
            for (model, tally) in tallies {
                let tallies_of_key = tallies_by_key.entry(key.clone()).or_default();
                *tallies_of_key.entry(model.clone()).or_default() += *tally;
            }
        }
        tallies_by_key
    }

    pub fn months(&self) -> BTreeSet<Month> {
        let days_by_key = self.lock();
        let days = days_by_key.values().flat_map(BTreeMap::keys);
        days.map(|day| Month::of(*day))
            .chain([Month::now()])
            .collect()
    }

    fn lock(&self) -> MutexGuard<'_, DaysByKey> {
        self.days_by_key
            .lock()
            .expect("the ledger lock is never poisoned")
    }
}

fn add_to_provider_of(model: &str, tally: &Tally, spent: &mut SpentByProvider) {
    let provider = model
        .split_once('/')
        .map_or(model, |(provider, _)| provider);
    match spent.get_mut(provider) {
        Some(spent) => *spent += tally.cost,
        None => drop(spent.insert(provider.to_owned(), tally.cost)),
    }
}

fn tallies_since<'ledger>(
    days_by_key: &'ledger DaysByKey,
    key: &str,
    since: NaiveDate,
) -> impl Iterator<Item = (&'ledger Arc<str>, &'ledger Tally)> {
    let days = days_by_key.get(key).into_iter();
    days.flat_map(move |days| days.range(since..).flat_map(|(_, tallies)| tallies))
}
