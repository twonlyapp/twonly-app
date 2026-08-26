/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

#[cfg(test)]
mod in_memory_store;
#[cfg(test)]
pub(super) use in_memory_store::InMemoryStore;

mod native;
pub(crate) use native::{NativeUserDiscoveryStore, NativeUserDiscoveryUtils};
