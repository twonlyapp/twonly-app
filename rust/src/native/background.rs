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
use crate::services::background::{self, Job, RunOutcome};
use std::ffi::{c_char, CStr, CString};
use std::panic::{catch_unwind, AssertUnwindSafe};
use std::sync::{LazyLock, Mutex, MutexGuard};

/// One maintenance run at a time per process. Two concurrent runs would only
/// contend on the same per-media locks and the same socket.
static MAINTENANCE_WORKER: LazyLock<Mutex<()>> = LazyLock::new(|| Mutex::new(()));

fn worker_lock() -> MutexGuard<'static, ()> {
    MAINTENANCE_WORKER
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner())
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
            r#"{{"ok":true,"pending_uploads":{}}}"#,
            outcome.pending_uploads
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
    database_dir: *const c_char,
    data_dir: *const c_char,
    media_id: *const c_char,
) -> *mut c_char {
    let result = catch_unwind(AssertUnwindSafe(|| {
        let _worker = worker_lock();
        let database_dir = unsafe { required_string(database_dir, "database_dir") }?;
        let data_dir = unsafe { required_string(data_dir, "data_dir") }?;
        let job = match unsafe { optional_string(media_id) } {
            Some(media_id) => Job::PrepareMedia(media_id),
            None => Job::Flush,
        };
        runtime()?
            .block_on(background::run(
                InitConfig {
                    database_dir,
                    data_dir,
                },
                job,
            ))
            .map_err(|error| error.to_string())
    }));

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

#[cfg(target_os = "android")]
mod android_jni {
    use super::*;
    use jni::objects::{JClass, JString};
    use jni::sys::jstring;
    use jni::JNIEnv;

    #[unsafe(no_mangle)]
    pub extern "system" fn Java_eu_twonly_directmedia_NativeMediaPrepareBridge_run(
        mut env: JNIEnv<'_>,
        _class: JClass<'_>,
        database_dir: JString<'_>,
        data_dir: JString<'_>,
        media_id: JString<'_>,
    ) -> jstring {
        let result = (|| -> Result<String, String> {
            let java_string =
                |env: &mut JNIEnv<'_>, value: JString<'_>| -> Result<String, String> {
                    env.get_string(&value)
                        .map(Into::into)
                        .map_err(|error| format!("invalid Java string: {error}"))
                };
            let database_dir = CString::new(java_string(&mut env, database_dir)?)
                .map_err(|error| error.to_string())?;
            let data_dir = CString::new(java_string(&mut env, data_dir)?)
                .map_err(|error| error.to_string())?;
            // A null Java string is the flush job, so it is not required here.
            let media_id = if media_id.is_null() {
                None
            } else {
                Some(
                    CString::new(java_string(&mut env, media_id)?)
                        .map_err(|error| error.to_string())?,
                )
            };
            // SAFETY: Each CString remains alive for the synchronous ABI call.
            let pointer = unsafe {
                twonly_background_run(
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
        env.new_string(json)
            .map(JString::into_raw)
            .unwrap_or(std::ptr::null_mut())
    }
}
