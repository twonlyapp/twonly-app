use std::sync::Arc;
use tokio::sync::{RwLock, RwLockReadGuard};

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
