use std::{
    collections::BTreeMap,
    iter,
    path::Path,
    sync::{Arc, mpsc},
    thread,
};

use anyhow::{Context, Result};
use chrono::{Datelike, NaiveDate};
use redb::{Database, ReadableDatabase, ReadableTable, TableDefinition};

use crate::{
    keys::StoredKey,
    ledger::{DaysByKey, Tally, TallyRow},
};

const TALLIES: TableDefinition<(i32, &str, &str), TallyRow> = TableDefinition::new("tallies");
const KEYS: TableDefinition<&str, &[u8]> = TableDefinition::new("keys");

#[derive(Clone)]
pub struct Store {
    database: Arc<Database>,
    writes: mpsc::Sender<Write>,
}

pub enum Write {
    Tally {
        day: NaiveDate,
        key: Arc<str>,
        model: Arc<str>,
        tally: Tally,
    },
    Key {
        name: Arc<str>,
        key: StoredKey,
    },
    RevokedKey {
        name: Arc<str>,
    },
    Flush(mpsc::Sender<()>),
}

impl Store {
    pub fn open(file: &Path) -> Result<Self> {
        let database = Database::create(file)
            .with_context(|| format!("opening the store {}", file.display()))?;
        let creating_tables = database.begin_write()?;
        creating_tables.open_table(TALLIES)?;
        creating_tables.open_table(KEYS)?;
        creating_tables.commit()?;

        let database = Arc::new(database);
        let (writes, received) = mpsc::channel();
        thread::Builder::new()
            .name("store".to_owned())
            .spawn({
                let database = database.clone();
                move || write_batches(&database, &received)
            })
            .context("starting the store's writer")?;
        Ok(Self { database, writes })
    }

    pub fn tallies(&self) -> Result<DaysByKey> {
        let table = self.database.begin_read()?.open_table(TALLIES)?;
        let mut days_by_key = DaysByKey::new();
        for row in table.iter()? {
            let (name, row) = row?;
            let (days_from_common_era, key, model) = name.value();
            let day = NaiveDate::from_num_days_from_ce_opt(days_from_common_era)
                .context("a tally's day is out of range")?;
            let days = days_by_key.entry(key.into()).or_default();
            let tallies = days.entry(day).or_default();
            tallies.insert(model.into(), Tally::from_row(row.value()));
        }
        Ok(days_by_key)
    }

    pub fn keys(&self) -> Result<BTreeMap<String, StoredKey>> {
        let table = self.database.begin_read()?.open_table(KEYS)?;
        let mut keys = BTreeMap::new();
        for row in table.iter()? {
            let (name, key) = row?;
            let key = serde_json::from_slice(key.value())
                .with_context(|| format!("reading the key {}", name.value()))?;
            keys.insert(name.value().to_owned(), key);
        }
        Ok(keys)
    }

    pub fn write(&self, write: Write) {
        let _ = self.writes.send(write);
    }

    pub fn flush(&self) {
        let (written, flushed) = mpsc::channel();
        self.write(Write::Flush(written));
        let _ = flushed.recv();
    }
}

fn write_batches(database: &Database, received: &mpsc::Receiver<Write>) {
    while let Ok(first) = received.recv() {
        let batch: Vec<Write> = iter::once(first).chain(received.try_iter()).collect();
        if let Err(error) = write_batch(database, &batch) {
            tracing::error!(%error, "the store was not written; stopping so that the service starts again");
            std::process::exit(1);
        }
        for write in batch {
            if let Write::Flush(written) = write {
                let _ = written.send(());
            }
        }
    }
}

fn write_batch(database: &Database, batch: &[Write]) -> Result<()> {
    let transaction = database.begin_write()?;
    {
        let mut tallies = transaction.open_table(TALLIES)?;
        let mut keys = transaction.open_table(KEYS)?;
        for write in batch {
            match write {
                Write::Tally {
                    day,
                    key,
                    model,
                    tally,
                } => {
                    tallies.insert((day.num_days_from_ce(), &**key, &**model), tally.row())?;
                }
                Write::Key { name, key } => {
                    keys.insert(&**name, &*serde_json::to_vec(key)?)?;
                }
                Write::RevokedKey { name } => {
                    keys.remove(&**name)?;
                }
                Write::Flush(_) => {}
            }
        }
    }
    transaction.commit()?;
    Ok(())
}
