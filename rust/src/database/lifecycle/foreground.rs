//! Each visible Flutter session owns its pools and async descendants. Its
//! supervisor survives Flutter suspension until rollback and closure finish.

use super::{foreground_admission, Lease, Operation};
use crate::bridge::InitConfig;
use crate::context::{Context, RuntimeMode};
use crate::error::{Result, TwonlyError};
use futures_util::FutureExt;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::{Arc, Mutex};
use tokio::sync::watch;

static ACTIVE: AtomicBool = AtomicBool::new(true);

static RESETTING: AtomicBool = AtomicBool::new(false);

static NATIVE_EVENTS: AtomicBool = AtomicBool::new(false);

static CHANGED: tokio::sync::Notify = tokio::sync::Notify::const_new();

static TRANSITION: tokio::sync::Mutex<()> = tokio::sync::Mutex::const_new(());

#[derive(Clone)]

enum Phase {
    Starting,
    Ready,
    Closed(std::result::Result<(), String>),
}

pub(crate) struct Epoch {
    operation: Operation,
    phase: watch::Sender<Phase>,
    retry: AtomicBool,
}

struct InitializingCaller(Option<Operation>);

impl Drop for InitializingCaller {
    fn drop(&mut self) {
        if let Some(operation) = &self.0 {
            operation.cancel();
        }
    }
}

#[derive(Default)]

pub(crate) struct Foreground {
    epoch: Mutex<Option<Arc<Epoch>>>,
}

impl Foreground {
    pub(crate) fn operation(&self) -> Option<Operation> {
        self.epoch
            .lock()
            .unwrap()
            .as_ref()
            .map(|epoch| epoch.operation.clone())
    }

    pub(crate) fn ready(&self) -> bool {
        self.ready_operation().is_some()
    }

    pub(crate) fn ready_operation(&self) -> Option<Operation> {
        self.epoch
            .lock()
            .unwrap()
            .as_ref()
            .filter(|epoch| {
                !epoch.operation.cancelled() && matches!(*epoch.phase.borrow(), Phase::Ready)
            })
            .map(|epoch| epoch.operation.clone())
    }

    fn epoch(&self) -> Option<Arc<Epoch>> {
        self.epoch.lock().unwrap().clone()
    }

    fn attach(&self, epoch: Arc<Epoch>) {
        *self.epoch.lock().unwrap() = Some(epoch);

        CHANGED.notify_waiters();
    }

    pub(crate) async fn wait_ready(&self) -> Result<()> {
        loop {
            let changed = CHANGED.notified();

            if let Some(epoch) = self.epoch() {
                if self.ready() {
                    return Ok(());
                }

                if let Phase::Closed(Err(error)) = epoch.phase.borrow().clone() {
                    return Err(TwonlyError::Generic(error));
                }
            }

            changed.await;
        }
    }

    pub(crate) async fn drained(&self) -> Result<()> {
        if let Some(epoch) = self.epoch() {
            epoch.closed().await?;
        }

        Ok(())
    }
}

impl Epoch {
    async fn ready(&self) -> Result<()> {
        let mut phase = self.phase.subscribe();

        loop {
            match phase.borrow_and_update().clone() {
                Phase::Ready => return self.operation.check(),
                Phase::Closed(result) => {
                    result.map_err(TwonlyError::Generic)?;

                    return Err(TwonlyError::Generic(
                        "Foreground initialization interrupted".into(),
                    ));
                }
                Phase::Starting => {}
            }

            phase
                .changed()
                .await
                .map_err(|_| TwonlyError::Initialization)?;
        }
    }

    async fn closed(&self) -> Result<()> {
        let mut phase = self.phase.subscribe();

        loop {
            if let Phase::Closed(result) = phase.borrow_and_update().clone() {
                return result.map_err(TwonlyError::Generic);
            }

            phase
                .changed()
                .await
                .map_err(|_| TwonlyError::Initialization)?;
        }
    }
}

pub(crate) fn active() -> bool {
    ACTIVE.load(Ordering::Acquire)
}

pub(crate) async fn until_background() {
    loop {
        let changed = CHANGED.notified();

        if !active() {
            return;
        }

        changed.await;
    }
}

pub(crate) fn visibility(active: bool) {
    let active = active && !RESETTING.load(Ordering::Acquire);

    ACTIVE.store(active, Ordering::Release);

    CHANGED.notify_waiters();

    if !active {
        super::cancel_foreground();

        super::cancel_native();

        if let Ok(context) = Context::get_static() {
            context.request_foreground_suspend();
        }
    }
}

/// Lib tests share one process. `visibility(false)` cancels every native
/// operation in it, including other tests' admissions running in parallel.
#[cfg(test)]
pub(crate) fn set_active_for_test(active: bool) {
    ACTIVE.store(active, Ordering::Release);

    CHANGED.notify_waiters();
}

async fn visible() -> Result<()> {
    loop {
        let changed = CHANGED.notified();

        if RESETTING.load(Ordering::Acquire) {
            return Err(TwonlyError::Generic(
                "Restart required after local data reset".into(),
            ));
        }

        #[cfg(target_os = "ios")]
        let active = crate::native::background_execution::active()?;

        #[cfg(not(target_os = "ios"))]
        let active = active();

        if active {
            ACTIVE.store(true, Ordering::Release);

            return Ok(());
        }

        tokio::select! { _ = changed => {}, _ = tokio::time::sleep(std::time::Duration::from_millis(100)) => {} }
    }
}

/// A reset abandons this process's identity. Lifecycle callbacks must not
/// reopen its pools or write its credentials again before the app restarts.
pub(crate) async fn stop_for_reset() {
    RESETTING.store(true, Ordering::Release);

    visibility(false);

    let _transition = TRANSITION.lock().await;

    // Initialization may have admitted an epoch just after the first cancel.
    // Holding TRANSITION now ensures this cancellation cannot miss its owner.
    visibility(false);

    if let Ok(context) = Context::get_static() {
        // A failed startup can leave a Closed(Err) epoch. Waiting still drains
        // its handles; its original initialization error must not block reset.
        if let Err(error) = context.foreground.drained().await {
            tracing::warn!(%error, "foreground closed with an error before reset");
        }
    }

    super::stop_native_for_reset().await;
}

/// Startup and resume use the same serialized owner. The owned task finishes
/// connection setup even if UIKit cancels midway through initialization.
pub(crate) async fn activate(config: InitConfig) -> Result<()> {
    let _transition = TRANSITION.lock().await;

    loop {
        visible().await?;

        if let Ok(context) = Context::get_static() {
            if context.foreground.ready() {
                return Ok(());
            }

            if let Some(previous) = context.foreground.epoch() {
                previous.operation.cancel();

                previous.closed().await?;
            }
        }

        let operation = Operation::foreground();

        let lease = match Lease::admit(operation.clone()) {
            Ok(lease) => lease,
            Err(error) => {
                #[cfg(target_os = "ios")]
                if !crate::native::background_execution::active()? {
                    continue;
                }

                return Err(error);
            }
        };

        let (phase, _) = watch::channel(Phase::Starting);

        let epoch = Arc::new(Epoch {
            operation,
            phase,
            retry: AtomicBool::new(false),
        });

        let mut caller = InitializingCaller(Some(epoch.operation.clone()));

        if let Ok(context) = Context::get_static() {
            context.foreground.attach(epoch.clone());
        }

        // Waiting for the previous epoch can take seconds, and a background
        // transition meanwhile had nothing registered to cancel. This epoch
        // would then stay open in the background, and every push wake-up and
        // Flutter pause would wait for a close that never comes. The OPERATIONS
        // lock orders this check against visibility(false)'s cancellation.
        if !active() {
            epoch.operation.cancel();
        }

        let owned = epoch.clone();

        let configuration = InitConfig {
            database_dir: config.database_dir.clone(),
            data_dir: config.data_dir.clone(),
        };

        // The owner is never an abortable descendant of the preceding epoch.
        tokio::spawn(async move {
            let mut admission = Some(foreground_admission(&owned.operation).await);

            let initialized = if admission.as_ref().unwrap().is_ok() {
                std::panic::AssertUnwindSafe(
                    owned
                        .operation
                        .scope(Context::init_common(configuration, RuntimeMode::Flutter)),
                )
                .catch_unwind()
                .await
                .map_err(|_| TwonlyError::Generic("Foreground initialization panicked".into()))
                .and_then(|result| result)
            } else {
                Err(TwonlyError::Generic(
                    "Foreground admission cancelled".into(),
                ))
            };

            let context = Context::get_static().ok().cloned();

            if let Some(context) = &context {
                context.foreground.attach(owned.clone());
            }

            // Only initialization/adoption needs native admission. Foreground
            // and scoped native callbacks may use the open pools concurrently.
            if initialized.is_ok() && !owned.operation.cancelled() {
                drop(admission.take());

                owned.phase.send_replace(Phase::Ready);

                CHANGED.notify_waiters();

                if let Some(context) = &context {
                    context.app_db.read().await.refresh_watches();

                    owned.operation.scope_sync(|| {
                        crate::services::background::schedule_foreground_maintenance(context);
                    });
                }

                owned.operation.until_cancelled().await;
            }

            let interrupted = owned.operation.cancelled();

            owned.retry.store(interrupted, Ordering::Release);

            owned.operation.cancel();

            let cleanup = if let Some(context) = context {
                context.finish_foreground_databases(&owned.operation).await
            } else {
                Ok(())
            };

            owned.operation.drain().await;

            drop(lease);

            drop(admission);

            let result = if interrupted {
                cleanup
            } else {
                initialized.and(cleanup)
            }
            .map_err(|error| error.to_string());

            owned.phase.send_replace(Phase::Closed(result));

            CHANGED.notify_waiters();
        });

        let result = epoch.ready().await;

        if result.is_ok() {
            caller.0 = None;

            return result;
        }

        epoch.closed().await?;

        if !epoch.retry.load(Ordering::Acquire) {
            return result;
        }
    }
}

/// UIKit/Android lifecycle callbacks return immediately. Cleanup runs on the
/// saved Flutter runtime, even while the Flutter isolate itself is suspended.
#[unsafe(no_mangle)]
pub extern "C" fn twonly_database_set_foreground(active: bool) {
    NATIVE_EVENTS.store(true, Ordering::Release);

    visibility(active);

    if active {
        if let Ok(context) = Context::get_static() {
            if let Some(runtime) = context.saved_foreground_runtime() {
                let context = context.clone();

                runtime.spawn(async move {
                    let config = InitConfig {
                        database_dir: context.config.database_dir.clone(),
                        data_dir: context.config.data_dir.clone(),
                    };

                    if let Err(error) = activate(config).await {
                        tracing::error!(%error, "foreground database resume failed");
                    }
                });
            }
        }
    }
}

pub(crate) fn flutter_visibility(active: bool) {
    // Native callbacks are authoritative once installed. A queued Flutter
    // pause/resume must not reverse a more recent native lifecycle event.
    // Replaying an identical pause would also cancel a notification worker
    // that started after native onStop. Native visibility already did the work.
    if !NATIVE_EVENTS.load(Ordering::Acquire) {
        visibility(active);
    }
}
