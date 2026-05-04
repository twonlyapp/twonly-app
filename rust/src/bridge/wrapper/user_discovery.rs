use crate::bridge::error::Result;
use crate::bridge::get_twonly_flutter;

pub struct FlutterUserDiscovery {}

impl FlutterUserDiscovery {
    pub async fn initialize_or_update(
        threshold: u8,
        user_id: i64,
        public_key: Vec<u8>,
        share_promotion: bool,
    ) -> Result<()> {
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
    }

    pub async fn get_current_version() -> Result<Vec<u8>> {
        Ok(get_twonly_flutter()?
            .user_discovery
            .get()
            .await
            .get_current_version()
            .await?)
    }

    pub async fn get_new_messages(
        contact_id: i64,
        received_version: &[u8],
    ) -> Result<Vec<Vec<u8>>> {
        Ok(get_twonly_flutter()?
            .user_discovery
            .get()
            .await
            .get_new_messages(contact_id, received_version)
            .await?)
    }

    pub async fn should_request_new_messages(
        contact_id: i64,
        version: &[u8],
    ) -> Result<Option<Vec<u8>>> {
        Ok(get_twonly_flutter()?
            .user_discovery
            .get()
            .await
            .should_request_new_messages(contact_id, version)
            .await?)
    }

    pub async fn handle_new_messages(
        contact_id: i64,
        public_key_verified_timestamp: Option<i64>,
        messages: Vec<Vec<u8>>,
    ) -> Result<()> {
        Ok(get_twonly_flutter()?
            .user_discovery
            .get()
            .await
            .handle_new_messages(contact_id, public_key_verified_timestamp, messages)
            .await?)
    }

    pub async fn update_verification_state_for_user(
        contact_id: i64,
        public_key_verified_timestamp: Option<i64>,
    ) -> Result<()> {
        Ok(get_twonly_flutter()?
            .user_discovery
            .get()
            .await
            .update_verification_state_for_user(contact_id, public_key_verified_timestamp)
            .await?)
    }
}
