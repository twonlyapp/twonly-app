/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! Work the app does when it is not running.
//!
//! Everything a send needs is durable — the receipt outbox, the media state
//! machine, the direct-media job rows — but until now only a Flutter launch
//! resumed any of it. A user who sends and closes the app, or who composes
//! offline and never reopens, is exactly the case that leaves. These entry
//! points are driven by the platform's own schedulers (`WorkManager` on
//! Android, `BGTaskScheduler` on iOS) and need neither Flutter nor a visible
//! app.

use crate::api::messages::incoming::messages;
use crate::api::runtime::ApiRuntime;
use crate::bridge::api::ApiConnectionState;
use crate::context::Context;
use crate::error::Result;
use crate::services::direct_media_upload::DirectMediaUploadService;
use crate::services::media_upload::MediaUploadService;
use crate::services::outbox_dispatch::OutboxDispatchService;
use std::sync::Arc;
use std::time::Duration;

/// How long to wait for the socket to authenticate before giving up on the
/// parts of the flush that need it. A background job has a hard budget of its
/// own, so this stays well inside it.

const AUTHENTICATION_TIMEOUT: Duration = Duration::from_secs(20);

const AUTHENTICATION_POLL: Duration = Duration::from_millis(250);

/// Mailbox delivery and the final receipt flush share one bounded window.
/// On expiry their durable rows remain owned by the native scheduler.

const MESSAGE_DRAIN_TIMEOUT: Duration = Duration::from_secs(20);

/// Foreground work belongs to the Rust operation, so suspension cancels and
/// drains it and the next foreground epoch retries it without a Dart timer.

pub(crate) fn schedule_foreground_maintenance(ctx: &Arc<Context>) {
    let ctx = ctx.clone();

    crate::database::lifecycle::spawn(async move {
        tokio::time::sleep(Duration::from_secs(1)).await;

        if let Err(error) = purge_expired_data(&ctx).await {
            tracing::warn!(%error, "foreground expiry cleanup failed");
        }
    });

    crate::database::lifecycle::spawn(async {
        tokio::time::sleep(Duration::from_secs(120)).await;

        let cleaned = crate::database::lifecycle::spawn_blocking(crate::log::clean_log_file).await;

        if !matches!(cleaned, Ok(Ok(()))) {
            tracing::warn!(?cleaned, "log cleanup failed");
        }
    });
}

/// The first Flutter launch still imports the historical store after Rust
/// initialization. Maintenance must see the imported rows before it runs.

pub(crate) async fn wait_for_legacy_import(ctx: &Context) -> Result<()> {
    let database = ctx.app_db.read().await.clone();

    while !database.is_legacy_import_complete().await? {
        tokio::time::sleep(Duration::from_secs(1)).await;
    }

    Ok(())
}

async fn purge_expired_data(ctx: &Arc<Context>) -> Result<()> {
    wait_for_legacy_import(ctx).await?;

    if let Err(error) = crate::services::stories::purge_expired(ctx).await {
        tracing::warn!(%error, "could not purge expired stories");
    }

    let now = chrono::Utc::now();

    let database = ctx.app_db.read().await.clone();

    let mut transaction = database.pool.begin().await?;

    crate::database::app::messages::writes::purge(&mut transaction, now.timestamp_millis()).await?;

    crate::database::app::receipts::writes::purge(
        &mut transaction,
        (now - chrono::Duration::days(45)).timestamp(),
    )
    .await?;

    transaction.commit().await?;

    MediaUploadService::new(ctx).purge_temp_folder().await
}

/// What a maintenance run should do.

pub enum Job {
    /// Prepare one media file and hand it to the OS uploader. This is the job
    /// scheduled the moment the user hits send.
    PrepareMedia(String),
    /// Resume everything that was left in flight: interrupted preparations,
    /// transfers the OS has since settled, and the message outbox.
    Flush,
}

/// State the native scheduler needs in order to decide whether this job is
/// finished or must be retried later by the OS.

pub struct RunOutcome {
    pub pending_uploads: bool,
    pub pending_messages: bool,
}

/// Runs a maintenance job in a process that may have no Flutter engine.
///
/// Safe to call concurrently with a running app: every step it performs is the
/// same idempotent one the app runs itself, guarded by the same locks.

pub(crate) async fn run(ctx: Arc<Context>, job: Job) -> Result<RunOutcome> {
    if let Err(error) = crate::services::mediafiles::cleanup_pending_file_removals(&ctx).await {
        tracing::warn!(%error, "pending media file cleanup will be retried");
    }

    // Authentication can drain a small mailbox before the worker reaches its
    // final wait. Sampling after connecting would miss that completion.
    let mailbox_generation = ctx.mailbox_generation();

    // A send that has not been prepared yet needs an upload slot, and one for a
    // contact with no Signal session yet needs a prekey bundle. Both want the
    // network, so the connection is opened before the work rather than after.
    //
    // Except when the app is up in this same process: this job owns a Tokio
    // runtime that is dropped the moment it returns, so connecting here would
    // put the socket's reader on a runtime that is about to go away and kill a
    // connection the app is relying on. The app's own post-authentication sweep
    // already does all of this, so the job sticks to the media work.
    let owns_connection = !ctx.is_flutter_runtime();

    let connected = if owns_connection {
        connect_and_authenticate(&ctx).await
    } else {
        matches!(
            ApiRuntime::connection_state(&ctx).await,
            Ok(ApiConnectionState::Authenticated)
        )
    };

    if !connected {
        tracing::info!("background maintenance is running without a server connection");
    } else if owns_connection && ctx.mailbox_generation() == mailbox_generation {
        // Also covers an already-authenticated connection whose previous
        // mailbox drain happened before this run sampled its generation.
        ApiRuntime::client(&ctx).await?.request_catch_up().await;
    }

    match &job {
        Job::PrepareMedia(media_id) => {
            MediaUploadService::new(&ctx).start_upload(media_id).await?;
        }
        Job::Flush => {
            // First, so nothing below spends effort on an expired story.
            if let Err(error) = crate::services::stories::purge_expired(&ctx).await {
                tracing::warn!(%error, "could not purge expired stories");
            }

            if let Err(error) = MediaUploadService::new(&ctx).finish_started_uploads().await {
                tracing::warn!(%error, "could not finish started media uploads");
            }

            if let Err(error) = MediaUploadService::new(&ctx).reupload_pending().await {
                tracing::warn!(%error, "could not retry pending media reuploads");
            }
        }
    }

    // A watcher spawned from this function would be cancelled when the native
    // entry point drops its temporary Tokio runtime. Perform one status pass
    // synchronously instead and tell WorkManager to retry durably while a job
    // is still waiting for the server.
    let direct_uploads = DirectMediaUploadService::new(&ctx);

    if let Err(error) = direct_uploads.reconcile().await {
        tracing::warn!(%error, "could not reconcile direct-media uploads");
    }

    let pending_uploads = direct_uploads
        .pending_job_count()
        .await
        .map(|count| count > 0)
        .unwrap_or_else(|error| {
            tracing::warn!(%error, "could not count pending direct-media uploads");

            // A failed count must not let the OS discard the only durable retry.
            true
        });

    if connected && owns_connection {
        // The Flutter runtime does this from its post-authentication sweep,
        // which deliberately does not run in a background runtime.
        if let Err(error) = ApiRuntime::replay_outbox(&ctx).await {
            tracing::warn!(%error, "could not replay the API outbox");
        }

        if let Err(error) = DirectMediaUploadService::new(&ctx).preload_slots().await {
            tracing::warn!(%error, "could not preload direct-media upload slots");
        }
    } else if owns_connection {
        // Nothing can be sent right now, so leave the envelopes with the OS,
        // which waits for connectivity by itself.
        if let Err(error) = OutboxDispatchService::new(&ctx).hand_pending_to_os().await {
            tracing::warn!(%error, "could not hand queued envelopes to the OS");
        }
    }

    let messages_finished = if connected && owns_connection {
        finish_message_work(&ctx, mailbox_generation, MESSAGE_DRAIN_TIMEOUT).await
    } else {
        !owns_connection
    };

    let pending_messages = owns_connection
        && ctx.is_notification_runtime()
        && (!messages_finished
            || messages::has_pending_receipts(&ctx)
                .await
                .unwrap_or_else(|error| {
                    tracing::warn!(%error, "could not count pending receipts");

                    true
                }));

    // The native entry point owns cancellation, producer shutdown and actual
    // database closure, including errors and expiration before this return.
    Ok(RunOutcome {
        pending_uploads,
        pending_messages,
    })
}

/// MailboxDrained is sent by the server after it has received the page ACKs.
/// Only then can the last outbox pass know every inbound delivery receipt is
/// durable. Waiting for the active flush prevents shutdown under its requests.

async fn finish_message_work(ctx: &Arc<Context>, generation: u64, budget: Duration) -> bool {
    match tokio::time::timeout(budget, async {
        ctx.wait_for_mailbox_after(generation).await;

        messages::retransmit_queued_receipts_and_wait(ctx).await
    })
    .await
    {
        Ok(Ok(())) => true,
        Ok(Err(error)) => {
            tracing::warn!(%error, "could not finish background receipt flush");

            false
        }
        Err(_) => {
            tracing::info!("background message drain window elapsed; retaining work for retry");

            false
        }
    }
}

/// Opens the socket and waits for the handshake, bounded. A background job that
/// cannot reach the server still has offline work worth doing, so a failure
/// here is reported rather than raised.

async fn connect_and_authenticate(ctx: &Arc<Context>) -> bool {
    if matches!(
        ApiRuntime::connection_state(ctx).await,
        Ok(ApiConnectionState::Authenticated)
    ) {
        return true;
    }

    if let Err(error) = ApiRuntime::connect(ctx).await {
        tracing::info!(%error, "background maintenance could not connect");

        return false;
    }

    let deadline = tokio::time::Instant::now() + AUTHENTICATION_TIMEOUT;

    while tokio::time::Instant::now() < deadline {
        match ApiRuntime::connection_state(ctx).await {
            Ok(ApiConnectionState::Authenticated) => return true,
            Ok(ApiConnectionState::PermanentlyRejected) => return false,
            _ => tokio::time::sleep(AUTHENTICATION_POLL).await,
        }
    }

    false
}

#[cfg(test)]

mod tests {

    use super::*;

    #[tokio::test]

    async fn expiry_waits_for_import_and_retries_after_foreground_cancellation() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx = Context::init_for_testing(
            directory.path().join("database"),
            directory.path().join("data"),
        )
        .await?;

        let database = ctx.app_db.read().await.clone();

        // Context now completes import before exposing a runtime. Recreate an
        // incomplete import explicitly to exercise the maintenance guard.
        sqlx::query("DELETE FROM app_metadata WHERE key = 'legacy_import_complete'")
            .execute(&database.pool)
            .await?;

        sqlx::query!(
            r#"
                INSERT INTO groups(group_id, group_name, delete_messages_after_milliseconds)
                VALUES ('expiry', 'Expiry', 1000)
            "#,
        )
        .execute(&database.pool)
        .await?;

        sqlx::query!(
            r#"
                INSERT INTO messages(
                    message_id, group_id, type, created_at, opened_by_all, is_story, media_stored
                )
                VALUES ('expired-message', 'expiry', 'text', 1, 1, 0, 0),
                    ('current-message', 'expiry', 'text', 1, NULL, 0, 0),
                    ('expired-story', 'expiry', 'text', 1, NULL, 1, 0),
                    ('saved-story', 'expiry', 'text', 1, NULL, 1, 1)
            "#,
        )
        .execute(&database.pool)
        .await?;

        let now = chrono::Utc::now().timestamp();

        sqlx::query!(
            r#"
                INSERT INTO received_receipts(receipt_id, created_at)
                VALUES ('expired-receipt', 1), ('current-receipt', ?)
            "#,
            now,
        )
        .execute(&database.pool)
        .await?;

        let operation = crate::database::lifecycle::Operation::foreground();

        let mut pending = operation.scope_sync(|| {
            let ctx = ctx.clone();

            crate::database::lifecycle::spawn(async move { purge_expired_data(&ctx).await })
        });

        assert!(
            tokio::time::timeout(Duration::from_millis(50), &mut pending)
                .await
                .is_err()
        );

        operation.cancel();

        tokio::time::timeout(Duration::from_secs(2), operation.drain())
            .await
            .unwrap();

        assert!(pending.await.unwrap_err().is_cancelled());

        assert_eq!(
            sqlx::query_scalar!("SELECT COUNT(*) FROM messages")
                .fetch_one(&database.pool)
                .await?,
            4,
        );

        database.complete_empty_legacy_import().await?;

        // A new foreground owner retries locally even without authentication.
        let resumed = crate::database::lifecycle::Operation::foreground();

        tokio::time::timeout(
            Duration::from_secs(5),
            resumed.scope(purge_expired_data(&ctx)),
        )
        .await
        .unwrap()?;

        assert_eq!(
            sqlx::query_scalar!("SELECT message_id FROM messages ORDER BY message_id")
                .fetch_all(&database.pool)
                .await?,
            ["current-message", "saved-story"],
        );

        assert_eq!(
            sqlx::query_scalar!("SELECT receipt_id FROM received_receipts ORDER BY receipt_id")
                .fetch_all(&database.pool)
                .await?,
            ["current-receipt"],
        );

        Ok(())
    }

    #[tokio::test]

    async fn shutdown_waits_for_mailbox_and_the_existing_receipt_flush() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx = Context::init_for_testing(
            directory.path().join("database"),
            directory.path().join("data"),
        )
        .await?;

        let generation = ctx.mailbox_generation();

        let database = ctx.app_db.read().await.clone();

        // Hold the single connection so the existing flush cannot finish.
        let transaction = database.pool.begin().await?;

        let active = {
            let ctx = ctx.clone();

            tokio::spawn(async move { messages::retransmit_queued_receipts(&ctx).await })
        };

        tokio::task::yield_now().await;

        let finishing = {
            let ctx = ctx.clone();

            tokio::spawn(async move {
                finish_message_work(&ctx, generation, Duration::from_secs(2)).await
            })
        };

        tokio::task::yield_now().await;

        assert!(
            !finishing.is_finished(),
            "authentication alone is not a drained mailbox"
        );

        ctx.mark_mailbox_drained();

        tokio::task::yield_now().await;

        assert!(
            !finishing.is_finished(),
            "the active flush still owns database work"
        );

        transaction.commit().await?;

        active.await.unwrap()?;

        assert!(finishing.await.unwrap());

        Ok(())
    }

    #[tokio::test]

    async fn shutdown_recognises_a_mailbox_drained_before_the_wait() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx = Context::init_for_testing(
            directory.path().join("database"),
            directory.path().join("data"),
        )
        .await?;

        let generation = ctx.mailbox_generation();

        ctx.mark_mailbox_drained();

        assert!(finish_message_work(&ctx, generation, Duration::from_secs(1)).await);

        Ok(())
    }

    #[tokio::test]

    async fn shutdown_deadline_keeps_unfinished_receipts_durable() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let ctx = Context::init_for_testing(
            directory.path().join("database"),
            directory.path().join("data"),
        )
        .await?;

        let database = ctx.app_db.read().await.clone();

        sqlx::query!("INSERT INTO contacts(user_id, username) VALUES (7, 'peer')")
            .execute(&database.pool)
            .await?;

        sqlx::query!(
            "INSERT INTO receipts(receipt_id, contact_id, message) VALUES ('unsent', 7, x'00')",
        )
        .execute(&database.pool)
        .await?;

        let generation = ctx.mailbox_generation();

        tokio::time::pause();

        assert!(!finish_message_work(&ctx, generation, Duration::from_secs(1)).await);

        tokio::time::resume();

        assert!(messages::has_pending_receipts(&ctx).await?);

        assert_eq!(
            sqlx::query_scalar!("SELECT COUNT(*) FROM receipts WHERE receipt_id = 'unsent'")
                .fetch_one(&database.pool)
                .await?,
            1
        );

        Ok(())
    }
}
