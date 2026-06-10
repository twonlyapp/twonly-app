pub(crate) mod log;
mod macros;
pub(crate) mod user_discovery;

use crate::user_discovery::traits::{AnnouncedUser, OtherPromotion};
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

// This will also generate the function init_flutter_callbacks which MUST be called from Flutter to initialize the callbacks
callback_generator! {
    FlutterCallbacks {
        Logging logging {
            get_stream_sink: () => StreamSink<String>
        },
        UserDiscoveryCallbacks user_discovery {
            // UserDiscoveryUtils
            sign_data: (Vec<u8>) => Option<Vec<u8>>,
            verify_signature: (Vec<u8>, Vec<u8>, Vec<u8>) => bool,
            verify_stored_pubkey: (i64, Vec<u8>) => bool,

            // UserDiscoveryStore
            set_shares: (Vec<Vec<u8>>) => bool,
            get_share_for_contact: (i64) => Option<Vec<u8>>,
            push_own_promotion_and_clear_old_version: (i64, i64, Vec<u8>) => bool,
            get_own_promotions_after_version: (i64) => Option<Vec<Vec<u8>>>,
            store_other_promotion: (OtherPromotion) => bool,
            get_other_promotions_by_public_id: (i64) => Option<Vec<OtherPromotion>>,
            get_announced_user_by_public_id: (i64) => Option<AnnouncedUser>,
            get_contact_version: (i64) => Option<Vec<u8>>,
            set_contact_version: (i64, Vec<u8>) => bool,
            push_new_user_relation: (i64, AnnouncedUser, Option<i64>) => bool,
            get_contact_promotion: (i64) => Option<Vec<u8>>
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
