use super::table::MockGalleryItem;
use super::writes;
use crate::database::app::AppDatabase;

#[tokio::test]

async fn debug_batches_preserve_related_rows_and_roll_back_on_conflicts() {
    let directory = tempfile::tempdir().unwrap();

    let database = AppDatabase::new(
        directory.path().join("app.sqlite").to_str().unwrap(),
        None,
        false,
    )
    .await
    .unwrap();

    database.run_migrations().await.unwrap();

    let mut tx = database.pool.begin().await.unwrap();

    let items = || {
        (0..13)
            .map(|i| MockGalleryItem {
                created_at: i,
                month: "Januar 2024".into(),
            })
            .collect()
    };

    writes::seed_gallery(&mut tx, items(), 100).await.unwrap();

    writes::seed_gallery(&mut tx, items(), 100).await.unwrap();

    let preserved: i64 =
        sqlx::query_scalar("SELECT COUNT(*) FROM messages WHERE sender_id IS NOT NULL")
            .fetch_one(&mut *tx)
            .await
            .unwrap();

    assert_eq!(preserved, 13);

    sqlx::query(
        r#"
        INSERT INTO group_members(group_id, contact_id, member_state)
        VALUES ('mock_group_gallery', 9000000, 'normal'), ('mock_group_gallery', 9000001, 'leftGroup')
        "#,
    ).execute(&mut *tx).await.unwrap();

    assert_eq!(
        writes::seed_messages(&mut tx, "mock_group_gallery", 3, 100, "debug")
            .await
            .unwrap(),
        3
    );

    assert_eq!(
        writes::seed_messages(&mut tx, "missing", 3, 100, "empty")
            .await
            .unwrap(),
        0
    );

    let senders: Vec<i64> =
        sqlx::query_scalar("SELECT sender_id FROM messages WHERE message_id LIKE 'debug_%'")
            .fetch_all(&mut *tx)
            .await
            .unwrap();

    assert_eq!(senders, vec![9000000; 3]);

    tx.commit().await.unwrap();

    let mut tx = database.pool.begin().await.unwrap();

    assert!(
        writes::seed_messages(&mut tx, "mock_group_gallery", 4, 100, "debug")
            .await
            .is_err()
    );

    tx.rollback().await.unwrap();

    let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM messages")
        .fetch_one(&database.pool)
        .await
        .unwrap();

    assert_eq!(count, 16);
}

#[tokio::test]

async fn debug_export_preserves_encrypted_source_metadata_and_does_not_replace_files() {
    let directory = tempfile::tempdir().unwrap();

    let source = directory.path().join("app.sqlite");

    let target = directory.path().join("inspect'copy.sqlite");

    let database = AppDatabase::new(
        source.to_str().unwrap(),
        Some("00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff"),
        false,
    )
    .await
    .unwrap();

    database.run_migrations().await.unwrap();

    sqlx::query("INSERT INTO app_metadata(key, value) VALUES ('snapshot', 'committed')")
        .execute(&database.pool)
        .await
        .unwrap();

    sqlx::query("PRAGMA user_version = 77")
        .execute(&database.pool)
        .await
        .unwrap();

    writes::export_debug(&database, &target).await.unwrap();

    let copy = AppDatabase::new(
        target.to_str().unwrap(),
        Some("00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff"),
        false,
    )
    .await
    .unwrap();

    let marker: String =
        sqlx::query_scalar("SELECT value FROM app_metadata WHERE key = 'snapshot'")
            .fetch_one(&copy.pool)
            .await
            .unwrap();

    assert_eq!(marker, "committed");

    let version: i64 = sqlx::query_scalar("PRAGMA user_version")
        .fetch_one(&copy.pool)
        .await
        .unwrap();

    assert_eq!(version, 77);

    assert!(writes::export_debug(&database, &target).await.is_err());

    assert_ne!(&std::fs::read(&target).unwrap()[..16], b"SQLite format 3\0");

    copy.pool.close().await;
}
