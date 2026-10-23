/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

pub mod app_database;
pub mod backup;
pub mod key_manager;
pub mod signal;
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

#[cfg(test)]
mod tests {
    use super::RustUtils;

    #[test]
    fn legacy_recovery_shares_remain_readable() {
        // Three-of-three recovery shares generated with blahaj 0.6.0.
        let shares = [
            "01f628b0f2432c02dd8a33522605b7749ad6cd3191e7e4",
            "02885fae5838d951c1157bce6d2536721f5a68cc1ba938",
            "03121279cb188c736efa2bf33d45f37fa5ffc09ef82ba8",
        ]
        .map(|share| hex::decode(share).unwrap())
        .to_vec();

        assert_eq!(
            RustUtils::recover_secret(shares, 3).unwrap(),
            b"legacy recovery secret"
        );
    }
}
