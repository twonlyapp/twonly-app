use std::sync::{Arc, Mutex};

use crate::key_verification::{error::Result, traits::KeyVerificationStore};

#[derive(Default)]
pub struct InMemoryStore {
    verification_tokens: Arc<Mutex<Vec<Vec<u8>>>>,
}

impl KeyVerificationStore for InMemoryStore {
    fn push_new_secret_verification_token(&self, token: &[u8]) -> Result<()> {
        self.verification_tokens
            .lock()
            .unwrap()
            .push(token.to_vec());
        Ok(())
    }

    fn get_all_valid_verification_tokens(&self) -> Result<Vec<Vec<u8>>> {
        Ok(self.verification_tokens.lock().unwrap().clone())
    }
}
