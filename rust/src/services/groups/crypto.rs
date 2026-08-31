/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::proto::client::EncryptedGroupStateEnvelop;
use crate::error::{Result, TwonlyError};
use chacha20poly1305::aead::{Aead, AeadCore, KeyInit, OsRng};
use chacha20poly1305::{ChaCha20Poly1305, Nonce};
use prost::Message;

const NONCE_SIZE: usize = 12;
const TAG_SIZE: usize = 16;

pub(crate) fn encrypt(key: &[u8], plaintext: &[u8]) -> Result<Vec<u8>> {
    let cipher = ChaCha20Poly1305::new_from_slice(key)
        .map_err(|_| TwonlyError::Generic("invalid group state key".into()))?;
    let nonce = ChaCha20Poly1305::generate_nonce(&mut OsRng);
    let mut sealed = cipher
        .encrypt(&nonce, plaintext)
        .map_err(|_| TwonlyError::Generic("group state encryption failed".into()))?;
    let mac = sealed.split_off(sealed.len().saturating_sub(16));
    Ok(EncryptedGroupStateEnvelop {
        nonce: nonce.to_vec(),
        encrypted_group_state: sealed,
        mac,
    }
    .encode_to_vec())
}

pub(crate) fn decrypt(key: &[u8], envelope: &[u8]) -> Result<Vec<u8>> {
    let envelope = EncryptedGroupStateEnvelop::decode(envelope)
        .map_err(|error| TwonlyError::Generic(error.to_string()))?;
    // The envelope arrives from the group server, which accepts appends without
    // checking membership, so its lengths are attacker-chosen. `Nonce::from_slice`
    // asserts on a length mismatch, so both are checked before the conversion.
    if envelope.nonce.len() != NONCE_SIZE {
        return Err(TwonlyError::Generic("invalid group state nonce".into()));
    }
    if envelope.mac.len() != TAG_SIZE {
        return Err(TwonlyError::Generic("invalid group state MAC".into()));
    }
    let cipher = ChaCha20Poly1305::new_from_slice(key)
        .map_err(|_| TwonlyError::Generic("invalid group state key".into()))?;
    let nonce = Nonce::from_slice(&envelope.nonce);
    let mut sealed = envelope.encrypted_group_state;
    sealed.extend(envelope.mac);
    cipher
        .decrypt(nonce, sealed.as_ref())
        .map_err(|_| TwonlyError::Generic("group state authentication failed".into()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn group_state_round_trip() {
        let key = [7_u8; 32];
        let encrypted = super::encrypt(&key, b"state").unwrap();
        assert_eq!(super::decrypt(&key, &encrypted).unwrap(), b"state");
    }

    /// A nonce of the wrong length used to reach `Nonce::from_slice`, which
    /// asserts on the length and panics. The group server takes appends from
    /// anyone who knows the group ID, so this envelope is attacker-shaped.
    #[test]
    fn a_nonce_of_the_wrong_length_is_rejected_instead_of_panicking() {
        let key = [7_u8; 32];
        let encrypted = super::encrypt(&key, b"state").unwrap();
        let mut envelope = EncryptedGroupStateEnvelop::decode(encrypted.as_slice()).unwrap();

        for nonce in [vec![], vec![0_u8; 11], vec![0_u8; 13], vec![0_u8; 64]] {
            let mut tampered = envelope.clone();
            tampered.nonce = nonce;
            let error = super::decrypt(&key, &tampered.encode_to_vec()).unwrap_err();
            assert!(error.to_string().contains("invalid group state nonce"));
        }

        envelope.nonce = vec![0_u8; NONCE_SIZE];
        assert!(super::decrypt(&key, &envelope.encode_to_vec()).is_err());
    }

    #[test]
    fn a_mac_of_the_wrong_length_is_rejected() {
        let key = [7_u8; 32];
        let encrypted = super::encrypt(&key, b"state").unwrap();
        let mut envelope = EncryptedGroupStateEnvelop::decode(encrypted.as_slice()).unwrap();
        envelope.mac = vec![0_u8; 15];

        let error = super::decrypt(&key, &envelope.encode_to_vec()).unwrap_err();
        assert!(error.to_string().contains("invalid group state MAC"));
    }

    #[test]
    fn a_truncated_envelope_is_rejected() {
        let key = [7_u8; 32];
        let error = super::decrypt(&key, &[]).unwrap_err();
        assert!(error.to_string().contains("invalid group state nonce"));
    }
}
