/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! Handing a finished media file to the user's photo library.
//!
//! Rust decides whether an export happens and writes the metadata into the file
//! first; the platform only performs the insert, because MediaStore and Photos
//! have no Rust equivalent.

use crate::error::{Result, TwonlyError};
use std::path::Path;

#[cfg(target_os = "ios")]
pub(crate) fn save(path: &Path, is_video: bool, _name: &str, created_at_millis: i64) -> Result<()> {
    use std::ffi::CString;
    use std::os::raw::c_char;

    type SaveToGallery = unsafe extern "C" fn(*const c_char, bool, i64) -> bool;

    let path = CString::new(path.as_os_str().as_encoded_bytes())
        .map_err(|_| TwonlyError::Generic("gallery path contains a NUL byte".into()))?;
    let symbol = c"twonly_save_to_gallery";
    let callback = unsafe { libc::dlsym(libc::RTLD_DEFAULT, symbol.as_ptr()) };
    if callback.is_null() {
        return Err(TwonlyError::Generic(
            "iOS gallery export is unavailable".into(),
        ));
    }
    // SAFETY: the Swift @_cdecl declaration has this exact stable C ABI signature.
    let callback: SaveToGallery = unsafe { std::mem::transmute(callback) };
    // SAFETY: Swift copies the string before this call returns.
    if unsafe { callback(path.as_ptr(), is_video, created_at_millis) } {
        Ok(())
    } else {
        Err(TwonlyError::Generic(
            "iOS could not save to the photo library".into(),
        ))
    }
}

#[cfg(target_os = "android")]
pub(crate) fn save(path: &Path, is_video: bool, name: &str, created_at_millis: i64) -> Result<()> {
    use crate::native::transfer::android::{gallery_class, jni_env};
    use jni::objects::{JObject, JValue};

    let class = gallery_class()?;
    let mut env = jni_env()?;
    let string = |value: &str| {
        env.new_string(value)
            .map_err(|error| TwonlyError::Generic(error.to_string()))
    };
    let path = JObject::from(string(&path.to_string_lossy())?);
    let name = JObject::from(string(name)?);
    let call = env
        .call_static_method(
            class,
            "save",
            "(Ljava/lang/String;ZLjava/lang/String;J)Z",
            &[
                JValue::Object(&path),
                JValue::Bool(u8::from(is_video)),
                JValue::Object(&name),
                JValue::Long(created_at_millis),
            ],
        )
        .and_then(|value| value.z());
    if env.exception_check().unwrap_or(false) {
        let _ = env.exception_describe();
        let _ = env.exception_clear();
    }
    if call.map_err(|error| TwonlyError::Generic(error.to_string()))? {
        Ok(())
    } else {
        Err(TwonlyError::Generic(
            "Android could not save to the photo library".into(),
        ))
    }
}

#[cfg(not(any(target_os = "android", target_os = "ios")))]
pub(crate) fn save(
    _path: &Path,
    _is_video: bool,
    _name: &str,
    _created_at_millis: i64,
) -> Result<()> {
    Err(TwonlyError::Generic(
        "platform gallery export is only available on Android and iOS".into(),
    ))
}
