//! Consistent snapshots preserve the source's SQLCipher key and SQLite header
//! metadata. Developer exports explicitly produce plaintext instead. Never copy
//! a live main file or return an export connection early.

use super::lifecycle::Operation;
use crate::error::{Result, TwonlyError};
use sqlx::{Connection, SqliteConnection, SqlitePool};
use std::path::Path;
use std::time::Duration;

pub(crate) async fn watch(
    connection: &mut sqlx::SqliteConnection, operation: &Operation,
) -> Result<()> {
    let mut handle = connection.lock_handle().await?;

    let cancel = operation.clone();

    handle.set_progress_handler(1000, move || !cancel.cancelled());

    Ok(())
}

pub(crate) async fn create(pool: &SqlitePool, path: &Path, operation: &Operation) -> Result<()> {
    create_export(pool, path, operation, false).await
}

/// An inspection copy that opens in ordinary SQLite without the source key.
pub(crate) async fn create_plaintext(
    pool: &SqlitePool, path: &Path, operation: &Operation,
) -> Result<()> {
    create_export(pool, path, operation, true).await
}

async fn create_export(
    pool: &SqlitePool, path: &Path, operation: &Operation, plaintext: bool,
) -> Result<()> {
    operation.check()?;

    if path.try_exists()? {
        return Err(TwonlyError::Generic(
            "Snapshot target already exists".into(),
        ));
    }

    let pooled = tokio::select! {
        biased;
        _ = operation.until_cancelled() => return operation.check(),
        result = pool.acquire() => result?,
    };

    // Keep the checkout tracked by the pool until native closure completes.
    // In particular, pool.close() during restore must wait for this snapshot.
    let mut connection = pooled;

    let setup = watch(&mut connection, operation).await;

    let result = async {
        setup?;

        // Progress callbacks do not run while SQLite sleeps on a busy lock.
        // Bound each wait and retry only a fresh, disposable snapshot.
        sqlx::query!("PRAGMA busy_timeout = 50")
            .fetch_optional(&mut *connection)
            .await?;

        let destination = path.to_string_lossy();

        loop {
            operation.check()?;

            let result = if plaintext {
                export_plaintext(&mut connection, destination.as_ref()).await
            } else {
                sqlx::query!("VACUUM INTO ?", destination.as_ref())
                    .execute(&mut *connection)
                    .await
                    .map(|_| ())
            };

            match result {
                Err(sqlx::Error::Database(ref error))
                    if error
                        .code()
                        .and_then(|code| code.parse::<i32>().ok())
                        .is_some_and(|code| matches!(code & 255, 5 | 6)) =>
                {
                    if path.try_exists()? {
                        std::fs::remove_file(path)?;
                    }

                    tokio::select! {
                        _ = operation.until_cancelled() => operation.check()?,
                        _ = tokio::time::sleep(Duration::from_millis(25)) => {}
                    }
                }
                result => {
                    result?;

                    return Ok::<_, TwonlyError>(());
                }
            }
        }
    }
    .await;

    // Closing joins SQLx's connection worker. Never drop/abort the executing
    // future on cancellation and assume SQLite has stopped.
    let closed = connection.close().await;

    let cancellation = operation.check();

    if result.is_err() || closed.is_err() || cancellation.is_err() {
        let _ = std::fs::remove_file(path);
    }

    result?;

    closed?;

    cancellation
}

async fn export_plaintext(
    connection: &mut SqliteConnection, destination: &str,
) -> sqlx::Result<()> {
    // An explicit empty key prevents the attached database from inheriting
    // the source's SQLCipher encryption. The source is never rekeyed.
    sqlx::query("ATTACH DATABASE ? AS debug_export KEY ''")
        .bind(destination)
        .execute(&mut *connection)
        .await?;

    let result = async {
        // Pin the source snapshot across the schema, rows and header reads,
        // including commits that are still in its WAL.
        let mut transaction = connection.begin().await?;

        let user_version: i64 = sqlx::query_scalar("PRAGMA main.user_version")
            .fetch_one(&mut *transaction)
            .await?;
        let application_id: i64 = sqlx::query_scalar("PRAGMA main.application_id")
            .fetch_one(&mut *transaction)
            .await?;

        sqlx::query("SELECT sqlcipher_export('debug_export')")
            .execute(&mut *transaction)
            .await?;

        // sqlcipher_export copies schema and rows, but not these header fields.
        for (pragma, value) in [
            ("user_version", user_version),
            ("application_id", application_id),
        ] {
            sqlx::query(sqlx::AssertSqlSafe(format!(
                "PRAGMA debug_export.{pragma} = {value}"
            )))
            .execute(&mut *transaction)
            .await?;
        }

        transaction.commit().await
    }
    .await;

    // Detach before a busy retry removes the incomplete file and tries again.
    let detached = sqlx::query("DETACH DATABASE debug_export")
        .execute(&mut *connection)
        .await;

    result?;
    detached?;
    Ok(())
}

#[cfg(test)]
mod tests;
