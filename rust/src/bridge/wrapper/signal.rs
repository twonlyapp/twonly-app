use crate::bridge::get_twonly_flutter;
use crate::error::{Result, TwonlyError};
use crate::signal::engine::{FrbPqcPreKey, FrbPreKeyBundle};

pub struct RustSignal {}

impl RustSignal {
    pub async fn generate_bundle() -> Result<FrbPreKeyBundle> {
        let guard = get_twonly_flutter()?.signal_engine.lock().await;
        let engine = guard.as_ref().ok_or(TwonlyError::Initialization)?;
        engine
            .generate_bundle()
            .await
    }

    pub async fn generate_pqc_prekeys() -> Result<Vec<FrbPqcPreKey>> {
        let guard = get_twonly_flutter()?.signal_engine.lock().await;
        let engine = guard.as_ref().ok_or(TwonlyError::Initialization)?;
        engine.generate_pqc_prekeys().await
    }

    pub async fn process_prekey_bundle(
        name: String,
        device_id: u32,
        bundle: FrbPreKeyBundle,
    ) -> Result<()> {
        let guard = get_twonly_flutter()?.signal_engine.lock().await;
        let engine = guard.as_ref().ok_or(TwonlyError::Initialization)?;
        engine.process_prekey_bundle(name, device_id, bundle).await
    }

    pub async fn encrypt(name: String, device_id: u32, plaintext: Vec<u8>) -> Result<Vec<u8>> {
        let guard = get_twonly_flutter()?.signal_engine.lock().await;
        let engine = guard.as_ref().ok_or(TwonlyError::Initialization)?;
        Ok(engine.encrypt_message(name, device_id, plaintext).await?)
    }

    pub async fn decrypt(name: String, device_id: u32, ciphertext: Vec<u8>) -> Result<Vec<u8>> {
        let guard = get_twonly_flutter()?.signal_engine.lock().await;
        let engine = guard.as_ref().ok_or(TwonlyError::Initialization)?;
        engine
            .decrypt_message(name.clone(), device_id, ciphertext.clone())
            .await
    }
}
