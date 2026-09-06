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

    #[error("encrypted media is {bytes} bytes but the plan allows {limit}")]
    MediaTooLarge { bytes: i64, limit: i64 },

    /// The group server refused a state update because it was written against
    /// a version it no longer holds. Somebody else changed the group first, so
    /// the update has to be applied again to the version that won.
    #[error("group state was updated by somebody else first")]
    GroupStateConflict,

    /// Content that will never be processable: it is malformed, or it uses a
    /// feature this client does not implement. Callers must not retry it —
    /// a reliable-mailbox row carrying such a message is acknowledged so the
    /// server stops redelivering it forever.
    #[error("unprocessable content: {0}")]
    UnprocessableContent(String),

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

    /// The server answered with the account but holds no PQC prekey bundle for
    /// it, so no new Signal session can be opened with that peer. Distinct from
    /// `ApiResponseMissingField` because callers defer work instead of failing:
    /// the peer publishes a bundle only when their client next registers or
    /// republishes, and an inbound message from them still opens a session.
    #[error("peer {0} has published no prekey bundle")]
    PeerHasNoPrekeyBundle(i64),

    /// The server does not know this account. Distinct from every other reason
    /// a lookup can fail, because it is the only one that justifies dropping a
    /// message instead of retrying it: a network error must never be mistaken
    /// for a peer who no longer exists.
    #[error("the server does not know peer {0}")]
    PeerAccountDeleted(i64),

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

    /// The Signal session for a peer can no longer decrypt what they send:
    /// the ratchet states have diverged past repair, the session record is
    /// structurally invalid, or it is gone entirely. Retrying the same
    /// ciphertext against it never succeeds, so callers reset the session and
    /// ask the peer to open a fresh one. See `signal::reset`.
    #[error("Signal session is unusable: {0}")]
    SignalSessionUnusable(String),

    /// The peer sent a message this session already ratcheted past. The
    /// session is healthy; the message is simply a duplicate and must not
    /// trigger a reset.
    #[error("duplicated Signal message: {0}")]
    SignalDuplicateMessage(String),
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
        use libsignal_protocol::SignalProtocolError as Error;

        let message = error.to_string();
        match error {
            // libsignal collapses every failed candidate session into a single
            // `InvalidMessage`; the per-session causes ("post-quantum ratchet
            // error: epoch not in valid range", "message keys not found", ...)
            // only reach its log. Whatever the cause, no session in the record
            // could open the message, which is exactly the reset condition.
            Error::InvalidMessage(..)
            | Error::SessionNotFound(..)
            | Error::InvalidSessionStructure(..)
            | Error::InvalidRegistrationId(..)
            // A restored backup can lack the private prekey for a bundle the
            // server still hands out, so inbound sessions built from it can
            // never be opened either.
            | Error::InvalidPreKeyId
            | Error::InvalidSignedPreKeyId
            | Error::InvalidKyberPreKeyId => TwonlyError::SignalSessionUnusable(message),

            Error::DuplicatedMessage(..) => TwonlyError::SignalDuplicateMessage(message),

            // An identity change is not a broken session: resetting would
            // silently trust a new key. It stays a plain Signal error so the
            // key-verification flow keeps owning it.
            _ => TwonlyError::Signal(message),
        }
    }
}
