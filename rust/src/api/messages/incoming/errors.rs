/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::proto::client::encrypted_content;
use crate::context::Context;
use crate::database::app::contacts::table::UpdateContact;
use crate::error::Result;
use crate::services::groups::GroupService;
use encrypted_content::error_messages::Type;
use sqlx::{Sqlite, Transaction};
use std::sync::Arc;

pub(crate) async fn handle_error_message(
    ctx: &Arc<Context>, t: &mut Transaction<'_, Sqlite>, from_user_id: i64, group_id: Option<&str>,
    error: encrypted_content::ErrorMessages,
) -> Result<()> {
    let error_type = Type::try_from(error.r#type)?;

    tracing::warn!(?error_type, from_user_id, "received client error message");

    match error_type {
        Type::ErrorProcessingMessageCreatedAccountRequestInstead => {
            // A peer's missing contact state is not a local unfriend action.
            // Ignore stale errors after the related outbox entry was delivered.
            let Some(established) = sqlx::query_scalar::<_, bool>(
                r#"SELECT c.accepted != 0 OR EXISTS (
                       SELECT 1 FROM group_members m JOIN groups g ON g.group_id = m.group_id
                       WHERE m.contact_id = c.user_id AND g.is_direct_chat = 1
                   ) FROM contacts c
                   WHERE c.user_id = ? AND c.blocked = 0 AND c.deleted_by_user = 0
                     AND c.account_deleted = 0 AND EXISTS (
                         SELECT 1 FROM receipts r WHERE r.receipt_id = ? AND r.contact_id = c.user_id
                     )"#,
            )
            .bind(from_user_id)
            .bind(&error.related_receipt_id)
            .fetch_optional(&mut **t)
            .await? else {
                return Ok(());
            };

            if established {
                UpdateContact::builder()
                    .user_id(from_user_id)
                    .accepted(true)
                    .requested(false)
                    .requested_by_user(false)
                    .build()
                    .update(t)
                    .await?;
                // Keep retrying the original message and repair the peer's
                // handshake without turning our existing friend into a request.
                sqlx::query("UPDATE receipts SET mark_for_retry_after_accepted = NULL WHERE receipt_id = ? AND contact_id = ?")
                    .bind(&error.related_receipt_id)
                    .bind(from_user_id)
                    .execute(&mut **t)
                    .await?;
                super::messages::queue_encrypted_content(
                    t,
                    from_user_id,
                    crate::api::proto::client::EncryptedContent {
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

            sqlx::query!(
                r#"
                UPDATE receipts
                SET mark_for_retry_after_accepted = CAST(strftime('%s', 'now') AS INTEGER)
                WHERE receipt_id = ? AND contact_id = ?
                "#,
                error.related_receipt_id,
                from_user_id,
            )
            .execute(&mut **t)
            .await?;

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

    #[tokio::test]
    async fn a_peer_contact_error_preserves_friends_and_ignores_stale_errors() -> Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;
        let database = ctx.app_db.read().await.clone();
        for statement in [
            "INSERT INTO contacts(user_id, username, accepted, requested_by_user, blocked, deleted_by_user) VALUES
             (7, 'friend', 1, 0, 0, 0), (8, 'pending', 0, 1, 0, 0),
             (9, 'blocked', 0, 0, 1, 1), (10, 'stale', 1, 0, 0, 0), (11, 'direct', 0, 0, 0, 0)",
            "INSERT INTO groups(group_id, group_name, is_direct_chat) VALUES ('direct', 'Direct', 1)",
            "INSERT INTO group_members(group_id, contact_id) VALUES ('direct', 11)",
        ] {
            sqlx::query(statement).execute(&database.pool).await?;
        }
        let mut t = database.pool.begin().await?;
        for id in [7, 8, 9, 10, 11] {
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
                "SELECT accepted, requested, requested_by_user, deleted_by_user FROM contacts WHERE user_id = ?"
            ).bind(id).fetch_one(&mut *t).await?;
            assert_eq!(
                state,
                match id {
                    7 | 10 | 11 => (true, false, false, false),
                    8 => (false, false, true, false),
                    9 => (false, false, false, true),
                    _ => unreachable!(),
                }
            );
            let parked: bool = sqlx::query_scalar("SELECT mark_for_retry_after_accepted IS NOT NULL FROM receipts WHERE receipt_id = ?")
                .bind(&receipt).fetch_one(&mut *t).await?;
            assert_eq!(parked, id == 8);
        }
        Ok(())
    }
}
