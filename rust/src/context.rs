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
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::{
    path::{Path, PathBuf},
    sync::{Arc, OnceLock as StdOnceLock},
};
use tokio::sync::{Mutex, Notify, OnceCell, RwLock};
use zeroize::Zeroize;

static GLOBAL_CONTEXT: OnceCell<Arc<Context>> = OnceCell::const_new();

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum RuntimeMode {
    Flutter,
    Standalone,
    Notification,
}

pub struct Context {
    pub config: InitConfig,
    pub(crate) runtime_mode: RuntimeMode,
    /// A native worker can initialize this process before Flutter does. Once
    /// Flutter claims it, background jobs must neither open nor close a second
    /// API connection through the shared client.
    flutter_claimed: AtomicBool,
    /// Runtime owned by flutter_rust_bridge. Native workers may call into the
    /// same library from a temporary runtime; UI-facing pollers must be spawned
    /// here so they survive that native call returning.
    foreground_runtime: StdOnceLock<tokio::runtime::Handle>,
    pub rust_db: Arc<RwLock<Arc<Database>>>,
    pub app_db: Arc<RwLock<Arc<AppDatabase>>>,
    pub(crate) secure_storage: SecureStorage,
    pub(crate) key_manager: Arc<Mutex<KeyManager>>,
    pub(crate) user_discovery: Shared<UserDiscovery>,
    pub(crate) signal_engine: Arc<Mutex<Option<RustSignalEngine>>>,
    pub(crate) api_client: OnceCell<RwLock<Arc<ApiClient>>>,
    mailbox_generation: AtomicU64,
    mailbox_drained: Notify,
    incoming_generation: AtomicU64,
    incoming_committed: Notify,
    /// Set once this connection has confirmed the account has a PQC prekey
    /// bundle on the server (or has just published one). Per context rather
    /// than process-wide so two accounts in one process check independently.
    pub(crate) pqc_bundle_verified: AtomicBool,
}

impl Context {
    pub(crate) async fn init_flutter(config: InitConfig) -> Result<()> {
        Self::init_common(config, RuntimeMode::Flutter).await
    }

    #[allow(dead_code)]
    pub(crate) async fn init_standalone(config: InitConfig) -> Result<()> {
        Self::init_common(config, RuntimeMode::Standalone).await
    }

    pub(crate) async fn init_notification(config: InitConfig) -> Result<()> {
        Self::init_common(config, RuntimeMode::Notification).await
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
            runtime_mode: RuntimeMode::Standalone,
            flutter_claimed: AtomicBool::new(false),
            foreground_runtime: StdOnceLock::new(),
            rust_db,
            app_db,
            secure_storage,
            key_manager,
            user_discovery,
            signal_engine: Arc::new(Mutex::new(None)),
            api_client: OnceCell::const_new(),
            mailbox_generation: AtomicU64::new(0),
            mailbox_drained: Notify::new(),
            incoming_generation: AtomicU64::new(0),
            incoming_committed: Notify::new(),
            pqc_bundle_verified: AtomicBool::new(false),
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
    ) -> Result<()> {
        let mut key_manager = self.key_manager.lock().await;
        key_manager.signal_identity = Some(crate::keys::SignalIdentityKey {
            identity_key_pair_structure,
            registration_id,
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

    async fn init_common(config: InitConfig, runtime_mode: RuntimeMode) -> Result<()> {
        std::fs::create_dir_all(&config.database_dir)?;
        std::fs::create_dir_all(&config.data_dir)?;

        // Logging is process-wide and owns app.log directly. Initialize it
        // before the context check so notification and Flutter runtimes both
        // have a sink even when the main context already exists.
        let foreground_already_owns_process = GLOBAL_CONTEXT
            .get()
            .is_some_and(|context| context.is_flutter_runtime());
        init_tracing(
            Path::new(&config.data_dir),
            runtime_mode != RuntimeMode::Flutter && !foreground_already_owns_process,
        );

        if GLOBAL_CONTEXT.initialized() {
            tracing::info!("twonly already initialized. Ensuring storage directories exist.");
            if runtime_mode == RuntimeMode::Flutter {
                let context = GLOBAL_CONTEXT.get().ok_or(TwonlyError::Initialization)?;
                Self::claim_for_flutter(context).await?;
            }
            return Ok(());
        }

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
                        tracing::warn!("{err}");
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

                if runtime_mode == RuntimeMode::Flutter {
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
                        runtime_mode,
                        flutter_claimed: AtomicBool::new(true),
                        foreground_runtime: StdOnceLock::new(),
                        secure_storage,
                        rust_db: rust_db_handle,
                        app_db,
                        key_manager,
                        user_discovery,
                        signal_engine,
                        api_client: OnceCell::const_new(),
                        mailbox_generation: AtomicU64::new(0),
                        mailbox_drained: Notify::new(),
                        incoming_generation: AtomicU64::new(0),
                        incoming_committed: Notify::new(),
            pqc_bundle_verified: AtomicBool::new(false),
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
                        runtime_mode,
                        flutter_claimed: AtomicBool::new(false),
                        foreground_runtime: StdOnceLock::new(),
                        rust_db: rust_db_handle,
                        app_db,
                        key_manager,
                        secure_storage,
                        user_discovery,
                        signal_engine,
                        api_client: OnceCell::const_new(),
                        mailbox_generation: AtomicU64::new(0),
                        mailbox_drained: Notify::new(),
                        incoming_generation: AtomicU64::new(0),
                        incoming_committed: Notify::new(),
            pqc_bundle_verified: AtomicBool::new(false),
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
        if runtime_mode == RuntimeMode::Flutter {
            Self::claim_for_flutter(ctx).await?;
        } else if runtime_mode != RuntimeMode::Notification {
            ApiRuntime::connect(ctx).await?;
        }
        Ok(())
    }

    async fn claim_for_flutter(context: &Arc<Context>) -> Result<()> {
        if let Ok(runtime) = tokio::runtime::Handle::try_current() {
            let _ = context.foreground_runtime.set(runtime);
        }
        let newly_claimed = !context.flutter_claimed.swap(true, Ordering::AcqRel);
        if newly_claimed && context.runtime_mode != RuntimeMode::Flutter {
            tracing::info!("promoting native background runtime to Flutter ownership");
            // Rebuild the client so the next authentication is explicitly
            // foreground. The old background client is closed before Flutter
            // starts observing connection state.
            ApiRuntime::reload_configuration(context).await
        } else {
            ApiRuntime::connect(context).await
        }
    }

    pub(crate) fn is_flutter_runtime(&self) -> bool {
        self.runtime_mode == RuntimeMode::Flutter || self.flutter_claimed.load(Ordering::Acquire)
    }

    pub(crate) fn is_notification_runtime(&self) -> bool {
        self.runtime_mode == RuntimeMode::Notification
            && !self.flutter_claimed.load(Ordering::Acquire)
    }

    pub(crate) fn foreground_runtime(&self) -> Option<tokio::runtime::Handle> {
        self.is_flutter_runtime()
            .then(|| self.foreground_runtime.get().cloned())
            .flatten()
    }

    pub(super) fn get_static() -> Result<&'static Arc<Context>> {
        GLOBAL_CONTEXT.get().ok_or(TwonlyError::Initialization)
    }

    pub(crate) fn mailbox_generation(&self) -> u64 {
        self.mailbox_generation.load(Ordering::Acquire)
    }

    pub(crate) fn mark_mailbox_drained(&self) {
        self.mailbox_generation.fetch_add(1, Ordering::AcqRel);
        self.mailbox_drained.notify_waiters();
    }

    pub(crate) async fn wait_for_mailbox_after(&self, generation: u64) {
        while self.mailbox_generation() <= generation {
            let notified = self.mailbox_drained.notified();
            if self.mailbox_generation() > generation {
                break;
            }
            notified.await;
        }
    }

    pub(crate) fn incoming_generation(&self) -> u64 {
        self.incoming_generation.load(Ordering::Acquire)
    }

    pub(crate) fn mark_incoming_committed(&self) {
        self.incoming_generation.fetch_add(1, Ordering::AcqRel);
        self.incoming_committed.notify_waiters();
    }

    pub(crate) async fn wait_for_incoming_after(&self, generation: u64) {
        while self.incoming_generation() <= generation {
            let notified = self.incoming_committed.notified();
            if self.incoming_generation() > generation {
                break;
            }
            notified.await;
        }
    }

    pub(crate) async fn user_id(&self) -> Result<i64> {
        self.key_manager
            .lock()
            .await
            .user_id
            .ok_or_else(|| TwonlyError::Generic("local user ID is missing".into()))
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
