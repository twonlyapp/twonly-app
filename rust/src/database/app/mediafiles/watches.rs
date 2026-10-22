use super::queries;
use super::table::*;
use crate::database::app::{watch, AppDatabase};
use crate::error::Result;
use std::sync::Arc;
use tokio::sync::RwLock;
use tokio_util::sync::CancellationToken;

pub async fn media(
    databases: Arc<RwLock<Arc<AppDatabase>>>, input: MediaQuery, cancellation: CancellationToken,
    emit: impl Fn(MediaCollection) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["media_files", "messages"],
        cancellation,
        move |database| {
            let input = input.clone();

            async move { queries::list(&mut *database.read_pool.acquire().await?, &input).await }
        },
        move |rows| {
            let mut seen = std::collections::HashSet::new();

            let order = rows.iter().map(|row| row.media_id.clone()).collect();

            let files = rows
                .into_iter()
                .filter(|row| seen.insert(row.media_id.clone()))
                .collect();

            emit(MediaCollection { files, order })
        },
    )
    .await
}

pub async fn by_chat(
    databases: Arc<RwLock<Arc<AppDatabase>>>, cancellation: CancellationToken,
    emit: impl Fn(ChatMediaSnapshot) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["media_files", "messages", "groups"],
        cancellation,
        |database| async move {
            let mut tx = database.read_pool.begin().await?;

            let result = queries::by_chat(&mut tx).await?;

            tx.commit().await?;

            Ok(result)
        },
        emit,
    )
    .await
}
