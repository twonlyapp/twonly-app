pub(crate) mod log;
mod macros;
pub(crate) mod user_discovery;

use flutter_rust_bridge::DartFnFuture;
use protocols::user_discovery::traits::{AnnouncedUser, OtherPromotion};

use super::error::Result;
use crate::{callback_generator, frb_generated::StreamSink};
use std::sync::{Arc, OnceLock};

use crate::bridge::error::TwonlyError;

static FLUTTER_CALLBACKS: OnceLock<FlutterCallbacks> = OnceLock::new();

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
        }
    }
}

pub(crate) fn get_callbacks() -> Result<&'static FlutterCallbacks> {
    FLUTTER_CALLBACKS
        .get()
        .ok_or(TwonlyError::MissingCallbackInitialization)
}
