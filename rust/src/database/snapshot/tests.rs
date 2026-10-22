use super::*;
use crate::database::app::AppDatabase;
use sqlx::sqlite::{SqliteConnectOptions, SqliteJournalMode, SqlitePoolOptions};
use sqlx::Connection;

#[tokio::test]

async fn cancellation_during_pool_wait_does_not_cancel_another_transaction() {
    let directory = tempfile::tempdir().unwrap();

    let database = AppDatabase::new(
        directory.path().join("source.sqlite").to_str().unwrap(),
        None,
        false,
    )
    .await
    .unwrap();

    database.run_migrations().await.unwrap();

    let mut tx = database.pool.begin().await.unwrap();

    sqlx::query!("INSERT INTO app_metadata(key, value) VALUES ('owner', 'committed')")
        .execute(&mut *tx)
        .await
        .unwrap();

    let operation = Operation::new(Duration::from_secs(10));

    let target = directory.path().join("never-started.sqlite");

    let snapshot = create(&database.pool, &target, &operation);

    tokio::pin!(snapshot);

    assert!(futures_util::poll!(snapshot.as_mut()).is_pending());

    operation.cancel();

    assert!(snapshot.await.is_err());

    assert!(!target.exists());

    tx.commit().await.unwrap();

    assert_eq!(
        sqlx::query_scalar!("SELECT value FROM app_metadata WHERE key = 'owner'")
            .fetch_one(&database.pool)
            .await
            .unwrap(),
        "committed"
    );

    database.pool.close().await;
}

#[tokio::test]

async fn a_sqlite_lock_wait_respects_the_operation_deadline() {
    let directory = tempfile::tempdir().unwrap();

    let pool = SqlitePoolOptions::new()
        .max_connections(2)
        .min_connections(2)
        .connect_with(
            SqliteConnectOptions::new()
                .filename(directory.path().join("source.sqlite"))
                .create_if_missing(true),
        )
        .await
        .unwrap();

    sqlx::migrate!("./src/database/app/migrations")
        .run(&pool)
        .await
        .unwrap();

    let mut blocker = pool.acquire().await.unwrap();

    sqlx::query!("BEGIN EXCLUSIVE")
        .execute(&mut *blocker)
        .await
        .unwrap();

    let target = directory.path().join("blocked.sqlite");

    let operation = Operation::new(Duration::from_millis(120));

    let result = tokio::time::timeout(Duration::from_secs(2), create(&pool, &target, &operation))
        .await
        .expect("SQLite's busy handler exceeded the cancellation budget");

    assert!(result.is_err());

    assert!(!target.exists());

    sqlx::query!("ROLLBACK")
        .execute(&mut *blocker)
        .await
        .unwrap();

    blocker.close().await.unwrap();

    pool.close().await;
}

#[tokio::test]

async fn encrypted_wal_snapshot_contains_uncheckpointed_commits_and_header_metadata() {
    let directory = tempfile::tempdir().unwrap();

    let source = directory.path().join("source.sqlite");

    let target = directory.path().join("snapshot.sqlite");

    let key = "00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff";

    let pool = SqlitePoolOptions::new()
        .max_connections(1)
        .connect_with(
            SqliteConnectOptions::new()
                .filename(&source)
                .create_if_missing(true)
                .pragma(
                    "key",
                    crate::database::cipher::KeyForm::Raw.pragma_value(key),
                )
                .journal_mode(SqliteJournalMode::Wal)
                .pragma("synchronous", "FULL")
                .pragma("wal_autocheckpoint", "0"),
        )
        .await
        .unwrap();

    sqlx::migrate!("./src/database/app/migrations")
        .run(&pool)
        .await
        .unwrap();

    sqlx::query!("PRAGMA user_version = 77")
        .execute(&pool)
        .await
        .unwrap();

    sqlx::query!("INSERT INTO app_metadata(key, value) VALUES ('wal-sentinel', 'committed')")
        .execute(&pool)
        .await
        .unwrap();

    assert!(
        directory
            .path()
            .join("source.sqlite-wal")
            .metadata()
            .unwrap()
            .len()
            > 32
    );

    create(&pool, &target, &Operation::new(Duration::from_secs(10)))
        .await
        .unwrap();

    let copy = AppDatabase::new(target.to_str().unwrap(), Some(key), true)
        .await
        .unwrap();

    assert_eq!(
        sqlx::query_scalar!("SELECT value FROM app_metadata WHERE key = 'wal-sentinel'")
            .fetch_one(&copy.pool)
            .await
            .unwrap(),
        "committed"
    );

    assert_eq!(
        sqlx::query_scalar!("PRAGMA user_version")
            .fetch_one(&copy.pool)
            .await
            .unwrap(),
        Some(77)
    );

    assert_ne!(&std::fs::read(&target).unwrap()[..16], b"SQLite format 3\0");

    copy.pool.close().await;

    assert!(
        AppDatabase::new(target.to_str().unwrap(), Some("wrong-key"), true)
            .await
            .is_err()
    );

    pool.close().await;
}

#[tokio::test]

async fn cancellation_of_an_executing_write_rolls_back_and_releases_its_lock() {
    let directory = tempfile::tempdir().unwrap();

    let path = directory.path().join("source.sqlite");

    let database = AppDatabase::new(path.to_str().unwrap(), None, false)
        .await
        .unwrap();

    database.run_migrations().await.unwrap();

    let mut connection = database.pool.acquire().await.unwrap().detach();

    let operation = Operation::new(Duration::from_secs(10));

    watch(&mut connection, &operation).await.unwrap();

    let (started, executing) = tokio::sync::oneshot::channel();

    let mut started = Some(started);

    connection
        .lock_handle()
        .await
        .unwrap()
        .set_update_hook(move |_| {
            if let Some(started) = started.take() {
                let _ = started.send(());
            }
        });

    let worker = tokio::spawn(async move {
        let result = sqlx::query!(
            r#"
                WITH RECURSIVE rows(n) AS (
                    VALUES(1) UNION ALL SELECT n + 1 FROM rows WHERE n < 10000000
                )
                INSERT INTO app_metadata(key, value)
                SELECT 'cancel-' || n, 'must-roll-back' FROM rows
            "#,
        )
        .execute(&mut connection)
        .await;

        connection.close().await.unwrap();

        result
    });

    // The first update hook proves SQLite is executing this statement.
    executing.await.unwrap();

    operation.cancel();

    assert!(tokio::time::timeout(Duration::from_secs(2), worker)
        .await
        .unwrap()
        .unwrap()
        .is_err());

    let probe = AppDatabase::new(path.to_str().unwrap(), None, false)
        .await
        .unwrap();

    let mut tx = probe.pool.begin_with("BEGIN EXCLUSIVE").await.unwrap();

    assert_eq!(
        sqlx::query_scalar!("SELECT COUNT(*) FROM app_metadata WHERE key LIKE 'cancel-%'")
            .fetch_one(&mut *tx)
            .await
            .unwrap(),
        0
    );

    tx.rollback().await.unwrap();

    probe.pool.close().await;

    database.pool.close().await;
}

#[tokio::test]

async fn refused_or_cancelled_snapshots_leave_existing_files_untouched() {
    let directory = tempfile::tempdir().unwrap();

    let database = AppDatabase::new(
        directory.path().join("source.sqlite").to_str().unwrap(),
        None,
        false,
    )
    .await
    .unwrap();

    let target = directory.path().join("existing.sqlite");

    std::fs::write(&target, b"previous-valid-backup").unwrap();

    let operation = Operation::new(Duration::from_secs(1));

    assert!(create(&database.pool, &target, &operation).await.is_err());

    operation.cancel();

    assert!(create(
        &database.pool,
        &directory.path().join("cancelled.sqlite"),
        &operation
    )
    .await
    .is_err());

    assert_eq!(std::fs::read(target).unwrap(), b"previous-valid-backup");

    assert!(!directory.path().join("cancelled.sqlite").exists());

    database.pool.close().await;
}
