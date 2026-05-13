#![allow(dead_code)]
use serde::{Deserialize, Serialize};

/// Send from the person who tries to recover their account.
/// This can be done via a link, which will then be opened in the app of the contact.
/// The contact then has to manually select from which user he got the request.
#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct RecoveryRequest {
    pub temp_id: i64,
    pub public_key: Vec<u8>,
}

/// Used as envelope for TrustedFriendShare and RecoveryData
#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct EncryptedEnvelope {
    pub encrypted_data: Vec<u8>,
    pub iv: Vec<u8>,
    pub mac: Vec<u8>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct User {
    pub user_id: i64,
    pub display_name: String,
    pub avatar: Vec<u8>,
}

/// Send from the trusted friend.
/// This is encrypted with the received public key.
#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct TrustedFriendShare {
    /// This allows to display the user which user has send him his recovery data.
    pub trusted_friend: User,
    /// This allows to display the userdata, showing that he is recovering the correct person.
    pub share_user: User,
    /// The minimum threshold required to decrypt the shares.
    pub threshold: i32,
    /// The actual share which will become: SecretSharedData
    pub share: Vec<u8>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct SecondFactorPin {
    /// Required to try the PIN to get the share from the server.
    /// This prevents that someone else can lock the pin, as the server only
    /// allows 3 tries then after 1 day again 3 tries until the key is deleted.
    pub unlock_token: Vec<u8>,
    /// This never is send to the server but used to hash the pin before sending it to the server.
    /// This prevents that the server every knows the short 4-digit PIN.
    pub pin_seed: Vec<u8>,
    /// The recovery data in case a second factor was used
    /// The decryption key is loaded from the server either using the PIN or the MAIL
    pub recovery_data_encrypted: Vec<u8>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct SecondFactorMail {
    /// The users selected mail which will be send to the server
    /// To this mail the encryption key for the recovery_data is send
    pub mail: String,
    /// Required to try the PIN to get the share from the server.
    /// This prevents that someone else can lock the pin, as the server only
    /// allows 3 tries then after 1 day again 3 tries until the key is deleted.
    pub unlock_token: Vec<u8>,
    /// The recovery data in case a second factor was used
    /// The decryption key is loaded from the server either using the PIN or the MAIL
    pub recovery_data_encrypted: Vec<u8>,
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub enum SecretSharedData {
    None(RecoveryData),
    Mail(SecondFactorMail),
    Pin(SecondFactorPin),
}

/// The data which is recovered at the end.
/// The backup_master_key allows to recover the actual backup uploaded in the background to the server.
/// In case the backup is not available any more the user can use its user_id and his private_key to register as a new user.
#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct RecoveryData {
    pub user_id: i64,
    pub master_key: Vec<u8>,
}
