use protocols::user_discovery::error::Result;
use protocols::user_discovery::traits::UserDiscoveryUtils;

pub(crate) struct UserDiscoveryUtilsFlutter {}

impl UserDiscoveryUtils for UserDiscoveryUtilsFlutter {
    async fn sign_data(&self, input_data: &[u8]) -> Result<Vec<u8>> {
        todo!()
    }

    async fn verify_signature(
        &self,
        input_data: &[u8],
        pubkey: &[u8],
        signature: &[u8],
    ) -> Result<bool> {
        todo!()
    }

    async fn verify_stored_pubkey(
        &self,
        from_contact_id: protocols::user_discovery::UserID,
        pubkey: &[u8],
    ) -> Result<bool> {
        todo!()
    }
}
