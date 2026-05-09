use crate::error::Result;
use crate::{bridge::get_twonly_flutter, keys::KeyManager};

pub struct FlutterKeyManager {}

impl FlutterKeyManager {
    pub async fn get_login_token() -> Result<Vec<u8>> {
        let ctx = get_twonly_flutter()?;
        let key_manager = KeyManager::try_from_keychain(&ctx.secure_storage)?;
        Ok(key_manager.main_key.get_login_token().to_vec())
    }
}
