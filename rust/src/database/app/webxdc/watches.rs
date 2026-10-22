use super::queries;
use super::table::WebxdcCardInstance;
use crate::database::app::{watch, AppDatabase};
use crate::error::Result;
use std::sync::Arc;
use tokio::sync::RwLock;
use tokio_util::sync::CancellationToken;

pub async fn instance(
    databases: Arc<RwLock<Arc<AppDatabase>>>, id: String, cancellation: CancellationToken,
    emit: impl Fn(Option<WebxdcCardInstance>) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["webxdc_instances"],
        cancellation,
        move |database| {
            let id = id.clone();

            async move { queries::instance(&mut *database.read_pool.acquire().await?, &id).await }
        },
        emit,
    )
    .await
}

pub async fn serial(
    databases: Arc<RwLock<Arc<AppDatabase>>>, id: String, cancellation: CancellationToken,
    emit: impl Fn(i64) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["webxdc_updates"],
        cancellation,
        move |database| {
            let id = id.clone();

            async move { queries::serial(&mut *database.read_pool.acquire().await?, &id).await }
        },
        emit,
    )
    .await
}
