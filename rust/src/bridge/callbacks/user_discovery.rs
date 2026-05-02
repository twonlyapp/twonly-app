use crate::bridge::callbacks::get_callbacks;
use crate::bridge::error::TwonlyError;
use crate::bridge::get_twonly_flutter;
use protocols::user_discovery::error::{Result, UserDiscoveryError};
use protocols::user_discovery::traits::UserDiscoveryUtils;
use protocols::user_discovery::traits::{AnnouncedUser, OtherPromotion, UserDiscoveryStore};
use std::collections::HashMap;
use std::path::PathBuf;

#[derive(Clone)]
pub(crate) struct UserDiscoveryStoreFlutter {}
pub(crate) struct UserDiscoveryUtilsFlutter {}

impl UserDiscoveryUtils for UserDiscoveryUtilsFlutter {
    async fn sign_data(&self, input_data: &[u8]) -> Result<Vec<u8>> {
        match (get_callbacks()?.user_discovery.sign_data)(input_data.to_vec()).await {
            Some(signature) => Ok(signature),
            None => Err(TwonlyError::DartError)?,
        }
    }

    async fn verify_signature(
        &self,
        input_data: &[u8],
        pubkey: &[u8],
        signature: &[u8],
    ) -> Result<bool> {
        Ok((get_callbacks()?.user_discovery.verify_signature)(
            input_data.to_vec(),
            pubkey.to_vec(),
            signature.to_vec(),
        )
        .await)
    }

    async fn verify_stored_pubkey(&self, from_contact_id: i64, pubkey: &[u8]) -> Result<bool> {
        Ok(
            (get_callbacks()?.user_discovery.verify_stored_pubkey)(
                from_contact_id,
                pubkey.to_vec(),
            )
            .await,
        )
    }
}

impl UserDiscoveryStore for UserDiscoveryStoreFlutter {
    async fn get_config(&self) -> Result<String> {
        let ws = get_twonly_flutter().unwrap();
        let config_path =
            PathBuf::from(&ws.config.data_directory).join("user_discovery_config.json");

        if !config_path.is_file() {
            return Err(UserDiscoveryError::NotInitialized);
        }

        Ok(std::fs::read_to_string(&config_path)?)
    }

    async fn update_config(&self, update: String) -> Result<()> {
        tracing::debug!("Updating configuration file.");
        let ws = get_twonly_flutter().unwrap();
        let config_path =
            PathBuf::from(&ws.config.data_directory).join("user_discovery_config.json");
        std::fs::write(config_path, &update)?;
        Ok(())
    }

    async fn set_shares(&self, shares: Vec<Vec<u8>>) -> Result<()> {
        (get_callbacks()?.user_discovery.set_shares)(shares).await;
        Ok(())
    }

    async fn get_share_for_contact(&self, contact_id: i64) -> Result<Vec<u8>> {
        match (get_callbacks()?.user_discovery.get_share_for_contact)(contact_id).await {
            Some(share) => Ok(share),
            None => Err(UserDiscoveryError::NoSharesLeft),
        }
    }

    async fn push_own_promotion_and_clear_old_version(
        &self,
        contact_id: i64,
        version: u32,
        promotion: Vec<u8>,
    ) -> Result<()> {
        (get_callbacks()?
            .user_discovery
            .push_own_promotion_and_clear_old_version)(contact_id, version as i64, promotion)
        .await
        .then_some(())
        .ok_or(TwonlyError::DartError.into())
    }

    async fn get_own_promotions_after_version(&self, version: u32) -> Result<Vec<Vec<u8>>> {
        match (get_callbacks()?
            .user_discovery
            .get_own_promotions_after_version)(version as i64)
        .await
        {
            Some(share) => Ok(share),
            None => Err(TwonlyError::DartError)?,
        }
    }

    async fn store_other_promotion(&self, promotion: OtherPromotion) -> Result<()> {
        (get_callbacks()?.user_discovery.store_other_promotion)(promotion)
            .await
            .then_some(())
            .ok_or(TwonlyError::DartError.into())
    }

    async fn get_other_promotions_by_public_id(
        &self,
        public_id: i64,
    ) -> Result<Vec<OtherPromotion>> {
        match (get_callbacks()?
            .user_discovery
            .get_other_promotions_by_public_id)(public_id)
        .await
        {
            Some(promotions) => Ok(promotions),
            None => Err(TwonlyError::DartError)?,
        }
    }

    async fn get_announced_user_by_public_id(
        &self,
        public_id: i64,
    ) -> Result<Option<AnnouncedUser>> {
        Ok((get_callbacks()?
            .user_discovery
            .get_announced_user_by_public_id)(public_id)
        .await)
    }

    async fn push_new_user_relation(
        &self,
        from_contact_id: i64,
        announced_user: AnnouncedUser,
        public_key_verified_timestamp: Option<i64>,
    ) -> Result<()> {
        (get_callbacks()?.user_discovery.push_new_user_relation)(
            from_contact_id,
            announced_user,
            public_key_verified_timestamp,
        )
        .await
        .then_some(())
        .ok_or(TwonlyError::DartError.into())
    }

    async fn get_all_announced_users(
        &self,
    ) -> Result<HashMap<AnnouncedUser, Vec<(i64, Option<i64>)>>> {
        // This is never called from the RUST code.
        Err(TwonlyError::DartError)?
    }

    async fn get_contact_version(&self, contact_id: i64) -> Result<Option<Vec<u8>>> {
        Ok((get_callbacks()?.user_discovery.get_contact_version)(contact_id).await)
    }

    async fn set_contact_version(&self, contact_id: i64, update: Vec<u8>) -> Result<()> {
        (get_callbacks()?.user_discovery.set_contact_version)(contact_id, update)
            .await
            .then_some(())
            .ok_or(TwonlyError::DartError.into())
    }

    async fn get_contact_promotion(&self, contact_id: i64) -> Result<Option<Vec<u8>>> {
        Ok((get_callbacks()?.user_discovery.get_contact_promotion)(contact_id).await)
    }
}
