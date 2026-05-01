#![allow(unexpected_cfgs)]
pub mod callbacks;
pub mod error;
pub mod log;
pub mod wrapper;

use crate::bridge::callbacks::user_discovery::{
    UserDiscoveryStoreFlutter, UserDiscoveryUtilsFlutter,
};
use crate::bridge::log::init_tracing;
use crate::utils::Shared;
use error::Result;
use error::TwonlyError;
use flutter_rust_bridge::frb;
use protocols::user_discovery::UserDiscovery;
use std::path::PathBuf;
use tokio::sync::OnceCell;

pub use protocols::user_discovery::traits::AnnouncedUser;
pub use protocols::user_discovery::traits::OtherPromotion;

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

pub struct TwonlyConfig {
    pub database_path: String,
    pub data_directory: String,
}

pub(crate) struct TwonlyFlutter {
    #[allow(dead_code)]
    pub(crate) config: TwonlyConfig,
    // /// Rust runs in the same process as drift, the database can only be opened in readonly mode
    // pub(crate) twonly_db_readonly: Arc<Database>,
    pub(crate) user_discovery:
        Shared<UserDiscovery<UserDiscoveryStoreFlutter, UserDiscoveryUtilsFlutter>>,
}

static GLOBAL_TWONLY: OnceCell<TwonlyFlutter> = OnceCell::const_new();

pub(super) fn get_twonly_flutter() -> Result<&'static TwonlyFlutter> {
    GLOBAL_TWONLY.get().ok_or(TwonlyError::Initialization)
}

pub async fn initialize_twonly_flutter(config: TwonlyConfig) -> Result<()> {
    let log_dir = PathBuf::from(&config.data_directory).join("log");
    init_tracing(&log_dir, true).await;
    tracing::info!("Initialized twonly workspace.");
    let twonly_res: Result<&'static TwonlyFlutter> = GLOBAL_TWONLY
        .get_or_try_init(|| async {
            // let database_dir = PathBuf::from(&config.database_path.clone());
            // let Some(rust_db_path) = database_dir.parent() else {
            //     return Err(TwonlyError::DatabaseNotFound);
            // };
            // let rust_db_path = rust_db_path.join("rust_db.sqlite").display().to_string();

            // let twonly_db_readonly = Arc::new(Database::new(&config.database_path, true).await?);
            // let rust_db = Arc::new(Database::new(&rust_db_path, false).await?);

            Ok(TwonlyFlutter {
                config,
                // twonly_db_readonly,
                // rust_db,
                user_discovery: Shared::new(UserDiscovery::new(
                    UserDiscoveryStoreFlutter {},
                    UserDiscoveryUtilsFlutter {},
                )?),
            })
        })
        .await;

    twonly_res?;

    Ok(())
}
