/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

pub mod app_database;
pub mod backup;
pub mod key_manager;
pub mod signal;
pub mod user_discovery;

use crate::error::{Result, TwonlyError};
use blahaj::{Share, Sharks};
use std::collections::{BTreeSet, HashMap, HashSet};

pub struct RustUtils {}

/// A secret that some `threshold` of the given shares reconstruct.
#[derive(Clone, Debug, PartialEq, Eq)]

pub struct RecoveredSecretCandidate {
    pub secret: Vec<u8>,
    /// Positions in the input of every share that reconstructs this secret.
    pub share_indexes: Vec<u32>,
}

/// Share combinations one recovery may try. Honest recoveries stay far below
/// it; only a flood of submissions reaches it.
const MAX_SHARE_COMBINATIONS: u64 = 20_000;

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

    /// Recovers every secret that some `threshold` of `shares` reconstruct,
    /// the one most shares agree on first.
    ///
    /// Shamir shares carry no integrity: interpolating over a duplicate, a
    /// stale share from an earlier setup or a forged one silently yields
    /// garbage. Each combination is therefore tried on its own, so the honest
    /// shares still agree on their secret and a share missing from the chosen
    /// candidate is the one that does not fit. Identical shares count once,
    /// and two different shares with the same x are never combined.
    pub fn recover_secret_candidates(
        shares: Vec<Vec<u8>>, threshold: u8,
    ) -> Result<Vec<RecoveredSecretCandidate>> {
        if threshold < 2 {
            return Err(TwonlyError::ShamirsSecret(format!(
                "threshold {threshold} is below 2"
            )));
        }

        let mut seen = HashSet::new();

        // Only shares of the same length can come from one secret.
        let mut by_length: HashMap<usize, Vec<(u32, Share, u8)>> = HashMap::new();

        for (index, bytes) in shares.iter().enumerate() {
            if !seen.insert(bytes.as_slice()) {
                continue;
            }

            let Ok(share) = Share::try_from(bytes.as_slice()) else {
                continue;
            };

            by_length
                .entry(bytes.len())
                .or_default()
                .push((index as u32, share, bytes[0]));
        }

        let size = usize::from(threshold);

        let combinations: u64 = by_length
            .values()
            .map(|group| binomial(group.len() as u64, size as u64))
            .fold(0, u64::saturating_add);

        if combinations > MAX_SHARE_COMBINATIONS {
            return Err(TwonlyError::ShamirsSecret(format!(
                "{combinations} share combinations exceed the limit"
            )));
        }

        let sharks = Sharks(threshold);

        let mut supporters: HashMap<Vec<u8>, BTreeSet<u32>> = HashMap::new();

        for group in by_length.values() {
            for_each_combination(group.len(), size, |picked| {
                let xs: HashSet<u8> = picked.iter().map(|&i| group[i].2).collect();

                if xs.len() != picked.len() {
                    return;
                }

                let Ok(secret) = sharks.recover(picked.iter().map(|&i| &group[i].1)) else {
                    return;
                };

                supporters
                    .entry(secret)
                    .or_default()
                    .extend(picked.iter().map(|&i| group[i].0));
            });
        }

        let mut candidates: Vec<RecoveredSecretCandidate> = supporters
            .into_iter()
            .map(|(secret, indexes)| RecoveredSecretCandidate {
                secret,
                share_indexes: indexes.into_iter().collect(),
            })
            .collect();

        candidates.sort_by(|a, b| {
            b.share_indexes
                .len()
                .cmp(&a.share_indexes.len())
                .then_with(|| a.share_indexes.cmp(&b.share_indexes))
        });

        Ok(candidates)
    }
}

fn binomial(n: u64, k: u64) -> u64 {
    if k > n {
        return 0;
    }

    (0..k.min(n - k)).fold(1u64, |acc, i| acc.saturating_mul(n - i) / (i + 1))
}

/// Calls `visit` with the positions of every `size`-element subset of
/// `0..len`, in lexicographic order.
fn for_each_combination(len: usize, size: usize, mut visit: impl FnMut(&[usize])) {
    if size == 0 || size > len {
        return;
    }

    let mut picked: Vec<usize> = (0..size).collect();

    loop {
        visit(&picked);

        let Some(position) = (0..size).rev().find(|&i| picked[i] < len - size + i) else {
            return;
        };

        picked[position] += 1;

        for i in position + 1..size {
            picked[i] = picked[i - 1] + 1;
        }
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

    const SECRET: &[u8] = b"shared secret data of the owner";

    fn shares_of(secret: &[u8], threshold: u8, count: usize) -> Vec<Vec<u8>> {
        RustUtils::generate_shares(secret.to_vec(), count as u8, threshold).unwrap()
    }

    #[test]
    fn candidates_ignore_a_share_submitted_twice() {
        let shares = shares_of(SECRET, 2, 4);

        // Interpolating over the duplicate cancels it out in GF(256).
        let input = vec![shares[0].clone(), shares[1].clone(), shares[1].clone()];

        assert_ne!(RustUtils::recover_secret(input.clone(), 2).unwrap(), SECRET);

        let candidates = RustUtils::recover_secret_candidates(input, 2).unwrap();

        assert_eq!(candidates.len(), 1);
        assert_eq!(candidates[0].secret, SECRET);
        assert_eq!(candidates[0].share_indexes, vec![0, 1]);
    }

    #[test]
    fn candidates_keep_the_honest_pair_next_to_a_stale_share() {
        let shares = shares_of(SECRET, 2, 4);
        let stale = shares_of(b"secret data of an earlier setup", 2, 4);

        let input = vec![shares[0].clone(), stale[2].clone(), shares[3].clone()];

        let candidates = RustUtils::recover_secret_candidates(input, 2).unwrap();

        // With exactly `threshold` honest shares every pair is equally well
        // supported; the caller tells them apart by parsing the secret.
        assert_eq!(candidates.len(), 3);

        let honest = candidates.iter().find(|c| c.secret == SECRET).unwrap();

        assert_eq!(honest.share_indexes, vec![0, 2]);
    }

    #[test]
    fn candidates_prefer_the_secret_more_shares_agree_on() {
        let shares = shares_of(SECRET, 2, 5);
        let stale = shares_of(b"secret data of an earlier setup", 2, 5);

        let input = vec![
            stale[0].clone(),
            shares[1].clone(),
            stale[4].clone(),
            shares[2].clone(),
            shares[3].clone(),
        ];

        let candidates = RustUtils::recover_secret_candidates(input, 2).unwrap();

        assert_eq!(candidates[0].secret, SECRET);
        assert_eq!(candidates[0].share_indexes, vec![1, 3, 4]);
    }

    #[test]
    fn candidates_never_combine_two_shares_with_the_same_x() {
        let shares = shares_of(SECRET, 2, 3);
        let stale = shares_of(b"secret data of an earlier setup", 2, 3);

        // Both carry x = 1: a helper that kept its share from before a re-setup.
        let input = vec![shares[0].clone(), stale[0].clone(), shares[1].clone()];

        let candidates = RustUtils::recover_secret_candidates(input, 2).unwrap();

        assert_eq!(candidates.len(), 2);
        assert!(candidates.iter().all(|c| c.share_indexes != vec![0, 1]));

        let honest = candidates.iter().find(|c| c.secret == SECRET).unwrap();

        assert_eq!(honest.share_indexes, vec![0, 2]);
    }

    #[test]
    fn candidates_reject_a_threshold_below_two() {
        let mut forged = vec![1u8];
        forged.extend_from_slice(b"attacker chosen data");

        assert!(RustUtils::recover_secret_candidates(vec![forged], 1).is_err());
    }

    #[test]
    fn candidates_skip_shares_of_another_length() {
        let shares = shares_of(SECRET, 2, 3);
        let other = shares_of(b"short", 2, 3);

        let input = vec![other[0].clone(), shares[0].clone(), shares[2].clone()];

        let candidates = RustUtils::recover_secret_candidates(input, 2).unwrap();

        assert_eq!(candidates.len(), 1);
        assert_eq!(candidates[0].secret, SECRET);
        assert_eq!(candidates[0].share_indexes, vec![1, 2]);
    }

    #[test]
    fn candidates_refuse_a_flood_of_shares() {
        // C(60, 5) is far above the limit.
        let input: Vec<Vec<u8>> = (1..=60u8)
            .map(|x| {
                let mut share = vec![x];
                share.extend_from_slice(SECRET);
                share
            })
            .collect();

        assert!(RustUtils::recover_secret_candidates(input, 5).is_err());
    }
}
