//! Consent-gated performance reporting. Fixed operation names and numeric
//! measurements only; existing logs, arguments and errors are never exported.
//! Each opt-in gets a fresh session so revocation also invalidates old spans.
use crate::context::Context;
use crate::error::Result;
use crate::user_config::UserConfig;
use sentry::{
    protocol::SpanStatus, Client, ClientOptions, Envelope, Hub, Scope, TransactionContext,
    TransactionOrSpan, Transport,
};
use std::future::Future;
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex, OnceLock};
use std::time::Duration;
use tokio::sync::mpsc;
use tokio_util::sync::CancellationToken;

const DSN: &str = "https://6b24a012c85144c9b522440a1d17d01c@glitchtip.twonly.eu/4";
const SAMPLE_RATE: f64 = if cfg!(debug_assertions) || cfg!(feature = "dev-api") {
    1.0
} else {
    0.01
};

#[derive(Default)]
struct State {
    data_dir: Option<PathBuf>,
    permission: bool,
    session: Option<Arc<Session>>,
}

static STATE: OnceLock<Mutex<State>> = OnceLock::new();

fn state() -> &'static Mutex<State> {
    STATE.get_or_init(Mutex::default)
}

struct Gate {
    revoked: CancellationToken,
}

impl Gate {
    fn allowed(&self) -> bool {
        !self.revoked.is_cancelled()
    }
}

struct Session {
    gate: Arc<Gate>,
    client: Arc<Client>,
}

impl Session {
    fn new() -> Option<Arc<Self>> {
        let dsn: sentry::types::Dsn = DSN.parse().ok()?;
        let endpoint = dsn.envelope_api_url();
        let auth = dsn.to_auth(Some("twonly-performance/1")).to_string();
        let gate = Arc::new(Gate {
            revoked: CancellationToken::new(),
        });
        let (sender, mut receiver) = mpsc::channel::<Envelope>(32);
        let transport = Arc::new(ConsentTransport {
            gate: gate.clone(),
            sender,
        });
        let client = Arc::new(Client::with_options(ClientOptions {
            dsn: Some(dsn),
            release: Some(format!("eu.twonly@{}", env!("TWONLY_APP_FULL_VERSION")).into()),
            environment: Some(env!("TWONLY_BUILD_MODE").into()),
            traces_sample_rate: SAMPLE_RATE as f32,
            default_integrations: false,
            send_default_pii: false,
            server_name: None,
            transport: Some(Arc::new(transport)),
            ..Default::default()
        }));
        let worker_gate = gate.clone();
        // Own the runtime: native background calls may use temporary runtimes.
        // The bounded, memory-only queue is discarded on revocation. No disk
        // cache or retry can send an old opt-in's data after re-enabling.
        std::thread::Builder::new().name("twonly-performance".into()).spawn(move || {
            let Ok(runtime) = tokio::runtime::Builder::new_current_thread().enable_all().build() else { return; };
            runtime.block_on(async move {
                let Ok(http) = crate::api::http::client_builder()
                    .redirect(reqwest::redirect::Policy::none())
                    .connect_timeout(Duration::from_secs(3))
                    .timeout(Duration::from_secs(5)).build() else { return; };
                loop {
                    let envelope = tokio::select! {
                        biased;
                        _ = worker_gate.revoked.cancelled() => break,
                        envelope = receiver.recv() => match envelope { Some(envelope) => envelope, None => break },
                    };
                    if !worker_gate.allowed() { break; }
                    let mut bytes = Vec::new();
                    if envelope.to_writer(&mut bytes).is_err() || bytes.len() > 256 * 1024 { continue; }
                    // Recheck immediately before HTTP and cancel an in-flight
                    // request when consent is revoked in this process.
                    if !worker_gate.allowed() { break; }
                    tokio::select! {
                        biased;
                        _ = worker_gate.revoked.cancelled() => break,
                        _ = async {
                            if let Ok(response) = http.post(endpoint.clone())
                                .header("X-Sentry-Auth", &auth)
                                .header("Content-Type", "application/x-sentry-envelope")
                                .body(bytes).send().await {
                                // Drain the small ingest response so subsequent
                                // samples can reuse the TLS connection.
                                let _ = response.bytes().await;
                            }
                        } => {},
                    }
                }
            });
        }).ok()?;
        Some(Arc::new(Self { gate, client }))
    }
}

struct ConsentTransport {
    gate: Arc<Gate>,
    sender: mpsc::Sender<Envelope>,
}

impl Transport for ConsentTransport {
    fn send_envelope(&self, envelope: Envelope) {
        if self.gate.allowed() {
            // This client handles performance only. Do not accidentally route
            // errors, breadcrumbs, attachments or session data through it.
            if let Some(envelope) = envelope
                .filter(|item| matches!(item, sentry::protocol::EnvelopeItem::Transaction(_)))
            {
                let _ = self.sender.try_send(envelope);
            }
        }
    }
}

/// Called once when the process creates its application context. Subsequent
/// runtime activations keep the cached permission; UserConfig saves update it.
pub(crate) fn initialize(context: &Context) {
    let data_dir = Path::new(&context.config.data_dir);
    {
        let Ok(state) = state().lock() else {
            return;
        };
        if state.data_dir.as_deref() == Some(data_dir) {
            return;
        }
    }
    // Use the existing configuration loader and its normalization/locking.
    // Never load settings from the tracing or transport paths.
    let permission = UserConfig::load_from(context)
        .ok()
        .flatten()
        .is_some_and(|config| config.allow_error_tracking_via_sentry);
    let Ok(mut state) = state().lock() else {
        return;
    };
    if let Some(session) = state.session.take() {
        session.gate.revoked.cancel();
    }
    state.data_dir = Some(data_dir.to_path_buf());
    state.permission = permission;
    configure(&mut state, true);
}

fn configure(state: &mut State, enabled: bool) {
    // Automated Flutter/native tests must never send production telemetry.
    let enabled = enabled && !cfg!(test) && std::env::var_os("FLUTTER_TEST").is_none();
    let allowed = enabled && state.permission;
    if !allowed {
        if let Some(session) = state.session.take() {
            session.gate.revoked.cancel();
        }
    } else if state
        .session
        .as_ref()
        .is_none_or(|session| session.gate.revoked.is_cancelled())
    {
        state.session = Session::new();
    }
}

/// Flutter can suspend reporting for account deletion. Enabling still requires
/// the permission cached from UserConfig; this is not a second permission.
pub(crate) fn set_enabled(enabled: bool) {
    if let Ok(mut state) = state().lock() {
        configure(&mut state, enabled);
    }
}

pub(crate) fn configuration_saved(data_dir: &str, enabled: bool) {
    if let Ok(mut state) = state().lock() {
        if state.data_dir.as_deref() == Some(Path::new(data_dir)) {
            state.permission = enabled;
            configure(&mut state, true);
        }
    }
}

#[derive(Clone)]
struct Active {
    session: Arc<Session>,
    span: TransactionOrSpan,
}

tokio::task_local! {
    static CURRENT: Option<Active>;
    static PARENT: std::cell::RefCell<Option<String>>;
}

pub(crate) fn enabled() -> bool {
    state()
        .lock()
        .ok()
        .and_then(|state| state.session.clone())
        .is_some_and(|session| session.gate.allowed())
}

pub(crate) async fn with_parent<T>(parent: Option<String>, future: impl Future<Output = T>) -> T {
    PARENT.scope(std::cell::RefCell::new(parent), future).await
}

pub(crate) struct Trace {
    active: Option<Active>,
    status: SpanStatus,
}

impl Trace {
    pub(crate) fn start(name: &str, op: &str) -> Self {
        Self {
            active: Self::start_active(name, op),
            status: SpanStatus::Cancelled,
        }
    }

    fn start_active(name: &str, op: &str) -> Option<Active> {
        if let Ok(parent) = CURRENT.try_with(Clone::clone) {
            return parent
                .filter(|parent| parent.session.gate.allowed())
                .map(|parent| Active {
                    span: parent.span.start_child(op, name).into(),
                    session: parent.session,
                });
        }
        let session = state().lock().ok()?.session.clone()?;
        if session.gate.revoked.is_cancelled() {
            return None;
        }
        let parent = PARENT
            .try_with(|parent| parent.borrow_mut().take())
            .ok()
            .flatten();
        let mut context = if let Some(parent) = parent.as_deref() {
            TransactionContext::continue_from_headers(name, op, [("sentry-trace", parent)])
        } else {
            TransactionContext::new(name, op)
        };
        let sampled = context
            .sampled()
            .unwrap_or_else(|| rand::random::<f64>() < SAMPLE_RATE);
        if !sampled || !session.gate.allowed() {
            return None;
        }
        context.set_sampled(true);
        let hub = Hub::new(Some(session.client.clone()), Arc::new(Scope::default()));
        let transaction = hub.start_transaction(context);
        transaction.set_tag("component", "rust");
        transaction.set_tag("platform", std::env::consts::OS);
        transaction.set_tag(
            "execution",
            match crate::log::current_log_source() {
                crate::log::LogSource::Foreground => "foreground",
                crate::log::LogSource::Notification => "notification",
                crate::log::LogSource::ForegroundService => "foreground_service",
                crate::log::LogSource::Background => "background",
            },
        );
        Some(Active {
            session,
            span: transaction.into(),
        })
    }

    pub(crate) fn child(&self, name: &str, op: &str) -> Self {
        let active = self
            .active
            .as_ref()
            .filter(|active| active.session.gate.allowed())
            .map(|parent| Active {
                session: parent.session.clone(),
                span: parent.span.start_child(op, name).into(),
            });
        Self {
            active,
            status: SpanStatus::Cancelled,
        }
    }

    pub(crate) async fn scope<T>(&self, future: impl Future<Output = T>) -> T {
        CURRENT.scope(self.active.clone(), future).await
    }

    pub(crate) fn boolean(&self, name: &'static str, value: bool) {
        if let Some(active) = self
            .active
            .as_ref()
            .filter(|active| active.session.gate.allowed())
        {
            active.span.set_data(name, value.into());
        }
    }

    pub(crate) fn status(&mut self, success: bool) {
        self.status = if success {
            SpanStatus::Ok
        } else {
            SpanStatus::InternalError
        };
    }
}

impl Drop for Trace {
    fn drop(&mut self) {
        if let Some(active) = self
            .active
            .take()
            .filter(|active| active.session.gate.allowed())
        {
            active.span.set_status(self.status);
            // Finish on an empty scope; never inherit unrelated log/user data.
            Hub::run(
                Arc::new(Hub::new(
                    Some(active.session.client.clone()),
                    Arc::new(Scope::default()),
                )),
                || active.span.finish(),
            );
        }
    }
}

pub(crate) fn count(name: &'static str, value: usize) {
    let _ = CURRENT.try_with(|active| {
        if let Some(active) = active
            .as_ref()
            .filter(|active| active.session.gate.allowed())
        {
            active.span.set_data(name, value.into());
        }
    });
}

pub(crate) async fn measure<T>(
    name: &str, op: &str, future: impl Future<Output = Result<T>>,
) -> Result<T> {
    let mut trace = Trace::start(name, op);
    let result = trace.scope(future).await;
    trace.status(result.is_ok());
    result
}

pub(crate) async fn rows<T>(
    name: &str, future: impl Future<Output = Result<Vec<T>>>,
) -> Result<Vec<T>> {
    measure(name, "db.sql.query", async {
        let rows = future.await?;
        count("db.rows", rows.len());
        Ok(rows)
    })
    .await
}

pub(crate) async fn acquire(
    pool: &sqlx::SqlitePool,
) -> Result<sqlx::pool::PoolConnection<sqlx::Sqlite>> {
    measure("sqlite.read_pool.acquire", "db.connection", async {
        Ok(pool.acquire().await?)
    })
    .await
}
