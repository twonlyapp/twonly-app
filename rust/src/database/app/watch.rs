//! Snapshot watches subscribe before reading and retain invalidations arriving
//! during evaluation. All database connections are released between snapshots.

use super::AppDatabase;
use crate::error::Result;
use std::future::Future;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::broadcast::error::RecvError;
use tokio::sync::RwLock;
use tokio_util::sync::CancellationToken;

pub async fn snapshots<T, Q, F, E>(
    databases: Arc<RwLock<Arc<AppDatabase>>>, dependencies: &'static [&'static str],
    cancellation: CancellationToken, query: Q, emit: E,
) -> Result<()>
where
    T: Clone + PartialEq,
    Q: Fn(Arc<AppDatabase>) -> F,
    F: Future<Output = Result<T>>,
    E: Fn(T) -> bool,
{
    loop {
        if cancellation.is_cancelled() {
            return Ok(());
        }

        let database = databases.read().await.clone();

        let mut changes = database.subscribe();

        let original = Arc::downgrade(&database);

        drop(database);

        let mut previous = None;

        let mut lifecycle_check = tokio::time::interval(Duration::from_millis(250));

        'evaluate: loop {
            let current = databases.read().await.clone();

            if original.as_ptr() != Arc::as_ptr(&current) {
                break;
            }

            if current.pool.is_closed() || current.operations.suspended() {
                drop(current);

                tokio::select! {
                    _ = cancellation.cancelled() => return Ok(()),
                    _ = lifecycle_check.tick() => continue,
                }
            }

            let operations = current.operations.clone();

            let result = tokio::select! {
                _ = cancellation.cancelled() => return Ok(()),
                result = query(current) => result,
            };

            let value = match result {
                Err(crate::TwonlyError::SqliteError(sqlx::Error::PoolClosed)) => continue,
                Err(_) if operations.suspended() => continue,
                other => other?,
            };

            if previous.as_ref() != Some(&value) {
                previous = Some(value.clone());

                if !emit(value) {
                    return Ok(());
                }
            }

            loop {
                tokio::select! {
                    _ = cancellation.cancelled() => return Ok(()),
                    _ = lifecycle_check.tick() => {
                        let latest = databases.read().await.clone();
                        if original.as_ptr() != Arc::as_ptr(&latest) { break 'evaluate; }
                        if !latest.pool.is_closed() && !latest.operations.suspended() {
                            tokio::select! {
                                _ = cancellation.cancelled() => return Ok(()),
                                result = latest.poll_external_changes() => {
                                    if let Err(error) = result {
                                        if !latest.pool.is_closed() && !latest.operations.suspended() { return Err(error); }
                                    }
                                }
                            }
                        }
                    }
                    change = changes.recv() => match change {
                        Ok(change) if change.tables.is_empty() || change.tables.iter().any(|table| dependencies.contains(&table.as_str())) => {
                            // One fresh evaluation covers the whole queued burst.
                            while changes.try_recv().is_ok() {}
                            continue 'evaluate;
                        }
                        Ok(_) => {},
                        Err(RecvError::Lagged(_)) => continue 'evaluate,
                        Err(RecvError::Closed) => break 'evaluate,
                    }
                }
            }
        }
    }
}

#[cfg(test)]

mod refresh_tests {

    use super::*;
    use sqlx::SqlitePool;

    #[tokio::test]

    async fn watches_pause_across_close_and_native_ownership_then_resume_on_the_new_pool() {
        use crate::database::lifecycle::Operation;
        use std::sync::atomic::{AtomicUsize, Ordering};

        let directory = tempfile::tempdir().unwrap();

        let foreground = Operation::foreground();

        let database = Arc::new(
            foreground
                .scope(AppDatabase::new(
                    directory.path().join("watch.sqlite").to_str().unwrap(),
                    None,
                    false,
                ))
                .await
                .unwrap(),
        );

        foreground.scope(database.run_migrations()).await.unwrap();

        let databases = Arc::new(RwLock::new(database.clone()));

        let watching = databases.clone();

        let cancellation = CancellationToken::new();

        let stop = cancellation.clone();

        let evaluations = Arc::new(AtomicUsize::new(0));

        let observed = evaluations.clone();

        let (sender, mut receiver) = tokio::sync::mpsc::unbounded_channel();

        let task = tokio::spawn(async move {
            snapshots(
                watching,
                &["contacts"],
                stop,
                move |database| {
                    observed.fetch_add(1, Ordering::AcqRel);

                    async move {
                        Ok(sqlx::query_scalar!("SELECT COUNT(*) FROM contacts")
                            .fetch_one(&database.pool)
                            .await?)
                    }
                },
                move |value| sender.send(value).is_ok(),
            )
            .await
        });

        assert_eq!(receiver.recv().await, Some(0));

        foreground.cancel();

        database.pool.close().await;

        foreground.drain().await;

        let native_operation = Operation::new(Duration::from_secs(10));

        let native = Arc::new(native_operation.scope(database.reopen()).await.unwrap());

        *databases.write().await = native.clone();

        // An unscoped UI callback must be rejected even if it bypasses the
        // watch registry and reaches this pool while the native run owns it.
        assert!(sqlx::query_scalar!("SELECT COUNT(*) FROM contacts")
            .fetch_one(&native.pool)
            .await
            .is_err());

        native_operation
            .scope(async {
                sqlx::query!("INSERT INTO contacts(user_id, username) VALUES (7, 'native-watch')")
                    .execute(&native.pool)
                    .await
                    .unwrap();
            })
            .await;

        native.refresh_watches();

        // More than one watch cadence: no evaluation may borrow native-owned
        // pools merely because this process still contains a Flutter stream.
        assert!(
            tokio::time::timeout(Duration::from_millis(600), receiver.recv())
                .await
                .is_err()
        );

        assert!(!task.is_finished());

        assert_eq!(evaluations.load(Ordering::Acquire), 1);

        native_operation.cancel();

        native.pool.close().await;

        native_operation.drain().await;

        let resumed_operation = Operation::foreground();

        let resumed = Arc::new(resumed_operation.scope(native.reopen()).await.unwrap());

        *databases.write().await = resumed.clone();

        resumed.refresh_watches();

        assert_eq!(
            tokio::time::timeout(Duration::from_secs(2), receiver.recv())
                .await
                .unwrap(),
            Some(1)
        );

        cancellation.cancel();

        task.await.unwrap().unwrap();

        resumed_operation.cancel();

        resumed.pool.close().await;

        resumed_operation.drain().await;
    }

    #[tokio::test]

    async fn polling_observes_external_commits_without_manual_refresh_or_duplicate_results() {
        let directory = tempfile::tempdir().unwrap();

        let path = directory.path().join("app.sqlite");

        let database = Arc::new(
            AppDatabase::new(path.to_str().unwrap(), None, false)
                .await
                .unwrap(),
        );

        database.run_migrations().await.unwrap();

        let databases = Arc::new(RwLock::new(database.clone()));

        let cancellation = CancellationToken::new();

        let (sender, mut receiver) = tokio::sync::mpsc::unbounded_channel();

        let stop = cancellation.clone();

        let task = tokio::spawn(async move {
            snapshots(
                databases,
                &["contacts"],
                stop,
                |database| async move {
                    Ok(
                        sqlx::query_scalar::<_, i64>("SELECT COUNT(*) FROM contacts")
                            .fetch_one(&database.pool)
                            .await?,
                    )
                },
                move |value| sender.send(value).is_ok(),
            )
            .await
        });

        assert_eq!(receiver.recv().await, Some(0));

        let external = SqlitePool::connect(&format!("sqlite://{}", path.display()))
            .await
            .unwrap();

        sqlx::query("INSERT INTO contacts(user_id, username) VALUES (7, 'background')")
            .execute(&external)
            .await
            .unwrap();

        assert_eq!(
            tokio::time::timeout(Duration::from_secs(2), receiver.recv())
                .await
                .unwrap(),
            Some(1)
        );

        database.refresh_watches();

        assert!(
            tokio::time::timeout(Duration::from_millis(20), receiver.recv())
                .await
                .is_err()
        );

        cancellation.cancel();

        tokio::time::timeout(Duration::from_secs(1), task)
            .await
            .unwrap()
            .unwrap()
            .unwrap();

        external.close().await;

        database.pool.close().await;
    }
}
