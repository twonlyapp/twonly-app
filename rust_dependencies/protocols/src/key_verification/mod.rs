use crate::key_verification::{error::KeyVerificationError, traits::KeyVerificationStore};
use crate::user_discovery::UserID;
use base64::{engine::general_purpose::URL_SAFE_NO_PAD, Engine as _};
use error::Result;
use hmac::{Hmac, KeyInit, Mac};
use prost::Message;
use sha2::Sha256;

pub(crate) mod error;
pub mod stores;
pub mod traits;

include!(concat!(env!("OUT_DIR"), "/key_verification.rs"));

pub struct KeyVerificationConfig {
    /// The link prefix for the qr code which should be registered as a deeplink on Android and a universal link on iOS
    /// The link MUST start with a https:// and end with a #
    /// The link should contain the username of the user so the application can show the scanned user without internet
    /// Example: https://me.twonly.eu/tobi#
    deeplink_prefix: String,
    /// The user ID used to calculate the verification proof
    user_id: UserID,
    /// The public_key of the user to calculate the verification proof
    public_key: Vec<u8>,
}

pub struct ScannedUser {
    pub user_id: UserID,
    pub public_key: Vec<u8>,
    pub verification_proof: Vec<u8>,
}

pub struct KeyVerification<Store: KeyVerificationStore> {
    store: Store,
    config: KeyVerificationConfig,
}

impl<Store: KeyVerificationStore> KeyVerification<Store> {
    pub fn new(store: Store, config: KeyVerificationConfig) -> Result<KeyVerification<Store>> {
        if !config.deeplink_prefix.starts_with("https://") || !config.deeplink_prefix.ends_with("#")
        {
            return Err(KeyVerificationError::InvalidDeeplinkPrefix);
        }
        Ok(Self { store, config })
    }

    /// Generates the a string which should be displayed in the UI so others can scan it.
    pub fn generate_qr_text(&self) -> Result<String> {
        // 10 Bytes should be enough. Tokens are only valid for one day and then deleted.
        let secret_verification_token: Vec<u8> = rand::random_iter().take(16).collect();

        self.store
            .push_new_secret_verification_token(&secret_verification_token)?;

        let verification_data = VerificationData {
            user_id: self.config.user_id,
            public_key: self.config.public_key.clone(),
            secret_verification_token,
        };

        let verification_data_bytes = verification_data.encode_to_vec();
        let encoded = URL_SAFE_NO_PAD.encode(verification_data_bytes);

        Ok(format!("{}{}", self.config.deeplink_prefix, encoded))
    }

    /// Handles the scanned qr code text and creates a response message
    /// which can be send to the other person
    pub fn get_user_from_scanned_qr_text(&self, received_text: &str) -> Result<ScannedUser> {
        let splitted: Vec<_> = received_text.split('#').collect();
        if splitted.len() != 2 {
            tracing::info!("Scanned qr text does not contain a #");
            return Err(KeyVerificationError::InvalidQrText);
        }
        let verification_data_bytes = URL_SAFE_NO_PAD.decode(splitted[1])?;
        let verification_data = VerificationData::decode(verification_data_bytes.as_slice())?;

        let mut mac = Hmac::<Sha256>::new_from_slice(&verification_data.secret_verification_token)?;
        mac.update(&self.config.user_id.to_le_bytes());
        mac.update(&self.config.public_key);
        mac.update(&verification_data.user_id.to_le_bytes());
        mac.update(&verification_data.public_key);

        let verification_proof = mac.finalize().into_bytes().to_vec();

        Ok(ScannedUser {
            user_id: verification_data.user_id,
            public_key: verification_data.public_key,
            verification_proof,
        })
    }

    /// Checks whether the received verification proof is valid
    pub fn is_received_verification_proof_valid(
        &self,
        from_user_id: UserID,
        public_key: Vec<u8>,
        verification_proof: Vec<u8>,
    ) -> Result<bool> {
        let verification_tokens = self.store.get_all_valid_verification_tokens()?;

        for verification_token in &verification_tokens {
            let calculated_verification_proof = {
                let mut mac = Hmac::<Sha256>::new_from_slice(verification_token)?;
                mac.update(&from_user_id.to_le_bytes());
                mac.update(&public_key);
                mac.update(&self.config.user_id.to_le_bytes());
                mac.update(&self.config.public_key);
                mac.finalize().into_bytes().to_vec()
            };

            if calculated_verification_proof == verification_proof {
                return Ok(true);
            }
        }

        Ok(false)
    }
}

#[cfg(test)]
mod tests {
    use crate::key_verification::{stores::InMemoryStore, KeyVerification, KeyVerificationConfig};

    #[test]
    fn test_key_verification() {
        let _ = pretty_env_logger::try_init();

        const ALICE_ID: i64 = 10;
        const BOB_ID: i64 = 11;

        let alice_kv = KeyVerification::new(
            InMemoryStore::default(),
            KeyVerificationConfig {
                user_id: ALICE_ID,
                public_key: vec![ALICE_ID as u8; 32],
                deeplink_prefix: "https://me.twonly.eu/alice#".into(),
            },
        )
        .unwrap();

        let bob_kv = KeyVerification::new(
            InMemoryStore::default(),
            KeyVerificationConfig {
                user_id: BOB_ID,
                public_key: vec![BOB_ID as u8; 32],
                deeplink_prefix: "https://me.twonly.eu/bob#".into(),
            },
        )
        .unwrap();

        let qr_code_text = alice_kv.generate_qr_text().unwrap();
        assert_eq!(qr_code_text.len(), 99);

        tracing::debug!("Generated QR-Code-Link: {qr_code_text}");

        let scanned_user = bob_kv.get_user_from_scanned_qr_text(&qr_code_text).unwrap();

        // THIS must be done by the application
        assert_eq!(scanned_user.user_id, ALICE_ID);
        assert_eq!(scanned_user.public_key, vec![ALICE_ID as u8; 32]);

        // SEND scanned_user.verification_proof over the establish e2ee protected session if public_key verification was valid.

        let valid_verification_proof = alice_kv
            .is_received_verification_proof_valid(
                BOB_ID,
                vec![BOB_ID as u8; 32],
                scanned_user.verification_proof.clone(),
            )
            .unwrap();

        assert_eq!(valid_verification_proof, true);

        let valid_verification_proof = alice_kv
            .is_received_verification_proof_valid(
                BOB_ID,
                vec![(BOB_ID + 1) as u8; 32],
                scanned_user.verification_proof.clone(),
            )
            .unwrap();

        assert_eq!(valid_verification_proof, false);

        let mut modified_proof = scanned_user.verification_proof;
        modified_proof[0] = modified_proof[0] + 1;

        let valid_verification_proof = alice_kv
            .is_received_verification_proof_valid(BOB_ID, vec![BOB_ID as u8; 32], modified_proof)
            .unwrap();

        assert_eq!(valid_verification_proof, false);
    }
}
