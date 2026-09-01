/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! Keeping media preparation alive when the app is not.
//!
//! Everything between the send button and [`crate::native::transfer::schedule`]
//! — transcoding, encryption, and one Signal ratchet step per recipient — runs
//! in this process. Once the transfer is scheduled the OS owns it, but until
//! then a process death strands the send until the next launch. Each platform
//! protects that window differently:
//!
//! * Android runs the preparation inside a `WorkManager` job, which survives
//!   the task being swiped away and is re-run after a reboot.
//! * iOS cannot outlive a force quit at all, so the preparation stays in this
//!   process under a `UIApplication` background task assertion, which buys the
//!   roughly thirty seconds that a backgrounded app is still allowed to run.

/// How this platform is keeping a preparation alive.
pub(crate) enum Preparation {
    /// The OS owns a job that runs the preparation itself; the caller must not
    /// start one.
    #[cfg_attr(not(target_os = "android"), allow(dead_code))]
    Scheduled,
    /// The preparation belongs to this process. The caller runs it and holds
    /// the guard for as long as it does.
    InProcess(Guard),
}

/// Releases the platform's background execution assertion when dropped.
pub(crate) struct Guard {
    #[cfg_attr(not(target_os = "ios"), allow(dead_code))]
    assertion: Option<u64>,
}

impl Guard {
    /// A guard for a platform that offers no assertion to take.
    #[cfg_attr(target_os = "ios", allow(dead_code))]
    pub(crate) fn unprotected() -> Self {
        Self { assertion: None }
    }
}

impl Drop for Guard {
    fn drop(&mut self) {
        #[cfg(target_os = "ios")]
        if let Some(assertion) = self.assertion.take() {
            ios::end_background_task(assertion);
        }
    }
}

/// Asks the platform to protect the preparation of `media_id`.
///
/// Never fails: a platform that cannot protect the work still has to prepare
/// it, and an interrupted preparation is picked up by the next maintenance
/// pass. The reason is logged so a missing native hook is visible.
pub(crate) fn begin(media_id: &str) -> Preparation {
    #[cfg(target_os = "android")]
    {
        match android::schedule(media_id) {
            Ok(()) => return Preparation::Scheduled,
            Err(error) => {
                tracing::warn!(media_id, %error, "no WorkManager preparation job; preparing in process");
            }
        }
    }
    #[cfg(target_os = "ios")]
    {
        let _ = media_id;
        return Preparation::InProcess(Guard {
            assertion: ios::begin_background_task(),
        });
    }
    #[cfg(not(target_os = "ios"))]
    {
        let _ = media_id;
        Preparation::InProcess(Guard::unprotected())
    }
}

#[cfg(target_os = "android")]
mod android {
    use crate::error::{Result, TwonlyError};
    use crate::native::transfer::android::jni_env;
    use jni::objects::{JObject, JValue};

    pub(super) fn schedule(media_id: &str) -> Result<()> {
        let prepare = crate::native::transfer::android::prepare_class()?;
        let mut env = jni_env()?;
        let media_id = env
            .new_string(media_id)
            .map_err(|error| TwonlyError::Generic(error.to_string()))?;
        let media_id = JObject::from(media_id);
        let call = env
            .call_static_method(
                prepare,
                "schedule",
                "(Ljava/lang/String;)Z",
                &[JValue::Object(&media_id)],
            )
            .and_then(|value| value.z());
        // A pending Java exception would be raised as a fatal error when this
        // thread next enters the VM, taking the process with it.
        if env.exception_check().unwrap_or(false) {
            let _ = env.exception_describe();
            let _ = env.exception_clear();
        }
        if call.map_err(|error| TwonlyError::Generic(error.to_string()))? {
            Ok(())
        } else {
            Err(TwonlyError::Generic(
                "Android rejected the media preparation job".into(),
            ))
        }
    }
}

#[cfg(target_os = "ios")]
mod ios {
    use std::os::raw::c_char;

    type BeginBackgroundTask = unsafe extern "C" fn() -> u64;
    type EndBackgroundTask = unsafe extern "C" fn(u64);

    fn symbol(name: &std::ffi::CStr) -> Option<*mut std::ffi::c_void> {
        // The implementation lives in the app executable, so it is resolved at
        // runtime rather than being required when the cdylib is linked.
        let pointer = unsafe { libc::dlsym(libc::RTLD_DEFAULT, name.as_ptr().cast::<c_char>()) };
        (!pointer.is_null()).then_some(pointer)
    }

    pub(super) fn begin_background_task() -> Option<u64> {
        let callback = symbol(c"twonly_begin_background_task")?;
        // SAFETY: the Swift @_cdecl declaration has this exact C ABI signature.
        let callback: BeginBackgroundTask = unsafe { std::mem::transmute(callback) };
        let identifier = unsafe { callback() };
        // UIBackgroundTaskInvalid is reported as zero.
        (identifier != 0).then_some(identifier)
    }

    pub(super) fn end_background_task(identifier: u64) {
        let Some(callback) = symbol(c"twonly_end_background_task") else {
            return;
        };
        // SAFETY: the Swift @_cdecl declaration has this exact C ABI signature.
        let callback: EndBackgroundTask = unsafe { std::mem::transmute(callback) };
        unsafe { callback(identifier) };
    }
}
