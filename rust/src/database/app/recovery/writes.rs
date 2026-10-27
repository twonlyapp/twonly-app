use super::table::RecoveryShare;
use crate::error::{Result, TwonlyError};
use sqlx::{Sqlite, Transaction};
use std::collections::HashSet;

pub async fn store_shares(
    tx: &mut Transaction<'_, Sqlite>, shares: Vec<RecoveryShare>,
) -> Result<()> {
    let mut seen = HashSet::new();

    for share in &shares {
        if share.secret.is_empty() || !seen.insert(share.contact_id) {
            return Err(TwonlyError::Generic(
                "invalid or duplicate recovery share".into(),
            ));
        }
    }

    for share in shares {
        let updated = sqlx::query!(
            r#"
                UPDATE contacts
                SET recovery_is_trusted_friend = 1,
                    recovery_last_heartbeat = NULL,
                    recovery_secret_share = ?
                WHERE user_id = ?
            "#,
            share.secret,
            share.contact_id,
        )
        .execute(&mut **tx)
        .await?
        .rows_affected();

        if updated != 1 {
            return Err(TwonlyError::Generic(
                "recovery contact no longer exists".into(),
            ));
        }
    }

    Ok(())
}
