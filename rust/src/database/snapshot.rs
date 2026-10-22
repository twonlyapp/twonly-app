//! Consistent snapshots preserve the source's SQLCipher key and SQLite header
//! metadata. Never copy a live main file or return an export connection early.

use super::lifecycle::Operation;
use crate::error::{Result, TwonlyError};
use sqlx::SqlitePool;
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

            let result = sqlx::query!("VACUUM INTO ?", destination.as_ref())
                .execute(&mut *connection)
                .await;

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

#[cfg(test)]
mod tests;
