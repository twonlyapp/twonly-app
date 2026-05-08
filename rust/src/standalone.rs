use crate::bridge::InitConfig;
use crate::database::Database;
use crate::secure_storage::SecureStorage;
use std::sync::Arc;

pub(crate) struct TwonlyStandalone {
    #[allow(dead_code)]
    pub(crate) config: InitConfig,
    pub(crate) rust_db: Arc<Database>,
    pub(crate) secure_storage: SecureStorage,
}
