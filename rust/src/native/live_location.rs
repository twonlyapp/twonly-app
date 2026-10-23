//! Native location workers use the existing notification runtime without
//! Flutter.

use crate::bridge::InitConfig;
use crate::error::TwonlyError;
use crate::services::live_location;
use serde::Deserialize;
use std::ffi::{c_char, CStr, CString};
use std::panic::{catch_unwind, AssertUnwindSafe};

#[derive(Deserialize)]

struct Request {
    action: String,
    session_id: Option<String>,
    fix: Option<(f64, f64, f64, i64)>,
}

fn run(directory: String, request: String, source: crate::log::LogSource) -> String {
    let result = catch_unwind(AssertUnwindSafe(|| -> Result<serde_json::Value, String> {
        let request: Request = serde_json::from_str(&request).map_err(|e| e.to_string())?;

        crate::native::notifications::native_job(
            InitConfig {
                database_dir: directory.clone(),
                data_dir: directory,
            },
            std::time::Duration::from_secs(5),
            source,
            move |ctx| async move {
                if request.action == "stop" {
                    live_location::stop(
                        &ctx,
                        request
                            .session_id
                            .as_deref()
                            .ok_or_else(|| TwonlyError::Generic("Missing session".into()))?,
                    )
                    .await?;
                } else if request.action == "update" {
                    live_location::update(
                        &ctx,
                        request
                            .session_id
                            .as_deref()
                            .ok_or_else(|| TwonlyError::Generic("Missing session".into()))?,
                        request.fix,
                        false,
                    )
                    .await?;
                } else if request.action != "state" {
                    return Err(TwonlyError::Generic("Unknown location action".into()));
                }

                let session = live_location::state(&ctx).await?;

                Ok(serde_json::json!({"ok":true,"session":session}))
            },
        )
    }));

    match result {
        Ok(Ok(value)) => value.to_string(),
        Ok(Err(error)) => serde_json::json!({"ok":false,"error":error}).to_string(),
        Err(_) => r#"{"ok":false,"error":"Location worker panicked"}"#.into(),
    }
}

/// Both input strings remain valid until return. Free the result with the
/// existing `twonly_notification_string_free` ABI.
#[unsafe(no_mangle)]

pub unsafe extern "C" fn twonly_live_location_run(
    directory: *const c_char, request: *const c_char,
) -> *mut c_char {
    let json = if directory.is_null() || request.is_null() {
        r#"{"ok":false,"error":"Missing location request"}"#.into()
    } else {
        // SAFETY: Native callers provide valid UTF-8 C strings during this call.
        run(
            unsafe { CStr::from_ptr(directory) }
                .to_string_lossy()
                .into_owned(),
            unsafe { CStr::from_ptr(request) }
                .to_string_lossy()
                .into_owned(),
            crate::log::LogSource::Background,
        )
    };

    CString::new(json)
        .expect("JSON escapes NUL bytes")
        .into_raw()
}

#[cfg(target_os = "android")]
#[unsafe(no_mangle)]

pub extern "system" fn Java_eu_twonly_location_NativeLiveLocationBridge_run(
    mut unowned_env: jni::EnvUnowned<'_>, _class: jni::objects::JClass<'_>,
    directory: jni::objects::JString<'_>, request: jni::objects::JString<'_>,
) -> jni::sys::jstring {
    unowned_env
        .with_env(|env| {
            Ok::<_, jni::errors::Error>({
                let strings = (|| -> std::result::Result<(String, String), jni::errors::Error> {
                    Ok((directory.try_to_string(env)?, request.try_to_string(env)?))
                })();

                let json = match strings {
                    Ok((directory, request)) => {
                        run(directory, request, crate::log::LogSource::ForegroundService)
                    }
                    Err(_) => r#"{"ok":false,"error":"Invalid JNI request"}"#.into(),
                };

                jni::objects::JString::from_str(env, json)
                    .map(|s| s.into_raw())
                    .unwrap_or(std::ptr::null_mut())
            })
        })
        .resolve::<jni::errors::LogErrorAndDefault>()
}
