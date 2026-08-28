/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::bridge::api::{ApiConfig, ApiConnectionState, ApiEvent, ApiEventKind};
use crate::context::Context;
use crate::error::{Result, TwonlyError};
use crate::frb_generated::StreamSink;
use std::sync::Arc;
use tokio::sync::broadcast;

pub(crate) mod auth;
pub(crate) mod client;
pub(crate) mod helpers;
pub(crate) mod request;

pub(crate) use client::{ApiClient, API_EVENTS};
use helpers::*;

#[doc(hidden)]
pub struct ApiRuntime {}

impl ApiRuntime {
    pub(crate) async fn initialize(ctx: &Arc<Context>) -> Result<()> {
        let config = ApiConfig::from_rust_state(ctx).await?;
        ctx.api_client
            .set(tokio::sync::RwLock::new(ApiClient::new(ctx, config)))
            .map_err(|_| TwonlyError::Initialization)
    }

    pub async fn reload_configuration(ctx: &Arc<Context>) -> Result<()> {
        let replacement = ApiClient::new(ctx, ApiConfig::from_rust_state(ctx).await?);
        let current = Self::client(ctx).await?;
        let slot = ctx
            .api_client
            .get()
            .ok_or(TwonlyError::Initialization)?;
        *slot.write().await = replacement;
        current.close().await;
        Self::client(ctx).await?.connect().await
    }

    pub async fn connect(ctx: &Arc<Context>) -> Result<()> {
        Self::client(ctx).await?.connect().await
    }

    pub async fn close(ctx: &Arc<Context>) -> Result<()> {
        Self::client(ctx).await?.close().await;
        Ok(())
    }

    pub async fn connection_state(ctx: &Arc<Context>) -> Result<ApiConnectionState> {
        Ok(*Self::client(ctx).await?.state.read().await)
    }

    pub async fn set_background(ctx: &Arc<Context>, in_background: bool) -> Result<()> {
        Self::client(ctx).await?.set_background(in_background).await
    }

    pub async fn set_network_available(ctx: &Arc<Context>, available: bool) -> Result<()> {
        Self::client(ctx)
            .await?
            .set_network_available(available)
            .await
    }

    pub async fn send_binary(ctx: &Arc<Context>, bytes: Vec<u8>) -> Result<()> {
        Self::client(ctx).await?.send(bytes).await
    }

    pub async fn request_binary(ctx: &Arc<Context>, bytes: Vec<u8>) -> Result<Vec<u8>> {
        let client = Self::client(ctx).await?;
        if client.ws_client.lock().await.is_none() {
            client.connect().await?;
        }
        client.request(bytes).await
    }

    pub async fn request_authenticated(
        ctx: &Arc<Context>,
        bytes: Vec<u8>,
        contact_id: Option<i64>,
    ) -> Result<Vec<u8>> {
        let client = Self::client(ctx).await?;
        if client.ws_client.lock().await.is_none() {
            client.connect().await?;
        }
        let response = client.request(bytes.clone()).await?;
        match response_error_code(&response)? {
            None => {
                client.handle_success_metadata(&response).await?;
                Ok(response)
            }
            Some(code)
                if code == crate::api::proto::error::ErrorCode::SessionNotAuthenticated as i32 =>
            {
                client.set_state(ApiConnectionState::Connected).await;

                let retried = client.request(bytes).await?;
                if let Some(code) = response_error_code(&retried)? {
                    client.handle_api_error(code, contact_id).await?;
                    return Ok(retried);
                }
                client.handle_success_metadata(&retried).await?;
                Ok(retried)
            }
            Some(code) => {
                client.handle_api_error(code, contact_id).await?;
                Ok(response)
            }
        }
    }

    pub async fn request_durable_authenticated(
        ctx: &Arc<Context>,
        bytes: Vec<u8>,
        operation_kind: &str,
    ) -> Result<Vec<u8>> {
        let client = Self::client(ctx).await?;
        if client.ws_client.lock().await.is_none() {
            client.connect().await?;
        }
        let response = client.request_durable(bytes, operation_kind).await?;
        if let Some(code) = response_error_code(&response)? {
            client.handle_api_error(code, None).await?;
        }
        Ok(response)
    }

    pub(crate) async fn replay_outbox(ctx: &Arc<Context>) -> Result<()> {
        let database = ctx.app_db.read().await.clone();
        let rows = sqlx::query!("SELECT sequence_id, payload FROM api_outbox ORDER BY created_at")
            .fetch_all(&database.pool)
            .await?;
        for row in rows {
            match Self::request_authenticated(ctx, row.payload, None).await {
                Ok(_) => {
                    sqlx::query!(
                        "DELETE FROM api_outbox WHERE sequence_id = ?",
                        row.sequence_id
                    )
                    .execute(&database.pool)
                    .await?;
                }
                Err(error) => {
                    tracing::warn!(sequence = row.sequence_id, "outbox replay failed: {error}")
                }
            }
        }
        database.notify_committed(["api_outbox"]);
        Ok(())
    }

    pub(crate) async fn replay_legacy_raw_outbox(ctx: &Arc<Context>) -> Result<()> {
        use base64::Engine as _;
        let path = std::path::Path::new(&ctx.config.data_dir)
            .join("keyvalue")
            .join("rawbytes-to-retransmit.json");
        if !path.exists() {
            return Ok(());
        }
        let value: serde_json::Value = serde_json::from_slice(&std::fs::read(&path)?)
            .map_err(|error| TwonlyError::Generic(format!("invalid legacy outbox: {error}")))?;
        let Some(messages) = value.as_object() else {
            return Err(TwonlyError::Generic(
                "legacy outbox is not an object".into(),
            ));
        };
        for encoded in messages.values() {
            let encoded = encoded.as_str().ok_or_else(|| {
                TwonlyError::Generic("legacy outbox payload is not a string".into())
            })?;
            let bytes = base64::engine::general_purpose::STANDARD
                .decode(encoded)
                .map_err(|error| {
                    TwonlyError::Generic(format!("invalid legacy outbox payload: {error}"))
                })?;
            Self::request_authenticated(ctx, bytes, None).await?;
        }
        std::fs::remove_file(path)?;
        Ok(())
    }

    pub async fn allocate_sequence(ctx: &Arc<Context>) -> Result<u64> {
        Ok(Self::client(ctx).await?.next_sequence().await)
    }

    pub async fn events(ctx: &Arc<Context>, sink: StreamSink<ApiEvent>) -> Result<()> {
        let mut receiver = API_EVENTS.subscribe();

        // The Dart stream is created synchronously, but this async FFI call may
        // not have installed its broadcast receiver before Dart starts the API
        // connection. Send a snapshot after subscribing so Dart can use it as
        // a readiness handshake and no connection events are lost at startup.
        let state = Self::connection_state(ctx).await?;
        if sink
            .add(ApiEvent {
                kind: ApiEventKind::ConnectionStateChanged,
                state: Some(state),
                message: None,
            })
            .is_err()
        {
            return Ok(());
        }

        tokio::spawn(async move {
            loop {
                match receiver.recv().await {
                    Ok(event) => {
                        if sink.add(event).is_err() {
                            break;
                        }
                    }
                    Err(broadcast::error::RecvError::Lagged(skipped)) => {
                        let _ = sink.add(ApiEvent {
                            kind: ApiEventKind::TransportError,
                            state: None,
                            message: Some(format!("API event consumer lagged by {skipped} events")),
                        });
                    }
                    Err(broadcast::error::RecvError::Closed) => break,
                }
            }
        });
        Ok(())
    }

    pub(crate) async fn client(ctx: &Arc<Context>) -> Result<Arc<ApiClient>> {
        let client = ctx
            .api_client
            .get()
            .ok_or(TwonlyError::Initialization)?;
        Ok(client.read().await.clone())
    }
}
