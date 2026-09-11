use crate::error::{Result, TwonlyError};

#[cfg(target_os = "ios")]
pub(crate) fn schedule(descriptor_json: &str) -> Result<()> {
    use std::ffi::CString;
    use std::os::raw::c_char;

    type ScheduleUpload = unsafe extern "C" fn(*const c_char) -> bool;

    let descriptor = CString::new(descriptor_json)
        .map_err(|_| TwonlyError::Generic("native upload descriptor contains a NUL byte".into()))?;
    let symbol = c"twonly_schedule_direct_media_uploads";
    // The callback lives in the containing iOS executable, so resolve it at runtime instead of
    // requiring it while Cargo links the standalone Rust cdylib build product.
    let callback = unsafe { libc::dlsym(libc::RTLD_DEFAULT, symbol.as_ptr()) };
    if callback.is_null() {
        return Err(TwonlyError::Generic(
            "iOS direct-media upload callback is unavailable".into(),
        ));
    }
    // SAFETY: the Swift @_cdecl declaration has this exact stable C ABI signature.
    let callback: ScheduleUpload = unsafe { std::mem::transmute(callback) };
    // SAFETY: Swift copies and decodes the string before this call returns.
    if unsafe { callback(descriptor.as_ptr()) } {
        Ok(())
    } else {
        Err(TwonlyError::Generic(
            "iOS rejected the direct-media upload schedule".into(),
        ))
    }
}

#[cfg(target_os = "android")]
pub(crate) mod android {
    use super::*;
    use jni::objects::{GlobalRef, JObject, JValue};
    use jni::sys::{jint, JNI_VERSION_1_6};
    use jni::{AttachGuard, JavaVM};
    use std::ffi::c_void;
    use std::sync::OnceLock;

    const TRANSFER_CLASS: &str = "eu/twonly/directmedia/DirectMediaTransfer";
    const PREPARE_CLASS: &str = "eu/twonly/directmedia/DirectMediaPrepare";
    const MEDIA_CODEC_CLASS: &str = "eu/twonly/media/NativeImageCodec";
    const VIDEO_CODEC_CLASS: &str = "eu/twonly/media/NativeVideoCodec";
    const GALLERY_CLASS: &str = "eu/twonly/media/NativeGallery";
    const LOCATION_CLASS: &str = "eu/twonly/location/NativeLocation";

    static JAVA_VM: OnceLock<JavaVM> = OnceLock::new();
    static TRANSFER: OnceLock<GlobalRef> = OnceLock::new();
    static PREPARE: OnceLock<GlobalRef> = OnceLock::new();
    static MEDIA_CODEC: OnceLock<GlobalRef> = OnceLock::new();
    static VIDEO_CODEC: OnceLock<GlobalRef> = OnceLock::new();
    static GALLERY: OnceLock<GlobalRef> = OnceLock::new();
    static LOCATION: OnceLock<GlobalRef> = OnceLock::new();
    /// `JNI_OnLoad` runs before Rust logging exists, so failures there are
    /// recorded rather than logged, and reported by the first call that needs
    /// the class.
    static CLASS_ERROR: OnceLock<String> = OnceLock::new();

    #[unsafe(no_mangle)]
    pub extern "system" fn JNI_OnLoad(vm: JavaVM, _reserved: *mut c_void) -> jint {
        // A thread Rust spawned itself and attaches later only sees the system
        // class loader, which knows nothing about the APK. `JNI_OnLoad` runs on
        // the Java thread that called `System.loadLibrary`, so it is the one
        // place where the application's own classes can still be resolved by
        // name. Hold on to them; every later call comes from a Rust thread.
        match vm.get_env() {
            Ok(mut env) => {
                for (name, cache) in [
                    (TRANSFER_CLASS, &TRANSFER),
                    (PREPARE_CLASS, &PREPARE),
                    (MEDIA_CODEC_CLASS, &MEDIA_CODEC),
                    (VIDEO_CODEC_CLASS, &VIDEO_CODEC),
                    (GALLERY_CLASS, &GALLERY),
                    (LOCATION_CLASS, &LOCATION),
                ] {
                    match env
                        .find_class(name)
                        .and_then(|class| env.new_global_ref(class))
                    {
                        Ok(global) => {
                            let _ = cache.set(global);
                        }
                        Err(error) => {
                            // Leaving a ClassNotFoundException pending would abort
                            // the process the next time this thread enters the VM.
                            let _ = env.exception_clear();
                            let _ = CLASS_ERROR.set(format!("{name}: {error}"));
                        }
                    }
                }
            }
            Err(error) => {
                let _ = CLASS_ERROR.set(format!("no JNI env during JNI_OnLoad: {error}"));
            }
        }
        let _ = JAVA_VM.set(vm);
        JNI_VERSION_1_6
    }

    fn cached_class(cache: &'static OnceLock<GlobalRef>, name: &str) -> Result<&'static GlobalRef> {
        cache.get().ok_or_else(|| {
            TwonlyError::Generic(format!(
                "Android class {name} is unavailable ({})",
                CLASS_ERROR
                    .get()
                    .map_or("JNI_OnLoad never ran", String::as_str)
            ))
        })
    }

    pub(crate) fn prepare_class() -> Result<&'static GlobalRef> {
        cached_class(&PREPARE, PREPARE_CLASS)
    }

    pub(crate) fn media_codec_class() -> Result<&'static GlobalRef> {
        cached_class(&MEDIA_CODEC, MEDIA_CODEC_CLASS)
    }

    pub(crate) fn video_codec_class() -> Result<&'static GlobalRef> {
        cached_class(&VIDEO_CODEC, VIDEO_CODEC_CLASS)
    }

    pub(crate) fn gallery_class() -> Result<&'static GlobalRef> {
        cached_class(&GALLERY, GALLERY_CLASS)
    }

    pub(crate) fn location_class() -> Result<&'static GlobalRef> {
        cached_class(&LOCATION, LOCATION_CLASS)
    }

    pub(crate) fn jni_env() -> Result<AttachGuard<'static>> {
        JAVA_VM
            .get()
            .ok_or_else(|| TwonlyError::Generic("Android Java VM is unavailable".into()))?
            .attach_current_thread()
            .map_err(|error| TwonlyError::Generic(error.to_string()))
    }

    pub(crate) fn schedule(descriptor_json: &str) -> Result<()> {
        let transfer = cached_class(&TRANSFER, TRANSFER_CLASS)?;
        let mut env = jni_env()?;
        let descriptor = env
            .new_string(descriptor_json)
            .map_err(|error| TwonlyError::Generic(error.to_string()))?;
        let descriptor_object = JObject::from(descriptor);
        let call = env
            .call_static_method(
                transfer,
                "schedule",
                "(Ljava/lang/String;)Z",
                &[JValue::Object(&descriptor_object)],
            )
            .and_then(|value| value.z());
        // A pending Java exception left on this thread would be raised as a
        // fatal error when the attachment is dropped, taking the process with
        // it. The scheduling failure is reported through `Result` instead.
        if env.exception_check().unwrap_or(false) {
            let _ = env.exception_describe();
            let _ = env.exception_clear();
        }
        if call.map_err(|error| TwonlyError::Generic(error.to_string()))? {
            Ok(())
        } else {
            Err(TwonlyError::Generic(
                "Android rejected the direct-media upload schedule".into(),
            ))
        }
    }
}

#[cfg(target_os = "android")]
pub(crate) use android::schedule;

#[cfg(not(any(target_os = "android", target_os = "ios")))]
pub(crate) fn schedule(_descriptor_json: &str) -> Result<()> {
    Err(TwonlyError::Generic(
        "native background transfer is only available on Android and iOS".into(),
    ))
}
