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
//!   process under a `UIApplication` background task assertion, whose lifetime
//!   is owned by the foreground database operation.

/// How this platform is keeping a preparation alive.

pub(crate) enum Preparation {
    /// The OS owns a job that runs the preparation itself; the caller must not
    /// start one.
    #[cfg_attr(not(target_os = "android"), allow(dead_code))]
    Scheduled,
    /// The preparation belongs to this process and inherits its caller's
    /// admitted operation through completion and cleanup.
    InProcess,
}

/// Asks the platform to protect the preparation of `media_id`.
///
/// In-process preparation inherits the admitted database operation. It is
/// deferred if no owner exists; durable media rows are resumed later.

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

    let _ = media_id;

    Preparation::InProcess
}

#[cfg(target_os = "android")]

mod android {

    use crate::error::{Result, TwonlyError};
    use crate::native::transfer::android::with_env;
    use jni::objects::{JObject, JValue};

    pub(super) fn schedule(media_id: &str) -> Result<()> {
        let prepare = crate::native::transfer::android::prepare_class()?;

        with_env(|env| {
            let media_id = jni::objects::JString::from_str(env, media_id)
                .map_err(|error| TwonlyError::Generic(error.to_string()))?;

            let media_id = JObject::from(media_id);

            let call = env
                .call_static_method(
                    prepare,
                    jni::jni_str!("schedule"),
                    jni::jni_sig!("(Ljava/lang/String;)Z"),
                    &[JValue::Object(&media_id)],
                )
                .and_then(|value| value.z());

            // A pending Java exception would be raised as a fatal error when this
            // thread next enters the VM, taking the process with it.
            if env.exception_check() {
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
        })
    }
}
