/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::proto::client::{encrypted_content, EncryptedContent, Message};
use crate::context::Context;
use crate::database::app::contacts::table::UpdateContact;
use crate::database::app::groups::native::Group;
use crate::error::Result;
use crate::services::groups::GroupService;
use encrypted_content::error_messages::Type;
use prost::Message as _;
use sqlx::{Sqlite, Transaction};
use std::sync::Arc;

const CONTACT_HANDSHAKE_REPAIR_INTERVAL_SECS: i64 = 60 * 60;

async fn claim_contact_handshake_repair(
    t: &mut Transaction<'_, Sqlite>, contact_id: i64,
) -> Result<bool> {
    let now = crate::utils::current_time().timestamp();
    let retry_before = now - CONTACT_HANDSHAKE_REPAIR_INTERVAL_SECS;

    Ok(sqlx::query!(
        r#"INSERT INTO contact_handshake_repairs(contact_id, requested_at) VALUES (?, ?)
           ON CONFLICT(contact_id) DO UPDATE SET requested_at = excluded.requested_at
           WHERE contact_handshake_repairs.requested_at IS NULL
              OR contact_handshake_repairs.requested_at <= ?"#,
        contact_id,
        now,
        retry_before,
    )
    .execute(&mut **t)
    .await?
    .rows_affected()
        != 0)
}

fn queued_content(bytes: &[u8]) -> Option<EncryptedContent> {
    let message = Message::decode(bytes).ok()?;
    EncryptedContent::decode(message.encrypted_content?.as_slice()).ok()
}

pub(super) fn requires_contact_acceptance(content: &EncryptedContent, contact_id: i64) -> bool {
    content.contact_request.is_none()
        && content.error_messages.is_none()
        && (content.story.is_some()
            || content
                .group_id
                .as_deref()
                .is_some_and(|id| Group::is_direct_chat_id(id, contact_id)))
}

pub(crate) async fn release_after_contact_acceptance(
    t: &mut Transaction<'_, Sqlite>, contact_id: i64,
) -> Result<()> {
    sqlx::query!(
        "UPDATE contact_handshake_repairs SET awaiting_acceptance_since = NULL WHERE contact_id = ?",
        contact_id,
    )
    .execute(&mut **t)
    .await?;
    sqlx::query!(
        r#"UPDATE receipts SET mark_for_retry_after_accepted = NULL,
               mark_for_retry = CAST(strftime('%s', 'now') AS INTEGER),
               ack_by_server_at = NULL, last_retry = NULL
           WHERE contact_id = ? AND mark_for_retry_after_accepted IS NOT NULL"#,
        contact_id,
    )
    .execute(&mut **t)
    .await?;
    Ok(())
}

pub(super) async fn queue_contact_acceptance_error(
    t: &mut Transaction<'_, Sqlite>, from_user_id: i64, receipt_id: &str,
) -> Result<()> {
    let now = crate::utils::current_time().timestamp();
    let retry_before = now - CONTACT_HANDSHAKE_REPAIR_INTERVAL_SECS;

    // The reliable mailbox retains the original until acceptance. Each new
    // reply triggers another drain, so minting an error on every redelivery
    // would sustain the exchange even after the sender stops making requests.
    let claimed = sqlx::query!(
        r#"INSERT INTO contact_handshake_repairs(contact_id, notified_at) VALUES (?, ?)
           ON CONFLICT(contact_id) DO UPDATE SET notified_at = excluded.notified_at
           WHERE contact_handshake_repairs.notified_at IS NULL
              OR contact_handshake_repairs.notified_at <= ?"#,
        from_user_id,
        now,
        retry_before,
    )
    .execute(&mut **t)
    .await?
    .rows_affected()
        != 0;

    if claimed {
        super::messages::queue_encrypted_content(
            t,
            from_user_id,
            EncryptedContent {
                error_messages: Some(encrypted_content::ErrorMessages {
                    r#type: Type::ErrorProcessingMessageCreatedAccountRequestInstead as i32,
                    related_receipt_id: receipt_id.to_owned(),
                }),
                ..Default::default()
            },
            false,
        )
        .await?;
    }

    Ok(())
}

pub(crate) async fn handle_error_message(
    ctx: &Arc<Context>, t: &mut Transaction<'_, Sqlite>, from_user_id: i64, group_id: Option<&str>,
    error: encrypted_content::ErrorMessages,
) -> Result<()> {
    let error_type = Type::try_from(error.r#type)?;

    tracing::warn!(
        ?error_type,
        from_user_id,
        related_receipt_id = error.related_receipt_id,
        "received client error message"
    );

    match error_type {
        Type::ErrorProcessingMessageCreatedAccountRequestInstead => {
            // Only our own direct chat with the sender is evidence of a
            // friendship. A row in anyone else's says nothing about them.
            let direct_chat_id = Group::direct_chat_id(ctx.user_id().await?, from_user_id);

            // A peer's missing contact state is not a local unfriend action.
            // Ignore stale errors after the related outbox entry was delivered.
            let Some(related) = sqlx::query!(
                r#"SELECT c.accepted != 0 OR EXISTS (
                       SELECT 1 FROM group_members m JOIN groups g ON g.group_id = m.group_id
                       WHERE m.contact_id = c.user_id AND g.is_direct_chat = 1
                         AND g.group_id = ?
                   ) AS "established!: bool", r.message
                   FROM contacts c JOIN receipts r ON r.contact_id = c.user_id
                   WHERE c.user_id = ? AND c.blocked = 0 AND c.deleted_by_user = 0
                     AND c.account_deleted = 0 AND r.receipt_id = ?"#,
                direct_chat_id,
                from_user_id,
                &error.related_receipt_id
            )
            .fetch_optional(&mut **t)
            .await?
            else {
                return Ok(());
            };

            // Handshakes and error replies do not require an accepted direct
            // chat. Repairing a rejection of either with another handshake
            // turns a peer's error response into a new request on every round.
            let Some(content) = queued_content(&related.message) else {
                return Ok(());
            };
            if content.contact_request.is_some() || content.error_messages.is_some() {
                tracing::info!("Ignoring a contact-state error for a protocol reply");
                return Ok(());
            }

            // Local friendship does not prove the peer has accepted us. Keep
            // their explicit refusal as separate, durable delivery state.
            let first_wait = sqlx::query!(
                r#"INSERT INTO contact_handshake_repairs(contact_id, awaiting_acceptance_since)
                   VALUES (?, CAST(strftime('%s', 'now') AS INTEGER))
                   ON CONFLICT(contact_id) DO UPDATE SET
                       awaiting_acceptance_since = excluded.awaiting_acceptance_since
                   WHERE contact_handshake_repairs.awaiting_acceptance_since IS NULL"#,
                from_user_id,
            )
            .execute(&mut **t)
            .await?
            .rows_affected()
                != 0;
            sqlx::query!(
                "UPDATE receipts SET mark_for_retry_after_accepted = CAST(strftime('%s', 'now') AS INTEGER) \
                 WHERE receipt_id = ? AND contact_id = ?",
                &error.related_receipt_id,
                from_user_id,
            )
            .execute(&mut **t)
            .await?;

            if first_wait {
                let queued = sqlx::query!(
                    "SELECT receipt_id, message FROM receipts WHERE contact_id = ?",
                    from_user_id,
                )
                .fetch_all(&mut **t)
                .await?;
                for receipt in queued {
                    if queued_content(&receipt.message)
                        .is_some_and(|content| requires_contact_acceptance(&content, from_user_id))
                    {
                        sqlx::query!(
                            "UPDATE receipts SET mark_for_retry_after_accepted = CAST(strftime('%s', 'now') AS INTEGER) \
                             WHERE receipt_id = ? AND contact_id = ?",
                            receipt.receipt_id,
                            from_user_id,
                        )
                        .execute(&mut **t)
                        .await?;
                    }
                }
            }

            if related.established {
                UpdateContact::builder()
                    .user_id(from_user_id)
                    .accepted(true)
                    .requested(false)
                    .requested_by_user(false)
                    .build()
                    .update(t)
                    .await?;

                // Acknowledging the request is not accepting the friendship.
                // Keep waiting even if the repair's retry interval has elapsed.
                if !first_wait {
                    return Ok(());
                }
                // A burst of errors can refer to different messages, and an
                // ACK removes the repair from the outbox. Bound repairs per
                // peer durably so neither case (nor a restart) creates a new
                // request for every error envelope.
                if !claim_contact_handshake_repair(t, from_user_id).await? {
                    tracing::info!("Contact handshake repair was already requested recently");

                    return Ok(());
                }

                let queued = sqlx::query_scalar!(
                    "SELECT message FROM receipts WHERE contact_id = ? AND \
                     contact_will_sends_receipt != 0",
                    from_user_id,
                )
                .fetch_all(&mut **t)
                .await?;
                if queued.iter().any(|bytes| {
                    queued_content(bytes).is_some_and(|content| {
                        content.contact_request.is_some_and(|request| {
                            request.r#type
                                == encrypted_content::contact_request::Type::Request as i32
                        })
                    })
                }) {
                    return Ok(());
                }

                super::messages::queue_encrypted_content(
                    t,
                    from_user_id,
                    EncryptedContent {
                        contact_request: Some(encrypted_content::ContactRequest {
                            r#type: encrypted_content::contact_request::Type::Request as i32,
                        }),
                        ..Default::default()
                    },
                    true,
                )
                .await?;
                return Ok(());
            }

            // This is a new, unaccepted contact. Park the receipt until their
            // accept arrives without inventing an incoming request or changing
            // any local friendship flags.
        }
        Type::GroupNotFoundOrNotAMember => {
            if let Some(group_id) = group_id {
                // The repair refreshes the group from the server and owns its
                // own transaction, so it has to run once this one commits.
                let ctx = ctx.clone();

                let group_id = group_id.to_owned();

                let related_receipt_id = error.related_receipt_id;

                crate::database::lifecycle::spawn(async move {
                    if let Err(error) = GroupService::new(&ctx)
                        .handle_membership_error(from_user_id, group_id, related_receipt_id)
                        .await
                    {
                        tracing::warn!("group membership repair failed: {error}");
                    }
                });
            }
        }
        Type::SessionOutOfSync | Type::UnknownMessageType => {}
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::api::messages::incoming::messages::queue_encrypted_content;
    use crate::api::proto::client::EncryptedContent;

    async fn test_context(directory: &tempfile::TempDir) -> Result<Arc<Context>> {
        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;
        crate::api::ApiRuntime::close(&ctx).await?;
        crate::user_config::UserConfig::save_json(
            &ctx,
            r#"{"userId":42,"username":"me","displayName":"Me"}"#,
        )?;
        ctx.inject_test_user_id(42).await?;
        Ok(ctx)
    }

    fn contact_error(receipt_id: &str) -> encrypted_content::ErrorMessages {
        encrypted_content::ErrorMessages {
            r#type: Type::ErrorProcessingMessageCreatedAccountRequestInstead as i32,
            related_receipt_id: receipt_id.into(),
        }
    }

    #[tokio::test]
    async fn an_existing_friend_waits_for_peer_acceptance_before_sending_again() -> Result<()> {
        use crate::api::messages::incoming::{contact::handle_contact_request, messages};
        use crate::services::outbox_dispatch::OutboxDispatchService;

        let directory = tempfile::tempdir()?;
        let ctx = test_context(&directory).await?;
        let database = ctx.app_db.read().await.clone();
        sqlx::query(
            "INSERT INTO contacts(user_id, username, accepted) VALUES (7, 'friend', 1), (8, 'other', 1)",
        )
        .execute(&database.pool)
        .await?;
        let content = EncryptedContent {
            group_id: Some(Group::direct_chat_id(42, 7)),
            text_message: Some(encrypted_content::TextMessage {
                sender_message_id: "message".into(),
                text: "hello".into(),
                ..Default::default()
            }),
            ..Default::default()
        };
        let mut t = database.pool.begin().await?;
        let original = queue_encrypted_content(&mut t, 7, content.clone(), true).await?;
        let already_queued = queue_encrypted_content(&mut t, 7, content.clone(), true).await?;
        handle_error_message(&ctx, &mut t, 7, None, contact_error(&original)).await?;
        let repair: String = sqlx::query_scalar(
            "SELECT receipt_id FROM receipts WHERE contact_id = 7 AND mark_for_retry_after_accepted IS NULL",
        )
        .fetch_one(&mut *t)
        .await?;
        messages::handle_sender_delivery_receipt(&mut t, 7, &repair).await?;
        let newly_queued = queue_encrypted_content(&mut t, 7, content, true).await?;

        // Shared groups and the handshake itself can still exchange traffic.
        let group_receipt = queue_encrypted_content(
            &mut t,
            7,
            EncryptedContent {
                group_id: Some("shared-group".into()),
                ..Default::default()
            },
            true,
        )
        .await?;
        let group_waits: bool = sqlx::query_scalar(
            "SELECT mark_for_retry_after_accepted IS NOT NULL FROM receipts WHERE receipt_id = ?",
        )
        .bind(&group_receipt)
        .fetch_one(&mut *t)
        .await?;
        assert!(!group_waits);
        messages::handle_sender_delivery_receipt(&mut t, 7, &group_receipt).await?;

        // Neither elapsed retry timers nor a different peer's accept can release it.
        sqlx::query(
            "UPDATE receipts SET last_retry = 0, ack_by_server_at = NULL, mark_for_retry = 0",
        )
        .execute(&mut *t)
        .await?;
        handle_contact_request(
            &ctx,
            &mut t,
            8,
            encrypted_content::ContactRequest {
                r#type: encrypted_content::contact_request::Type::Accept as i32,
            },
        )
        .await?;
        t.commit().await?;

        // Reopening the database must retain the peer's acceptance requirement.
        let key = ctx
            .key_manager
            .lock()
            .await
            .main_key
            .get_database_key(crate::keys::DatabaseKey::AppDb);
        database.close().await;
        let database = Arc::new(
            crate::database::app::AppDatabase::new(
                directory
                    .path()
                    .join("db")
                    .join(crate::database::app::APP_DATABASE_FILE)
                    .to_str()
                    .unwrap(),
                Some(&key),
                false,
            )
            .await?,
        );
        *ctx.app_db.write().await = database.clone();

        assert!(!messages::has_pending_receipts(&ctx).await?);
        for receipt in [&original, &already_queued, &newly_queued] {
            assert!(messages::prepare_queued_receipt(&ctx, receipt)
                .await?
                .is_none());
            messages::send_queued_receipt(&ctx, receipt).await?;
            assert!(!OutboxDispatchService::new(&ctx).hand_to_os(receipt).await?);
        }

        let mut t = database.pool.begin().await?;
        handle_contact_request(
            &ctx,
            &mut t,
            7,
            encrypted_content::ContactRequest {
                r#type: encrypted_content::contact_request::Type::Accept as i32,
            },
        )
        .await?;
        t.commit().await?;
        assert!(messages::has_pending_receipts(&ctx).await?);
        let waiting: i64 = sqlx::query_scalar(
            "SELECT COUNT(*) FROM receipts WHERE mark_for_retry_after_accepted IS NOT NULL",
        )
        .fetch_one(&database.pool)
        .await?;
        assert_eq!(waiting, 0);
        let retained: i64 =
            sqlx::query_scalar("SELECT COUNT(*) FROM receipts WHERE contact_id = 7")
                .fetch_one(&database.pool)
                .await?;
        assert_eq!(retained, 3, "acceptance resumes the original receipts");
        Ok(())
    }

    #[tokio::test]
    async fn contact_handshake_repair_budget_is_transactional_and_survives_reopening() -> Result<()>
    {
        use crate::database::app::AppDatabase;

        let directory = tempfile::tempdir()?;
        let path = directory.path().join("app.sqlite");
        let database = AppDatabase::new(path.to_str().unwrap(), None, false).await?;
        database.run_migrations().await?;
        sqlx::query("INSERT INTO contacts(user_id, username) VALUES (7, 'alice'), (8, 'bob')")
            .execute(&database.pool)
            .await?;
        let mut t = database.pool.begin().await?;
        queue_contact_acceptance_error(&mut t, 7, "inbound").await?;
        assert!(claim_contact_handshake_repair(&mut t, 7).await?);
        assert!(!claim_contact_handshake_repair(&mut t, 7).await?);
        t.rollback().await?;
        let mut t = database.pool.begin().await?;
        queue_contact_acceptance_error(&mut t, 7, "inbound").await?;
        assert!(claim_contact_handshake_repair(&mut t, 7).await?);
        assert!(claim_contact_handshake_repair(&mut t, 8).await?);
        t.commit().await?;
        database.close().await;

        let database = AppDatabase::new(path.to_str().unwrap(), None, false).await?;
        database.run_migrations().await?;
        let mut t = database.pool.begin().await?;
        assert!(!claim_contact_handshake_repair(&mut t, 7).await?);
        assert!(!claim_contact_handshake_repair(&mut t, 8).await?);
        sqlx::query("DELETE FROM receipts").execute(&mut *t).await?;
        queue_contact_acceptance_error(&mut t, 7, "redelivery").await?;
        let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM receipts")
            .fetch_one(&mut *t)
            .await?;
        assert_eq!(
            count, 0,
            "a sent contact error must stay suppressed after reopening"
        );
        sqlx::query("UPDATE contact_handshake_repairs SET requested_at = requested_at - ? WHERE contact_id = 7")
            .bind(CONTACT_HANDSHAKE_REPAIR_INTERVAL_SECS)
            .execute(&mut *t)
            .await?;
        assert!(claim_contact_handshake_repair(&mut t, 7).await?);
        assert!(!claim_contact_handshake_repair(&mut t, 8).await?);
        t.commit().await?;
        database.close().await;
        Ok(())
    }

    #[tokio::test]
    async fn encrypted_errors_do_not_request_an_end_to_end_acknowledgement() -> Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx = test_context(&directory).await?;
        let database = ctx.app_db.read().await.clone();
        sqlx::query("INSERT INTO contacts(user_id, username, accepted) VALUES (7, 'friend', 1)")
            .execute(&database.pool)
            .await?;
        let mut t = database.pool.begin().await?;
        let delivery = super::super::handle_encrypted(
            &ctx,
            &mut t,
            7,
            "error-receipt",
            EncryptedContent {
                error_messages: Some(contact_error("already-delivered")),
                ..Default::default()
            },
        )
        .await?;
        assert_eq!(delivery, super::super::Delivery::Withhold);
        Ok(())
    }

    #[tokio::test]
    async fn contact_errors_reuse_an_existing_outgoing_request() -> Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx = test_context(&directory).await?;
        let database = ctx.app_db.read().await.clone();
        sqlx::query("INSERT INTO contacts(user_id, username, accepted) VALUES (7, 'friend', 1)")
            .execute(&database.pool)
            .await?;
        let mut t = database.pool.begin().await?;
        let request = queue_encrypted_content(
            &mut t,
            7,
            EncryptedContent {
                contact_request: Some(encrypted_content::ContactRequest {
                    r#type: encrypted_content::contact_request::Type::Request as i32,
                }),
                ..Default::default()
            },
            true,
        )
        .await?;
        let original =
            queue_encrypted_content(&mut t, 7, EncryptedContent::default(), true).await?;
        handle_error_message(&ctx, &mut t, 7, None, contact_error(&original)).await?;
        super::super::messages::handle_sender_delivery_receipt(&mut t, 7, &request).await?;
        handle_error_message(&ctx, &mut t, 7, None, contact_error(&original)).await?;
        let remaining: Vec<String> = sqlx::query_scalar("SELECT receipt_id FROM receipts")
            .fetch_all(&mut *t)
            .await?;
        assert_eq!(remaining, vec![original]);
        Ok(())
    }

    #[tokio::test]
    async fn repeated_contact_errors_do_not_multiply_handshake_requests() -> Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx = test_context(&directory).await?;
        let database = ctx.app_db.read().await.clone();
        sqlx::query("INSERT INTO contacts(user_id, username, accepted) VALUES (7, 'friend', 1)")
            .execute(&database.pool)
            .await?;
        let mut t = database.pool.begin().await?;
        let original =
            queue_encrypted_content(&mut t, 7, EncryptedContent::default(), true).await?;
        for _ in 0..32 {
            handle_error_message(&ctx, &mut t, 7, None, contact_error(&original)).await?;
        }
        let repairs: Vec<String> =
            sqlx::query_scalar("SELECT receipt_id FROM receipts WHERE receipt_id != ?")
                .bind(&original)
                .fetch_all(&mut *t)
                .await?;
        assert_eq!(
            repairs.len(),
            1,
            "fresh error IDs must not create fresh repairs"
        );
        super::super::messages::handle_sender_delivery_receipt(&mut t, 7, &repairs[0]).await?;
        t.commit().await?;

        // An ACK removes the repair but must not let the next error recreate it.
        let mut t = database.pool.begin().await?;
        sqlx::query("UPDATE contact_handshake_repairs SET requested_at = 0 WHERE contact_id = 7")
            .execute(&mut *t)
            .await?;
        let second = queue_encrypted_content(&mut t, 7, EncryptedContent::default(), true).await?;
        for receipt in [&original, &second] {
            handle_error_message(&ctx, &mut t, 7, None, contact_error(receipt)).await?;
        }
        let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM receipts")
            .fetch_one(&mut *t)
            .await?;
        assert_eq!(
            count, 2,
            "only the two original messages should remain queued"
        );
        Ok(())
    }

    #[tokio::test]
    async fn contact_errors_for_handshakes_and_errors_do_not_start_another_handshake() -> Result<()>
    {
        let directory = tempfile::tempdir()?;
        let ctx = test_context(&directory).await?;
        let database = ctx.app_db.read().await.clone();
        sqlx::query("INSERT INTO contacts(user_id, username, accepted) VALUES (7, 'friend', 1)")
            .execute(&database.pool)
            .await?;
        let mut t = database.pool.begin().await?;
        for content in [
            EncryptedContent {
                contact_request: Some(encrypted_content::ContactRequest {
                    r#type: encrypted_content::contact_request::Type::Request as i32,
                }),
                ..Default::default()
            },
            EncryptedContent {
                contact_request: Some(encrypted_content::ContactRequest {
                    r#type: encrypted_content::contact_request::Type::Accept as i32,
                }),
                ..Default::default()
            },
            EncryptedContent {
                error_messages: Some(contact_error("peer-message")),
                ..Default::default()
            },
        ] {
            let receipt = queue_encrypted_content(&mut t, 7, content, true).await?;
            handle_error_message(&ctx, &mut t, 7, None, contact_error(&receipt)).await?;
            let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM receipts")
                .fetch_one(&mut *t)
                .await?;
            assert_eq!(
                count, 1,
                "a rejected protocol reply must not create another request"
            );
            super::super::messages::handle_sender_delivery_receipt(&mut t, 7, &receipt).await?;
        }
        Ok(())
    }

    #[tokio::test]
    async fn a_peer_contact_error_preserves_friends_and_ignores_stale_errors() -> Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;
        crate::user_config::UserConfig::save_json(
            &ctx,
            r#"{"userId":42,"username":"me","displayName":"Me"}"#,
        )?;
        ctx.inject_test_user_id(42).await?;
        let database = ctx.app_db.read().await.clone();
        sqlx::query(
            "INSERT INTO contacts(user_id, username, accepted, requested_by_user, blocked, \
             deleted_by_user) VALUES
             (7, 'friend', 1, 0, 0, 0), (8, 'pending', 0, 1, 0, 0),
             (9, 'blocked', 0, 0, 1, 1), (10, 'stale', 1, 0, 0, 0), (11, 'direct', 0, 0, 0, 0),
             (12, 'intruder', 0, 0, 0, 0)",
        )
        .execute(&database.pool)
        .await?;
        // 12 has a row in the direct chat with 7, which is not theirs and so
        // proves no friendship with them.
        for (contact, chat) in [(11, 11), (7, 7), (12, 7)] {
            let group_id = Group::direct_chat_id(42, chat);
            sqlx::query(
                "INSERT OR IGNORE INTO groups(group_id, group_name, is_direct_chat) VALUES (?, \
                 'Direct', 1)",
            )
            .bind(&group_id)
            .execute(&database.pool)
            .await?;
            sqlx::query("INSERT INTO group_members(group_id, contact_id) VALUES (?, ?)")
                .bind(&group_id)
                .bind(contact)
                .execute(&database.pool)
                .await?;
        }
        let mut t = database.pool.begin().await?;
        for id in [7, 8, 9, 10, 11, 12] {
            let receipt =
                queue_encrypted_content(&mut t, id, EncryptedContent::default(), true).await?;
            handle_error_message(
                &ctx,
                &mut t,
                id,
                None,
                encrypted_content::ErrorMessages {
                    r#type: Type::ErrorProcessingMessageCreatedAccountRequestInstead as i32,
                    related_receipt_id: if id == 10 {
                        "already-delivered".into()
                    } else {
                        receipt.clone()
                    },
                },
            )
            .await?;
            let state: (bool, bool, bool, bool) = sqlx::query_as(
                "SELECT accepted, requested, requested_by_user, deleted_by_user FROM contacts \
                 WHERE user_id = ?",
            )
            .bind(id)
            .fetch_one(&mut *t)
            .await?;
            assert_eq!(
                state,
                match id {
                    7 | 10 | 11 => (true, false, false, false),
                    8 => (false, false, true, false),
                    9 => (false, false, false, true),
                    12 => (false, false, false, false),
                    _ => unreachable!(),
                }
            );
            let parked: bool = sqlx::query_scalar(
                "SELECT mark_for_retry_after_accepted IS NOT NULL FROM receipts WHERE receipt_id \
                 = ?",
            )
            .bind(&receipt)
            .fetch_one(&mut *t)
            .await?;
            assert_eq!(parked, matches!(id, 7 | 8 | 11 | 12));
        }
        Ok(())
    }
}
