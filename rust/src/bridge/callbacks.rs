/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

pub(crate) mod log;
mod macros;
use flutter_rust_bridge::DartFnFuture;

use crate::error::{Result, TwonlyError};
use crate::{callback_generator, frb_generated::StreamSink};
use std::sync::Arc;

use std::collections::HashMap;

tokio::task_local! {
    pub(crate) static CURRENT_CALLBACK_ID: u32;
}

pub(crate) static FLUTTER_CALLBACKS: std::sync::RwLock<Option<HashMap<u32, FlutterCallbacks>>> =
    std::sync::RwLock::new(None);

#[derive(Clone, Debug)]
pub struct LegacySignalDecryptResult {
    /// Serialized `EncryptedContent` when legacy Signal decryption succeeded.
    pub plaintext: Option<Vec<u8>>,
    /// Serialized protobuf enum value for `DecryptionErrorMessage.Type`.
    pub decryption_error_type: Option<i32>,
}

#[derive(Clone, Debug)]
pub struct LegacySignalEncryptResult {
    pub ciphertext: Vec<u8>,
    /// `Message.Type.CIPHERTEXT` or `Message.Type.PREKEY_BUNDLE`.
    pub message_type: i32,
}

#[derive(Clone, Debug)]
pub struct LegacySignalPreKey {
    pub id: i64,
    pub public_key: Vec<u8>,
}

// This will also generate the function init_flutter_callbacks which MUST be called from Flutter to initialize the callbacks
callback_generator! {
    FlutterCallbacks {
        Logging logging {
            get_stream_sink: () => StreamSink<String>
        },
        LegacySignal legacy_signal {
            decrypt: (i64, Vec<u8>, i32) => LegacySignalDecryptResult,
            encrypt: (i64, Vec<u8>) => Option<LegacySignalEncryptResult>,
            generate_prekeys: () => Vec<LegacySignalPreKey>
        },
        Api api {
            resync_signal_session: (i64) => (),
            push_key_requested: (i64) => (),
            group_membership_error: (i64, String, String) => (),
            media_action: (String, String, i64, String) => (),
            verification_proof: (i64, Vec<u8>) => (),
            create_push_data: (i64, Option<String>, Vec<u8>, i32) => Option<Vec<u8>>,
            create_push_avatars: (i64) => (),
            recovery_changed: () => (),
            media_received: (String, i64) => (),
            group_state_refresh: (String, bool) => ()
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

    // Fallback: if not in a scoped tokio task or if the specific callback_id isn't found,
    // we pick the first available callbacks from the map. This gracefully handles
    // tracing initialization which happens outside of any scoped task.
    if let Some((_, cb)) = map.iter().next() {
        tracing::error!("FlutterCallbacks fallback used: No CURRENT_CALLBACK_ID scope was found, or the ID was missing from the map. Using an arbitrary callback. This may lead to race conditions if multiple isolates are active.");
        return Ok(cb.clone());
    }

    Err(TwonlyError::MissingCallbackInitialization)
}
