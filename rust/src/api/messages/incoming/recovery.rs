/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::messages::outgoing::send_c2c_message_to_contact;
use crate::api::proto::client::encrypted_content;
use crate::api::proto::client::EncryptedContent;
use crate::api::Server;
use crate::bridge::api::ServerResult;
use crate::context::Context;
use crate::error::{twonly_error, Result};
use crate::user_config::UserConfig;
use prost::Message as _;
use sha2::{Digest, Sha256};
use sqlx::{Sqlite, Transaction};
use std::sync::Arc;

pub(crate) async fn handle_passwordless_recovery(
    t: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    recovery: encrypted_content::PasswordLessRecovery,
) -> Result<()> {
    if recovery.delete {
        sqlx::query!(
            r#"
            UPDATE contacts
            SET recovery_contacts_secret_share = NULL,
                recovery_contacts_last_heartbeat = NULL,
                recovery_contacts_threshold = NULL
            WHERE user_id = ?
            "#,
            from_user_id,
        )
        .execute(&mut **t)
        .await?;
    } else if let Some(share) = recovery.recovery_secret_share {
        sqlx::query!(
            r#"
            UPDATE contacts
            SET recovery_contacts_secret_share = ?,
                recovery_contacts_threshold = ?,
                recovery_contacts_last_heartbeat = NULL
            WHERE user_id = ?
            "#,
            share,
            recovery.threshold,
            from_user_id,
        )
        .execute(&mut **t)
        .await?;
    }
    if let Ok(ctx) = Context::get_static() {
        let ctx = ctx.clone();
        tokio::spawn(async move {
            if let Err(error) = perform_heartbeat(&ctx).await {
                tracing::warn!(%error, "passwordless recovery heartbeat failed");
            }
        });
    }
    Ok(())
}

pub async fn perform_heartbeat(ctx: &Arc<Context>) -> Result<()> {
    let now = crate::utils::current_time().with_timezone(&chrono::Utc);
    let base_config = UserConfig::load_required_from(ctx)?;
    let mut config = base_config.clone();

    if let Some(recovery) = config.password_less_recovery.as_mut() {
        let server_due = recovery
            .last_server_heartbeat
            .is_none_or(|last| now.signed_duration_since(last).num_days() > 20);
        if server_due {
            if let Some(encrypted_key) = recovery.encrypted_server_key.clone() {
                if let ServerResult::ErrorCode(_) = Server::register_passwordless_recovery(
                    ctx,
                    encrypted_key,
                    recovery.pin_unlock_token.clone(),
                )
                .await?
                {
                    return Err(twonly_error!("passwordless registration failed: {code}"));
                }
                recovery.last_server_heartbeat = Some(now);
            }
        }

        let contacts_due = recovery
            .last_contact_heartbeat
            .is_none_or(|last| now.signed_duration_since(last).num_hours() >= 24);
        if contacts_due {
            let database = ctx.app_db.read().await.clone();
            // A helper that restored an old backup or lost its local share
            // cannot send a heartbeat. Retry stale confirmations as well as
            // never-confirmed shares so it can become a helper again.
            let contacts = sqlx::query_as::<_, (i64, Vec<u8>)>(
                r#"SELECT user_id, recovery_secret_share FROM contacts
                   WHERE recovery_is_trusted_friend = 1
                     AND (recovery_last_heartbeat IS NULL
                          OR recovery_last_heartbeat <= ?)
                     AND recovery_secret_share IS NOT NULL"#,
            )
            .bind((now - chrono::Duration::days(7)).timestamp())
            .fetch_all(&database.pool)
            .await?;
            drop(database);

            for (contact_id, share) in contacts {
                let content = EncryptedContent {
                    passwordless_recovery: Some(encrypted_content::PasswordLessRecovery {
                        recovery_secret_share: Some(share),
                        threshold: recovery.threshold,
                        delete: false,
                    }),
                    ..Default::default()
                };
                send_c2c_message_to_contact()
                    .ctx(ctx)
                    .contact_id(contact_id)
                    .encrypted_content(content.encode_to_vec())
                    .call()
                    .await?;
            }
            recovery.last_contact_heartbeat = Some(now);
        }
    }

    let database = ctx.app_db.read().await.clone();
    let contacts = sqlx::query!(
        r#"SELECT user_id, recovery_contacts_secret_share FROM contacts
           WHERE recovery_contacts_secret_share IS NOT NULL
             AND (recovery_contacts_last_heartbeat IS NULL
                  OR recovery_contacts_last_heartbeat <= ?)"#,
        (now - chrono::Duration::days(7)).timestamp(),
    )
    .fetch_all(&database.pool)
    .await?;
    drop(database);

    for contact in contacts {
        let Some(share) = contact.recovery_contacts_secret_share else {
            continue;
        };
        let content = EncryptedContent {
            passwordless_recovery_heartbeat: Some(
                encrypted_content::PasswordLessRecoveryHeartbeat {
                    hash: Sha256::digest(share).to_vec(),
                },
            ),
            ..Default::default()
        };

        send_c2c_message_to_contact()
            .ctx(ctx)
            .contact_id(contact.user_id)
            .encrypted_content(content.encode_to_vec())
            .call()
            .await?;

        let database = ctx.app_db.read().await.clone();
        sqlx::query!(
            "UPDATE contacts SET recovery_contacts_last_heartbeat = ? WHERE user_id = ?",
            now.timestamp(),
            contact.user_id,
        )
        .execute(&database.pool)
        .await?;
    }

    if config != base_config {
        let updated_recovery = config.password_less_recovery.as_ref();
        let last_server_heartbeat = updated_recovery.and_then(|r| r.last_server_heartbeat);
        let last_contact_heartbeat = updated_recovery.and_then(|r| r.last_contact_heartbeat);
        let config = UserConfig::update(ctx, |current| {
            if let Some(recovery) = current.password_less_recovery.as_mut() {
                recovery.last_server_heartbeat = last_server_heartbeat;
                recovery.last_contact_heartbeat = last_contact_heartbeat;
            }
        })?;
        if let Ok(callbacks) = crate::bridge::callbacks::get_callbacks() {
            (callbacks.api.user_config_changed)(config).await;
        }
    }
    Ok(())
}

pub(crate) async fn handle_passwordless_recovery_heartbeat(
    t: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    heartbeat: encrypted_content::PasswordLessRecoveryHeartbeat,
) -> Result<()> {
    let share = sqlx::query_scalar!(
        r#"
        SELECT recovery_secret_share
        FROM contacts
        WHERE user_id = ?
        "#,
        from_user_id,
    )
    .fetch_optional(&mut **t)
    .await?
    .flatten();

    let valid = share
        .as_deref()
        .is_some_and(|share| Sha256::digest(share).as_slice() == heartbeat.hash);

    if share.is_none() {
        super::messages::queue_encrypted_content(
            t,
            from_user_id,
            crate::api::proto::client::EncryptedContent {
                passwordless_recovery: Some(encrypted_content::PasswordLessRecovery {
                    recovery_secret_share: None,
                    threshold: 0,
                    delete: true,
                }),
                ..Default::default()
            },
            true,
        )
        .await?;
    }
    sqlx::query!(
        r#"
        UPDATE contacts
        SET recovery_last_heartbeat = CASE
            WHEN ? THEN CAST(strftime('%s', 'now') AS INTEGER)
            ELSE NULL
        END
        WHERE user_id = ?
        "#,
        valid,
        from_user_id,
    )
    .execute(&mut **t)
    .await?;

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    async fn context() -> anyhow::Result<(tempfile::TempDir, Arc<Context>)> {
        let temp = tempfile::tempdir()?;
        let database_dir = temp.path().join("database");
        let data_dir = temp.path().join("data");
        std::fs::create_dir_all(data_dir.join("keyvalue"))?;
        std::fs::write(
            data_dir.join("keyvalue/user.json"),
            serde_json::to_vec(&UserConfig::default())?,
        )?;
        let context = Context::init_for_testing(database_dir, data_dir).await?;
        Ok((temp, context))
    }

    async fn insert_contact(ctx: &Arc<Context>, user_id: i64) -> Result<()> {
        let database = ctx.app_db.read().await.clone();
        sqlx::query!(
            "INSERT INTO contacts(user_id, username, accepted) VALUES (?, ?, 1)",
            user_id,
            format!("user_{user_id}"),
        )
        .execute(&database.pool)
        .await?;
        Ok(())
    }

    #[tokio::test]
    async fn recovery_share_is_stored_and_deleted() -> anyhow::Result<()> {
        let (_temp, ctx) = context().await?;
        insert_contact(&ctx, 7).await?;
        let database = ctx.app_db.read().await.clone();

        let mut transaction = database.pool.begin().await?;
        handle_passwordless_recovery(
            &mut transaction,
            7,
            encrypted_content::PasswordLessRecovery {
                recovery_secret_share: Some(vec![1, 2, 3]),
                threshold: 2,
                delete: false,
            },
        )
        .await?;
        transaction.commit().await?;

        let stored = sqlx::query!(
            "SELECT recovery_contacts_secret_share, recovery_contacts_threshold FROM contacts WHERE user_id = 7"
        )
        .fetch_one(&database.pool)
        .await?;
        assert_eq!(stored.recovery_contacts_secret_share, Some(vec![1, 2, 3]));
        assert_eq!(stored.recovery_contacts_threshold, Some(2));

        let mut transaction = database.pool.begin().await?;
        handle_passwordless_recovery(
            &mut transaction,
            7,
            encrypted_content::PasswordLessRecovery {
                delete: true,
                ..Default::default()
            },
        )
        .await?;
        transaction.commit().await?;

        let deleted = sqlx::query!(
            "SELECT recovery_contacts_secret_share, recovery_contacts_threshold FROM contacts WHERE user_id = 7"
        )
        .fetch_one(&database.pool)
        .await?;
        assert_eq!(deleted.recovery_contacts_secret_share, None);
        assert_eq!(deleted.recovery_contacts_threshold, None);
        Ok(())
    }

    #[tokio::test]
    async fn valid_and_invalid_heartbeat_update_the_expected_state() -> anyhow::Result<()> {
        let (_temp, ctx) = context().await?;
        insert_contact(&ctx, 8).await?;
        let database = ctx.app_db.read().await.clone();
        let share = vec![4, 5, 6];
        sqlx::query!(
            "UPDATE contacts SET recovery_secret_share = ? WHERE user_id = 8",
            share,
        )
        .execute(&database.pool)
        .await?;

        let mut transaction = database.pool.begin().await?;
        handle_passwordless_recovery_heartbeat(
            &mut transaction,
            8,
            encrypted_content::PasswordLessRecoveryHeartbeat {
                hash: Sha256::digest([4, 5, 6]).to_vec(),
            },
        )
        .await?;
        transaction.commit().await?;
        let valid =
            sqlx::query_scalar!("SELECT recovery_last_heartbeat FROM contacts WHERE user_id = 8")
                .fetch_one(&database.pool)
                .await?;
        assert!(valid.is_some());

        let mut transaction = database.pool.begin().await?;
        handle_passwordless_recovery_heartbeat(
            &mut transaction,
            8,
            encrypted_content::PasswordLessRecoveryHeartbeat { hash: vec![0; 32] },
        )
        .await?;
        transaction.commit().await?;
        let invalid =
            sqlx::query_scalar!("SELECT recovery_last_heartbeat FROM contacts WHERE user_id = 8")
                .fetch_one(&database.pool)
                .await?;
        assert_eq!(invalid, None);
        Ok(())
    }

    #[tokio::test]
    async fn heartbeat_without_share_queues_deletion_response() -> anyhow::Result<()> {
        let (_temp, ctx) = context().await?;
        insert_contact(&ctx, 9).await?;
        let database = ctx.app_db.read().await.clone();
        let mut transaction = database.pool.begin().await?;
        handle_passwordless_recovery_heartbeat(
            &mut transaction,
            9,
            encrypted_content::PasswordLessRecoveryHeartbeat { hash: vec![1; 32] },
        )
        .await?;
        transaction.commit().await?;

        let queued = sqlx::query_scalar!("SELECT COUNT(*) FROM receipts WHERE contact_id = 9")
            .fetch_one(&database.pool)
            .await?;
        assert_eq!(queued, 1);
        Ok(())
    }

    #[tokio::test]
    async fn heartbeat_distributes_shares_to_every_unconfirmed_helper() -> anyhow::Result<()> {
        let (_temp, ctx) = context().await?;
        let database = ctx.app_db.read().await.clone();
        let recovery = serde_json::from_value(serde_json::json!({"threshold": 2}))?;
        UserConfig::update(&ctx, |config| {
            config.password_less_recovery = Some(recovery);
        })?;
        for user_id in [7, 8, 9] {
            insert_contact(&ctx, user_id).await?;
            sqlx::query("UPDATE contacts SET recovery_is_trusted_friend = 1, recovery_secret_share = ? WHERE user_id = ?")
                .bind(vec![user_id as u8, 42])
                .bind(user_id)
                .execute(&database.pool).await?;
        }

        perform_heartbeat(&ctx).await?;
        let queued: Vec<(i64, Vec<u8>)> =
            sqlx::query_as("SELECT contact_id, message FROM receipts ORDER BY contact_id")
                .fetch_all(&database.pool)
                .await?;
        assert_eq!(queued.len(), 3);
        for (contact_id, bytes) in queued {
            let message = crate::api::proto::client::Message::decode(bytes.as_slice())?;
            let content = EncryptedContent::decode(message.encrypted_content.unwrap().as_slice())?;
            let recovery = content.passwordless_recovery.unwrap();
            assert_eq!(
                recovery.recovery_secret_share,
                Some(vec![contact_id as u8, 42])
            );
            assert_eq!(recovery.threshold, 2);
        }
        Ok(())
    }

    #[tokio::test]
    async fn heartbeat_retries_stale_helpers_that_cannot_confirm_a_lost_share() -> anyhow::Result<()>
    {
        let (_temp, ctx) = context().await?;
        let database = ctx.app_db.read().await.clone();
        let recovery = serde_json::from_value(serde_json::json!({"threshold": 2}))?;
        UserConfig::update(&ctx, |config| {
            config.password_less_recovery = Some(recovery);
        })?;
        let now = crate::utils::current_time().timestamp();
        // 7 has never acknowledged; 8 acknowledged before losing its share;
        // 9 still confirms possession of its share regularly.
        for (user_id, heartbeat) in [(7, None), (8, Some(now - 8 * 86400)), (9, Some(now))] {
            insert_contact(&ctx, user_id).await?;
            sqlx::query("UPDATE contacts SET recovery_is_trusted_friend = 1, recovery_secret_share = ?, recovery_last_heartbeat = ? WHERE user_id = ?")
                .bind(vec![user_id as u8, 42]).bind(heartbeat).bind(user_id)
                .execute(&database.pool).await?;
        }

        perform_heartbeat(&ctx).await?;
        let recipients: Vec<i64> =
            sqlx::query_scalar("SELECT contact_id FROM receipts ORDER BY contact_id")
                .fetch_all(&database.pool)
                .await?;
        assert_eq!(recipients, vec![7, 8]);

        // Keep the daily throttle: reconnecting immediately must not enqueue
        // the same recovery shares again.
        perform_heartbeat(&ctx).await?;
        let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM receipts")
            .fetch_one(&database.pool)
            .await?;
        assert_eq!(count, 2);
        Ok(())
    }
}
