use prost::DecodeError;
use thiserror::Error;

pub type Result<T> = core::result::Result<T, KeyVerificationError>;

#[derive(Error, Debug)]
pub enum KeyVerificationError {
    #[error("The prefix deeplink url must start with https:// and end with a #")]
    InvalidDeeplinkPrefix,

    #[error("Invalid qr text")]
    InvalidQrText,

    #[error(
        "Contact user_id is known and the stored public_key does not match the received user id"
    )]
    InvalidPublicKeyAndUserIdCombination,

    #[error("Store error: `{0}`")]
    Store(String),

    #[error("`{0}`")]
    Base64(#[from] base64::DecodeError),

    #[error("`{0}`")]
    Prost(#[from] DecodeError),

    #[error("`{0}`")]
    Hmac(#[from] hmac::digest::InvalidLength),
}
