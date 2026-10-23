//! An admitted operation owns its native execution and cleanup, even when its
//! caller disappears. Cancellation never stands in for worker completion.

use crate::error::{Result, TwonlyError};
use futures_util::FutureExt;
use std::collections::HashMap;
use std::future::Future;
use std::sync::atomic::{AtomicU64, AtomicUsize, Ordering};
use std::sync::{Arc, LazyLock, Mutex, Weak};
use std::time::{Duration, Instant};
use tokio_util::sync::CancellationToken;

pub(crate) mod foreground;
pub(crate) mod pool;

tokio::task_local! {
    static CURRENT: Operation;
}

static NEXT_ID: AtomicU64 = AtomicU64::new(1);

static NEXT_TASK: AtomicU64 = AtomicU64::new(1);

static NATIVE_RUNS: LazyLock<Arc<tokio::sync::Semaphore>> =
    LazyLock::new(|| Arc::new(tokio::sync::Semaphore::new(1)));

static OPERATIONS: LazyLock<Mutex<HashMap<u64, Weak<State>>>> =
    LazyLock::new(|| Mutex::new(HashMap::new()));

struct State {
    cancellation: CancellationToken,
    deadline: Option<Instant>,
    foreground: bool,
    log_source: crate::log::LogSource,
    native: std::sync::atomic::AtomicBool,
    connections: AtomicUsize,
    tasks: AtomicUsize,
    children: Mutex<HashMap<u64, tokio::task::AbortHandle>>,
    drained: tokio::sync::Notify,
}

#[derive(Clone)]

pub(crate) struct Operation(Arc<State>);

/// Native maintenance and the complete notification/render/finalize sequence
/// share one admission slot. A queued job retains its own deadline and can be
/// cancelled without adopting another job's pools or socket.

pub(crate) async fn native_admission(
    operation: &Operation,
) -> Result<tokio::sync::OwnedSemaphorePermit> {
    operation.0.native.store(true, Ordering::Release);

    tokio::select! {
        biased;
        _ = operation.until_cancelled() => Err(TwonlyError::Generic("Native database admission cancelled".into())),
        permit = NATIVE_RUNS.clone().acquire_owned() => {
            operation.check()?;
            permit.map_err(|_| TwonlyError::Generic("Native database admission closed".into()))
        }
    }
}

pub(crate) fn cancel_native() {
    let operations = OPERATIONS
        .lock()
        .unwrap()
        .values()
        .filter_map(Weak::upgrade)
        .filter(|state| state.native.load(Ordering::Acquire))
        .collect::<Vec<_>>();

    for state in operations {
        Operation(state).cancel();
    }
}

/// Wait for the admitted native job's cleanup, then keep this process from
/// starting another job while its identity and files are being removed.
pub(crate) async fn stop_native_for_reset() {
    cancel_native();

    if let Ok(_permit) = NATIVE_RUNS.clone().acquire_owned().await {
        NATIVE_RUNS.close();
    }
}

pub(crate) fn cancel_foreground() {
    let operations = OPERATIONS
        .lock()
        .unwrap()
        .values()
        .filter_map(Weak::upgrade)
        .filter(|state| state.foreground)
        .collect::<Vec<_>>();

    for state in operations {
        Operation(state).cancel();
    }
}

async fn foreground_admission(operation: &Operation) -> Result<tokio::sync::OwnedSemaphorePermit> {
    cancel_native();

    tokio::select! {
        biased;
        _ = operation.until_cancelled() => operation.check().map(|_| unreachable!()),
        permit = NATIVE_RUNS.clone().acquire_owned() => {
            operation.check()?;
            permit.map_err(|_| TwonlyError::Generic("Native database admission closed".into()))
        }
    }
}

impl Operation {
    pub(crate) fn new(budget: Duration) -> Self {
        Self::with_log_source(budget, crate::log::LogSource::Background)
    }

    pub(crate) fn with_log_source(budget: Duration, source: crate::log::LogSource) -> Self {
        Self::with_deadline(Some(Instant::now() + budget), source)
    }

    pub(crate) fn foreground() -> Self {
        Self::with_deadline(None, crate::log::LogSource::Foreground)
    }

    fn with_deadline(deadline: Option<Instant>, log_source: crate::log::LogSource) -> Self {
        Self(Arc::new(State {
            cancellation: CancellationToken::new(),
            deadline,
            foreground: log_source == crate::log::LogSource::Foreground,
            log_source,
            native: std::sync::atomic::AtomicBool::new(false),
            connections: AtomicUsize::new(0),
            tasks: AtomicUsize::new(0),
            children: Mutex::new(HashMap::new()),
            drained: tokio::sync::Notify::new(),
        }))
    }

    pub(crate) fn cancelled(&self) -> bool {
        self.0.cancellation.is_cancelled()
            || self
                .0
                .deadline
                .is_some_and(|deadline| Instant::now() >= deadline)
    }

    pub(crate) fn is_foreground(&self) -> bool {
        self.0.foreground
    }

    pub(crate) fn log_source(&self) -> crate::log::LogSource {
        self.0.log_source
    }

    pub(crate) fn same(&self, other: &Self) -> bool {
        Arc::ptr_eq(&self.0, &other.0)
    }

    pub(crate) fn check(&self) -> Result<()> {
        if self.cancelled() {
            Err(TwonlyError::Generic(
                "Database operation cancelled; retry when active".into(),
            ))
        } else {
            Ok(())
        }
    }

    pub(crate) async fn until_cancelled(&self) {
        let Some(deadline) = self.0.deadline else {
            self.0.cancellation.cancelled().await;

            return;
        };

        tokio::select! {
            _ = self.0.cancellation.cancelled() => {}
            _ = tokio::time::sleep_until(deadline.into()) => {}
        }
    }

    pub(crate) fn cancel(&self) {
        self.0.cancellation.cancel();

        let children = std::mem::take(
            &mut *self
                .0
                .children
                .lock()
                .unwrap_or_else(|error| error.into_inner()),
        );

        // Aborting drops futures on their executor. Tickets remain owned until
        // that has actually happened, and SQLite connections have their own
        // tickets until rollback/release/close completes.
        for child in children.into_values() {
            child.abort();
        }
    }

    pub(crate) fn current() -> Option<Self> {
        CURRENT.try_with(Clone::clone).ok()
    }

    pub(crate) fn inherited() -> Option<Self> {
        Self::current().or_else(|| {
            crate::context::Context::get_static()
                .ok()
                .and_then(|context| context.foreground.operation())
        })
    }

    pub(crate) fn scope_sync<T>(&self, work: impl FnOnce() -> T) -> T {
        CURRENT.sync_scope(self.clone(), work)
    }

    pub(crate) async fn scope<T>(&self, work: impl Future<Output = T>) -> T {
        CURRENT.scope(self.clone(), work).await
    }

    pub(crate) async fn drain(&self) {
        loop {
            let drained = self.0.drained.notified();

            if self.0.connections.load(Ordering::Acquire) == 0
                && self.0.tasks.load(Ordering::Acquire) == 0
            {
                return;
            }

            drained.await;
        }
    }
}

struct TaskTicket {
    operation: Operation,
    id: u64,
}

impl TaskTicket {
    fn new(operation: Operation) -> Self {
        operation.0.tasks.fetch_add(1, Ordering::AcqRel);

        Self {
            operation,
            id: NEXT_TASK.fetch_add(1, Ordering::Relaxed),
        }
    }
}

impl Drop for TaskTicket {
    fn drop(&mut self) {
        self.operation
            .0
            .children
            .lock()
            .unwrap_or_else(|error| error.into_inner())
            .remove(&self.id);

        if self.operation.0.tasks.fetch_sub(1, Ordering::AcqRel) == 1 {
            self.operation.0.drained.notify_waiters();
        }
    }
}

/// Tokio does not inherit task locals. Background descendants must retain the
/// original owner, including when they are sent to the foreground runtime.

pub(crate) fn spawn<W>(work: W) -> tokio::task::JoinHandle<W::Output>
where
    W: Future + Send + 'static,
    W::Output: Send + 'static,
{
    spawn_on(&tokio::runtime::Handle::current(), work)
}

pub(crate) fn spawn_on<W>(
    runtime: &tokio::runtime::Handle, work: W,
) -> tokio::task::JoinHandle<W::Output>
where
    W: Future + Send + 'static,
    W::Output: Send + 'static,
{
    let Some(operation) = Operation::inherited() else {
        return runtime.spawn(work);
    };

    let ticket = TaskTicket::new(operation.clone());

    let id = ticket.id;

    let (start, ready) = tokio::sync::oneshot::channel();

    let child_operation = operation.clone();

    let child = runtime.spawn(async move {
        let _ticket = ticket;

        // Registration precedes the first poll of application code, so a
        // concurrent expiration cannot miss a newly spawned descendant.
        let _ = ready.await;

        child_operation.scope(work).await
    });

    let mut children = operation
        .0
        .children
        .lock()
        .unwrap_or_else(|error| error.into_inner());

    if operation.cancelled() {
        drop(children);

        child.abort();
    } else {
        children.insert(id, child.abort_handle());

        drop(children);

        let _ = start.send(());
    }

    child
}

/// Running blocking work cannot be aborted by Tokio. Retain ownership until
/// the closure exits; SQLite and chunked archive work observe cancellation.

pub(crate) fn spawn_blocking<F, T>(work: F) -> tokio::task::JoinHandle<T>
where
    F: FnOnce() -> T + Send + 'static,
    T: Send + 'static,
{
    let Some(operation) = Operation::inherited() else {
        return tokio::task::spawn_blocking(work);
    };

    let ticket = TaskTicket::new(operation.clone());

    tokio::task::spawn_blocking(move || {
        let _ticket = ticket;

        CURRENT.sync_scope(operation, work)
    })
}

pub(crate) struct ConnectionTicket(Operation);

impl ConnectionTicket {
    pub(crate) fn new(operation: Operation) -> Self {
        operation.0.connections.fetch_add(1, Ordering::AcqRel);

        Self(operation)
    }
}

impl Drop for ConnectionTicket {
    fn drop(&mut self) {
        if self.0 .0.connections.fetch_sub(1, Ordering::AcqRel) == 1 {
            self.0 .0.drained.notify_waiters();
        }
    }
}

pub(crate) struct Lease {
    id: u64,
    platform: u64,
    started: Instant,
    _operation: Operation,
}

impl Lease {
    fn admit(operation: Operation) -> Result<Self> {
        let mut lease = Self::external(operation);

        #[cfg(target_os = "ios")]
        {
            lease.platform = crate::native::background_execution::begin(lease.id)?;
        }

        #[cfg(not(target_os = "ios"))]
        let _ = &mut lease;

        Ok(lease)
    }

    /// The OS scheduler already owns this execution allowance. Registration
    /// precedes queueing, so expiration before worker start is not lost.

    pub(crate) fn external(operation: Operation) -> Self {
        let id = NEXT_ID.fetch_add(1, Ordering::Relaxed);

        OPERATIONS
            .lock()
            .unwrap()
            .insert(id, Arc::downgrade(&operation.0));

        tracing::debug!(operation_id = id, "database operation registered");

        Self {
            id,
            platform: 0,
            started: Instant::now(),
            _operation: operation,
        }
    }

    pub(crate) fn id(&self) -> u64 {
        self.id
    }

    pub(crate) fn operation(&self) -> Operation {
        self._operation.clone()
    }
}

impl Drop for Lease {
    fn drop(&mut self) {
        OPERATIONS.lock().unwrap().remove(&self.id);

        tracing::info!(
            operation_id = self.id,
            elapsed_ms = self.started.elapsed().as_millis() as u64,
            connections = self._operation.0.connections.load(Ordering::Acquire),
            tasks = self._operation.0.tasks.load(Ordering::Acquire),
            "database operation lease released"
        );

        #[cfg(target_os = "ios")]
        if self.platform != 0 {
            crate::native::background_execution::end(self.platform);
        }

        #[cfg(not(target_os = "ios"))]
        let _ = self.platform;
    }
}

struct CancelOnDrop(Operation);

impl Drop for CancelOnDrop {
    fn drop(&mut self) {
        self.0.cancel();
    }
}

/// Only the owned task drops its lease, after `work` has awaited cleanup.

pub(crate) async fn run<T, F, W>(work: F) -> Result<T>
where
    T: Send + 'static,
    F: FnOnce(Operation) -> W + Send + 'static,
    W: Future<Output = Result<T>> + Send + 'static,
{
    run_with_budget(Duration::from_secs(120), work).await
}

pub(crate) async fn run_with_budget<T, F, W>(budget: Duration, work: F) -> Result<T>
where
    T: Send + 'static,
    F: FnOnce(Operation) -> W + Send + 'static,
    W: Future<Output = Result<T>> + Send + 'static,
{
    // A background transition cancels immediately on iOS. This independent
    // cap also bounds an export if the platform callback is unavailable.
    let operation = Operation::new(budget);

    let lease = Lease::admit(operation.clone())?;

    let caller = CancelOnDrop(operation.clone());

    let worker = tokio::spawn(async move {
        let _lease = lease;

        operation.check()?;

        let running = operation.clone();

        let result =
            std::panic::AssertUnwindSafe(operation.scope(async move { work(running).await }))
                .catch_unwind()
                .await;

        operation.cancel();

        operation.drain().await;

        result.map_err(|_| TwonlyError::Generic("Database operation panicked".into()))?
    });

    let result = worker.await.map_err(|error| {
        TwonlyError::Generic(format!("Database operation worker failed: {error}"))
    })?;

    drop(caller);

    result
}

/// Nonblocking C entry point; cancellation is observed by the owned worker.
#[unsafe(no_mangle)]

pub extern "C" fn twonly_database_operation_cancel(id: u64) {
    let state = OPERATIONS.lock().unwrap().get(&id).and_then(Weak::upgrade);

    if let Some(state) = state {
        tracing::info!(
            operation_id = id,
            "database operation cancellation requested"
        );

        Operation(state).cancel();
    }
}

#[cfg(test)]
mod tests;
