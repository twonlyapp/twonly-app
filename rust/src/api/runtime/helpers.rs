/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::messages::incoming::{messages, recovery};
use crate::api::proto::server_to_client;
use crate::api::runtime::ApiRuntime;
use crate::api::Server;

use crate::bridge::api::ServerResult;
use crate::context::Context;
use crate::error::{Result, TwonlyError};
use crate::services::direct_media_upload::DirectMediaUploadService;
use crate::services::groups::GroupService;
use crate::services::media_upload::MediaUploadService;
use crate::services::mediafiles::MediaFileService;
use prost::Message as ProstMessage;
use std::future::Future;
use std::pin::Pin;
use std::sync::Arc;
use std::time::Duration;

pub(crate) fn response_error_code(bytes: &[u8]) -> Result<Option<i32>> {
    let response = server_to_client::ServerToClient::decode(bytes)
        .map_err(|error| TwonlyError::Generic(format!("invalid API response: {error}")))?;

    let Some(server_to_client::server_to_client::V::V0(v0)) = response.v else {
        return Err(TwonlyError::Generic(
            "API response has no V0 envelope".into(),
        ));
    };

    let Some(server_to_client::v0::Kind::Response(response)) = v0.kind else {
        return Err(TwonlyError::Generic(
            "API response has no response payload".into(),
        ));
    };

    Ok(match response.response {
        Some(server_to_client::response::Response::Error(code)) => Some(code),
        Some(server_to_client::response::Response::Ok(_)) => None,
        None => return Err(TwonlyError::Generic("empty API response".into())),
    })
}

pub(crate) fn schedule_post_authentication(ctx: &Arc<Context>, in_background: bool) {
    // Notification workers only drain and commit the mailbox. Media downloads,
    // maintenance, and outbox replay belong to the main application runtime.
    if ctx.is_notification_runtime() {
        return;
    }

    let ctx = ctx.clone();

    crate::database::lifecycle::spawn(async move {
        // Wait a bit to let other initial state settle
        tokio::time::sleep(Duration::from_millis(100)).await;

        if ctx.is_flutter_runtime() {
            if let Err(error) = crate::services::background::wait_for_legacy_import(&ctx).await {
                tracing::warn!(%error, "post-authentication maintenance cannot read the imported store");

                return;
            }
        }

        crate::api::messages::incoming::contact::metadata::schedule(&ctx);

        let replay: Pin<Box<dyn Future<Output = Result<()>> + Send>> =
            Box::pin(ApiRuntime::replay_outbox(&ctx));

        if let Err(error) = replay.await {
            tracing::warn!("failed to replay API outbox: {error}");
        }

        if let Err(error) = ApiRuntime::replay_legacy_raw_outbox(&ctx).await {
            tracing::warn!("failed to replay legacy raw-byte outbox: {error}");
        }

        // Runs before the receipt sweep below: without a bundle on the server
        // no peer can open a session with this account, so anything they have
        // queued for us stays stuck.
        if let Err(error) = Server::ensure_pqc_bundle_published(&ctx).await {
            tracing::warn!("failed to verify this account's PQC prekey bundle: {error}");
        }

        if let Err(error) = Server::maintain_prekeys(&ctx).await {
            tracing::warn!(%error, "Signal key maintenance failed");
        }

        if let Err(error) = crate::services::messages::MessageService::new(&ctx)
            .recover_unqueued_text()
            .await
        {
            tracing::warn!(%error, "failed to recover text messages without an outbox entry");
        }

        // Direct-media uploads consume Rust-owned slots, so keep their cache
        // warm whenever an authenticated connection becomes available.
        if let Err(error) = DirectMediaUploadService::new(&ctx).preload_slots().await {
            tracing::warn!("failed to preload direct-media upload slots: {error}");
        }

        if let Err(error) = messages::retransmit_queued_receipts(&ctx).await {
            tracing::warn!("failed to retransmit queued receipts: {error}");
        }

        // A preparation that a terminated process left half-finished is only
        // resumed by a sweep like this one; a mid-session reconnect is just as
        // good a moment for it as a cold start, and far more frequent.
        if let Err(error) = MediaUploadService::new(&ctx).finish_started_uploads().await {
            tracing::warn!("failed to finish started media uploads: {error}");
        }

        if let Err(error) = MediaFileService::new(&ctx).download_pending().await {
            tracing::warn!("failed to download pending media: {error}");
        }

        if in_background {
            return;
        }

        let uploads = ctx.clone();

        crate::database::lifecycle::spawn(async move {
            if let Err(error) = MediaUploadService::new(&uploads).reupload_pending().await {
                tracing::warn!(%error, "failed to retry pending media reuploads");
            }
        });

        let contacts = ctx.clone();

        crate::database::lifecycle::spawn(async move {
            if let Err(error) = Server::refresh_contact_joined_dates(&contacts).await {
                tracing::warn!(%error, "contact account-date refresh failed");
            }
        });

        if let Err(error) = GroupService::new(&ctx).on_connected().await {
            tracing::warn!("group post-connection maintenance failed: {error}");
        }

        if let Err(error) = Server::check_for_deleted_usernames(&ctx).await {
            tracing::warn!("deleted-username refresh failed: {error}");
        }

        if let Err(error) = recovery::perform_heartbeat(&ctx).await {
            tracing::warn!("passwordless recovery heartbeat failed: {error}");
        }

        if let Err(error) = ctx.user_discovery.get().await.on_connected(&ctx).await {
            tracing::warn!("user-discovery post-connection refresh failed: {error}");
        }
    });
}

pub(crate) fn decode_ok(
    bytes: Vec<u8>,
) -> Result<ServerResult<server_to_client::response::ok::Ok>> {
    let response = server_to_client::ServerToClient::decode(bytes.as_slice())
        .map_err(|error| TwonlyError::Generic(format!("invalid API response: {error}")))?;

    let Some(server_to_client::server_to_client::V::V0(v0)) = response.v else {
        return Err(TwonlyError::Generic(
            "API response has no V0 envelope".into(),
        ));
    };

    let Some(server_to_client::v0::Kind::Response(response)) = v0.kind else {
        return Err(TwonlyError::Generic(
            "API response has no response payload".into(),
        ));
    };

    match response.response {
        Some(server_to_client::response::Response::Ok(ok)) => {
            let ok_val = ok.ok.ok_or_else(|| {
                TwonlyError::Generic("successful API response has no value".into())
            })?;

            Ok(ServerResult::Ok(ok_val))
        }
        Some(server_to_client::response::Response::Error(code)) => {
            Ok(ServerResult::ErrorCode(code))
        }
        None => Err(TwonlyError::Generic("empty API response".into())),
    }
}

pub(crate) fn decode_ok_value<T>(
    bytes: Vec<u8>, extract: impl FnOnce(server_to_client::response::ok::Ok) -> Option<T>,
) -> Result<ServerResult<T>> {
    match decode_ok(bytes)? {
        ServerResult::Ok(ok) => {
            let extracted = extract(ok).ok_or_else(|| {
                TwonlyError::Generic("successful API response has an unexpected value".into())
            })?;

            Ok(ServerResult::Ok(extracted))
        }
        ServerResult::ErrorCode(code) => Ok(ServerResult::ErrorCode(code)),
    }
}

pub(crate) fn decode_empty_ok(bytes: Vec<u8>) -> Result<ServerResult<()>> {
    decode_ok_value(bytes, |value| match value {
        server_to_client::response::ok::Ok::None(_) => Some(()),
        _ => None,
    })
}
