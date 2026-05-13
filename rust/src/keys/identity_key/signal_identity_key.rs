use std::collections::HashMap;

use serde::{Deserialize, Serialize};
use zeroize::{Zeroize, ZeroizeOnDrop};

#[derive(Debug, PartialEq, Serialize, Deserialize)]
pub(crate) struct SignalIdentityKey {
    // https://github.com/MixinNetwork/libsignal_protocol_dart/blob/c95a1586057022acdbb9c76b1692d94cc549bcc7/protobuf/LocalStorageProtocol.proto#L85
    pub(crate) identity_key_pair_structure: Vec<u8>,
    pub(crate) registration_id: i64,
    pub(crate) pre_key_store: HashMap<i64, Vec<u8>>,
}

impl SignalIdentityKey {}

impl Zeroize for SignalIdentityKey {
    fn zeroize(&mut self) {
        self.identity_key_pair_structure.zeroize();
        self.registration_id.zeroize();
        for value in self.pre_key_store.values_mut() {
            value.zeroize();
        }
        self.pre_key_store.clear();
    }
}

impl Drop for SignalIdentityKey {
    fn drop(&mut self) {
        self.zeroize();
    }
}

impl ZeroizeOnDrop for SignalIdentityKey {}
