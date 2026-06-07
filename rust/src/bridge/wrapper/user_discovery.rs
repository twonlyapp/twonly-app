use crate::bridge::callbacks::CURRENT_CALLBACK_ID;
use crate::bridge::get_twonly_flutter;
use crate::error::Result;

pub struct FlutterUserDiscovery {}

impl FlutterUserDiscovery {
    pub async fn initialize_or_update(
        callback_id: u32,
        threshold: u8,
        user_id: i64,
        public_key: Vec<u8>,
        share_promotion: bool,
    ) -> Result<()> {
        CURRENT_CALLBACK_ID.scope(callback_id, async move {
            tracing::info!("Rust bridge: initialize_or_update started");
            let twonly = get_twonly_flutter()?;
            tracing::info!("Rust bridge: getting user_discovery lock");
            let user_discovery = twonly.user_discovery.get().await;
            tracing::info!("Rust bridge: calling initialize_or_update on protocols");
            let res = user_discovery
                .initialize_or_update(threshold, user_id, public_key, share_promotion)
                .await;
            tracing::info!("Rust bridge: initialize_or_update on protocols finished");
            Ok(res?)
        }).await
    }

    pub async fn get_current_version(callback_id: u32) -> Result<Vec<u8>> {
        CURRENT_CALLBACK_ID.scope(callback_id, async move {
            Ok(get_twonly_flutter()?
                .user_discovery
                .get()
                .await
                .get_current_version()
                .await?)
        }).await
    }

    pub async fn get_new_messages(
        callback_id: u32,
        contact_id: i64,
        received_version: &[u8],
    ) -> Result<Vec<Vec<u8>>> {
        CURRENT_CALLBACK_ID.scope(callback_id, async move {
            Ok(get_twonly_flutter()?
                .user_discovery
                .get()
                .await
                .get_new_messages(contact_id, received_version)
                .await?)
        }).await
    }

    pub async fn should_request_new_messages(
        callback_id: u32,
        contact_id: i64,
        version: &[u8],
    ) -> Result<Option<Vec<u8>>> {
        CURRENT_CALLBACK_ID.scope(callback_id, async move {
            Ok(get_twonly_flutter()?
                .user_discovery
                .get()
                .await
                .should_request_new_messages(contact_id, version)
                .await?)
        }).await
    }

    pub async fn handle_new_messages(
        callback_id: u32,
        contact_id: i64,
        public_key_verified_timestamp: Option<i64>,
        messages: Vec<Vec<u8>>,
    ) -> Result<()> {
        CURRENT_CALLBACK_ID.scope(callback_id, async move {
            Ok(get_twonly_flutter()?
                .user_discovery
                .get()
                .await
                .handle_new_messages(contact_id, public_key_verified_timestamp, messages)
                .await?)
        }).await
    }

    pub async fn update_verification_state_for_user(
        callback_id: u32,
        contact_id: i64,
        public_key_verified_timestamp: Option<i64>,
    ) -> Result<()> {
        CURRENT_CALLBACK_ID.scope(callback_id, async move {
            Ok(get_twonly_flutter()?
                .user_discovery
                .get()
                .await
                .update_verification_state_for_user(contact_id, public_key_verified_timestamp)
                .await?)
        }).await
    }
}
