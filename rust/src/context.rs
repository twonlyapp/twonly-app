/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::runtime::{ApiClient, ApiRuntime};
use crate::bridge::InitConfig;
use crate::database::app::{AppDatabase, APP_DATABASE_FILE};
use crate::database::signal::Database;
use crate::error::{Result, TwonlyError};
use crate::keys::{DatabaseKey, KeyManager};
use crate::log::init_tracing;
use crate::secure_storage::SecureStorage;
use crate::signal::engine::RustSignalEngine;
use crate::user_discovery::UserDiscovery;
use crate::utils::Shared;
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::{Arc, OnceLock as StdOnceLock};
use tokio::sync::{Mutex, Notify, OnceCell, RwLock};
use zeroize::Zeroize;

static GLOBAL_CONTEXT: OnceCell<Arc<Context>> = OnceCell::const_new();

#[derive(Clone, Copy, Debug, Eq, PartialEq)]

pub enum RuntimeMode {
    Flutter,
    Standalone,
    Notification,
}

#[cfg(test)]
mod lifecycle_tests;

#[cfg(test)]
mod restore_tests;

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
    pub(crate) database_lifecycle: Mutex<()>,
    pub(crate) foreground: crate::database::lifecycle::foreground::Foreground,
    suspended: AtomicBool,
    native_databases: AtomicBool,
    pub rust_db: Arc<RwLock<Arc<Database>>>,
    pub app_db: Arc<RwLock<Arc<AppDatabase>>>,
    pub(crate) secure_storage: SecureStorage,
    pub(crate) key_manager: Arc<Mutex<KeyManager>>,
    pub(crate) user_discovery: Shared<UserDiscovery>,
    pub(crate) signal_engine: Arc<Mutex<Option<RustSignalEngine>>>,
    pub(crate) api_client: OnceCell<RwLock<Arc<ApiClient>>>,
    mailbox_generation: AtomicU64,
    mailbox_drained: Notify,
    /// Set once this connection has confirmed the account has a PQC prekey
    /// bundle on the server (or has just published one). Per context rather
    /// than process-wide so two accounts in one process check independently.
    pub(crate) pqc_bundle_verified: AtomicBool,
    /// Serializes publication and bounds checks prompted by stale ciphertext.
    pub(crate) prekey_publication: Mutex<Option<std::time::Instant>>,
    /// Coalesces overlapping flushes of this account's receipt queue. Per
    /// context for the same reason: a flush scans one app database, so a claim
    /// held for one account must not silence another account's flush.
    pub(crate) queued_receipt_flush: crate::api::messages::incoming::messages::FlushClaim,
    /// Serializes this account's upload preparation, which reserves slots and
    /// writes request files that a second concurrent pass would duplicate.
    /// Held across a reconciliation round trip, so one account waiting on the
    /// network must not stall another's uploads.
    pub(crate) media_preprocessing: Mutex<()>,
    /// Serializes this account's media retransmission sweep, for the same
    /// reason.
    pub(crate) media_retransmission: Mutex<()>,
    pub(crate) webxdc_visibility: crate::services::webxdc::visibility::Visibility,
}

impl Context {
    pub(crate) async fn init_flutter(config: InitConfig) -> Result<()> {
        crate::database::lifecycle::foreground::activate(config).await
    }

    #[allow(dead_code)]

    pub(crate) async fn init_standalone(config: InitConfig) -> Result<()> {
        Self::init_common(config, RuntimeMode::Standalone).await
    }

    pub(crate) async fn init_notification(config: InitConfig) -> Result<()> {
        crate::database::lifecycle::Operation::current()
            .ok_or_else(|| {
                TwonlyError::Generic("Native database work requires an operation lease".into())
            })?
            .check()?;

        Self::init_common(config, RuntimeMode::Notification).await
    }

    pub async fn init_for_testing(
        database_dir: PathBuf, data_dir: PathBuf,
    ) -> Result<Arc<Context>> {
        Self::test_context(database_dir, data_dir, RuntimeMode::Standalone).await
    }

    async fn test_context(
        database_dir: PathBuf, data_dir: PathBuf, runtime_mode: RuntimeMode,
    ) -> Result<Arc<Context>> {
        std::fs::create_dir_all(&database_dir)?;

        std::fs::create_dir_all(&data_dir)?;

        let config = InitConfig {
            database_dir: database_dir.display().to_string(),
            data_dir: data_dir.display().to_string(),
        };

        // Initialize tracing and secure storage if not already done
        let _ = SecureStorage::init();

        let secure_storage =
            SecureStorage::new(&format!("eu.twonly.testing.{}", uuid::Uuid::new_v4()))
                .with_database_dir(&database_dir);

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
        app_db.prepare_application_data(&database_dir).await?;

        let app_db = Arc::new(RwLock::new(Arc::new(app_db)));

        let rust_db = Arc::new(RwLock::new(rust_db));

        let key_manager = Arc::new(Mutex::new(key_manager));

        let user_discovery = Shared::new(UserDiscovery::new(
            data_dir.to_str().unwrap(),
            database_dir.to_str().unwrap(),
            key_manager.clone(),
            rust_db.clone(),
        )?);

        let ctx = Arc::new(Context {
            config,
            runtime_mode,
            flutter_claimed: AtomicBool::new(false),
            foreground_runtime: StdOnceLock::new(),
            database_lifecycle: Mutex::new(()),
            foreground: Default::default(),
            suspended: AtomicBool::new(false),
            native_databases: AtomicBool::new(runtime_mode == RuntimeMode::Notification),
            rust_db,
            app_db,
            secure_storage,
            key_manager,
            user_discovery,
            signal_engine: Arc::new(Mutex::new(None)),
            api_client: OnceCell::const_new(),
            mailbox_generation: AtomicU64::new(0),
            mailbox_drained: Notify::new(),
            pqc_bundle_verified: AtomicBool::new(false),
            prekey_publication: Mutex::new(None),
            queued_receipt_flush: Default::default(),
            media_preprocessing: Mutex::new(()),
            media_retransmission: Mutex::new(()),
            webxdc_visibility: Default::default(),
        });

        ApiRuntime::initialize(&ctx).await?;

        if runtime_mode != RuntimeMode::Notification {
            ApiRuntime::connect(&ctx).await?;
        }

        Ok(ctx)
    }

    #[doc(hidden)]
    #[cfg(any(test, debug_assertions))]

    pub async fn inject_test_signal_identity(
        &self, identity_key_pair_structure: Vec<u8>, registration_id: i64,
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

    pub(crate) async fn init_common(config: InitConfig, runtime_mode: RuntimeMode) -> Result<()> {
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
            if runtime_mode == RuntimeMode::Flutter || foreground_already_owns_process {
                crate::log::LogSource::Foreground
            } else {
                crate::database::lifecycle::Operation::current()
                    .map(|operation| operation.log_source())
                    .unwrap_or(if runtime_mode == RuntimeMode::Notification {
                        crate::log::LogSource::Notification
                    } else {
                        crate::log::LogSource::Background
                    })
            },
        );

        crate::database::restore_install::recover_before_open(&config).await?;

        if GLOBAL_CONTEXT.initialized() {
            tracing::info!("twonly already initialized. Ensuring storage directories exist.");

            if runtime_mode == RuntimeMode::Flutter {
                let context = GLOBAL_CONTEXT.get().ok_or(TwonlyError::Initialization)?;

                Self::claim_for_flutter(context).await?;
            } else if runtime_mode == RuntimeMode::Notification {
                GLOBAL_CONTEXT
                    .get()
                    .ok_or(TwonlyError::Initialization)?
                    .prepare_native_databases()
                    .await?;
            }

            return Ok(());
        }

        // Only the foreground app re-encrypts a database still on the old
        // SQLCipher key; see `database::cipher`.
        crate::database::cipher::set_migration_enabled(runtime_mode == RuntimeMode::Flutter);

        SecureStorage::init()?;

        let secure_storage =
            SecureStorage::new("eu.twonly").with_database_dir(&config.database_dir);

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
                            tracing::error!(
                                "Rust Database exists, while the key manager not. This must be a \
                                 secure storage error."
                            );

                            return Err(TwonlyError::SecureStorageError);
                        }

                        tracing::info!("Generating a new key manager.");

                        let new = KeyManager::generate()?;

                        new.store_to_keychain(&secure_storage)?;

                        new
                    }
                };

                let mut rust_db_key = key_manager.main_key.get_database_key(DatabaseKey::RustDb);

                let mut app_db_key = key_manager.main_key.get_database_key(DatabaseKey::AppDb);

                // The two files are independent, and opening one is mostly
                // waiting on the filesystem, so they are opened concurrently
                // rather than one after the other.
                let (rust_db, app_db) = tokio::join!(
                    async {
                        let database = Database::new(
                            &rust_db_path.display().to_string(),
                            Some(rust_db_key.as_str()),
                            false,
                        )
                        .await?;

                        database.run_migrations().await?;

                        Ok::<_, TwonlyError>(database)
                    },
                    async {
                        let database = AppDatabase::new(
                            &app_db_path.display().to_string(),
                            Some(app_db_key.as_str()),
                            false,
                        )
                        .await?;

                        database.run_migrations().await?;
                        database.prepare_application_data(&database_dir).await?;

                        Ok::<_, TwonlyError>(database)
                    },
                );

                // Do not abandon the other SQLite open/migration on error.
                let rust_db = rust_db?;

                let app_db = app_db?;

                let rust_db_handle = Arc::new(RwLock::new(Arc::new(rust_db)));

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
                        &config.database_dir,
                        key_manager.clone(),
                        rust_db_handle.clone(),
                    )?);

                    let ctx = Arc::new(Context {
                        config,
                        runtime_mode,
                        flutter_claimed: AtomicBool::new(true),
                        foreground_runtime: StdOnceLock::new(),
                        database_lifecycle: Mutex::new(()),
                        foreground: Default::default(),
                        suspended: AtomicBool::new(false),
                        native_databases: AtomicBool::new(false),
                        secure_storage,
                        rust_db: rust_db_handle,
                        app_db,
                        key_manager,
                        user_discovery,
                        signal_engine,
                        api_client: OnceCell::const_new(),
                        mailbox_generation: AtomicU64::new(0),
                        mailbox_drained: Notify::new(),
                        pqc_bundle_verified: AtomicBool::new(false),
                        prekey_publication: Mutex::new(None),
                        queued_receipt_flush: Default::default(),
                        media_preprocessing: Mutex::new(()),
                        media_retransmission: Mutex::new(()),
                        webxdc_visibility: Default::default(),
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

                        let engine = match (
                            key_manager_guard.user_id,
                            &key_manager_guard.signal_identity,
                        ) {
                            (Some(user_id), Some(identity)) => {
                                Some(RustSignalEngine::new_with_pool(
                                    rust_db_handle.read().await.pool.clone(),
                                    identity.identity_key_pair_structure.clone(),
                                    identity.registration_id as u32,
                                    user_id.to_string(),
                                )?)
                            }
                            _ => None,
                        };

                        Arc::new(Mutex::new(engine))
                    };

                    let user_discovery = Shared::new(UserDiscovery::new(
                        &config.data_dir,
                        &config.database_dir,
                        key_manager.clone(),
                        rust_db_handle.clone(),
                    )?);

                    let ctx = Arc::new(Context {
                        config,
                        runtime_mode,
                        flutter_claimed: AtomicBool::new(false),
                        foreground_runtime: StdOnceLock::new(),
                        database_lifecycle: Mutex::new(()),
                        foreground: Default::default(),
                        suspended: AtomicBool::new(false),
                        native_databases: AtomicBool::new(
                            runtime_mode == RuntimeMode::Notification,
                        ),
                        rust_db: rust_db_handle,
                        app_db,
                        key_manager,
                        secure_storage,
                        user_discovery,
                        signal_engine,
                        api_client: OnceCell::const_new(),
                        mailbox_generation: AtomicU64::new(0),
                        mailbox_drained: Notify::new(),
                        pqc_bundle_verified: AtomicBool::new(false),
                        prekey_publication: Mutex::new(None),
                        queued_receipt_flush: Default::default(),
                        media_preprocessing: Mutex::new(()),
                        media_retransmission: Mutex::new(()),
                        webxdc_visibility: Default::default(),
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
        } else if runtime_mode == RuntimeMode::Notification {
            // Also handles losing the OnceCell initialization race to another
            // native caller with a different execution owner.
            ctx.prepare_native_databases().await?;
        } else if runtime_mode != RuntimeMode::Notification {
            ApiRuntime::connect(ctx).await?;
        }

        Ok(())
    }

    async fn claim_for_flutter(context: &Arc<Context>) -> Result<()> {
        let _lifecycle = context.database_lifecycle.lock().await;

        crate::database::cipher::set_migration_enabled(true);

        context.reopen_databases().await?;

        let was_suspended = context.suspended.swap(false, Ordering::AcqRel);

        let was_native = context.native_databases.swap(false, Ordering::AcqRel);

        let app = context.app_db.read().await.clone();

        let signal = context.rust_db.read().await.clone();

        let owner = crate::database::lifecycle::Operation::current();

        app.operations.set_default(owner.clone());

        signal.operations.set_default(owner);

        // Visit distinct idle handles to remove the preceding native run's
        // lifetime tickets. Active handles clear them on release.
        for pool in [&app.pool, &app.read_pool, &signal.pool] {
            let idle = pool.num_idle();

            let mut checkouts = Vec::new();

            for _ in 0..idle {
                match tokio::time::timeout(std::time::Duration::from_secs(2), pool.acquire()).await
                {
                    Ok(Ok(connection)) => checkouts.push(connection),
                    _ => break,
                }
            }

            drop(checkouts);
        }

        if let Ok(runtime) = tokio::runtime::Handle::try_current() {
            let _ = context.foreground_runtime.set(runtime);
        }

        let newly_claimed = !context.flutter_claimed.swap(true, Ordering::AcqRel);

        if was_suspended
            || was_native
            || (newly_claimed && context.runtime_mode != RuntimeMode::Flutter)
        {
            tracing::info!("promoting native background runtime to Flutter ownership");

            // Rebuild the client so the next authentication is explicitly
            // foreground. The old background client is closed before Flutter
            // starts observing connection state.
            ApiRuntime::reload_configuration(context).await
        } else {
            ApiRuntime::connect(context).await
        }
    }

    /// Called under database_lifecycle after staging validates. The restore
    /// worker has its own lease, so retiring UI producers cannot cancel it.

    pub(crate) async fn quiesce_for_restore(self: &Arc<Self>) -> Result<()> {
        self.suspended.store(true, Ordering::Release);

        let old = self.foreground.operation();

        if let Some(old) = &old {
            old.cancel();

            crate::database::app::transaction::abort_for_operation(old).await;
        }

        ApiRuntime::close(self).await?;

        let app = self.app_db.read().await.clone();

        let signal = self.rust_db.read().await.clone();

        tokio::join!(app.close(), signal.pool.close());

        if let Some(old) = old {
            old.drain().await;
        }

        Ok(())
    }

    pub(crate) async fn resume_after_restore(
        self: &Arc<Self>, admission: tokio::sync::OwnedSemaphorePermit,
    ) -> Result<()> {
        // Keep native admission until replacement handles are either closed
        // or detached from the restore owner. Foreground adoption also takes
        // this lifecycle mutex, so it cannot race our background close.
        let lifecycle = self.database_lifecycle.lock().await;

        if !self.has_flutter() {
            let app = self.app_db.read().await.clone();

            let signal = self.rust_db.read().await.clone();

            app.operations.set_default(None);

            signal.operations.set_default(None);

            for pool in [&app.pool, &app.read_pool, &signal.pool] {
                let mut checkouts = Vec::new();

                for _ in 0..pool.num_idle() {
                    checkouts.push(pool.acquire().await?);
                }

                drop(checkouts);
            }

            self.suspended.store(false, Ordering::Release);
        } else {
            // Close restore-owned handles even while visible. If UIKit
            // backgrounds between this point and foreground reactivation, no
            // restore handle remains open while activate waits for visibility.
            ApiRuntime::close(self).await?;

            let app = self.app_db.read().await.clone();

            let signal = self.rust_db.read().await.clone();

            tokio::join!(app.close(), signal.pool.close());

            drop(lifecycle);

            drop(admission);

            if crate::database::lifecycle::foreground::active() {
                tokio::select! {
                    result = crate::database::lifecycle::foreground::activate(InitConfig {
                        database_dir: self.config.database_dir.clone(),
                        data_dir: self.config.data_dir.clone(),
                    }) => result?,
                    _ = crate::database::lifecycle::foreground::until_background() => {}
                }
            }
        }

        Ok(())
    }

    async fn prepare_native_databases(self: &Arc<Self>) -> Result<()> {
        if self.has_flutter() && !crate::database::lifecycle::foreground::active() {
            self.foreground.drained().await?;
        }

        let _lifecycle = self.database_lifecycle.lock().await;

        if let Some(operation) = crate::database::lifecycle::Operation::current() {
            operation.check()?;
        }

        let mut replace_api = false;

        if self.has_flutter() {
            if crate::database::lifecycle::foreground::active() {
                if self.suspended.load(Ordering::Acquire)
                    || self.app_db.read().await.pool.is_closed()
                    || self.rust_db.read().await.pool.is_closed()
                {
                    return Err(TwonlyError::Generic(
                        "Foreground database admission is closed; defer native work".into(),
                    ));
                }

                // A visible Flutter session retains ownership of its pools.
                return Ok(());
            }

            replace_api = !self.native_databases.swap(true, Ordering::AcqRel);
        }

        self.reopen_databases().await?;

        let owner = if self.is_notification_runtime() {
            crate::database::lifecycle::Operation::current()
        } else {
            None
        };

        if let Some(owner) = &owner {
            // Native admission serializes complete jobs, including the render
            // phase of a notification. Reject accidental adoption of a pool
            // still belonging to another owner or an unscoped initializer.
            if !self.app_db.read().await.operations.owned_by(owner)
                || !self.rust_db.read().await.operations.owned_by(owner)
            {
                return Err(TwonlyError::Generic(
                    "Native notification work owns the databases; defer maintenance".into(),
                ));
            }
        } else if self.is_notification_runtime()
            && (self.app_db.read().await.operations.has_owner()
                || self.rust_db.read().await.operations.has_owner())
        {
            return Err(TwonlyError::Generic(
                "Native maintenance owns the databases; defer notification work".into(),
            ));
        }

        self.app_db
            .read()
            .await
            .operations
            .set_default(owner.clone());

        self.rust_db.read().await.operations.set_default(owner);

        if replace_api {
            ApiRuntime::reload_configuration_deferred(self).await?;

            ApiRuntime::client(self)
                .await?
                .network_available
                .store(true, Ordering::Release);
        }

        Ok(())
    }

    async fn reopen_databases(&self) -> Result<()> {
        crate::database::restore_install::recover_with_storage(
            &self.config,
            self.secure_storage.clone(),
        )
        .await?;

        let mut keys = self.key_manager.lock().await;

        *keys = KeyManager::try_from_keychain(&self.secure_storage)?;

        let app_key = zeroize::Zeroizing::new(keys.main_key.get_database_key(DatabaseKey::AppDb));

        let signal_key =
            zeroize::Zeroizing::new(keys.main_key.get_database_key(DatabaseKey::RustDb));

        let app = self.app_db.read().await.clone();

        if app.pool.is_closed() {
            *self.app_db.write().await = Arc::new(app.reopen_with_key(Some(&app_key)).await?);
        }

        let signal = self.rust_db.read().await.clone();

        if signal.pool.is_closed() {
            let replacement = signal.reopen_with_key(Some(&signal_key)).await?;

            self.replace_rust_database(replacement, &keys).await?;
        }

        Ok(())
    }

    pub(crate) async fn finish_native_databases(
        self: &Arc<Self>, operation: &crate::database::lifecycle::Operation,
    ) -> Result<()> {
        let _lifecycle = self.database_lifecycle.lock().await;

        if !self.is_notification_runtime() {
            return Ok(());
        }

        let app = self.app_db.read().await.clone();

        let signal = self.rust_db.read().await.clone();

        let owns_app = app.operations.owned_by(operation);

        let owns_signal = signal.operations.owned_by(operation);

        if !owns_app && !owns_signal {
            return Ok(());
        }

        operation.cancel();

        crate::database::app::transaction::abort_for_operation(operation).await;

        // Reopening can fail after just one pool was replaced. Always close
        // that owned pool, without closing another job's remaining live pool.
        // close() closes admission synchronously, before awaiting networking.
        let close_app = owns_app.then(|| app.close());

        let close_signal = owns_signal.then(|| signal.pool.close());

        let network =
            if (owns_app || app.pool.is_closed()) && (owns_signal || signal.pool.is_closed()) {
                ApiRuntime::close(self).await
            } else {
                Ok(())
            };

        tokio::join!(
            async {
                if let Some(close) = close_app {
                    close.await;
                }
            },
            async {
                if let Some(close) = close_signal {
                    close.await;
                }
            },
        );

        operation.drain().await;

        self.native_databases.store(false, Ordering::Release);

        network
    }

    pub(crate) fn request_foreground_suspend(&self) {
        if self.has_flutter() {
            self.suspended.store(true, Ordering::Release);

            if let Some(operation) = self.foreground.operation() {
                operation.cancel();
            }
        }
    }

    pub(crate) async fn finish_foreground_databases(
        self: &Arc<Self>, operation: &crate::database::lifecycle::Operation,
    ) -> Result<()> {
        let _lifecycle = self.database_lifecycle.lock().await;

        let app = self.app_db.read().await.clone();

        let signal = self.rust_db.read().await.clone();

        let owns_app = app.operations.owned_by(operation);

        let owns_signal = signal.operations.owned_by(operation);

        if !owns_app && !owns_signal {
            return Ok(());
        }

        self.suspended.store(true, Ordering::Release);

        operation.cancel();

        // Close admission before waiting for rollback or network shutdown.
        let close_app = owns_app.then(|| app.close());

        let close_signal = owns_signal.then(|| signal.pool.close());

        crate::database::app::transaction::abort_for_operation(operation).await;

        let network = ApiRuntime::close(self).await;

        tokio::join!(
            async {
                if let Some(close) = close_app {
                    close.await;
                }
            },
            async {
                if let Some(close) = close_signal {
                    close.await;
                }
            },
        );

        operation.drain().await;

        self.native_databases.store(false, Ordering::Release);

        tracing::info!("foreground database pools drained and closed");

        network
    }

    fn has_flutter(&self) -> bool {
        self.runtime_mode == RuntimeMode::Flutter || self.flutter_claimed.load(Ordering::Acquire)
    }

    pub(crate) fn is_suspended(&self) -> bool {
        self.has_flutter() && self.suspended.load(Ordering::Acquire)
    }

    pub(crate) fn saved_foreground_runtime(&self) -> Option<tokio::runtime::Handle> {
        self.foreground_runtime.get().cloned()
    }

    pub(crate) async fn wait_for_foreground(&self) -> Result<()> {
        if !self.has_flutter() {
            return Ok(());
        }

        if let Some(operation) = crate::database::lifecycle::Operation::current() {
            return operation.check();
        }

        self.foreground.wait_ready().await
    }

    pub(crate) fn is_flutter_runtime(&self) -> bool {
        self.has_flutter()
            && !self.suspended.load(Ordering::Acquire)
            && !self.native_databases.load(Ordering::Acquire)
    }

    pub(crate) fn is_notification_runtime(&self) -> bool {
        self.native_databases.load(Ordering::Acquire)
            || (self.runtime_mode == RuntimeMode::Notification && !self.has_flutter())
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

    pub(crate) async fn user_id(&self) -> Result<i64> {
        self.key_manager
            .lock()
            .await
            .user_id
            .ok_or_else(|| TwonlyError::Generic("local user ID is missing".into()))
    }

    pub(crate) async fn replace_rust_database(
        &self, database: Database, key_manager: &KeyManager,
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
        self.pqc_bundle_verified.store(false, Ordering::Release);
        *self.prekey_publication.lock().await = None;

        Ok(())
    }
}
