use super::queries;
use super::table::Receipt;
use crate::database::app::{watch, AppDatabase};
use crate::error::Result;
use std::sync::Arc;
use tokio::sync::RwLock;
use tokio_util::sync::CancellationToken;

pub async fn all(
    databases: Arc<RwLock<Arc<AppDatabase>>>, cancellation: CancellationToken,
    emit: impl Fn(Vec<Receipt>) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["receipts"],
        cancellation,
        |database| async move {
            queries::list(&mut *crate::performance::acquire(&database.read_pool).await?).await
        },
        emit,
    )
    .await
}
