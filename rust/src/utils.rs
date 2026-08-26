/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use std::sync::Arc;
use tokio::sync::{RwLock, RwLockReadGuard};

pub(crate) fn milliseconds_to_seconds(timestamp: i64) -> i64 {
    timestamp.div_euclid(1_000)
}

pub(crate) fn new_uuid_v4() -> String {
    uuid::Uuid::new_v4().to_string()
}

#[derive(Default, Clone)]
pub(crate) struct Shared<T>(Arc<RwLock<T>>);
impl<T> Shared<T> {
    pub(crate) fn new(value: T) -> Self {
        Self(Arc::new(RwLock::new(value)))
    }
    pub(crate) async fn get(&self) -> RwLockReadGuard<'_, T> {
        self.0.read().await
    }
    // pub(crate) async fn set(&self, value: T) {
    //     *self.0.write().await = value;
    // }
}

#[cfg(test)]
mod tests {
    use super::milliseconds_to_seconds;

    #[test]
    fn converts_milliseconds_to_seconds() {
        assert_eq!(milliseconds_to_seconds(1_999), 1);
        assert_eq!(milliseconds_to_seconds(1_000), 1);
        assert_eq!(milliseconds_to_seconds(999), 0);
    }
}
