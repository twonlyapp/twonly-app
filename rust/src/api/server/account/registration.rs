//! Registration may initialize an empty account, never rename an existing one.

use crate::context::Context;
use crate::error::{Result, TwonlyError};
use crate::user_config::UserConfig;
use sqlx::{AssertSqlSafe, SqlitePool};

fn dirty() -> TwonlyError {
    TwonlyError::Generic(
        "Registration requires cleared local account data and a fresh app start".into(),
    )
}

pub(super) async fn ensure_clean(ctx: &Context) -> Result<()> {
    if UserConfig::load_from(ctx)?.is_some()
        || crate::keys::restore::pending(&ctx.secure_storage)?.is_some()
        || ctx.secure_storage.read("api_auth_token")?.is_some()
    {
        return Err(dirty());
    }

    let keys = ctx.key_manager.lock().await;
    if keys.user_id.is_some() || keys.backup_password.is_some() {
        return Err(dirty());
    }
    drop(keys);

    let app = ctx.app_db.read().await.clone();
    empty_account_tables(&app.pool, false).await?;

    let signal = ctx.rust_db.read().await.clone();
    empty_account_tables(&signal.pool, true).await
}

async fn empty_account_tables(pool: &SqlitePool, signal: bool) -> Result<()> {
    let tables = sqlx::query_scalar::<_, String>(
        "SELECT name FROM sqlite_schema WHERE type = 'table' \
         AND name NOT GLOB 'sqlite_*' AND name != '_sqlx_migrations'",
    )
    .fetch_all(pool)
    .await?;

    for table in tables {
        let predicate = match (signal, table.as_str()) {
            // A failed registration may have generated our own unpublished
            // prekeys. Keep them for retries; no peer state is permitted.
            (true, "signal_pre_keys" | "signal_signed_pre_keys" | "signal_kyber_pre_keys") => {
                continue;
            }
            (false, "app_metadata") => {
                " WHERE key NOT IN ('legacy_import_complete', 'legacy_schema_version', \
                  'verification_policy_refresh', 'schema_version', \
                  'webxdc_notification_content_restored')"
            }
            (false, "own_custom_avatar") => {
                " WHERE webp IS NOT NULL OR sha256 IS NOT NULL OR width IS NOT NULL \
                  OR height IS NOT NULL OR source_revision != 0 OR accepted_contacts_only != 1"
            }
            (false, "contact_metadata_refresh_budget") => " WHERE next_attempt_at != 0",
            _ => "",
        };
        // The identifier comes from SQLite's own catalog and is quoted even
        // for an unexpected table. New user-owned tables fail closed by default.
        let table = table.replace('"', "\"\"");
        let present = sqlx::query_scalar::<_, i64>(AssertSqlSafe(format!(
            "SELECT EXISTS(SELECT 1 FROM \"{table}\"{predicate})"
        )))
        .fetch_one(pool)
        .await?;
        if present != 0 {
            return Err(TwonlyError::Generic(format!(
                "Registration requires cleared local account data; {table} still contains data"
            )));
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn registration_accepts_empty_databases_and_unpublished_retry_keys() -> Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;
        ensure_clean(&ctx).await?;

        let signal = ctx.rust_db.read().await.clone();
        sqlx::query("INSERT INTO signal_pre_keys(pre_key_id, record_bytes) VALUES (1, X'01')")
            .execute(&signal.pool)
            .await?;
        ensure_clean(&ctx).await
    }

    #[tokio::test]
    async fn registration_refuses_old_account_contacts_and_peer_sessions() -> Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;
        let app = ctx.app_db.read().await.clone();
        sqlx::query("INSERT INTO contacts(user_id, username) VALUES (7, 'old_friend')")
            .execute(&app.pool)
            .await?;
        assert!(ensure_clean(&ctx).await.is_err());
        sqlx::query("DELETE FROM contacts")
            .execute(&app.pool)
            .await?;

        let signal = ctx.rust_db.read().await.clone();
        sqlx::query(
            "INSERT INTO signal_sessions(name, device_id, record_bytes) VALUES ('7', 1, X'01')",
        )
        .execute(&signal.pool)
        .await?;
        assert!(ensure_clean(&ctx).await.is_err());
        Ok(())
    }

    #[tokio::test]
    async fn registration_refuses_credentials_and_recovery_state() -> Result<()> {
        let directory = tempfile::tempdir()?;
        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;
        ctx.key_manager.lock().await.user_id = Some(7);
        assert!(ensure_clean(&ctx).await.is_err());
        ctx.key_manager.lock().await.user_id = None;

        let imported = crate::keys::KeyManager::generate()?;
        crate::keys::restore::stage(&ctx.secure_storage, imported)?;
        assert!(ensure_clean(&ctx).await.is_err());
        crate::keys::restore::discard(&ctx.secure_storage)?;

        ctx.secure_storage.write("api_auth_token", "old token")?;
        assert!(ensure_clean(&ctx).await.is_err());
        Ok(())
    }
}
