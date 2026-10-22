use super::*;
use tokio::sync::oneshot;

#[tokio::test]

async fn cancelled_pool_borrow_does_not_retry_or_execute_a_small_write() {
    let directory = tempfile::tempdir().unwrap();

    let database = crate::database::app::AppDatabase::new(
        directory.path().join("cancelled.sqlite").to_str().unwrap(),
        None,
        false,
    )
    .await
    .unwrap();

    database.run_migrations().await.unwrap();

    let operation = Operation::new(Duration::from_secs(5));

    operation.cancel();

    let result = tokio::time::timeout(
        Duration::from_secs(1),
        operation.scope(async {
            sqlx::query!(
                "INSERT INTO app_metadata(key, value) VALUES ('cancelled-borrow', 'must-not-run')"
            )
            .execute(&database.pool)
            .await
        }),
    )
    .await
    .unwrap();

    assert!(result.is_err());

    operation.drain().await;

    assert_eq!(
        sqlx::query_scalar!("SELECT COUNT(*) FROM app_metadata WHERE key = 'cancelled-borrow'")
            .fetch_one(&database.pool)
            .await
            .unwrap(),
        0
    );

    database.pool.close().await;
}

#[tokio::test]

async fn pool_busy_handler_stops_a_lock_wait_at_the_operation_deadline() {
    use sqlx::{Connection, Executor};

    let directory = tempfile::tempdir().unwrap();

    let path = directory.path().join("busy.sqlite");

    let database = crate::database::app::AppDatabase::new(path.to_str().unwrap(), None, false)
        .await
        .unwrap();

    database.run_migrations().await.unwrap();

    // Acquire before the external lock so this tests the installed native busy
    // callback rather than SQLx connection setup or its connection health ping.
    let operation = Operation::new(Duration::from_millis(150));

    let mut connection = operation.scope(database.pool.acquire()).await.unwrap();

    let mut locker = sqlx::SqliteConnection::connect(&format!("sqlite://{}", path.display()))
        .await
        .unwrap();

    locker.execute("BEGIN EXCLUSIVE").await.unwrap();

    let result = tokio::time::timeout(Duration::from_secs(2), async {
        sqlx::query!("INSERT INTO app_metadata(key, value) VALUES ('busy-owner', 'must-not-run')")
            .execute(&mut *connection)
            .await
    })
    .await
    .unwrap();

    assert!(result.is_err());

    connection.close().await.unwrap();

    operation.cancel();

    operation.drain().await;

    locker.execute("ROLLBACK").await.unwrap();

    locker.close().await.unwrap();

    database.pool.close().await;
}

#[tokio::test]

async fn cancelling_an_operation_joins_its_descendants_and_rejects_late_children() {
    let operation = Operation::new(Duration::from_secs(5));

    let (started, ready) = oneshot::channel();

    let expected = operation.clone();

    let child = operation
        .scope(async {
            spawn(async move {
                assert!(Arc::ptr_eq(&Operation::current().unwrap().0, &expected.0));

                started.send(()).unwrap();

                std::future::pending::<()>().await;
            })
        })
        .await;

    ready.await.unwrap();

    operation.cancel();

    tokio::time::timeout(Duration::from_secs(1), operation.drain())
        .await
        .unwrap();

    assert!(child.await.unwrap_err().is_cancelled());

    let (started, ready) = oneshot::channel();

    let late = operation
        .scope(async {
            spawn(async move {
                let _ = started.send(());
            })
        })
        .await;

    assert!(late.await.unwrap_err().is_cancelled());

    assert!(ready.await.is_err());

    operation.drain().await;
}

#[tokio::test]

async fn abandoned_blocking_work_remains_owned_until_it_finishes() {
    let operation = Operation::new(Duration::from_secs(5));

    let (started, ready) = oneshot::channel();

    let (finish, finished) = std::sync::mpsc::channel();

    let expected = operation.clone();

    let child = operation
        .scope(async {
            spawn_blocking(move || {
                assert!(Arc::ptr_eq(&Operation::current().unwrap().0, &expected.0));

                started.send(()).unwrap();

                finished.recv().unwrap();
            })
        })
        .await;

    ready.await.unwrap();

    drop(child);

    operation.cancel();

    assert!(
        tokio::time::timeout(Duration::from_millis(20), operation.drain())
            .await
            .is_err()
    );

    finish.send(()).unwrap();

    tokio::time::timeout(Duration::from_secs(1), operation.drain())
        .await
        .unwrap();
}

#[tokio::test]

async fn dropping_an_executing_query_waits_for_sqlite_before_reusing_the_connection() {
    let directory = tempfile::tempdir().unwrap();

    let database = crate::database::app::AppDatabase::new(
        directory.path().join("owned.sqlite").to_str().unwrap(),
        None,
        false,
    )
    .await
    .unwrap();

    database.run_migrations().await.unwrap();

    let operation = Operation::new(Duration::from_secs(10));

    let worker_operation = operation.clone();

    let pool = database.pool.clone();

    let (started, executing) = oneshot::channel();

    let worker = tokio::spawn(async move {
        let result = worker_operation
            .scope(async {
                tokio::select! {
                    biased;
                    _ = worker_operation.until_cancelled() => worker_operation.check(),
                    result = async {
                        let mut connection = pool.acquire().await?;
                        let mut started = Some(started);
                        connection.lock_handle().await?.set_update_hook(move |_| {
                            if let Some(started) = started.take() { let _ = started.send(()); }
                        });
                        sqlx::query!(
                            r#"
                            WITH RECURSIVE rows(n) AS (
                                VALUES(1) UNION ALL SELECT n + 1 FROM rows WHERE n < 10000000
                            )
                            INSERT INTO app_metadata(key, value)
                            SELECT 'owned-' || n, 'must-roll-back' FROM rows
                        "#,
                        ).execute(&mut *connection).await?;
                        Ok::<_, TwonlyError>(())
                    } => result,
                }
            })
            .await;

        worker_operation.cancel();

        worker_operation.drain().await;

        result
    });

    executing.await.unwrap();

    operation.cancel();

    assert!(tokio::time::timeout(Duration::from_secs(2), worker)
        .await
        .unwrap()
        .unwrap()
        .is_err());

    let mut probe = database.pool.begin_with("BEGIN EXCLUSIVE").await.unwrap();

    assert_eq!(
        sqlx::query_scalar!("SELECT COUNT(*) FROM app_metadata WHERE key LIKE 'owned-%'")
            .fetch_one(&mut *probe)
            .await
            .unwrap(),
        0
    );

    probe.rollback().await.unwrap();

    // A late cancel belongs to the old owner, never the next borrower.
    operation.cancel();

    sqlx::query!("INSERT INTO app_metadata(key, value) VALUES ('next-owner', 'works')")
        .execute(&database.pool)
        .await
        .unwrap();

    database.pool.close().await;
}

#[tokio::test]

async fn native_pool_lifetime_tickets_wait_for_actual_closure_of_both_databases() {
    let directory = tempfile::tempdir().unwrap();

    let operation = Operation::new(Duration::from_secs(10));

    let (app, signal) = operation
        .scope(async {
            let app = crate::database::app::AppDatabase::new(
                directory.path().join("app.sqlite").to_str().unwrap(),
                None,
                false,
            )
            .await
            .unwrap();

            let signal = crate::database::signal::Database::new(
                &directory
                    .path()
                    .join("signal.sqlite")
                    .to_string_lossy()
                    .to_string(),
                None,
                false,
            )
            .await
            .unwrap();

            (app, signal)
        })
        .await;

    assert!(operation.0.connections.load(Ordering::Acquire) >= 2);

    operation.cancel();

    tokio::join!(app.pool.close(), signal.pool.close());

    tokio::time::timeout(Duration::from_secs(1), operation.drain())
        .await
        .unwrap();

    assert_eq!(operation.0.connections.load(Ordering::Acquire), 0);
}

#[tokio::test]

async fn foreground_promotion_removes_the_native_pools_previous_owner() {
    let directory = tempfile::tempdir().unwrap();

    let old = Operation::new(Duration::from_secs(10));

    let database = old
        .scope(crate::database::app::AppDatabase::new(
            directory.path().join("app.sqlite").to_str().unwrap(),
            None,
            false,
        ))
        .await
        .unwrap();

    database.operations.set_default(None);

    let connection = database.pool.acquire().await.unwrap();

    old.cancel();

    tokio::time::timeout(Duration::from_secs(1), old.drain())
        .await
        .unwrap();

    drop(connection);

    database.run_migrations().await.unwrap();

    sqlx::query!("INSERT INTO app_metadata(key, value) VALUES ('promoted', 'foreground')")
        .execute(&database.pool)
        .await
        .unwrap();

    database.pool.close().await;
}

#[tokio::test]

async fn dropping_the_caller_cancels_but_keeps_the_worker_owned_until_cleanup() {
    let (started, ready) = oneshot::channel();

    let (allow_cleanup, cleanup_allowed) = oneshot::channel();

    let (done, finished) = oneshot::channel();

    let caller = tokio::spawn(run(move |operation| async move {
        let id = OPERATIONS
            .lock()
            .unwrap()
            .iter()
            .find_map(|(id, weak)| {
                weak.upgrade()
                    .filter(|state| Arc::ptr_eq(state, &operation.0))
                    .map(|_| *id)
            })
            .unwrap();

        started.send(id).unwrap();

        operation.until_cancelled().await;

        cleanup_allowed.await.unwrap();

        assert!(OPERATIONS.lock().unwrap().contains_key(&id));

        done.send(()).unwrap();

        operation.check()
    }));

    let id = ready.await.unwrap();

    caller.abort();

    assert!(caller.await.unwrap_err().is_cancelled());

    assert!(OPERATIONS.lock().unwrap().contains_key(&id));

    allow_cleanup.send(()).unwrap();

    finished.await.unwrap();

    tokio::time::timeout(Duration::from_secs(1), async {
        while OPERATIONS.lock().unwrap().contains_key(&id) {
            tokio::task::yield_now().await;
        }
    })
    .await
    .unwrap();
}

#[tokio::test]

async fn late_cancellation_cannot_cancel_a_different_operation() {
    let operation = Operation::new(Duration::from_secs(1));

    let lease = Lease::admit(operation.clone()).unwrap();

    let old_id = lease.id;

    drop(lease);

    let next = Operation::new(Duration::from_secs(1));

    let _lease = Lease::admit(next.clone()).unwrap();

    twonly_database_operation_cancel(old_id);

    assert!(!next.cancelled());

    assert!(!operation.cancelled());
}
