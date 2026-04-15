use super::error::Result;
pub trait KeyVerificationStore {
    fn push_new_secret_verification_token(&self, token: &[u8]) -> Result<()>;
    /// This function should return all tokens from the last 24h
    /// All other tokens can be removed from the database
    fn get_all_valid_verification_tokens(&self) -> Result<Vec<Vec<u8>>>;
}
