use crate::bridge::error::Result;
use crate::bridge::get_twonly_flutter;

pub struct FlutterUserDiscovery {}

impl FlutterUserDiscovery {
    pub async fn initialize_or_update(
        threshold: u8,
        user_id: i64,
        public_key: Vec<u8>,
    ) -> Result<()> {
        Ok(get_twonly_flutter()?
            .user_discovery
            .get()
            .await
            .initialize_or_update(threshold, user_id, public_key)
            .await?)
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

    pub async fn should_request_new_messages(contact_id: i64, version: &[u8]) -> Result<bool> {
        Ok(get_twonly_flutter()?
            .user_discovery
            .get()
            .await
            .should_request_new_messages(contact_id, version)
            .await?)
    }

    pub async fn handle_user_discovery_messages(
        contact_id: i64,
        messages: Vec<Vec<u8>>,
    ) -> Result<()> {
        Ok(get_twonly_flutter()?
            .user_discovery
            .get()
            .await
            .handle_user_discovery_messages(contact_id, messages)
            .await?)
    }
}
