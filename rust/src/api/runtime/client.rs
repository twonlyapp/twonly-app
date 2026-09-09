/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::bridge::api::{ApiConfig, ApiConnectionState, ApiEvent, ApiEventKind};
use crate::context::Context;
use crate::error::Result;
use std::collections::HashMap;
use std::sync::atomic::{AtomicBool, AtomicU32, Ordering};
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
/// A socket whose transport has died does not reconnect by itself: a failed
/// handshake makes the supervisor give up for good, and it leaves the send
/// channel behind so every later send reports a closed channel. These bound
/// the redial we drive ourselves, backing off so a handshake that keeps
/// failing (a rejected token, say) does not turn into a dial loop.
const FORCED_RECONNECT_INITIAL_DELAY: Duration = Duration::from_secs(1);
const FORCED_RECONNECT_MAX_DELAY: Duration = Duration::from_secs(60);

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
    /// Serializes replacing/closing the client slot. The WebSocket runner emits
    /// events asynchronously, so overlapping replacements must not clear each
    /// other's pending requests or publish stale state.
    connection_change: Mutex<()>,
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
    /// Set while a forced redial is pending, so the many sends that fail
    /// against one dead socket schedule a single reconnect between them.
    forced_reconnect_in_flight: AtomicBool,
    /// Counts forced redials since the last authenticated session; feeds the
    /// backoff in [`ApiClient::schedule_reconnect`].
    forced_reconnect_attempts: AtomicU32,
}

impl ApiClient {
    pub(crate) fn new(context: &Arc<Context>, config: ApiConfig) -> Arc<Self> {
        let in_background = config.in_background;
        Arc::new(Self {
            context: Arc::downgrade(context),
            config,
            state: RwLock::const_new(ApiConnectionState::Stopped),
            ws_client: Mutex::const_new(None),
            connection_change: Mutex::const_new(()),
            pending: Arc::new(Mutex::const_new(HashMap::new())),
            next_sequence: Mutex::const_new(1),
            events: API_EVENTS.clone(),
            deliberately_closed: AtomicBool::new(false),
            in_background: AtomicBool::new(in_background),
            network_available: AtomicBool::new(true),
            is_authenticated: Arc::new(AtomicBool::new(false)),
            catch_up_tx: Mutex::const_new(None),
            forced_reconnect_in_flight: AtomicBool::new(false),
            forced_reconnect_attempts: AtomicU32::new(0),
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

                // The outbox needs the same safety net as the mailbox. Every
                // other flush is tied to an event -- authenticating, a message
                // arriving, a background job -- so on a connection that stays
                // up while nothing comes in, a send that failed once had
                // nothing left to retry it. A one-way conversation is exactly
                // the case with no inbound message to trigger the sweep.
                //
                // Not in a notification worker: its whole budget belongs to the
                // alert, and it must not spend the one app-database connection
                // on the outbox while a drain is waiting for it.
                if !context.is_notification_runtime() {
                    if let Err(error) =
                        crate::api::messages::incoming::messages::retransmit_queued_receipts(
                            &context,
                        )
                        .await
                    {
                        tracing::warn!("outbox catch-up flush failed: {error}");
                    }
                }
            }
        });
    }

    /// Discards a socket the transport has declared dead and dials a fresh one.
    ///
    /// The supervisor cannot do this itself: it treats every failure our
    /// handshaker reports as permanent, so it stops reconnecting, and because
    /// that path skips its session cleanup it leaves the send channel in place
    /// with no reader behind it. `ws_client` therefore still holds a client
    /// that looks alive while every send fails with `ChannelClosed`, and
    /// `connect` returns early on it. Only replacing it recovers.
    ///
    /// `stale` is the connection the caller failed on; if the slot already
    /// holds a different one, someone reconnected in the meantime and this is
    /// a no-op. The redial runs detached so the caller can return its own
    /// error right away — whatever failed to send is retried by the
    /// post-authentication receipt sweep once the new socket is up.
    pub(crate) fn schedule_reconnect(self: &Arc<Self>, stale: &Arc<WebSocketClient>, reason: &str) {
        if self.deliberately_closed.load(Ordering::Acquire)
            || API_PERMANENTLY_REJECTED.load(Ordering::Acquire)
        {
            return;
        }
        // Every send against the dead socket lands here; only the first one
        // gets to schedule the redial.
        if self.forced_reconnect_in_flight.swap(true, Ordering::AcqRel) {
            return;
        }

        let client = self.clone();
        let stale = stale.clone();
        let reason = reason.to_owned();
        tokio::spawn(async move {
            let result = client.reconnect(&stale, &reason).await;
            client
                .forced_reconnect_in_flight
                .store(false, Ordering::Release);
            if let Err(error) = result {
                tracing::warn!("reconnect after a dead API WebSocket failed: {error}");
            }
        });
    }

    async fn reconnect(self: &Arc<Self>, stale: &Arc<WebSocketClient>, reason: &str) -> Result<()> {
        let connection_change = self.connection_change.lock().await;
        {
            let guard = self.ws_client.lock().await;
            if !guard
                .as_ref()
                .is_some_and(|current| Arc::ptr_eq(current, stale))
            {
                return Ok(());
            }
        }

        // Counted only for a socket that was still the live one, so a stale
        // report cannot inflate the backoff.
        let attempt = self
            .forced_reconnect_attempts
            .fetch_add(1, Ordering::AcqRel);
        let delay = FORCED_RECONNECT_INITIAL_DELAY
            .saturating_mul(1_u32 << attempt.min(6))
            .min(FORCED_RECONNECT_MAX_DELAY);
        tracing::warn!(
            reason,
            attempt,
            ?delay,
            "API WebSocket is dead, reconnecting"
        );

        self.discard_current_connection(reason).await;
        drop(connection_change);

        tokio::time::sleep(delay).await;

        // Closing the client or losing the network during the delay means the
        // redial is no longer wanted.
        if self.deliberately_closed.load(Ordering::Acquire)
            || !self.network_available.load(Ordering::Acquire)
        {
            return Ok(());
        }
        self.connect().await
    }

    /// Restarts the forced-reconnect backoff. A session that got all the way to
    /// an authenticated handshake proves the credentials and the server are
    /// fine, so the next dead socket starts over at the short delay.
    pub(crate) fn note_authenticated(&self) {
        self.forced_reconnect_attempts.store(0, Ordering::Release);
    }

    pub(crate) async fn set_state(&self, state: ApiConnectionState) {
        let mut guard = self.state.write().await;
        if *guard != state {
            *guard = state;
            drop(guard);
            tracing::info!(?state, "API connection state changed");
            let _ = self.events.send(ApiEvent {
                kind: ApiEventKind::ConnectionStateChanged,
                state: Some(state),
                message: None,
            });
        }
    }

    /// Returns whether `connection` still owns the live client slot.
    ///
    /// A replaced socket can emit its final disconnect/shutdown events after
    /// the new socket has started. Those events must not overwrite the new
    /// connection's state or schedule another reconnect.
    async fn is_current_connection(&self, connection: &Arc<WebSocketClient>) -> bool {
        self.ws_client
            .lock()
            .await
            .as_ref()
            .is_some_and(|current| Arc::ptr_eq(current, connection))
    }

    /// Drops the current transport without waiting for its graceful-shutdown
    /// timeout. Used for external reachability changes, where waiting would
    /// defeat the purpose of an immediate reconnect.
    async fn discard_current_connection(&self, reason: &str) {
        let current = self.ws_client.lock().await.take();
        self.is_authenticated.store(false, Ordering::Release);
        // Dropping the sender ends the catch-up loop bound to the old socket.
        *self.catch_up_tx.lock().await = None;

        if let Some(current) = current {
            tracing::info!(reason, "discarding API WebSocket");
            current.shutdown();
        }

        self.fail_pending().await;
        self.set_state(ApiConnectionState::Stopped).await;
    }

    /// Starts a fresh connection immediately, bypassing any retry sleep owned
    /// by the previous transport. The replacement client still uses the normal
    /// exponential backoff if this first attempt fails.
    async fn reconnect_now(self: &Arc<Self>, reason: &str) -> Result<()> {
        let _connection_change = self.connection_change.lock().await;
        if API_PERMANENTLY_REJECTED.load(Ordering::Acquire)
            || self.deliberately_closed.load(Ordering::Acquire)
            || self.in_background.load(Ordering::Acquire)
            || !self.network_available.load(Ordering::Acquire)
        {
            return Ok(());
        }

        self.discard_current_connection(reason).await;
        self.connect_inner().await
    }

    pub async fn connect(self: &Arc<Self>) -> Result<()> {
        let _connection_change = self.connection_change.lock().await;
        self.connect_inner().await
    }

    async fn connect_inner(self: &Arc<Self>) -> Result<()> {
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
        let connection = Arc::downgrade(&ws_arc);
        tokio::spawn(async move {
            loop {
                tokio::select! {
                    msg = receiver.recv() => {
                        match msg {
                            Ok(msg) => {
                                let Some(connection) = connection.upgrade() else {
                                    break;
                                };
                                if !self_clone.is_current_connection(&connection).await {
                                    break;
                                }
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
                        let Some(connection) = connection.upgrade() else {
                            break;
                        };
                        if !self_clone.is_current_connection(&connection).await {
                            break;
                        }
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
                            // The supervisor has stopped reconnecting: it
                            // treats every handshake failure as permanent, and
                            // that path leaves the send channel behind with no
                            // reader, so this socket can neither reconnect nor
                            // send. Replace it instead of sitting on it.
                            Ok(ConnectionEvent::FatalError { .. } | ConnectionEvent::Shutdown) => {
                                self_clone.is_authenticated.store(false, Ordering::Release);
                                self_clone.schedule_reconnect(
                                    &connection,
                                    "supervisor stopped reconnecting",
                                );
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
        let _connection_change = self.connection_change.lock().await;
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
        } else {
            // Mobile platforms can freeze the process while keeping the socket
            // object alive. Its TCP connection may be dead even though neither
            // the OS nor tungstenite has reported that yet, so foregrounding
            // always starts a fresh attempt instead of waiting for a timeout.
            self.reconnect_now("application entered the foreground")
                .await?;
        }
        Ok(())
    }

    pub(crate) async fn set_network_available(self: &Arc<Self>, available: bool) -> Result<()> {
        self.network_available.store(available, Ordering::Release);
        if available {
            // A Wi-Fi/mobile/route change can leave an apparently connected
            // socket bound to the old network. Replace it now, including when
            // its own supervisor is currently sleeping in reconnect backoff.
            self.reconnect_now("network became available or changed")
                .await?;
        } else {
            // Reflect loss of reachability immediately instead of showing an
            // authenticated state until the receive timeout expires.
            let _connection_change = self.connection_change.lock().await;
            self.discard_current_connection("network became unavailable")
                .await;
        }
        Ok(())
    }
}
