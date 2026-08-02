use crate::error::{Result, TwonlyError};
use libsignal_protocol::{
    message_encrypt, process_prekey_bundle, DeviceId, GenericSignedPreKey, IdentityKey,
    IdentityKeyPair, IdentityKeyStore, KyberPreKeyId, KyberPreKeyStore, PreKeyBundle, PreKeyId,
    PreKeySignalMessage, PreKeyStore, ProtocolAddress, PublicKey, SignalMessage, SignedPreKeyId,
    SignedPreKeyStore, Timestamp,
};
use std::sync::Arc;
use std::time::{SystemTime, UNIX_EPOCH};
use tokio::sync::Mutex;

use crate::signal::store::DbSignalProtocolStore;

pub struct RustSignalEngine {
    store: Arc<Mutex<DbSignalProtocolStore>>,
}

pub struct FrbPreKeyBundle {
    pub registration_id: u32,
    pub device_id: u32,
    pub pre_key_id: Option<u32>,
    pub pre_key_public: Option<Vec<u8>>,
    pub signed_pre_key_id: u32,
    pub signed_pre_key_public: Vec<u8>,
    pub signed_pre_key_signature: Vec<u8>,
    pub kyber_pre_key_id: u32,
    pub kyber_pre_key_public: Vec<u8>,
    pub kyber_pre_key_signature: Vec<u8>,
    pub identity_key: Vec<u8>,
}

impl RustSignalEngine {
    pub async fn new() -> Result<Self> {
        let twonly = crate::bridge::get_twonly_flutter()?;
        let pool = twonly.rust_db.pool.clone();

        let km = twonly.key_manager.lock().await;
        let signal_identity = km
            .signal_identity
            .as_ref()
            .ok_or_else(|| TwonlyError::Generic("No signal identity found".to_string()))?;

        let identity_key_pair =
            IdentityKeyPair::try_from(&signal_identity.identity_key_pair_structure[..])
                .map_err(|e| TwonlyError::Signal(e.to_string()))?;

        let store = DbSignalProtocolStore::new(
            pool,
            identity_key_pair,
            signal_identity.registration_id as u32,
        );

        Ok(Self {
            store: Arc::new(Mutex::new(store)),
        })
    }

    pub fn new_with_pool(
        pool: sqlx::SqlitePool,
        identity_key_pair_bytes: Vec<u8>,
        local_registration_id: u32,
    ) -> Result<Self> {
        let identity_key_pair = IdentityKeyPair::try_from(&identity_key_pair_bytes[..])
            .map_err(|e| TwonlyError::Signal(e.to_string()))?;

        let store = DbSignalProtocolStore::new(pool, identity_key_pair, local_registration_id);

        Ok(Self {
            store: Arc::new(Mutex::new(store)),
        })
    }

    pub fn generate_identity_key_pair() -> Result<Vec<u8>> {
        let mut csprng = rand::rng();
        let key_pair = IdentityKeyPair::generate(&mut csprng);
        Ok(key_pair.serialize().to_vec())
    }

    pub async fn generate_bundle(
        &self,
        pre_key_id: u32,
        signed_pre_key_id: u32,
    ) -> Result<FrbPreKeyBundle> {
        let mut store_guard = self.store.lock().await;
        let store = &mut *store_guard;
        let mut csprng = rand::rng();

        let pre_key_pair = libsignal_protocol::KeyPair::generate(&mut csprng);
        store
            .pre_key_store
            .save_pre_key(
                pre_key_id.into(),
                &libsignal_protocol::PreKeyRecord::new(pre_key_id.into(), &pre_key_pair),
            )
            .await
            .map_err(|e| TwonlyError::Signal(e.to_string()))?;

        let signed_pre_key_pair = libsignal_protocol::KeyPair::generate(&mut csprng);
        let signature = store
            .identity_store
            .get_identity_key_pair()
            .await
            .map_err(|e| TwonlyError::Signal(e.to_string()))?
            .private_key()
            .calculate_signature_for_multipart_message(
                &[&signed_pre_key_pair.public_key.serialize()],
                &mut csprng,
            )
            .map_err(|e| TwonlyError::Signal(e.to_string()))?;
        let timestamp = Timestamp::from_epoch_millis(
            SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .unwrap()
                .as_millis() as u64,
        );
        store
            .signed_pre_key_store
            .save_signed_pre_key(
                signed_pre_key_id.into(),
                &libsignal_protocol::SignedPreKeyRecord::new(
                    signed_pre_key_id.into(),
                    timestamp,
                    &signed_pre_key_pair,
                    &signature,
                ),
            )
            .await
            .map_err(|e| TwonlyError::Signal(e.to_string()))?;

        let kyber_pre_key_id = 1;
        let kyber_key_pair = libsignal_protocol::kem::KeyPair::generate(
            libsignal_protocol::kem::KeyType::Kyber1024,
            &mut csprng,
        );
        let kyber_signature = store
            .identity_store
            .get_identity_key_pair()
            .await
            .map_err(|e| TwonlyError::Signal(e.to_string()))?
            .private_key()
            .calculate_signature_for_multipart_message(
                &[&kyber_key_pair.public_key.serialize()],
                &mut csprng,
            )
            .map_err(|e| TwonlyError::Signal(e.to_string()))?;
        let kyber_sig_arr: [u8; 64] = kyber_signature[..].try_into().unwrap();
        store
            .kyber_pre_key_store
            .save_kyber_pre_key(
                kyber_pre_key_id.into(),
                &libsignal_protocol::KyberPreKeyRecord::new(
                    kyber_pre_key_id.into(),
                    timestamp,
                    &kyber_key_pair,
                    &kyber_sig_arr,
                ),
            )
            .await
            .map_err(|e| TwonlyError::Signal(e.to_string()))?;

        Ok(FrbPreKeyBundle {
            registration_id: store
                .identity_store
                .get_local_registration_id()
                .await
                .map_err(|e| TwonlyError::Signal(e.to_string()))?,
            device_id: 1,
            pre_key_id: Some(pre_key_id),
            pre_key_public: Some(pre_key_pair.public_key.serialize().to_vec()),
            signed_pre_key_id: signed_pre_key_id,
            signed_pre_key_public: signed_pre_key_pair.public_key.serialize().to_vec(),
            signed_pre_key_signature: signature.to_vec(),
            kyber_pre_key_id: kyber_pre_key_id,
            kyber_pre_key_public: kyber_key_pair.public_key.serialize().to_vec(),
            kyber_pre_key_signature: kyber_signature.to_vec(),
            identity_key: store
                .identity_store
                .get_identity_key_pair()
                .await
                .map_err(|e| TwonlyError::Signal(e.to_string()))?
                .identity_key()
                .serialize()
                .to_vec(),
        })
    }

    pub async fn process_prekey_bundle(
        &self,
        name: String,
        device_id: u32,
        bundle: FrbPreKeyBundle,
    ) -> Result<()> {
        let mut store_guard = self.store.lock().await;
        let store = &mut *store_guard;

        let d_id = DeviceId::try_from(device_id)
            .map_err(|_| TwonlyError::Generic(format!("Invalid device id: {}", device_id)))?;
        let remote_address = ProtocolAddress::new(name, d_id);
        let local_address =
            ProtocolAddress::new("local".to_string(), DeviceId::try_from(1).unwrap());

        let identity_key = IdentityKey::decode(&bundle.identity_key)
            .map_err(|e| TwonlyError::Signal(e.to_string()))?;

        let signed_pre_key_public = PublicKey::deserialize(&bundle.signed_pre_key_public)
            .map_err(|e| TwonlyError::Signal(e.to_string()))?;

        let pre_key_public = match bundle.pre_key_public {
            Some(pk) => {
                Some(PublicKey::deserialize(&pk).map_err(|e| TwonlyError::Signal(e.to_string()))?)
            }
            None => None,
        };

        let pre_key = match (bundle.pre_key_id, pre_key_public) {
            (Some(id), Some(pk)) => Some((PreKeyId::from(id), pk)),
            _ => None,
        };

        let mut csprng = rand::rng();

        let pre_key_bundle = PreKeyBundle::new(
            bundle.registration_id,
            DeviceId::try_from(bundle.device_id).unwrap_or(DeviceId::try_from(1).unwrap()),
            pre_key,
            SignedPreKeyId::from(bundle.signed_pre_key_id),
            signed_pre_key_public,
            bundle.signed_pre_key_signature,
            KyberPreKeyId::from(bundle.kyber_pre_key_id),
            libsignal_protocol::kem::PublicKey::deserialize(&bundle.kyber_pre_key_public)
                .map_err(|e| TwonlyError::Signal(e.to_string()))?,
            bundle.kyber_pre_key_signature,
            identity_key,
        )
        .map_err(|e| TwonlyError::Signal(e.to_string()))?;

        process_prekey_bundle(
            &remote_address,
            &local_address,
            &mut store.session_store,
            &mut store.identity_store,
            &pre_key_bundle,
            SystemTime::now(),
            &mut csprng,
        )
        .await
        .map_err(|e| TwonlyError::Signal(e.to_string()))?;

        Ok(())
    }

    pub async fn encrypt_message(
        &self,
        name: String,
        device_id: u32,
        plaintext: Vec<u8>,
    ) -> Result<Vec<u8>> {
        let mut store_guard = self.store.lock().await;
        let store = &mut *store_guard;

        let d_id = DeviceId::try_from(device_id)
            .map_err(|_| TwonlyError::Generic(format!("Invalid device id: {}", device_id)))?;
        let remote_address = ProtocolAddress::new(name, d_id);
        let local_address =
            ProtocolAddress::new("local".to_string(), DeviceId::try_from(1).unwrap());

        let mut csprng = rand::rng();
        let now = SystemTime::now();

        let ciphertext = message_encrypt(
            &plaintext,
            &remote_address,
            &local_address,
            &mut store.session_store,
            &mut store.identity_store,
            now,
            &mut csprng,
        )
        .await
        .map_err(|e| TwonlyError::Signal(e.to_string()))?;

        Ok(ciphertext.serialize().to_vec())
    }

    pub async fn decrypt_message(
        &self,
        name: String,
        device_id: u32,
        ciphertext_bytes: Vec<u8>,
        is_prekey_message: bool,
    ) -> Result<Vec<u8>> {
        let mut store_guard = self.store.lock().await;
        let store = &mut *store_guard;

        let d_id = DeviceId::try_from(device_id)
            .map_err(|_| TwonlyError::Generic(format!("Invalid device id: {}", device_id)))?;
        let remote_address = ProtocolAddress::new(name, d_id);
        let local_address =
            ProtocolAddress::new("local".to_string(), DeviceId::try_from(1).unwrap());

        let plaintext = if is_prekey_message {
            let message = PreKeySignalMessage::try_from(&ciphertext_bytes[..])
                .map_err(|e| TwonlyError::Signal(e.to_string()))?;
            let mut csprng = rand::rng();
            libsignal_protocol::message_decrypt_prekey(
                &message,
                &remote_address,
                &local_address,
                &mut store.session_store,
                &mut store.identity_store,
                &mut store.pre_key_store,
                &store.signed_pre_key_store,
                &mut store.kyber_pre_key_store,
                &mut csprng,
            )
            .await
            .map_err(|e| TwonlyError::Signal(e.to_string()))?
        } else {
            let message = SignalMessage::try_from(&ciphertext_bytes[..])
                .map_err(|e| TwonlyError::Signal(e.to_string()))?;
            let mut csprng = rand::rng();
            libsignal_protocol::message_decrypt_signal(
                &message,
                &remote_address,
                &local_address,
                &mut store.session_store,
                &mut store.identity_store,
                &mut csprng,
            )
            .await
            .map_err(|e| TwonlyError::Signal(e.to_string()))?
        };

        Ok(plaintext.to_vec())
    }
}
