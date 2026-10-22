#[cfg(feature = "sqlite-wal")]
use super::*;

#[tokio::test]

async fn shipped_engine_contains_the_wal_reset_fix() {
    assert!(unsafe { libsqlite3_sys::sqlite3_libversion_number() } >= 3_051_003);
}

#[cfg(feature = "sqlite-wal")]
#[tokio::test]

async fn readers_keep_their_snapshot_while_a_writer_commits_and_reject_writes() {
    let directory = tempfile::tempdir().unwrap();

    let key = "0101010101010101010101010101010101010101010101010101010101010101";

    let database = AppDatabase::new(
        directory.path().join("app.sqlite").to_str().unwrap(),
        Some(key),
        false,
    )
    .await
    .unwrap();

    database.run_migrations().await.unwrap();

    let mut reader = database.read_pool.begin().await.unwrap();

    assert_eq!(
        sqlx::query_scalar!("SELECT COUNT(*) FROM contacts")
            .fetch_one(&mut *reader)
            .await
            .unwrap(),
        0
    );

    let mut other_reader = database.read_pool.acquire().await.unwrap();

    assert!(
        sqlx::query!("INSERT INTO contacts(user_id, username) VALUES (7, 'background')")
            .execute(&mut *other_reader)
            .await
            .is_err()
    );

    tokio::time::timeout(
        Duration::from_secs(2),
        sqlx::query!("INSERT INTO contacts(user_id, username) VALUES (7, 'background')")
            .execute(&database.pool),
    )
    .await
    .unwrap()
    .unwrap();

    assert_eq!(
        sqlx::query_scalar!("SELECT COUNT(*) FROM contacts")
            .fetch_one(&mut *reader)
            .await
            .unwrap(),
        0
    );

    reader.commit().await.unwrap();

    assert_eq!(
        sqlx::query_scalar!("SELECT COUNT(*) FROM contacts")
            .fetch_one(&mut *other_reader)
            .await
            .unwrap(),
        1
    );

    other_reader.close().await.unwrap();

    database.close().await;

    let reopened = AppDatabase::new(
        directory.path().join("app.sqlite").to_str().unwrap(),
        Some(key),
        false,
    )
    .await
    .unwrap();

    assert_eq!(
        sqlx::query_scalar!("SELECT COUNT(*) FROM contacts")
            .fetch_one(&reopened.read_pool)
            .await
            .unwrap(),
        1
    );

    reopened.close().await;
}
