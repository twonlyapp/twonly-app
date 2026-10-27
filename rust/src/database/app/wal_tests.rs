use super::*;

#[tokio::test]

async fn normal_sync_is_applied_to_writer_readers_and_reopened_connections() {
    let directory = tempfile::tempdir().unwrap();
    let path = directory.path().join("app.sqlite");
    let key = "0101010101010101010101010101010101010101010101010101010101010101";
    let mut database = AppDatabase::new(path.to_str().unwrap(), Some(key), false)
        .await
        .unwrap();
    database.run_migrations().await.unwrap();

    for round in 0..2 {
        assert_eq!(
            sqlx::query_scalar::<_, i64>("PRAGMA synchronous")
                .fetch_one(&database.pool)
                .await
                .unwrap(),
            1
        );
        assert_eq!(
            sqlx::query_scalar::<_, String>("PRAGMA journal_mode")
                .fetch_one(&database.pool)
                .await
                .unwrap(),
            if cfg!(feature = "sqlite-wal") {
                "wal"
            } else {
                "delete"
            }
        );

        if cfg!(feature = "sqlite-wal") {
            let mut first = database.read_pool.acquire().await.unwrap();
            let mut second = database.read_pool.acquire().await.unwrap();
            for connection in [&mut first, &mut second] {
                assert_eq!(
                    sqlx::query_scalar::<_, i64>("PRAGMA synchronous")
                        .fetch_one(&mut **connection)
                        .await
                        .unwrap(),
                    1
                );
                assert_eq!(
                    sqlx::query_scalar::<_, i64>("PRAGMA query_only")
                        .fetch_one(&mut **connection)
                        .await
                        .unwrap(),
                    1
                );
            }
        }

        database.close().await;
        if round == 0 {
            database = database.reopen().await.unwrap();
        }
    }
}

#[tokio::test]

async fn close_stops_admission_before_it_is_awaited() {
    let directory = tempfile::tempdir().unwrap();
    let path = directory.path().join("app.sqlite");
    let key = "0101010101010101010101010101010101010101010101010101010101010101";
    let database = AppDatabase::new(path.to_str().unwrap(), Some(key), false)
        .await
        .unwrap();
    database.run_migrations().await.unwrap();

    // Lifecycle cleanup creates this future, then shuts the network down.
    let closing = database.close();
    assert!(database.pool.is_closed());
    assert!(database.read_pool.is_closed());
    assert!(database.pool.acquire().await.is_err());

    closing.await;
    assert_eq!(database.pool.size(), 0);
    assert_eq!(database.read_pool.size(), 0);
}

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
