/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! One-shot, precise foreground location access implemented by the host app.

use crate::error::Result;
#[cfg(any(target_os = "android", target_os = "ios"))]
use crate::error::TwonlyError;
use std::time::Duration;

#[derive(Clone, Copy, Debug)]
pub(crate) struct LocationFix {
    pub latitude: f64,
    pub longitude: f64,
    pub accuracy: f64,
}

#[cfg(target_os = "ios")]
pub(crate) fn current(timeout: Duration) -> Result<Option<LocationFix>> {
    type CurrentLocation = unsafe extern "C" fn(i64, *mut f64, *mut f64, *mut f64) -> bool;

    let callback = unsafe { libc::dlsym(libc::RTLD_DEFAULT, c"twonly_current_location".as_ptr()) };
    if callback.is_null() {
        return Err(TwonlyError::Generic(
            "iOS location service is unavailable".into(),
        ));
    }
    // SAFETY: the Swift @_cdecl declaration has this exact stable C ABI signature.
    let callback: CurrentLocation = unsafe { std::mem::transmute(callback) };
    let mut latitude = 0.0;
    let mut longitude = 0.0;
    let mut accuracy = 0.0;
    // SAFETY: all output pointers remain valid until the synchronous call returns.
    let found = unsafe {
        callback(
            timeout.as_millis().min(i64::MAX as u128) as i64,
            &mut latitude,
            &mut longitude,
            &mut accuracy,
        )
    };
    Ok(found.then_some(LocationFix {
        latitude,
        longitude,
        accuracy,
    }))
}

#[cfg(target_os = "android")]
pub(crate) fn current(timeout: Duration) -> Result<Option<LocationFix>> {
    use crate::native::transfer::android::{jni_env, location_class};
    use jni::objects::JString;

    let class = location_class()?;
    let mut env = jni_env()?;
    let value = env
        .call_static_method(
            class,
            "current",
            "(J)Ljava/lang/String;",
            &[jni::objects::JValue::Long(
                timeout.as_millis().min(i64::MAX as u128) as i64,
            )],
        )
        .and_then(|value| value.l());
    if env.exception_check().unwrap_or(false) {
        let _ = env.exception_describe();
        let _ = env.exception_clear();
    }
    let value = value.map_err(|error| TwonlyError::Generic(error.to_string()))?;
    if value.is_null() {
        return Ok(None);
    }
    let json: String = env
        .get_string(&JString::from(value))
        .map_err(|error| TwonlyError::Generic(error.to_string()))?
        .into();
    let values: Vec<f64> = serde_json::from_str(&json)?;
    if values.len() != 3 {
        return Err(TwonlyError::Generic(
            "Android returned an invalid location".into(),
        ));
    }
    Ok(Some(LocationFix {
        latitude: values[0],
        longitude: values[1],
        accuracy: values[2],
    }))
}

#[cfg(not(any(target_os = "android", target_os = "ios")))]
pub(crate) fn current(_timeout: Duration) -> Result<Option<LocationFix>> {
    Ok(None)
}
