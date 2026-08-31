/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! The one image job Rust cannot do alone: decoding container formats with no
//! practical pure-Rust decoder — HEIC/HEIF from an iPhone camera above all.
//! The platform decodes to PNG on disk and Rust takes it from there, so no
//! pixel buffer has to cross the FFI boundary.

use crate::error::{Result, TwonlyError};
use std::path::Path;

#[cfg(target_os = "ios")]
pub(crate) fn decode_to_png(input: &Path, output: &Path) -> Result<()> {
    use std::ffi::CString;
    use std::os::raw::c_char;

    type DecodeImage = unsafe extern "C" fn(*const c_char, *const c_char) -> bool;

    let input = CString::new(input.as_os_str().as_encoded_bytes())
        .map_err(|_| TwonlyError::Generic("image path contains a NUL byte".into()))?;
    let output = CString::new(output.as_os_str().as_encoded_bytes())
        .map_err(|_| TwonlyError::Generic("image path contains a NUL byte".into()))?;
    // The implementation lives in the app executable, so it is resolved at
    // runtime rather than required when the standalone cdylib is linked.
    let symbol = c"twonly_decode_image_to_png";
    let callback = unsafe { libc::dlsym(libc::RTLD_DEFAULT, symbol.as_ptr()) };
    if callback.is_null() {
        return Err(TwonlyError::Generic(
            "iOS image decoding is unavailable".into(),
        ));
    }
    // SAFETY: the Swift @_cdecl declaration has this exact stable C ABI signature.
    let callback: DecodeImage = unsafe { std::mem::transmute(callback) };
    // SAFETY: Swift copies both strings before this call returns.
    if unsafe { callback(input.as_ptr(), output.as_ptr()) } {
        Ok(())
    } else {
        Err(TwonlyError::Generic(
            "iOS could not decode this image".into(),
        ))
    }
}

#[cfg(target_os = "android")]
pub(crate) fn decode_to_png(input: &Path, output: &Path) -> Result<()> {
    use crate::native::transfer::android::{jni_env, media_codec_class};
    use jni::objects::{JObject, JValue};

    let class = media_codec_class()?;
    let mut env = jni_env()?;
    let input = env
        .new_string(input.to_string_lossy().as_ref())
        .map_err(|error| TwonlyError::Generic(error.to_string()))?;
    let output = env
        .new_string(output.to_string_lossy().as_ref())
        .map_err(|error| TwonlyError::Generic(error.to_string()))?;
    let input = JObject::from(input);
    let output = JObject::from(output);
    let call = env
        .call_static_method(
            class,
            "decodeToPng",
            "(Ljava/lang/String;Ljava/lang/String;)Z",
            &[JValue::Object(&input), JValue::Object(&output)],
        )
        .and_then(|value| value.z());
    // A pending Java exception would abort the process once this thread returns
    // to the VM, so it is cleared and reported as a plain error instead.
    if env.exception_check().unwrap_or(false) {
        let _ = env.exception_describe();
        let _ = env.exception_clear();
    }
    if call.map_err(|error| TwonlyError::Generic(error.to_string()))? {
        Ok(())
    } else {
        Err(TwonlyError::Generic(
            "Android could not decode this image".into(),
        ))
    }
}

#[cfg(not(any(target_os = "android", target_os = "ios")))]
pub(crate) fn decode_to_png(_input: &Path, _output: &Path) -> Result<()> {
    Err(TwonlyError::Generic(
        "platform image decoding is only available on Android and iOS".into(),
    ))
}
