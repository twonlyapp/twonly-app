/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::proto::client::encrypted_content;
use crate::error::Result;
use sha2::{Digest, Sha256};
use sqlx::{Sqlite, Transaction};

pub(crate) async fn handle_passwordless_recovery(
    transaction: &mut Transaction<'_, Sqlite>,
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
        .execute(&mut **transaction)
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
        .execute(&mut **transaction)
        .await?;
    }
    if let Ok(callbacks) = crate::bridge::callbacks::get_callbacks() {
        tokio::spawn(async move {
            (callbacks.api.recovery_changed)().await;
        });
    }
    Ok(())
}

pub(crate) async fn handle_passwordless_recovery_heartbeat(
    transaction: &mut Transaction<'_, Sqlite>,
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
    .fetch_optional(&mut **transaction)
    .await?
    .flatten();
    let valid = share
        .as_deref()
        .is_some_and(|share| Sha256::digest(share).as_slice() == heartbeat.hash);
    if share.is_none() {
        super::messages::queue_encrypted_content(
            transaction,
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
    .execute(&mut **transaction)
    .await?;
    Ok(())
}
