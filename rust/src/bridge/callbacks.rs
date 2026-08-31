/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

mod macros;
use flutter_rust_bridge::DartFnFuture;

use crate::callback_generator;
use crate::error::{Result, TwonlyError};
use std::sync::Arc;

use std::collections::HashMap;

tokio::task_local! {
    pub(crate) static CURRENT_CALLBACK_ID: u32;
}

pub(crate) static FLUTTER_CALLBACKS: std::sync::RwLock<Option<HashMap<u32, FlutterCallbacks>>> =
    std::sync::RwLock::new(None);

// This will also generate the function init_flutter_callbacks which MUST be called from Flutter to initialize the callbacks
callback_generator! {
    FlutterCallbacks {
        Api api {
            verification_succeeded: (i64) => (),
            user_config_changed: (crate::user_config::UserConfig) => ()
        }
    }
}

pub(crate) fn get_callbacks() -> Result<FlutterCallbacks> {
    let caller_opt = CURRENT_CALLBACK_ID.try_with(|&c| c).ok();

    let lock = FLUTTER_CALLBACKS.read().unwrap();
    let map = lock
        .as_ref()
        .ok_or(TwonlyError::MissingCallbackInitialization)?;

    if let Some(id) = caller_opt {
        if let Some(cb) = map.get(&id) {
            return Ok(cb.clone());
        }
    }

    // Incoming API events are not always associated with the Flutter call
    // that started their work. Preserve the existing fallback for those API
    // callbacks; logging no longer depends on this path.
    if let Some((_, callbacks)) = map.iter().next() {
        tracing::warn!("FlutterCallbacks fallback used: No CURRENT_CALLBACK_ID scope was found, or the ID was missing from the map. Using an arbitrary callback. This may lead to race conditions if multiple isolates are active.");
        return Ok(callbacks.clone());
    }

    Err(TwonlyError::MissingCallbackInitialization)
}
