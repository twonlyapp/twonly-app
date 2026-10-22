//! Native hooks collect candidates; only a returned, successfully committed
//! connection publishes them. The commit hook itself runs before commit ends.

use super::DatabaseChange;
use sqlx::sqlite::UpdateHookResult;
use sqlx::SqliteConnection;
use std::collections::{BTreeSet, HashMap};
use std::sync::{Arc, Mutex, Weak};
use tokio::sync::broadcast;

#[derive(Default)]

struct Pending {
    written: BTreeSet<String>,
    committed: BTreeSet<String>,
    data_version: Option<i64>,
}

#[derive(Clone, Default)]

pub(super) struct ConnectionChanges(Arc<Mutex<HashMap<usize, Weak<Mutex<Pending>>>>>);

impl ConnectionChanges {
    pub async fn install(&self, connection: &mut SqliteConnection) -> sqlx::Result<()> {
        let mut handle = connection.lock_handle().await?;

        let pending = Arc::new(Mutex::new(Pending::default()));

        {
            let mut connections = self.0.lock().unwrap();

            connections.retain(|_, value| value.strong_count() > 0);

            connections.insert(
                handle.as_raw_handle().as_ptr() as usize,
                Arc::downgrade(&pending),
            );
        }

        let updated = pending.clone();

        handle.set_update_hook(move |result: UpdateHookResult| {
            updated
                .lock()
                .unwrap()
                .written
                .insert(result.table.to_owned());
        });

        let committed = pending.clone();

        handle.set_commit_hook(move || {
            let mut state = committed.lock().unwrap();

            let written = std::mem::take(&mut state.written);

            state.committed.extend(written);

            true
        });

        handle.set_rollback_hook(move || {
            let mut state = pending.lock().unwrap();

            state.written.clear();

            state.committed.clear();
        });

        Ok(())
    }

    pub async fn observe_external(
        &self, connection: &mut SqliteConnection, changes: &broadcast::Sender<DatabaseChange>,
    ) -> sqlx::Result<()> {
        let version = sqlx::query_scalar!("PRAGMA data_version")
            .fetch_one(&mut *connection)
            .await?;

        let mut handle = connection.lock_handle().await?;

        let pending = self
            .0
            .lock()
            .unwrap()
            .get(&(handle.as_raw_handle().as_ptr() as usize))
            .and_then(Weak::upgrade);

        if let Some(pending) = pending {
            let mut state = pending.lock().unwrap();

            // data_version is meaningful only on the same physical handle.
            // A new handle invalidates subscribers too, covering pool churn.
            if state.data_version != version {
                state.data_version = version;

                let _ = changes.send(DatabaseChange {
                    tables: BTreeSet::new(),
                });
            }
        }

        Ok(())
    }

    pub async fn release(
        &self, connection: &mut SqliteConnection, changes: &broadcast::Sender<DatabaseChange>,
    ) -> sqlx::Result<bool> {
        let mut handle = connection.lock_handle().await?;

        let native = handle.as_raw_handle();

        // SAFETY: lock_handle exclusively owns this live native connection.
        // No SQLite call or SQL execution is made from inside a native hook.
        if unsafe { libsqlite3_sys::sqlite3_get_autocommit(native.as_ptr()) } == 0 {
            // A raw BEGIN must never return an open transaction to the pool.
            // SQLx closes this connection, rolling back its uncommitted work.
            return Ok(false);
        }

        let pending = self
            .0
            .lock()
            .unwrap()
            .get(&(native.as_ptr() as usize))
            .and_then(Weak::upgrade);

        if let Some(pending) = pending {
            let tables = std::mem::take(&mut pending.lock().unwrap().committed);

            if !tables.is_empty() {
                let _ = changes.send(DatabaseChange { tables });
            }
        }

        Ok(true)
    }
}
