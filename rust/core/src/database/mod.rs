pub(crate) mod contact;
use crate::bridge::error::{Result, TwonlyError};
use sqlx::migrate::MigrateDatabase;
use sqlx::sqlite::{SqliteConnectOptions, SqlitePoolOptions};
use sqlx::{ConnectOptions, Sqlite, SqlitePool};
use std::time::Duration;

pub(crate) struct Database {
    pub(crate) pool: SqlitePool,
}

impl Database {
    pub(crate) async fn new(db_path: &String) -> Result<Self> {
        let db_url = format!("sqlite://{}", db_path);

        match Sqlite::database_exists(&db_url).await {
            Ok(true) => {
                tracing::debug!("database exists");
            }
            Ok(false) => {
                tracing::error!("could not open the sqlite3 database");
                return Err(TwonlyError::DatabaseNotFound);
            }
            Err(e) => {
                tracing::error!(
                    "Could not check if database exists: {:?}, attempting to create",
                    e
                );
                return Err(TwonlyError::DatabaseNotFound);
            }
        }

        tracing::debug!("Creating database connection pool");

        let log_statements_level = if std::env::var("SQLX_LOG_STATEMENTS").is_ok() {
            tracing::log::LevelFilter::Info
        } else {
            tracing::log::LevelFilter::Off
        };

        let connect_options = format!("{db_url}?mode=rwc")
            .parse::<SqliteConnectOptions>()?
            .log_statements(log_statements_level)
            .journal_mode(sqlx::sqlite::SqliteJournalMode::Wal)
            .foreign_keys(true)
            .busy_timeout(Duration::from_millis(5000))
            .pragma("recursive_triggers", "ON")
            .log_slow_statements(tracing::log::LevelFilter::Warn, Duration::from_millis(500));

        let pool = SqlitePoolOptions::new()
            .acquire_timeout(Duration::from_secs(5))
            .max_connections(10)
            .connect_with(connect_options)
            .await?;

        Ok(Self { pool: pool })
    }
}
