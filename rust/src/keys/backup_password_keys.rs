use crate::error::Result;
use scrypt::{scrypt, Params};
use serde::{Deserialize, Serialize};
use zeroize::{Zeroize, ZeroizeOnDrop};

#[derive(Debug, Clone, PartialEq, Zeroize, ZeroizeOnDrop, Serialize, Deserialize)]
pub struct BackupPasswordKeys {
    pub backup_id: [u8; 32],
    pub encryption_key: [u8; 32],
}

impl BackupPasswordKeys {
    pub(crate) fn new(backup_id: [u8; 32], encryption_key: [u8; 32]) -> Self {
        Self {
            backup_id,
            encryption_key,
        }
    }

    pub(crate) fn from_password(password: &str, user_id: i64) -> Result<Self> {
        let params = Params::new(16, 8, 1)?;
        let mut output = [0u8; 64];

        scrypt(
            password.as_bytes(),
            &user_id.to_be_bytes(),
            &params,
            &mut output,
        )?;

        let mut backup_id = [0u8; 32];
        let mut encryption_key = [0u8; 32];
        backup_id.copy_from_slice(&output[0..32]);
        encryption_key.copy_from_slice(&output[32..64]);

        Ok(Self::new(backup_id, encryption_key))
    }
}
