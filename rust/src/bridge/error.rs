use protocols::user_discovery::error::UserDiscoveryError;
use thiserror::Error;

pub type Result<T> = core::result::Result<T, TwonlyError>;

#[derive(Error, Debug)]
pub enum TwonlyError {
    #[error("global twonly is not initialized")]
    Initialization,
    #[error("init_flutter_callbacks was not called")]
    MissingCallbackInitialization,
    #[error("Could not find the given database")]
    DatabaseNotFound,
    #[error("{0}")]
    UserDiscoveryError(#[from] UserDiscoveryError),
    #[error("Error in dart callback")]
    DartError,
    #[error("{0}")]
    SqliteError(#[from] sqlx::Error),
}

impl From<TwonlyError> for UserDiscoveryError {
    fn from(error: TwonlyError) -> Self {
        UserDiscoveryError::Store(error.to_string())
    }
}
