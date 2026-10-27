//! Names the deadlock the app database's single write connection invites.
//!
//! A task that asks for a connection while it still holds the writer -- an
//! open transaction, a `PoolConnection` -- waits for itself until the acquire
//! timeout, and every other database user waits with it. The failure only
//! reads `pool timed out`, wherever the clock ran out. Each writer records the
//! acquiring task to flag this possibility. The timed-out pool is unknown to
//! SQLx's generic error conversion, so holding a writer is not proof of a cycle.
//!
//! The check runs on the timeout, not on the request: SQLx returns released
//! connections from a spawned task, so right after a commit the writer can
//! still be recorded for a task that has already let go of it.

use std::collections::HashMap;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{LazyLock, Mutex};
use tokio::task::Id;

// Keyed per pool, so test processes that open several databases stay apart.
static HOLDERS: LazyLock<Mutex<HashMap<u64, Id>>> = LazyLock::new(Default::default);

static NEXT_WRITER: AtomicU64 = AtomicU64::new(0);

/// One writer pool's entry in [`HOLDERS`].
pub(crate) struct WriterHolder {
    key: u64,
}

impl WriterHolder {
    pub(crate) fn new() -> Self {
        Self {
            key: NEXT_WRITER.fetch_add(1, Ordering::Relaxed),
        }
    }

    pub(crate) fn acquired(&self) {
        let mut holders = HOLDERS.lock().unwrap();

        match tokio::task::try_id() {
            Some(task) => holders.insert(self.key, task),
            None => holders.remove(&self.key),
        };
    }

    pub(crate) fn released(&self) {
        HOLDERS.lock().unwrap().remove(&self.key);
    }
}

impl Drop for WriterHolder {
    fn drop(&mut self) {
        self.released();
    }
}

/// Whether the current task acquired a writer connection it has not given back.
pub(crate) fn current_task_holds_writer() -> bool {
    let Some(task) = tokio::task::try_id() else {
        return false;
    };

    HOLDERS
        .lock()
        .unwrap()
        .values()
        .any(|holder| *holder == task)
}

/// Runs for every pool timeout, in the task that timed out.
pub(crate) fn report_pool_timeout() {
    if !current_task_holds_writer() {
        return;
    }

    tracing::warn!(
        "a database pool request timed out while this task held an app database write connection; \
         check for a nested checkout of the same pool or a long transaction"
    );
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::database::app::AppDatabase;
    use std::time::Duration;

    #[tokio::test]
    async fn another_pools_timeout_remains_a_recoverable_error_while_holding_a_writer(
    ) -> anyhow::Result<()> {
        tokio::spawn(async {
            let directory = tempfile::tempdir()?;
            let db = AppDatabase::new(
                directory.path().join("app.sqlite").to_str().unwrap(),
                None,
                false,
            )
            .await?;
            let transaction = db.pool.begin().await?;
            let other = sqlx::sqlite::SqlitePoolOptions::new()
                .max_connections(1)
                .acquire_timeout(Duration::from_millis(25))
                .connect("sqlite::memory:")
                .await?;
            let pool = other.clone();
            let (ready, occupied) = tokio::sync::oneshot::channel();
            let (release, released) = tokio::sync::oneshot::channel();
            let holder = tokio::spawn(async move {
                let connection = pool.acquire().await.unwrap();
                ready.send(()).unwrap();
                let _ = released.await;
                drop(connection);
            });
            occupied.await?;
            let error = crate::TwonlyError::from(other.acquire().await.unwrap_err());
            assert!(matches!(
                error,
                crate::TwonlyError::SqliteError(sqlx::Error::PoolTimedOut)
            ));
            release.send(()).unwrap();
            holder.await?;
            transaction.rollback().await?;
            db.close().await;
            other.close().await;
            anyhow::Ok(())
        })
        .await?
    }

    async fn released_by_this_task() -> anyhow::Result<()> {
        // The connection goes back to the pool from a spawned task.
        tokio::time::timeout(Duration::from_secs(5), async {
            while current_task_holds_writer() {
                tokio::time::sleep(Duration::from_millis(10)).await;
            }
        })
        .await?;

        Ok(())
    }

    #[tokio::test]

    async fn only_the_task_inside_a_transaction_holds_the_writer() -> anyhow::Result<()> {
        // `block_on`, which runs a test body, has no task id.
        tokio::spawn(async {
            let directory = tempfile::tempdir()?;

            let db = AppDatabase::new(
                directory.path().join("app.sqlite").to_str().unwrap(),
                None,
                false,
            )
            .await?;

            // Opening the pool takes a test connection without releasing it
            // through the hook, which must not leave this task recorded.
            assert!(!current_task_holds_writer());

            let t = db.pool.begin().await?;

            assert!(current_task_holds_writer());

            let elsewhere = tokio::spawn(async { current_task_holds_writer() }).await?;

            assert!(
                !elsewhere,
                "another task does not hold this task's transaction"
            );

            t.commit().await?;

            released_by_this_task().await?;

            sqlx::query("SELECT 1").execute(&db.pool).await?;

            released_by_this_task().await
        })
        .await?
    }
}
