use super::table::*;
use crate::database::app::groups;
use crate::error::Result;
use sqlx::SqliteConnection;

pub async fn get(connection: &mut SqliteConnection, id: &str) -> Result<Option<MediaFile>> {
    Ok(sqlx::query_as!(
        MediaFile,
        r#"
            SELECT
            media_id AS "media_id!",
                type AS "type!",
                upload_state AS "upload_state?",
                cloud_state AS "cloud_state!",
                blurhash AS "blurhash?",
                download_state AS "download_state?",
                requires_authentication AS "requires_authentication!: bool",
                stored AS "stored!: bool",
                is_draft_media AS "is_draft_media!: bool",
                is_widget_media AS "is_widget_media!: bool",
                is_favorite AS "is_favorite!: bool",
                has_crop_analyzed AS "has_crop_analyzed!: bool",
                pre_progressing_process AS "pre_progressing_process?",
                reupload_requested_by AS "reupload_requested_by?",
                display_limit_in_milliseconds AS "display_limit_in_milliseconds?",
                remove_audio AS "remove_audio?: bool",
                trim_start_ms AS "trim_start_ms?",
                trim_end_ms AS "trim_end_ms?",
                download_token AS "download_token?",
                encryption_key AS "encryption_key?",
                encryption_mac AS "encryption_mac?",
                encryption_nonce AS "encryption_nonce?",
                stored_file_hash AS "stored_file_hash?",
                has_thumbnail AS "has_thumbnail!: bool",
                size_in_bytes AS "size_in_bytes?",
                location_latitude AS "location_latitude?",
                location_longitude AS "location_longitude?",
                location_accuracy AS "location_accuracy?",
                location_status AS "location_status?",
                location_deadline_at AS "location_deadline_at?",
                gallery_export_pending AS "gallery_export_pending!: bool",
                created_at AS "created_at!",
                created_at_month AS "created_at_month?"
            FROM media_files WHERE media_id = ?
        "#,
        id,
    )
    .fetch_optional(connection)
    .await?)
}

pub async fn list(connection: &mut SqliteConnection, input: &MediaQuery) -> Result<Vec<MediaFile>> {
    // Each expansion contains only SQL literals; SQLx checks every filter at build
    // time.
    macro_rules! select {
        ($tail:literal $(, $arg:expr)* $(,)?) => {
            sqlx::query_as!(
                MediaFile,
                r#"
                    SELECT f.media_id AS "media_id!",
                        f.type AS "type!",
                        f.upload_state AS "upload_state?",
                        f.cloud_state AS "cloud_state!",
                        f.blurhash AS "blurhash?",
                        f.download_state AS "download_state?",
                        f.requires_authentication AS "requires_authentication!: bool",
                        f.stored AS "stored!: bool",
                        f.is_draft_media AS "is_draft_media!: bool",
                        f.is_widget_media AS "is_widget_media!: bool",
                        f.is_favorite AS "is_favorite!: bool",
                        f.has_crop_analyzed AS "has_crop_analyzed!: bool",
                        f.pre_progressing_process AS "pre_progressing_process?",
                        f.reupload_requested_by AS "reupload_requested_by?",
                        f.display_limit_in_milliseconds AS "display_limit_in_milliseconds?",
                        f.remove_audio AS "remove_audio?: bool",
                        f.trim_start_ms AS "trim_start_ms?",
                        f.trim_end_ms AS "trim_end_ms?",
                        f.download_token AS "download_token?",
                        f.encryption_key AS "encryption_key?",
                        f.encryption_mac AS "encryption_mac?",
                        f.encryption_nonce AS "encryption_nonce?",
                        f.stored_file_hash AS "stored_file_hash?",
                        f.has_thumbnail AS "has_thumbnail!: bool",
                        f.size_in_bytes AS "size_in_bytes?",
                        f.location_latitude AS "location_latitude?",
                        f.location_longitude AS "location_longitude?",
                        f.location_accuracy AS "location_accuracy?",
                        f.location_status AS "location_status?",
                        f.location_deadline_at AS "location_deadline_at?",
                        f.gallery_export_pending AS "gallery_export_pending!: bool",
                        f.created_at AS "created_at!",
                        f.created_at_month AS "created_at_month?"
                    FROM media_files f
                "# + $tail,
                $($arg),*
            ).fetch_all(&mut *connection).await?
        };
    }

    Ok(match input.filter {
        MediaFilter::All => select!(
            r#"
                ORDER BY f.rowid
            "#
        ),
        MediaFilter::Ids => select!(
            r#"
                WHERE f.media_id IN (SELECT value FROM json_each(?)) ORDER BY f.rowid
            "#,
            serde_json::to_string(&input.ids)?
        ),
        MediaFilter::Draft => select!(
            r#"
                WHERE f.is_draft_media = 1 ORDER BY f.rowid LIMIT 1
            "#
        ),
        MediaFilter::PendingDownload => select!(
            r#"
                WHERE f.download_state IN ('pending','downloading') ORDER BY f.rowid
            "#
        ),
        MediaFilter::ReuploadRequested => select!(
            r#"
                WHERE f.download_state = 'reuploadRequested' ORDER BY f.rowid
            "#
        ),
        MediaFilter::PendingMigration => select!(
            r#"
                WHERE f.stored = 1 AND (f.stored_file_hash IS NULL OR f.blurhash IS NULL OR f.has_crop_analyzed = 0
                OR (f.has_thumbnail = 0 AND f.type != 'audio') OR f.size_in_bytes IS NULL) ORDER BY f.rowid
            "#
        ),
        MediaFilter::PendingUpload => select!(
            r#"
                WHERE f.upload_state IN ('initialized','uploadLimitReached','uploading','preprocessing')
                ORDER BY f.rowid
            "#
        ),
        MediaFilter::Stored => select!(
            r#"
                WHERE f.stored = 1 OR f.cloud_state = 'uploaded' GROUP BY COALESCE(f.stored_file_hash, f.media_id)
                ORDER BY f.rowid
            "#
        ),
        MediaFilter::Geotagged => select!(
            r#"
                WHERE (f.stored = 1 OR f.cloud_state = 'uploaded') AND f.is_draft_media = 0 AND f.is_widget_media = 0
                AND f.type != 'audio' AND f.location_latitude BETWEEN -90 AND 90
                AND f.location_longitude BETWEEN -180 AND 180 AND (? = 0 OR f.is_favorite = 1)
                GROUP BY COALESCE(f.stored_file_hash, f.media_id) ORDER BY f.created_at DESC, f.media_id
            "#,
            input.favorites_only
        ),
        MediaFilter::Group => select!(
            r#"
                JOIN messages m ON m.media_id = f.media_id WHERE m.group_id = ? AND (m.is_story = 0
                OR m.media_stored = 1) ORDER BY f.rowid
            "#,
            input.group_id.as_deref()
        ),
        // SQLCipher can otherwise choose the dense history index for text-only
        // chats. These two branches must use their sparse candidate indexes.
        MediaFilter::ChatList => select!(
            r#"
                WHERE f.media_id IN (
                    SELECT m.media_id FROM messages m INDEXED BY idx_messages_chat_unopened
                    WHERE (m.opened_at IS NULL OR m.type = 'webxdcApp')
                        AND m.opened_at IS NULL AND m.media_id IS NOT NULL
                        AND (m.is_story = 0 OR m.media_stored = 1)
                    UNION
                    SELECT (
                        SELECT m.media_id FROM messages m INDEXED BY idx_messages_chat_media
                        WHERE m.group_id = g.group_id AND m.media_id IS NOT NULL
                            AND (m.is_story = 0 OR m.media_stored = 1)
                        ORDER BY m.created_at DESC, m.message_id DESC LIMIT 1
                    ) FROM groups g
                )
                ORDER BY f.rowid
            "#
        ),
        MediaFilter::ByHash => select!(
            r#"
                WHERE f.stored_file_hash = ? ORDER BY f.rowid
            "#,
            input.hash.as_deref()
        ),
        MediaFilter::MemoriesToBackup => select!(
            r#"
                WHERE f.stored = 1 AND f.cloud_state IN ('none','pending') ORDER BY f.rowid
            "#
        ),
    })
}

pub async fn by_chat(connection: &mut SqliteConnection) -> Result<ChatMediaSnapshot> {
    let groups = groups::queries::list(
        connection,
        &groups::table::GroupQuery {
            filter: groups::table::GroupFilter::All,
            group_id: None,
            contact_id: None,
        },
    )
    .await?;

    let links: Vec<ChatMediaLink> = sqlx::query_as!(
        ChatMediaLink,
        r#"
            SELECT DISTINCT group_id AS "group_id!",
                media_id AS "media_id!"
            FROM messages
            WHERE media_id IS NOT NULL
            ORDER BY group_id,
                rowid
        "#,
    )
    .fetch_all(&mut *connection)
    .await?;

    let files = sqlx::query_as!(
        MediaFile,
        r#"
            SELECT
            media_id AS "media_id!",
                type AS "type!",
                upload_state AS "upload_state?",
                cloud_state AS "cloud_state!",
                blurhash AS "blurhash?",
                download_state AS "download_state?",
                requires_authentication AS "requires_authentication!: bool",
                stored AS "stored!: bool",
                is_draft_media AS "is_draft_media!: bool",
                is_widget_media AS "is_widget_media!: bool",
                is_favorite AS "is_favorite!: bool",
                has_crop_analyzed AS "has_crop_analyzed!: bool",
                pre_progressing_process AS "pre_progressing_process?",
                reupload_requested_by AS "reupload_requested_by?",
                display_limit_in_milliseconds AS "display_limit_in_milliseconds?",
                remove_audio AS "remove_audio?: bool",
                trim_start_ms AS "trim_start_ms?",
                trim_end_ms AS "trim_end_ms?",
                download_token AS "download_token?",
                encryption_key AS "encryption_key?",
                encryption_mac AS "encryption_mac?",
                encryption_nonce AS "encryption_nonce?",
                stored_file_hash AS "stored_file_hash?",
                has_thumbnail AS "has_thumbnail!: bool",
                size_in_bytes AS "size_in_bytes?",
                location_latitude AS "location_latitude?",
                location_longitude AS "location_longitude?",
                location_accuracy AS "location_accuracy?",
                location_status AS "location_status?",
                location_deadline_at AS "location_deadline_at?",
                gallery_export_pending AS "gallery_export_pending!: bool",
                created_at AS "created_at!",
                created_at_month AS "created_at_month?"
            FROM media_files
            WHERE media_id IN (
                SELECT media_id
                FROM messages
            )
            ORDER BY rowid
        "#,
    )
    .fetch_all(connection)
    .await?;

    Ok(ChatMediaSnapshot {
        groups,
        files,
        links,
    })
}

pub async fn message_ids_by_hash(
    connection: &mut SqliteConnection, hash: &[u8], sender: i64,
) -> Result<Vec<String>> {
    Ok(sqlx::query_scalar!(
        r#"
            SELECT m.message_id AS "value!"
            FROM messages m
            JOIN media_files f
            ON f.media_id = m.media_id
            WHERE f.stored_file_hash = ?
                AND m.sender_id = ?
                AND m.is_widget_media = 0
                AND m.is_story = 0
                AND m.opened_at IS NULL
            ORDER BY m.rowid
        "#,
        hash,
        sender,
    )
    .fetch_all(connection)
    .await?)
}

pub async fn missing_month_dates(connection: &mut SqliteConnection) -> Result<Vec<i64>> {
    Ok(sqlx::query_scalar!(
        r#"
            SELECT DISTINCT created_at AS "value!"
            FROM media_files
            WHERE created_at_month IS NULL
            ORDER BY created_at
        "#,
    )
    .fetch_all(connection)
    .await?)
}
