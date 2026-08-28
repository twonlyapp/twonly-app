/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::messages::content_type_kind;
use crate::api::messages::incoming::messages;
use crate::api::proto::client as proto;
use crate::context::Context;
use crate::error::Result;
use crate::user_config::UserConfig;
use prost::Message as _;
use std::sync::Arc;

pub(crate) async fn decorate_content(
    ctx: &Context,
    contact_id: i64,
    content: &mut proto::EncryptedContent,
    is_persisted_message: bool,
) -> Result<()> {
    let Some(config) = UserConfig::load_from(ctx)? else {
        return Ok(());
    };

    content.sender_profile_counter = Some(config.avatar_counter);

    if config.ask_for_friend_promotions {
        let database = ctx.app_db.read().await.clone();
        let accepted = sqlx::query_scalar!("SELECT COUNT(*) FROM contacts WHERE accepted = 1")
            .fetch_one(&database.pool)
            .await?;
        if accepted <= 5 {
            content.ask_for_friend_promotions = Some(true);
        }
    }

    if config.is_user_discovery_enabled & is_persisted_message {
        ctx.initialize_user_discovery_from_config().await?;
        let database = ctx.app_db.read().await.clone();
        let allowed = sqlx::query_scalar!(
            r#"SELECT EXISTS(SELECT 1 FROM contacts WHERE user_id = ? AND accepted = 1
               AND blocked = 0 AND media_send_counter >= ? AND user_discovery_excluded = 0
               AND (? = 0 OR user_discovery_manual_approved = 1))"#,
            contact_id,
            config.required_send_images,
            config.user_discovery_requires_manual_approval,
        )
        .fetch_one(&database.pool)
        .await?;
        if allowed != 0 {
            content.sender_user_discovery_version =
                Some(ctx.user_discovery.get().await.get_current_version().await?);
        }
    }
    Ok(())
}

#[bon::builder]
pub async fn send_c2c_message_to_contact(
    ctx: &Arc<Context>,
    contact_id: i64,
    encrypted_content: Vec<u8>,
    message_id: Option<String>,
    #[builder(default)] only_send_if_no_receipts_are_open: bool,
    #[builder(default)] only_return_encrypted_data: bool,
    #[builder(default)] blocking: bool,
) -> Result<Option<Vec<u8>>> {
    let mut content = proto::EncryptedContent::decode(encrypted_content.as_slice())?;

    decorate_content(ctx, contact_id, &mut content, message_id.is_some()).await?;

    let db_app = ctx.app_db.read().await.clone();
    let mut t = db_app.pool.begin().await?;

    if only_send_if_no_receipts_are_open {
        let count = sqlx::query_scalar!(
            "SELECT COUNT(*) FROM receipts WHERE contact_id = ?",
            contact_id
        )
        .fetch_one(&mut *t)
        .await?;
        if count > 10 {
            return Ok(None);
        }
    }

    let mut retry_count = 0_i64;
    let mut last_retry = None;
    if let Some(message_id) = &message_id {
        let previous = sqlx::query!(
            r#"SELECT COUNT(*) AS "count!: i64", MAX(last_retry) AS last_retry
               FROM receipts WHERE contact_id = ? AND message_id = ?"#,
            contact_id,
            message_id,
        )
        .fetch_one(&mut *t)
        .await?;
        retry_count = previous.count;
        last_retry = previous.last_retry;
        sqlx::query!(
            "DELETE FROM receipts WHERE contact_id = ? AND message_id = ?",
            contact_id,
            message_id
        )
        .execute(&mut *t)
        .await?;
    }

    let type_kind = content_type_kind(&content);
    let receipt_id = messages::queue_encrypted_content(&mut t, contact_id, content, true).await?;

    tracing::info!(
        contact_id,
        ?message_id,
        receipt_id,
        type_kind,
        "queued c2c message to contact"
    );

    sqlx::query!(
        r#"UPDATE receipts SET message_id = ?, will_be_retried_by_media_upload = ?,
           retry_count = ?, last_retry = ? WHERE receipt_id = ?"#,
        message_id,
        only_return_encrypted_data,
        retry_count,
        last_retry,
        receipt_id
    )
    .execute(&mut *t)
    .await?;

    t.commit().await?;
    db_app.notify_committed(["receipts"]);

    if only_return_encrypted_data {
        return messages::prepare_queued_receipt(ctx, &receipt_id).await;
    }

    if blocking {
        tracing::info!(receipt_id, "sending c2c message synchronously");
        messages::send_queued_receipt(ctx, &receipt_id).await?;
    } else {
        tracing::info!(receipt_id, "sending c2c message asynchronously");
        let queued_receipt_id = receipt_id.clone();
        let ctx = ctx.clone();
        tokio::spawn(async move {
            if let Err(error) = messages::send_queued_receipt(&ctx, &queued_receipt_id).await {
                tracing::warn!(
                    receipt_id = queued_receipt_id,
                    "queued message send failed: {error}"
                );
            }
        });
    }
    Ok(None)
}
