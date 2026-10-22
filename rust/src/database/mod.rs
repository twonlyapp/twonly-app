/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

pub mod app;
pub(crate) mod cipher;
pub(crate) mod lifecycle;
pub(crate) mod maintenance;
pub(crate) mod restore_install;
pub mod signal;
pub(crate) mod snapshot;

/// Retain the original key material for resume: another process may migrate
/// passphrase to raw form while this process has every handle closed.

pub(crate) struct Source {
    path: String,
    key: Option<zeroize::Zeroizing<String>>,
    read_only: bool,
}

impl Source {
    fn new(path: &str, key: Option<&str>, read_only: bool) -> Self {
        Self {
            path: path.into(),
            key: key.map(|key| zeroize::Zeroizing::new(key.to_owned())),
            read_only,
        }
    }
}
