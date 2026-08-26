/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::proto::client::encrypted_content;
use crate::error::{Result, TwonlyError};
use crate::utils::milliseconds_to_seconds;
use sqlx::{Sqlite, Transaction};
use std::sync::atomic::{AtomicI64, Ordering};

static LAST_PUSH_KEY_REQUEST: AtomicI64 = AtomicI64::new(0);
pub(crate) async fn handle_push_key(
    tx: &mut Transaction<'_, Sqlite>,
    user: i64,
    value: encrypted_content::PushKeys,
) -> Result<()> {
    use encrypted_content::push_keys::Type;
    match Type::try_from(value.r#type)
        .map_err(|_| TwonlyError::Generic("invalid push-key message".into()))?
    {
        Type::Update => {
            let (Some(id), Some(key), Some(created_at)) =
                (value.key_id, value.key, value.created_at)
            else {
                return Err(TwonlyError::Generic("incomplete push-key update".into()));
            };
            sqlx::query!(
                r#"
                INSERT INTO contact_push_keys(contact_id, key_id, key, created_at)
                VALUES (?, ?, ?, ?)
                ON CONFLICT(contact_id, key_id)
                DO UPDATE SET key = excluded.key, created_at = excluded.created_at
                "#,
                user,
                id,
                key,
                milliseconds_to_seconds(created_at),
            )
            .execute(&mut **tx)
            .await?;
            Ok(())
        }
        Type::Request => {
            let now = std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap_or_default()
                .as_secs() as i64;
            let previous = LAST_PUSH_KEY_REQUEST.load(Ordering::Relaxed);
            if now - previous < 60
                || LAST_PUSH_KEY_REQUEST
                    .compare_exchange(previous, now, Ordering::AcqRel, Ordering::Relaxed)
                    .is_err()
            {
                return Ok(());
            }
            if let Ok(callbacks) = crate::bridge::callbacks::get_callbacks() {
                tokio::spawn(async move {
                    (callbacks.api.push_key_requested)(user).await;
                });
            }
            Ok(())
        }
    }
}
