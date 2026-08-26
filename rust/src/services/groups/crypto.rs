/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::proto::client::EncryptedGroupStateEnvelop;
use crate::error::{Result, TwonlyError};
use chacha20poly1305::aead::{Aead, AeadCore, KeyInit, OsRng};
use chacha20poly1305::{ChaCha20Poly1305, Nonce};
use prost::Message;

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
    #[test]
    fn group_state_round_trip() {
        let key = [7_u8; 32];
        let encrypted = super::encrypt(&key, b"state").unwrap();
        assert_eq!(super::decrypt(&key, &encrypted).unwrap(), b"state");
    }
}
