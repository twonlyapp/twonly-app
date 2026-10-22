//! A push owns one bounded run across process, render, acknowledge and
//! finalize. The supervisor survives its callers and closes native resources on
//! deadline, including when the platform never calls finalize.

use crate::database::lifecycle::{native_admission, Lease, Operation};
use crate::error::{Result, TwonlyError};
use futures_util::FutureExt;
use std::collections::HashMap;
use std::future::Future;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, LazyLock, Mutex};
use std::time::Duration;
use tokio::sync::{watch, Mutex as AsyncMutex};

static SESSIONS: LazyLock<Mutex<HashMap<u64, Arc<Session>>>> =
    LazyLock::new(|| Mutex::new(HashMap::new()));

#[derive(Clone)]

enum Phase {
    Queued,
    Ready,
    Draining,
    Closed(std::result::Result<(), String>),
}

pub(super) struct Session {
    pub(super) id: u64,
    operation: Operation,
    serial: AsyncMutex<()>,
    phase: watch::Sender<Phase>,
    initialized: AtomicBool,
}

fn failure(message: impl Into<String>) -> TwonlyError {
    TwonlyError::Generic(message.into())
}

impl Session {
    pub(super) fn start(budget: Duration) -> std::result::Result<Arc<Self>, String> {
        Self::start_with_source(budget, crate::log::LogSource::Notification)
    }

    pub(super) fn start_with_source(
        budget: Duration, source: crate::log::LogSource,
    ) -> std::result::Result<Arc<Self>, String> {
        let runtime = super::runtime()?;

        Ok(Self::start_on(
            runtime.handle(),
            budget,
            source,
            |operation| async move {
                if let Ok(context) = crate::context::Context::get_static() {
                    context.finish_native_databases(&operation).await?;
                }

                Ok(())
            },
        ))
    }

    fn start_on<F, W>(
        runtime: &tokio::runtime::Handle, budget: Duration, source: crate::log::LogSource,
        cleanup: F,
    ) -> Arc<Self>
    where
        F: FnOnce(Operation) -> W + Send + 'static,
        W: Future<Output = Result<()>> + Send + 'static,
    {
        let operation = Operation::with_log_source(budget, source);

        let lease = Lease::external(operation.clone());

        let (phase, _) = watch::channel(Phase::Queued);

        let session = Arc::new(Self {
            id: lease.id(),
            operation,
            serial: AsyncMutex::new(()),
            phase,
            initialized: AtomicBool::new(false),
        });

        SESSIONS
            .lock()
            .unwrap_or_else(|error| error.into_inner())
            .insert(session.id, session.clone());

        let owned = session.clone();

        // This owner must not inherit the operation's abortable child scope.
        runtime.spawn(async move {
            source
                .scope(async move {
                    let admission = native_admission(&owned.operation).await;

                    if admission.is_ok() {
                        owned.phase.send_replace(Phase::Ready);

                        owned.operation.until_cancelled().await;
                    }

                    owned.operation.cancel();

                    owned.phase.send_replace(Phase::Draining);

                    let _serial = owned.serial.lock().await;

                    tracing::info!(
                        operation_id = owned.id,
                        "notification database cleanup started"
                    );

                    let result = std::panic::AssertUnwindSafe(cleanup(owned.operation.clone()))
                        .catch_unwind()
                        .await
                        .map_err(|_| failure("Notification cleanup panicked"))
                        .and_then(|result| result);

                    owned.operation.drain().await;

                    tracing::info!(
                        operation_id = owned.id,
                        "notification database cleanup finished"
                    );

                    let result = admission
                        .map(|_| ())
                        .and(result)
                        .map_err(|error| error.to_string());

                    // A completion acknowledgement observes the permit and lease gone.
                    drop(_serial);

                    drop(lease);

                    owned.phase.send_replace(Phase::Closed(result));

                    SESSIONS
                        .lock()
                        .unwrap_or_else(|error| error.into_inner())
                        .remove(&owned.id);
                })
                .await
        });

        session
    }

    pub(super) fn find(id: u64) -> Result<Arc<Self>> {
        SESSIONS
            .lock()
            .unwrap_or_else(|error| error.into_inner())
            .get(&id)
            .cloned()
            .ok_or_else(|| failure("Notification run is closed or unknown"))
    }

    pub(super) fn mark_initialized(&self) {
        self.initialized.store(true, Ordering::Release);
    }

    pub(super) fn is_initialized(&self) -> bool {
        self.initialized.load(Ordering::Acquire)
    }

    async fn ready(&self) -> Result<()> {
        let mut phase = self.phase.subscribe();

        loop {
            match phase.borrow_and_update().clone() {
                Phase::Ready => return self.operation.check(),
                Phase::Closed(_) | Phase::Draining => {
                    return Err(failure("Notification run is closing"))
                }
                Phase::Queued => {}
            }

            tokio::select! {
                biased;
                _ = self.operation.until_cancelled() => return self.operation.check(),
                result = phase.changed() => result.map_err(|_| failure("Notification supervisor stopped"))?,
            }
        }
    }

    /// Connection setup/migrations must finish their native work before the
    /// phase is unlocked. Ordinary work may be dropped on cancellation: native
    /// connection tickets then keep cleanup owned until SQLite really stops.

    pub(super) async fn execute<T>(
        &self, work: impl Future<Output = Result<T>>, interrupt: bool,
    ) -> Result<T> {
        let result = async {
            self.ready().await?;
            let _serial = tokio::select! {
                biased;
                _ = self.operation.until_cancelled() => return Err(failure("Notification run cancelled")),
                serial = self.serial.lock() => serial,
            };
            self.operation.check()?;
            let work = std::panic::AssertUnwindSafe(self.operation.scope(work)).catch_unwind();
            let result = if interrupt {
                tokio::select! {
                    biased;
                    _ = self.operation.until_cancelled() => return Err(failure("Notification run cancelled")),
                    result = work => result,
                }
            } else { work.await };
            result.map_err(|_| failure("Notification worker panicked"))?
        }.await;

        if result.is_err() {
            self.finish().await?;
        }

        result
    }

    pub(super) async fn finish(&self) -> Result<()> {
        self.operation.cancel();

        let mut phase = self.phase.subscribe();

        loop {
            if let Phase::Closed(result) = phase.borrow_and_update().clone() {
                return result.map_err(failure);
            }

            phase
                .changed()
                .await
                .map_err(|_| failure("Notification supervisor stopped"))?;
        }
    }
}

#[cfg(test)]
mod tests;
