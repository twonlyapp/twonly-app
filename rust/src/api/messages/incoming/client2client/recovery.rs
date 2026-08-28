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
    #[cfg(not(test))]
    {
        let ctx = Context::get_static()?.clone();
        tokio::spawn(async move {
            if let Err(error) = perform_heartbeat(&ctx).await {
                tracing::warn!(%error, "passwordless recovery heartbeat failed");
            }
        });
    }
    Ok(())
}

pub(crate) async fn perform_heartbeat(ctx: &Arc<Context>) -> Result<()> {
    let now = chrono::Utc::now();
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
            let database = ctx.get_app_database().await;
            let contacts = sqlx::query!(
                r#"SELECT user_id, recovery_secret_share FROM contacts
                   WHERE recovery_is_trusted_friend = 1
                     AND recovery_last_heartbeat IS NULL
                     AND recovery_secret_share IS NOT NULL"#
            )
            .fetch_all(&database.pool)
            .await?;
            drop(database);

            for contact in contacts {
                let content = EncryptedContent {
                    passwordless_recovery: Some(encrypted_content::PasswordLessRecovery {
                        recovery_secret_share: contact.recovery_secret_share,
                        threshold: recovery.threshold,
                        delete: false,
                    }),
                    ..Default::default()
                };
                send_c2c_message_to_contact()
                    .ctx(ctx)
                    .contact_id(contact.user_id)
                    .encrypted_content(content.encode_to_vec())
                    .call()
                    .await?;
            }
            recovery.last_contact_heartbeat = Some(now);
        }
    }

    let database = ctx.get_app_database().await;
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

        let database = ctx.get_app_database().await;
        sqlx::query!(
            "UPDATE contacts SET recovery_contacts_last_heartbeat = ? WHERE user_id = ?",
            now.timestamp(),
            contact.user_id,
        )
        .execute(&database.pool)
        .await?;
    }

    if config != base_config {
        UserConfig::update_json(
            ctx,
            &serde_json::to_string(&base_config)?,
            &serde_json::to_string(&config)?,
        )?;
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
        let database = ctx.get_app_database().await;
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
        let database = ctx.get_app_database().await;

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
        let database = ctx.get_app_database().await;
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
        let database = ctx.get_app_database().await;
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
}
