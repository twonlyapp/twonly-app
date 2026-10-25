use super::queries;
use super::table::*;
use crate::database::app::mediafiles::table::MediaCollection;
use crate::database::app::{watch, AppDatabase};
use crate::error::Result;
use std::sync::Arc;
use tokio::sync::RwLock;
use tokio_util::sync::CancellationToken;

pub async fn messages(
    databases: Arc<RwLock<Arc<AppDatabase>>>, input: MessageQuery, cancellation: CancellationToken,
    emit: impl Fn(Vec<StoredMessage>) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["messages", "groups", "media_files"],
        cancellation,
        move |database| {
            let input = input.clone();

            async move { queries::list(&mut *database.read_pool.acquire().await?, &input).await }
        },
        emit,
    )
    .await
}

pub async fn unopened_media(
    databases: Arc<RwLock<Arc<AppDatabase>>>, cancellation: CancellationToken,
    emit: impl Fn(MediaCollection) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["messages", "media_files"],
        cancellation,
        |database| async move {
            queries::unopened_media(&mut *database.read_pool.acquire().await?).await
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

pub async fn actions(
    databases: Arc<RwLock<Arc<AppDatabase>>>, id: String, cancellation: CancellationToken,
    emit: impl Fn(MessageActionsWithContacts) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["message_actions", "contacts", "messages", "webxdc_updates"],
        cancellation,
        move |database| {
            let id = id.clone();

            async move {
                let mut tx = database.read_pool.begin().await?;

                let value = queries::actions(&mut tx, &id).await?;

                tx.commit().await?;

                Ok(value)
            }
        },
        emit,
    )
    .await
}

pub async fn delivery_actions(
    databases: Arc<RwLock<Arc<AppDatabase>>>, ids: Vec<String>, cancellation: CancellationToken,
    emit: impl Fn(Vec<MessageAction>) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["message_actions", "messages", "groups"],
        cancellation,
        move |database| {
            let ids = ids.clone();

            async move {
                queries::delivery_actions(&mut *database.read_pool.acquire().await?, &ids).await
            }
        },
        emit,
    )
    .await
}

pub async fn history(
    databases: Arc<RwLock<Arc<AppDatabase>>>, id: String, cancellation: CancellationToken,
    emit: impl Fn(Vec<MessageHistory>) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["message_histories"],
        cancellation,
        move |database| {
            let id = id.clone();

            async move { queries::history(&mut *database.read_pool.acquire().await?, &id).await }
        },
        emit,
    )
    .await
}
