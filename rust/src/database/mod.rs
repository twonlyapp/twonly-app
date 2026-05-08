use crate::error::{Result, TwonlyError};
use sqlx::sqlite::{SqliteConnectOptions, SqlitePoolOptions};
use sqlx::{ConnectOptions, SqlitePool};
use std::time::Duration;

pub(crate) mod tables;

pub(crate) struct Database {
    pub(crate) pool: SqlitePool,
}

impl Database {
    pub(crate) async fn new(
        db_path: &String,
        encryption_key: Option<&str>,
        read_only: bool,
    ) -> Result<Self> {
        let db_url = format!("sqlite://{}", db_path);

        let log_statements_level = if std::env::var("SQLX_LOG_STATEMENTS").is_ok() {
            tracing::log::LevelFilter::Info
        } else {
            tracing::log::LevelFilter::Off
        };

        let mut connect_options = format!("{db_url}?mode=rwc")
            .parse::<SqliteConnectOptions>()?
            .log_statements(log_statements_level)
            .journal_mode(sqlx::sqlite::SqliteJournalMode::Wal)
            .foreign_keys(true)
            .read_only(read_only)
            .busy_timeout(Duration::from_millis(5000))
            .pragma("recursive_triggers", "ON")
            .log_slow_statements(tracing::log::LevelFilter::Warn, Duration::from_millis(500));

        if let Some(encryption_key) = encryption_key {
            connect_options = connect_options.pragma("key", format!("'{}'", encryption_key));
        }

        let pool = SqlitePoolOptions::new()
            .acquire_timeout(Duration::from_secs(5))
            .max_connections(10)
            .connect_with(connect_options)
            .await?;

        sqlx::migrate!("./src/database/migrations")
            .run(&pool)
            .await
            .map_err(|e| {
                tracing::error!("migration error: {:?}", e);
                TwonlyError::Generic(format!("Migration error: {}", e))
            })?;

        Ok(Self { pool })
    }

    pub(crate) async fn create_backup(
        &self,
        output_path: &str,
        encryption_key: Option<&str>,
    ) -> Result<()> {
        if let Some(key) = encryption_key {
            let mut conn = self
                .pool
                .acquire()
                .await
                .map_err(|e| TwonlyError::Generic(e.to_string()))?;

            sqlx::query("ATTACH DATABASE ? AS backup KEY ?")
                .bind(output_path)
                .bind(key)
                .execute(&mut *conn)
                .await
                .map_err(|e| TwonlyError::Generic(format!("Attach failed: {}", e)))?;

            sqlx::query("SELECT sqlcipher_export('backup')")
                .execute(&mut *conn)
                .await
                .map_err(|e| TwonlyError::Generic(format!("Export failed: {}", e)))?;

            sqlx::query("DETACH DATABASE backup")
                .execute(&mut *conn)
                .await
                .map_err(|e| TwonlyError::Generic(format!("Detach failed: {}", e)))?;
        } else {
            sqlx::query("VACUUM INTO ?")
                .bind(output_path)
                .execute(&self.pool)
                .await
                .map_err(|e| TwonlyError::Generic(format!("Backup failed: {}", e)))?;
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use crate::database::tables::received_messages::ReceivedMessage;

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
        ReceivedMessage::insert(&db.pool, "sender1", b"hello world")
            .await
            .unwrap();

        // 2. Try to open with WRONG key
        let result = Database::new(&db_path, Some("wrong_password"), false).await;
        assert!(
                result.is_err(),
                "Opening with wrong key should fail. If this passes, the database might not be encrypted!"
            );

        // 3. Open with CORRECT key again
        let db = Database::new(&db_path, Some(key), false).await.unwrap();
        let messages = ReceivedMessage::get_all(&db.pool).await.unwrap();
        assert_eq!(messages.len(), 1);
        assert_eq!(messages[0].sender_id, "sender1");
        assert_eq!(messages[0].content, b"hello world");
    }

    #[tokio::test]
    async fn test_database_backup_encrypted() {
        let _ = pretty_env_logger::try_init();
        let dir = tempdir().unwrap();
        let db_path = dir.path().join("test_enc.sqlite").display().to_string();
        let backup_path = dir.path().join("backup_enc.sqlite").display().to_string();
        let key = "secure_password";

        let db = Database::new(&db_path, Some(key), false).await.unwrap();
        ReceivedMessage::insert(&db.pool, "sender1", b"hello world")
            .await
            .unwrap();

        db.create_backup(&backup_path, Some(key)).await.unwrap();

        // 1. Verify it cannot be opened with wrong key
        let result = Database::new(&backup_path, Some("wrong_password"), false).await;
        assert!(
            result.is_err(),
            "Encrypted backup should fail with wrong key"
        );

        // 2. Open backup with correct key and verify data
        let backup_db = Database::new(&backup_path, Some(key), false).await.unwrap();
        let messages = ReceivedMessage::get_all(&backup_db.pool).await.unwrap();
        assert_eq!(messages.len(), 1);
        assert_eq!(messages[0].sender_id, "sender1");
    }

    #[tokio::test]
    async fn test_database_backup_plaintext() {
        let _ = pretty_env_logger::try_init();
        let dir = tempdir().unwrap();
        let db_path = dir.path().join("test_plain.sqlite").display().to_string();
        let backup_path = dir.path().join("backup_plain.sqlite").display().to_string();

        let db = Database::new(&db_path, None, false).await.unwrap();
        ReceivedMessage::insert(&db.pool, "sender1", b"hello world")
            .await
            .unwrap();

        db.create_backup(&backup_path, None).await.unwrap();

        // Open backup and verify
        let backup_db = Database::new(&backup_path, None, false).await.unwrap();
        let messages = ReceivedMessage::get_all(&backup_db.pool).await.unwrap();
        assert_eq!(messages.len(), 1);
        assert_eq!(messages[0].sender_id, "sender1");
    }
}
