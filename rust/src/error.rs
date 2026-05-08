use protocols::user_discovery::error::UserDiscoveryError;
use thiserror::Error;
use zip::result::ZipError;

pub type Result<T> = core::result::Result<T, TwonlyError>;

#[derive(Error, Debug)]
pub enum TwonlyError {
    #[error("global twonly is not initialized")]
    Initialization,
    #[error("Tried to access the wrong context")]
    WrongContext,
    #[error("init_flutter_callbacks was not called")]
    MissingCallbackInitialization,
    #[error("Could not find the given database")]
    DatabaseNotFound,
    #[error("{0}")]
    UserDiscoveryError(#[from] UserDiscoveryError),
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
    #[error("{0}")]
    IoError(#[from] std::io::Error),

    #[error("{0}")]
    ZipError(#[from] ZipError),

    #[error("{0}")]
    Walkdir(#[from] walkdir::Error),
}

impl From<String> for TwonlyError {
    fn from(error: String) -> Self {
        TwonlyError::Generic(error)
    }
}

impl From<TwonlyError> for UserDiscoveryError {
    fn from(error: TwonlyError) -> Self {
        UserDiscoveryError::Store(error.to_string())
    }
}
