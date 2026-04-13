use std::collections::HashMap;

use crate::user_discovery::error::Result;
use crate::user_discovery::UserID;

#[derive(Clone)]
pub struct OtherPromotion {
    pub promotion_id: u32,
    pub public_id: u64,
    pub from_contact_id: UserID,
    pub threshold: u8,
    pub announcement_share: Vec<u8>,
    pub public_key_verified_timestamp: Option<i64>,
}

#[derive(Clone, Hash, PartialEq, Eq)]
pub struct AnnouncedUser {
    pub user_id: UserID,
    pub public_key: Vec<u8>,
    pub public_id: u64,
}

pub trait UserDiscoveryStore {
    fn get_config(&self) -> Result<Vec<u8>>;
    fn update_config(&self, update: Vec<u8>) -> Result<()>;
    fn set_shares(&self, shares: Vec<Vec<u8>>) -> Result<()>;

    fn get_share_for_contact(&self, contact_id: UserID) -> Result<Vec<u8>>;

    fn push_own_promotion(
        &self,
        contact_id: UserID,
        version: u32,
        promotion: Vec<u8>,
    ) -> Result<()>;

    fn get_own_promotions_after_version(&self, version: u32) -> Result<Vec<Vec<u8>>>;

    fn store_other_promotion(&self, promotion: OtherPromotion) -> Result<()>;
    fn get_other_promotions_by_public_id(&self, public_id: u64) -> Vec<OtherPromotion>;

    fn get_announced_user_by_public_id(&self, public_id: u64) -> Result<Option<AnnouncedUser>>;

    fn push_new_user_relation(
        &self,
        from_contact_id: UserID,
        announced_user: AnnouncedUser,
        public_key_verified_timestamp: Option<i64>,
    ) -> Result<()>;

    fn get_all_announced_users(&self)
        -> Result<HashMap<AnnouncedUser, Vec<(UserID, Option<i64>)>>>;

    fn get_contact_version(&self, contact_id: UserID) -> Result<Option<Vec<u8>>>;
    fn set_contact_version(&self, contact_id: UserID, update: Vec<u8>) -> Result<()>;
}

pub trait UserDiscoveryUtils {
    fn sign_data(&self, input_data: &[u8]) -> Result<Vec<u8>>;
    fn verify_signature(&self, input_data: &[u8], pubkey: &[u8], signature: &[u8]) -> Result<bool>;
    fn verify_stored_pubkey(&self, from_contact_id: UserID, pubkey: &[u8]) -> Result<bool>;
}

#[cfg(test)]
pub(crate) mod tests {
    use crate::user_discovery::traits::UserDiscoveryUtils;

    #[derive(Default)]
    pub(crate) struct TestingUtils {}
    impl UserDiscoveryUtils for TestingUtils {
        fn sign_data(&self, _input_data: &[u8]) -> crate::user_discovery::error::Result<Vec<u8>> {
            Ok(vec![0; 64])
        }

        fn verify_signature(
            &self,
            _data: &[u8],
            _pubkey: &[u8],
            _signature: &[u8],
        ) -> crate::user_discovery::error::Result<bool> {
            Ok(true)
        }

        fn verify_stored_pubkey(
            &self,
            _from_contact_id: crate::user_discovery::UserID,
            _pubkey: &[u8],
        ) -> crate::user_discovery::error::Result<bool> {
            Ok(true)
        }
    }
}
