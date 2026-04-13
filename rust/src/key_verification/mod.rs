use crate::key_verification::traits::KeyVerificationStore;

pub mod traits;

pub struct KeyVerificationConfig {
    /// The link prefix for the qr code which should be registered as a deeplink on Android and a universal link on iOS
    deeplink_prefix: String,
}

struct KeyVerification<Store: KeyVerificationStore> {
    store: Store,
    config: KeyVerificationConfig,
}

impl<Store: KeyVerificationStore> KeyVerification<Store> {
    pub fn new(store: Store, config: KeyVerificationConfig) -> KeyVerification<Store> {
        Self { store, config }
    }

    /// Generates the a string which should be displayed in the UI so others can scan it.
    pub fn generate_qr_code_data() -> String {
        todo!();
    }

    /// Generates the a string which should be displayed in the UI so others can scan it.
    pub fn handle_qr_code_data() -> String {
        todo!();
    }
}
