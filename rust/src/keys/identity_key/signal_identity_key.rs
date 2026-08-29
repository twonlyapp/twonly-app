/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::error::Result;
use libsignal_protocol::IdentityKeyPair;
use rand::SeedableRng;
use serde::{Deserialize, Serialize};
use zeroize::{Zeroize, ZeroizeOnDrop};

#[derive(Debug, PartialEq, Serialize, Deserialize)]
pub(crate) struct SignalIdentityKey {
    pub(crate) identity_key_pair_structure: Vec<u8>,
    pub(crate) registration_id: i64,
}

impl SignalIdentityKey {
    pub(crate) fn generate() -> Result<Self> {
        let mut csprng = rand::rngs::StdRng::from_os_rng();
        let identity_key_pair = IdentityKeyPair::generate(&mut csprng);
        let registration_id = rand::Rng::random::<u32>(&mut csprng) & 0x7fff_ffff;
        Ok(Self {
            identity_key_pair_structure: identity_key_pair.serialize().to_vec(),
            registration_id: i64::from(registration_id),
        })
    }
}

impl Zeroize for SignalIdentityKey {
    fn zeroize(&mut self) {
        self.identity_key_pair_structure.zeroize();
        self.registration_id.zeroize();
    }
}

impl Drop for SignalIdentityKey {
    fn drop(&mut self) {
        self.zeroize();
    }
}

impl ZeroizeOnDrop for SignalIdentityKey {}
