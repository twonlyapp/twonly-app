/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! Stable synchronous C entry points for native notification executables.
//! The ABI owns its Tokio runtime so neither Swift nor Kotlin needs Flutter or
//! flutter_rust_bridge to process a background wake-up.

use crate::bridge::InitConfig;
use crate::context::Context;
use crate::database::lifecycle::twonly_database_operation_cancel;
use crate::services::notifications::{self, NotificationBatch, NotificationPresentation};
use serde::Serialize;
use std::ffi::{c_char, CStr, CString};
use std::future::Future;
use std::panic::{catch_unwind, AssertUnwindSafe};
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::LazyLock;
use std::time::Duration;

mod session;

use session::Session;

static LEGACY_RUN: AtomicU64 = AtomicU64::new(0);

#[cfg(test)]
mod tests;

#[derive(Serialize)]

struct NativeNotificationResponse {
    ok: bool,
    widget_refresh: bool,
    batch: Option<NotificationBatch>,
    fallback: Option<NotificationPresentation>,
    error: Option<String>,
}

fn response_json(response: NativeNotificationResponse) -> *mut c_char {
    let json = serde_json::to_string(&response).unwrap_or_else(|error| {
        format!(
            r#"{{"ok":false,"batch":null,"fallback":null,"error":"serialization failed: {error}"}}"#
        )
    });

    CString::new(json)
        .expect("JSON serializers must escape interior NUL bytes")
        .into_raw()
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

fn log_push_received(data_dir: &str, message_id: &str, sent_at_ms: i64) {
    // Arrival must be durable before WorkManager queues the drain, even when
    // storage/credentials prevent Context initialization. Do not acquire the
    // worker lock: a previous push may still be waiting for its mailbox.
    let flutter_owns_process = Context::get_static().is_ok_and(|ctx| ctx.is_flutter_runtime());

    crate::log::init_tracing(
        std::path::Path::new(data_dir),
        if flutter_owns_process {
            crate::log::LogSource::Foreground
        } else {
            crate::log::LogSource::Notification
        },
    );

    crate::log::LogSource::Notification.scope_sync(|| {
        tracing::info!(
            platform = std::env::consts::OS,
            message_id,
            sent_at_ms = (sent_at_ms > 0).then_some(sent_at_ms),
            "native push received"
        )
    });
}

/// Records native push arrival in app.log without starting a worker or opening
/// the database. Only transport metadata belongs here, never the push payload.
#[unsafe(no_mangle)]

pub unsafe extern "C" fn twonly_notification_received(
    data_dir: *const c_char, message_id: *const c_char, sent_at_ms: i64,
) {
    let _ = catch_unwind(AssertUnwindSafe(|| {
        let Ok(data_dir) = (unsafe { required_string(data_dir, "data_dir") }) else {
            return;
        };

        let Ok(message_id) = (unsafe { required_string(message_id, "message_id") }) else {
            return;
        };

        log_push_received(&data_dir, &message_id, sent_at_ms);
    }));
}

/// One runtime for the whole worker process. `twonly_notification_process`
/// hands its batch back before the background socket is done with it, so the
/// tasks it spawned have to outlive that call — a per-call runtime would drop
/// them on the way out and leave `twonly_notification_finalize` with a dead
/// connection.

static NOTIFICATION_RUNTIME: LazyLock<Result<tokio::runtime::Runtime, String>> =
    LazyLock::new(|| {
        tokio::runtime::Builder::new_multi_thread()
            .worker_threads(2)
            .enable_all()
            .build()
            .map_err(|error| format!("could not create notification runtime: {error}"))
    });

pub(crate) fn runtime() -> Result<&'static tokio::runtime::Runtime, String> {
    NOTIFICATION_RUNTIME.as_ref().map_err(Clone::clone)
}

/// A native callback with no render/acknowledge phase uses the same admission,
/// cancellation and pool cleanup as a notification run.

pub(crate) fn native_job<T, F, W>(
    config: InitConfig, budget: Duration, source: crate::log::LogSource, work: F,
) -> Result<T, String>
where
    F: FnOnce(std::sync::Arc<Context>) -> W,
    W: Future<Output = crate::error::Result<T>>,
{
    let session = Session::start_with_source(budget, source)?;

    runtime()?
        .block_on(async {
            session
                .execute(Context::init_notification(config), false)
                .await?;

            let context = Context::get_static()?.clone();

            let result = session.execute(work(context), true).await;

            session.finish().await?;

            result
        })
        .map_err(|error| error.to_string())
}

/// Processes an opaque FCM/APNs wake-up and returns a JSON-encoded
/// `NativeNotificationResponse`. The returned pointer must be released with
/// `twonly_notification_string_free`.
#[unsafe(no_mangle)]

pub unsafe extern "C" fn twonly_notification_process(
    database_dir: *const c_char, data_dir: *const c_char, locale: *const c_char, deadline_ms: u64,
) -> *mut c_char {
    let id = twonly_notification_run_create(55_000);

    let old = LEGACY_RUN.swap(id, Ordering::AcqRel);

    twonly_database_operation_cancel(old);

    unsafe { twonly_notification_process_with_id(id, database_dir, data_dir, locale, deadline_ms) }
}

/// The budget covers queueing, initialization, rendering/acknowledgement and
/// finalization together. Register before dispatching to a platform queue.
#[unsafe(no_mangle)]

pub extern "C" fn twonly_notification_run_create(budget_ms: u64) -> u64 {
    crate::native::background::cancel_maintenance_runs();
    Session::start(Duration::from_millis(budget_ms.clamp(1, 120_000)))
        .map(|session| session.id)
        .unwrap_or(0)
}

#[unsafe(no_mangle)]

pub unsafe extern "C" fn twonly_notification_process_with_id(
    id: u64, database_dir: *const c_char, data_dir: *const c_char, locale: *const c_char,
    deadline_ms: u64,
) -> *mut c_char {
    let result = catch_unwind(AssertUnwindSafe(|| {
        let session = Session::find(id).map_err(|error| error.to_string())?;

        let database_dir = unsafe { required_string(database_dir, "database_dir") }?;

        let data_dir = unsafe { required_string(data_dir, "data_dir") }?;

        let locale = unsafe { required_string(locale, "locale") }?;

        let runtime = runtime()?;

        runtime
            .block_on(async {
                session
                    .execute(
                        Context::init_notification(InitConfig {
                            database_dir,
                            data_dir,
                        }),
                        false,
                    )
                    .await?;

                session.mark_initialized();

                let context = Context::get_static()?.clone();

                session
                    .execute(
                        notifications::process_initialized(&context, &locale, deadline_ms),
                        true,
                    )
                    .await
            })
            .map_err(|error| error.to_string())
    }));

    match result {
        Ok(Ok(batch)) => response_json(NativeNotificationResponse {
            ok: true,
            widget_refresh: true,
            batch: Some(batch),
            fallback: Some(notifications::fallback_presentation(
                &notifications::app_locale(
                    unsafe { required_string(locale, "locale") }
                        .as_deref()
                        .unwrap_or("en"),
                ),
            )),
            error: None,
        }),
        Ok(Err(error)) => response_json(NativeNotificationResponse {
            ok: false,
            widget_refresh: false,
            batch: None,
            fallback: Some(notifications::fallback_presentation(
                &notifications::app_locale(
                    unsafe { required_string(locale, "locale") }
                        .as_deref()
                        .unwrap_or("en"),
                ),
            )),
            error: Some(error),
        }),
        Err(_) => response_json(NativeNotificationResponse {
            ok: false,
            widget_refresh: false,
            batch: None,
            fallback: Some(notifications::fallback_presentation("en")),
            error: Some("notification worker panicked".into()),
        }),
    }
}

/// Settles the deferred wake-up work once the caller has rendered the batch:
/// media downloads, widget upkeep, and closing the background socket. Safe to
/// skip — an OS that reclaims the worker first only defers this to the next
/// wake-up or app launch.
#[unsafe(no_mangle)]

pub unsafe extern "C" fn twonly_notification_finalize(deadline_ms: u64) -> *mut c_char {
    unsafe { twonly_notification_finalize_with_id(LEGACY_RUN.load(Ordering::Acquire), deadline_ms) }
}

#[unsafe(no_mangle)]

pub unsafe extern "C" fn twonly_notification_finalize_with_id(
    id: u64, deadline_ms: u64,
) -> *mut c_char {
    let result = catch_unwind(AssertUnwindSafe(|| {
        let session = Session::find(id).map_err(|error| error.to_string())?;

        runtime()?
            .block_on(async {
                let result = if session.is_initialized() {
                    session
                        .execute(notifications::finalize_wakeup(deadline_ms), true)
                        .await
                } else {
                    Ok(())
                };

                session.finish().await?;

                result
            })
            .map_err(|error| error.to_string())
    }));

    let error = match result {
        Ok(Ok(())) => None,
        Ok(Err(error)) => Some(error),
        Err(_) => Some("notification finalization panicked".into()),
    };

    response_json(NativeNotificationResponse {
        ok: error.is_none(),
        widget_refresh: error.is_none(),
        batch: None,
        fallback: None,
        error,
    })
}

/// Marks successfully scheduled native events as delivered. `event_ids_json`
/// must be a JSON string array.
#[unsafe(no_mangle)]

pub unsafe extern "C" fn twonly_notification_acknowledge(
    event_ids_json: *const c_char,
) -> *mut c_char {
    unsafe {
        twonly_notification_acknowledge_with_id(LEGACY_RUN.load(Ordering::Acquire), event_ids_json)
    }
}

#[unsafe(no_mangle)]

pub unsafe extern "C" fn twonly_notification_acknowledge_with_id(
    id: u64, event_ids_json: *const c_char,
) -> *mut c_char {
    let result = catch_unwind(AssertUnwindSafe(|| {
        let session = Session::find(id).map_err(|error| error.to_string())?;

        let event_ids_json = unsafe { required_string(event_ids_json, "event_ids_json") }?;

        let event_ids: Vec<String> =
            serde_json::from_str(&event_ids_json).map_err(|error| error.to_string())?;

        if !session.is_initialized() {
            return Err("Notification run is not initialized".into());
        }

        let ctx = Context::get_static()
            .map_err(|error| error.to_string())?
            .clone();

        runtime()?
            .block_on(session.execute(notifications::acknowledge_batch(&ctx, &event_ids), true))
            .map_err(|error| error.to_string())
    }));

    match result {
        Ok(Ok(())) => response_json(NativeNotificationResponse {
            ok: true,
            widget_refresh: false,
            batch: None,
            fallback: None,
            error: None,
        }),
        Ok(Err(error)) => response_json(NativeNotificationResponse {
            ok: false,
            widget_refresh: false,
            batch: None,
            fallback: None,
            error: Some(error),
        }),
        Err(_) => response_json(NativeNotificationResponse {
            ok: false,
            widget_refresh: false,
            batch: None,
            fallback: None,
            error: Some("notification acknowledgement panicked".into()),
        }),
    }
}

/// Cancels and waits for actual cleanup without starting optional maintenance.
#[unsafe(no_mangle)]

pub extern "C" fn twonly_notification_run_finish(id: u64) {
    if let (Ok(session), Ok(runtime)) = (Session::find(id), runtime()) {
        let _ = runtime.block_on(session.finish());
    }
}

/// Releases a string returned by a Twonly notification C entry point.
#[unsafe(no_mangle)]

pub unsafe extern "C" fn twonly_notification_string_free(pointer: *mut c_char) {
    if !pointer.is_null() {
        // SAFETY: The pointer was allocated by `CString::into_raw` above and
        // ownership is transferred back exactly once by the native caller.
        drop(unsafe { CString::from_raw(pointer) });
    }
}

#[cfg(target_os = "android")]

mod android_jni {

    use super::*;
    use jni::objects::{JClass, JString};
    use jni::sys::{jboolean, jlong, jstring};
    use jni::{Env, EnvUnowned};

    #[unsafe(no_mangle)]

    pub extern "system" fn Java_eu_twonly_notifications_NativeNotificationBridge_setApplicationActive(
        _env: EnvUnowned<'_>, _class: JClass<'_>, active: jboolean,
    ) {
        crate::database::lifecycle::foreground::twonly_database_set_foreground(active);
    }

    #[unsafe(no_mangle)]

    pub extern "system" fn Java_eu_twonly_notifications_NativeNotificationBridge_createRun(
        _env: EnvUnowned<'_>, _class: JClass<'_>, budget_ms: jlong,
    ) -> jlong {
        twonly_notification_run_create(budget_ms.max(1) as u64) as jlong
    }

    #[unsafe(no_mangle)]

    pub extern "system" fn Java_eu_twonly_notifications_NativeNotificationBridge_cancelRun(
        _env: EnvUnowned<'_>, _class: JClass<'_>, id: jlong,
    ) {
        twonly_database_operation_cancel(id as u64);
    }

    #[unsafe(no_mangle)]

    pub extern "system" fn Java_eu_twonly_notifications_NativeNotificationBridge_finishRun(
        _env: EnvUnowned<'_>, _class: JClass<'_>, id: jlong,
    ) {
        twonly_notification_run_finish(id as u64);
    }

    fn java_string(env: &mut Env<'_>, value: JString<'_>) -> Result<String, String> {
        value
            .try_to_string(env)
            .map_err(|error| format!("invalid Java string: {error}"))
    }

    fn return_string(env: &mut Env<'_>, value: String) -> jstring {
        jni::objects::JString::from_str(env, value)
            .map(JString::into_raw)
            .unwrap_or(std::ptr::null_mut())
    }

    #[unsafe(no_mangle)]

    pub extern "system" fn Java_eu_twonly_notifications_NativeNotificationBridge_logPushReceived(
        mut unowned_env: EnvUnowned<'_>, _class: JClass<'_>, data_dir: JString<'_>,
        message_id: JString<'_>, sent_at_ms: jlong,
    ) {
        unowned_env
            .with_env(|env| {
                Ok::<_, jni::errors::Error>({
                    let _ = catch_unwind(AssertUnwindSafe(|| {
                        if let (Ok(data_dir), Ok(message_id)) =
                            (java_string(env, data_dir), java_string(env, message_id))
                        {
                            log_push_received(&data_dir, &message_id, sent_at_ms);
                        }
                    }));
                })
            })
            .resolve::<jni::errors::LogErrorAndDefault>()
    }

    #[unsafe(no_mangle)]

    pub extern "system" fn Java_eu_twonly_notifications_NativeNotificationBridge_processWithId(
        mut unowned_env: EnvUnowned<'_>, _class: JClass<'_>, id: jlong, database_dir: JString<'_>,
        data_dir: JString<'_>, locale: JString<'_>, deadline_ms: jlong,
    ) -> jstring {
        unowned_env
            .with_env(|env| {
                Ok::<_, jni::errors::Error>({
                    let result = (|| {
                        let database_dir = CString::new(java_string(env, database_dir)?)
                            .map_err(|error| error.to_string())?;

                        let data_dir = CString::new(java_string(env, data_dir)?)
                            .map_err(|error| error.to_string())?;

                        let locale = CString::new(java_string(env, locale)?)
                            .map_err(|error| error.to_string())?;

                        // SAFETY: Each CString remains alive for the synchronous ABI call.
                        let pointer = unsafe {
                            twonly_notification_process_with_id(
                                id as u64,
                                database_dir.as_ptr(),
                                data_dir.as_ptr(),
                                locale.as_ptr(),
                                deadline_ms.max(0) as u64,
                            )
                        };

                        if pointer.is_null() {
                            return Err("Rust notification worker returned null".into());
                        }

                        // SAFETY: The C ABI returns a valid owned CString.
                        let json = unsafe { CStr::from_ptr(pointer) }
                            .to_string_lossy()
                            .into_owned();

                        unsafe { twonly_notification_string_free(pointer) };

                        Ok(json)
                    })();

                    return_string(
                        env,
                        result.unwrap_or_else(|error: String| {
                            format!(
                                r#"{{"ok":false,"batch":null,"fallback":null,"error":{}}}"#,
                                serde_json::to_string(&error).unwrap_or_else(|_| "null".into())
                            )
                        }),
                    )
                })
            })
            .resolve::<jni::errors::LogErrorAndDefault>()
    }

    #[unsafe(no_mangle)]

    pub extern "system" fn Java_eu_twonly_notifications_NativeNotificationBridge_finalizeWakeup(
        mut unowned_env: EnvUnowned<'_>, _class: JClass<'_>, id: jlong, deadline_ms: jlong,
    ) -> jstring {
        unowned_env
            .with_env(|env| {
                Ok::<_, jni::errors::Error>({
                    let pointer = unsafe {
                        twonly_notification_finalize_with_id(id as u64, deadline_ms.max(0) as u64)
                    };

                    let json = if pointer.is_null() {
                        r#"{"ok":false,"error":"Rust notification finalization returned null"}"#
                            .to_owned()
                    } else {
                        // SAFETY: The C ABI returns a valid owned CString.
                        let json = unsafe { CStr::from_ptr(pointer) }
                            .to_string_lossy()
                            .into_owned();

                        unsafe { twonly_notification_string_free(pointer) };

                        json
                    };

                    return_string(env, json)
                })
            })
            .resolve::<jni::errors::LogErrorAndDefault>()
    }

    #[unsafe(no_mangle)]

    pub extern "system" fn Java_eu_twonly_notifications_NativeNotificationBridge_acknowledge(
        mut unowned_env: EnvUnowned<'_>, _class: JClass<'_>, id: jlong, event_ids_json: JString<'_>,
    ) -> jstring {
        unowned_env
            .with_env(|env| {
                Ok::<_, jni::errors::Error>({
                    let result = (|| {
                        let event_ids_json = CString::new(java_string(env, event_ids_json)?)
                            .map_err(|error| error.to_string())?;

                        let pointer = unsafe {
                            twonly_notification_acknowledge_with_id(
                                id as u64,
                                event_ids_json.as_ptr(),
                            )
                        };

                        if pointer.is_null() {
                            return Err("Rust notification acknowledgement returned null".into());
                        }

                        let json = unsafe { CStr::from_ptr(pointer) }
                            .to_string_lossy()
                            .into_owned();

                        unsafe { twonly_notification_string_free(pointer) };

                        Ok(json)
                    })();

                    return_string(env, result.unwrap_or_else(|error: String| error))
                })
            })
            .resolve::<jni::errors::LogErrorAndDefault>()
    }

    #[unsafe(no_mangle)]

    pub extern "system" fn Java_eu_twonly_notifications_NativeNotificationBridge_storeFcmToken(
        mut unowned_env: EnvUnowned<'_>, _class: JClass<'_>, database_dir: JString<'_>,
        data_dir: JString<'_>, token: JString<'_>,
    ) -> jstring {
        unowned_env
            .with_env(|env| {
                Ok::<_, jni::errors::Error>({
                    let result = (|| {
                        let config = InitConfig {
                            database_dir: java_string(env, database_dir)?,
                            data_dir: java_string(env, data_dir)?,
                        };

                        let token = java_string(env, token)?;

                        crate::native::background::cancel_maintenance_runs();
                        native_job(
                            config,
                            Duration::from_secs(10),
                            crate::log::LogSource::Notification,
                            move |context| async move {
                                notifications::store_fcm_token(&context, token)
                            },
                        )
                    })();

                    let response = match result {
                        Ok(()) => r#"{"ok":true}"#.to_owned(),
                        Err(error) => format!(
                            r#"{{"ok":false,"error":{}}}"#,
                            serde_json::to_string(&error).unwrap_or_else(|_| "null".into())
                        ),
                    };

                    return_string(env, response)
                })
            })
            .resolve::<jni::errors::LogErrorAndDefault>()
    }
}
