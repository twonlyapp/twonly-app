/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use super::client::{ApiClient, API_PERMANENTLY_REJECTED};
use crate::api::messages::incoming::handle_server_message;
use crate::api::proto::{client_to_server, server_to_client};
use crate::bridge::api::{ApiConnectionState, ApiEvent, ApiEventKind};
use crate::context::Context;
use crate::error::{Result, TwonlyError};
use core::result::Result as StdResult;
use prost::Message;
use std::future::Future;
use std::pin::Pin;
use std::sync::atomic::Ordering;
use std::sync::Arc;
use std::time::Duration;
use stream_tungstenite::error::SendError;
use tokio::sync::oneshot;

fn call_handle_server_message(
    ctx: Arc<Context>,
    kind: server_to_client::v0::Kind,
) -> Pin<Box<dyn Future<Output = StdResult<client_to_server::Response, String>> + Send>> {
    Box::pin(async move {
        handle_server_message(&ctx, kind)
            .await
            .map_err(|error| error.to_string())
    })
}

/// Maps the error codes that make further connection attempts pointless onto
/// the event the UI shows for them. Everything else is a per-request error.
pub(crate) fn permanent_rejection_kind(code: i32) -> Option<ApiEventKind> {
    use crate::api::proto::error::ErrorCode;
    if code == ErrorCode::AppVersionOutdated as i32 {
        Some(ApiEventKind::AppOutdated)
    } else if code == ErrorCode::NewDeviceRegistered as i32 {
        Some(ApiEventKind::NewDeviceRegistered)
    } else {
        None
    }
}

/// Whether a send failure means the socket can never carry another frame.
/// `ChannelClosed` is the signature of a connection the supervisor abandoned
/// mid-handshake: it left the send channel in place but dropped the reader, so
/// every further send fails the same way until the client is replaced. The
/// other variants describe a single message or a connection that is still
/// coming up, and are left to the caller to retry.
fn is_dead_transport(error: &SendError) -> bool {
    matches!(error, SendError::ChannelClosed)
}

impl ApiClient {
    pub(crate) async fn handle_incoming(self: &Arc<Self>, bytes: &[u8]) {
        let Ok(message) = server_to_client::ServerToClient::decode(bytes) else {
            return;
        };

        if let Some(server_to_client::server_to_client::V::V0(v0)) = message.v {
            if let Some(kind) = v0.kind {
                if matches!(kind, server_to_client::v0::Kind::Response(_)) {
                    let mut pending = self.pending.lock().await;
                    if let Some(sender) = pending.remove(&v0.seq) {
                        let _ = sender.send(bytes.to_vec());
                    }
                } else {
                    let client = self.clone();
                    let Some(ctx) = self.context.upgrade() else {
                        tracing::warn!("context was dropped before handling a server message");
                        return;
                    };
                    tokio::spawn(async move {
                        match call_handle_server_message(ctx, kind).await {
                            Ok(response) => {
                                let acknowledgement = client_to_server::ClientToServer {
                                    v: Some(client_to_server::client_to_server::V::V0(
                                        client_to_server::V0 {
                                            seq: v0.seq,
                                            kind: Some(client_to_server::v0::Kind::Response(
                                                response,
                                            )),
                                        },
                                    )),
                                };
                                if let Err(error) =
                                    client.send(acknowledgement.encode_to_vec()).await
                                {
                                    tracing::warn!("failed to acknowledge server message: {error}");
                                }
                            }
                            Err(error) => {
                                tracing::warn!("failed to process server message: {error}");
                            }
                        }
                    });
                }
            }
        }
    }

    pub(crate) async fn send(self: &Arc<Self>, bytes: Vec<u8>) -> Result<()> {
        let ws_client = self.ws_client.lock().await.clone();
        if let Some(client) = ws_client {
            let msg =
                stream_tungstenite::tokio_tungstenite::tungstenite::Message::Binary(bytes.into());
            let start = tokio::time::Instant::now();
            loop {
                match client.send_async(msg.clone()).await {
                    Ok(_) => return Ok(()),
                    Err(SendError::NotConnected) if start.elapsed() < Duration::from_secs(10) => {
                        tokio::time::sleep(Duration::from_millis(50)).await;
                    }
                    Err(e) => {
                        if is_dead_transport(&e) {
                            self.schedule_reconnect(&client, "send failed");
                        }
                        return Err(TwonlyError::Generic(format!("send error: {:?}", e)));
                    }
                }
            }
        } else {
            Err(TwonlyError::Generic("Not connected".into()))
        }
    }

    pub(crate) async fn request(self: &Arc<Self>, bytes: Vec<u8>) -> Result<Vec<u8>> {
        self.request_internal(bytes, Duration::from_secs(30)).await
    }

    pub(crate) async fn request_durable(
        self: &Arc<Self>,
        bytes: Vec<u8>,
        operation_kind: &str,
    ) -> Result<Vec<u8>> {
        let sequence = self.next_sequence().await;
        let context = self.context.upgrade().ok_or(TwonlyError::Initialization)?;
        let database = context.app_db.read().await.clone();

        sqlx::query!(
            "INSERT INTO api_outbox(sequence_id, operation_kind, payload) VALUES(?, ?, ?)",
            sequence as i64,
            operation_kind,
            bytes
        )
        .execute(&database.pool)
        .await?;

        let response = self.request_internal(bytes, Duration::from_secs(60)).await;

        if response.is_ok() {
            sqlx::query!(
                "DELETE FROM api_outbox WHERE sequence_id = ?",
                sequence as i64
            )
            .execute(&database.pool)
            .await?;
        }
        response
    }

    pub(crate) async fn request_internal(
        self: &Arc<Self>,
        bytes: Vec<u8>,
        timeout: Duration,
    ) -> Result<Vec<u8>> {
        let mut request = client_to_server::ClientToServer::decode(bytes.as_slice())
            .map_err(|error| TwonlyError::Generic(format!("invalid request payload: {error}")))?;
        let sequence = self.next_sequence().await;
        if let Some(client_to_server::client_to_server::V::V0(v0)) = &mut request.v {
            v0.seq = sequence;
        }

        let (sender, receiver) = oneshot::channel();
        self.pending.lock().await.insert(sequence, sender);

        let ws_client = self.ws_client.lock().await.clone();
        if let Some(client) = ws_client {
            let msg = stream_tungstenite::tokio_tungstenite::tungstenite::Message::Binary(
                request.encode_to_vec().into(),
            );
            let start = tokio::time::Instant::now();
            let mut sent = false;
            while start.elapsed() < Duration::from_secs(10) {
                match client.send_async(msg.clone()).await {
                    Ok(_) => {
                        sent = true;
                        break;
                    }
                    Err(SendError::NotConnected) => {
                        tokio::time::sleep(Duration::from_millis(50)).await;
                    }
                    Err(e) => {
                        self.pending.lock().await.remove(&sequence);
                        if is_dead_transport(&e) {
                            self.schedule_reconnect(&client, "request send failed");
                        }
                        return Err(TwonlyError::Generic(format!("send error: {:?}", e)));
                    }
                }
            }
            if !sent {
                self.pending.lock().await.remove(&sequence);
                return Err(TwonlyError::Generic(
                    "send error: NotConnected (timeout)".into(),
                ));
            }
        } else {
            self.pending.lock().await.remove(&sequence);
            return Err(TwonlyError::Generic("Not connected".into()));
        }

        match tokio::time::timeout(timeout, receiver).await {
            Ok(Ok(response)) => Ok(response),
            Ok(Err(_)) => Err(TwonlyError::Generic("response channel closed".into())),
            Err(_) => {
                self.pending.lock().await.remove(&sequence);
                Err(TwonlyError::Generic("API request timed out".into()))
            }
        }
    }

    pub(crate) async fn next_sequence(&self) -> u64 {
        let mut guard = self.next_sequence.lock().await;
        let value = *guard;
        *guard += 1;
        value
    }

    pub(crate) async fn handle_success_metadata(&self, bytes: &[u8]) -> Result<()> {
        let response = server_to_client::ServerToClient::decode(bytes)
            .map_err(|error| TwonlyError::Generic(format!("invalid API response: {error}")))?;
        let Some(server_to_client::server_to_client::V::V0(v0)) = response.v else {
            return Ok(());
        };
        let Some(server_to_client::v0::Kind::Response(response)) = v0.kind else {
            return Ok(());
        };
        let Some(server_to_client::response::Response::Ok(ok)) = response.response else {
            return Ok(());
        };
        if let Some(server_to_client::response::ok::Ok::Authenticated(authenticated)) = ok.ok {
            // Note: publish_plan needs to be reachable, we'll keep it in auth or request.
            self.publish_plan(authenticated.plan).await?;
        }
        Ok(())
    }

    /// Rejections the server will keep returning for as long as this
    /// installation stays as it is: the socket is closed for good and the UI is
    /// told why, instead of the client reconnecting into the same error.
    pub(crate) async fn reject_permanently(&self, kind: ApiEventKind) {
        self.set_state(ApiConnectionState::PermanentlyRejected)
            .await;
        API_PERMANENTLY_REJECTED.store(true, Ordering::Release);
        self.deliberately_closed.store(true, Ordering::Release);
        let _ = self.events.send(ApiEvent {
            kind,
            state: Some(ApiConnectionState::PermanentlyRejected),
            message: None,
        });
        if let Some(client) = self.ws_client.lock().await.take() {
            if let Err(error) = client.shutdown_graceful(Duration::from_secs(5)).await {
                tracing::warn!(%error, "permanently rejected WebSocket did not shut down cleanly");
            }
        }
    }

    pub(crate) async fn handle_api_error(&self, code: i32, contact_id: Option<i64>) -> Result<()> {
        use crate::api::proto::error::ErrorCode;
        if let Some(kind) = permanent_rejection_kind(code) {
            self.reject_permanently(kind).await;
        }
        if code == ErrorCode::UserIdNotFound as i32 {
            if let Some(contact_id) = contact_id {
                let context = self.context.upgrade().ok_or(TwonlyError::Initialization)?;
                let database = context.app_db.read().await.clone();
                let mut transaction = database.pool.begin().await?;
                sqlx::query!(
                    "UPDATE contacts SET account_deleted = 1 WHERE user_id = ?",
                    contact_id
                )
                .execute(&mut *transaction)
                .await?;
                sqlx::query!("DELETE FROM receipts WHERE contact_id = ?", contact_id)
                    .execute(&mut *transaction)
                    .await?;
                transaction.commit().await?;
            }
        }
        Ok(())
    }
}
