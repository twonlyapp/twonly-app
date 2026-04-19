use std::collections::HashMap;

use crate::user_discovery::error::Result;
use crate::user_discovery::UserID;
use std::future::Future;

#[derive(Clone, sqlx::FromRow)]
pub struct OtherPromotion {
    pub promotion_id: u32,
    pub public_id: i64,
    pub from_contact_id: UserID,
    pub threshold: u8,
    pub announcement_share: Vec<u8>,
    pub public_key_verified_timestamp: Option<i64>,
}

#[derive(Clone, Hash, PartialEq, Eq)]
pub struct AnnouncedUser {
    pub user_id: UserID,
    pub public_key: Vec<u8>,
    pub public_id: i64,
}

pub trait UserDiscoveryStore {
    fn get_config(&self) -> impl Future<Output = Result<String>> + Send;
    fn update_config(&self, update: String) -> impl Future<Output = Result<()>> + Send;
    fn set_shares(&self, shares: Vec<Vec<u8>>) -> impl Future<Output = Result<()>> + Send;

    fn get_share_for_contact(
        &self,
        contact_id: UserID,
    ) -> impl Future<Output = Result<Vec<u8>>> + Send;

    fn push_own_promotion(
        &self,
        contact_id: UserID,
        version: u32,
        promotion: Vec<u8>,
    ) -> impl Future<Output = Result<()>> + Send;

    fn get_own_promotions_after_version(
        &self,
        version: u32,
    ) -> impl Future<Output = Result<Vec<Vec<u8>>>> + Send;

    fn store_other_promotion(
        &self,
        promotion: OtherPromotion,
    ) -> impl Future<Output = Result<()>> + Send;
    fn get_other_promotions_by_public_id(
        &self,
        public_id: i64,
    ) -> impl Future<Output = Result<Vec<OtherPromotion>>> + Send;

    fn get_announced_user_by_public_id(
        &self,
        public_id: i64,
    ) -> impl Future<Output = Result<Option<AnnouncedUser>>> + Send;

    fn push_new_user_relation(
        &self,
        from_contact_id: UserID,
        announced_user: AnnouncedUser,
        public_key_verified_timestamp: Option<i64>,
    ) -> impl Future<Output = Result<()>> + Send;

    fn get_all_announced_users(
        &self,
    ) -> impl Future<Output = Result<HashMap<AnnouncedUser, Vec<(UserID, Option<i64>)>>>> + Send;

    fn get_contact_version(
        &self,
        contact_id: UserID,
    ) -> impl Future<Output = Result<Option<Vec<u8>>>> + Send;
    fn set_contact_version(
        &self,
        contact_id: UserID,
        update: Vec<u8>,
    ) -> impl Future<Output = Result<()>> + Send;
}

pub trait UserDiscoveryUtils {
    fn sign_data(&self, input_data: &[u8]) -> impl Future<Output = Result<Vec<u8>>> + Send;
    fn verify_signature(
        &self,
        input_data: &[u8],
        pubkey: &[u8],
        signature: &[u8],
    ) -> impl Future<Output = Result<bool>> + Send;
    /// In case the the user does not exists yet return false.
    /// If this happens this should trigger an error, as this functions is only when a message was received from this user...
    /// This is used to verify that the share of the promotions contains the same public key and the user is not secretly announcing a different one
    fn verify_stored_pubkey(
        &self,
        from_contact_id: UserID,
        pubkey: &[u8],
    ) -> impl Future<Output = Result<bool>> + Send;
}

pub(crate) mod tests {
    use crate::user_discovery::traits::UserDiscoveryUtils;

    #[derive(Default)]
    pub(crate) struct TestingUtils {}
    impl UserDiscoveryUtils for TestingUtils {
        async fn sign_data(
            &self,
            _input_data: &[u8],
        ) -> crate::user_discovery::error::Result<Vec<u8>> {
            Ok(vec![0; 64])
        }

        async fn verify_signature(
            &self,
            _data: &[u8],
            _pubkey: &[u8],
            _signature: &[u8],
        ) -> crate::user_discovery::error::Result<bool> {
            Ok(true)
        }

        async fn verify_stored_pubkey(
            &self,
            _from_contact_id: crate::user_discovery::UserID,
            _pubkey: &[u8],
        ) -> crate::user_discovery::error::Result<bool> {
            Ok(true)
        }
    }
}
