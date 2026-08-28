/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::runtime::{ApiClient, ApiRuntime};
use crate::bridge::InitConfig;
use crate::database::app::{AppDatabase, APP_DATABASE_FILE};
use crate::database::signal::Database;
use crate::error::Result;
use crate::error::TwonlyError;
use crate::keys::DatabaseKey;
use crate::keys::KeyManager;
use crate::log::init_tracing;
use crate::secure_storage::SecureStorage;
use crate::signal::engine::RustSignalEngine;
use crate::user_discovery::UserDiscovery;
use crate::utils::Shared;
use libsignal_protocol::IdentityKey;
use std::{path::PathBuf, sync::Arc};
use tokio::sync::{Mutex, OnceCell, RwLock};
use zeroize::Zeroize;

static GLOBAL_CONTEXT: OnceCell<Arc<Context>> = OnceCell::const_new();

pub struct Context {
    pub(crate) config: InitConfig,
    pub(crate) rust_db: Arc<RwLock<Arc<Database>>>,
    pub app_db: Arc<RwLock<Arc<AppDatabase>>>,
    pub(crate) secure_storage: SecureStorage,
    pub(crate) key_manager: Arc<Mutex<KeyManager>>,
    pub(crate) user_discovery: Shared<UserDiscovery>,
    pub(crate) signal_engine: Arc<Mutex<Option<RustSignalEngine>>>,
    pub(crate) api_client: OnceCell<RwLock<Arc<ApiClient>>>,
}

impl Context {
    pub(crate) async fn init_flutter(config: InitConfig) -> Result<()> {
        Self::init_common(config, true).await
    }

    #[allow(dead_code)]
    pub(crate) async fn init_standalone(config: InitConfig) -> Result<()> {
        Self::init_common(config, false).await
    }

    pub async fn init_for_testing(
        database_dir: PathBuf,
        data_dir: PathBuf,
    ) -> Result<Arc<Context>> {
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

        let app_db_path = database_dir.join(APP_DATABASE_FILE);
        let app_db = AppDatabase::new(
            &app_db_path.display().to_string(),
            Some(&key_manager.main_key.get_database_key(DatabaseKey::AppDb)),
            false,
        )
        .await?;
        app_db.run_migrations().await?;
        let app_db = Arc::new(RwLock::new(Arc::new(app_db)));
        let rust_db = Arc::new(RwLock::new(rust_db));
        let key_manager = Arc::new(Mutex::new(key_manager));
        let user_discovery = Shared::new(UserDiscovery::new(
            data_dir.to_str().unwrap(),
            key_manager.clone(),
            rust_db.clone(),
        )?);

        let ctx = Arc::new(Context {
            config,
            rust_db,
            app_db,
            secure_storage,
            key_manager,
            user_discovery,
            signal_engine: Arc::new(Mutex::new(None)),
            api_client: OnceCell::const_new(),
        });
        ApiRuntime::initialize(&ctx).await?;
        ApiRuntime::connect(&ctx).await?;
        Ok(ctx)
    }

    #[doc(hidden)]
    #[cfg(any(test, debug_assertions))]
    pub async fn inject_test_signal_identity(
        &self,
        identity_key_pair_structure: Vec<u8>,
        registration_id: i64,
        pre_key_store: std::collections::HashMap<i64, Vec<u8>>,
    ) -> Result<()> {
        let mut key_manager = self.key_manager.lock().await;
        key_manager.signal_identity = Some(crate::keys::SignalIdentityKey {
            identity_key_pair_structure,
            registration_id,
            pre_key_store,
        });
        Ok(())
    }

    #[doc(hidden)]
    #[cfg(any(test, debug_assertions))]
    pub async fn inject_test_user_id(&self, user_id: i64) -> Result<()> {
        let mut key_manager = self.key_manager.lock().await;
        key_manager.user_id = Some(user_id);
        key_manager.store_to_keychain(&self.secure_storage)?;
        let signal_identity = key_manager.signal_identity.as_ref().map(|identity| {
            (
                identity.identity_key_pair_structure.clone(),
                identity.registration_id,
            )
        });
        drop(key_manager);

        if let Some((identity_key_pair_structure, registration_id)) = signal_identity {
            let database = self.rust_db.read().await.clone();
            *self.signal_engine.lock().await = Some(RustSignalEngine::new_with_pool(
                database.pool.clone(),
                identity_key_pair_structure,
                registration_id as u32,
                user_id.to_string(),
            )?);
        }
        self.initialize_user_discovery_from_config().await?;
        Ok(())
    }

    pub(crate) async fn initialize_user_discovery_from_config(&self) -> Result<()> {
        self.user_discovery
            .get()
            .await
            .initialize_from_config(self)
            .await
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
        let app_db_path = database_dir.join(APP_DATABASE_FILE);

        tracing::info!("Initialized twonly workspace.");
        let res: Result<&'static Arc<Context>> = GLOBAL_CONTEXT
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
                let rust_db_handle = Arc::new(RwLock::new(rust_db));

                let mut app_db_key = key_manager.main_key.get_database_key(DatabaseKey::AppDb);
                let app_db = AppDatabase::new(
                    &app_db_path.display().to_string(),
                    Some(app_db_key.as_str()),
                    false,
                )
                .await?;
                app_db.run_migrations().await?;
                let app_db = Arc::new(RwLock::new(Arc::new(app_db)));
                app_db_key.zeroize();
                rust_db_key.zeroize();

                if is_flutter {
                    let key_manager = Arc::new(Mutex::new(key_manager));
                    let signal_engine = {
                        let key_manager_guard = key_manager.lock().await;
                        let engine = match (
                            key_manager_guard.user_id,
                            &key_manager_guard.signal_identity,
                        ) {
                            (Some(user_id), Some(signal_identity)) => {
                                Some(RustSignalEngine::new_with_pool(
                                rust_db_handle.read().await.pool.clone(),
                                signal_identity.identity_key_pair_structure.clone(),
                                signal_identity.registration_id as u32,
                                user_id.to_string(),
                                )?)
                            }
                            _ => None,
                        };
                        Arc::new(Mutex::new(engine))
                    };
                    let user_discovery = Shared::new(UserDiscovery::new(
                        &config.data_dir,
                        key_manager.clone(),
                        rust_db_handle.clone(),
                    )?);
                    let ctx = Arc::new(Context {
                        config,
                        secure_storage,
                        rust_db: rust_db_handle,
                        app_db,
                        key_manager,
                        user_discovery,
                        signal_engine,
                        api_client: OnceCell::const_new(),
                    });
                    if let Err(error) = ctx.initialize_user_discovery_from_config().await {
                        tracing::warn!("failed to initialize user discovery: {error}");
                    }
                    ApiRuntime::initialize(&ctx).await?;
                    Ok(ctx)
                } else {
                    let key_manager = Arc::new(Mutex::new(key_manager));
                    let signal_engine = {
                        let key_manager_guard = key_manager.lock().await;
                        let engine = match (key_manager_guard.user_id, &key_manager_guard.signal_identity) {
                            (Some(user_id), Some(identity)) => Some(RustSignalEngine::new_with_pool(
                                rust_db_handle.read().await.pool.clone(),
                                identity.identity_key_pair_structure.clone(),
                                identity.registration_id as u32,
                                user_id.to_string(),
                            )?),
                            _ => None,
                        };
                        Arc::new(Mutex::new(engine))
                    };
                    let user_discovery = Shared::new(UserDiscovery::new(
                        &config.data_dir,
                        key_manager.clone(),
                        rust_db_handle.clone(),
                    )?);
                    let ctx = Arc::new(Context {
                        config,
                        rust_db: rust_db_handle,
                        app_db,
                        key_manager,
                        secure_storage,
                        user_discovery,
                        signal_engine,
                        api_client: OnceCell::const_new(),
                    });
                    if let Err(error) = ctx.initialize_user_discovery_from_config().await {
                        tracing::warn!("failed to initialize user discovery: {error}");
                    }
                    ApiRuntime::initialize(&ctx).await?;
                    Ok(ctx)
                }
            })
            .await;
        let ctx = res?;
        ApiRuntime::connect(ctx).await?;
        Ok(())
    }

    pub(super) fn get_static() -> Result<&'static Arc<Context>> {
        GLOBAL_CONTEXT.get().ok_or(TwonlyError::Initialization)
    }

    pub(crate) async fn user_id(&self) -> Result<i64> {
        self.key_manager
            .lock()
            .await
            .user_id
            .ok_or_else(|| TwonlyError::Generic("local user ID is missing".into()))
    }

    pub(crate) async fn get_identity(&self, user_id: i64) -> Result<Option<IdentityKey>> {
        let database = self.rust_db.read().await.clone();
        let user_id = user_id.to_string();
        let identity_key = sqlx::query_scalar!(
            r#"SELECT identity_key FROM signal_identities WHERE name = ?"#,
            user_id,
        )
        .fetch_optional(&database.pool)
        .await?;

        identity_key
            .map(|bytes| {
                IdentityKey::decode(&bytes).map_err(|error| TwonlyError::Signal(error.to_string()))
            })
            .transpose()
    }

    pub(crate) async fn replace_rust_database(
        &self,
        database: Database,
        key_manager: &KeyManager,
    ) -> Result<()> {
        let database = Arc::new(database);
        *self.rust_db.write().await = database.clone();
        let engine = match (key_manager.user_id, &key_manager.signal_identity) {
            (Some(user_id), Some(identity)) => Some(RustSignalEngine::new_with_pool(
                database.pool.clone(),
                identity.identity_key_pair_structure.clone(),
                identity.registration_id as u32,
                user_id.to_string(),
            )?),
            _ => None,
        };
        *self.signal_engine.lock().await = engine;
        Ok(())
    }
}
