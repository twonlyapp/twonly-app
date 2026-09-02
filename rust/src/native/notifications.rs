/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! Stable synchronous C entry points for native notification executables.
//! The ABI owns its Tokio runtime so neither Swift nor Kotlin needs Flutter or
//! flutter_rust_bridge to process a background wake-up.

use crate::bridge::InitConfig;
use crate::context::Context;
use crate::services::notifications::{self, NotificationBatch, NotificationPresentation};
use serde::Serialize;
use std::ffi::{c_char, CStr, CString};
use std::panic::{catch_unwind, AssertUnwindSafe};
use std::sync::{LazyLock, Mutex, MutexGuard};

static NOTIFICATION_WORKER: LazyLock<Mutex<()>> = LazyLock::new(|| Mutex::new(()));

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

fn runtime() -> Result<&'static tokio::runtime::Runtime, String> {
    NOTIFICATION_RUNTIME.as_ref().map_err(Clone::clone)
}

fn worker_lock() -> MutexGuard<'static, ()> {
    NOTIFICATION_WORKER
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner())
}

/// Processes an opaque FCM/APNs wake-up and returns a JSON-encoded
/// `NativeNotificationResponse`. The returned pointer must be released with
/// `twonly_notification_string_free`.
#[unsafe(no_mangle)]
pub unsafe extern "C" fn twonly_notification_process(
    database_dir: *const c_char,
    data_dir: *const c_char,
    locale: *const c_char,
    deadline_ms: u64,
) -> *mut c_char {
    let result = catch_unwind(AssertUnwindSafe(|| {
        let _worker = worker_lock();
        let database_dir = unsafe { required_string(database_dir, "database_dir") }?;
        let data_dir = unsafe { required_string(data_dir, "data_dir") }?;
        let locale = unsafe { required_string(locale, "locale") }?;
        let runtime = runtime()?;
        runtime
            .block_on(notifications::process_wakeup(
                InitConfig {
                    database_dir,
                    data_dir,
                },
                &locale,
                deadline_ms,
            ))
            .map_err(|error| error.to_string())
    }));

    match result {
        Ok(Ok(batch)) => response_json(NativeNotificationResponse {
            ok: true,
            widget_refresh: true,
            batch: Some(batch),
            fallback: Some(notifications::fallback_presentation(
                unsafe { required_string(locale, "locale") }
                    .as_deref()
                    .unwrap_or("en"),
            )),
            error: None,
        }),
        Ok(Err(error)) => response_json(NativeNotificationResponse {
            ok: false,
            widget_refresh: false,
            batch: None,
            fallback: Some(notifications::fallback_presentation(
                unsafe { required_string(locale, "locale") }
                    .as_deref()
                    .unwrap_or("en"),
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
    let result = catch_unwind(AssertUnwindSafe(|| {
        let _worker = worker_lock();
        runtime()?
            .block_on(notifications::finalize_wakeup(deadline_ms))
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
    let result = catch_unwind(AssertUnwindSafe(|| {
        let _worker = worker_lock();
        let event_ids_json = unsafe { required_string(event_ids_json, "event_ids_json") }?;
        let event_ids: Vec<String> =
            serde_json::from_str(&event_ids_json).map_err(|error| error.to_string())?;
        let ctx = Context::get_static()
            .map_err(|error| error.to_string())?
            .clone();
        runtime()?
            .block_on(notifications::acknowledge_batch(&ctx, &event_ids))
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
    use jni::sys::{jlong, jstring};
    use jni::JNIEnv;

    fn java_string(env: &mut JNIEnv<'_>, value: JString<'_>) -> Result<String, String> {
        env.get_string(&value)
            .map(Into::into)
            .map_err(|error| format!("invalid Java string: {error}"))
    }

    fn return_string(env: &mut JNIEnv<'_>, value: String) -> jstring {
        env.new_string(value)
            .map(JString::into_raw)
            .unwrap_or(std::ptr::null_mut())
    }

    #[unsafe(no_mangle)]
    pub extern "system" fn Java_eu_twonly_notifications_NativeNotificationBridge_process(
        mut env: JNIEnv<'_>,
        _class: JClass<'_>,
        database_dir: JString<'_>,
        data_dir: JString<'_>,
        locale: JString<'_>,
        deadline_ms: jlong,
    ) -> jstring {
        let result = (|| {
            let database_dir = CString::new(java_string(&mut env, database_dir)?)
                .map_err(|error| error.to_string())?;
            let data_dir = CString::new(java_string(&mut env, data_dir)?)
                .map_err(|error| error.to_string())?;
            let locale =
                CString::new(java_string(&mut env, locale)?).map_err(|error| error.to_string())?;
            // SAFETY: Each CString remains alive for the synchronous ABI call.
            let pointer = unsafe {
                twonly_notification_process(
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
            &mut env,
            result.unwrap_or_else(|error: String| {
                format!(
                    r#"{{"ok":false,"batch":null,"fallback":null,"error":{}}}"#,
                    serde_json::to_string(&error).unwrap_or_else(|_| "null".into())
                )
            }),
        )
    }

    #[unsafe(no_mangle)]
    pub extern "system" fn Java_eu_twonly_notifications_NativeNotificationBridge_finalizeWakeup(
        mut env: JNIEnv<'_>,
        _class: JClass<'_>,
        deadline_ms: jlong,
    ) -> jstring {
        let pointer = unsafe { twonly_notification_finalize(deadline_ms.max(0) as u64) };
        let json = if pointer.is_null() {
            r#"{"ok":false,"error":"Rust notification finalization returned null"}"#.to_owned()
        } else {
            // SAFETY: The C ABI returns a valid owned CString.
            let json = unsafe { CStr::from_ptr(pointer) }
                .to_string_lossy()
                .into_owned();
            unsafe { twonly_notification_string_free(pointer) };
            json
        };
        return_string(&mut env, json)
    }

    #[unsafe(no_mangle)]
    pub extern "system" fn Java_eu_twonly_notifications_NativeNotificationBridge_acknowledge(
        mut env: JNIEnv<'_>,
        _class: JClass<'_>,
        event_ids_json: JString<'_>,
    ) -> jstring {
        let result = (|| {
            let event_ids_json = CString::new(java_string(&mut env, event_ids_json)?)
                .map_err(|error| error.to_string())?;
            let pointer = unsafe { twonly_notification_acknowledge(event_ids_json.as_ptr()) };
            if pointer.is_null() {
                return Err("Rust notification acknowledgement returned null".into());
            }
            let json = unsafe { CStr::from_ptr(pointer) }
                .to_string_lossy()
                .into_owned();
            unsafe { twonly_notification_string_free(pointer) };
            Ok(json)
        })();
        return_string(&mut env, result.unwrap_or_else(|error: String| error))
    }

    #[unsafe(no_mangle)]
    pub extern "system" fn Java_eu_twonly_notifications_NativeNotificationBridge_storeFcmToken(
        mut env: JNIEnv<'_>,
        _class: JClass<'_>,
        database_dir: JString<'_>,
        data_dir: JString<'_>,
        token: JString<'_>,
    ) -> jstring {
        let result = (|| {
            let _worker = worker_lock();
            let config = InitConfig {
                database_dir: java_string(&mut env, database_dir)?,
                data_dir: java_string(&mut env, data_dir)?,
            };
            let token = java_string(&mut env, token)?;
            runtime()?
                .block_on(notifications::store_fcm_token(config, token))
                .map_err(|error| error.to_string())
        })();
        let response = match result {
            Ok(()) => r#"{"ok":true}"#.to_owned(),
            Err(error) => format!(
                r#"{{"ok":false,"error":{}}}"#,
                serde_json::to_string(&error).unwrap_or_else(|_| "null".into())
            ),
        };
        return_string(&mut env, response)
    }
}
