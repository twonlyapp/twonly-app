/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::bridge::api::{ApiConfig, ApiConnectionState, ApiEvent, ApiEventKind};
use crate::context::Context;
use crate::error::Result;
use std::collections::HashMap;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, LazyLock, Weak};
use std::time::Duration;
use stream_tungstenite::WebSocketClient;
use tokio::sync::{broadcast, oneshot, Mutex, RwLock};

use super::auth::ApiAuthHandshaker;

pub(super) type PendingRequests = Arc<Mutex<HashMap<u64, oneshot::Sender<Vec<u8>>>>>;

pub(crate) static API_EVENTS: LazyLock<broadcast::Sender<ApiEvent>> =
    LazyLock::new(|| broadcast::channel(256).0);
pub(crate) static API_PERMANENTLY_REJECTED: AtomicBool = AtomicBool::new(false);

pub(crate) struct ApiClient {
    pub(crate) context: Weak<Context>,
    pub(crate) config: ApiConfig,
    pub(crate) state: RwLock<ApiConnectionState>,
    pub(crate) ws_client: Mutex<Option<Arc<WebSocketClient>>>,
    pub(crate) pending: PendingRequests,
    pub(crate) next_sequence: Mutex<u64>,
    pub(crate) events: broadcast::Sender<ApiEvent>,
    pub(crate) deliberately_closed: AtomicBool,
    pub(crate) in_background: AtomicBool,
    pub(crate) network_available: AtomicBool,
    pub(crate) is_authenticated: Arc<AtomicBool>,
}

impl ApiClient {
    pub(crate) fn new(context: &Arc<Context>, config: ApiConfig) -> Arc<Self> {
        Arc::new(Self {
            context: Arc::downgrade(context),
            config,
            state: RwLock::const_new(ApiConnectionState::Stopped),
            ws_client: Mutex::const_new(None),
            pending: Arc::new(Mutex::const_new(HashMap::new())),
            next_sequence: Mutex::const_new(1),
            events: API_EVENTS.clone(),
            deliberately_closed: AtomicBool::new(false),
            in_background: AtomicBool::new(false),
            network_available: AtomicBool::new(true),
            is_authenticated: Arc::new(AtomicBool::new(false)),
        })
    }

    pub(crate) async fn set_state(&self, state: ApiConnectionState) {
        let mut guard = self.state.write().await;
        if *guard != state {
            *guard = state;
            drop(guard);
            let _ = self.events.send(ApiEvent {
                kind: ApiEventKind::ConnectionStateChanged,
                state: Some(state),
                message: None,
            });
        }
    }

    pub async fn connect(self: &Arc<Self>) -> Result<()> {
        if API_PERMANENTLY_REJECTED.load(Ordering::Acquire) {
            self.set_state(ApiConnectionState::PermanentlyRejected)
                .await;
            return Err(crate::error::TwonlyError::Generic(
                "API connection was permanently rejected for this process".into(),
            ));
        }
        self.deliberately_closed.store(false, Ordering::Release);

        let mut client_guard = self.ws_client.lock().await;
        if client_guard.is_some() {
            return Ok(());
        }

        self.set_state(ApiConnectionState::Connecting).await;

        let host = &self.config.websocket_url;

        let context = self
            .context
            .upgrade()
            .ok_or(crate::error::TwonlyError::Initialization)?;
        let handshaker = ApiAuthHandshaker {
            context,
            api_client: Arc::downgrade(self),
            is_authenticated: self.is_authenticated.clone(),
            in_background: self.in_background.load(Ordering::Acquire),
            events: self.events.clone(),
        };

        let client = WebSocketClient::builder(host)
            .receive_timeout(Duration::from_secs(60))
            .handshaker(handshaker)
            .build();

        let mut receiver = client.subscribe();
        let mut events = client.subscribe_events();

        let ws_arc = Arc::new(client);
        *client_guard = Some(ws_arc.clone());
        drop(client_guard);

        // Spawn client runner
        tokio::spawn({
            let c = ws_arc.clone();
            async move {
                let _ = c.run().await;
            }
        });

        let self_clone = self.clone();
        tokio::spawn(async move {
            loop {
                tokio::select! {
                    msg = receiver.recv() => {
                        match msg {
                            Ok(msg) => {
                                // Tungstenite message
                                if let stream_tungstenite::tokio_tungstenite::tungstenite::Message::Binary(bytes) = &*msg {
                                    self_clone.handle_incoming(bytes).await;
                                }
                            }
                            Err(_) => break,
                        }
                    }
                    ev = events.recv() => {
                        use stream_tungstenite::ConnectionEvent;
                        match ev {
                            Ok(ConnectionEvent::Connected { .. }) => {
                                let is_auth = self_clone.is_authenticated.load(Ordering::Acquire);
                                tracing::info!("ConnectionEvent::Connected received. is_authenticated={}", is_auth);
                                if is_auth {
                                    self_clone.set_state(ApiConnectionState::Authenticated).await;
                                } else {
                                    self_clone.set_state(ApiConnectionState::Connected).await;
                                }
                            }
                            Ok(ConnectionEvent::Disconnected { .. }) => {
                                self_clone.is_authenticated.store(false, Ordering::Release);
                                if API_PERMANENTLY_REJECTED.load(Ordering::Acquire) {
                                    self_clone.set_state(ApiConnectionState::PermanentlyRejected).await;
                                } else {
                                    self_clone.set_state(ApiConnectionState::Stopped).await;
                                }
                            }
                            Ok(ConnectionEvent::Connecting { .. }) => {
                                self_clone.set_state(ApiConnectionState::Connecting).await;
                            }
                            Ok(_) => {}
                            Err(_) => break,
                        }
                    }
                }
            }
        });

        Ok(())
    }

    pub async fn close(&self) {
        self.deliberately_closed.store(true, Ordering::Release);
        let client = self.ws_client.lock().await.take();
        if let Some(client) = client {
            if let Err(error) = client.shutdown_graceful(Duration::from_secs(5)).await {
                tracing::warn!("WebSocket shutdown did not finish cleanly: {error}");
            }
        }
        self.fail_pending().await;
        self.set_state(ApiConnectionState::Stopped).await;
    }

    pub(crate) async fn fail_pending(&self) {
        self.pending.lock().await.clear();
    }

    // pub async fn connection_state(&self) -> ApiConnectionState {
    //     *self.state.read().await
    // }

    pub(crate) async fn set_background(self: &Arc<Self>, in_background: bool) -> Result<()> {
        self.in_background.store(in_background, Ordering::Release);
        if in_background {
            self.set_state(ApiConnectionState::Suspended).await;
        } else if self.ws_client.lock().await.is_some() {
            self.set_state(ApiConnectionState::Authenticated).await;
        } else if self.network_available.load(Ordering::Acquire) {
            self.connect().await?;
        }
        Ok(())
    }

    pub(crate) async fn set_network_available(self: &Arc<Self>, available: bool) -> Result<()> {
        self.network_available.store(available, Ordering::Release);
        if available
            & !self.in_background.load(Ordering::Acquire)
            & self.ws_client.lock().await.is_none()
        {
            self.connect().await?;
        }
        Ok(())
    }
}
