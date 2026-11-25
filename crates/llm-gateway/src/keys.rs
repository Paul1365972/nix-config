use std::{
    collections::BTreeMap,
    fmt::Write as _,
    sync::{
        Arc, Mutex, MutexGuard, RwLock, RwLockReadGuard, RwLockWriteGuard,
        atomic::{AtomicUsize, Ordering},
    },
};

use anyhow::{Context, Result};
use chrono::{Datelike, Days, Months, NaiveDate, Weekday};
use ring::{
    digest::{SHA256, digest},
    rand::{SecureRandom, SystemRandom},
};
use serde::{Deserialize, Serialize};
use thiserror::Error;

use crate::{
    ledger::today,
    price::MicroUsd,
    store::{Store, Write},
};

const TOKEN_SECRET_BYTES: usize = 16;
const NAME_LIMIT_BYTES: usize = 64;
const LIMIT_REQUESTS_AT_ONCE_MAXIMUM: usize = 1024;

pub type Token = String;

#[derive(Debug, Clone, Copy, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum LimitResets {
    Daily,
    Weekly,
    Monthly,
    Never,
}

impl LimitResets {
    pub fn period(self) -> &'static str {
        match self {
            Self::Daily => "today",
            Self::Weekly => "this week",
            Self::Monthly => "this month",
            Self::Never => "in total",
        }
    }

    fn period_start(self, today: NaiveDate) -> NaiveDate {
        match self {
            Self::Daily => today,
            Self::Weekly => today.week(Weekday::Mon).first_day(),
            Self::Monthly => today.with_day(1).expect("every month has a first day"),
            Self::Never => NaiveDate::MIN,
        }
    }

    fn next_period_start(self, today: NaiveDate) -> Option<NaiveDate> {
        let period_start = self.period_start(today);
        match self {
            Self::Daily => period_start.checked_add_days(Days::new(1)),
            Self::Weekly => period_start.checked_add_days(Days::new(7)),
            Self::Monthly => period_start.checked_add_months(Months::new(1)),
            Self::Never => None,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct KeySettings {
    pub limit_usd: f64,
    #[serde(default)]
    pub limit_usd_by_provider: BTreeMap<String, f64>,
    pub limit_resets: LimitResets,
    pub limit_requests_at_once: usize,
}

impl KeySettings {
    fn check(&self) -> Result<(), KeyError> {
        let is_amount = |usd: &f64| usd.is_finite() && *usd >= 0.0;
        let mut limits =
            std::iter::once(&self.limit_usd).chain(self.limit_usd_by_provider.values());
        let is_valid = limits.all(is_amount)
            && (1..=LIMIT_REQUESTS_AT_ONCE_MAXIMUM).contains(&self.limit_requests_at_once);
        is_valid.then_some(()).ok_or(KeyError::InvalidSettings)
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StoredKey {
    token: Token,
    #[serde(default)]
    is_revoked: bool,
    #[serde(flatten)]
    settings: KeySettings,
}

pub struct Key {
    pub name: Arc<str>,
    pub settings: KeySettings,
    pub token: Token,
    pub is_revoked: bool,
    token_sha256: String,
    running_requests: Arc<AtomicUsize>,
}

impl Key {
    fn new(name: Arc<str>, settings: KeySettings, token: Token, is_revoked: bool) -> Self {
        Self {
            name,
            settings,
            token_sha256: sha256_hex(&token),
            token,
            is_revoked,
            running_requests: Arc::default(),
        }
    }

    fn changed(&self, settings: KeySettings, is_revoked: bool) -> Self {
        Self {
            name: self.name.clone(),
            settings,
            token: self.token.clone(),
            is_revoked,
            token_sha256: self.token_sha256.clone(),
            running_requests: self.running_requests.clone(),
        }
    }

    pub fn limit(&self) -> MicroUsd {
        MicroUsd::from_usd(self.settings.limit_usd)
    }

    pub fn limit_of_provider(&self, provider: &str) -> Option<MicroUsd> {
        let limit = self.settings.limit_usd_by_provider.get(provider)?;
        Some(MicroUsd::from_usd(*limit))
    }

    pub fn token_prefix_and_secret(&self) -> (&str, &str) {
        let secret_start = self.token.rfind('-').map_or(0, |dash| dash + 1);
        self.token.split_at(secret_start)
    }

    pub fn period_start(&self) -> NaiveDate {
        self.settings.limit_resets.period_start(today())
    }

    pub fn limit_resets_on(&self) -> Option<NaiveDate> {
        self.settings.limit_resets.next_period_start(today())
    }

    pub fn run_request(&self) -> Option<RunningRequest> {
        let limit = self.settings.limit_requests_at_once;
        let one_more_below_limit = |running: usize| (running < limit).then_some(running + 1);
        self.running_requests
            .try_update(Ordering::Relaxed, Ordering::Relaxed, one_more_below_limit)
            .ok()?;
        Some(RunningRequest {
            running_requests_of_key: self.running_requests.clone(),
        })
    }

    pub fn running_requests(&self) -> usize {
        self.running_requests.load(Ordering::Relaxed)
    }
}

pub struct RunningRequest {
    running_requests_of_key: Arc<AtomicUsize>,
}

impl Drop for RunningRequest {
    fn drop(&mut self) {
        self.running_requests_of_key.fetch_sub(1, Ordering::Relaxed);
    }
}

#[derive(Debug, Error)]
pub enum KeyError {
    #[error(
        "A key's name starts with a letter or digit and holds up to {NAME_LIMIT_BYTES} letters, digits, dashes, underscores and dots."
    )]
    InvalidName,
    #[error(
        "A key needs limits of zero or more, and may run between 1 and {LIMIT_REQUESTS_AT_ONCE_MAXIMUM} requests at once."
    )]
    InvalidSettings,
    #[error("A key of this name exists.")]
    NameTaken,
    #[error("No key has this name.")]
    NotFound,
}

type KeysByName = BTreeMap<Arc<str>, Arc<Key>>;

pub struct Keys {
    store: Store,
    token_prefix: String,
    by_name: RwLock<KeysByName>,
    one_change_at_a_time: Mutex<()>,
}

impl Keys {
    pub fn load(store: Store, public_host: &str) -> Result<Self> {
        let stored = store.keys().context("reading the keys")?;
        let by_name = stored.into_iter().map(|(name, stored)| {
            let name: Arc<str> = name.into();
            let key = Key::new(
                name.clone(),
                stored.settings,
                stored.token,
                stored.is_revoked,
            );
            (name, Arc::new(key))
        });
        Ok(Self {
            by_name: RwLock::new(by_name.collect()),
            store,
            token_prefix: public_host.replace('.', "-"),
            one_change_at_a_time: Mutex::new(()),
        })
    }

    pub fn all(&self) -> Vec<Arc<Key>> {
        self.read().values().cloned().collect()
    }

    pub fn named(&self, name: &str) -> Option<Arc<Key>> {
        self.read().get(name).cloned()
    }

    pub fn with_token(&self, token: &str) -> Option<Arc<Key>> {
        let token_sha256 = sha256_hex(token);
        let keys = self.read();
        let mut keys = keys.values();
        keys.find(|key| !key.is_revoked && key.token_sha256 == token_sha256)
            .cloned()
    }

    pub fn create(&self, name: &str, settings: KeySettings) -> Result<Token, KeyError> {
        let is_name_character = |byte: u8| byte.is_ascii_alphanumeric() || b"-_.".contains(&byte);
        let starts_with_letter_or_digit =
            name.starts_with(|first: char| first.is_ascii_alphanumeric());
        let is_valid_name = starts_with_letter_or_digit
            && name.len() <= NAME_LIMIT_BYTES
            && name.bytes().all(is_name_character);
        if !is_valid_name {
            return Err(KeyError::InvalidName);
        }
        settings.check()?;
        let mut secret = [0; TOKEN_SECRET_BYTES];
        let random = SystemRandom::new();
        random
            .fill(&mut secret)
            .expect("the system gives random bytes");
        let token = format!("{}-{}", self.token_prefix, hex(&secret));

        let _change = self.lock_changes();
        if self.read().contains_key(name) {
            return Err(KeyError::NameTaken);
        }
        self.store_then_publish(Key::new(name.into(), settings, token.clone(), false));
        Ok(token)
    }

    pub fn update(&self, name: &str, settings: KeySettings) -> Result<(), KeyError> {
        settings.check()?;
        self.change(name, |key| key.changed(settings, key.is_revoked))
    }

    pub fn revoke(&self, name: &str) -> Result<(), KeyError> {
        self.change(name, |key| key.changed(key.settings.clone(), true))
    }

    pub fn restore(&self, name: &str) -> Result<(), KeyError> {
        self.change(name, |key| key.changed(key.settings.clone(), false))
    }

    pub fn delete(&self, name: &str) -> Result<(), KeyError> {
        let _change = self.lock_changes();
        let key = self.write().remove(name).ok_or(KeyError::NotFound)?;
        self.store.write(Write::DeletedKey {
            name: key.name.clone(),
        });
        self.store.flush();
        Ok(())
    }

    fn change(&self, name: &str, changed: impl FnOnce(&Key) -> Key) -> Result<(), KeyError> {
        let _change = self.lock_changes();
        let key = self.named(name).ok_or(KeyError::NotFound)?;
        self.store_then_publish(changed(&key));
        Ok(())
    }

    fn store_then_publish(&self, key: Key) {
        self.store.write(Write::Key {
            name: key.name.clone(),
            key: StoredKey {
                token: key.token.clone(),
                is_revoked: key.is_revoked,
                settings: key.settings.clone(),
            },
        });
        self.store.flush();
        self.write().insert(key.name.clone(), Arc::new(key));
    }

    fn lock_changes(&self) -> MutexGuard<'_, ()> {
        self.one_change_at_a_time
            .lock()
            .expect("the changes lock is never poisoned")
    }

    fn read(&self) -> RwLockReadGuard<'_, KeysByName> {
        self.by_name
            .read()
            .expect("the keys lock is never poisoned")
    }

    fn write(&self) -> RwLockWriteGuard<'_, KeysByName> {
        self.by_name
            .write()
            .expect("the keys lock is never poisoned")
    }
}

fn sha256_hex(token: &str) -> String {
    hex(digest(&SHA256, token.as_bytes()).as_ref())
}

fn hex(bytes: &[u8]) -> String {
    bytes.iter().fold(String::new(), |mut hex, byte| {
        let _ = write!(hex, "{byte:02x}");
        hex
    })
}
