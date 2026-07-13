pub mod backup;
pub mod key_manager;
pub mod user_discovery;

use crate::error::Result;
use blahaj::{Share, Sharks};

pub struct RustUtils {}

impl RustUtils {
    pub fn generate_shares(secret: Vec<u8>, total: u8, threshold: u8) -> Result<Vec<Vec<u8>>> {
        let sharks = Sharks(threshold);
        let dealer = sharks.dealer(&secret);
        let shares = dealer.take(total as usize).map(|x| Vec::from(&x)).collect();
        Ok(shares)
    }

    pub fn recover_secret(shares: Vec<Vec<u8>>, threshold: u8) -> Result<Vec<u8>> {
        let sharks = Sharks(threshold);
        let shares: Vec<Share> = shares
            .iter()
            .filter_map(|x| Share::try_from(x.as_slice()).ok())
            .collect();
        let secret = sharks
            .recover(&shares)
            .map_err(|e| crate::error::TwonlyError::Generic(e.to_string()))?;
        Ok(secret)
    }
}
