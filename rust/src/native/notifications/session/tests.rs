use super::*;
use crate::database::app::AppDatabase;
use sqlx::{Connection, Executor, SqlitePool};
use std::sync::atomic::{AtomicBool, Ordering};
use tokio::sync::oneshot;

fn fixture_session(budget: Duration) -> (Arc<Session>, Arc<Mutex<Vec<SqlitePool>>>) {
    let pools = Arc::new(Mutex::new(Vec::<SqlitePool>::new()));

    let owned = pools.clone();

    let session = Session::start_on(
        &tokio::runtime::Handle::current(),
        budget,
        crate::log::LogSource::Notification,
        move |_| async move {
            let pools = owned.lock().unwrap().clone();

            for pool in pools {
                pool.close().await;
            }

            Ok(())
        },
    );

    (session, pools)
}

async fn open_database(
    session: &Session, pools: &Mutex<Vec<SqlitePool>>, path: &std::path::Path,
) -> Arc<AppDatabase> {
    session
        .execute(
            async {
                let database =
                    Arc::new(AppDatabase::new(path.to_str().unwrap(), None, false).await?);

                // Register before migrations so a setup failure still closes the pool.
                pools.lock().unwrap().push(database.pool.clone());

                database.run_migrations().await?;

                Ok(database)
            },
            false,
        )
        .await
        .unwrap()
}

async fn wait_closed(session: &Session) {
    tokio::time::timeout(Duration::from_secs(3), async {
        let mut phase = session.phase.subscribe();

        loop {
            if matches!(*phase.borrow_and_update(), Phase::Closed(_)) {
                return;
            }

            phase.changed().await.unwrap();
        }
    })
    .await
    .unwrap();
}

#[tokio::test]
async fn finalization_after_cancellation_returns_the_closing_response_without_running_work() {
    let (session, _) = fixture_session(Duration::from_secs(5));
    session.execute(async { Ok(()) }, false).await.unwrap();
    session.operation.cancel();
    wait_closed(&session).await;

    let result: Result<()> = session
        .execute(async { panic!("cancelled maintenance must not run") }, true)
        .await;
    assert_eq!(
        result.unwrap_err().to_string(),
        "Notification run is closing"
    );
}

#[tokio::test]

async fn execution_and_cleanup_keep_their_source() {
    for source in [
        crate::log::LogSource::Notification,
        crate::log::LogSource::ForegroundService,
    ] {
        let session = Session::start_on(
            &tokio::runtime::Handle::current(),
            Duration::from_secs(5),
            source,
            move |_| async move {
                assert_eq!(crate::log::current_log_source(), source);

                Ok(())
            },
        );

        session
            .execute(
                async {
                    assert_eq!(crate::log::current_log_source(), source);

                    Ok(())
                },
                false,
            )
            .await
            .unwrap();

        session.finish().await.unwrap();
    }
}

#[tokio::test]
async fn notification_preempts_native_maintenance_but_preserves_other_pushes() {
    let maintenance =
        Operation::with_log_source(Duration::from_secs(30), crate::log::LogSource::Background);
    let lease = Lease::external(maintenance.clone());
    let permit = native_admission(&maintenance).await.unwrap();
    crate::native::background::MAINTENANCE_RUNS
        .lock()
        .unwrap()
        .insert(lease.id());
    // A send being prepared shares the Background source but is not maintenance.
    let send =
        Operation::with_log_source(Duration::from_secs(30), crate::log::LogSource::Background);
    let _send_lease = Lease::external(send.clone());

    let run = crate::native::notifications::twonly_notification_run_create(5_000);
    crate::native::background::MAINTENANCE_RUNS
        .lock()
        .unwrap()
        .remove(&lease.id());
    let session = Session::find(run).unwrap();
    assert!(maintenance.cancelled());
    assert!(
        !send.cancelled(),
        "a push must not cancel a send's preparation"
    );
    assert!(!session.operation.cancelled());

    // Preemption does not steal a live job's handles. Admission remains held
    // until its supervisor has actually finished cleanup.
    assert!(matches!(*session.phase.borrow(), Phase::Queued));
    drop(permit);
    session.execute(async { Ok(()) }, false).await.unwrap();
    session.finish().await.unwrap();
}

#[tokio::test]

async fn cancellation_does_not_abandon_an_initialization_phase() {
    let (session, _) = fixture_session(Duration::from_secs(5));

    let (started, initializing) = oneshot::channel();

    let (finish, allowed) = oneshot::channel();

    let owned = session.clone();

    let initializing_task = tokio::spawn(async move {
        owned
            .execute(
                async {
                    started.send(()).unwrap();

                    allowed.await.unwrap();

                    Ok(())
                },
                false,
            )
            .await
    });

    initializing.await.unwrap();

    crate::database::lifecycle::twonly_database_operation_cancel(session.id);

    let owned = session.clone();

    let finishing = tokio::spawn(async move { owned.finish().await });

    tokio::task::yield_now().await;

    assert!(!initializing_task.is_finished());

    assert!(!finishing.is_finished());

    finish.send(()).unwrap();

    initializing_task.await.unwrap().unwrap();

    finishing.await.unwrap().unwrap();
}

#[tokio::test]

async fn missing_finalization_closes_pools_at_the_original_deadline() {
    let directory = tempfile::tempdir().unwrap();

    let path = directory.path().join("notification.sqlite");

    // The budget also covers waiting for the process-wide native admission,
    // which parallel lib tests hold for up to a second. wait_closed allows 3s.
    let (session, pools) = fixture_session(Duration::from_secs(2));

    let database = open_database(&session, &pools, &path).await;

    session
        .execute(
            async {
                sqlx::query!(
                    "INSERT INTO app_metadata(key, value) VALUES ('notification-persist', \
                     'committed')"
                )
                .execute(&database.pool)
                .await?;

                Ok(())
            },
            true,
        )
        .await
        .unwrap();

    // The platform got its batch, then never called acknowledge or finalize.
    wait_closed(&session).await;

    assert!(database.pool.is_closed());

    assert!(Session::find(session.id).is_err());

    let reopened = AppDatabase::new(path.to_str().unwrap(), None, false)
        .await
        .unwrap();

    assert_eq!(
        sqlx::query_scalar!("SELECT value FROM app_metadata WHERE key = 'notification-persist'")
            .fetch_one(&reopened.pool)
            .await
            .unwrap(),
        "committed"
    );

    reopened.pool.close().await;
}

#[tokio::test]

async fn expiration_interrupts_an_executing_write_and_waits_for_rollback_and_close() {
    let directory = tempfile::tempdir().unwrap();

    let path = directory.path().join("notification.sqlite");

    let (session, pools) = fixture_session(Duration::from_secs(5));

    let database = open_database(&session, &pools, &path).await;

    let owned = session.clone();

    let pool = database.pool.clone();

    let (started, executing) = oneshot::channel();

    let worker = tokio::spawn(async move {
        owned
            .execute(
                async {
                    let mut connection = pool.acquire().await?;

                    let mut started = Some(started);

                    connection.lock_handle().await?.set_update_hook(move |_| {
                        if let Some(started) = started.take() {
                            let _ = started.send(());
                        }
                    });

                    sqlx::query!(
                        r#"
                WITH RECURSIVE rows(n) AS (
                    VALUES(1) UNION ALL SELECT n + 1 FROM rows WHERE n < 10000000
                )
                INSERT INTO app_metadata(key, value)
                SELECT 'notification-interrupt-' || n, 'must-roll-back' FROM rows
                "#,
                    )
                    .execute(&mut *connection)
                    .await?;

                    Ok(())
                },
                true,
            )
            .await
    });

    executing.await.unwrap();

    crate::database::lifecycle::twonly_database_operation_cancel(session.id);

    assert!(tokio::time::timeout(Duration::from_secs(3), worker)
        .await
        .unwrap()
        .unwrap()
        .is_err());

    assert!(database.pool.is_closed());

    let mut probe = sqlx::SqliteConnection::connect(&format!("sqlite://{}", path.display()))
        .await
        .unwrap();

    probe.execute("BEGIN EXCLUSIVE").await.unwrap();

    assert_eq!(
        sqlx::query_scalar!(
            "SELECT COUNT(*) FROM app_metadata WHERE key LIKE 'notification-interrupt-%'"
        )
        .fetch_one(&mut probe)
        .await
        .unwrap(),
        0
    );

    probe.execute("ROLLBACK").await.unwrap();

    probe.close().await.unwrap();
}

#[tokio::test]

async fn a_cancelled_queued_push_never_starts_and_cannot_cancel_the_next_owner() {
    let (blocker, _) = fixture_session(Duration::from_secs(5));

    blocker.ready().await.unwrap();

    let (queued, _) = fixture_session(Duration::from_secs(5));

    let started = Arc::new(AtomicBool::new(false));

    let observed = started.clone();

    crate::database::lifecycle::twonly_database_operation_cancel(queued.id);

    assert!(queued
        .execute(
            async move {
                observed.store(true, Ordering::Release);

                Ok(())
            },
            true
        )
        .await
        .is_err());

    assert!(!started.load(Ordering::Acquire));

    blocker.finish().await.unwrap();

    let (next, _) = fixture_session(Duration::from_secs(5));

    crate::database::lifecycle::twonly_database_operation_cancel(queued.id);

    assert_eq!(next.execute(async { Ok(42) }, true).await.unwrap(), 42);

    next.finish().await.unwrap();
}

#[tokio::test]

async fn completion_waits_for_cleanup_and_releases_native_admission() {
    let (cleaning, started) = oneshot::channel();

    let (release, allowed) = oneshot::channel();

    let session = Session::start_on(
        &tokio::runtime::Handle::current(),
        Duration::from_secs(5),
        crate::log::LogSource::Notification,
        move |_| async move {
            cleaning.send(()).unwrap();

            allowed.await.unwrap();

            Ok(())
        },
    );

    session.ready().await.unwrap();

    let pending = session.clone();

    let finishing = tokio::spawn(async move { pending.finish().await });

    started.await.unwrap();

    assert!(!finishing.is_finished());

    let (next, _) = fixture_session(Duration::from_secs(5));

    assert!(matches!(*next.phase.borrow(), Phase::Queued));

    release.send(()).unwrap();

    finishing.await.unwrap().unwrap();

    next.ready().await.unwrap();

    next.finish().await.unwrap();
}

#[tokio::test]

async fn a_panicking_phase_rolls_back_and_closes_before_returning_the_error() {
    let directory = tempfile::tempdir().unwrap();

    let path = directory.path().join("panic.sqlite");

    let (session, pools) = fixture_session(Duration::from_secs(5));

    let database = open_database(&session, &pools, &path).await;

    let result = session
        .execute::<()>(
            async {
                let mut transaction = database.pool.begin().await?;

                sqlx::query!(
                    "INSERT INTO app_metadata(key, value) VALUES ('notification-panic', \
                     'must-roll-back')"
                )
                .execute(&mut *transaction)
                .await?;

                panic!("injected notification failure")
            },
            true,
        )
        .await;

    assert!(result.is_err());

    assert!(database.pool.is_closed());

    let reopened = AppDatabase::new(path.to_str().unwrap(), None, false)
        .await
        .unwrap();

    assert_eq!(
        sqlx::query_scalar!("SELECT COUNT(*) FROM app_metadata WHERE key = 'notification-panic'")
            .fetch_one(&reopened.pool)
            .await
            .unwrap(),
        0
    );

    reopened.pool.close().await;
}
