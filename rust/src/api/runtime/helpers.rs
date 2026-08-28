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
use crate::services::groups::GroupService;
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
    let ctx = ctx.clone();
    tokio::spawn(async move {
        // Wait a bit to let other initial state settle
        tokio::time::sleep(Duration::from_millis(100)).await;

        let replay: Pin<Box<dyn Future<Output = Result<()>> + Send>> =
            Box::pin(ApiRuntime::replay_outbox(&ctx));
        if let Err(error) = replay.await {
            tracing::warn!("failed to replay API outbox: {error}");
        }

        if let Err(error) = ApiRuntime::replay_legacy_raw_outbox(&ctx).await {
            tracing::warn!("failed to replay legacy raw-byte outbox: {error}");
        }

        if let Err(error) = messages::retransmit_queued_receipts(&ctx).await {
            tracing::warn!("failed to retransmit queued receipts: {error}");
        }
        if let Err(error) = MediaFileService::new(&ctx).download_pending().await {
            tracing::warn!("failed to download pending media: {error}");
        }

        if in_background {
            return;
        }

        if let Err(error) = GroupService::new(&ctx).on_connected().await {
            tracing::warn!("group post-connection maintenance failed: {error}");
        }

        if let Err(error) = Server::check_for_deleted_usernames(&ctx).await {
            tracing::warn!("deleted-username refresh failed: {error}");
        }

        if let Err(error) = recovery::perform_heartbeat(&ctx).await {
            tracing::warn!("passwordless recovery heartbeat failed: {error}");
        }

        if let Err(error) = ctx
            .user_discovery
            .get()
            .await
            .on_connected(&ctx)
            .await
        {
            tracing::warn!("user-discovery post-connection refresh failed: {error}");
        }

        let signal_engine = ctx.signal_engine.lock().await;
        if let Some(engine) = signal_engine.as_ref() {
            if let Err(error) = engine.on_connected(&ctx).await {
                tracing::warn!("Signal key maintenance failed: {error}");
            }
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
    bytes: Vec<u8>,
    extract: impl FnOnce(server_to_client::response::ok::Ok) -> Option<T>,
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
