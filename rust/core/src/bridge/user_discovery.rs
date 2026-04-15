use protocols::user_discovery::error::{Result, UserDiscoveryError};
use protocols::user_discovery::traits::{AnnouncedUser, OtherPromotion, UserDiscoveryStore};
use protocols::user_discovery::UserID;
use std::collections::HashMap;

struct UserDiscoveryDatabaseStore {}

impl UserDiscoveryStore for UserDiscoveryDatabaseStore {
    fn get_config(&self) -> Result<Vec<u8>> {
        todo!()
    }

    fn update_config(&self, update: Vec<u8>) -> Result<()> {
        todo!()
    }

    fn set_shares(&self, shares: Vec<Vec<u8>>) -> Result<()> {
        todo!()
    }

    fn get_share_for_contact(&self, contact_id: UserID) -> Result<Vec<u8>> {
        todo!()
    }

    fn push_own_promotion(
        &self,
        contact_id: UserID,
        version: u32,
        promotion: Vec<u8>,
    ) -> Result<()> {
        todo!()
    }

    fn get_own_promotions_after_version(&self, version: u32) -> Result<Vec<Vec<u8>>> {
        todo!()
    }

    fn store_other_promotion(&self, promotion: OtherPromotion) -> Result<()> {
        todo!()
    }

    fn get_other_promotions_by_public_id(&self, public_id: u64) -> Vec<OtherPromotion> {
        todo!()
    }

    fn get_announced_user_by_public_id(&self, public_id: u64) -> Result<Option<AnnouncedUser>> {
        todo!()
    }

    fn push_new_user_relation(
        &self,
        from_contact_id: UserID,
        announced_user: AnnouncedUser,
        public_key_verified_timestamp: Option<i64>,
    ) -> Result<()> {
        todo!()
    }

    fn get_all_announced_users(
        &self,
    ) -> Result<HashMap<AnnouncedUser, Vec<(UserID, Option<i64>)>>> {
        todo!()
    }

    fn get_contact_version(&self, contact_id: UserID) -> Result<Option<Vec<u8>>> {
        todo!()
    }

    fn set_contact_version(&self, contact_id: UserID, update: Vec<u8>) -> Result<()> {
        todo!()
    }
}
