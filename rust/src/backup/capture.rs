//! Freeze both SQLite writers before copying any snapshot. Settings are
//! captured while both stores are frozen; compression happens after release.

use crate::context::Context;
use crate::database::lifecycle::pool::PoolOperations;
use crate::database::lifecycle::Operation;
use crate::error::Result;
use sqlx::sqlite::SqlitePoolOptions;
use sqlx::SqlitePool;
use std::path::{Path, PathBuf};

async fn writer_pool(source: &SqlitePool, operation: &Operation) -> Result<SqlitePool> {
    // Preserve the source's actual journal mode, including WAL-only commits.
    // A retained bridge transaction can occupy the sole application writer.
    // Never hold the lifecycle mutex waiting for it after cancellation: the
    // foreground supervisor needs that mutex before it can roll back the owner.
    let mut connection = tokio::select! {
        biased;
        _ = operation.until_cancelled() => return operation.check().map(|_| unreachable!()),
        connection = source.acquire() => connection?,
    };

    let mode = sqlx::query_scalar!(
        "SELECT CAST((SELECT * FROM pragma_journal_mode) AS TEXT) AS \"mode!: String\""
    )
    .fetch_one(&mut *connection)
    .await?;

    drop(connection);

    operation.check()?;

    let options = source
        .connect_options()
        .as_ref()
        .clone()
        .pragma("journal_mode", mode)
        .busy_timeout(std::time::Duration::from_millis(50));

    let operations = std::sync::Arc::new(PoolOperations::new());

    Ok(SqlitePoolOptions::new()
        // One connection holds the writer reservation, the other copies the
        // store under it.
        .max_connections(2)
        .after_connect(move |connection, _| {
            let operations = operations.clone();

            Box::pin(async move { operations.connect(connection).await })
        })
        .connect_with(options)
        .await?)
}

pub(crate) async fn capture(ctx: &Context, directory: &Path, operation: &Operation) -> Result<()> {
    let app = writer_pool(&ctx.app_db.read().await.pool, operation).await?;

    let signal = match writer_pool(&ctx.rust_db.read().await.pool, operation).await {
        Ok(signal) => signal,
        Err(error) => {
            app.close().await;

            return Err(error);
        }
    };

    let result = capture_on(ctx, directory, operation, &app, &signal, || async {
        Ok(())
    })
    .await;

    tokio::join!(app.close(), signal.close());

    result
}

async fn capture_on<F>(
    ctx: &Context, directory: &Path, operation: &Operation, app: &SqlitePool, signal: &SqlitePool,
    frozen: impl FnOnce() -> F,
) -> Result<()>
where
    F: std::future::Future<Output = Result<()>>,
{
    // Checked no-op writes promote the deferred transactions to writer
    // reservations without altering rows or publishing invalidations. The
    // pools' second connections perform VACUUM INTO while these reservations
    // hold the cut.
    let mut app_writer = app.begin().await?;

    sqlx::query!("UPDATE app_metadata SET value = value WHERE 0")
        .execute(&mut *app_writer)
        .await?;

    let mut signal_writer = signal.begin().await?;

    sqlx::query!("UPDATE signal_sessions SET record_bytes = record_bytes WHERE 0")
        .execute(&mut *signal_writer)
        .await?;

    operation.check()?;

    frozen().await?;

    {
        let _settings =
            crate::database::maintenance::freeze_settings(Path::new(&ctx.config.database_dir))?;

        for (source, name) in [
            (
                PathBuf::from(&ctx.config.data_dir).join("keyvalue/user.json"),
                "user.json",
            ),
            (
                PathBuf::from(&ctx.config.data_dir).join("user_discovery_config.json"),
                "user_discovery_config.json",
            ),
        ] {
            if source.try_exists()? {
                std::fs::copy(source, directory.join(name))?;
            }
        }
    }

    // Copy through the capture pools, never the live ones. A live connection
    // can belong to a transaction whose next write waits for the reservation
    // above, so waiting for that connection here waited for ourselves until
    // SQLite's busy timeout or the pool's acquire timeout gave up.
    crate::database::snapshot::create(app, &directory.join("app_db.sqlite"), operation).await?;

    crate::database::snapshot::create(signal, &directory.join("signal-working.sqlite"), operation)
        .await?;

    signal_writer.rollback().await?;

    app_writer.rollback().await?;

    Ok(())
}

#[cfg(test)]
mod tests;
