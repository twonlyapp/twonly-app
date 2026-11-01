//! Inbound usernames are refresh hints, never authoritative profile data.
//! The durable queue coalesces hints by contact and reserves both budgets
//! before network I/O, including attempts that fail or are cancelled.

use crate::api::Server;
use crate::bridge::api::ServerResult;
use crate::context::Context;
use crate::database::app::groups::history::{GroupHistoryType, InsertGroupHistories};
use crate::error::{Result, TwonlyError};
use sqlx::SqlitePool;
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::{Mutex, Notify};

const CONTACT_COOLDOWN_SECONDS: i64 = 5 * 60;
const ACCOUNT_INTERVAL_SECONDS: i64 = 1;

#[derive(Default)]
pub(crate) struct Refresher {
    worker: Arc<Mutex<()>>,
    wake: Notify,
}

pub(super) async fn queue(ctx: &Arc<Context>, contact_id: i64) -> Result<()> {
    let database = ctx.app_db.read().await.clone();

    // Only existing, unblocked contacts can own a row. Neither the claim nor
    // the peer's profile counter is retained or used to reset a deadline.
    let queued = sqlx::query(
        "INSERT INTO contact_metadata_refreshes(contact_id)
         SELECT user_id FROM contacts WHERE user_id = ? AND blocked = 0
         ON CONFLICT(contact_id) DO UPDATE SET
             pending = 1, generation = contact_metadata_refreshes.generation + 1",
    )
    .bind(contact_id)
    .execute(&database.pool)
    .await?
    .rows_affected();

    if queued > 0 {
        schedule(ctx);
    }

    Ok(())
}

pub(crate) fn schedule(ctx: &Arc<Context>) {
    // Native notification work only drains the mailbox. Its durable hints
    // are picked up when the main runtime next authenticates.
    if ctx.is_notification_runtime() {
        return;
    }

    ctx.contact_metadata_refresh.wake.notify_one();

    // Reserve before spawning: a mailbox page cannot create one task per
    // hint, even while its existing worker is asleep or awaiting the server.
    let Ok(guard) = ctx.contact_metadata_refresh.worker.clone().try_lock_owned() else {
        return;
    };

    let ctx = ctx.clone();

    crate::database::lifecycle::spawn(async move {
        let _guard = guard;

        if let Err(error) = run(&ctx).await {
            tracing::warn!(%error, "contact metadata refresh stopped; queued work is retained");
        }
    });
}

async fn next_attempt(pool: &SqlitePool) -> Result<Option<i64>> {
    Ok(sqlx::query_scalar(
        "SELECT MIN(MAX(r.next_attempt_at, b.next_attempt_at))
         FROM contact_metadata_refreshes r
         JOIN contacts c ON c.user_id = r.contact_id
         CROSS JOIN contact_metadata_refresh_budget b
         WHERE r.pending = 1 AND c.blocked = 0",
    )
    .fetch_one(pool)
    .await?)
}

/// The transaction serializes reservations across workers and processes.
/// Pending stays set until success, so a process dying after this commit
/// leaves a retry that still observes the already-spent cooldown.
async fn claim(pool: &SqlitePool, now: i64) -> Result<Option<(i64, i64)>> {
    let mut transaction = pool.begin().await?;

    let candidate = sqlx::query_as::<_, (i64, i64)>(
        "SELECT r.contact_id, r.generation FROM contact_metadata_refreshes r
         JOIN contacts c ON c.user_id = r.contact_id
         WHERE r.pending = 1 AND r.next_attempt_at <= ? AND c.blocked = 0
         ORDER BY r.next_attempt_at, r.contact_id LIMIT 1",
    )
    .bind(now)
    .fetch_optional(&mut *transaction)
    .await?;

    let Some((contact_id, generation)) = candidate else {
        return Ok(None);
    };

    let reserved = sqlx::query(
        "UPDATE contact_metadata_refresh_budget SET next_attempt_at = ?
         WHERE singleton = 1 AND next_attempt_at <= ?",
    )
    .bind(now + ACCOUNT_INTERVAL_SECONDS)
    .bind(now)
    .execute(&mut *transaction)
    .await?
    .rows_affected();

    if reserved == 0 {
        return Ok(None);
    }

    sqlx::query("UPDATE contact_metadata_refreshes SET next_attempt_at = ? WHERE contact_id = ?")
        .bind(now + CONTACT_COOLDOWN_SECONDS)
        .bind(contact_id)
        .execute(&mut *transaction)
        .await?;

    transaction.commit().await?;

    Ok(Some((contact_id, generation)))
}

async fn run(ctx: &Arc<Context>) -> Result<()> {
    loop {
        // Register before reading the queue so a hint cannot be lost between
        // an empty query and going to sleep.
        let notified = ctx.contact_metadata_refresh.wake.notified();

        tokio::pin!(notified);

        notified.as_mut().enable();

        let database = ctx.app_db.read().await.clone();

        let due = next_attempt(&database.pool).await?;

        let now = crate::utils::current_time().timestamp();

        match due {
            None => notified.await,
            Some(due) if due > now => {
                tokio::select! {
                    _ = notified => {},
                    _ = tokio::time::sleep(Duration::from_secs((due - now) as u64)) => {},
                }
            }
            Some(_) => {
                if let Some((contact_id, generation)) = claim(&database.pool, now).await? {
                    if let Err(error) = refresh(ctx, contact_id, generation).await {
                        // The pending row and its reserved deadline already
                        // provide a bounded retry, independently of the message.
                        tracing::warn!(contact_id, %error, "contact metadata refresh failed");
                    }
                }
            }
        }
    }
}

async fn refresh(ctx: &Arc<Context>, contact_id: i64, generation: i64) -> Result<()> {
    // No database transaction or connection is held across this request.
    let user = match Server::get_user_metadata(ctx, contact_id).await? {
        ServerResult::Ok(user) => user,
        ServerResult::ErrorCode(code) => return Err(TwonlyError::Api(code)),
    };

    if user.user_id != contact_id {
        return Err(TwonlyError::Generic(
            "metadata response names another contact".into(),
        ));
    }

    let username = String::from_utf8(
        user.username
            .ok_or_else(|| TwonlyError::Generic("metadata response has no username".into()))?,
    )?;

    let database = ctx.app_db.read().await.clone();

    let mut transaction = database.pool.begin().await?;

    let previous = sqlx::query_scalar::<_, String>(
        "SELECT username FROM contacts WHERE user_id = ? AND blocked = 0",
    )
    .bind(contact_id)
    .fetch_optional(&mut *transaction)
    .await?;

    if let Some(previous) = previous {
        if previous != username {
            InsertGroupHistories::new(
                contact_id,
                &previous,
                &username,
                GroupHistoryType::UpdatedContactUsername,
            )
            .insert(&mut transaction)
            .await?;
        }

        sqlx::query(
            "UPDATE contacts SET username = ?, joined_at = COALESCE(?, joined_at) WHERE user_id = \
             ?",
        )
        .bind(username)
        .bind(user.joined_at)
        .bind(contact_id)
        .execute(&mut *transaction)
        .await?;
    }

    // A hint received during the request must still get its own later
    // refresh: the server may have renamed the contact after this response.
    sqlx::query(
        "UPDATE contact_metadata_refreshes SET pending = 0 WHERE contact_id = ? AND generation = ?",
    )
    .bind(contact_id)
    .bind(generation)
    .execute(&mut *transaction)
    .await?;

    transaction.commit().await?;

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use sqlx::sqlite::{SqliteConnectOptions, SqlitePoolOptions};
    use std::path::Path;

    async fn open(path: &Path) -> Result<SqlitePool> {
        Ok(SqlitePoolOptions::new()
            .max_connections(1)
            .connect_with(
                SqliteConnectOptions::new()
                    .filename(path)
                    .create_if_missing(true)
                    .foreign_keys(true),
            )
            .await?)
    }

    async fn initialize(pool: &SqlitePool) -> Result<()> {
        sqlx::raw_sql(
            "CREATE TABLE contacts(user_id INTEGER PRIMARY KEY, blocked INTEGER NOT NULL DEFAULT \
             0);
             INSERT INTO contacts(user_id) VALUES (8), (9);",
        )
        .execute(pool)
        .await?;
        sqlx::raw_sql(include_str!(
            "../../../../database/app/migrations/0060_contact_metadata_refreshes.sql"
        ))
        .execute(pool)
        .await?;
        sqlx::query("INSERT INTO contact_metadata_refreshes(contact_id) VALUES (8), (9)")
            .execute(pool)
            .await?;
        Ok(())
    }

    #[tokio::test]
    async fn reservations_bound_senders_and_the_account_and_survive_reopening() -> anyhow::Result<()>
    {
        let directory = tempfile::tempdir()?;
        let path = directory.path().join("metadata.sqlite");
        let pool = open(&path).await?;
        initialize(&pool).await?;

        let (first, concurrent) = tokio::join!(claim(&pool, 1000), claim(&pool, 1000));
        assert_eq!(
            first?.into_iter().chain(concurrent?).collect::<Vec<_>>(),
            [(8, 1)]
        );
        assert_eq!(claim(&pool, 1001).await?, Some((9, 1)));
        assert_eq!(next_attempt(&pool).await?, Some(1300));
        pool.close().await;

        let reopened = open(&path).await?;
        assert_eq!(
            claim(&reopened, 1002).await?,
            None,
            "reopening must not reset a spent budget"
        );
        assert_eq!(
            claim(&reopened, 1300).await?,
            Some((8, 1)),
            "an unfinished attempt must remain retryable"
        );
        assert_eq!(
            claim(&reopened, 1300).await?,
            None,
            "another peer still shares the account limit"
        );
        assert_eq!(claim(&reopened, 1301).await?, Some((9, 1)));
        Ok(())
    }

    #[tokio::test]
    async fn budgets_are_account_local_and_blocked_contacts_are_not_refreshed() -> anyhow::Result<()>
    {
        let directory = tempfile::tempdir()?;
        let a = open(&directory.path().join("a.sqlite")).await?;
        let b = open(&directory.path().join("b.sqlite")).await?;
        initialize(&a).await?;
        initialize(&b).await?;
        assert_eq!(claim(&a, 1000).await?, Some((8, 1)));
        assert_eq!(claim(&b, 1000).await?, Some((8, 1)));

        sqlx::query("UPDATE contacts SET blocked = 1")
            .execute(&a)
            .await?;
        assert_eq!(claim(&a, 2000).await?, None);
        assert_eq!(next_attempt(&a).await?, None);
        sqlx::query("DELETE FROM contacts WHERE user_id = 8")
            .execute(&a)
            .await?;
        let rows: i64 = sqlx::query_scalar(
            "SELECT COUNT(*) FROM contact_metadata_refreshes WHERE contact_id = 8",
        )
        .fetch_one(&a)
        .await?;
        assert_eq!(
            rows, 0,
            "deleting a contact must also remove its refresh state"
        );
        Ok(())
    }
}
