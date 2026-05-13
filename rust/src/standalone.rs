use tokio::sync::Mutex;

use crate::bridge::InitConfig;
use crate::database::Database;
use crate::keys::KeyManager;
use crate::secure_storage::SecureStorage;
use std::sync::Arc;

pub(crate) struct TwonlyStandalone {
    #[allow(dead_code)]
    pub(crate) config: InitConfig,
    #[allow(dead_code)]
    pub(crate) rust_db: Arc<Database>,
    #[allow(dead_code)]
    pub(crate) secure_storage: SecureStorage,
    pub(crate) key_manager: Arc<Mutex<KeyManager>>,
}
