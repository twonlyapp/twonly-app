/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::error::{Result, TwonlyError};
use libsignal_protocol::{
    message_encrypt, process_prekey_bundle, CiphertextMessageType, DeviceId, Fingerprint,
    GenericSignedPreKey, IdentityKey, IdentityKeyPair, IdentityKeyStore, KyberPreKeyId,
    KyberPreKeyStore, PreKeyBundle, PreKeyId, PreKeySignalMessage, PreKeyStore, ProtocolAddress,
    PublicKey, SessionStore, SignalMessage, SignedPreKeyId, SignedPreKeyStore, Timestamp,
};
use std::sync::Arc;
use std::time::{SystemTime, UNIX_EPOCH};
use tokio::sync::Mutex;

use crate::bridge::get_twonly_flutter;
use crate::signal::assert_send::AssertSendFutureExt;
use crate::signal::store::DbSignalProtocolStore;
use rand::{Rng, SeedableRng};

pub(crate) struct RustSignalEngine {
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

// MAX(id) is not an allocator: one-time ECC keys are removed after use, and
// restored snapshots rewind every counter. Random positive i32 IDs also avoid
// two processes independently choosing the same next ID. The store refuses to
// overwrite a different key if a concurrent allocation still collides.
async fn unused_prekey_id(
    pool: &sqlx::SqlitePool, kind: &str, rng: &mut rand::rngs::StdRng,
) -> Result<u32> {
    loop {
        let id = rng.random_range(1..=i32::MAX as u32);
        let used = match kind {
            "ecc" => {
                sqlx::query_scalar!(
                    r#"SELECT EXISTS(SELECT 1 FROM signal_pre_keys WHERE pre_key_id = ?) AS "used!: bool""#,
                    id
                )
                .fetch_one(pool)
                .await?
            }
            "signed" => {
                sqlx::query_scalar!(
                    r#"SELECT EXISTS(SELECT 1 FROM signal_signed_pre_keys WHERE signed_pre_key_id = ?) AS "used!: bool""#,
                    id
                )
                .fetch_one(pool)
                .await?
            }
            "kyber" => {
                sqlx::query_scalar!(
                    r#"SELECT EXISTS(SELECT 1 FROM signal_kyber_pre_keys WHERE kyber_pre_key_id = ?) AS "used!: bool""#,
                    id
                )
                .fetch_one(pool)
                .await?
            }
            _ => unreachable!("unknown local prekey store"),
        };
        if !used {
            return Ok(id);
        }
    }
}

fn create_safety_number(
    local_id: &str, local_key_bytes: &[u8], remote_id: &str, remote_key_bytes: &[u8],
) -> Result<String> {
    let local_key = IdentityKey::decode(local_key_bytes)
        .map_err(|error| TwonlyError::Signal(error.to_string()))?;

    let remote_key = IdentityKey::decode(remote_key_bytes)
        .map_err(|error| TwonlyError::Signal(error.to_string()))?;

    Fingerprint::new(
        2,
        5_200,
        local_id.as_bytes(),
        &local_key,
        remote_id.as_bytes(),
        &remote_key,
    )
    .and_then(|fingerprint| fingerprint.display_string())
    .map_err(|error| TwonlyError::Signal(error.to_string()))
}

impl RustSignalEngine {
    /// A nonempty server bundle can still refer to keys lost in a restore.
    /// Compare public material and parse the private records, rather than
    /// treating a successful account lookup as proof we can receive messages.
    pub(crate) async fn matches_published_bundle(
        &self, user: &crate::api::proto::server_to_client::response::UserData,
    ) -> Result<bool> {
        let store = self.store.lock().await;
        let identity = store
            .identity_store
            .get_identity_key_pair()
            .assert_send()
            .await?;
        let registration = store
            .identity_store
            .get_local_registration_id()
            .assert_send()
            .await?;
        if user.public_identity_key.as_deref() != Some(identity.identity_key().serialize().as_ref())
            || user.registration_id != Some(i64::from(registration))
        {
            return Ok(false);
        }
        let Some(bundle) = user.pqc_bundle.as_ref() else {
            return Ok(false);
        };
        let signed = sqlx::query_scalar!(
            "SELECT record_bytes FROM signal_signed_pre_keys WHERE signed_pre_key_id = ?",
            bundle.ecc_signed_prekey_id
        )
        .fetch_optional(&store.pool)
        .await?;
        let Some(signed) = signed
            .and_then(|bytes| libsignal_protocol::SignedPreKeyRecord::deserialize(&bytes).ok())
        else {
            return Ok(false);
        };
        if signed.key_pair().is_err()
            || signed.public_key()?.serialize().as_ref() != bundle.ecc_signed_prekey.as_slice()
            || signed.signature()? != bundle.ecc_signed_prekey_signature
        {
            return Ok(false);
        }
        let kyber = sqlx::query_scalar!(
            "SELECT record_bytes FROM signal_kyber_pre_keys WHERE kyber_pre_key_id = ?",
            bundle.kyber_signed_prekey_id
        )
        .fetch_optional(&store.pool)
        .await?;
        let Some(kyber) =
            kyber.and_then(|bytes| libsignal_protocol::KyberPreKeyRecord::deserialize(&bytes).ok())
        else {
            return Ok(false);
        };
        if kyber.key_pair().is_err()
            || kyber.public_key()?.serialize().as_ref() != bundle.kyber_signed_prekey.as_slice()
            || kyber.signature()? != bundle.kyber_signed_prekey_signature
        {
            return Ok(false);
        }
        if let Some(prekey) = &bundle.prekey {
            let ecc = sqlx::query_scalar!(
                "SELECT record_bytes FROM signal_pre_keys WHERE pre_key_id = ?",
                prekey.ecc_pre_key_id
            )
            .fetch_optional(&store.pool)
            .await?;
            let Some(ecc) =
                ecc.and_then(|bytes| libsignal_protocol::PreKeyRecord::deserialize(&bytes).ok())
            else {
                return Ok(false);
            };
            if ecc.key_pair().is_err()
                || ecc.public_key()?.serialize().as_ref() != prekey.ecc_pre_key.as_slice()
            {
                return Ok(false);
            }
            let kyber = sqlx::query_scalar!(
                "SELECT record_bytes FROM signal_kyber_pre_keys WHERE kyber_pre_key_id = ?",
                prekey.kyber_pre_key_id
            )
            .fetch_optional(&store.pool)
            .await?;
            let Some(kyber) = kyber
                .and_then(|bytes| libsignal_protocol::KyberPreKeyRecord::deserialize(&bytes).ok())
            else {
                return Ok(false);
            };
            if kyber.key_pair().is_err()
                || kyber.public_key()?.serialize().as_ref() != prekey.kyber_pre_key.as_slice()
                || kyber.signature()? != prekey.kyber_pre_key_signature
            {
                return Ok(false);
            }
        }
        Ok(true)
    }

    pub async fn new(local_name: String) -> Result<Self> {
        let twonly = get_twonly_flutter()?;

        let pool = twonly.rust_db.read().await.pool.clone();

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
        pool: sqlx::SqlitePool, identity_key_pair_bytes: Vec<u8>, local_registration_id: u32,
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

    pub async fn get_identity_key(&self) -> Result<Vec<u8>> {
        let store = self.store.lock().await;

        let key_pair = store
            .identity_store
            .get_identity_key_pair()
            .assert_send()
            .await
            .map_err(|e| TwonlyError::Signal(e.to_string()))?;

        Ok(key_pair.identity_key().serialize().to_vec())
    }

    pub async fn get_contact_identity_key(&self, name: &str) -> Result<Option<Vec<u8>>> {
        let store = self.store.lock().await;

        let identity = sqlx::query_scalar!(
            r#"SELECT identity_key FROM signal_identities WHERE name = ?"#,
            name,
        )
        .fetch_optional(&store.pool)
        .await?;

        Ok(identity)
    }

    pub async fn get_safety_number(&self, contact_id: i64) -> Result<Option<String>> {
        let Some(contact_key_bytes) = self
            .get_contact_identity_key(&contact_id.to_string())
            .await?
        else {
            return Ok(None);
        };

        // Signal's standard 60-digit numeric fingerprint. Both participants
        // derive the same display string because libsignal sorts the two
        // independently generated fingerprint halves before displaying them.
        create_safety_number(
            &self.local_name,
            &self.get_identity_key().await?,
            &contact_id.to_string(),
            &contact_key_bytes,
        )
        .map(Some)
    }

    #[cfg(test)]
    fn generate_identity_key_pair() -> Result<Vec<u8>> {
        let mut csprng = rand::rngs::StdRng::from_os_rng();

        let key_pair = IdentityKeyPair::generate(&mut csprng);

        Ok(key_pair.serialize().to_vec())
    }

    pub async fn generate_bundle(&self) -> Result<FrbPreKeyBundle> {
        let mut store_guard = self.store.lock().await;

        let store = &mut *store_guard;

        let mut csprng = rand::rngs::StdRng::from_os_rng();

        let pre_key_id = unused_prekey_id(&store.pool, "ecc", &mut csprng).await?;
        let signed_pre_key_id = unused_prekey_id(&store.pool, "signed", &mut csprng).await?;
        let kyber_pre_key_id = unused_prekey_id(&store.pool, "kyber", &mut csprng).await?;

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
            signed_pre_key_id,
            signed_pre_key_public: signed_pre_key_pair.public_key.serialize().to_vec(),
            signed_pre_key_signature: signature.to_vec(),
            kyber_pre_key_id,
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

        for _ in 0..30 {
            let kyber_pre_key_id = unused_prekey_id(&store.pool, "kyber", &mut csprng).await?;
            let pre_key_id = unused_prekey_id(&store.pool, "ecc", &mut csprng).await?;

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
        &self, name: String, device_id: u32, bundle: FrbPreKeyBundle,
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

    /// Retires the session with a peer so a fresh one can replace it.
    ///
    /// The current state is archived rather than dropped: libsignal keeps
    /// trying archived states on decrypt, so messages the peer sent on chains
    /// we can still follow keep arriving while the broken chain stops being
    /// the one new traffic is measured against. With no current state left,
    /// encrypting for the peer reports the session as missing, which
    /// `encrypt_v2_with_session_recovery` already repairs from a fresh prekey
    /// bundle, and an inbound prekey message installs a new session directly.
    ///
    /// `hard` deletes the record instead, dropping the archived states too.
    /// Only a user-initiated reset should ask for that: it makes every message
    /// still in flight from the peer undecryptable.
    ///
    /// Returns whether a session existed.
    pub async fn reset_session(&self, name: &str, device_id: u32, hard: bool) -> Result<bool> {
        let mut store_guard = self.store.lock().await;

        let store = &mut *store_guard;

        let d_id = DeviceId::try_from(device_id)
            .map_err(|_| TwonlyError::Generic(format!("Invalid device id: {}", device_id)))?;

        let address = ProtocolAddress::new(name.to_owned(), d_id);

        if hard {
            let device_id_value: u32 = device_id;

            let deleted = sqlx::query!(
                r#"DELETE FROM signal_sessions WHERE name = ? AND device_id = ?"#,
                name,
                device_id_value,
            )
            .execute(&store.pool)
            .await?
            .rows_affected();

            tracing::warn!(name, device_id, "deleted the signal session");

            return Ok(deleted != 0);
        }

        let Some(mut record) = store
            .session_store
            .load_session(&address)
            .assert_send()
            .await
            .map_err(|e| TwonlyError::Signal(e.to_string()))?
        else {
            return Ok(false);
        };

        // Idempotent: a record whose current state was already archived is left
        // alone by libsignal, and the archived list is capped, so repeated
        // resets for the same peer cannot grow the record without bound.
        record
            .archive_current_state()
            .map_err(|e| TwonlyError::Signal(e.to_string()))?;

        store
            .session_store
            .store_session(&address, &record)
            .assert_send()
            .await
            .map_err(|e| TwonlyError::Signal(e.to_string()))?;

        tracing::warn!(name, device_id, "archived the signal session for a reset");

        Ok(true)
    }

    pub async fn encrypt_message(
        &self, name: String, device_id: u32, plaintext: Vec<u8>,
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

        res.extend_from_slice(serialized);

        res.push(ciphertext.message_type() as u8);

        Ok(res)
    }

    pub async fn decrypt_message(
        &self, name: String, device_id: u32, ciphertext: Vec<u8>,
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
                // Classified rather than stringified: the caller has to tell a
                // session that can never open this message from a duplicate or
                // an identity change. See `TwonlyError::SignalSessionUnusable`.
                .map_err(TwonlyError::from)?
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
                .map_err(TwonlyError::from)?
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

    #[test]

    fn safety_number_matches_signal_format_and_is_symmetric() {
        let alice_key =
            hex::decode("0506863bc66d02b40d27b8d49ca7c09e9239236f9d7d25d6fcca5ce13c7064d868")
                .unwrap();

        let bob_key =
            hex::decode("05f781b6fb32fed9ba1cf2de978d4d5da28dc34046ae814402b5c0dbd96fda907b")
                .unwrap();

        let alice =
            create_safety_number("+14152222222", &alice_key, "+14153333333", &bob_key).unwrap();

        let bob =
            create_safety_number("+14153333333", &bob_key, "+14152222222", &alice_key).unwrap();

        assert_eq!(alice, bob);

        assert_eq!(
            alice,
            "300354477692869396892869876765458257569162576843440918079131"
        );

        assert_eq!(alice.len(), 60);

        assert!(alice.bytes().all(|byte| byte.is_ascii_digit()));
    }

    async fn create_test_engine(name: &str) -> (RustSignalEngine, tempfile::TempDir) {
        let dir = tempdir().unwrap();

        let db_path = dir.path().join(format!("{}.db", name));

        let _db_url = format!("sqlite://{}?mode=rwc", db_path.to_str().unwrap());

        // create the file manually just to be sure
        std::fs::File::create(&db_path).unwrap();

        let db = crate::database::signal::Database::new(
            &db_path.to_str().unwrap().to_string(),
            None,
            false,
        )
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

        assert_eq!(prekeys.len(), 30);

        for prekey in prekeys {
            assert!(!prekey.ecc_pre_key.is_empty());

            assert!(!prekey.kyber_pre_key.is_empty());

            assert!(!prekey.kyber_pre_key_signature.is_empty());
        }
    }

    fn published_bundle(
        bundle: &FrbPreKeyBundle,
    ) -> crate::api::proto::server_to_client::response::UserData {
        use crate::api::proto::server_to_client::response::{PqcBundle, UserData};
        UserData {
            public_identity_key: Some(bundle.identity_key.clone()),
            registration_id: Some(i64::from(bundle.registration_id)),
            pqc_bundle: Some(PqcBundle {
                ecc_signed_prekey_id: i64::from(bundle.signed_pre_key_id),
                ecc_signed_prekey: bundle.signed_pre_key_public.clone(),
                ecc_signed_prekey_signature: bundle.signed_pre_key_signature.clone(),
                kyber_signed_prekey_id: i64::from(bundle.kyber_pre_key_id),
                kyber_signed_prekey: bundle.kyber_pre_key_public.clone(),
                kyber_signed_prekey_signature: bundle.kyber_pre_key_signature.clone(),
                prekey: None,
            }),
            ..Default::default()
        }
    }

    #[tokio::test]
    async fn published_bundle_requires_matching_private_records_not_just_an_existing_bundle() {
        let (engine, _dir) = create_test_engine("bob").await;
        let bundle = engine.generate_bundle().await.unwrap();
        let user = published_bundle(&bundle);
        assert!(engine.matches_published_bundle(&user).await.unwrap());
        let mut wrong = user.clone();
        wrong.pqc_bundle.as_mut().unwrap().ecc_signed_prekey[1] ^= 1;
        assert!(!engine.matches_published_bundle(&wrong).await.unwrap());
        let mut wrong_identity = user.clone();
        wrong_identity.public_identity_key.as_mut().unwrap()[1] ^= 1;
        assert!(!engine
            .matches_published_bundle(&wrong_identity)
            .await
            .unwrap());
        let pool = engine.store.lock().await.pool.clone();
        sqlx::query("DELETE FROM signal_signed_pre_keys")
            .execute(&pool)
            .await
            .unwrap();
        assert!(!engine.matches_published_bundle(&user).await.unwrap());
        let repaired = engine.generate_bundle().await.unwrap();
        assert!(engine
            .matches_published_bundle(&published_bundle(&repaired))
            .await
            .unwrap());
        sqlx::query("UPDATE signal_kyber_pre_keys SET record_bytes = x'00'")
            .execute(&pool)
            .await
            .unwrap();
        assert!(!engine
            .matches_published_bundle(&published_bundle(&repaired))
            .await
            .unwrap());
    }

    #[tokio::test]
    async fn private_prekeys_cannot_be_overwritten_by_another_generator() {
        let (engine, _dir) = create_test_engine("bob").await;
        let bundle = engine.generate_bundle().await.unwrap();
        let mut store = engine.store.lock().await;
        let original = store
            .signed_pre_key_store
            .get_signed_pre_key(bundle.signed_pre_key_id.into())
            .await
            .unwrap();
        let replacement = libsignal_protocol::SignedPreKeyRecord::new(
            bundle.signed_pre_key_id.into(),
            Timestamp::from_epoch_millis(1),
            &libsignal_protocol::KeyPair::generate(&mut StdRng::from_os_rng()),
            &[0; 64],
        );
        let error = store
            .signed_pre_key_store
            .save_signed_pre_key(bundle.signed_pre_key_id.into(), &replacement)
            .await
            .unwrap_err();
        assert!(matches!(
            TwonlyError::from(error),
            TwonlyError::SignalStorage(_)
        ));
        let retained = store
            .signed_pre_key_store
            .get_signed_pre_key(bundle.signed_pre_key_id.into())
            .await
            .unwrap();
        assert_eq!(original.serialize().unwrap(), retained.serialize().unwrap());
        store
            .signed_pre_key_store
            .save_signed_pre_key(bundle.signed_pre_key_id.into(), &original)
            .await
            .unwrap();
    }

    #[tokio::test]
    async fn storage_failure_does_not_masquerade_as_a_missing_prekey_or_broken_session() {
        let (alice, _alice_dir) = create_test_engine("alice").await;
        let (bob, _bob_dir) = create_test_engine("bob").await;
        alice
            .process_prekey_bundle("bob".into(), 1, bob.generate_bundle().await.unwrap())
            .await
            .unwrap();
        let ciphertext = alice
            .encrypt_message("bob".into(), 1, b"persist me".to_vec())
            .await
            .unwrap();
        bob.store.lock().await.pool.close().await;
        let error = bob
            .decrypt_message("alice".into(), 1, ciphertext)
            .await
            .unwrap_err();
        assert!(matches!(error, TwonlyError::SignalStorage(_)), "{error:?}");
    }

    #[tokio::test]
    async fn missing_signed_prekey_is_reported_as_local_key_repair() {
        let (alice, _alice_dir) = create_test_engine("alice").await;
        let (bob, _bob_dir) = create_test_engine("bob").await;
        alice
            .process_prekey_bundle("bob".into(), 1, bob.generate_bundle().await.unwrap())
            .await
            .unwrap();
        let ciphertext = alice
            .encrypt_message("bob".into(), 1, b"retry after publication".to_vec())
            .await
            .unwrap();
        let pool = bob.store.lock().await.pool.clone();
        sqlx::query("DELETE FROM signal_signed_pre_keys")
            .execute(&pool)
            .await
            .unwrap();
        let error = bob
            .decrypt_message("alice".into(), 1, ciphertext)
            .await
            .unwrap_err();
        assert!(
            matches!(error, TwonlyError::SignalPreKeyUnavailable(_)),
            "{error:?}"
        );
        // Repair publication first, then let the sender retire its old half
        // and re-encrypt its retained plaintext using the repaired bundle.
        let repaired = bob.generate_bundle().await.unwrap();
        assert!(bob
            .matches_published_bundle(&published_bundle(&repaired))
            .await
            .unwrap());
        alice.reset_session("bob", 1, false).await.unwrap();
        alice
            .process_prekey_bundle("bob".into(), 1, repaired)
            .await
            .unwrap();
        assert_eq!(
            ping(&alice, &bob, "retry after publication").await.unwrap(),
            b"retry after publication"
        );
        assert_eq!(
            ping(&bob, &alice, "reply after repair").await.unwrap(),
            b"reply after repair"
        );
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

    /// Encrypts on one engine and decrypts on the other.
    async fn ping(from: &RustSignalEngine, to: &RustSignalEngine, text: &str) -> Result<Vec<u8>> {
        let ciphertext = from
            .encrypt_message(to.local_name.clone(), 1, text.as_bytes().to_vec())
            .await?;

        to.decrypt_message(from.local_name.clone(), 1, ciphertext)
            .await
    }

    /// Overwrites a peer's session record, the way restoring a backup puts an
    /// older signal database back in place.
    async fn restore_session(engine: &RustSignalEngine, name: &str, record: &[u8]) {
        let store = engine.store.lock().await;

        sqlx::query!(
            "UPDATE signal_sessions SET record_bytes = ? WHERE name = ? AND device_id = 1",
            record,
            name,
        )
        .execute(&store.pool)
        .await
        .unwrap();
    }

    async fn session_record(engine: &RustSignalEngine, name: &str) -> Vec<u8> {
        let store = engine.store.lock().await;

        sqlx::query_scalar!(
            "SELECT record_bytes FROM signal_sessions WHERE name = ? AND device_id = 1",
            name,
        )
        .fetch_one(&store.pool)
        .await
        .unwrap()
    }

    /// A restored backup rewinds one side's ratchet behind the other's. The
    /// session cannot be decrypted with again, the failure is reported as such,
    /// and a reset plus a fresh prekey bundle brings the pair back.
    #[tokio::test]

    async fn a_restored_session_is_reported_unusable_and_recovers_after_a_reset() {
        let (alice, _alice_dir) = create_test_engine("alice").await;

        let (bob, _bob_dir) = create_test_engine("bob").await;

        alice
            .process_prekey_bundle("bob".to_string(), 1, bob.generate_bundle().await.unwrap())
            .await
            .unwrap();

        assert_eq!(ping(&alice, &bob, "one").await.unwrap(), b"one");

        assert_eq!(ping(&bob, &alice, "two").await.unwrap(), b"two");

        // The state a backup taken at this point would carry.
        let backup = session_record(&bob, "alice").await;

        // Both sides keep ratcheting, so the archive falls behind a ratchet
        // step whose private key it never held.
        for _ in 0..3 {
            ping(&alice, &bob, "before").await.unwrap();

            ping(&bob, &alice, "before").await.unwrap();
        }

        restore_session(&bob, "alice", &backup).await;

        let ciphertext = alice
            .encrypt_message("bob".to_string(), 1, b"after the restore".to_vec())
            .await
            .unwrap();

        let error = bob
            .decrypt_message("alice".to_string(), 1, ciphertext.clone())
            .await
            .expect_err("a rewound session cannot open a message from the peer's current chain");

        assert!(
            matches!(error, TwonlyError::SignalSessionUnusable(_)),
            "a diverged ratchet has to be classified as unusable, got: {error:?}"
        );

        // Retrying the very same ciphertext is what the old error path did, and
        // it fails the same way -- which is why a reset is the only repair.
        assert!(bob
            .decrypt_message("alice".to_string(), 1, ciphertext)
            .await
            .is_err());

        // Bob retires his half and asks Alice for a new session; Alice retires
        // hers and builds one from Bob's current bundle.
        assert!(bob.reset_session("alice", 1, false).await.unwrap());

        assert!(alice.reset_session("bob", 1, false).await.unwrap());

        alice
            .process_prekey_bundle("bob".to_string(), 1, bob.generate_bundle().await.unwrap())
            .await
            .unwrap();

        assert_eq!(ping(&alice, &bob, "after").await.unwrap(), b"after");

        assert_eq!(ping(&bob, &alice, "back").await.unwrap(), b"back");
    }

    /// Archiving keeps the states a peer may still be sending on, so messages
    /// that crossed the reset in flight are not lost with it.
    #[tokio::test]

    async fn a_reset_still_decrypts_messages_sent_before_it() {
        let (alice, _alice_dir) = create_test_engine("alice").await;

        let (bob, _bob_dir) = create_test_engine("bob").await;

        alice
            .process_prekey_bundle("bob".to_string(), 1, bob.generate_bundle().await.unwrap())
            .await
            .unwrap();

        // Bob only has a record once he has received from Alice.
        assert_eq!(ping(&alice, &bob, "hello").await.unwrap(), b"hello");

        let in_flight = alice
            .encrypt_message("bob".to_string(), 1, b"sent before the reset".to_vec())
            .await
            .unwrap();

        assert!(bob.reset_session("alice", 1, false).await.unwrap());

        assert_eq!(
            bob.decrypt_message("alice".to_string(), 1, in_flight)
                .await
                .unwrap(),
            b"sent before the reset"
        );

        // A hard reset is the user-initiated one and does drop them.
        let in_flight = alice
            .encrypt_message("bob".to_string(), 1, b"dropped".to_vec())
            .await
            .unwrap();

        assert!(bob.reset_session("alice", 1, true).await.unwrap());

        assert!(bob
            .decrypt_message("alice".to_string(), 1, in_flight)
            .await
            .is_err());

        // Resetting a peer we have no session with is not an error.
        assert!(!bob.reset_session("carol", 1, false).await.unwrap());
    }

    /// The user-initiated reset: the record is gone, nothing encrypts for the
    /// peer until a fresh bundle builds a new session, and that one works.
    #[tokio::test]

    async fn hard_reset_deletes_and_allows_rebuilding_a_contact_session() {
        let (alice, _alice_dir) = create_test_engine("alice").await;

        let (bob, _bob_dir) = create_test_engine("bob").await;

        alice
            .process_prekey_bundle("bob".to_string(), 1, bob.generate_bundle().await.unwrap())
            .await
            .unwrap();

        assert!(alice.reset_session("bob", 1, true).await.unwrap());

        assert!(!alice.reset_session("bob", 1, true).await.unwrap());

        assert!(alice
            .encrypt_message("bob".to_string(), 1, b"missing".to_vec())
            .await
            .is_err());

        alice
            .process_prekey_bundle("bob".to_string(), 1, bob.generate_bundle().await.unwrap())
            .await
            .unwrap();

        assert_eq!(ping(&alice, &bob, "rebuilt").await.unwrap(), b"rebuilt");
    }

    /// A message decrypted twice is a duplicate, for prekey and whisper
    /// messages alike, and never reported as an unusable session.
    #[tokio::test]

    async fn decrypting_a_message_twice_reports_a_duplicate() {
        let (alice, _alice_dir) = create_test_engine("alice").await;

        let (bob, _bob_dir) = create_test_engine("bob").await;

        alice
            .process_prekey_bundle("bob".to_string(), 1, bob.generate_bundle().await.unwrap())
            .await
            .unwrap();

        let prekey_message = alice
            .encrypt_message("bob".to_string(), 1, b"first".to_vec())
            .await
            .unwrap();

        assert_eq!(
            prekey_message.last(),
            Some(&(CiphertextMessageType::PreKey as u8))
        );

        bob.decrypt_message("alice".to_string(), 1, prekey_message.clone())
            .await
            .unwrap();

        let error = bob
            .decrypt_message("alice".to_string(), 1, prekey_message)
            .await
            .unwrap_err();

        assert!(
            matches!(error, TwonlyError::SignalDuplicateMessage(_)),
            "{error}"
        );

        // After Bob's reply Alice no longer needs a PreKey message.
        ping(&bob, &alice, "reply").await.unwrap();

        let whisper_message = alice
            .encrypt_message("bob".to_string(), 1, b"second".to_vec())
            .await
            .unwrap();

        assert_eq!(
            whisper_message.last(),
            Some(&(CiphertextMessageType::Whisper as u8))
        );

        bob.decrypt_message("alice".to_string(), 1, whisper_message.clone())
            .await
            .unwrap();

        let error = bob
            .decrypt_message("alice".to_string(), 1, whisper_message)
            .await
            .unwrap_err();

        assert!(
            matches!(error, TwonlyError::SignalDuplicateMessage(_)),
            "{error}"
        );
    }

    #[tokio::test]

    async fn test_twonly_api_100_messages() -> std::result::Result<(), Box<dyn std::error::Error>> {
        use crate::database::signal::Database;

        let _ = pretty_env_logger::try_init();

        // 1. Setup in-memory databases
        let alice_db = Database::new(&"sqlite::memory:".to_string(), None, false).await?;

        alice_db.run_migrations().await?;

        let bob_db = Database::new(&"sqlite::memory:".to_string(), None, false).await?;

        bob_db.run_migrations().await?;

        // 2. Setup Alice and Bob identity keys
        let alice_identity_bytes = RustSignalEngine::generate_identity_key_pair()?;

        let bob_identity_bytes = RustSignalEngine::generate_identity_key_pair()?;

        // 3. Initialize engines with the DB pools
        let alice_engine = RustSignalEngine::new_with_pool(
            alice_db.pool.clone(),
            alice_identity_bytes,
            1234,
            "alice".to_string(),
        )?;

        let bob_engine = RustSignalEngine::new_with_pool(
            bob_db.pool.clone(),
            bob_identity_bytes,
            5678,
            "bob".to_string(),
        )?;

        // 4. Bob generates a bundle
        let bob_bundle = bob_engine.generate_bundle().await?;

        // 5. Alice processes Bob's bundle
        alice_engine
            .process_prekey_bundle("bob".to_string(), 1, bob_bundle)
            .await?;

        // 6. Exchange 100 messages
        let mut alice_to_bob = true;

        for i in 1..=100 {
            if alice_to_bob {
                let plaintext = format!("Message {} from Alice to Bob", i).into_bytes();

                let ciphertext = alice_engine
                    .encrypt_message("bob".to_string(), 1, plaintext.clone())
                    .await?;

                let decrypted = bob_engine
                    .decrypt_message("alice".to_string(), 1, ciphertext)
                    .await?;

                assert_eq!(plaintext, decrypted);
            } else {
                let plaintext = format!("Message {} from Bob to Alice", i).into_bytes();

                let ciphertext = bob_engine
                    .encrypt_message("alice".to_string(), 1, plaintext.clone())
                    .await?;

                let decrypted = alice_engine
                    .decrypt_message("bob".to_string(), 1, ciphertext)
                    .await?;

                assert_eq!(plaintext, decrypted);
            }

            alice_to_bob = !alice_to_bob;
        }

        Ok(())
    }
}
