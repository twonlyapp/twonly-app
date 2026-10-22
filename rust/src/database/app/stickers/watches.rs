use super::queries;
use super::table::*;
use crate::database::app::{watch, AppDatabase};
use crate::error::Result;
use std::collections::HashSet;
use std::sync::{Arc, Mutex};
use tokio::sync::RwLock;
use tokio_util::sync::CancellationToken;

pub async fn collection(
    databases: Arc<RwLock<Arc<AppDatabase>>>, cancellation: CancellationToken,
    emit: impl Fn(StickerCollection) -> bool,
) -> Result<()> {
    let known = Arc::new(Mutex::new(HashSet::<String>::new()));

    let query_known = known.clone();

    watch::snapshots(
        databases,
        &["stickers"],
        cancellation,
        move |database| {
            let known = query_known.clone();

            async move {
                let mut tx = database.read_pool.begin().await?;

                let items = queries::list(&mut tx).await?;

                let missing: Vec<_> = {
                    let known = known.lock().unwrap();

                    items
                        .iter()
                        .filter(|item| !known.contains(&item.content_hash))
                        .map(|item| item.content_hash.clone())
                        .collect()
                };

                let assets = queries::assets(&mut tx, &missing).await?;

                tx.commit().await?;

                Ok(StickerCollection { items, assets })
            }
        },
        move |value| {
            *known.lock().unwrap() = value
                .items
                .iter()
                .map(|item| item.content_hash.clone())
                .collect();

            emit(value)
        },
    )
    .await
}
