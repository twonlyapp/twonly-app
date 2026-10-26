use super::queries;
use super::table::*;
use crate::database::app::{watch, AppDatabase};
use crate::error::Result;
use std::sync::Arc;
use tokio::sync::RwLock;
use tokio_util::sync::CancellationToken;

pub async fn messages(
    databases: Arc<RwLock<Arc<AppDatabase>>>, ids: Vec<String>, cancellation: CancellationToken,
    emit: impl Fn(Vec<StoredReaction>) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["reactions"],
        cancellation,
        move |database| {
            let ids = ids.clone();

            async move {
                queries::list(
                    &mut *crate::performance::acquire(&database.read_pool).await?,
                    &ids,
                )
                .await
            }
        },
        emit,
    )
    .await
}

pub async fn last(
    databases: Arc<RwLock<Arc<AppDatabase>>>, group: String, cancellation: CancellationToken,
    emit: impl Fn(Option<StoredReaction>) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["reactions", "messages"],
        cancellation,
        move |database| {
            let group = group.clone();

            async move {
                queries::last(
                    &mut *crate::performance::acquire(&database.read_pool).await?,
                    &group,
                )
                .await
            }
        },
        emit,
    )
    .await
}

pub async fn latest(
    databases: Arc<RwLock<Arc<AppDatabase>>>, cancellation: CancellationToken,
    emit: impl Fn(Vec<GroupReaction>) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["reactions", "messages"],
        cancellation,
        |database| async move {
            queries::latest_by_group(&mut *crate::performance::acquire(&database.read_pool).await?)
                .await
        },
        emit,
    )
    .await
}

pub async fn contacts(
    databases: Arc<RwLock<Arc<AppDatabase>>>, message: String, cancellation: CancellationToken,
    emit: impl Fn(ReactionsWithContacts) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["reactions", "contacts"],
        cancellation,
        move |database| {
            let message = message.clone();

            async move {
                let mut tx = database.read_pool.begin().await?;

                let value = queries::with_contacts(&mut tx, &message).await?;

                tx.commit().await?;

                Ok(value)
            }
        },
        emit,
    )
    .await
}
