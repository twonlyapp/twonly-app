use crate::user_discovery::UserDiscovery;
use crate::{
    bridge::{
        callbacks::user_discovery::{UserDiscoveryStoreFlutter, UserDiscoveryUtilsFlutter},
        InitConfig,
    },
    database::Database,
    error::{Result, TwonlyError},
    keys::{DatabaseKey, KeyManager},
    log::init_tracing,
    utils::Shared,
};
use std::{path::PathBuf, sync::Arc};
use tokio::sync::{Mutex, OnceCell};
use zeroize::Zeroize;

use crate::{bridge::TwonlyFlutter, secure_storage::SecureStorage, standalone::TwonlyStandalone};

pub(crate) enum Context {
    Flutter(TwonlyFlutter),
    Standalone(TwonlyStandalone),
}

impl Context {
    #[cfg(test)]
    pub(crate) fn from_standalone(standalone: TwonlyStandalone) -> Self {
        Self::Standalone(standalone)
    }
}

static GLOBAL_CONTEXT: OnceCell<Context> = OnceCell::const_new();

impl Context {
    pub(crate) async fn init_flutter(config: InitConfig) -> Result<()> {
        Self::init_common(config, true).await
    }

    #[allow(dead_code)]
    pub(crate) async fn init_standalone(config: InitConfig) -> Result<()> {
        Self::init_common(config, false).await
    }

    #[cfg(test)]
    pub(crate) async fn init_for_testing(
        database_dir: PathBuf,
        data_dir: PathBuf,
    ) -> Result<Context> {
        use tokio::sync::Mutex;

        std::fs::create_dir_all(&database_dir)?;
        std::fs::create_dir_all(&data_dir)?;

        let config = InitConfig {
            database_dir: database_dir.display().to_string(),
            data_dir: data_dir.display().to_string(),
        };

        // Initialize tracing and secure storage if not already done
        let _ = SecureStorage::init();
        let secure_storage = SecureStorage::new("eu.twonly.testing");

        let key_manager = KeyManager::generate()?;
        key_manager.store_to_keychain(&secure_storage)?;

        let rust_db_path = database_dir.join("rust_db.sqlite");
        let rust_db = Database::new(
            &rust_db_path.display().to_string(),
            Some(&key_manager.main_key.get_database_key(DatabaseKey::RustDb)),
            false,
        )
        .await?;
        rust_db.run_migrations().await?;
        let rust_db = Arc::new(rust_db);

        Ok(Context::from_standalone(TwonlyStandalone {
            config,
            rust_db,
            secure_storage,
            key_manager: Arc::new(Mutex::new(key_manager)),
        }))
    }

    async fn init_common(config: InitConfig, is_flutter: bool) -> Result<()> {
        if GLOBAL_CONTEXT.initialized() {
            tracing::info!("twonly already initialized. Ensuring storage directories exist.");
            std::fs::create_dir_all(&config.database_dir)?;
            std::fs::create_dir_all(&config.data_dir)?;
            return Ok(());
        }

        std::fs::create_dir_all(&config.database_dir)?;
        std::fs::create_dir_all(&config.data_dir)?;

        let log_dir = PathBuf::from(&config.data_dir).join("log");
        init_tracing(&log_dir, is_flutter).await;

        SecureStorage::init()?;
        let secure_storage = SecureStorage::new("eu.twonly");

        let database_dir = PathBuf::from(&config.database_dir.clone());
        let rust_db_path = database_dir.join("rust_db.sqlite");

        tracing::info!("Initialized twonly workspace.");
        let res: Result<&'static Context> = GLOBAL_CONTEXT
            .get_or_try_init(|| async {
                let key_manager = match KeyManager::try_from_keychain(&secure_storage) {
                    Ok(key) => key,
                    Err(err) => {
                        tracing::error!("{err}");
                        if rust_db_path.exists() {
                            tracing::error!("Rust Database exists, while the key manager not. This must be a secure storage error.");
                            return Err(TwonlyError::SecureStorageError);
                        }
                        tracing::info!("Generating a new key manager.");
                        let new = KeyManager::generate()?;
                        new.store_to_keychain(&secure_storage)?;
                        new
                    }
                };

                let mut rust_db_key = key_manager.main_key.get_database_key(DatabaseKey::RustDb);

                let rust_db = Database::new(
                    &rust_db_path.display().to_string(),
                    Some(rust_db_key.as_str()),
                    false,
                )
                .await?;
                rust_db.run_migrations().await?;
                let rust_db = Arc::new(rust_db);

                rust_db_key.zeroize();

                if is_flutter {
                    Ok(Context::Flutter(TwonlyFlutter {
                        config,
                        secure_storage,
                        rust_db,
                        key_manager: Arc::new(Mutex::new(key_manager)),
                        user_discovery: Shared::new(UserDiscovery::new(
                            UserDiscoveryStoreFlutter {},
                            UserDiscoveryUtilsFlutter {},
                        )?),
                    }))
                } else {
                    Ok(Context::Standalone(TwonlyStandalone {
                        config,
                        rust_db,
                        key_manager: Arc::new(Mutex::new(key_manager)),
                        secure_storage,
                    }))
                }
            })
            .await;
        res?;
        Ok(())
    }

    pub(super) fn get_static() -> Result<&'static Context> {
        GLOBAL_CONTEXT.get().ok_or(TwonlyError::Initialization)
    }

    // pub(crate) fn get_secure_storage(&self) -> Result<&SecureStorage> {
    //     match self {
    //         Self::Flutter(twonly) => Ok(&twonly.secure_storage),
    //         Self::Standalone(twonly) => Ok(&twonly.secure_storage),
    //     }
    // }

    pub(crate) fn get_config(&self) -> Result<&InitConfig> {
        match self {
            Self::Flutter(twonly) => Ok(&twonly.config),
            Self::Standalone(twonly) => Ok(&twonly.config),
        }
    }

    pub(crate) async fn get_key_manager(&self) -> Result<tokio::sync::MutexGuard<'_, KeyManager>> {
        match self {
            Self::Flutter(twonly) => Ok(twonly.key_manager.lock().await),
            Self::Standalone(twonly) => Ok(twonly.key_manager.lock().await),
        }
    }
}
