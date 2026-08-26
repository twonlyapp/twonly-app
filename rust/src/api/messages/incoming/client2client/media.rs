/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::proto::client::encrypted_content;
use crate::bridge::callbacks::get_callbacks;
use crate::database::app::tables::Group;
use crate::error::{Result, TwonlyError};
use crate::utils::{milliseconds_to_seconds, new_uuid_v4};
use encrypted_content::media::Type as MediaType;
use encrypted_content::media_update::Type as MediaUpdateType;
use sqlx::{Sqlite, Transaction};

fn spawn_media_action(kind: &'static str, media_id: String, contact_id: i64, message_id: String) {
    if let Ok(callbacks) = get_callbacks() {
        tokio::spawn(async move {
            (callbacks.api.media_action)(kind.to_owned(), media_id, contact_id, message_id).await;
        });
    }
}

pub(crate) async fn handle_media(
    t: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    group_id: &str,
    media: encrypted_content::Media,
) -> Result<()> {
    let media_type = MediaType::try_from(media.r#type)?;

    if media_type == MediaType::Reupload {
        let media_id = sqlx::query_scalar!(
            r#"
            SELECT media_id
            FROM messages
            WHERE message_id = ? AND sender_id = ?
            "#,
            media.sender_message_id,
            from_user_id,
        )
        .fetch_optional(&mut **t)
        .await?
        .flatten();

        let Some(media_id) = media_id else {
            return Err(TwonlyError::Generic("invalid media reupload target".into()));
        };

        sqlx::query!(
            r#"
            UPDATE media_files
            SET download_state = 'pending',
                download_token = ?,
                encryption_key = ?,
                encryption_mac = ?,
                encryption_nonce = ?
            WHERE media_id = ?
            "#,
            media.download_token,
            media.encryption_key,
            media.encryption_mac,
            media.encryption_nonce,
            media_id,
        )
        .execute(&mut **t)
        .await?;

        spawn_media_action("download", media_id, from_user_id, media.sender_message_id);

        return Ok(());
    }

    let timestamp = milliseconds_to_seconds(media.timestamp);

    let existing = sqlx::query!(
        r#"
        SELECT m.sender_id, m.media_id, f.download_state
        FROM messages m
        LEFT JOIN media_files f ON f.media_id = m.media_id
        WHERE message_id = ?
        "#,
        media.sender_message_id,
    )
    .fetch_optional(&mut **t)
    .await?;

    if existing
        .as_ref()
        .is_some_and(|row| row.sender_id != Some(from_user_id))
    {
        return Err(TwonlyError::Generic(
            "attempted cross-sender media overwrite".into(),
        ));
    }

    let media_type = media_type.as_str_name().to_ascii_lowercase();

    if let Some(existing) = existing {
        let Some(media_id) = existing.media_id else {
            return Ok(());
        };

        if existing.download_state.as_deref() != Some("reuploadRequested") {
            return Ok(());
        }

        sqlx::query!(
            r#"UPDATE media_files SET type = ?, download_state = 'pending',
                   requires_authentication = ?, display_limit_in_milliseconds = ?,
                   download_token = ?, encryption_key = ?, encryption_mac = ?,
                   encryption_nonce = ?, created_at = ? WHERE media_id = ?"#,
            media_type,
            media.requires_authentication,
            media.display_limit_in_milliseconds,
            media.download_token,
            media.encryption_key,
            media.encryption_mac,
            media.encryption_nonce,
            timestamp,
            media_id,
        )
        .execute(&mut **t)
        .await?;

        spawn_media_action("download", media_id, from_user_id, media.sender_message_id);

        return Ok(());
    }

    let media_id = new_uuid_v4();
    sqlx::query!(
        r#"
        INSERT INTO media_files(
            media_id,
            type,
            download_state,
            requires_authentication,
            display_limit_in_milliseconds,
            download_token,
            encryption_key,
            encryption_mac,
            encryption_nonce,
            created_at
        ) VALUES (?, ?, 'pending', ?, ?, ?, ?, ?, ?, ?)
        "#,
        media_id,
        media_type,
        media.requires_authentication,
        media.display_limit_in_milliseconds,
        media.download_token,
        media.encryption_key,
        media.encryption_mac,
        media.encryption_nonce,
        timestamp,
    )
    .execute(&mut **t)
    .await?;
    sqlx::query!(
        r#"
        INSERT INTO messages(
            group_id,
            message_id,
            sender_id,
            type,
            media_id,
            additional_message_data,
            quotes_message_id,
            created_at
        ) VALUES (?, ?, ?, 'media', ?, ?, ?, ?)
        "#,
        group_id,
        media.sender_message_id,
        from_user_id,
        media_id,
        media.additional_message_data,
        media.quote_message_id,
        timestamp,
    )
    .execute(&mut **t)
    .await?;
    Group::increase_last_message_exchange(t, group_id, timestamp).await?;
    if let Ok(callbacks) = get_callbacks() {
        let group_id = group_id.to_owned();
        let timestamp = media.timestamp;
        tokio::spawn(async move {
            (callbacks.api.media_received)(group_id, timestamp).await;
        });
    }
    spawn_media_action("download", media_id, from_user_id, media.sender_message_id);
    Ok(())
}

pub(crate) async fn handle_media_update(
    t: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    update: encrypted_content::MediaUpdate,
) -> Result<()> {
    let media_id = sqlx::query_scalar!(
        r#"
        SELECT media_id
        FROM messages
        WHERE message_id = ? AND sender_id = ?
        "#,
        update.target_message_id,
        from_user_id,
    )
    .fetch_optional(&mut **t)
    .await?
    .flatten();
    let Some(media_id) = media_id else {
        return Ok(());
    };

    match MediaUpdateType::try_from(update.r#type)? {
        MediaUpdateType::Reopened => {
            sqlx::query!(
                r#"
                UPDATE messages
                SET media_reopened = 1
                WHERE message_id = ?
                "#,
                update.target_message_id,
            )
            .execute(&mut **t)
            .await?;
        }
        MediaUpdateType::Stored => {
            sqlx::query!(
                r#"
                UPDATE messages
                SET media_stored = 1
                WHERE message_id = ?
                "#,
                update.target_message_id,
            )
            .execute(&mut **t)
            .await?;

            spawn_media_action(
                "stored",
                media_id.clone(),
                from_user_id,
                update.target_message_id.clone(),
            );
        }
        MediaUpdateType::DecryptionError => {
            let requested_by = from_user_id.to_string();
            sqlx::query!(
                r#"
                UPDATE media_files
                SET upload_state = 'reuploadRequested',
                    reupload_requested_by = ?
                WHERE media_id = ?
                "#,
                requested_by,
                media_id,
            )
            .execute(&mut **t)
            .await?;

            spawn_media_action("reupload", media_id, from_user_id, update.target_message_id);
        }
    }
    Ok(())
}
