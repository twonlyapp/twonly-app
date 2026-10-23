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

// This will also generate the function init_flutter_callbacks which MUST be
// called from Flutter to initialize the callbacks
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
        return map
            .get(&id)
            .cloned()
            .ok_or(TwonlyError::MissingCallbackInitialization);
    }

    // Incoming API events are not always associated with the Flutter call
    // that started their work. Preserve the existing fallback for those API
    // callbacks. Initialization retains only the current isolate; never choose
    // arbitrarily if another registration path leaves an ambiguous map.
    if map.len() == 1 {
        return Ok(map.values().next().unwrap().clone());
    }

    Err(TwonlyError::MissingCallbackInitialization)
}
