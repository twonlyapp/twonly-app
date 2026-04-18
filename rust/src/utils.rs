use parking_lot::{RwLock, RwLockReadGuard};
use std::sync::Arc;

#[derive(Default, Clone)]
pub(crate) struct Shared<T>(Arc<RwLock<T>>);
impl<T> Shared<T>
where
    T: Clone,
{
    pub(crate) fn new(value: T) -> Self {
        Self(Arc::new(RwLock::new(value)))
    }
    pub(crate) fn get(&self) -> RwLockReadGuard<'_, T> {
        self.0.read()
    }
    pub(crate) fn cloned(&self) -> T {
        self.0.read().clone()
    }
    pub(crate) fn set(&self, value: T) {
        *self.0.write() = value;
    }
}
