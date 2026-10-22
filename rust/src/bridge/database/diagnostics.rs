use super::transaction::CommandTransaction;
use super::DatabaseSession;
use crate::bridge::get_twonly_flutter;
pub use crate::database::app::diagnostics::table::MockGalleryItem;
use crate::database::app::diagnostics::writes;
use crate::error::Result;

pub async fn seed_mock_gallery(
    items: Vec<MockGalleryItem>, opened_at: i64, transaction: &DatabaseSession,
) -> Result<()> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::seed_gallery(tx.transaction(), items, opened_at).await;

    tx.finish(result).await
}

pub async fn seed_mock_messages(
    group: String, count: i64, now: i64, prefix: String, transaction: &DatabaseSession,
) -> Result<i64> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::seed_messages(tx.transaction(), &group, count, now, &prefix).await;

    tx.finish(result).await
}

pub async fn export_debug_database(path: String) -> Result<()> {
    let database = get_twonly_flutter()?.app_db.read().await.clone();

    writes::export_debug(&database, std::path::Path::new(&path)).await
}
