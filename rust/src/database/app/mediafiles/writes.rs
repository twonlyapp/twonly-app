use super::table::{MediaFile, MediaFilePatch};
use crate::error::{Result, TwonlyError};
use sqlx::{Sqlite, Transaction};

pub async fn upsert(tx: &mut Transaction<'_, Sqlite>, patch: MediaFilePatch) -> Result<MediaFile> {
    if patch.media_id.is_none() {
        return Err(TwonlyError::Generic(
            "media_files.media_id is required".into(),
        ));
    }

    if patch.r#type.is_none() {
        return Err(TwonlyError::Generic("media_files.type is required".into()));
    }

    let id = patch.media_id.clone().expect("primary key checked");

    sqlx::query!(
        r#"
            INSERT INTO media_files (
                media_id,
                type,
                upload_state,
                cloud_state,
                blurhash,
                download_state,
                requires_authentication,
                stored,
                is_draft_media,
                is_widget_media,
                is_favorite,
                has_crop_analyzed,
                pre_progressing_process,
                reupload_requested_by,
                display_limit_in_milliseconds,
                remove_audio,
                trim_start_ms,
                trim_end_ms,
                download_token,
                encryption_key,
                encryption_mac,
                encryption_nonce,
                stored_file_hash,
                has_thumbnail,
                size_in_bytes,
                location_latitude,
                location_longitude,
                location_accuracy,
                location_status,
                location_deadline_at,
                gallery_export_pending,
                created_at,
                created_at_month
            ) VALUES (
                ?,
                ?,
                ?,
                COALESCE(?, 'none'),
                ?,
                ?,
                COALESCE(?, 0),
                COALESCE(?, 0),
                COALESCE(?, 0),
                COALESCE(?, 0),
                COALESCE(?, 0),
                COALESCE(?, 0),
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                COALESCE(?, 0),
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                COALESCE(?, 0),
                COALESCE(?, CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
                ?
            )
            ON CONFLICT(media_id) DO UPDATE SET
                type = CASE WHEN ? THEN excluded.type ELSE media_files.type END,
                upload_state = CASE WHEN ? THEN excluded.upload_state ELSE media_files.upload_state END,
                cloud_state = CASE WHEN ? THEN excluded.cloud_state ELSE media_files.cloud_state END,
                blurhash = CASE WHEN ? THEN excluded.blurhash ELSE media_files.blurhash END,
                download_state = CASE WHEN ? THEN excluded.download_state ELSE media_files.download_state END,
                requires_authentication = CASE WHEN ? THEN excluded.requires_authentication
                    ELSE media_files.requires_authentication END,
                stored = CASE WHEN ? THEN excluded.stored ELSE media_files.stored END,
                is_draft_media = CASE WHEN ? THEN excluded.is_draft_media ELSE media_files.is_draft_media END,
                is_widget_media = CASE WHEN ? THEN excluded.is_widget_media ELSE media_files.is_widget_media END,
                is_favorite = CASE WHEN ? THEN excluded.is_favorite ELSE media_files.is_favorite END,
                has_crop_analyzed = CASE WHEN ? THEN excluded.has_crop_analyzed ELSE media_files.has_crop_analyzed
                    END,
                pre_progressing_process = CASE WHEN ? THEN excluded.pre_progressing_process
                    ELSE media_files.pre_progressing_process END,
                reupload_requested_by = CASE WHEN ? THEN excluded.reupload_requested_by
                    ELSE media_files.reupload_requested_by END,
                display_limit_in_milliseconds = CASE WHEN ? THEN excluded.display_limit_in_milliseconds
                    ELSE media_files.display_limit_in_milliseconds END,
                remove_audio = CASE WHEN ? THEN excluded.remove_audio ELSE media_files.remove_audio END,
                trim_start_ms = CASE WHEN ? THEN excluded.trim_start_ms ELSE media_files.trim_start_ms END,
                trim_end_ms = CASE WHEN ? THEN excluded.trim_end_ms ELSE media_files.trim_end_ms END,
                download_token = CASE WHEN ? THEN excluded.download_token ELSE media_files.download_token END,
                encryption_key = CASE WHEN ? THEN excluded.encryption_key ELSE media_files.encryption_key END,
                encryption_mac = CASE WHEN ? THEN excluded.encryption_mac ELSE media_files.encryption_mac END,
                encryption_nonce = CASE WHEN ? THEN excluded.encryption_nonce ELSE media_files.encryption_nonce END,
                stored_file_hash = CASE WHEN ? THEN excluded.stored_file_hash ELSE media_files.stored_file_hash END,
                has_thumbnail = CASE WHEN ? THEN excluded.has_thumbnail ELSE media_files.has_thumbnail END,
                size_in_bytes = CASE WHEN ? THEN excluded.size_in_bytes ELSE media_files.size_in_bytes END,
                location_latitude = CASE WHEN ? THEN excluded.location_latitude ELSE media_files.location_latitude
                    END,
                location_longitude = CASE WHEN ? THEN excluded.location_longitude
                    ELSE media_files.location_longitude END,
                location_accuracy = CASE WHEN ? THEN excluded.location_accuracy ELSE media_files.location_accuracy
                    END,
                location_status = CASE WHEN ? THEN excluded.location_status ELSE media_files.location_status END,
                location_deadline_at = CASE WHEN ? THEN excluded.location_deadline_at
                    ELSE media_files.location_deadline_at END,
                gallery_export_pending = CASE WHEN ? THEN excluded.gallery_export_pending
                    ELSE media_files.gallery_export_pending END,
                created_at = CASE WHEN ? THEN excluded.created_at ELSE media_files.created_at END,
                created_at_month = CASE WHEN ? THEN excluded.created_at_month ELSE media_files.created_at_month END
        "#,
        patch.media_id.as_deref(),
        patch.r#type.as_deref(),
        patch.upload_state.as_ref().and_then(|value| value.value.as_deref()),
        patch.cloud_state.as_deref(),
        patch.blurhash.as_ref().and_then(|value| value.value.as_deref()),
        patch.download_state.as_ref().and_then(|value| value.value.as_deref()),
        patch.requires_authentication,
        patch.stored,
        patch.is_draft_media,
        patch.is_widget_media,
        patch.is_favorite,
        patch.has_crop_analyzed,
        patch.pre_progressing_process.as_ref().and_then(|value| value.value),
        patch.reupload_requested_by.as_ref().and_then(|value| value.value.as_deref()),
        patch.display_limit_in_milliseconds.as_ref().and_then(|value| value.value),
        patch.remove_audio.as_ref().and_then(|value| value.value),
        patch.trim_start_ms.as_ref().and_then(|value| value.value),
        patch.trim_end_ms.as_ref().and_then(|value| value.value),
        patch.download_token.as_ref().and_then(|value| value.value.as_deref()),
        patch.encryption_key.as_ref().and_then(|value| value.value.as_deref()),
        patch.encryption_mac.as_ref().and_then(|value| value.value.as_deref()),
        patch.encryption_nonce.as_ref().and_then(|value| value.value.as_deref()),
        patch.stored_file_hash.as_ref().and_then(|value| value.value.as_deref()),
        patch.has_thumbnail,
        patch.size_in_bytes.as_ref().and_then(|value| value.value),
        patch.location_latitude.as_ref().and_then(|value| value.value),
        patch.location_longitude.as_ref().and_then(|value| value.value),
        patch.location_accuracy.as_ref().and_then(|value| value.value),
        patch.location_status.as_ref().and_then(|value| value.value.as_deref()),
        patch.location_deadline_at.as_ref().and_then(|value| value.value),
        patch.gallery_export_pending,
        patch.created_at,
        patch.created_at_month.as_ref().and_then(|value| value.value.as_deref()),
        patch.r#type.is_some(),
        patch.upload_state.is_some(),
        patch.cloud_state.is_some(),
        patch.blurhash.is_some(),
        patch.download_state.is_some(),
        patch.requires_authentication.is_some(),
        patch.stored.is_some(),
        patch.is_draft_media.is_some(),
        patch.is_widget_media.is_some(),
        patch.is_favorite.is_some(),
        patch.has_crop_analyzed.is_some(),
        patch.pre_progressing_process.is_some(),
        patch.reupload_requested_by.is_some(),
        patch.display_limit_in_milliseconds.is_some(),
        patch.remove_audio.is_some(),
        patch.trim_start_ms.is_some(),
        patch.trim_end_ms.is_some(),
        patch.download_token.is_some(),
        patch.encryption_key.is_some(),
        patch.encryption_mac.is_some(),
        patch.encryption_nonce.is_some(),
        patch.stored_file_hash.is_some(),
        patch.has_thumbnail.is_some(),
        patch.size_in_bytes.is_some(),
        patch.location_latitude.is_some(),
        patch.location_longitude.is_some(),
        patch.location_accuracy.is_some(),
        patch.location_status.is_some(),
        patch.location_deadline_at.is_some(),
        patch.gallery_export_pending.is_some(),
        patch.created_at.is_some(),
        patch.created_at_month.is_some(),
    ).execute(&mut **tx).await?;

    Ok(super::queries::get(&mut **tx, &id)
        .await?
        .expect("row exists"))
}

pub async fn update(
    tx: &mut Transaction<'_, Sqlite>, id: Option<&str>, patch: MediaFilePatch,
) -> Result<()> {
    // Only name the supplied columns. The former CASE-based update named every
    // column, including the primary key and location index, for every patch.
    let mut query = sqlx::QueryBuilder::<Sqlite>::new("UPDATE media_files SET ");
    let mut has_updates = false;
    {
        let mut fields = query.separated(", ");
        macro_rules! set {
            ($field:ident, $column:literal) => {
                if let Some(value) = patch.$field {
                    has_updates = true;
                    fields
                        .push(concat!($column, " = "))
                        .push_bind_unseparated(value);
                }
            };
        }
        macro_rules! set_nullable {
            ($field:ident, $column:literal) => {
                if let Some(value) = patch.$field {
                    has_updates = true;
                    fields
                        .push(concat!($column, " = "))
                        .push_bind_unseparated(value.value);
                }
            };
        }

        set!(media_id, "media_id");
        set!(r#type, "type");
        set_nullable!(upload_state, "upload_state");
        set!(cloud_state, "cloud_state");
        set_nullable!(blurhash, "blurhash");
        set_nullable!(download_state, "download_state");
        set!(requires_authentication, "requires_authentication");
        set!(stored, "stored");
        set!(is_draft_media, "is_draft_media");
        set!(is_widget_media, "is_widget_media");
        set!(is_favorite, "is_favorite");
        set!(has_crop_analyzed, "has_crop_analyzed");
        set_nullable!(pre_progressing_process, "pre_progressing_process");
        set_nullable!(reupload_requested_by, "reupload_requested_by");
        set_nullable!(
            display_limit_in_milliseconds,
            "display_limit_in_milliseconds"
        );
        set_nullable!(remove_audio, "remove_audio");
        set_nullable!(trim_start_ms, "trim_start_ms");
        set_nullable!(trim_end_ms, "trim_end_ms");
        set_nullable!(download_token, "download_token");
        set_nullable!(encryption_key, "encryption_key");
        set_nullable!(encryption_mac, "encryption_mac");
        set_nullable!(encryption_nonce, "encryption_nonce");
        set_nullable!(stored_file_hash, "stored_file_hash");
        set!(has_thumbnail, "has_thumbnail");
        set_nullable!(size_in_bytes, "size_in_bytes");
        set_nullable!(location_latitude, "location_latitude");
        set_nullable!(location_longitude, "location_longitude");
        set_nullable!(location_accuracy, "location_accuracy");
        set_nullable!(location_status, "location_status");
        set_nullable!(location_deadline_at, "location_deadline_at");
        set!(gallery_export_pending, "gallery_export_pending");
        set!(created_at, "created_at");
        set_nullable!(created_at_month, "created_at_month");
    }

    if !has_updates {
        return Ok(());
    }
    if let Some(id) = id {
        query.push(" WHERE media_id = ").push_bind(id);
    }
    query.build().execute(&mut **tx).await?;

    Ok(())
}

pub async fn delete(tx: &mut Transaction<'_, Sqlite>, id: &str) -> Result<()> {
    sqlx::query!(
        r#"
            DELETE FROM media_files WHERE media_id = ?
        "#,
        id,
    )
    .execute(&mut **tx)
    .await?;

    Ok(())
}

pub async fn fill_months(
    tx: &mut Transaction<'_, Sqlite>, labels: Vec<super::table::MediaMonthLabel>,
) -> Result<()> {
    for label in labels {
        sqlx::query!(
            r#"
                UPDATE media_files
                SET created_at_month = ?
                WHERE created_at = ? AND created_at_month IS NULL
            "#,
            label.month,
            label.created_at,
        )
        .execute(&mut **tx)
        .await?;
    }

    Ok(())
}
