/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! Video composition and transcoding, in one hardware pass per platform.
//!
//! iOS uses AVFoundation (VideoToolbox underneath) and Android uses Media3
//! `Transformer` (MediaCodec plus an OpenGL overlay stage). Neither involves
//! ffmpeg or the Flutter engine, so a send can finish while the app is in the
//! background or was relaunched without its UI.

use crate::error::{Result, TwonlyError};
use std::path::{Path, PathBuf};
use std::sync::OnceLock;

/// One render request. The overlay is a pre-rasterised PNG the size of the
/// video frame; the editor draws it once when the user hits send. Owned so the
/// whole request can move onto the blocking pool.
// Only the mobile implementations read these; the desktop stub cannot render.
#[cfg_attr(not(any(target_os = "android", target_os = "ios")), allow(dead_code))]
pub(crate) struct RenderRequest {
    pub media_id: String,
    pub input: PathBuf,
    pub overlay: Option<PathBuf>,
    pub output: PathBuf,
    pub remove_audio: bool,
}

/// The platform reports progress from its own thread — Android's main looper,
/// a GCD timer on iOS — which is not inside the async runtime. Spawning from
/// there would panic, and a panic unwinding back through the C ABI aborts the
/// process, so the runtime is captured while still on a Rust thread.
#[cfg_attr(not(any(target_os = "android", target_os = "ios")), allow(dead_code))]
static RUNTIME: OnceLock<tokio::runtime::Handle> = OnceLock::new();

#[cfg_attr(not(any(target_os = "android", target_os = "ios")), allow(dead_code))]
fn remember_runtime() {
    if let Ok(handle) = tokio::runtime::Handle::try_current() {
        let _ = RUNTIME.set(handle);
    }
}

/// Reports transcoding progress back into the media row so the send state in
/// chat can show it. Called by the platform while a render is running.
#[cfg_attr(not(any(target_os = "android", target_os = "ios")), allow(dead_code))]
fn report_progress(media_id: &str, percent: i64) {
    let Ok(ctx) = crate::context::Context::get_static() else {
        return;
    };
    let Some(runtime) = RUNTIME.get() else {
        return;
    };
    let ctx = ctx.clone();
    let media_id = media_id.to_owned();
    runtime.spawn(async move {
        let database = ctx.app_db.read().await.clone();
        let _ =
            sqlx::query("UPDATE media_files SET pre_progressing_process = ? WHERE media_id = ?")
                .bind(percent.clamp(0, 100))
                .bind(&media_id)
                .execute(&database.pool)
                .await;
        database.notify_committed(["media_files"]);
    });
}

#[cfg(target_os = "ios")]
pub(crate) fn render(request: &RenderRequest) -> Result<()> {
    remember_runtime();
    use std::ffi::{CStr, CString};
    use std::os::raw::{c_char, c_int};

    type ProgressCallback = unsafe extern "C" fn(*const c_char, c_int);
    type RenderVideo = unsafe extern "C" fn(
        *const c_char,
        *const c_char,
        *const c_char,
        bool,
        *const c_char,
        ProgressCallback,
    ) -> bool;

    unsafe extern "C" fn progress(media_id: *const c_char, percent: c_int) {
        // Unwinding back into Swift would abort the process, so a panic here
        // can only cost this one progress update.
        let _ = std::panic::catch_unwind(|| {
            if media_id.is_null() {
                return;
            }
            // SAFETY: Swift passes the same NUL-terminated string it was handed.
            let media_id = unsafe { CStr::from_ptr(media_id) };
            if let Ok(media_id) = media_id.to_str() {
                report_progress(media_id, i64::from(percent));
            }
        });
    }

    let to_c = |path: &PathBuf| {
        CString::new(path.as_os_str().as_encoded_bytes())
            .map_err(|_| TwonlyError::Generic("video path contains a NUL byte".into()))
    };
    let input = to_c(&request.input)?;
    let output = to_c(&request.output)?;
    let overlay = request.overlay.as_ref().map(to_c).transpose()?;
    let media_id = CString::new(request.media_id.as_str())
        .map_err(|_| TwonlyError::Generic("media id contains a NUL byte".into()))?;

    let symbol = c"twonly_render_video";
    // The implementation lives in the app executable, so it is resolved at
    // runtime instead of being required when the cdylib is linked.
    let callback = unsafe { libc::dlsym(libc::RTLD_DEFAULT, symbol.as_ptr()) };
    if callback.is_null() {
        return Err(TwonlyError::Generic(
            "iOS video rendering is unavailable".into(),
        ));
    }
    // SAFETY: the Swift @_cdecl declaration has this exact stable C ABI signature.
    let callback: RenderVideo = unsafe { std::mem::transmute(callback) };
    // SAFETY: Swift copies every string before returning, and the progress
    // function pointer is only called for the duration of this call.
    let rendered = unsafe {
        callback(
            input.as_ptr(),
            overlay
                .as_ref()
                .map_or(std::ptr::null(), |path| path.as_ptr()),
            output.as_ptr(),
            request.remove_audio,
            media_id.as_ptr(),
            progress,
        )
    };
    if rendered {
        Ok(())
    } else {
        Err(TwonlyError::Generic(
            "iOS could not render the video".into(),
        ))
    }
}

#[cfg(target_os = "android")]
pub(crate) fn render(request: &RenderRequest) -> Result<()> {
    remember_runtime();
    use crate::native::transfer::android::{jni_env, video_codec_class};
    use jni::objects::{JObject, JValue};

    let class = video_codec_class()?;
    let mut env = jni_env()?;
    let string = |value: &str| {
        env.new_string(value)
            .map_err(|error| TwonlyError::Generic(error.to_string()))
    };
    let input = JObject::from(string(&request.input.to_string_lossy())?);
    let output = JObject::from(string(&request.output.to_string_lossy())?);
    let media_id = JObject::from(string(&request.media_id)?);
    let overlay = match request.overlay.as_ref() {
        Some(path) => JObject::from(string(&path.to_string_lossy())?),
        None => JObject::null(),
    };

    let call = env
        .call_static_method(
            class,
            "render",
            "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;ZLjava/lang/String;)Z",
            &[
                JValue::Object(&input),
                JValue::Object(&overlay),
                JValue::Object(&output),
                JValue::Bool(u8::from(request.remove_audio)),
                JValue::Object(&media_id),
            ],
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
            "Android could not render the video".into(),
        ))
    }
}

/// Progress reported by the Android renderer while `render` is blocked.
#[cfg(target_os = "android")]
#[unsafe(no_mangle)]
pub extern "system" fn Java_eu_twonly_media_NativeVideoCodec_reportProgress(
    mut env: jni::JNIEnv,
    _class: jni::objects::JClass,
    media_id: jni::objects::JString,
    percent: jni::sys::jint,
) {
    // This runs on Android's main looper. Unwinding back into the VM would
    // abort the process, so a panic can only cost this one progress update.
    let _ = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
        let Ok(media_id) = env.get_string(&media_id) else {
            return;
        };
        report_progress(&media_id.to_string_lossy(), i64::from(percent));
    }));
}

#[cfg(not(any(target_os = "android", target_os = "ios")))]
pub(crate) fn render(_request: &RenderRequest) -> Result<()> {
    Err(TwonlyError::Generic(
        "platform video rendering is only available on Android and iOS".into(),
    ))
}

/// Extracts a frame as PNG so Rust can encode the thumbnail itself. The frame
/// grab needs the platform's video decoder; everything after it does not.
#[cfg(target_os = "ios")]
pub(crate) fn extract_frame(input: &Path, output: &Path) -> Result<()> {
    use std::ffi::CString;
    use std::os::raw::c_char;

    type ExtractFrame = unsafe extern "C" fn(*const c_char, *const c_char) -> bool;

    let to_c = |path: &Path| {
        CString::new(path.as_os_str().as_encoded_bytes())
            .map_err(|_| TwonlyError::Generic("video path contains a NUL byte".into()))
    };
    let input = to_c(input)?;
    let output = to_c(output)?;
    let symbol = c"twonly_extract_video_frame";
    let callback = unsafe { libc::dlsym(libc::RTLD_DEFAULT, symbol.as_ptr()) };
    if callback.is_null() {
        return Err(TwonlyError::Generic(
            "iOS frame extraction is unavailable".into(),
        ));
    }
    // SAFETY: the Swift @_cdecl declaration has this exact stable C ABI signature.
    let callback: ExtractFrame = unsafe { std::mem::transmute(callback) };
    // SAFETY: Swift copies both strings before this call returns.
    if unsafe { callback(input.as_ptr(), output.as_ptr()) } {
        Ok(())
    } else {
        Err(TwonlyError::Generic(
            "iOS could not extract a video frame".into(),
        ))
    }
}

#[cfg(target_os = "android")]
pub(crate) fn extract_frame(input: &Path, output: &Path) -> Result<()> {
    use crate::native::transfer::android::{jni_env, video_codec_class};
    use jni::objects::{JObject, JValue};

    let class = video_codec_class()?;
    let mut env = jni_env()?;
    let string = |value: &str| {
        env.new_string(value)
            .map_err(|error| TwonlyError::Generic(error.to_string()))
    };
    let input = JObject::from(string(&input.to_string_lossy())?);
    let output = JObject::from(string(&output.to_string_lossy())?);
    let call = env
        .call_static_method(
            class,
            "extractFrame",
            "(Ljava/lang/String;Ljava/lang/String;)Z",
            &[JValue::Object(&input), JValue::Object(&output)],
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
            "Android could not extract a video frame".into(),
        ))
    }
}

#[cfg(not(any(target_os = "android", target_os = "ios")))]
pub(crate) fn extract_frame(_input: &Path, _output: &Path) -> Result<()> {
    Err(TwonlyError::Generic(
        "platform frame extraction is only available on Android and iOS".into(),
    ))
}
