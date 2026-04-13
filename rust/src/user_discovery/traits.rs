use crate::user_discovery::error::Result;
use crate::user_discovery::UserID;

pub trait UserDiscoveryStore {
    fn get_config(&self) -> Result<Vec<u8>>;
    fn update_config(&self, update: Vec<u8>) -> Result<()>;
    fn set_shares(&self, shares: Vec<Vec<u8>>) -> Result<()>;

    fn get_share_for_contact(&self, contact_id: UserID) -> Result<Vec<u8>>;

    fn push_promotion(&self, version: u32, promotion: Vec<u8>) -> Result<()>;
    fn get_promotions_after_version(&self, version: u32) -> Result<Vec<Vec<u8>>>;

    fn get_contact_version(&self, contact_id: UserID) -> Result<Option<Vec<u8>>>;
    fn set_contact_version(&self, contact_id: UserID, update: Vec<u8>) -> Result<()>;
}

pub trait UserDiscoveryUtils {
    fn sign_data(&self, input_data: Vec<u8>) -> Result<Vec<u8>>;
    fn verify_pubkey_and_signature_from(
        &self,
        from_contact_id: UserID,
        data: Vec<u8>,
        pubkey: Vec<u8>,
        signature: Vec<u8>,
    ) -> Result<bool>;
}

#[cfg(test)]
pub(crate) mod tests {
    use crate::user_discovery::traits::UserDiscoveryUtils;

    #[derive(Default)]
    pub(crate) struct TestingUtils {}
    impl UserDiscoveryUtils for TestingUtils {
        fn sign_data(&self, _input_data: Vec<u8>) -> crate::user_discovery::error::Result<Vec<u8>> {
            Ok(vec![0; 64])
        }

        fn verify_pubkey_and_signature_from(
            &self,
            from_contact_id: crate::user_discovery::UserID,
            data: Vec<u8>,
            pubkey: Vec<u8>,
            signature: Vec<u8>,
        ) -> crate::user_discovery::error::Result<bool> {
            Ok(true)
        }
    }
}
