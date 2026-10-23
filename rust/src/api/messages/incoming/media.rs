/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::messages::incoming::messages::queue_encrypted_content;
use crate::api::proto::client::{encrypted_content, EncryptedContent};
use crate::context::Context;
use crate::database::app::groups::native::Group;
use crate::error::{Result, TwonlyError};
use crate::services::media_upload::MediaUploadService;
use crate::services::mediafiles::MediaFileService;
use crate::utils::{milliseconds_to_seconds, new_uuid_v4};
use encrypted_content::media::Type as MediaType;
use encrypted_content::media_update::Type as MediaUpdateType;
use sqlx::{Sqlite, Transaction};
use std::sync::Arc;

fn spawn_media_download(ctx: &Arc<Context>, media_id: String) {
    let ctx = ctx.clone();

    crate::database::lifecycle::spawn(async move {
        if let Err(error) = MediaFileService::new(&ctx)
            .download_when_available(&media_id)
            .await
        {
            tracing::warn!(media_id, %error, "media download failed");
        }
    });
}

/// A group member kept the media, so every member keeps an available copy too.

fn spawn_media_store(ctx: &Arc<Context>, media_id: String) {
    let ctx = ctx.clone();

    crate::database::lifecycle::spawn(async move {
        if let Err(error) = MediaUploadService::new(&ctx).store(&media_id).await {
            tracing::warn!(media_id, %error, "storing media after a receiver response failed");
        }
    });
}

/// The receiver could not decrypt the media, so it has to be re-encrypted and
/// uploaded again for that contact.

fn spawn_media_reupload(ctx: &Arc<Context>, media_id: String, contact_id: i64, message_id: String) {
    let ctx = ctx.clone();

    crate::database::lifecycle::spawn(async move {
        if let Err(error) = MediaUploadService::new(&ctx)
            .reupload(contact_id, &media_id, &message_id)
            .await
        {
            tracing::warn!(media_id, %error, "media reupload failed");
        }
    });
}

pub(crate) async fn handle_media(
    ctx: &Arc<Context>, t: &mut Transaction<'_, Sqlite>, from_user_id: i64, group_id: &str,
    media: encrypted_content::Media, is_story: bool,
) -> Result<()> {
    let media_type = MediaType::try_from(media.r#type)?;

    let widget_only = media.widget_only == Some(true);

    if widget_only {
        let granted = sqlx::query_scalar::<_, i64>(
            "SELECT widget_sharing_granted FROM contacts WHERE user_id = ?",
        )
        .bind(from_user_id)
        .fetch_optional(&mut **t)
        .await?
        .unwrap_or(0)
            != 0;

        if !granted
            || media_type != MediaType::Image
            || media.display_limit_in_milliseconds.is_some()
        {
            tracing::warn!(from_user_id, "dropping unauthorized widget media");

            return Ok(());
        }
    }

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

        spawn_media_download(ctx, media_id);

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
                   encryption_nonce = ?, is_widget_media = ?, created_at = ? WHERE media_id = ?"#,
            media_type,
            media.requires_authentication,
            media.display_limit_in_milliseconds,
            media.download_token,
            media.encryption_key,
            media.encryption_mac,
            media.encryption_nonce,
            widget_only,
            timestamp,
            media_id,
        )
        .execute(&mut **t)
        .await?;

        spawn_media_download(ctx, media_id);

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
            is_widget_media,
            created_at
        ) VALUES (?, ?, 'pending', ?, ?, ?, ?, ?, ?, ?, ?)
        "#,
        media_id,
        media_type,
        media.requires_authentication,
        media.display_limit_in_milliseconds,
        media.download_token,
        media.encryption_key,
        media.encryption_mac,
        media.encryption_nonce,
        widget_only,
        timestamp,
    )
    .execute(&mut **t)
    .await?;

    let opened_timestamp = chrono::Utc::now().timestamp_millis();

    let (opened_at, opened_by_all) = if widget_only {
        (Some(opened_timestamp / 1000), Some(opened_timestamp / 1000))
    } else {
        (None, None)
    };

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
            is_widget_media,
            is_story,
            opened_at,
            opened_by_all,
            created_at
        ) VALUES (?, ?, ?, 'media', ?, ?, ?, ?, ?, ?, ?, ?)
        "#,
        group_id,
        media.sender_message_id,
        from_user_id,
        media_id,
        media.additional_message_data,
        media.quote_message_id,
        widget_only,
        is_story,
        opened_at,
        opened_by_all,
        timestamp,
    )
    .execute(&mut **t)
    .await?;

    if widget_only {
        // Widget images are opened on arrival. Tell the sender too so its
        // chat row follows the same retention timer as other opened media.
        queue_encrypted_content(
            t,
            from_user_id,
            EncryptedContent {
                message_update: Some(encrypted_content::MessageUpdate {
                    r#type: encrypted_content::message_update::Type::Opened as i32,
                    multiple_target_message_ids: vec![media.sender_message_id],
                    timestamp: opened_timestamp,
                    ..Default::default()
                }),
                ..Default::default()
            },
            true,
        )
        .await?;
    }

    // A story is not an exchange in the chat it is filed under: it neither
    // moves the chat up nor feeds its flames.
    if !is_story {
        Group::increase_last_message_exchange(t, group_id, timestamp).await?;

        Group::record_media_exchange(t, group_id, true, timestamp).await?;

        Group::record_text_or_media(t, group_id, timestamp).await?;
    }

    spawn_media_download(ctx, media_id);

    Ok(())
}

pub(crate) async fn handle_media_update(
    ctx: &Arc<Context>, t: &mut Transaction<'_, Sqlite>, from_user_id: i64,
    update: encrypted_content::MediaUpdate,
) -> Result<()> {
    let media_id = sqlx::query_scalar!(
        r#"
        SELECT media_id
        FROM messages
        WHERE message_id = ?
        "#,
        update.target_message_id,
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

            // Every recipient of a story shares one media file here, so the
            // second person saving it must not export it to the gallery again.
            let already_stored = sqlx::query_scalar!(
                r#"SELECT stored AS "stored: bool" FROM media_files WHERE media_id = ?"#,
                media_id,
            )
            .fetch_optional(&mut **t)
            .await?
            .unwrap_or(false);

            if !already_stored {
                spawn_media_store(ctx, media_id.clone());
            }
        }
        MediaUpdateType::DecryptionError => {
            // The upload state and the requester list are owned by the reupload
            // path itself, which appends this contact instead of replacing
            // whoever else is still waiting for the same media.
            spawn_media_reupload(ctx, media_id, from_user_id, update.target_message_id);
        }
    }

    Ok(())
}

#[cfg(test)]

mod tests {

    use super::*;
    use prost::Message as _;

    #[tokio::test]
    async fn stored_group_media_is_kept_silently_by_other_members() -> anyhow::Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;
        crate::user_config::UserConfig::save_json(
            &ctx,
            r#"{"userId":43,"username":"member","displayName":"Member","storeMediaFilesInGallery":false}"#,
        )?;
        let database = ctx.app_db.read().await.clone();
        let mut tx = database.pool.begin().await?;
        for statement in [
            "INSERT INTO contacts(user_id, username) VALUES (7, 'saver'), (42, 'author')",
            "INSERT INTO groups(group_id, group_name) VALUES ('group', 'Group')",
            "INSERT INTO media_files(media_id, type, download_state) \
             VALUES ('available', 'image', 'ready'), ('missing', 'image', 'ready')",
            "INSERT INTO messages(message_id, group_id, sender_id, type, media_id) \
             VALUES ('available', 'group', 42, 'media', 'available'), \
             ('missing', 'group', 42, 'media', 'missing')",
        ] {
            sqlx::query(statement).execute(&mut *tx).await?;
        }

        let files = MediaFileService::new(&ctx);
        let path = files.temp_path("available", "image");
        MediaFileService::ensure_parent(&path)?;
        image::RgbImage::from_pixel(8, 6, image::Rgb([12, 34, 56]))
            .save_with_format(&path, image::ImageFormat::Png)?;

        for message_id in ["available", "missing"] {
            super::super::handle_encrypted(
                &ctx,
                &mut tx,
                7,
                message_id,
                EncryptedContent {
                    group_id: Some("group".into()),
                    media_update: Some(encrypted_content::MediaUpdate {
                        r#type: MediaUpdateType::Stored as i32,
                        target_message_id: message_id.into(),
                    }),
                    ..Default::default()
                },
            )
            .await?;
        }
        tx.commit().await?;

        tokio::time::timeout(std::time::Duration::from_secs(5), async {
            loop {
                let stored: bool = sqlx::query_scalar(
                    "SELECT stored FROM media_files WHERE media_id = 'available'",
                )
                .fetch_one(&database.pool)
                .await?;
                if stored {
                    break Ok::<_, crate::error::TwonlyError>(());
                }
                tokio::time::sleep(std::time::Duration::from_millis(10)).await;
            }
        })
        .await??;

        assert!(files.stored_path("available", "image").is_file());
        let stored_messages: i64 =
            sqlx::query_scalar("SELECT COUNT(*) FROM messages WHERE media_stored = 1")
                .fetch_one(&database.pool)
                .await?;
        assert_eq!(stored_messages, 2);
        let missing_stored: bool =
            sqlx::query_scalar("SELECT stored FROM media_files WHERE media_id = 'missing'")
                .fetch_one(&database.pool)
                .await?;
        assert!(!missing_stored);
        assert_eq!(crate::services::notifications::badge_count(&ctx).await?, 0);
        let alerts: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM notification_outbox")
            .fetch_one(&database.pool)
            .await?;
        assert_eq!(alerts, 0);
        let messages: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM messages")
            .fetch_one(&database.pool)
            .await?;
        assert_eq!(
            messages, 2,
            "save updates must not add visible chat messages"
        );

        Ok(())
    }

    #[tokio::test]

    async fn receiving_widget_media_moves_the_chat_first_and_counts_towards_flames_once(
    ) -> anyhow::Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx = Context::init_for_testing(
            directory.path().join("database"),
            directory.path().join("data"),
        )
        .await?;

        let db = ctx.app_db.read().await.clone();

        let today = crate::utils::start_of_local_day()?;

        let now = chrono::Utc::now().timestamp();

        let mut t = db.pool.begin().await?;

        sqlx::query(
            "INSERT INTO contacts(user_id, username, widget_sharing_granted) VALUES (7, 'peer', 1)",
        )
        .execute(&mut *t)
        .await?;

        sqlx::query(
            "INSERT INTO groups(group_id, group_name, last_message_exchange, flame_counter,
                                last_message_send, last_message_received, \
             last_flame_counter_change)
             VALUES ('widget-chat', 'Peer', 1, 4, ?, ?, ?), ('other-chat', 'Other', ?, 0, NULL, \
             NULL, NULL)",
        )
        .bind(now)
        .bind(today - 1)
        .bind(today - 1)
        .bind(now - 1)
        .execute(&mut *t)
        .await?;

        sqlx::query("INSERT INTO group_members(group_id, contact_id) VALUES ('widget-chat', 7)")
            .execute(&mut *t)
            .await?;

        let media = encrypted_content::Media {
            sender_message_id: "widget-message".into(),
            r#type: MediaType::Image as i32,
            widget_only: Some(true),
            timestamp: now * 1000,
            ..Default::default()
        };

        handle_media(&ctx, &mut t, 7, "widget-chat", media.clone(), false).await?;

        handle_media(&ctx, &mut t, 7, "widget-chat", media, false).await?;

        t.commit().await?;

        let first_chat: String = sqlx::query_scalar(
            "SELECT group_id FROM groups ORDER BY last_message_exchange DESC LIMIT 1",
        )
        .fetch_one(&db.pool)
        .await?;

        assert_eq!(first_chat, "widget-chat");

        let state = Group::flame_state(&db.pool, "widget-chat").await?;

        assert_eq!((state.counter, state.is_expiring), (5, false));

        let (total, received_at, active_at): (i64, i64, i64) = sqlx::query_as(
            "SELECT total_media_counter, last_message_received, last_text_or_media_at FROM groups \
             WHERE group_id = 'widget-chat'",
        )
        .fetch_one(&db.pool)
        .await?;

        assert_eq!((total, received_at, active_at), (1, now, now));

        let received: i64 =
            sqlx::query_scalar("SELECT media_received_counter FROM contacts WHERE user_id = 7")
                .fetch_one(&db.pool)
                .await?;

        assert_eq!(received, 1);

        Ok(())
    }

    #[tokio::test]

    async fn widget_arrival_queues_one_opened_receipt_with_the_arrival_time() -> anyhow::Result<()>
    {
        let directory = tempfile::tempdir()?;

        let ctx = Context::init_for_testing(
            directory.path().join("database"),
            directory.path().join("data"),
        )
        .await?;

        let database = ctx.app_db.read().await.clone();

        let mut t = database.pool.begin().await?;

        sqlx::query(
            "INSERT INTO contacts(user_id, username, widget_sharing_granted) VALUES (7, 'sender', \
             1)",
        )
        .execute(&mut *t)
        .await?;

        sqlx::query("INSERT INTO groups(group_id, group_name) VALUES ('chat', 'Chat')")
            .execute(&mut *t)
            .await?;

        let before_arrival = chrono::Utc::now().timestamp();

        let media = encrypted_content::Media {
            sender_message_id: "widget-message".into(),
            r#type: MediaType::Image as i32,
            widget_only: Some(true),
            timestamp: (before_arrival - 3 * 86400) * 1000,
            ..Default::default()
        };

        handle_media(&ctx, &mut t, 7, "chat", media.clone(), false).await?;

        handle_media(&ctx, &mut t, 7, "chat", media, false).await?;

        let (opened_at, opened_by_all): (i64, i64) = sqlx::query_as(
            "SELECT opened_at, opened_by_all FROM messages WHERE message_id = 'widget-message'",
        )
        .fetch_one(&mut *t)
        .await?;

        assert!(opened_at >= before_arrival);

        assert_eq!(opened_by_all, opened_at);

        let receipts: Vec<(i64, Vec<u8>)> =
            sqlx::query_as("SELECT contact_id, message FROM receipts")
                .fetch_all(&mut *t)
                .await?;

        assert_eq!(receipts.len(), 1, "redelivery must not restart retention");

        assert_eq!(receipts[0].0, 7);

        let envelope = crate::api::proto::client::Message::decode(receipts[0].1.as_slice())?;

        let content = EncryptedContent::decode(
            envelope
                .encrypted_content
                .as_deref()
                .expect("queued content"),
        )?;

        let update = content.message_update.expect("opened receipt");

        assert_eq!(
            update.r#type,
            encrypted_content::message_update::Type::Opened as i32
        );

        assert_eq!(update.multiple_target_message_ids, vec!["widget-message"]);

        assert_eq!(update.timestamp / 1000, opened_at);

        t.rollback().await?;

        Ok(())
    }
}
