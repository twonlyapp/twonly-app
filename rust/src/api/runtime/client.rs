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
use stream_tungstenite::{ClientConfig, WebSocketClient};
use tokio::sync::{broadcast, mpsc, oneshot, Mutex, RwLock};

use super::auth::ApiAuthHandshaker;

pub(super) type PendingRequests = Arc<Mutex<HashMap<u64, oneshot::Sender<Vec<u8>>>>>;

/// Base delay of the safety catch-up while the socket stays connected. Every
/// other trigger (authentication, reconnection, foregrounding, a push) fires a
/// catch-up immediately, so this only has to cover a silently stalled drain.
const CATCH_UP_INTERVAL: Duration = Duration::from_secs(60);
/// Spread across clients so reconnect storms do not line their pulls up.
const CATCH_UP_JITTER: Duration = Duration::from_secs(15);

/// First reconnect attempt after a drop. Kept well below a second so a server
/// restart or a short network blip is over before the user notices missing
/// messages.
const RECONNECT_INITIAL_DELAY: Duration = Duration::from_millis(250);
const RECONNECT_MAX_DELAY: Duration = Duration::from_secs(20);
const RECEIVE_TIMEOUT: Duration = Duration::from_secs(45);
const CONNECT_TIMEOUT: Duration = Duration::from_secs(10);
const HANDSHAKE_RETRY_DELAY: Duration = Duration::from_secs(1);

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
    /// Wakes the per-connection catch-up loop. Capacity one, sent with
    /// `try_send`, so repeated triggers collapse into a single pull instead of
    /// queueing one request each.
    catch_up_tx: Mutex<Option<mpsc::Sender<()>>>,
}

impl ApiClient {
    pub(crate) fn new(context: &Arc<Context>, config: ApiConfig) -> Arc<Self> {
        let in_background = config.in_background;
        Arc::new(Self {
            context: Arc::downgrade(context),
            config,
            state: RwLock::const_new(ApiConnectionState::Stopped),
            ws_client: Mutex::const_new(None),
            pending: Arc::new(Mutex::const_new(HashMap::new())),
            next_sequence: Mutex::const_new(1),
            events: API_EVENTS.clone(),
            deliberately_closed: AtomicBool::new(false),
            in_background: AtomicBool::new(in_background),
            network_available: AtomicBool::new(true),
            is_authenticated: Arc::new(AtomicBool::new(false)),
            catch_up_tx: Mutex::const_new(None),
        })
    }

    /// Asks the server to redeliver anything still queued for this user.
    ///
    /// Coalescing happens in the channel: while a pull is in flight further
    /// triggers set the single pending slot, so the loop issues exactly one
    /// more request afterwards no matter how many arrived.
    pub(crate) async fn request_catch_up(&self) {
        if let Some(sender) = self.catch_up_tx.lock().await.as_ref() {
            let _ = sender.try_send(());
        }
    }

    /// Runs the catch-up loop for one connection. It exits as soon as that
    /// connection is replaced or closed, so a disconnected client never
    /// reconnects just to poll — reconnection triggers its own catch-up.
    fn spawn_catch_up_loop(
        self: &Arc<Self>,
        ws_client: &Arc<WebSocketClient>,
        mut receiver: mpsc::Receiver<()>,
    ) {
        let client = Arc::downgrade(self);
        let connection = Arc::downgrade(ws_client);
        tokio::spawn(async move {
            loop {
                let delay = CATCH_UP_INTERVAL
                    + Duration::from_millis(
                        rand::random::<u64>() % (CATCH_UP_JITTER.as_millis() as u64).max(1),
                    );
                tokio::select! {
                    trigger = receiver.recv() => {
                        if trigger.is_none() {
                            break;
                        }
                    }
                    () = tokio::time::sleep(delay) => {}
                }

                let (Some(client), Some(connection)) = (client.upgrade(), connection.upgrade())
                else {
                    break;
                };

                // Stop once this task no longer belongs to the live connection.
                let is_current = client
                    .ws_client
                    .lock()
                    .await
                    .as_ref()
                    .is_some_and(|current| Arc::ptr_eq(current, &connection));
                if !is_current {
                    break;
                }

                if !client.is_authenticated.load(Ordering::Acquire) {
                    continue;
                }

                // Fold any triggers that piled up into the request below.
                while receiver.try_recv().is_ok() {}

                let Some(context) = client.context.upgrade() else {
                    break;
                };
                if let Err(error) = crate::api::Server::request_pending_messages(&context).await {
                    tracing::warn!("mailbox catch-up request failed: {error}");
                }
            }
        });
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

        // `config` replaces the whole `ClientConfig`, so it has to come before
        // `receive_timeout`, which only overwrites that one field.
        let client = WebSocketClient::builder(host)
            .config(
                ClientConfig::default()
                    .with_connect_timeout(CONNECT_TIMEOUT)
                    .with_handshake_retry_delay(HANDSHAKE_RETRY_DELAY)
                    .with_nodelay(true),
            )
            .receive_timeout(RECEIVE_TIMEOUT)
            .exponential_backoff(RECONNECT_INITIAL_DELAY, RECONNECT_MAX_DELAY, 2.0)
            .handshaker(handshaker)
            .build();

        let mut receiver = client.subscribe();
        let mut events = client.subscribe_events();

        let ws_arc = Arc::new(client);
        *client_guard = Some(ws_arc.clone());
        drop(client_guard);

        let (catch_up_tx, catch_up_rx) = mpsc::channel(1);
        *self.catch_up_tx.lock().await = Some(catch_up_tx);
        self.spawn_catch_up_loop(&ws_arc, catch_up_rx);

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
        self.is_authenticated.store(false, Ordering::Release);
        // Dropping the sender ends the catch-up loop for this connection.
        *self.catch_up_tx.lock().await = None;
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
            // Returning to the foreground: pick up whatever arrived while the
            // socket was suspended.
            self.request_catch_up().await;
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
