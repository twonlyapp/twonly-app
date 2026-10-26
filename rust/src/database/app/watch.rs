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

fn transient(error: &crate::TwonlyError) -> bool {
    match error {
        crate::TwonlyError::SqliteError(sqlx::Error::PoolTimedOut | sqlx::Error::PoolClosed) => {
            true
        }
        crate::TwonlyError::SqliteError(sqlx::Error::Database(error)) => {
            error.code().is_some_and(|code| {
                // Extended SQLite BUSY/LOCKED codes retain the primary low byte.
                code.parse::<i32>()
                    .is_ok_and(|code| matches!(code & 0xff, 5 | 6))
            })
        }
        _ => false,
    }
}

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
    let watcher = std::any::type_name::<Q>();
    let watcher = watcher.split("::app::").nth(1).unwrap_or(watcher);
    let watcher = watcher.split("::{{closure}}").next().unwrap_or(watcher);
    let operation = format!("db.watch.{}", watcher.replace("::watches::", "."));
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

            let mut trace = crate::performance::Trace::start(&operation, "db.watch");
            let result = tokio::select! {
                _ = cancellation.cancelled() => return Ok(()),
                result = trace.scope(query(current)) => result,
            };
            trace.status(result.is_ok());

            let value = match result {
                Err(_) if operations.suspended() => continue,
                Err(error) if transient(&error) => {
                    drop(trace);
                    tracing::warn!(%error, "database watch will retry after temporary storage failure");
                    tokio::select! {
                        _ = cancellation.cancelled() => return Ok(()),
                        _ = tokio::time::sleep(Duration::from_millis(250)) => continue,
                    }
                }
                Err(error) => {
                    // Dart closes the stream with this error and never restarts
                    // it, so the screen stays empty until it is rebuilt.
                    tracing::error!(%error, ?dependencies, "database watch stopped");

                    return Err(error);
                }
                Ok(value) => value,
            };

            let changed = previous.as_ref() != Some(&value);
            trace.boolean("snapshot.changed", changed);
            if changed {
                previous = Some(value.clone());

                let mut emission = trace.child("database.snapshot.emit", "bridge.serialize");
                let accepted = emit(value);
                emission.status(accepted);
                if !accepted {
                    return Ok(());
                }
            }
            drop(trace);

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
                                        if transient(&error) { continue 'evaluate; }
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
    async fn temporary_pool_failure_retries_without_losing_the_watch() {
        use std::sync::atomic::{AtomicUsize, Ordering};
        let directory = tempfile::tempdir().unwrap();
        let database = Arc::new(
            AppDatabase::new(
                directory.path().join("retry.sqlite").to_str().unwrap(),
                None,
                false,
            )
            .await
            .unwrap(),
        );
        database.run_migrations().await.unwrap();
        let databases = Arc::new(RwLock::new(database.clone()));
        let attempts = Arc::new(AtomicUsize::new(0));
        let counted = attempts.clone();
        let cancellation = CancellationToken::new();
        let (sent, mut received) = tokio::sync::mpsc::unbounded_channel();
        let watch = tokio::spawn(snapshots(
            databases,
            &["contacts"],
            cancellation.clone(),
            move |_| {
                let attempt = counted.fetch_add(1, Ordering::SeqCst);
                async move {
                    if attempt == 0 {
                        return Err(sqlx::Error::PoolTimedOut.into());
                    }
                    Ok(42)
                }
            },
            move |value| sent.send(value).is_ok(),
        ));
        assert_eq!(
            tokio::time::timeout(Duration::from_secs(2), received.recv())
                .await
                .unwrap(),
            Some(42)
        );
        assert_eq!(attempts.load(Ordering::SeqCst), 2);
        cancellation.cancel();
        watch.await.unwrap().unwrap();
        database.close().await;
    }

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

    #[tokio::test]

    async fn local_writes_wake_only_dependent_watches_and_external_commits_still_arrive() {
        use std::sync::atomic::{AtomicUsize, Ordering};

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

        // Like the app's watches, both read through the WAL readers only.
        let watch = |dependencies: &'static [&'static str], statement: &'static str| {
            let evaluations = Arc::new(AtomicUsize::new(0));

            let counted = evaluations.clone();

            let (sender, receiver) = tokio::sync::mpsc::unbounded_channel();

            let task = tokio::spawn(snapshots(
                databases.clone(),
                dependencies,
                cancellation.clone(),
                move |database| {
                    counted.fetch_add(1, Ordering::SeqCst);

                    async move {
                        Ok(sqlx::query_scalar::<_, i64>(statement)
                            .fetch_one(&database.read_pool)
                            .await?)
                    }
                },
                move |value| sender.send(value).is_ok(),
            ));

            (evaluations, receiver, task)
        };

        let (_, mut contacts, contacts_task) =
            watch(&["contacts"], "SELECT COUNT(*) FROM contacts");

        let (group_evaluations, mut groups, groups_task) =
            watch(&["groups"], "SELECT COUNT(*) FROM groups");

        assert_eq!(contacts.recv().await, Some(0));

        assert_eq!(groups.recv().await, Some(0));

        for user in 1..=3_i64 {
            sqlx::query("INSERT INTO contacts(user_id, username) VALUES (?, 'local')")
                .bind(user)
                .execute(&database.pool)
                .await
                .unwrap();

            assert_eq!(
                tokio::time::timeout(Duration::from_secs(2), contacts.recv())
                    .await
                    .unwrap(),
                Some(user)
            );
        }

        // Give the readers and the external-change poll time to report a
        // change they should not report.
        tokio::time::sleep(Duration::from_millis(1_200)).await;

        assert_eq!(group_evaluations.load(Ordering::SeqCst), 1);

        let external = SqlitePool::connect(&format!("sqlite://{}", path.display()))
            .await
            .unwrap();

        sqlx::query("INSERT INTO groups(group_id, group_name) VALUES ('outside', 'Outside')")
            .execute(&external)
            .await
            .unwrap();

        assert_eq!(
            tokio::time::timeout(Duration::from_secs(2), groups.recv())
                .await
                .unwrap(),
            Some(1)
        );

        // Watches now rely on the published tables alone, so rows removed by
        // a foreign key cascade must be published as well.
        sqlx::query(
            "INSERT INTO messages(message_id, group_id, type) VALUES ('m', 'outside', 'text')",
        )
        .execute(&database.pool)
        .await
        .unwrap();

        let mut changes = database.subscribe();

        sqlx::query("DELETE FROM groups WHERE group_id = 'outside'")
            .execute(&database.pool)
            .await
            .unwrap();

        let published = loop {
            let change = tokio::time::timeout(Duration::from_secs(1), changes.recv())
                .await
                .unwrap()
                .unwrap();

            if !change.tables.is_empty() {
                break change.tables;
            }
        };

        assert!(published.contains("groups"), "{published:?}");

        assert!(published.contains("messages"), "{published:?}");

        cancellation.cancel();

        for task in [contacts_task, groups_task] {
            tokio::time::timeout(Duration::from_secs(1), task)
                .await
                .unwrap()
                .unwrap()
                .unwrap();
        }

        external.close().await;

        database.close().await;
    }
}
