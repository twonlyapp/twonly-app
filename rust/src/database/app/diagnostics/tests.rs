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
                media_id: format!("mock_gen_{i}"),
                created_at: i,
                month: "Januar 2024".into(),
            })
            .collect()
    };

    writes::seed_gallery(&mut tx, items()).await.unwrap();

    writes::seed_gallery(&mut tx, items()).await.unwrap();

    let stored: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM media_files WHERE stored = 1")
        .fetch_one(&mut *tx)
        .await
        .unwrap();

    assert_eq!(stored, 13);

    let unrelated: (i64, i64, i64) = sqlx::query_as(
        "SELECT (SELECT COUNT(*) FROM groups), (SELECT COUNT(*) FROM contacts), \
         (SELECT COUNT(*) FROM messages)",
    )
    .fetch_one(&mut *tx)
    .await
    .unwrap();

    assert_eq!(unrelated, (0, 0, 0));

    assert!(writes::seed_gallery(
        &mut tx,
        vec![MockGalleryItem {
            media_id: "real_media".into(),
            created_at: 0,
            month: "Januar 2024".into(),
        }],
    )
    .await
    .is_err());

    sqlx::query(
        r#"
        INSERT INTO groups(group_id, group_name, is_direct_chat, joined_group)
        VALUES ('mock_group_gallery', 'Mock Gallery Group', 0, 1)
        "#,
    )
    .execute(&mut *tx)
    .await
    .unwrap();

    sqlx::query(
        r#"
        INSERT INTO contacts(user_id, username, display_name)
        VALUES (9000000, 'mock_user_0', 'Author 0'), (9000001, 'mock_user_1', 'Author 1')
        "#,
    )
    .execute(&mut *tx)
    .await
    .unwrap();

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

    assert_eq!(count, 3);
}

#[tokio::test]

async fn debug_export_opens_without_a_key_and_preserves_source_and_metadata() {
    for key in [
        Some("00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff"),
        None,
    ] {
        let directory = tempfile::tempdir().unwrap();
        let source = directory.path().join("app.sqlite");
        let target = directory.path().join("inspect'copy.sqlite");
        let database = AppDatabase::new(source.to_str().unwrap(), key, false)
            .await
            .unwrap();

        database.run_migrations().await.unwrap();

        sqlx::query("PRAGMA wal_autocheckpoint = 0")
            .execute(&database.pool)
            .await
            .unwrap();
        sqlx::query("INSERT INTO app_metadata(key, value) VALUES ('snapshot', 'committed')")
            .execute(&database.pool)
            .await
            .unwrap();
        sqlx::query("PRAGMA user_version = 77")
            .execute(&database.pool)
            .await
            .unwrap();
        sqlx::query("PRAGMA application_id = 12345")
            .execute(&database.pool)
            .await
            .unwrap();

        let schema: Vec<(String, String)> =
            sqlx::query_as("SELECT type, name FROM sqlite_schema ORDER BY name")
                .fetch_all(&database.pool)
                .await
                .unwrap();

        writes::export_debug(&database, &target).await.unwrap();

        assert_eq!(&std::fs::read(&target).unwrap()[..16], b"SQLite format 3\0");

        let copy = AppDatabase::new(target.to_str().unwrap(), None, true)
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

        let application_id: i64 = sqlx::query_scalar("PRAGMA application_id")
            .fetch_one(&copy.pool)
            .await
            .unwrap();
        assert_eq!(application_id, 12345);

        let copied_schema: Vec<(String, String)> =
            sqlx::query_as("SELECT type, name FROM sqlite_schema ORDER BY name")
                .fetch_all(&copy.pool)
                .await
                .unwrap();
        assert_eq!(copied_schema, schema);

        let exported_bytes = std::fs::read(&target).unwrap();
        assert!(writes::export_debug(&database, &target).await.is_err());
        assert_eq!(std::fs::read(&target).unwrap(), exported_bytes);

        copy.pool.close().await;
        database.pool.close().await;

        if key.is_some() {
            assert_ne!(&std::fs::read(&source).unwrap()[..16], b"SQLite format 3\0");
            assert!(AppDatabase::new(source.to_str().unwrap(), None, true)
                .await
                .is_err());
        }
        let original = AppDatabase::new(source.to_str().unwrap(), key, true)
            .await
            .unwrap();
        let marker: String =
            sqlx::query_scalar("SELECT value FROM app_metadata WHERE key = 'snapshot'")
                .fetch_one(&original.pool)
                .await
                .unwrap();
        assert_eq!(marker, "committed");
        original.pool.close().await;
    }
}
