/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::bridge::api::{ApiConfig, ApiConnectionState, ApiEvent, ApiEventKind};
use crate::context::Context;
use crate::error::Result;
use std::collections::{HashMap, VecDeque};
use std::sync::atomic::{AtomicBool, AtomicU32, AtomicU64, Ordering};
use std::sync::{Arc, LazyLock, Mutex as SyncMutex, Weak};
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

/// The safety catch-up while a large mailbox is being caught up. A drain the
/// server stopped would otherwise leave the progress screen frozen for a
/// minute.

const SYNC_CATCH_UP_INTERVAL: Duration = Duration::from_secs(10);

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

/// Transport cleanup must outlive cancellation of database consumers. Aborting
/// `run()` detaches the transport's receiver task and leaves its socket open.
fn spawn_transport(client: Arc<WebSocketClient>) -> tokio::task::JoinHandle<()> {
    let operation = crate::database::lifecycle::Operation::inherited();
    let source = crate::log::current_log_source();

    tokio::spawn(source.scope(async move {
        if let Some(operation) = operation {
            let running = operation.scope(client.run());
            tokio::pin!(running);

            tokio::select! {
                _ = operation.until_cancelled() => {
                    client.shutdown();
                    let _ = running.await;
                }
                _ = &mut running => {}
            }
        } else {
            let _ = client.run().await;
        }
    }))
}

#[derive(Default)]

struct ReconnectWork {
    running: bool,
    pending: VecDeque<(Arc<WebSocketClient>, String)>,
}

#[cfg(test)]

mod tests {

    use super::*;

    fn client() -> Arc<ApiClient> {
        Arc::new(ApiClient {
            context: Weak::new(),
            config: ApiConfig {
                websocket_url: "ws://127.0.0.1:1".into(),
                legacy_user_app_version: 0,
                in_background: false,
                can_use_login_token_for_auth: true,
            },
            state: RwLock::new(ApiConnectionState::Stopped),
            ws_client: Mutex::new(None),
            connection_change: Mutex::new(()),
            connection_generation: AtomicU64::new(0),
            pending: Arc::new(Mutex::new(HashMap::new())),
            next_sequence: Mutex::new(1),
            events: broadcast::channel(32).0,
            deliberately_closed: AtomicBool::new(false),
            in_background: AtomicBool::new(false),
            requested_background: AtomicBool::new(false),
            network_available: AtomicBool::new(true),
            is_authenticated: Arc::new(AtomicBool::new(false)),
            catch_up_tx: Mutex::new(None),
            forced_reconnect: SyncMutex::new(ReconnectWork::default()),
            forced_reconnect_attempts: AtomicU32::new(0),
            background_deferred: AtomicBool::new(false),
        })
    }

    fn socket() -> Arc<WebSocketClient> {
        // Never run the transport: these tests must not access the network.
        Arc::new(WebSocketClient::builder("ws://127.0.0.1:1").build())
    }

    #[tokio::test]
    async fn cancelling_database_owner_closes_the_transport_and_peer_socket() {
        use futures_util::StreamExt;
        use stream_tungstenite::tokio_tungstenite::accept_async;

        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let socket = Arc::new(
            WebSocketClient::builder(format!("ws://{}", listener.local_addr().unwrap())).build(),
        );
        let (received, ready) = oneshot::channel();
        let peer = tokio::spawn(async move {
            let (stream, _) = listener.accept().await.unwrap();
            let mut stream = accept_async(stream).await.unwrap();
            assert!(stream.next().await.unwrap().unwrap().is_binary());
            let _ = received.send(());
            // A detached receiver used to keep this socket alive until its
            // receive timeout, even after the database owner was fully drained.
            let _ = stream.next().await;
        });

        let operation = crate::database::lifecycle::Operation::foreground();
        let runner = operation
            .scope(async { spawn_transport(socket.clone()) })
            .await;

        tokio::time::timeout(Duration::from_secs(3), async {
            loop {
                if socket
                    .send(
                        stream_tungstenite::tokio_tungstenite::tungstenite::Message::Binary(
                            vec![1].into(),
                        ),
                    )
                    .await
                    .is_ok()
                {
                    break;
                }
                tokio::task::yield_now().await;
            }
            ready.await.unwrap();
        })
        .await
        .unwrap();

        operation.cancel();
        operation.drain().await;
        tokio::time::timeout(Duration::from_secs(2), runner)
            .await
            .unwrap()
            .unwrap();
        tokio::time::timeout(Duration::from_secs(2), peer)
            .await
            .unwrap()
            .unwrap();
    }

    #[tokio::test]
    async fn background_rejection_defers_only_its_current_client() {
        let client = client();
        client.in_background.store(true, Ordering::Release);
        client.connection_generation.store(2, Ordering::Release);

        client.defer_background_for_generation(1).await;
        assert!(!client.background_deferred());

        client.defer_background_for_generation(2).await;
        assert!(client.background_deferred());
        assert_eq!(*client.state.read().await, ApiConnectionState::Suspended);

        client.schedule_reconnect(&socket(), "handshake refused background auth");
        assert!(client.forced_reconnect.lock().unwrap().pending.is_empty());

        // A later connect in the same run must not restart the dial loop.
        client.connect().await.unwrap();
        assert!(client.ws_client.lock().await.is_none());
        assert!(!self::client().background_deferred());

        client.close().await;
        assert!(!client.background_deferred());
        client.deliberately_closed.store(false, Ordering::Release);
        client
            .defer_background_for_generation(client.connection_generation.load(Ordering::Acquire))
            .await;
        assert!(client.background_deferred());

        // Foreground adoption is allowed to authenticate normally again.
        let _ = client.set_background(false).await;
        assert!(!client.background_deferred());
    }

    #[tokio::test]

    async fn obsolete_handshake_cannot_publish_authenticated_state() {
        let client = client();

        client.connection_generation.store(1, Ordering::Release);

        assert!(
            client
                .set_state_for_generation(1, ApiConnectionState::Authenticated)
                .await
        );

        {
            let _change = client.connection_change.lock().await;

            client.discard_current_connection("replacement").await;
        }

        assert!(
            !client
                .set_state_for_generation(1, ApiConnectionState::Authenticated)
                .await
        );

        assert!(!client.is_authenticated.load(Ordering::Acquire));

        assert_eq!(*client.state.read().await, ApiConnectionState::Stopped);

        assert!(
            client
                .set_state_for_generation(2, ApiConnectionState::Authenticating)
                .await
        );

        assert_eq!(
            *client.state.read().await,
            ApiConnectionState::Authenticating
        );
    }

    #[tokio::test]

    async fn focus_only_resume_keeps_the_authenticated_socket() {
        let client = client();

        let socket = socket();

        *client.ws_client.lock().await = Some(socket.clone());

        client.is_authenticated.store(true, Ordering::Release);

        client.set_state(ApiConnectionState::Authenticated).await;

        client.set_background(false).await.unwrap();

        assert!(client.is_current_connection(&socket).await);

        assert_eq!(
            *client.state.read().await,
            ApiConnectionState::Authenticated
        );
    }

    #[tokio::test]

    async fn native_push_keeps_a_healthy_socket_and_requests_catch_up() {
        let client = client();

        let socket = socket();

        *client.ws_client.lock().await = Some(socket.clone());

        client.is_authenticated.store(true, Ordering::Release);

        client.set_state(ApiConnectionState::Authenticated).await;

        let (sender, mut receiver) = mpsc::channel(1);

        *client.catch_up_tx.lock().await = Some(sender);

        client.catch_up_after_push().await.unwrap();

        assert!(client.is_current_connection(&socket).await);

        assert!(receiver.try_recv().is_ok());

        assert!(client.is_authenticated.load(Ordering::Acquire));
    }

    #[tokio::test]

    async fn native_push_does_not_replace_an_in_flight_connection() {
        let client = client();

        let socket = socket();

        *client.ws_client.lock().await = Some(socket.clone());

        client.set_state(ApiConnectionState::Connecting).await;

        client.catch_up_after_push().await.unwrap();

        assert!(client.is_current_connection(&socket).await);

        assert_eq!(*client.state.read().await, ApiConnectionState::Connecting);
    }

    #[tokio::test]

    async fn replacement_failure_is_processed_during_an_existing_retry() {
        let client = client();

        // Keep the test offline, including once the forced retry timer expires.
        client.network_available.store(false, Ordering::Release);

        let first = socket();

        *client.ws_client.lock().await = Some(first.clone());

        client.schedule_reconnect(&first, "first failure");

        tokio::time::timeout(Duration::from_secs(1), async {
            while client.ws_client.lock().await.is_some() {
                tokio::task::yield_now().await;
            }
        })
        .await
        .unwrap();

        // The first worker is asleep. A foreground/network transition has
        // installed another transport that now also fails permanently.
        let replacement = socket();

        *client.ws_client.lock().await = Some(replacement.clone());

        client.schedule_reconnect(&replacement, "replacement failure");

        client.schedule_reconnect(&replacement, "duplicate failure");

        assert_eq!(client.forced_reconnect.lock().unwrap().pending.len(), 1);

        tokio::time::timeout(Duration::from_secs(2), async {
            while client.ws_client.lock().await.is_some() {
                tokio::task::yield_now().await;
            }
        })
        .await
        .unwrap();

        assert_eq!(client.forced_reconnect_attempts.load(Ordering::Acquire), 2);
    }
}

pub(crate) struct ApiClient {
    pub(crate) context: Weak<Context>,
    pub(crate) config: ApiConfig,
    pub(crate) state: RwLock<ApiConnectionState>,
    pub(crate) ws_client: Mutex<Option<Arc<WebSocketClient>>>,
    /// Serializes replacing/closing the client slot. The WebSocket runner emits
    /// events asynchronously, so overlapping replacements must not clear each
    /// other's pending requests or publish stale state.
    pub(super) connection_change: Mutex<()>,
    pub(super) connection_generation: AtomicU64,
    pub(crate) pending: PendingRequests,
    pub(crate) next_sequence: Mutex<u64>,
    pub(crate) events: broadcast::Sender<ApiEvent>,
    pub(crate) deliberately_closed: AtomicBool,
    pub(crate) in_background: AtomicBool,
    // Preserve the app's lifecycle while location sharing temporarily keeps
    // the transport awake. Stopping must return to that lifecycle.
    pub(crate) requested_background: AtomicBool,
    pub(crate) network_available: AtomicBool,
    pub(crate) is_authenticated: Arc<AtomicBool>,
    /// Wakes the per-connection catch-up loop. Capacity one, sent with
    /// `try_send`, so repeated triggers collapse into a single pull instead of
    /// queueing one request each.
    catch_up_tx: Mutex<Option<mpsc::Sender<()>>>,
    /// Coalesces failures per socket while retaining failures from replacement
    /// sockets that die before the preceding retry finishes.
    forced_reconnect: SyncMutex<ReconnectWork>,
    /// Counts forced redials since the last authenticated session; feeds the
    /// backoff in [`ApiClient::schedule_reconnect`].
    forced_reconnect_attempts: AtomicU32,
    /// The server has a foreground session for this account. Only a later
    /// native run or foreground adoption should try background auth again.
    background_deferred: AtomicBool,
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
            connection_generation: AtomicU64::new(0),
            pending: Arc::new(Mutex::const_new(HashMap::new())),
            next_sequence: Mutex::const_new(1),
            events: API_EVENTS.clone(),
            deliberately_closed: AtomicBool::new(false),
            in_background: AtomicBool::new(in_background),
            requested_background: AtomicBool::new(in_background),
            network_available: AtomicBool::new(true),
            is_authenticated: Arc::new(AtomicBool::new(false)),
            catch_up_tx: Mutex::const_new(None),
            forced_reconnect: SyncMutex::new(ReconnectWork::default()),
            forced_reconnect_attempts: AtomicU32::new(0),
            background_deferred: AtomicBool::new(false),
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

    /// A native push can run while Flutter is suspended with a cached offline
    /// flag and no socket. Restore the shared client before requesting a drain;
    /// runtime ownership alone says nothing about transport availability.

    pub(crate) async fn catch_up_after_push(self: &Arc<Self>) -> Result<()> {
        let _change = self.connection_change.lock().await;

        let state = *self.state.read().await;

        let missing_socket = self.ws_client.lock().await.is_none();

        tracing::info!(
            ?state,
            missing_socket,
            network_available = self.network_available.load(Ordering::Acquire),
            in_background = self.in_background.load(Ordering::Acquire),
            "processing native push catch-up"
        );

        // Dart's connectivity stream may not run again until the app resumes.
        // The native wake-up gets one network attempt regardless of that cache.
        self.network_available.store(true, Ordering::Release);

        if missing_socket || state == ApiConnectionState::Stopped {
            if !missing_socket {
                self.discard_current_connection("native push found a stopped connection")
                    .await;
            }

            tracing::info!("restoring API connection for native push");

            self.connect_inner().await?;
        }

        self.request_catch_up().await;

        Ok(())
    }

    pub(crate) async fn retry_deferred_push(self: &Arc<Self>) -> Result<()> {
        let _change = self.connection_change.lock().await;

        if self.background_deferred() && self.in_background.load(Ordering::Acquire) {
            self.background_deferred.store(false, Ordering::Release);
            self.discard_current_connection("retrying native push after session handoff")
                .await;
            self.connect_inner().await?;
        }

        Ok(())
    }

    /// Runs the catch-up loop for one connection. It exits as soon as that
    /// connection is replaced or closed, so a disconnected client never
    /// reconnects just to poll — reconnection triggers its own catch-up.

    fn spawn_catch_up_loop(
        self: &Arc<Self>, ws_client: &Arc<WebSocketClient>, mut receiver: mpsc::Receiver<()>,
    ) {
        let client = Arc::downgrade(self);

        let connection = Arc::downgrade(ws_client);

        crate::database::lifecycle::spawn(async move {
            loop {
                let delay = if crate::api::messages::mailbox_sync::is_active() {
                    SYNC_CATCH_UP_INTERVAL
                } else {
                    CATCH_UP_INTERVAL
                        + Duration::from_millis(
                            rand::random::<u64>() % (CATCH_UP_JITTER.as_millis() as u64).max(1),
                        )
                };

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
            || self.background_deferred()
        {
            return;
        }

        let mut work = self
            .forced_reconnect
            .lock()
            .unwrap_or_else(|error| error.into_inner());

        if !work
            .pending
            .iter()
            .any(|(connection, _)| Arc::ptr_eq(connection, stale))
        {
            work.pending.push_back((stale.clone(), reason.to_owned()));
        }

        // A replacement socket can fail while the preceding retry is still
        // asleep. Keep that failure queued rather than dropping its only
        // FatalError event and leaving the replacement permanently stopped.
        if work.running {
            return;
        }

        work.running = true;

        drop(work);

        let client = self.clone();

        crate::database::lifecycle::spawn(async move {
            loop {
                let next = {
                    let mut work = client
                        .forced_reconnect
                        .lock()
                        .unwrap_or_else(|error| error.into_inner());

                    match work.pending.pop_front() {
                        Some(next) => Some(next),
                        None => {
                            work.running = false;

                            None
                        }
                    }
                };

                let Some((stale, reason)) = next else {
                    break;
                };

                if let Err(error) = client.reconnect(&stale, &reason).await {
                    tracing::warn!("reconnect after a dead API WebSocket failed: {error}");
                }
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
            || self.background_deferred()
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

    pub(super) async fn set_state_for_generation(
        &self, generation: u64, state: ApiConnectionState,
    ) -> bool {
        let _change = self.connection_change.lock().await;

        if generation != self.connection_generation.load(Ordering::Acquire) {
            return false;
        }

        if state == ApiConnectionState::Authenticated {
            self.is_authenticated.store(true, Ordering::Release);

            self.note_authenticated();
        }

        self.set_state(state).await;

        true
    }

    pub(crate) fn background_deferred(&self) -> bool {
        self.background_deferred.load(Ordering::Acquire)
    }

    pub(super) async fn defer_background_for_generation(&self, generation: u64) {
        let _change = self.connection_change.lock().await;

        if generation == self.connection_generation.load(Ordering::Acquire)
            && self.in_background.load(Ordering::Acquire)
        {
            self.background_deferred.store(true, Ordering::Release);
            self.set_state(ApiConnectionState::Suspended).await;
        }
    }

    /// Returns whether `connection` still owns the live client slot.
    ///
    /// A replaced socket can emit its final disconnect/shutdown events after
    /// the new socket has started. Those events must not overwrite the new
    /// connection's state or schedule another reconnect.

    pub(super) async fn is_current_connection(&self, connection: &Arc<WebSocketClient>) -> bool {
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
        self.connection_generation.fetch_add(1, Ordering::AcqRel);

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
        // A push may restore the shared socket while Flutter is visible. Its
        // short-lived notification operation must not own the app's receive
        // and catch-up tasks, or finishing that push would stop delivery again.
        if let Some(context) = self.context.upgrade() {
            if context.is_flutter_runtime() {
                // A cancelled epoch stays attached until the next resume, and
                // tasks spawned under it are aborted before their first poll.
                if let Some(operation) = context.foreground.ready_operation() {
                    return operation.scope(self.connect_for_owner()).await;
                }
            }
        }

        self.connect_for_owner().await
    }

    async fn connect_for_owner(self: &Arc<Self>) -> Result<()> {
        if self.background_deferred() {
            self.set_state(ApiConnectionState::Suspended).await;

            return Ok(());
        }

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
            generation: self.connection_generation.fetch_add(1, Ordering::AcqRel) + 1,
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

        // The transport must finish its own cleanup after its owner expires.
        // Application message handlers below remain abortable descendants.
        spawn_transport(ws_arc.clone());

        let self_clone = self.clone();

        let connection = Arc::downgrade(&ws_arc);

        crate::database::lifecycle::spawn(async move {
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
                                use stream_tungstenite::tokio_tungstenite::tungstenite::Message;
                                match &*msg {
                                    Message::Binary(bytes) => {
                                        self_clone.handle_incoming(&connection, bytes).await;
                                    }
                                    // The server's close code tells why it dropped the
                                    // connection, e.g. 1013 (outbound queue full) or 4003
                                    // (ack timeouts). The disconnect event does not carry it.
                                    Message::Close(frame) => match frame {
                                        Some(frame) => tracing::info!(
                                            "websocket closed by the server with code {}: {}",
                                            u16::from(frame.code),
                                            frame.reason
                                        ),
                                        None => tracing::info!(
                                            "websocket closed by the server without a code"
                                        ),
                                    },
                                    _ => {}
                                }
                            }
                            Err(_) => break,
                        }
                    }
                    ev = events.recv() => {
                        use stream_tungstenite::ConnectionEvent;
                        let _change = self_clone.connection_change.lock().await;
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
                                } else if self_clone.background_deferred() {
                                    self_clone.set_state(ApiConnectionState::Suspended).await;
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

        let client = {
            let _connection_change = self.connection_change.lock().await;

            self.connection_generation.fetch_add(1, Ordering::AcqRel);

            self.background_deferred.store(false, Ordering::Release);

            self.is_authenticated.store(false, Ordering::Release);

            // Dropping the sender ends the catch-up loop for this connection.
            *self.catch_up_tx.lock().await = None;

            let client = self.ws_client.lock().await.take();

            self.fail_pending().await;
            self.set_state(ApiConnectionState::Stopped).await;
            client
        };

        if let Some(client) = client {
            // A handshaker may be waiting for connection_change to publish its
            // generation. Do not hold that lock while joining the transport.
            if let Err(error) = client.shutdown_graceful(Duration::from_secs(5)).await {
                tracing::warn!("WebSocket shutdown did not finish cleanly: {error}");
            }
        }
    }

    pub(crate) async fn fail_pending(&self) {
        self.pending.lock().await.clear();
    }

    // pub async fn connection_state(&self) -> ApiConnectionState {
    //     *self.state.read().await
    // }

    pub(crate) async fn set_background(self: &Arc<Self>, in_background: bool) -> Result<()> {
        let was_background = self.in_background.swap(in_background, Ordering::AcqRel);

        if in_background {
            self.set_state(ApiConnectionState::Suspended).await;
        } else {
            self.background_deferred.store(false, Ordering::Release);

            if !was_background
                && matches!(
                    *self.state.read().await,
                    ApiConnectionState::Authenticated
                        | ApiConnectionState::Authenticating
                        | ApiConnectionState::Connected
                        | ApiConnectionState::Connecting
                        | ApiConnectionState::Reconnecting
                )
            {
                // Permission sheets and control centre also emit resumed.
                // They must not repeatedly tear down a healthy socket.
                return Ok(());
            }

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
