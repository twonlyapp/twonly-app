/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! Stable synchronous entry points for the platform's background schedulers.
//!
//! `WorkManager` and `BGTaskScheduler` may start the process with no Flutter
//! engine in it, so these mirror the notification ABI in
//! [`crate::native::notifications`]: they own their Tokio runtime and take the
//! storage directories rather than assuming an initialized context.

use crate::bridge::InitConfig;
use crate::context::Context;
use crate::database::lifecycle::{Lease, Operation};
use crate::services::background::{self, Job, RunOutcome};
use futures_util::FutureExt;
use std::collections::{HashMap, HashSet};
use std::ffi::{c_char, CStr, CString};
use std::panic::{catch_unwind, AssertUnwindSafe};
use std::sync::{LazyLock, Mutex, MutexGuard};
use std::time::Duration;

/// One maintenance run at a time per process. Two concurrent runs would only
/// contend on the same per-media locks and the same socket.

static MAINTENANCE_WORKER: LazyLock<Mutex<()>> = LazyLock::new(|| Mutex::new(()));

static PENDING_RUNS: LazyLock<Mutex<HashMap<u64, Lease>>> =
    LazyLock::new(|| Mutex::new(HashMap::new()));

static BACKUP_RUNS: LazyLock<Mutex<HashSet<u64>>> = LazyLock::new(|| Mutex::new(HashSet::new()));

/// Flush runs: deferred media maintenance that a push may preempt. A run that
/// prepares a send is never listed, so a wake-up cannot delay the user's send.
pub(crate) static MAINTENANCE_RUNS: LazyLock<Mutex<HashSet<u64>>> =
    LazyLock::new(|| Mutex::new(HashSet::new()));

/// Optional exports yield their database admission to message delivery.
pub(crate) fn cancel_backup_runs() {
    for id in BACKUP_RUNS.lock().unwrap().iter().copied() {
        crate::database::lifecycle::twonly_database_operation_cancel(id);
    }
}

/// A push takes priority over optional exports and media maintenance. Their
/// supervisors still finish rollback and pool cleanup before releasing
/// admission.
pub(crate) fn cancel_maintenance_runs() {
    cancel_backup_runs();

    for id in MAINTENANCE_RUNS.lock().unwrap().iter().copied() {
        crate::database::lifecycle::twonly_database_operation_cancel(id);
    }
}

// Debug media preparation has a deep async poll chain that exceeds Android's
// WorkManager thread stack. Runtime::block_on polls its root future on the
// calling thread, even with a multithreaded runtime.
const MAINTENANCE_STACK_SIZE: usize = 8 * 1024 * 1024;

fn run_on_worker_stack<T: Send + 'static>(
    work: impl FnOnce() -> Result<T, String> + Send + 'static,
) -> Result<T, String> {
    std::thread::Builder::new()
        .name("twonly-maintenance".into())
        .stack_size(MAINTENANCE_STACK_SIZE)
        .spawn(work)
        .map_err(|error| format!("could not start maintenance thread: {error}"))?
        .join()
        .map_err(|_| "background maintenance panicked".to_owned())?
}

/// A native HTTP callback is only a hint to check the server's attachment
/// state. It must not mark a 202 response as sent or initialize a runtime when
/// Flutter is absent; durable maintenance handles that case later.
#[unsafe(no_mangle)]

pub extern "C" fn twonly_direct_media_transfer_finished() -> bool {
    catch_unwind(AssertUnwindSafe(|| {
        let Ok(ctx) = Context::get_static() else {
            return false;
        };

        if ctx.foreground_runtime().is_none() {
            return false;
        }

        crate::services::direct_media_upload::watch_pending_uploads(ctx);

        true
    }))
    .unwrap_or(false)
}

fn worker_lock(operation: &Operation) -> Result<MutexGuard<'static, ()>, String> {
    loop {
        operation.check().map_err(|error| error.to_string())?;

        match MAINTENANCE_WORKER.try_lock() {
            Ok(guard) => return Ok(guard),
            Err(std::sync::TryLockError::Poisoned(error)) => return Ok(error.into_inner()),
            Err(std::sync::TryLockError::WouldBlock) => {
                std::thread::sleep(Duration::from_millis(5))
            }
        }
    }
}

fn runtime() -> Result<tokio::runtime::Runtime, String> {
    tokio::runtime::Builder::new_multi_thread()
        .worker_threads(2)
        .enable_all()
        .build()
        .map_err(|error| format!("could not create maintenance runtime: {error}"))
}

unsafe fn required_string(pointer: *const c_char, name: &str) -> Result<String, String> {
    if pointer.is_null() {
        return Err(format!("{name} is null"));
    }

    // SAFETY: Native callers promise a valid NUL-terminated string for the
    // duration of this synchronous function call.
    unsafe { CStr::from_ptr(pointer) }
        .to_str()
        .map(str::to_owned)
        .map_err(|error| format!("{name} is not UTF-8: {error}"))
}

unsafe fn optional_string(pointer: *const c_char) -> Option<String> {
    if pointer.is_null() {
        return None;
    }

    unsafe { CStr::from_ptr(pointer) }
        .to_str()
        .ok()
        .map(str::to_owned)
        .filter(|value| !value.is_empty())
}

fn response_json(outcome: Option<RunOutcome>, error: Option<String>) -> *mut c_char {
    let json = match (outcome, error) {
        (Some(outcome), None) => format!(
            r#"{{"ok":true,"pending_uploads":{},"pending_messages":{}}}"#,
            outcome.pending_uploads, outcome.pending_messages
        ),
        (_, Some(error)) => format!(
            r#"{{"ok":false,"error":{}}}"#,
            serde_json::to_string(&error).unwrap_or_else(|_| "null".into())
        ),
        (None, None) => r#"{"ok":false,"error":"missing background outcome"}"#.to_owned(),
    };

    CString::new(json)
        .expect("JSON serializers must escape interior NUL bytes")
        .into_raw()
}

/// Runs one maintenance job and returns a JSON `{"ok":bool,"error":string?}`.
///
/// A null or empty `media_id` runs the full flush; otherwise only that media
/// file is prepared. The returned pointer must be released with
/// `twonly_background_string_free`.
#[unsafe(no_mangle)]

pub unsafe extern "C" fn twonly_background_run(
    database_dir: *const c_char, data_dir: *const c_char, media_id: *const c_char,
) -> *mut c_char {
    let id = twonly_background_run_create();

    unsafe { twonly_background_run_with_id(id, database_dir, data_dir, media_id) }
}

/// Register before enqueueing the OS worker so an early expiration is retained.
#[unsafe(no_mangle)]

pub extern "C" fn twonly_background_run_create() -> u64 {
    create_run(crate::log::LogSource::Background)
}

fn create_run(source: crate::log::LogSource) -> u64 {
    let budget = if cfg!(target_os = "ios") { 20 } else { 120 };

    create_run_with_budget(source, budget)
}

fn create_run_with_budget(source: crate::log::LogSource, budget: u64) -> u64 {
    let lease = Lease::external(Operation::with_log_source(
        Duration::from_secs(budget),
        source,
    ));

    let id = lease.id();

    PENDING_RUNS
        .lock()
        .unwrap_or_else(|error| error.into_inner())
        .insert(id, lease);

    id
}

/// Release a registered run that never reached its worker (for example when
/// the App Group directory is unavailable). It cannot dispose an active run.
#[unsafe(no_mangle)]

pub extern "C" fn twonly_background_run_dispose(id: u64) {
    let pending = PENDING_RUNS
        .lock()
        .unwrap_or_else(|error| error.into_inner())
        .remove(&id);
    if pending.is_some() {
        BACKUP_RUNS.lock().unwrap().remove(&id);
    }
}

#[unsafe(no_mangle)]

pub unsafe extern "C" fn twonly_background_run_with_id(
    id: u64, database_dir: *const c_char, data_dir: *const c_char, media_id: *const c_char,
) -> *mut c_char {
    cancel_backup_runs();
    let job = match unsafe { optional_string(media_id) } {
        Some(media_id) => Job::PrepareMedia(media_id),
        None => Job::Flush,
    };
    let maintenance = matches!(job, Job::Flush);
    if maintenance {
        MAINTENANCE_RUNS.lock().unwrap().insert(id);
    }
    let response = unsafe { run_job_with_id(id, database_dir, data_dir, job) };
    if maintenance {
        MAINTENANCE_RUNS.lock().unwrap().remove(&id);
    }
    response
}

/// Backups have a processing grant, rather than the short message drain grant.
#[unsafe(no_mangle)]
pub extern "C" fn twonly_backup_run_create() -> u64 {
    let mut backups = BACKUP_RUNS.lock().unwrap();
    let budget = if cfg!(target_os = "ios") { 120 } else { 9 * 60 };
    let id = create_run_with_budget(crate::log::LogSource::Background, budget);
    backups.insert(id);
    id
}

#[unsafe(no_mangle)]
pub unsafe extern "C" fn twonly_backup_run_with_id(
    id: u64, database_dir: *const c_char, data_dir: *const c_char,
) -> *mut c_char {
    unsafe { run_job_with_id(id, database_dir, data_dir, Job::Backup) }
}

unsafe fn run_job_with_id(
    id: u64, database_dir: *const c_char, data_dir: *const c_char, job: Job,
) -> *mut c_char {
    let lease = PENDING_RUNS
        .lock()
        .unwrap_or_else(|error| error.into_inner())
        .remove(&id);

    let Some(lease) = lease else {
        return response_json(
            None,
            Some("background run is closed or already started".into()),
        );
    };

    let operation = lease.operation();

    let result = catch_unwind(AssertUnwindSafe(|| {
        let _worker = worker_lock(&operation)?;

        let database_dir = unsafe { required_string(database_dir, "database_dir") }?;

        let data_dir = unsafe { required_string(data_dir, "data_dir") }?;

        // Own the input strings before crossing threads. Join synchronously so
        // the worker lock and lease cover database cleanup and runtime shutdown.
        run_on_worker_stack(move || {
            runtime()?.block_on(operation.log_source().scope(async {
                let _admission = crate::database::lifecycle::native_admission(&operation)
                    .await.map_err(|error| error.to_string())?;
                // Initialization is owned and awaited: abandoning a partially
                // opened SQLCipher connection does not prove its locks are gone.
                let initialized = AssertUnwindSafe(operation.scope(async {
                    operation.check()?;
                    Context::init_notification(InitConfig { database_dir, data_dir }).await
                })).catch_unwind().await;
                let context = Context::get_static().ok().cloned();
                let result = match initialized {
                    Ok(Ok(())) => {
                        let ctx = context.as_ref().unwrap().clone();
                        AssertUnwindSafe(operation.scope(async {
                            tokio::select! {
                                biased;
                                _ = operation.until_cancelled() => operation.check().map(|_| unreachable!()),
                                result = background::run(ctx, job) => result,
                            }
                        })).catch_unwind().await
                    }
                    Ok(Err(error)) => Ok(Err(error)),
                    Err(panic) => Err(panic),
                };
                operation.cancel();
                tracing::info!(operation_id = id, "background database cleanup started");
                let cleanup = if let Some(context) = context {
                    context.finish_native_databases(&operation).await
                } else { Ok(()) };
                operation.drain().await;
                tracing::info!(operation_id = id, "background database cleanup finished");
                cleanup.map_err(|error| error.to_string())?;
                result.map_err(|_| "background maintenance panicked".to_owned())?
                    .map_err(|error| error.to_string())
            }))
        })
    }));

    // The lease remains registered through SQLx closure and runtime shutdown.
    drop(lease);
    BACKUP_RUNS.lock().unwrap().remove(&id);

    match result {
        Ok(Ok(outcome)) => response_json(Some(outcome), None),
        Ok(Err(error)) => response_json(None, Some(error)),
        Err(_) => response_json(None, Some("background maintenance panicked".into())),
    }
}

/// Releases a string returned by a Twonly background entry point.
#[unsafe(no_mangle)]

pub unsafe extern "C" fn twonly_background_string_free(pointer: *mut c_char) {
    if !pointer.is_null() {
        // SAFETY: The pointer was allocated by `CString::into_raw` above and
        // ownership is transferred back exactly once by the native caller.
        drop(unsafe { CString::from_raw(pointer) });
    }
}

#[cfg(test)]

mod lifecycle_tests {

    use super::*;

    #[test]
    fn delivery_cancels_backup_admission_without_cancelling_message_work() {
        let backup = twonly_backup_run_create();
        let message = twonly_background_run_create();
        cancel_backup_runs();
        assert!(!PENDING_RUNS
            .lock()
            .unwrap()
            .get(&message)
            .unwrap()
            .operation()
            .cancelled());
        let directory = tempfile::tempdir().unwrap();
        let missing = directory.path().join("must-not-be-created");
        let path = CString::new(missing.to_str().unwrap()).unwrap();
        let response = unsafe {
            read_response(twonly_backup_run_with_id(
                backup,
                path.as_ptr(),
                path.as_ptr(),
            ))
        };
        assert_eq!(response["ok"], false);
        assert!(response["error"].as_str().unwrap().contains("cancelled"));
        assert!(!missing.exists());
        twonly_background_run_dispose(message);
    }

    #[inline(never)]
    fn use_large_stack() -> u8 {
        let mut buffer = [0_u8; 2 * 1024 * 1024];
        std::hint::black_box(&mut buffer);
        buffer[0] = 42;
        std::hint::black_box(&buffer);
        buffer[0]
    }

    #[test]
    fn maintenance_root_future_has_its_own_stack_and_finishes_before_returning() {
        std::thread::Builder::new()
            .stack_size(128 * 1024)
            .spawn(|| {
                let caller = std::thread::current().id();
                let completed = std::sync::Arc::new(std::sync::atomic::AtomicBool::new(false));
                let worker_completed = completed.clone();
                let result = run_on_worker_stack(move || {
                    assert_ne!(std::thread::current().id(), caller);
                    let result = runtime()?.block_on(async { use_large_stack() });
                    worker_completed.store(true, std::sync::atomic::Ordering::SeqCst);
                    Ok(result)
                });

                assert_eq!(result.unwrap(), 42);
                assert!(completed.load(std::sync::atomic::Ordering::SeqCst));
            })
            .unwrap()
            .join()
            .unwrap();
    }

    #[test]
    fn maintenance_thread_errors_and_panics_are_reported() {
        let error = run_on_worker_stack(|| Err::<(), _>("maintenance failed".to_owned()));
        assert_eq!(error.unwrap_err(), "maintenance failed");

        let panic = run_on_worker_stack::<()>(|| panic!("maintenance test panic"));
        assert_eq!(panic.unwrap_err(), "background maintenance panicked");
    }

    unsafe fn read_response(pointer: *mut c_char) -> serde_json::Value {
        let text = unsafe { CStr::from_ptr(pointer) }
            .to_str()
            .unwrap()
            .to_owned();

        unsafe { twonly_background_string_free(pointer) };

        serde_json::from_str(&text).unwrap()
    }

    #[test]

    fn expiration_before_worker_start_never_opens_the_database() {
        let directory = tempfile::tempdir().unwrap();

        let missing = directory.path().join("must-not-be-created");

        let path = CString::new(missing.to_str().unwrap()).unwrap();

        let id = twonly_background_run_create();

        crate::database::lifecycle::twonly_database_operation_cancel(id);

        let response = unsafe {
            read_response(twonly_background_run_with_id(
                id,
                path.as_ptr(),
                path.as_ptr(),
                std::ptr::null(),
            ))
        };

        assert_eq!(response["ok"], false);

        assert!(response["error"].as_str().unwrap().contains("cancelled"));

        assert!(!missing.exists());
    }

    #[test]

    fn disposed_and_duplicate_worker_ids_cannot_run_or_cancel_a_later_worker() {
        let old = twonly_background_run_create();

        twonly_background_run_dispose(old);

        let current = twonly_background_run_create();

        crate::database::lifecycle::twonly_database_operation_cancel(old);

        assert!(!PENDING_RUNS
            .lock()
            .unwrap()
            .get(&current)
            .unwrap()
            .operation()
            .cancelled());

        let response = unsafe {
            read_response(twonly_background_run_with_id(
                old,
                std::ptr::null(),
                std::ptr::null(),
                std::ptr::null(),
            ))
        };

        assert_eq!(response["ok"], false);

        twonly_background_run_dispose(current);
    }
}

#[cfg(target_os = "android")]

mod android_jni {

    use super::*;
    use jni::objects::{JClass, JString};
    use jni::sys::{jboolean, jstring};
    use jni::{Env, EnvUnowned};

    #[unsafe(no_mangle)]
    pub extern "system" fn Java_eu_twonly_directmedia_NativeMediaTransferBridge_report(
        mut unowned_env: EnvUnowned<'_>, _class: JClass<'_>, directory: JString<'_>,
        attachment_id: JString<'_>, role: JString<'_>, queued_ms: jni::sys::jlong,
        worker_ms: jni::sys::jlong, http_ms: jni::sys::jlong, status: jni::sys::jint,
        attempt: jni::sys::jint,
    ) {
        unowned_env
            .with_env(|env| {
                let directory = directory.try_to_string(env)?;
                let attachment_id = attachment_id.try_to_string(env)?;
                let role = role.try_to_string(env)?;
                if Context::get_static().is_err() {
                    crate::log::init_tracing(
                        std::path::Path::new(&directory),
                        crate::log::LogSource::Background,
                    );
                }
                crate::log::LogSource::Background.scope_sync(|| {
                    tracing::info!(
                        %attachment_id, %role, queued_ms, worker_ms, http_ms, status, attempt,
                        "native direct-media transfer finished"
                    );
                });
                twonly_direct_media_transfer_finished();
                Ok::<_, jni::errors::Error>(())
            })
            .resolve::<jni::errors::LogErrorAndDefault>();
    }

    #[unsafe(no_mangle)]
    pub extern "system" fn Java_eu_twonly_backup_NativeBackupBridge_create(
        _env: EnvUnowned<'_>, _class: JClass<'_>,
    ) -> jni::sys::jlong {
        twonly_backup_run_create() as jni::sys::jlong
    }

    #[unsafe(no_mangle)]
    pub extern "system" fn Java_eu_twonly_backup_NativeBackupBridge_cancel(
        _env: EnvUnowned<'_>, _class: JClass<'_>, id: jni::sys::jlong,
    ) {
        crate::database::lifecycle::twonly_database_operation_cancel(id as u64);
    }

    #[unsafe(no_mangle)]
    pub extern "system" fn Java_eu_twonly_backup_NativeBackupBridge_run(
        mut unowned_env: EnvUnowned<'_>, _class: JClass<'_>, id: jni::sys::jlong,
        directory: JString<'_>,
    ) -> jstring {
        unowned_env
            .with_env(|env| {
                let directory = directory.try_to_string(env)?;
                let directory = CString::new(directory).expect("Android directory contains no NUL");
                let pointer = unsafe {
                    twonly_backup_run_with_id(id as u64, directory.as_ptr(), directory.as_ptr())
                };
                let json = unsafe { CStr::from_ptr(pointer) }
                    .to_string_lossy()
                    .into_owned();
                unsafe { twonly_background_string_free(pointer) };
                jni::objects::JString::from_str(env, json).map(JString::into_raw)
            })
            .resolve::<jni::errors::LogErrorAndDefault>()
    }

    #[unsafe(no_mangle)]
    pub extern "system" fn Java_eu_twonly_backup_NativeBackupBridge_dispose(
        _env: EnvUnowned<'_>, _class: JClass<'_>, id: jni::sys::jlong,
    ) {
        twonly_background_run_dispose(id as u64);
    }

    #[unsafe(no_mangle)]

    pub extern "system" fn Java_eu_twonly_directmedia_NativeMediaPrepareBridge_run(
        mut unowned_env: EnvUnowned<'_>, _class: JClass<'_>, database_dir: JString<'_>,
        data_dir: JString<'_>, media_id: JString<'_>, foreground_service: jboolean,
    ) -> jstring {
        unowned_env
            .with_env(|env| {
                Ok::<_, jni::errors::Error>({
                    let result = (|| -> Result<String, String> {
                        let java_string =
                            |env: &mut Env<'_>, value: JString<'_>| -> Result<String, String> {
                                value
                                    .try_to_string(env)
                                    .map_err(|error| format!("invalid Java string: {error}"))
                            };

                        let database_dir = CString::new(java_string(env, database_dir)?)
                            .map_err(|error| error.to_string())?;

                        let data_dir = CString::new(java_string(env, data_dir)?)
                            .map_err(|error| error.to_string())?;

                        // A null Java string is the flush job, so it is not required here.
                        let media_id = if media_id.is_null() {
                            None
                        } else {
                            Some(
                                CString::new(java_string(env, media_id)?)
                                    .map_err(|error| error.to_string())?,
                            )
                        };

                        let id = create_run(if foreground_service {
                            crate::log::LogSource::ForegroundService
                        } else {
                            crate::log::LogSource::Background
                        });

                        // SAFETY: Each CString remains alive for the synchronous ABI call.
                        let pointer = unsafe {
                            twonly_background_run_with_id(
                                id,
                                database_dir.as_ptr(),
                                data_dir.as_ptr(),
                                media_id
                                    .as_ref()
                                    .map_or(std::ptr::null(), |value| value.as_ptr()),
                            )
                        };

                        if pointer.is_null() {
                            return Err("Rust maintenance worker returned null".into());
                        }

                        // SAFETY: The C ABI returns a valid owned CString.
                        let json = unsafe { CStr::from_ptr(pointer) }
                            .to_string_lossy()
                            .into_owned();

                        unsafe { twonly_background_string_free(pointer) };

                        Ok(json)
                    })();

                    let json = result.unwrap_or_else(|error| {
                        format!(
                            r#"{{"ok":false,"error":{}}}"#,
                            serde_json::to_string(&error).unwrap_or_else(|_| "null".into())
                        )
                    });

                    jni::objects::JString::from_str(env, json)
                        .map(JString::into_raw)
                        .unwrap_or(std::ptr::null_mut())
                })
            })
            .resolve::<jni::errors::LogErrorAndDefault>()
    }
}
