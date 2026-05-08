#![allow(unexpected_cfgs)]
pub mod callbacks;
pub mod wrapper;

use std::path::Path;
use std::sync::Arc;

use crate::bridge::callbacks::user_discovery::{
    UserDiscoveryStoreFlutter, UserDiscoveryUtilsFlutter,
};
use crate::context::Context;
use crate::database::Database;
use crate::error::Result;
use crate::error::TwonlyError;
use crate::secure_storage::SecureStorage;
use crate::utils::Shared;
use flutter_rust_bridge::frb;
use protocols::user_discovery::UserDiscovery;

pub use protocols::user_discovery::traits::AnnouncedUser;
pub use protocols::user_discovery::traits::OtherPromotion;

pub struct InitConfig {
    pub database_dir: String,
    pub data_dir: String,
}

#[frb(mirror(OtherPromotion))]
pub struct _OtherPromotion {
    pub promotion_id: u32,
    pub public_id: i64,
    pub from_contact_id: i64,
    pub threshold: u8,
    pub announcement_share: Vec<u8>,
    pub public_key_verified_timestamp: Option<i64>,
}

#[frb(mirror(AnnouncedUser))]
pub struct _AnnouncedUser {
    pub user_id: i64,
    pub public_key: Vec<u8>,
    pub public_id: i64,
}

pub(crate) struct TwonlyFlutter {
    #[allow(dead_code)]
    pub(crate) config: InitConfig,
    pub(crate) user_discovery:
        Shared<UserDiscovery<UserDiscoveryStoreFlutter, UserDiscoveryUtilsFlutter>>,
    pub(crate) rust_db: Arc<Database>,
    pub(crate) secure_storage: SecureStorage,
}

pub(super) fn get_twonly_flutter() -> Result<&'static TwonlyFlutter> {
    let ctx = Context::get_static()?;
    if let Context::Flutter(twonly) = ctx {
        return Ok(twonly);
    } else {
        return Err(TwonlyError::Initialization);
    }
}

pub async fn initialize_twonly_flutter(config: InitConfig) -> Result<()> {
    Context::init_flutter(config).await?;
    Ok(())
}
