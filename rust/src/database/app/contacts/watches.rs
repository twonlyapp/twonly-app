use super::queries;
use super::table::*;
use crate::database::app::{watch, AppDatabase};
use crate::error::Result;
use std::sync::Arc;
use tokio::sync::RwLock;
use tokio_util::sync::CancellationToken;

pub async fn contacts(
    databases: Arc<RwLock<Arc<AppDatabase>>>, input: ContactQuery, cancellation: CancellationToken,
    emit: impl Fn(Vec<Contact>) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["contacts"],
        cancellation,
        move |database| {
            let input = input.clone();

            async move { queries::list(&mut *database.read_pool.acquire().await?, &input).await }
        },
        emit,
    )
    .await
}

pub async fn count(
    databases: Arc<RwLock<Arc<AppDatabase>>>, metric: ContactCount,
    cancellation: CancellationToken, emit: impl Fn(i64) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["contacts"],
        cancellation,
        move |database| async move {
            queries::count(&mut *database.read_pool.acquire().await?, metric).await
        },
        emit,
    )
    .await
}

pub async fn photo(
    databases: Arc<RwLock<Arc<AppDatabase>>>, id: i64, cancellation: CancellationToken,
    emit: impl Fn(bool) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["contacts", "received_custom_avatars"],
        cancellation,
        move |database| async move {
            queries::has_photo(&mut *database.read_pool.acquire().await?, id).await
        },
        emit,
    )
    .await
}
