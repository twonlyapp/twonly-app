#![allow(unexpected_cfgs)]
pub mod error;
mod user_discovery_utils;
use crate::bridge::user_discovery_utils::UserDiscoveryUtilsFlutter;
use crate::database::contact::Contact;
use crate::database::Database;
use crate::user_discovery_store::UserDiscoveryDatabaseStore;
use crate::utils::Shared;
use error::Result;
use error::TwonlyError;
use flutter_rust_bridge::frb;
use protocols::user_discovery::UserDiscovery;
use std::sync::Arc;
use tokio::sync::OnceCell;

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

pub struct TwonlyConfig {
    pub database_path: String,
    pub data_directory: String,
}

pub(crate) struct Twonly {
    #[allow(dead_code)]
    pub(crate) config: TwonlyConfig,
    pub(crate) database: Arc<Database>,
    pub(crate) user_discovery:
        Shared<Option<UserDiscovery<UserDiscoveryDatabaseStore, UserDiscoveryUtilsFlutter>>>,
}

static GLOBAL_TWONLY: OnceCell<Twonly> = OnceCell::const_new();

pub(crate) fn get_workspace() -> Result<&'static Twonly> {
    GLOBAL_TWONLY.get().ok_or(TwonlyError::Initialization)
}

pub async fn initialize_twonly(config: TwonlyConfig) -> Result<()> {
    tracing::debug!("Initialized twonly workspace.");
    let twonly_res: Result<&'static Twonly> = GLOBAL_TWONLY
        .get_or_try_init(|| async {
            let database = Arc::new(Database::new(&config.database_path).await?);
            Ok(Twonly {
                config,
                database,
                user_discovery: Shared::default(),
            })
        })
        .await;

    twonly_res?;

    Ok(())
}

pub async fn get_all_contacts() -> Result<Vec<Contact>> {
    let twonly = get_workspace()?;
    Contact::get_all_contacts(twonly.database.as_ref()).await
}

pub fn load_promotions() -> OtherPromotion {
    todo!()
}

#[cfg(test)]
pub(crate) mod tests {
    use sqlx::sqlite::{SqliteConnectOptions, SqlitePoolOptions};
    use tempfile::{NamedTempFile, TempDir};
    use tokio::sync::OnceCell;

    use crate::{database::Database, utils::Shared};

    use super::error::Result;
    use super::Twonly;
    use std::{path::PathBuf, sync::Arc};
    use tokio::sync::Mutex;

    use super::{get_workspace, initialize_twonly, TwonlyConfig};

    static TWONLY_TESTING: [OnceCell<Twonly>; 10] = [
        OnceCell::const_new(),
        OnceCell::const_new(),
        OnceCell::const_new(),
        OnceCell::const_new(),
        OnceCell::const_new(),
        OnceCell::const_new(),
        OnceCell::const_new(),
        OnceCell::const_new(),
        OnceCell::const_new(),
        OnceCell::const_new(),
    ];

    static TWONLY_TESTING_INDEX: OnceCell<Arc<Mutex<usize>>> = OnceCell::const_new();

    pub(crate) async fn initialize_twonly_for_testing(use_global: bool) -> Result<&'static Twonly> {
        let default_twonly_database = PathBuf::from("tests/testing.db");

        if !default_twonly_database.is_file() {
            panic!("{} not found!", default_twonly_database.display())
        }

        let temp_file = NamedTempFile::new().unwrap().path().to_owned();

        tracing::info!("Crated db copy: {}", temp_file.display());

        let conn = SqlitePoolOptions::new()
            .connect_with(
                format!("sqlite://{}", default_twonly_database.display())
                    .parse::<SqliteConnectOptions>()
                    .unwrap(),
            )
            .await
            .unwrap();

        let path_str = temp_file.display().to_string();
        sqlx::query("VACUUM INTO $1")
            .bind(path_str)
            .execute(&conn)
            .await
            .expect("Failed to backup database");

        let tmp_dir = TempDir::new().unwrap().path().to_owned();
        std::fs::create_dir_all(&tmp_dir).unwrap();
        let config = TwonlyConfig {
            database_path: temp_file.display().to_string(),
            data_directory: tmp_dir.to_str().unwrap().to_string(),
        };

        if use_global {
            initialize_twonly(config).await.unwrap();

            get_workspace()
        } else {
            let index = TWONLY_TESTING_INDEX
                .get_or_init(|| async { Arc::default() })
                .await;
            let mut index = index.lock().await;
            let res: Result<&'static Twonly> = TWONLY_TESTING[*index]
                .get_or_try_init(|| async {
                    let database = Arc::new(Database::new(&config.database_path).await?);
                    Ok(Twonly {
                        config,
                        database,
                        user_discovery: Shared::default(),
                    })
                })
                .await;
            tracing::debug!("TWONLY_TESTING_INDEX: {index}");
            *index += 1;
            res
        }
    }
}
