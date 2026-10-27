use super::queries;
use super::table::*;
use crate::database::app::{watch, AppDatabase};
use crate::error::Result;
use std::sync::Arc;
use tokio::sync::RwLock;
use tokio_util::sync::CancellationToken;

pub async fn received(
    databases: Arc<RwLock<Arc<AppDatabase>>>, cutoff: i64, group: Option<String>,
    cancellation: CancellationToken, emit: impl Fn(ReceivedStories) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["messages", "media_files", "contacts"],
        cancellation,
        move |database| {
            let group = group.clone();

            async move {
                let mut tx = database.read_pool.begin().await?;

                let value = queries::received(&mut tx, cutoff, group.as_deref(), None).await?;

                tx.commit().await?;

                Ok(value)
            }
        },
        emit,
    )
    .await
}

pub async fn own(
    databases: Arc<RwLock<Arc<AppDatabase>>>, cutoff: i64, cancellation: CancellationToken,
    emit: impl Fn(OwnStories) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["messages", "media_files"],
        cancellation,
        move |database| async move {
            let mut tx = database.read_pool.begin().await?;

            let value = queries::own(&mut tx, cutoff).await?;

            tx.commit().await?;

            Ok(value)
        },
        emit,
    )
    .await
}

pub async fn viewers(
    databases: Arc<RwLock<Arc<AppDatabase>>>, media: String, cancellation: CancellationToken,
    emit: impl Fn(StoryViewers) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["messages", "group_members", "contacts", "message_actions"],
        cancellation,
        move |database| {
            let media = media.clone();

            async move {
                let mut tx = database.read_pool.begin().await?;

                let value = queries::viewers(&mut tx, &media).await?;

                tx.commit().await?;

                Ok(value)
            }
        },
        emit,
    )
    .await
}
