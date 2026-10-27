/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::error::{Result, TwonlyError};
use sqlx::sqlite::{SqliteConnectOptions, SqlitePoolOptions};
use sqlx::{ConnectOptions, SqlitePool};
use std::time::Duration;

pub struct Database {
    pub pool: SqlitePool,
    pub(crate) operations: std::sync::Arc<crate::database::lifecycle::pool::PoolOperations>,
    source: super::Source,
}

impl Database {
    pub async fn new(
        db_path: &String, encryption_key: Option<&str>, read_only: bool,
    ) -> Result<Self> {
        crate::database::maintenance::initialize()?;

        let db_url = format!("sqlite://{}", db_path);

        let log_statements_level = if std::env::var("SQLX_LOG_STATEMENTS").is_ok() {
            tracing::log::LevelFilter::Info
        } else {
            tracing::log::LevelFilter::Off
        };

        let mut connect_options = format!("{db_url}?mode=rwc")
            .parse::<SqliteConnectOptions>()?
            .log_statements(log_statements_level)
            .foreign_keys(true)
            .read_only(read_only)
            // Bound initial PRAGMAs before after_connect installs cancellation.
            .busy_timeout(
                if crate::database::lifecycle::Operation::current().is_some() {
                    Duration::from_millis(50)
                } else {
                    Duration::from_secs(30)
                },
            )
            .pragma("synchronous", "NORMAL")
            .pragma("recursive_triggers", "ON")
            .log_slow_statements(tracing::log::LevelFilter::Warn, Duration::from_millis(500));

        if !read_only {
            // Signal's journal policy is independent of the application reader
            // pool rollout. Read-only opens must preserve either source mode.
            connect_options = connect_options.journal_mode(sqlx::sqlite::SqliteJournalMode::Delete);
        }

        if let Some(encryption_key) = encryption_key {
            // Migrates a database still encrypted with the old passphrase-derived
            // key before the pool opens it. See `database::cipher`.
            let key_pragma =
                crate::database::cipher::key_pragma(db_path, encryption_key, read_only).await?;

            connect_options = connect_options.pragma("key", key_pragma);
        }

        Self::open(
            connect_options,
            super::Source::new(db_path, encryption_key, read_only),
        )
        .await
    }

    async fn open(connect_options: SqliteConnectOptions, source: super::Source) -> Result<Self> {
        let operations =
            std::sync::Arc::new(crate::database::lifecycle::pool::PoolOperations::new());

        let connect_operations = operations.clone();

        let acquire_operations = operations.clone();

        let release_operations = operations.clone();

        let pool = SqlitePoolOptions::new()
            .acquire_timeout(Duration::from_secs(30))
            .max_connections(10)
            .after_connect(move |connection, _meta| {
                let operations = connect_operations.clone();

                Box::pin(async move { operations.connect(connection).await })
            })
            .before_acquire(move |connection, _meta| {
                let operations = acquire_operations.clone();

                Box::pin(async move { operations.acquire(connection).await.map(|_| true) })
            })
            .after_release(move |connection, _meta| {
                let operations = release_operations.clone();

                Box::pin(async move { operations.release(connection).await })
            })
            .connect_with(connect_options)
            .await?;

        Ok(Self {
            pool,
            operations,
            source,
        })
    }

    pub(crate) async fn reopen(&self) -> Result<Self> {
        self.reopen_with_key(self.source.key.as_ref().map(|key| key.as_str()))
            .await
    }

    pub(crate) async fn reopen_with_key(&self, key: Option<&str>) -> Result<Self> {
        Self::new(&self.source.path, key, self.source.read_only).await
    }

    pub async fn run_migrations(&self) -> Result<()> {
        if let Some(operation) = crate::database::lifecycle::Operation::current() {
            operation.check()?;
        }

        sqlx::migrate!("./src/database/signal/migrations")
            .run(&self.pool)
            .await
            .map_err(|e| {
                tracing::error!("migration error: {:?}", e);

                TwonlyError::Generic(format!("Migration error: {}", e))
            })?;

        Ok(())
    }

    pub(crate) async fn check_integrity(&self) -> Result<()> {
        let integrity = sqlx::query_scalar!(r#"PRAGMA integrity_check"#)
            .fetch_one(&self.pool)
            .await
            .map_err(|e| TwonlyError::Generic(format!("Integrity check query failed: {}", e)))?;

        let integrity = integrity
            .ok_or_else(|| TwonlyError::Generic("Integrity check returned no result".to_owned()))?;

        if integrity.to_lowercase() == "ok" {
            Ok(())
        } else {
            Err(TwonlyError::Generic(format!(
                "Database integrity check failed: {}",
                integrity
            )))
        }
    }
}

#[cfg(test)]
mod tests {

    use super::*;
    use tempfile::tempdir;

    #[tokio::test]

    async fn test_database_encryption_and_migrations() {
        let _ = pretty_env_logger::try_init();

        let dir = tempdir().unwrap();

        let db_path = dir.path().join("test.sqlite").display().to_string();

        let key = "secure_password";

        // 1. Create and initialize database with key
        let db = Database::new(&db_path, Some(key), false).await.unwrap();

        db.run_migrations().await.unwrap();

        // 2. Try to open with WRONG key
        let result = Database::new(&db_path, Some("wrong_password"), false).await;

        assert!(
            result.is_err(),
            "Opening with wrong key should fail. If this passes, the database might not be \
             encrypted!"
        );

        // 3. Open with CORRECT key again
        Database::new(&db_path, Some(key), false).await.unwrap();
    }

    #[tokio::test]

    async fn test_database_backup_encrypted() {
        let _ = pretty_env_logger::try_init();

        let dir = tempdir().unwrap();

        let db_path = dir.path().join("test_enc.sqlite").display().to_string();

        let backup_path = dir.path().join("backup_enc.sqlite").display().to_string();

        let key = "secure_password";

        let db = Database::new(&db_path, Some(key), false).await.unwrap();

        db.run_migrations().await.unwrap();

        crate::database::snapshot::create(
            &db.pool,
            std::path::Path::new(&backup_path),
            &crate::database::lifecycle::Operation::new(Duration::from_secs(10)),
        )
        .await
        .unwrap();

        // 1. Verify it cannot be opened with wrong key
        let result = Database::new(&backup_path, Some("wrong_password"), false).await;

        assert!(
            result.is_err(),
            "Encrypted backup should fail with wrong key"
        );

        // 2. Open backup with correct key and verify data
        Database::new(&backup_path, Some(key), false).await.unwrap();
    }

    #[tokio::test]

    async fn test_database_backup_plaintext() {
        let _ = pretty_env_logger::try_init();

        let dir = tempdir().unwrap();

        let db_path = dir.path().join("test_plain.sqlite").display().to_string();

        let backup_path = dir.path().join("backup_plain.sqlite").display().to_string();

        let db = Database::new(&db_path, None, false).await.unwrap();

        db.run_migrations().await.unwrap();

        crate::database::snapshot::create(
            &db.pool,
            std::path::Path::new(&backup_path),
            &crate::database::lifecycle::Operation::new(Duration::from_secs(10)),
        )
        .await
        .unwrap();

        // Open backup and verify
        Database::new(&backup_path, None, false).await.unwrap();
    }
}
