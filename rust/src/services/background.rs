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
use crate::bridge::InitConfig;
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
}

/// Runs a maintenance job in a process that may have no Flutter engine.
///
/// Safe to call concurrently with a running app: every step it performs is the
/// same idempotent one the app runs itself, guarded by the same locks.
pub async fn run(config: InitConfig, job: Job) -> Result<RunOutcome> {
    Context::init_notification(config).await?;
    let ctx = Context::get_static()?.clone();

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
    }

    match &job {
        Job::PrepareMedia(media_id) => {
            MediaUploadService::new(&ctx).start_upload(media_id).await?;
        }
        Job::Flush => {
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
        if let Err(error) = messages::retransmit_queued_receipts(&ctx).await {
            tracing::warn!(%error, "could not retransmit queued receipts");
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

    // Flutter may have claimed a process that WorkManager started while this
    // run was in flight. Never close the replacement foreground client.
    if owns_connection && ctx.is_notification_runtime() {
        ApiRuntime::close(&ctx).await?;
    }
    Ok(RunOutcome { pending_uploads })
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
