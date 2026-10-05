/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::messages::content_type_kind;
use crate::api::messages::incoming::messages;
use crate::api::proto::client as proto;
use crate::context::Context;
use crate::error::Result;
use crate::user_config::{TwonlyScoreVisibility, UserConfig};
use prost::Message as _;
use sqlx::{Sqlite, Transaction};
use std::sync::Arc;

/// Brings user discovery up before an envelope asks it for a version.
///
/// Initializing it builds the share set, which writes through the app database
/// on a connection of its own. The pool has exactly one, so this has to happen
/// before the caller opens the transaction [`decorate_content`] then runs on.
pub(crate) async fn prepare_user_discovery(
    ctx: &Context,
    is_persisted_message: bool,
) -> Result<()> {
    if !is_persisted_message {
        return Ok(());
    }
    let Some(config) = UserConfig::load_from(ctx)? else {
        return Ok(());
    };
    if config.is_user_discovery_enabled {
        ctx.initialize_user_discovery_from_config().await?;
    }
    Ok(())
}

/// Fills in the metadata every outgoing envelope carries beside its payload.
///
/// The reads run on the caller's transaction rather than on the pool: the app
/// database has a single connection, so asking the pool for one here while the
/// caller holds that connection open waits for the caller to finish and
/// deadlocks until the acquire times out thirty seconds later -- with every
/// other database user in the process blocked behind it.
///
/// A caller that passes `is_persisted_message` must have called
/// [`prepare_user_discovery`] before opening `t`.
pub(crate) async fn decorate_content(
    ctx: &Context,
    t: &mut Transaction<'_, Sqlite>,
    contact_id: i64,
    content: &mut proto::EncryptedContent,
    is_persisted_message: bool,
) -> Result<()> {
    let Some(config) = UserConfig::load_from(ctx)? else {
        return Ok(());
    };

    content.sender_profile_counter = Some(config.avatar_counter);
    content.widget_sharing_allowed = Some(
        sqlx::query_scalar!(
            "SELECT widget_sharing_granted FROM contacts WHERE user_id = ?",
            contact_id,
        )
        .fetch_optional(&mut **t)
        .await?
        .unwrap_or(0)
            != 0,
    );
    let share_twonly_score = match config.twonly_score_visibility {
        TwonlyScoreVisibility::Nobody => false,
        TwonlyScoreVisibility::OnlyContacts => {
            sqlx::query_scalar!(
                "SELECT accepted FROM contacts WHERE user_id = ?",
                contact_id,
            )
            .fetch_optional(&mut **t)
            .await?
            .unwrap_or(0)
                != 0
        }
        TwonlyScoreVisibility::Everyone => true,
    };
    content.sender_twonly_score = if share_twonly_score {
        Some(
            sqlx::query_scalar::<_, i64>(
                "SELECT COALESCE(SUM(total_media_counter), 0) FROM groups",
            )
            .fetch_one(&mut **t)
            .await?,
        )
    } else {
        None
    };
    if config.ask_for_friend_promotions {
        let accepted = sqlx::query_scalar!("SELECT COUNT(*) FROM contacts WHERE accepted = 1")
            .fetch_one(&mut **t)
            .await?;
        if accepted <= 5 {
            content.ask_for_friend_promotions = Some(true);
        }
    }

    if config.is_user_discovery_enabled & is_persisted_message {
        let allowed = sqlx::query_scalar!(
            r#"SELECT EXISTS(SELECT 1 FROM contacts WHERE user_id = ? AND accepted = 1
               AND blocked = 0 AND media_send_counter >= ? AND user_discovery_excluded = 0
               AND (? = 0 OR user_discovery_manual_approved = 1))"#,
            contact_id,
            config.required_send_images,
            config.user_discovery_requires_manual_approval,
        )
        .fetch_one(&mut **t)
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

    prepare_user_discovery(ctx, message_id.is_some()).await?;

    let db_app = ctx.app_db.read().await.clone();
    let mut t = db_app.pool.begin().await?;

    decorate_content(ctx, &mut t, contact_id, &mut content, message_id.is_some()).await?;

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
    // A resend of a message the server already took has already pushed the
    // recipient once. The replacement receipt must not ask for a second alert
    // about the same message.
    let mut already_woken = false;
    if let Some(message_id) = &message_id {
        let previous = sqlx::query!(
            r#"SELECT COUNT(*) AS "count!: i64", MAX(last_retry) AS last_retry,
                      MAX(ack_by_server_at) AS acknowledged
               FROM receipts WHERE contact_id = ? AND message_id = ?"#,
            contact_id,
            message_id,
        )
        .fetch_one(&mut *t)
        .await?;
        retry_count = previous.count;
        last_retry = previous.last_retry;
        already_woken = previous.acknowledged.is_some();
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
           retry_count = ?, last_retry = ?,
           wake_receiver = CASE WHEN ? THEN 0 ELSE wake_receiver END
           WHERE receipt_id = ?"#,
        message_id,
        only_return_encrypted_data,
        retry_count,
        last_retry,
        already_woken,
        receipt_id
    )
    .execute(&mut *t)
    .await?;

    t.commit().await?;

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

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn twonly_score_respects_recipient_visibility() -> Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx = Context::init_for_testing(
            directory.path().join("database"),
            directory.path().join("data"),
        )
        .await?;
        UserConfig::save_json(
            &ctx,
            r#"{"userId":42,"username":"ben","displayName":"Ben"}"#,
        )?;

        let database = ctx.app_db.read().await.clone();
        sqlx::query("INSERT INTO contacts(user_id, username) VALUES (7, 'anna')")
            .execute(&database.pool)
            .await?;
        sqlx::query(
            "INSERT INTO groups(group_id, group_name, total_media_counter) VALUES ('a', 'A', 4), ('b', 'B', 7)",
        )
        .execute(&database.pool)
        .await?;

        let mut content = proto::EncryptedContent::default();
        let mut transaction = database.pool.begin().await?;
        decorate_content(&ctx, &mut transaction, 7, &mut content, false).await?;
        transaction.rollback().await?;
        assert_eq!(content.sender_twonly_score, Some(11));

        UserConfig::update(&ctx, |config| {
            config.twonly_score_visibility = TwonlyScoreVisibility::OnlyContacts;
        })?;
        let mut hidden_content = proto::EncryptedContent {
            sender_twonly_score: Some(999),
            ..Default::default()
        };
        let mut transaction = database.pool.begin().await?;
        decorate_content(&ctx, &mut transaction, 7, &mut hidden_content, false).await?;
        transaction.rollback().await?;
        assert_eq!(hidden_content.sender_twonly_score, None);

        sqlx::query("UPDATE contacts SET accepted = 1 WHERE user_id = 7")
            .execute(&database.pool)
            .await?;
        let mut contact_content = proto::EncryptedContent::default();
        let mut transaction = database.pool.begin().await?;
        decorate_content(&ctx, &mut transaction, 7, &mut contact_content, false).await?;
        transaction.rollback().await?;
        assert_eq!(contact_content.sender_twonly_score, Some(11));

        UserConfig::update(&ctx, |config| {
            config.twonly_score_visibility = TwonlyScoreVisibility::Nobody;
        })?;
        let mut nobody_content = proto::EncryptedContent {
            sender_twonly_score: Some(999),
            ..Default::default()
        };
        let mut transaction = database.pool.begin().await?;
        decorate_content(&ctx, &mut transaction, 7, &mut nobody_content, false).await?;
        transaction.rollback().await?;
        assert_eq!(nobody_content.sender_twonly_score, None);

        Ok(())
    }
}
