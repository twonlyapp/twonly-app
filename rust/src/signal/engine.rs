use crate::error::{Result, TwonlyError};
use libsignal_protocol::{
    message_encrypt, process_prekey_bundle, CiphertextMessageType, DeviceId, GenericSignedPreKey,
    IdentityKey, IdentityKeyPair, IdentityKeyStore, KyberPreKeyId, KyberPreKeyStore, PreKeyBundle,
    PreKeyId, PreKeySignalMessage, PreKeyStore, ProtocolAddress, PublicKey, SignalMessage,
    SignedPreKeyId, SignedPreKeyStore, Timestamp,
};
use std::sync::Arc;
use std::time::{SystemTime, UNIX_EPOCH};
use tokio::sync::Mutex;

use crate::bridge::get_twonly_flutter;
use crate::signal::assert_send::AssertSendFutureExt;
use crate::signal::store::DbSignalProtocolStore;
use rand::SeedableRng;

pub struct RustSignalEngine {
    store: Arc<Mutex<DbSignalProtocolStore>>,
    local_name: String,
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

pub struct FrbPqcPreKey {
    pub ecc_pre_key_id: u32,
    pub ecc_pre_key: Vec<u8>,
    pub kyber_pre_key_id: u32,
    pub kyber_pre_key: Vec<u8>,
    pub kyber_pre_key_signature: Vec<u8>,
}

impl RustSignalEngine {
    pub async fn new(local_name: String) -> Result<Self> {
        let twonly = get_twonly_flutter()?;
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
            local_name,
        })
    }

    pub fn new_with_pool(
        pool: sqlx::SqlitePool,
        identity_key_pair_bytes: Vec<u8>,
        local_registration_id: u32,
        local_name: String,
    ) -> Result<Self> {
        let identity_key_pair = IdentityKeyPair::try_from(&identity_key_pair_bytes[..])
            .map_err(|e| TwonlyError::Signal(e.to_string()))?;

        let store = DbSignalProtocolStore::new(pool, identity_key_pair, local_registration_id);

        Ok(Self {
            store: Arc::new(Mutex::new(store)),
            local_name,
        })
    }

    pub fn generate_identity_key_pair() -> Result<Vec<u8>> {
        let mut csprng = rand::rngs::StdRng::from_os_rng();
        let key_pair = IdentityKeyPair::generate(&mut csprng);
        Ok(key_pair.serialize().to_vec())
    }

    pub async fn generate_bundle(&self) -> Result<FrbPreKeyBundle> {
        let mut store_guard = self.store.lock().await;
        let store = &mut *store_guard;
        let mut csprng = rand::rngs::StdRng::from_os_rng();

        let pre_key_id: u32 = {
            let id: u32 =
                sqlx::query_scalar("SELECT COALESCE(MAX(pre_key_id), 0) FROM signal_pre_keys")
                    .fetch_one(&store.pool)
                    .await?;
            if id > 16_777_215 {
                1
            } else {
                id + 1
            }
        };

        let signed_pre_key_id: u32 = {
            let id: u32 = sqlx::query_scalar(
                "SELECT COALESCE(MAX(signed_pre_key_id), 0) FROM signal_signed_pre_keys",
            )
            .fetch_one(&store.pool)
            .await?;
            if id > 16_777_215 {
                1
            } else {
                id + 1
            }
        };

        let kyber_pre_key_id: u32 = {
            let id: u32 = sqlx::query_scalar(
                "SELECT COALESCE(MAX(kyber_pre_key_id), 0) FROM signal_kyber_pre_keys",
            )
            .fetch_one(&store.pool)
            .await?;
            if id > 16_777_215 {
                1
            } else {
                id + 1
            }
        };

        let pre_key_pair = libsignal_protocol::KeyPair::generate(&mut csprng);
        store
            .pre_key_store
            .save_pre_key(
                pre_key_id.into(),
                &libsignal_protocol::PreKeyRecord::new(pre_key_id.into(), &pre_key_pair),
            )
            .assert_send()
            .await
            .map_err(|e| TwonlyError::Signal(e.to_string()))?;

        let signed_pre_key_pair = libsignal_protocol::KeyPair::generate(&mut csprng);
        let signature = store
            .identity_store
            .get_identity_key_pair()
            .assert_send()
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
                .map_err(|e| TwonlyError::Signal(e.to_string()))?
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
            .assert_send()
            .await
            .map_err(|e| TwonlyError::Signal(e.to_string()))?;

        let kyber_key_pair = libsignal_protocol::kem::KeyPair::generate(
            libsignal_protocol::kem::KeyType::Kyber1024,
            &mut csprng,
        );
        let kyber_signature = store
            .identity_store
            .get_identity_key_pair()
            .assert_send()
            .await
            .map_err(|e| TwonlyError::Signal(e.to_string()))?
            .private_key()
            .calculate_signature_for_multipart_message(
                &[&kyber_key_pair.public_key.serialize()],
                &mut csprng,
            )
            .map_err(|e| TwonlyError::Signal(e.to_string()))?;
        let kyber_sig_arr: [u8; 64] = kyber_signature[..]
            .try_into()
            .map_err(|e: std::array::TryFromSliceError| TwonlyError::Signal(e.to_string()))?;
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
            .assert_send()
            .await
            .map_err(|e| TwonlyError::Signal(e.to_string()))?;

        Ok(FrbPreKeyBundle {
            registration_id: store
                .identity_store
                .get_local_registration_id()
                .assert_send()
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
                .assert_send()
                .await
                .map_err(|e| TwonlyError::Signal(e.to_string()))?
                .identity_key()
                .serialize()
                .to_vec(),
        })
    }

    pub async fn generate_pqc_prekeys(&self) -> Result<Vec<FrbPqcPreKey>> {
        let mut store_guard = self.store.lock().await;
        let store = &mut *store_guard;
        let mut csprng = rand::rngs::StdRng::from_os_rng();
        let mut prekeys = vec![];

        let timestamp = Timestamp::from_epoch_millis(
            SystemTime::now()
                .duration_since(UNIX_EPOCH)
                .map_err(|e| TwonlyError::Signal(e.to_string()))?
                .as_millis() as u64,
        );

        let mut kyber_pre_key_id: u32 = {
            let id = sqlx::query_scalar(
                "SELECT COALESCE(MAX(kyber_pre_key_id), 0) FROM signal_kyber_pre_keys",
            )
            .fetch_one(&store.pool)
            .await?;

            if id > 16_777_215 {
                1
            } else {
                id
            }
        };

        let mut pre_key_id: u32 = {
            let id =
                sqlx::query_scalar("SELECT COALESCE(MAX(pre_key_id), 0)  FROM signal_pre_keys")
                    .fetch_one(&store.pool)
                    .await?;

            if id > 16_777_215 {
                1
            } else {
                id
            }
        };

        for _ in 0..30 {
            kyber_pre_key_id += 1;
            pre_key_id += 1;
            let kyber_key_pair = libsignal_protocol::kem::KeyPair::generate(
                libsignal_protocol::kem::KeyType::Kyber1024,
                &mut csprng,
            );

            let kyber_pre_key_signature = store
                .identity_store
                .get_identity_key_pair()
                .assert_send()
                .await
                .map_err(|e| TwonlyError::Signal(e.to_string()))?
                .private_key()
                .calculate_signature_for_multipart_message(
                    &[&kyber_key_pair.public_key.serialize()],
                    &mut csprng,
                )
                .map_err(|e| TwonlyError::Signal(e.to_string()))?;

            let kyber_sig_arr: [u8; 64] = kyber_pre_key_signature[..]
                .try_into()
                .map_err(|e: std::array::TryFromSliceError| TwonlyError::Signal(e.to_string()))?;

            let record = libsignal_protocol::KyberPreKeyRecord::new(
                kyber_pre_key_id.into(),
                timestamp,
                &kyber_key_pair,
                &kyber_sig_arr,
            );

            store
                .kyber_pre_key_store
                .save_kyber_pre_key(kyber_pre_key_id.into(), &record)
                .assert_send()
                .await
                .map_err(|e| TwonlyError::Signal(e.to_string()))?;

            let ecc_key_par = libsignal_protocol::KeyPair::generate(&mut csprng);

            let record = libsignal_protocol::PreKeyRecord::new(pre_key_id.into(), &ecc_key_par);

            store
                .pre_key_store
                .save_pre_key(pre_key_id.into(), &record)
                .assert_send()
                .await
                .map_err(|e| TwonlyError::Signal(e.to_string()))?;

            prekeys.push(FrbPqcPreKey {
                kyber_pre_key_id,
                kyber_pre_key: kyber_key_pair.public_key.serialize().to_vec(),
                kyber_pre_key_signature: kyber_pre_key_signature.to_vec(),
                ecc_pre_key_id: pre_key_id,
                ecc_pre_key: ecc_key_par.public_key.serialize().to_vec(),
            });
        }

        Ok(prekeys)
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
        let local_address = ProtocolAddress::new(
            self.local_name.clone(),
            DeviceId::try_from(1)
                .map_err(|_| TwonlyError::Generic("Invalid device id 1".to_string()))?,
        );

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

        let mut csprng = rand::rngs::StdRng::from_os_rng();

        let pre_key_bundle = PreKeyBundle::new(
            bundle.registration_id,
            DeviceId::try_from(bundle.device_id).map_err(|_| {
                TwonlyError::Generic(format!("Invalid device id: {}", bundle.device_id))
            })?,
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
        .assert_send()
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
        let local_address = ProtocolAddress::new(
            self.local_name.clone(),
            DeviceId::try_from(1)
                .map_err(|_| TwonlyError::Generic("Invalid device id 1".to_string()))?,
        );

        let mut csprng = rand::rngs::StdRng::from_os_rng();
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
        .assert_send()
        .await
        .map_err(|e| TwonlyError::Signal(e.to_string()))?;

        let serialized = ciphertext.serialize();
        let mut res = Vec::with_capacity(serialized.len() + 1);
        res.extend_from_slice(&serialized);
        res.push(ciphertext.message_type() as u8);

        Ok(res)
    }

    pub async fn decrypt_message(
        &self,
        name: String,
        device_id: u32,
        ciphertext: Vec<u8>,
    ) -> Result<Vec<u8>> {
        let mut store_guard = self.store.lock().await;
        let store = &mut *store_guard;

        let d_id = DeviceId::try_from(device_id)
            .map_err(|_| TwonlyError::Generic(format!("Invalid device id: {}", device_id)))?;
        let remote_address = ProtocolAddress::new(name, d_id);
        let local_address = ProtocolAddress::new(
            self.local_name.clone(),
            DeviceId::try_from(1)
                .map_err(|_| TwonlyError::Signal("Invalid device id 1".to_string()))?,
        );

        let (msg_type, ciphertext) = ciphertext
            .split_last()
            .ok_or(TwonlyError::Generic("Invalid ciphertext".to_string()))?;

        let msg_type = CiphertextMessageType::try_from(*msg_type)
            .map_err(|_| TwonlyError::Signal("Invalid message type".to_string()))?;

        let mut csprng = rand::rngs::StdRng::from_os_rng();

        let plaintext = match msg_type {
            CiphertextMessageType::Whisper => {
                let message = SignalMessage::try_from(ciphertext)
                    .map_err(|e| TwonlyError::Signal(e.to_string()))?;
                libsignal_protocol::message_decrypt_signal(
                    &message,
                    &remote_address,
                    &local_address,
                    &mut store.session_store,
                    &mut store.identity_store,
                    &mut csprng,
                )
                .assert_send()
                .await
                .map_err(|e| TwonlyError::Signal(e.to_string()))?
            }
            CiphertextMessageType::PreKey => {
                let message = PreKeySignalMessage::try_from(ciphertext)
                    .map_err(|e| TwonlyError::Signal(e.to_string()))?;
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
                .assert_send()
                .await
                .map_err(|e| TwonlyError::Signal(e.to_string()))?
            }
            _ => {
                return Err(TwonlyError::Signal("Invalid message type".to_string()));
            }
        };

        Ok(plaintext.to_vec())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use libsignal_protocol::IdentityKeyPair;
    use rand::rngs::StdRng;
    use tempfile::tempdir;

    async fn create_test_engine(name: &str) -> (RustSignalEngine, tempfile::TempDir) {
        let dir = tempdir().unwrap();
        let db_path = dir.path().join(format!("{}.db", name));

        let _db_url = format!("sqlite://{}?mode=rwc", db_path.to_str().unwrap());
        // create the file manually just to be sure
        std::fs::File::create(&db_path).unwrap();

        let db =
            crate::database::Database::new(&db_path.to_str().unwrap().to_string(), None, false)
                .await
                .unwrap();
        db.run_migrations().await.unwrap();
        let pool = db.pool.clone();

        let mut csprng = StdRng::from_os_rng();
        let identity_key_pair = IdentityKeyPair::generate(&mut csprng);

        let store =
            DbSignalProtocolStore::new(pool, identity_key_pair, rand::Rng::random(&mut csprng));

        (
            RustSignalEngine {
                store: Arc::new(Mutex::new(store)),
                local_name: name.to_string(),
            },
            dir,
        )
    }

    #[tokio::test]
    async fn test_generate_pqc_prekeys() {
        let (engine, _dir) = create_test_engine("alice").await;
        let prekeys = engine.generate_pqc_prekeys().await.unwrap();
        assert_eq!(prekeys.len(), 50);
        for prekey in prekeys {
            assert!(prekey.ecc_pre_key.len() > 0);
            assert!(prekey.kyber_pre_key.len() > 0);
            assert!(prekey.kyber_pre_key_signature.len() > 0);
        }
    }

    #[tokio::test]
    async fn test_v2_end_to_end_encryption() {
        let (alice_engine, _alice_dir) = create_test_engine("alice").await;
        let (bob_engine, _bob_dir) = create_test_engine("bob").await;

        // Bob generates a V2 bundle
        let bob_bundle = bob_engine.generate_bundle().await.unwrap();

        let bundle = FrbPreKeyBundle {
            registration_id: bob_bundle.registration_id,
            device_id: bob_bundle.device_id,
            pre_key_id: bob_bundle.pre_key_id,
            pre_key_public: bob_bundle.pre_key_public,
            signed_pre_key_id: bob_bundle.signed_pre_key_id,
            signed_pre_key_public: bob_bundle.signed_pre_key_public,
            signed_pre_key_signature: bob_bundle.signed_pre_key_signature,
            identity_key: bob_bundle.identity_key,
            kyber_pre_key_id: bob_bundle.kyber_pre_key_id,
            kyber_pre_key_public: bob_bundle.kyber_pre_key_public,
            kyber_pre_key_signature: bob_bundle.kyber_pre_key_signature,
        };

        // Alice processes Bob's bundle
        alice_engine
            .process_prekey_bundle("bob".to_string(), 1, bundle)
            .await
            .unwrap();

        // Alice encrypts a message
        let plaintext = b"Hello Post-Quantum World!";
        let ciphertext = alice_engine
            .encrypt_message("bob".to_string(), 1, plaintext.to_vec())
            .await
            .unwrap();

        // Bob decrypts the message
        let decrypted = bob_engine
            .decrypt_message("alice".to_string(), 1, ciphertext)
            .await
            .unwrap();

        assert_eq!(plaintext.to_vec(), decrypted);
    }
}
