/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::error::{Result, TwonlyError};
use sqlx::sqlite::{SqliteConnectOptions, SqlitePoolOptions};
use sqlx::{AssertSqlSafe, Column, ConnectOptions, Row, SqlitePool, TypeInfo, ValueRef};
use std::collections::BTreeSet;
use std::str::FromStr;
use std::time::Duration;
use tokio::sync::broadcast;

mod legacy_import;
pub mod tables;

pub const APP_DATABASE_FILE: &str = "app_db.sqlite";
pub const APP_SCHEMA_VERSION: i64 = 2;

pub const APPLICATION_TABLES: &[&str] = &[
    "contacts",
    "groups",
    "media_files",
    "messages",
    "message_histories",
    "reactions",
    "group_members",
    "receipts",
    "received_receipts",
    "message_actions",
    "group_histories",
    "key_verifications",
    "verification_tokens",
    "user_discovery_announced_users",
    "user_discovery_user_relations",
    "user_discovery_other_promotions",
    "user_discovery_own_promotions",
    "user_discovery_shares",
    "shortcuts",
    "shortcut_members",
    "labels",
    "contact_labels",
];

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct DatabaseChange {
    pub tables: BTreeSet<String>,
}

pub struct AppDatabase {
    pub pool: SqlitePool,
    changes: broadcast::Sender<DatabaseChange>,
}

impl AppDatabase {
    pub async fn new(db_path: &str, encryption_key: Option<&str>, read_only: bool) -> Result<Self> {
        let db_url = format!("sqlite://{db_path}");
        let mut options = SqliteConnectOptions::from_str(&format!("{db_url}?mode=rwc"))?
            .create_if_missing(!read_only)
            .journal_mode(sqlx::sqlite::SqliteJournalMode::Delete)
            .foreign_keys(true)
            .read_only(read_only)
            .busy_timeout(Duration::from_secs(30))
            .pragma("synchronous", "FULL")
            .log_statements(tracing::log::LevelFilter::Off)
            .log_slow_statements(tracing::log::LevelFilter::Warn, Duration::from_millis(500));
        if let Some(key) = encryption_key {
            options = options.pragma("key", format!("'{key}'"));
        }
        let pool = SqlitePoolOptions::new()
            // The compatibility executor uses statement-based transactions.
            // Keeping one connection guarantees BEGIN, all statements, and
            // COMMIT are executed on that same native connection.
            .max_connections(1)
            .acquire_timeout(Duration::from_secs(30))
            .connect_with(options)
            .await?;
        let (changes, _) = broadcast::channel(256);
        Ok(Self { pool, changes })
    }

    pub async fn run_migrations(&self) -> Result<()> {
        sqlx::migrate!("./src/database/app/migrations")
            .run(&self.pool)
            .await
            .map_err(|error| {
                TwonlyError::Generic(format!("App database migration failed: {error}"))
            })?;
        sqlx::query!(
            r#"
            INSERT INTO app_metadata(key, value)
            VALUES('schema_version', ?)
            ON CONFLICT(key) DO UPDATE SET value = excluded.value
            "#,
            APP_SCHEMA_VERSION.to_string()
        )
        .execute(&self.pool)
        .await?;
        Ok(())
    }

    pub fn subscribe(&self) -> broadcast::Receiver<DatabaseChange> {
        self.changes.subscribe()
    }

    pub fn notify_committed<'a>(&self, tables: impl IntoIterator<Item = &'a str>) {
        let tables = tables.into_iter().map(str::to_owned).collect();
        let _ = self.changes.send(DatabaseChange { tables });
    }

    pub async fn raw_select(&self, statement: String, arguments: Vec<SqlValue>) -> Result<SqlRows> {
        let rows = bind_arguments(sqlx::query(AssertSqlSafe(statement)), arguments)?
            .fetch_all(&self.pool)
            .await?;
        let columns = rows
            .first()
            .map(|row| {
                row.columns()
                    .iter()
                    .map(|column| column.name().to_owned())
                    .collect()
            })
            .unwrap_or_default();
        let mut output_rows = Vec::with_capacity(rows.len());
        for row in rows {
            let mut values = Vec::with_capacity(row.len());
            for index in 0..row.len() {
                let raw = row.try_get_raw(index)?;
                let value = if raw.is_null() {
                    SqlValue::null()
                } else {
                    match raw.type_info().name() {
                        "INTEGER" | "INT" | "BOOLEAN" | "DATETIME" => {
                            SqlValue::integer(row.try_get(index)?)
                        }
                        "REAL" | "FLOAT" | "DOUBLE" => SqlValue::real(row.try_get(index)?),
                        "BLOB" => SqlValue::blob(row.try_get(index)?),
                        _ => SqlValue::text(row.try_get(index)?),
                    }
                };
                values.push(value);
            }
            output_rows.push(SqlRow { values });
        }
        Ok(SqlRows {
            columns,
            rows: output_rows,
        })
    }

    pub async fn raw_execute(
        &self,
        statement: String,
        arguments: Vec<SqlValue>,
    ) -> Result<SqlExecutionResult> {
        let result = bind_arguments(sqlx::query(AssertSqlSafe(statement)), arguments)?
            .execute(&self.pool)
            .await?;
        Ok(SqlExecutionResult {
            affected_rows: result.rows_affected() as i64,
            last_insert_row_id: result.last_insert_rowid(),
        })
    }

    pub async fn create_backup(&self, output_path: &str, encryption_key: &str) -> Result<()> {
        let mut connection = self.pool.acquire().await?;
        // SQLCipher-only syntax cannot be described by the SQLite database
        // used by SQLx during compile-time query preparation.
        sqlx::query(r#"ATTACH DATABASE ? AS backup KEY ?"#)
            .bind(output_path)
            .bind(encryption_key)
            .execute(&mut *connection)
            .await
            .map_err(|error| TwonlyError::Generic(format!("Attach app backup failed: {error}")))?;
        let export = sqlx::query(r#"SELECT sqlcipher_export('backup')"#)
            .execute(&mut *connection)
            .await;
        let detach = sqlx::query(r#"DETACH DATABASE backup"#)
            .execute(&mut *connection)
            .await;
        export.map_err(|error| TwonlyError::Generic(format!("App export failed: {error}")))?;
        detach
            .map_err(|error| TwonlyError::Generic(format!("Detach app backup failed: {error}")))?;
        Ok(())
    }
}

#[derive(Clone, Debug, PartialEq)]
pub struct SqlValue {
    /// 0 = null, 1 = integer, 2 = real, 3 = text, 4 = blob.
    pub kind: u8,
    pub integer_value: Option<i64>,
    pub real_value: Option<f64>,
    pub text_value: Option<String>,
    pub blob_value: Option<Vec<u8>>,
}

impl SqlValue {
    fn null() -> Self {
        Self {
            kind: 0,
            integer_value: None,
            real_value: None,
            text_value: None,
            blob_value: None,
        }
    }

    fn integer(value: i64) -> Self {
        Self {
            kind: 1,
            integer_value: Some(value),
            real_value: None,
            text_value: None,
            blob_value: None,
        }
    }

    fn real(value: f64) -> Self {
        Self {
            kind: 2,
            integer_value: None,
            real_value: Some(value),
            text_value: None,
            blob_value: None,
        }
    }

    fn text(value: String) -> Self {
        Self {
            kind: 3,
            integer_value: None,
            real_value: None,
            text_value: Some(value),
            blob_value: None,
        }
    }

    fn blob(value: Vec<u8>) -> Self {
        Self {
            kind: 4,
            integer_value: None,
            real_value: None,
            text_value: None,
            blob_value: Some(value),
        }
    }
}

#[derive(Clone, Debug, PartialEq)]
pub struct SqlRows {
    pub columns: Vec<String>,
    pub rows: Vec<SqlRow>,
}

#[derive(Clone, Debug, PartialEq)]
pub struct SqlRow {
    pub values: Vec<SqlValue>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct SqlExecutionResult {
    pub affected_rows: i64,
    pub last_insert_row_id: i64,
}

fn bind_arguments<'q>(
    mut query: sqlx::query::Query<'q, sqlx::Sqlite, sqlx::sqlite::SqliteArguments>,
    arguments: Vec<SqlValue>,
) -> Result<sqlx::query::Query<'q, sqlx::Sqlite, sqlx::sqlite::SqliteArguments>> {
    for argument in arguments {
        query = match argument {
            SqlValue { kind: 0, .. } => query.bind(Option::<i64>::None),
            SqlValue {
                kind: 1,
                integer_value: Some(value),
                ..
            } => query.bind(value),
            SqlValue {
                kind: 2,
                real_value: Some(value),
                ..
            } => query.bind(value),
            SqlValue {
                kind: 3,
                text_value: Some(value),
                ..
            } => query.bind(value),
            SqlValue {
                kind: 4,
                blob_value: Some(value),
                ..
            } => query.bind(value),
            invalid => {
                return Err(TwonlyError::Generic(format!(
                    "Invalid SQL value received from bridge: {invalid:?}"
                )))
            }
        };
    }
    Ok(query)
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct MigrationReport {
    pub legacy_version: i64,
    pub tables: Vec<TableMigrationCount>,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct TableMigrationCount {
    pub table: String,
    pub rows: i64,
}
