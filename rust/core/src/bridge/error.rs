use thiserror::Error;

pub type Result<T> = core::result::Result<T, TwonlyError>;

#[derive(Error, Debug)]
pub enum TwonlyError {
    #[error("global twonly is not initialized")]
    Initialization,
    #[error("Could not find the given database")]
    DatabaseNotFound,
    #[error("sqlx error")]
    SqliteError(#[from] sqlx::Error),
}
