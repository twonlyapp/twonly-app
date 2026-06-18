include!(concat!(env!("OUT_DIR"), "/passwordless_recovery.rs"));

struct PasswordLessRecovery {}

impl PasswordLessRecovery {
    pub(crate) fn create_shared_secret_data(
        total_shares: i64,
        threshold: i64,
        pin_unlock_token: Option<Vec<u8>>,
    ) {
    }
}
