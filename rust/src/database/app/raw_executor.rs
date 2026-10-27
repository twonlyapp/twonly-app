//! Raw-SQL compatibility methods for historical tests and bridge assertions.

use super::{bind_arguments, encode_rows, SqlExecutionResult, SqlRows, SqlValue};
use crate::error::Result;
use sqlx::AssertSqlSafe;

impl super::transaction::TransactionScope {
    pub async fn select(&self, statement: String, arguments: Vec<SqlValue>) -> Result<SqlRows> {
        let mut guard = self.lock().await?;

        let transaction = guard.as_mut().unwrap();

        let rows = bind_arguments(sqlx::query(AssertSqlSafe(statement)), arguments)?
            .fetch_all(&mut **transaction)
            .await?;

        encode_rows(rows)
    }

    pub async fn execute(
        &self, statement: String, arguments: Vec<SqlValue>,
    ) -> Result<SqlExecutionResult> {
        let mut guard = self.lock().await?;

        let transaction = guard.as_mut().unwrap();

        let result = bind_arguments(sqlx::query(AssertSqlSafe(statement)), arguments)?
            .execute(&mut **transaction)
            .await?;

        Ok(SqlExecutionResult {
            affected_rows: result.rows_affected() as i64,
            last_insert_row_id: result.last_insert_rowid(),
        })
    }
}
