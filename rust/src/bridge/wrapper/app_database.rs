use std::path::PathBuf;

use crate::bridge::get_twonly_flutter;
pub use crate::database::app::{SqlExecutionResult, SqlRow, SqlRows, SqlValue};
use crate::error::Result;

pub struct RustAppDatabase {}

pub struct LegacyMigrationReport {
    pub legacy_version: i64,
    pub tables: Vec<LegacyTableMigrationCount>,
}

pub struct LegacyTableMigrationCount {
    pub table: String,
    pub rows: i64,
}

impl RustAppDatabase {
    /// Imports the non-Signal tables from a Drift v25 database. The import is
    /// transactional and idempotent. Drift must be closed while this runs.
    pub async fn migrate_legacy_database() -> Result<LegacyMigrationReport> {
        let context = get_twonly_flutter()?;
        let legacy_path = PathBuf::from(&context.config.database_dir).join("twonly.sqlite");
        let app_db = context.app_db.read().await.clone();
        let report = if legacy_path.exists() {
            app_db.import_legacy(&legacy_path).await?
        } else {
            app_db.complete_empty_legacy_import().await?
        };
        Ok(LegacyMigrationReport {
            legacy_version: report.legacy_version,
            tables: report
                .tables
                .into_iter()
                .map(|entry| LegacyTableMigrationCount {
                    table: entry.table,
                    rows: entry.rows,
                })
                .collect(),
        })
    }

    pub async fn legacy_import_complete() -> Result<bool> {
        get_twonly_flutter()?
            .app_db
            .read()
            .await
            .is_legacy_import_complete()
            .await
    }

    pub async fn select(statement: String, arguments: Vec<SqlValue>) -> Result<SqlRows> {
        get_twonly_flutter()?
            .app_db
            .read()
            .await
            .raw_select(statement, arguments)
            .await
    }

    pub async fn execute(
        statement: String,
        arguments: Vec<SqlValue>,
    ) -> Result<SqlExecutionResult> {
        get_twonly_flutter()?
            .app_db
            .read()
            .await
            .raw_execute(statement, arguments)
            .await
    }
}
