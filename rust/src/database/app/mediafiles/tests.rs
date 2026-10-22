use super::table::*;
use super::{queries, storage, writes};
use crate::database::app::AppDatabase;

fn input(filter: MediaFilter) -> MediaQuery {
    MediaQuery {
        filter,
        ids: vec![],
        group_id: None,
        hash: None,
        favorites_only: false,
    }
}

#[tokio::test]

async fn media_queries_preserve_states_deduplication_links_and_small_storage_results() {
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

    sqlx::query("INSERT INTO groups(group_id,group_name) VALUES ('g','G'),('empty','Empty')")
        .execute(&mut *tx)
        .await
        .unwrap();

    writes::upsert(
        &mut tx,
        MediaFilePatch {
            media_id: Some("one".into()),
            r#type: Some("image".into()),
            stored: Some(true),
            size_in_bytes: Some(crate::database::app::patch::NullableInt { value: Some(123) }),
            ..Default::default()
        },
    )
    .await
    .unwrap();

    sqlx::query(r#"
        INSERT INTO media_files(media_id,type,stored,stored_file_hash,location_latitude,location_longitude,
                cloud_state
        )
        VALUES ('unlocated','image',1,X'12',NULL,NULL,'none'),
            ('located','video',1,X'12',52,13,'uploaded')
        "#,
)
    .execute(&mut *tx).await.unwrap();

    sqlx::query(
        r#"
        INSERT INTO messages(message_id,group_id,type,media_id)
        VALUES ('a','g','media','one'),
            ('b','g','media','one')
        "#,
    )
    .execute(&mut *tx)
    .await
    .unwrap();

    assert_eq!(
        queries::list(&mut tx, &input(MediaFilter::Stored))
            .await
            .unwrap()
            .len(),
        2
    );

    assert_eq!(
        queries::list(&mut tx, &input(MediaFilter::Geotagged))
            .await
            .unwrap()[0]
            .media_id,
        "located"
    );

    let chats = queries::by_chat(&mut tx).await.unwrap();

    assert_eq!(
        (chats.groups.len(), chats.files.len(), chats.links.len()),
        (2, 1, 1)
    );

    std::fs::write(directory.path().join("one.webp"), b"image").unwrap();

    let stats = storage::stats(&mut tx, directory.path().into())
        .await
        .unwrap();

    assert_eq!((stats.len(), stats[0].bytes), (1, 123));

    assert_eq!(
        storage::cloud_only_count(&mut tx, directory.path().into())
            .await
            .unwrap(),
        1
    );

    for filter in [
        MediaFilter::All,
        MediaFilter::Ids,
        MediaFilter::Draft,
        MediaFilter::PendingDownload,
        MediaFilter::ReuploadRequested,
        MediaFilter::PendingMigration,
        MediaFilter::PendingUpload,
        MediaFilter::ChatList,
        MediaFilter::ByHash,
        MediaFilter::MemoriesToBackup,
    ] {
        queries::list(&mut tx, &input(filter)).await.unwrap();
    }

    let mut group = input(MediaFilter::Group);

    group.group_id = Some("g".into());

    assert_eq!(queries::list(&mut tx, &group).await.unwrap().len(), 2);

    writes::delete(&mut tx, "one").await.unwrap();

    assert!(queries::get(&mut tx, "one").await.unwrap().is_none());
}

#[tokio::test]

async fn month_backfill_and_backup_cleanup_preserve_existing_data_and_rollback() {
    let directory = tempfile::tempdir().unwrap();

    let database = AppDatabase::new(
        directory.path().join("app.sqlite").to_str().unwrap(),
        None,
        false,
    )
    .await
    .unwrap();

    database.run_migrations().await.unwrap();

    let stored = directory.path().join("stored");

    std::fs::create_dir(&stored).unwrap();

    std::fs::write(stored.join("keep.webp"), []).unwrap();

    let mut tx = database.pool.begin().await.unwrap();

    sqlx::query(
        r#"
        INSERT INTO media_files(media_id, type, stored, cloud_state, created_at, created_at_month)
        VALUES ('keep', 'image', 1, 'uploaded', 1, 'keep-label'),
            ('missing', 'video', 1, 'uploaded', 1, NULL),
            ('other', 'image', 0, 'uploaded', 2, NULL)
        "#,
    )
    .execute(&mut *tx)
    .await
    .unwrap();

    tx.commit().await.unwrap();

    let mut tx = database.pool.begin().await.unwrap();

    assert_eq!(
        queries::missing_month_dates(&mut tx).await.unwrap(),
        vec![1, 2]
    );

    writes::fill_months(
        &mut tx,
        vec![MediaMonthLabel {
            created_at: 1,
            month: "Januar 2024".into(),
        }],
    )
    .await
    .unwrap();

    assert_eq!(
        queries::get(&mut tx, "keep")
            .await
            .unwrap()
            .unwrap()
            .created_at_month
            .as_deref(),
        Some("keep-label")
    );

    assert_eq!(
        queries::get(&mut tx, "missing")
            .await
            .unwrap()
            .unwrap()
            .created_at_month
            .as_deref(),
        Some("Januar 2024")
    );

    assert_eq!(
        storage::finish_backup_disable(&mut tx, stored.clone())
            .await
            .unwrap(),
        1
    );

    assert!(queries::get(&mut tx, "missing").await.unwrap().is_none());

    assert_eq!(
        queries::get(&mut tx, "other")
            .await
            .unwrap()
            .unwrap()
            .cloud_state,
        "none"
    );

    tx.rollback().await.unwrap();

    let mut tx = database.pool.begin().await.unwrap();

    let queued: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM pending_media_file_removals")
        .fetch_one(&mut *tx)
        .await
        .unwrap();

    assert_eq!(queued, 0);

    let missing = queries::get(&mut tx, "missing").await.unwrap().unwrap();

    assert_eq!(missing.cloud_state, "uploaded");

    assert!(missing.created_at_month.is_none());

    assert!(queries::get(&mut tx, "keep").await.unwrap().is_some());

    tx.commit().await.unwrap();

    let mut tx = database.pool.begin().await.unwrap();

    assert!(
        storage::finish_backup_disable(&mut tx, std::path::PathBuf::from("\0"))
            .await
            .is_err()
    );

    assert_eq!(
        queries::get(&mut tx, "missing")
            .await
            .unwrap()
            .unwrap()
            .cloud_state,
        "uploaded"
    );

    tx.rollback().await.unwrap();

    let mut tx = database.pool.begin().await.unwrap();

    assert_eq!(
        storage::finish_backup_disable(&mut tx, stored.clone())
            .await
            .unwrap(),
        1
    );

    tx.commit().await.unwrap();

    assert!(stored.join("keep.webp").exists());

    let mut connection = database.pool.acquire().await.unwrap();

    assert!(queries::get(&mut connection, "missing")
        .await
        .unwrap()
        .is_none());

    assert!(queries::get(&mut connection, "keep")
        .await
        .unwrap()
        .is_some());

    assert_eq!(
        queries::get(&mut connection, "other")
            .await
            .unwrap()
            .unwrap()
            .cloud_state,
        "none"
    );

    let pending: String = sqlx::query_scalar("SELECT media_id FROM pending_media_file_removals")
        .fetch_one(&mut *connection)
        .await
        .unwrap();

    assert_eq!(pending, "missing");
}
