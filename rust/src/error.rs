/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use hex::FromHexError;
use scrypt::errors::{InvalidOutputLen, InvalidParams};
use std::string::FromUtf8Error;
use thiserror::Error;
use zip::result::ZipError;

pub type Result<T> = core::result::Result<T, TwonlyError>;

macro_rules! twonly_error {
    ($message:expr) => {
        $crate::error::TwonlyError::Located {
            message: ($message).into(),
            file: file!(),
            line: line!(),
        }
    };
}

pub(crate) use twonly_error;

#[derive(Error, Debug)]
pub enum TwonlyError {
    #[error("global twonly is not initialized")]
    Initialization,

    #[error("Tried to access the wrong context")]
    WrongContext,

    #[error("Tried to access signal identity while it does not exists")]
    SignalIdentityNotFound,

    #[error("init_flutter_callbacks was not called")]
    MissingCallbackInitialization,

    #[error("wrong input key size. expected: {0} but got {1}")]
    WronKeySize(usize, usize),

    #[error("Could not find the given database")]
    DatabaseNotFound,

    #[error("main_key could not be loaded from the key_chain")]
    MissingMainKey,

    #[error("User discovery store error: `{0}`")]
    UserDiscoveryStore(String),

    #[error("The encrypted announcement data contains malicious data: `{0}`")]
    MaliciousAnnouncementData(String),

    #[error("no user-discovery shares left")]
    NoSharesLeft,

    #[error("User discovery contains no configuration")]
    UserDiscoveryNotInitialized,

    #[error("error while calculating Shamir's secret shares: `{0}`")]
    ShamirsSecret(String),

    #[error("tried to push an invalid user-discovery version")]
    PushedInvalidVersion,

    #[error("Error in dart callback")]
    DartError,

    #[error(
        "Storage error: database exists but master key could not be loaded from secure storage"
    )]
    SecureStorageError,

    #[error("{0}")]
    SqliteError(#[from] sqlx::Error),

    #[error("{0}")]
    Generic(String),

    #[error("{message} at {file}:{line}")]
    Located {
        message: String,
        file: &'static str,
        line: u32,
    },

    #[error("API error code {0}")]
    Api(i32),

    #[error("API user response is missing required field: {0}")]
    ApiResponseMissingField(&'static str),

    #[error("{0}")]
    IoError(#[from] std::io::Error),

    #[error("{0}")]
    JsonError(#[from] serde_json::Error),

    #[error("{0}")]
    ZipError(#[from] ZipError),

    #[error("{0}")]
    Walkdir(#[from] walkdir::Error),

    #[error("{0}")]
    Postcard(#[from] postcard::Error),

    #[error("Protobuf decoding error: {0}")]
    ProtobufDecode(#[from] prost::DecodeError),

    #[error("Unknown protobuf enum value: {0}")]
    UnknownProtobufEnumValue(#[from] prost::UnknownEnumValue),

    #[error(transparent)]
    SealedSender(#[from] crate::sealed_sender::SealedSenderError),

    #[error("{0}")]
    HexError(#[from] FromHexError),

    #[error("invalid UTF-8 string: {0}")]
    Utf8(#[from] FromUtf8Error),

    #[error("{0}")]
    InvalidParams(#[from] InvalidParams),
    #[error("{0}")]
    InvalidOutputLen(#[from] InvalidOutputLen),
    #[error("{0}")]
    InvalidDigestLength(#[from] sha2::digest::InvalidLength),
    #[error("AES-GCM error")]
    AesGcm,

    #[error("Signal protocol error: {0}")]
    Signal(String),
}

impl From<String> for TwonlyError {
    fn from(error: String) -> Self {
        TwonlyError::Generic(error)
    }
}

impl From<aes_gcm::Error> for TwonlyError {
    fn from(_: aes_gcm::Error) -> Self {
        TwonlyError::AesGcm
    }
}

impl From<libsignal_protocol::SignalProtocolError> for TwonlyError {
    fn from(error: libsignal_protocol::SignalProtocolError) -> Self {
        TwonlyError::Signal(error.to_string())
    }
}
