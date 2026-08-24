use chacha20poly1305::{
    aead::{Aead, Payload},
    KeyInit, XChaCha20Poly1305, XNonce,
};
use hkdf::Hkdf;
use libsignal_protocol::{IdentityKeyPair, KeyPair, PublicKey};
use prost::Message as ProstMessage;
use rand::{CryptoRng, Rng};
use sha2::Sha256;
use std::time::{SystemTime, UNIX_EPOCH};
use thiserror::Error;

use crate::context::Context;

pub mod proto {
    include!(concat!(env!("OUT_DIR"), "/client_messages.rs"));
}

const PAYLOAD_MAGIC: &str = "twonly-message-envelope-v1";
const ENCRYPTION_CONTEXT: &[u8] = b"twonly-message-envelope-encryption-v1";
const X25519_PUBLIC_KEY_SIZE: usize = 32;
const XCHACHA20_NONCE_SIZE: usize = 24;
const POLY1305_TAG_SIZE: usize = 16;
const ENVELOPE_VALIDITY_SECONDS: i64 = 45 * 24 * 60 * 60;
const MAX_FUTURE_CLOCK_SKEW_SECONDS: i64 = 5 * 60;

pub type Result<T> = std::result::Result<T, SealedSenderError>;

#[derive(Debug, Error)]
pub enum SealedSenderError {
    #[error("invalid protobuf: {0}")]
    InvalidProtobuf(#[from] prost::DecodeError),
    #[error("invalid ephemeral public key")]
    InvalidEphemeralPublicKey,
    #[error("invalid XChaCha20-Poly1305 nonce")]
    InvalidNonce,
    #[error("invalid XChaCha20-Poly1305 ciphertext")]
    InvalidCiphertext,
    #[error("X25519 key agreement failed")]
    KeyAgreement,
    #[error("sender signature generation failed")]
    SignatureGeneration,
    #[error("HKDF key derivation failed")]
    KeyDerivation,
    #[error("XChaCha20-Poly1305 encryption failed")]
    EncryptionFailed,
    #[error("XChaCha20-Poly1305 authentication failed")]
    AuthenticationFailed,
    #[error("invalid sealed-sender payload magic")]
    InvalidMagic,
    #[error("message was addressed to user {actual}, not user {expected}")]
    WrongRecipient { expected: i64, actual: i64 },
    #[error("sealed-sender payload does not contain a message")]
    MissingMessage,
    #[error("sealed-sender message has an empty receipt ID")]
    MissingReceiptId,
    #[error("no identity key is available for sender {0}")]
    UnknownSender(i64),
    #[error("invalid sender signature")]
    InvalidSignature,
    #[error("sealed-sender context error: {0}")]
    Context(String),
    #[error("the local user ID is unavailable")]
    MissingLocalUserId,
    #[error("the local Signal identity is unavailable")]
    MissingLocalIdentity,
    #[error("invalid local Signal identity")]
    InvalidLocalIdentity,
    #[error("system clock is before the Unix epoch")]
    InvalidSystemTime,
    #[error("sealed-sender envelope has expired")]
    ExpiredEnvelope,
    #[error("sealed-sender envelope timestamp is too far in the future")]
    FutureEnvelope,
}

/// Encrypts and decrypts twonly sealed-sender envelopes.
///
/// The outer encryption authenticates the ciphertext but intentionally does not
/// authenticate the sender. Sender authentication is provided by the XEdDSA
/// identity-key signature inside the encrypted envelope.
pub(crate) struct SealedSender;

impl SealedSender {
    pub(crate) fn encrypt<R>(
        from_user_id: i64,
        recipient_user_id: i64,
        message: proto::Message,
        sender_identity: &IdentityKeyPair,
        recipient_identity_key: &PublicKey,
        rng: &mut R,
    ) -> Result<Vec<u8>>
    where
        R: Rng + CryptoRng + ?Sized,
    {
        Self::encrypt_at(
            from_user_id,
            recipient_user_id,
            message,
            unix_time_seconds()?,
            sender_identity,
            recipient_identity_key,
            rng,
        )
    }

    fn encrypt_at<R>(
        from_user_id: i64,
        recipient_user_id: i64,
        message: proto::Message,
        created_at_unix_seconds: i64,
        sender_identity: &IdentityKeyPair,
        recipient_identity_key: &PublicKey,
        rng: &mut R,
    ) -> Result<Vec<u8>>
    where
        R: Rng + CryptoRng + ?Sized,
    {
        if message.receipt_id.is_empty() {
            return Err(SealedSenderError::MissingReceiptId);
        }
        let payload = proto::MessageEnvelopePayload {
            magic: PAYLOAD_MAGIC.to_owned(),
            from_user_id,
            recipient_user_id,
            message: Some(message),
            created_at_unix_seconds,
        };
        let signed_payload = payload.encode_to_vec();
        let signature = sender_identity
            .private_key()
            .calculate_signature(&signed_payload, rng)
            .map_err(|_| SealedSenderError::SignatureGeneration)?;
        let envelope = proto::MessageEnvelope {
            signed_payload,
            signature: signature.into_vec(),
        }
        .encode_to_vec();

        let ephemeral_key_pair = KeyPair::generate(rng);
        let ephemeral_public_key = ephemeral_key_pair.public_key.public_key_bytes().to_vec();
        let shared_secret = ephemeral_key_pair
            .private_key
            .calculate_agreement(recipient_identity_key)
            .map_err(|_| SealedSenderError::KeyAgreement)?;
        let key = derive_encryption_key(
            &shared_secret,
            &ephemeral_public_key,
            recipient_identity_key,
        )?;

        let mut nonce = [0_u8; XCHACHA20_NONCE_SIZE];
        rng.fill_bytes(&mut nonce);
        let ciphertext = XChaCha20Poly1305::new((&key).into())
            .encrypt(
                XNonce::from_slice(&nonce),
                Payload {
                    msg: &envelope,
                    aad: ENCRYPTION_CONTEXT,
                },
            )
            .map_err(|_| SealedSenderError::EncryptionFailed)?;

        Ok(proto::EncryptedMessageEnvelope {
            ephemeral_public_key,
            nonce: nonce.to_vec(),
            ciphertext,
        }
        .encode_to_vec())
    }

    /// Decrypts an envelope with the local identity from `context` and verifies
    /// the signature using the sender identity stored by Signal.
    pub(crate) async fn decrypt(
        encrypted_envelope: &[u8],
        context: &Context,
    ) -> Result<proto::MessageEnvelopePayload> {
        let (recipient_user_id, recipient_identity) = {
            let key_manager = context.get_key_manager().await.map_err(context_error)?;
            let recipient_user_id = key_manager
                .user_id
                .ok_or(SealedSenderError::MissingLocalUserId)?;
            let serialized_identity = &key_manager
                .signal_identity
                .as_ref()
                .ok_or(SealedSenderError::MissingLocalIdentity)?
                .identity_key_pair_structure;
            let recipient_identity = IdentityKeyPair::try_from(serialized_identity.as_slice())
                .map_err(|_| SealedSenderError::InvalidLocalIdentity)?;
            (recipient_user_id, recipient_identity)
        };

        let (envelope, payload) =
            Self::decrypt_envelope(encrypted_envelope, recipient_user_id, &recipient_identity)?;
        let sender_identity = context
            .get_identity(payload.from_user_id)
            .await
            .map_err(context_error)?
            .ok_or(SealedSenderError::UnknownSender(payload.from_user_id))?;
        verify_sender_and_message(&envelope, &payload, sender_identity.public_key())?;
        Ok(payload)
    }

    fn decrypt_envelope(
        encrypted_envelope: &[u8],
        recipient_user_id: i64,
        recipient_identity: &IdentityKeyPair,
    ) -> Result<(proto::MessageEnvelope, proto::MessageEnvelopePayload)> {
        let encrypted = proto::EncryptedMessageEnvelope::decode(encrypted_envelope)?;
        if encrypted.ephemeral_public_key.len() != X25519_PUBLIC_KEY_SIZE {
            return Err(SealedSenderError::InvalidEphemeralPublicKey);
        }
        if encrypted.nonce.len() != XCHACHA20_NONCE_SIZE {
            return Err(SealedSenderError::InvalidNonce);
        }
        if encrypted.ciphertext.len() < POLY1305_TAG_SIZE {
            return Err(SealedSenderError::InvalidCiphertext);
        }

        let ephemeral_public_key =
            PublicKey::from_djb_public_key_bytes(&encrypted.ephemeral_public_key)
                .map_err(|_| SealedSenderError::InvalidEphemeralPublicKey)?;
        let shared_secret = recipient_identity
            .private_key()
            .calculate_agreement(&ephemeral_public_key)
            .map_err(|_| SealedSenderError::KeyAgreement)?;
        let key = derive_encryption_key(
            &shared_secret,
            &encrypted.ephemeral_public_key,
            recipient_identity.identity_key().public_key(),
        )?;
        let plaintext = XChaCha20Poly1305::new((&key).into())
            .decrypt(
                XNonce::from_slice(&encrypted.nonce),
                Payload {
                    msg: &encrypted.ciphertext,
                    aad: ENCRYPTION_CONTEXT,
                },
            )
            .map_err(|_| SealedSenderError::AuthenticationFailed)?;

        let envelope = proto::MessageEnvelope::decode(plaintext.as_slice())?;
        let payload = proto::MessageEnvelopePayload::decode(envelope.signed_payload.as_slice())?;
        if payload.magic != PAYLOAD_MAGIC {
            return Err(SealedSenderError::InvalidMagic);
        }
        if payload.recipient_user_id != recipient_user_id {
            return Err(SealedSenderError::WrongRecipient {
                expected: recipient_user_id,
                actual: payload.recipient_user_id,
            });
        }
        Ok((envelope, payload))
    }
}

fn verify_sender_and_message(
    envelope: &proto::MessageEnvelope,
    payload: &proto::MessageEnvelopePayload,
    sender_key: &PublicKey,
) -> Result<()> {
    if !sender_key.verify_signature(&envelope.signed_payload, &envelope.signature) {
        return Err(SealedSenderError::InvalidSignature);
    }
    let message = payload
        .message
        .as_ref()
        .ok_or(SealedSenderError::MissingMessage)?;
    if message.receipt_id.is_empty() {
        return Err(SealedSenderError::MissingReceiptId);
    }
    let now = unix_time_seconds()?;
    if payload.created_at_unix_seconds < now.saturating_sub(ENVELOPE_VALIDITY_SECONDS) {
        return Err(SealedSenderError::ExpiredEnvelope);
    }
    if payload.created_at_unix_seconds > now.saturating_add(MAX_FUTURE_CLOCK_SKEW_SECONDS) {
        return Err(SealedSenderError::FutureEnvelope);
    }
    Ok(())
}

fn context_error(error: impl std::fmt::Display) -> SealedSenderError {
    SealedSenderError::Context(error.to_string())
}

fn unix_time_seconds() -> Result<i64> {
    let seconds = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map_err(|_| SealedSenderError::InvalidSystemTime)?
        .as_secs();
    i64::try_from(seconds).map_err(|_| SealedSenderError::InvalidSystemTime)
}

fn derive_encryption_key(
    shared_secret: &[u8],
    ephemeral_public_key: &[u8],
    recipient_identity_key: &PublicKey,
) -> Result<[u8; 32]> {
    let mut info = Vec::with_capacity(
        ENCRYPTION_CONTEXT.len()
            + ephemeral_public_key.len()
            + recipient_identity_key.serialize().len(),
    );
    info.extend_from_slice(ENCRYPTION_CONTEXT);
    info.extend_from_slice(ephemeral_public_key);
    info.extend_from_slice(&recipient_identity_key.serialize());

    let mut key = [0_u8; 32];
    Hkdf::<Sha256>::new(None, shared_secret)
        .expand(&info, &mut key)
        .map_err(|_| SealedSenderError::KeyDerivation)?;
    Ok(key)
}

#[cfg(test)]
mod tests {
    use super::*;
    use rand::{rngs::StdRng, SeedableRng};

    fn test_message() -> proto::Message {
        proto::Message {
            r#type: proto::message::Type::PlaintextContent as i32,
            receipt_id: "1f58417a-5cd4-4bb6-9f38-2f499d9cfa8e".to_owned(),
            ..Default::default()
        }
    }

    fn decrypt_with_identity(
        encrypted: &[u8],
        recipient_user_id: i64,
        recipient: &IdentityKeyPair,
        sender_key: &PublicKey,
    ) -> Result<proto::MessageEnvelopePayload> {
        let (envelope, payload) =
            SealedSender::decrypt_envelope(encrypted, recipient_user_id, recipient)?;
        verify_sender_and_message(&envelope, &payload, sender_key)?;
        Ok(payload)
    }

    #[tokio::test]
    async fn encrypts_decrypts_and_authenticates_a_sealed_sender_message() {
        let mut rng = StdRng::seed_from_u64(7);
        let sender = IdentityKeyPair::generate(&mut rng);
        let recipient = IdentityKeyPair::generate(&mut rng);
        let message = test_message();
        let temporary_directory = tempfile::tempdir().unwrap();
        let context = Context::init_for_testing(
            temporary_directory.path().join("database"),
            temporary_directory.path().join("data"),
        )
        .await
        .unwrap();
        {
            let mut key_manager = context.get_key_manager().await.unwrap();
            key_manager.user_id = Some(42);
            key_manager.signal_identity = Some(crate::keys::SignalIdentityKey {
                identity_key_pair_structure: recipient.serialize().to_vec(),
                registration_id: 1,
                pre_key_store: Default::default(),
            });
        }
        let database = context.get_rust_database().await;
        sqlx::query(
            "INSERT INTO signal_identities (name, identity_key, timestamp) VALUES (?, ?, 0)",
        )
        .bind("41")
        .bind(sender.identity_key().serialize().as_ref())
        .execute(&database.pool)
        .await
        .unwrap();

        let encrypted = SealedSender::encrypt(
            41,
            42,
            message.clone(),
            &sender,
            recipient.identity_key().public_key(),
            &mut rng,
        )
        .unwrap();
        let decrypted = SealedSender::decrypt(&encrypted, &context).await.unwrap();

        assert_eq!(decrypted.magic, PAYLOAD_MAGIC);
        assert_eq!(decrypted.from_user_id, 41);
        assert_eq!(decrypted.recipient_user_id, 42);
        assert_eq!(decrypted.message, Some(message));
        assert!(decrypted.created_at_unix_seconds > 0);
    }

    #[test]
    fn rejects_tampered_ciphertext() {
        let mut rng = StdRng::seed_from_u64(8);
        let sender = IdentityKeyPair::generate(&mut rng);
        let recipient = IdentityKeyPair::generate(&mut rng);
        let encrypted = SealedSender::encrypt(
            41,
            42,
            test_message(),
            &sender,
            recipient.identity_key().public_key(),
            &mut rng,
        )
        .unwrap();
        let mut wrapper = proto::EncryptedMessageEnvelope::decode(encrypted.as_slice()).unwrap();
        wrapper.ciphertext[0] ^= 1;

        let error = decrypt_with_identity(
            &wrapper.encode_to_vec(),
            42,
            &recipient,
            sender.identity_key().public_key(),
        )
        .unwrap_err();

        assert!(matches!(error, SealedSenderError::AuthenticationFailed));
    }

    #[test]
    fn rejects_a_signature_from_another_identity() {
        let mut rng = StdRng::seed_from_u64(9);
        let sender = IdentityKeyPair::generate(&mut rng);
        let impostor = IdentityKeyPair::generate(&mut rng);
        let recipient = IdentityKeyPair::generate(&mut rng);
        let encrypted = SealedSender::encrypt(
            41,
            42,
            test_message(),
            &sender,
            recipient.identity_key().public_key(),
            &mut rng,
        )
        .unwrap();

        let error = decrypt_with_identity(
            &encrypted,
            42,
            &recipient,
            impostor.identity_key().public_key(),
        )
        .unwrap_err();

        assert!(matches!(error, SealedSenderError::InvalidSignature));
    }

    #[test]
    fn rejects_an_envelope_for_another_recipient_before_resolving_sender() {
        let mut rng = StdRng::seed_from_u64(10);
        let sender = IdentityKeyPair::generate(&mut rng);
        let recipient = IdentityKeyPair::generate(&mut rng);
        let encrypted = SealedSender::encrypt(
            41,
            42,
            test_message(),
            &sender,
            recipient.identity_key().public_key(),
            &mut rng,
        )
        .unwrap();

        let error = SealedSender::decrypt_envelope(&encrypted, 43, &recipient).unwrap_err();

        assert!(matches!(
            error,
            SealedSenderError::WrongRecipient {
                expected: 43,
                actual: 42
            }
        ));
    }

    #[test]
    fn rejects_an_expired_envelope() {
        let mut rng = StdRng::seed_from_u64(11);
        let sender = IdentityKeyPair::generate(&mut rng);
        let recipient = IdentityKeyPair::generate(&mut rng);
        let expired_at = unix_time_seconds().unwrap() - ENVELOPE_VALIDITY_SECONDS - 1;
        let encrypted = SealedSender::encrypt_at(
            41,
            42,
            test_message(),
            expired_at,
            &sender,
            recipient.identity_key().public_key(),
            &mut rng,
        )
        .unwrap();

        let error = decrypt_with_identity(
            &encrypted,
            42,
            &recipient,
            sender.identity_key().public_key(),
        )
        .unwrap_err();

        assert!(matches!(error, SealedSenderError::ExpiredEnvelope));
    }

    #[test]
    fn rejects_an_envelope_too_far_in_the_future() {
        let mut rng = StdRng::seed_from_u64(12);
        let sender = IdentityKeyPair::generate(&mut rng);
        let recipient = IdentityKeyPair::generate(&mut rng);
        let future_at = unix_time_seconds().unwrap() + MAX_FUTURE_CLOCK_SKEW_SECONDS + 1;
        let encrypted = SealedSender::encrypt_at(
            41,
            42,
            test_message(),
            future_at,
            &sender,
            recipient.identity_key().public_key(),
            &mut rng,
        )
        .unwrap();

        let error = decrypt_with_identity(
            &encrypted,
            42,
            &recipient,
            sender.identity_key().public_key(),
        )
        .unwrap_err();

        assert!(matches!(error, SealedSenderError::FutureEnvelope));
    }
}
