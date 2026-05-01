use prost::DecodeError;
use thiserror::Error;

pub type Result<T> = core::result::Result<T, UserDiscoveryError>;

#[derive(Error, Debug)]
pub enum UserDiscoveryError {
    #[error("Store error: `{0}`")]
    Store(String),

    #[error("The encrypted announcement data contains malicious data: `{0}`")]
    MaliciousAnnouncementData(String),

    #[error("no shares left.")]
    NoSharesLeft,

    #[error("User discovery contains no configuration.")]
    NotInitialized,

    #[error("`{0}`")]
    JsonError(#[from] serde_json::Error),

    #[error("`{0}`")]
    IoError(#[from] std::io::Error),

    #[error("error while calculating shamirs secret shares: `{0}`")]
    ShamirsSecret(String),

    #[error("tried to push a invalid version")]
    PushedInvalidVersion,

    #[error("`{0}`")]
    Prost(#[from] DecodeError),
}
