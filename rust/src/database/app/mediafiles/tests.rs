use super::table::*;
use super::{queries, storage, writes};
use crate::database::app::patch::{NullableBytes, NullableInt, NullableReal, NullableText};
use crate::database::app::AppDatabase;

#[tokio::test]
async fn sparse_media_patches_preserve_other_columns_and_skip_empty_updates() {
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
    sqlx::query(
        "INSERT INTO \
         media_files(media_id,type,is_draft_media,location_status,location_deadline_at,\
         encryption_key) VALUES \
         ('one','image',1,'pending',123,X'0102'),('other','video',1,NULL,NULL,X'0304')",
    )
    .execute(&mut *tx)
    .await
    .unwrap();
    let before = queries::get(&mut tx, "one").await.unwrap().unwrap();
    let other = queries::get(&mut tx, "other").await.unwrap().unwrap();

    // A sparse update must not even name the primary key or indexed location
    // columns. This catches the old all-column CASE query despite equal values.
    sqlx::query(
        "CREATE TEMP TRIGGER reject_unrelated_media_columns BEFORE UPDATE OF \
         media_id,type,location_status,location_deadline_at ON media_files BEGIN SELECT \
         RAISE(ABORT, 'unrelated media column in SET'); END",
    )
    .execute(&mut *tx)
    .await
    .unwrap();
    sqlx::query("CREATE TEMP TABLE media_patch_updates (id TEXT)")
        .execute(&mut *tx)
        .await
        .unwrap();
    sqlx::query(
        "CREATE TEMP TRIGGER count_media_patches AFTER UPDATE ON media_files BEGIN INSERT INTO \
         media_patch_updates VALUES (NEW.media_id); END",
    )
    .execute(&mut *tx)
    .await
    .unwrap();

    writes::update(&mut tx, Some("one"), MediaFilePatch::default())
        .await
        .unwrap();
    assert_eq!(
        sqlx::query_scalar::<_, i64>("SELECT count(*) FROM media_patch_updates")
            .fetch_one(&mut *tx)
            .await
            .unwrap(),
        0
    );

    writes::update(
        &mut tx,
        Some("one"),
        MediaFilePatch {
            is_draft_media: Some(false),
            ..Default::default()
        },
    )
    .await
    .unwrap();
    assert_eq!(
        queries::get(&mut tx, "one").await.unwrap().unwrap(),
        MediaFile {
            is_draft_media: false,
            ..before
        }
    );
    assert_eq!(
        queries::get(&mut tx, "other").await.unwrap().unwrap(),
        other
    );
    writes::update(
        &mut tx,
        Some("missing"),
        MediaFilePatch {
            stored: Some(true),
            ..Default::default()
        },
    )
    .await
    .unwrap();
    assert_eq!(
        sqlx::query_scalar::<_, i64>("SELECT count(*) FROM media_patch_updates")
            .fetch_one(&mut *tx)
            .await
            .unwrap(),
        1
    );

    // Explicit internal bulk operations retain their existing behavior. The
    // Flutter bridge separately rejects a missing media ID.
    writes::update(
        &mut tx,
        None,
        MediaFilePatch {
            is_favorite: Some(true),
            ..Default::default()
        },
    )
    .await
    .unwrap();
    assert_eq!(
        sqlx::query_scalar::<_, i64>("SELECT count(*) FROM media_files WHERE is_favorite = 1")
            .fetch_one(&mut *tx)
            .await
            .unwrap(),
        2
    );
    tx.commit().await.unwrap();
}

#[tokio::test]
async fn media_patches_bind_every_type_and_distinguish_null_from_omitted() {
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
    sqlx::query("INSERT INTO media_files(media_id,type) VALUES ('original','image')")
        .execute(&mut *tx)
        .await
        .unwrap();
    let expected = MediaFile {
        media_id: "renamed'; SELECT 1; --".into(),
        r#type: "video".into(),
        upload_state: Some("uploaded".into()),
        cloud_state: "uploaded".into(),
        blurhash: Some("hash'; --".into()),
        download_state: Some("downloaded".into()),
        requires_authentication: true,
        stored: true,
        is_draft_media: true,
        is_widget_media: true,
        is_favorite: true,
        has_crop_analyzed: true,
        pre_progressing_process: Some(23),
        reupload_requested_by: Some("[42]".into()),
        display_limit_in_milliseconds: Some(1234),
        remove_audio: Some(true),
        trim_start_ms: Some(100),
        trim_end_ms: Some(900),
        download_token: Some(vec![0, 1]),
        encryption_key: Some(vec![2, 3]),
        encryption_mac: Some(vec![4, 5]),
        encryption_nonce: Some(vec![6, 7]),
        stored_file_hash: Some(vec![8, 9]),
        has_thumbnail: true,
        size_in_bytes: Some(789),
        location_latitude: Some(52.5),
        location_longitude: Some(13.25),
        location_accuracy: Some(12.5),
        location_status: Some("pending".into()),
        location_deadline_at: Some(456),
        gallery_export_pending: true,
        created_at: 123,
        created_at_month: Some("2026-10".into()),
    };
    macro_rules! nullable {
        ($kind:ident, $field:ident) => {
            Some($kind {
                value: expected.$field.clone(),
            })
        };
    }
    writes::update(
        &mut tx,
        Some("original"),
        MediaFilePatch {
            media_id: Some(expected.media_id.clone()),
            r#type: Some(expected.r#type.clone()),
            upload_state: nullable!(NullableText, upload_state),
            cloud_state: Some(expected.cloud_state.clone()),
            blurhash: nullable!(NullableText, blurhash),
            download_state: nullable!(NullableText, download_state),
            requires_authentication: Some(expected.requires_authentication),
            stored: Some(expected.stored),
            is_draft_media: Some(expected.is_draft_media),
            is_widget_media: Some(expected.is_widget_media),
            is_favorite: Some(expected.is_favorite),
            has_crop_analyzed: Some(expected.has_crop_analyzed),
            pre_progressing_process: nullable!(NullableInt, pre_progressing_process),
            reupload_requested_by: nullable!(NullableText, reupload_requested_by),
            display_limit_in_milliseconds: nullable!(NullableInt, display_limit_in_milliseconds),
            remove_audio: Some(NullableInt { value: Some(1) }),
            trim_start_ms: nullable!(NullableInt, trim_start_ms),
            trim_end_ms: nullable!(NullableInt, trim_end_ms),
            download_token: nullable!(NullableBytes, download_token),
            encryption_key: nullable!(NullableBytes, encryption_key),
            encryption_mac: nullable!(NullableBytes, encryption_mac),
            encryption_nonce: nullable!(NullableBytes, encryption_nonce),
            stored_file_hash: nullable!(NullableBytes, stored_file_hash),
            has_thumbnail: Some(expected.has_thumbnail),
            size_in_bytes: nullable!(NullableInt, size_in_bytes),
            location_latitude: nullable!(NullableReal, location_latitude),
            location_longitude: nullable!(NullableReal, location_longitude),
            location_accuracy: nullable!(NullableReal, location_accuracy),
            location_status: nullable!(NullableText, location_status),
            location_deadline_at: nullable!(NullableInt, location_deadline_at),
            gallery_export_pending: Some(expected.gallery_export_pending),
            created_at: Some(expected.created_at),
            created_at_month: nullable!(NullableText, created_at_month),
        },
    )
    .await
    .unwrap();
    assert!(queries::get(&mut tx, "original").await.unwrap().is_none());
    assert_eq!(
        queries::get(&mut tx, &expected.media_id)
            .await
            .unwrap()
            .unwrap(),
        expected
    );

    writes::update(
        &mut tx,
        Some(&expected.media_id),
        MediaFilePatch {
            upload_state: Some(NullableText { value: None }),
            trim_end_ms: Some(NullableInt { value: None }),
            encryption_key: Some(NullableBytes { value: None }),
            location_accuracy: Some(NullableReal { value: None }),
            ..Default::default()
        },
    )
    .await
    .unwrap();
    let cleared = MediaFile {
        upload_state: None,
        trim_end_ms: None,
        encryption_key: None,
        location_accuracy: None,
        ..expected
    };
    assert_eq!(
        queries::get(&mut tx, &cleared.media_id)
            .await
            .unwrap()
            .unwrap(),
        cleared
    );
    tx.commit().await.unwrap();
    let mut tx = database.pool.begin().await.unwrap();
    assert_eq!(
        queries::get(&mut tx, &cleared.media_id)
            .await
            .unwrap()
            .unwrap(),
        cleared
    );
}

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
