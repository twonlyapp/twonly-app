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

#[cfg(test)]
mod avatar_activity_tests;
mod changes;
#[cfg(test)]
mod chat_activity_tests;
#[cfg(test)]
mod chat_archive_tests;
pub mod contact_groups;
pub mod contacts;
#[cfg(test)]
mod defaults_tests;
pub mod diagnostics;
#[cfg(test)]
mod durability_tests;
pub mod groups;
pub mod key_verifications;
#[cfg(test)]
mod storage_tests;
#[cfg(test)]
mod wal_tests;

mod legacy_import;
pub(crate) mod legacy_upgrade;
pub mod mediafiles;
pub mod messages;
pub mod patch;
mod raw_executor;
pub mod reactions;
pub mod receipts;
pub mod recovery;
pub mod stickers;
pub mod stories;
pub(crate) mod transaction;
pub mod user_discovery;
pub(crate) mod watch;
pub mod webxdc;
pub(crate) mod writer_holder;

pub const APP_DATABASE_FILE: &str = "app_db.sqlite";

pub const APP_SCHEMA_VERSION: i64 = 17;

/// User-owned application tables in the current Rust schema. Rust-only outbox
/// tables are deliberately absent because they are reconstructed locally.
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
    "contact_groups",
    "contact_group_members",
];

/// Tables copied one-to-one from the legacy Drift schema. Contact labels and
/// shortcuts need a typed transformation into the unified contact-group tables.
pub const LEGACY_COPY_TABLES: &[&str] = &[
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
];

#[derive(Clone, Debug, PartialEq, Eq)]

pub struct DatabaseChange {
    pub tables: BTreeSet<String>,
}

pub struct AppDatabase {
    pub pool: SqlitePool,
    pub(crate) read_pool: SqlitePool,
    reader_shutdown: Option<tokio_util::sync::CancellationToken>,
    changes: broadcast::Sender<DatabaseChange>,
    pub(crate) operations: std::sync::Arc<crate::database::lifecycle::pool::PoolOperations>,
    source: super::Source,
    external_poll: std::sync::Mutex<std::time::Instant>,
}

impl AppDatabase {
    pub async fn new(db_path: &str, encryption_key: Option<&str>, read_only: bool) -> Result<Self> {
        let (changes, _) = broadcast::channel(256);

        Self::new_with_changes(db_path, encryption_key, read_only, changes).await
    }

    async fn new_with_changes(
        db_path: &str, encryption_key: Option<&str>, read_only: bool,
        changes: broadcast::Sender<DatabaseChange>,
    ) -> Result<Self> {
        crate::database::maintenance::initialize()?;

        let db_url = format!("sqlite://{db_path}");

        let mut options = SqliteConnectOptions::from_str(&format!("{db_url}?mode=rwc"))?
            .create_if_missing(!read_only)
            .foreign_keys(true)
            .read_only(read_only)
            // Connection setup runs before cancellation hooks can be installed.
            .busy_timeout(
                if crate::database::lifecycle::Operation::current().is_some() {
                    Duration::from_millis(50)
                } else {
                    Duration::from_secs(30)
                },
            )
            .pragma("synchronous", "NORMAL")
            .log_statements(tracing::log::LevelFilter::Off)
            .log_slow_statements(tracing::log::LevelFilter::Warn, Duration::from_millis(500));

        if !read_only {
            if cfg!(feature = "sqlite-wal")
                && unsafe { libsqlite3_sys::sqlite3_libversion_number() } < 3_051_003
            {
                return Err(TwonlyError::Generic(
                    "WAL requires a verified SQLite engine".into(),
                ));
            }

            options = options.journal_mode(if cfg!(feature = "sqlite-wal") {
                sqlx::sqlite::SqliteJournalMode::Wal
            } else {
                sqlx::sqlite::SqliteJournalMode::Delete
            });

            options = options.pragma("wal_autocheckpoint", "1000");
        }

        if let Some(key) = encryption_key {
            // Migrates a database still encrypted with the old passphrase-derived
            // key before the pool opens it. See `database::cipher`.
            let key_pragma = crate::database::cipher::key_pragma(db_path, key, read_only).await?;

            options = options.pragma("key", key_pragma);
        }

        Self::open(
            options,
            changes,
            super::Source::new(db_path, encryption_key, read_only),
        )
        .await
    }

    async fn open(
        options: SqliteConnectOptions, changes: broadcast::Sender<DatabaseChange>,
        source: super::Source,
    ) -> Result<Self> {
        let operations =
            std::sync::Arc::new(crate::database::lifecycle::pool::PoolOperations::new());

        // Only the writer looks for commits from other processes. A reader's
        // data_version also moves whenever this writer commits, and the
        // release hook has already published those tables, so a reader that
        // reported it would re-run every watch after each local write.
        let pool = Self::connect_pool(
            options.clone(),
            changes.clone(),
            operations.clone(),
            1,
            false,
            true,
        )
        .await?;

        let (read_pool, reader_shutdown) = if cfg!(feature = "sqlite-wal") && !source.read_only {
            let readers = Self::connect_pool(
                options
                    .read_only(true)
                    .create_if_missing(false)
                    .pragma("query_only", "ON"),
                changes.clone(),
                operations.clone(),
                // The chat list's whole-table summaries re-run on every message.
                // A third reader keeps an open chat's own queries from waiting
                // behind them.
                3,
                true,
                false,
            )
            .await?;

            let stop = tokio_util::sync::CancellationToken::new();

            let cancelled = stop.clone();

            let writer = pool.clone();

            let closing = readers.clone();

            // This supervisor must survive foreground child cancellation.
            // It closes readers when callers close the public writer pool or
            // drop AppDatabase, then releases every native lifetime ticket.
            tokio::spawn(async move {
                tokio::select! { _ = writer.close_event() => {}, _ = cancelled.cancelled() => {} }

                closing.close().await;
            });

            (readers, Some(stop))
        } else {
            (pool.clone(), None)
        };

        Ok(Self {
            pool,
            read_pool,
            reader_shutdown,
            changes,
            operations,
            source,
            external_poll: std::sync::Mutex::new(std::time::Instant::now()),
        })
    }

    async fn connect_pool(
        options: SqliteConnectOptions, changes: broadcast::Sender<DatabaseChange>,
        operations: std::sync::Arc<crate::database::lifecycle::pool::PoolOperations>, maximum: u32,
        lazy: bool, writer: bool,
    ) -> Result<SqlitePool> {
        let connect_operations = operations.clone();

        let acquire_operations = operations.clone();

        let release_operations = operations.clone();

        // SQLx runs the connect and acquire hooks in the acquiring task.
        let holder = writer.then(|| std::sync::Arc::new(writer_holder::WriterHolder::new()));

        let connect_holder = holder.clone();

        let acquire_holder = holder.clone();

        let release_holder = holder.clone();

        let hooks = changes::ConnectionChanges::default();

        let connect_hooks = hooks.clone();

        let acquire_hooks = hooks.clone();

        let acquire_changes = changes.clone();

        let release_changes = changes.clone();

        let pool = SqlitePoolOptions::new()
            .max_connections(maximum)
            .acquire_timeout(Duration::from_secs(30))
            .after_connect(move |connection, _meta| {
                let hooks = connect_hooks.clone();

                let operations = connect_operations.clone();

                if let Some(holder) = &connect_holder {
                    holder.acquired();
                }

                Box::pin(async move {
                    hooks.install(connection).await?;

                    operations.connect(connection).await
                })
            })
            .before_acquire(move |connection, _meta| {
                let operations = acquire_operations.clone();

                let hooks = acquire_hooks.clone();

                let changes = acquire_changes.clone();

                if let Some(holder) = &acquire_holder {
                    holder.acquired();
                }

                Box::pin(async move {
                    operations.acquire(connection).await?;

                    if writer {
                        hooks.observe_external(connection, &changes).await?;
                    }

                    Ok(true)
                })
            })
            .after_release(move |connection, _meta| {
                let hooks = hooks.clone();

                let changes = release_changes.clone();

                let operations = release_operations.clone();

                if let Some(holder) = &release_holder {
                    holder.released();
                }

                Box::pin(async move {
                    if !hooks.release(connection, &changes).await? {
                        return Ok(false);
                    }

                    operations.release(connection).await
                })
            });

        if lazy {
            return Ok(pool.connect_lazy_with(options));
        }

        let pool = pool.connect_with(options).await?;

        // `connect_with` returns its test connection to the pool without the
        // release hook.
        if let Some(holder) = &holder {
            holder.released();
        }

        Ok(pool)
    }

    /// Like `Pool::close`, admission closes on the call, before the first poll.
    /// Idle connections close only once the returned future runs.
    pub fn close(&self) -> impl std::future::Future<Output = ()> + '_ {
        let writer = self.pool.close();

        let readers = self.read_pool.close();

        async move {
            tokio::join!(writer, readers);
        }
    }

    pub(crate) async fn reopen(&self) -> Result<Self> {
        self.reopen_with_key(self.source.key.as_ref().map(|key| key.as_str()))
            .await
    }

    pub(crate) async fn reopen_with_key(&self, key: Option<&str>) -> Result<Self> {
        Self::new_with_changes(
            &self.source.path,
            key,
            self.source.read_only,
            self.changes.clone(),
        )
        .await
    }

    /// Requery active watches after resume/reconnect, including commits made
    /// through a connection in another process that our hooks cannot observe.
    pub fn refresh_watches(&self) {
        let _ = self.changes.send(DatabaseChange {
            tables: BTreeSet::new(),
        });
    }

    pub(crate) async fn poll_external_changes(&self) -> Result<()> {
        {
            let mut last = self.external_poll.lock().unwrap();

            if last.elapsed() < Duration::from_millis(500) {
                return Ok(());
            }

            *last = std::time::Instant::now();
        }

        // A busy writer compares data_version when it is next handed out.
        // Waiting for it here would only hold this watch behind that write.
        if self.pool.size() > 0 && self.pool.num_idle() == 0 {
            return Ok(());
        }

        // before_acquire compares the writer's own data_version, which moves
        // only for commits made by other processes. The pool retains no extra
        // checkout/transaction between polls or on suspend.
        let connection = self.pool.acquire().await?;

        drop(connection);

        Ok(())
    }

    pub async fn run_migrations(&self) -> Result<()> {
        if let Some(operation) = crate::database::lifecycle::Operation::current() {
            operation.check()?;
        }

        sqlx::migrate!("./src/database/app/migrations")
            .run(&self.pool)
            .await
            .map_err(|error| {
                TwonlyError::Generic(format!("App database migration failed: {error}"))
            })?;

        webxdc::queries::restore_notification_content(&self.pool).await?;

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

    pub async fn raw_select(&self, statement: String, arguments: Vec<SqlValue>) -> Result<SqlRows> {
        let rows = bind_arguments(sqlx::query(AssertSqlSafe(statement)), arguments)?
            .fetch_all(&self.pool)
            .await?;

        encode_rows(rows)
    }

    pub async fn raw_execute(
        &self, statement: String, arguments: Vec<SqlValue>,
    ) -> Result<SqlExecutionResult> {
        let first = statement.split_whitespace().next().unwrap_or_default();

        if ["BEGIN", "COMMIT", "END", "ROLLBACK", "SAVEPOINT", "RELEASE"]
            .iter()
            .any(|keyword| first.eq_ignore_ascii_case(keyword))
        {
            return Err(TwonlyError::Generic(
                "Use an owned database transaction for transaction control".into(),
            ));
        }

        let result = bind_arguments(sqlx::query(AssertSqlSafe(statement)), arguments)?
            .execute(&self.pool)
            .await?;

        Ok(SqlExecutionResult {
            affected_rows: result.rows_affected() as i64,
            last_insert_row_id: result.last_insert_rowid(),
        })
    }
}

fn encode_rows(rows: Vec<sqlx::sqlite::SqliteRow>) -> Result<SqlRows> {
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

impl Drop for AppDatabase {
    fn drop(&mut self) {
        if let Some(stop) = &self.reader_shutdown {
            stop.cancel();
        }
    }
}

#[cfg(test)]
mod change_notification_tests {

    use super::*;
    use tempfile::tempdir;
    use tokio::sync::broadcast::error::TryRecvError;

    async fn open() -> (tempfile::TempDir, AppDatabase) {
        let directory = tempdir().unwrap();

        let path = directory.path().join("app_db.sqlite");

        let database = AppDatabase::new(path.to_str().unwrap(), None, false)
            .await
            .unwrap();

        database.run_migrations().await.unwrap();

        // Wait for the migration connection's post-commit release callback.
        {
            let _connection = database.pool.acquire().await.unwrap();
        }

        (directory, database)
    }

    #[tokio::test]

    async fn contact_joined_at_is_nullable_and_persisted() {
        let (_dir, database) = open().await;

        sqlx::query("INSERT INTO contacts(user_id, username) VALUES(7, 'alice')")
            .execute(&database.pool)
            .await
            .unwrap();

        let joined_at: Option<i64> =
            sqlx::query_scalar("SELECT joined_at FROM contacts WHERE user_id = 7")
                .fetch_one(&database.pool)
                .await
                .unwrap();

        assert_eq!(joined_at, None);

        sqlx::query("UPDATE contacts SET joined_at = ? WHERE user_id = 7")
            .bind(1_700_000_000_i64)
            .execute(&database.pool)
            .await
            .unwrap();

        let joined_at: Option<i64> =
            sqlx::query_scalar("SELECT joined_at FROM contacts WHERE user_id = 7")
                .fetch_one(&database.pool)
                .await
                .unwrap();

        assert_eq!(joined_at, Some(1_700_000_000));
    }

    fn insert(key: &str) -> String {
        format!("INSERT INTO app_metadata(key, value) VALUES('{key}', '1')")
    }

    #[tokio::test]

    async fn committed_writes_report_their_tables() {
        let (_dir, database) = open().await;

        let mut changes = database.subscribe();

        database
            .raw_execute(insert("hook"), Vec::new())
            .await
            .unwrap();

        let change = tokio::time::timeout(Duration::from_secs(2), changes.recv())
            .await
            .unwrap()
            .unwrap();

        assert!(change.tables.contains("app_metadata"));
    }

    #[tokio::test]

    async fn rolled_back_writes_report_nothing() {
        let (_dir, database) = open().await;

        let mut changes = database.subscribe();

        let transaction = transaction::TransactionScope::begin(&database.pool)
            .await
            .unwrap();

        transaction
            .execute(insert("discarded"), Vec::new())
            .await
            .unwrap();

        transaction.rollback().await.unwrap();

        let _connection = database.pool.acquire().await.unwrap();

        assert_eq!(changes.try_recv().unwrap_err(), TryRecvError::Empty);
    }

    #[tokio::test]

    async fn a_transaction_reports_every_table_once_on_commit() {
        let (_dir, database) = open().await;

        let mut changes = database.subscribe();

        let transaction = transaction::TransactionScope::begin(&database.pool)
            .await
            .unwrap();

        transaction
            .execute(insert("first"), Vec::new())
            .await
            .unwrap();

        transaction
            .execute(insert("second"), Vec::new())
            .await
            .unwrap();

        // Nothing may reach the UI before the transaction commits.
        assert_eq!(changes.try_recv().unwrap_err(), TryRecvError::Empty);

        transaction.commit().await.unwrap();

        let change = tokio::time::timeout(Duration::from_secs(2), changes.recv())
            .await
            .unwrap()
            .unwrap();

        assert_eq!(change.tables, BTreeSet::from(["app_metadata".to_owned()]));

        assert_eq!(changes.try_recv().unwrap_err(), TryRecvError::Empty);
    }
}
