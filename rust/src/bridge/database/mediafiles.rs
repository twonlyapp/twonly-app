use super::transaction::CommandTransaction;
use super::{DatabaseSession, DatabaseWatch};
use crate::bridge::get_twonly_flutter;
pub use crate::database::app::mediafiles::table::{
    ChatMediaLink, ChatMediaSnapshot, MediaCollection, MediaFile, MediaFilePatch, MediaFilter,
    MediaMonthLabel, MediaQuery, MediaStorageStat,
};
use crate::database::app::mediafiles::{queries, storage, watches, writes};
use crate::error::Result;
use crate::frb_generated::StreamSink;

pub async fn list_media_files(
    input: MediaQuery, transaction: &DatabaseSession,
) -> Result<Vec<MediaFile>> {
    let mut tx = CommandTransaction::read(transaction).await?;

    let result = queries::list(tx.transaction(), &input).await;

    tx.finish(result).await
}

pub async fn upsert_media_file(
    mut patch: MediaFilePatch, transaction: &DatabaseSession,
) -> Result<MediaFile> {
    if patch.media_id.is_none() {
        patch.media_id = Some(uuid::Uuid::now_v7().to_string());
    }

    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::upsert(tx.transaction(), patch).await;

    tx.finish(result).await
}

pub async fn update_media_files(
    id: Option<String>, patch: MediaFilePatch, transaction: &DatabaseSession,
) -> Result<()> {
    // No Flutter caller needs a table-wide update. An omitted ID must never
    // silently turn editor cleanup into a write to the complete media library.
    let id = id.ok_or_else(|| {
        crate::error::TwonlyError::Generic(
            "A media ID is required; bulk media updates are not supported".into(),
        )
    })?;

    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::update(tx.transaction(), Some(&id), patch).await;

    tx.finish(result).await
}

pub async fn delete_media_file(id: String, transaction: &DatabaseSession) -> Result<()> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::delete(tx.transaction(), &id).await;

    tx.finish(result).await
}

pub async fn media_message_ids_by_hash(
    hash: Vec<u8>, sender: i64, transaction: &DatabaseSession,
) -> Result<Vec<String>> {
    let mut tx = CommandTransaction::read(transaction).await?;

    let result = queries::message_ids_by_hash(tx.transaction(), &hash, sender).await;

    tx.finish(result).await
}

pub async fn media_storage_stats(
    directory: String, transaction: &DatabaseSession,
) -> Result<Vec<MediaStorageStat>> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = storage::stats(tx.transaction(), directory.into()).await;

    tx.finish(result).await
}

pub async fn cloud_only_media_count(
    directory: String, transaction: &DatabaseSession,
) -> Result<i64> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = storage::cloud_only_count(tx.transaction(), directory.into()).await;

    tx.finish(result).await
}

pub async fn watch_media_files(
    input: MediaQuery, control: &DatabaseWatch, sink: StreamSink<MediaCollection>,
) -> Result<()> {
    control
        .traced(watches::media(
            get_twonly_flutter()?.app_db.clone(),
            input,
            control.cancellation.clone(),
            move |value| sink.add(value).is_ok(),
        ))
        .await
}

pub async fn watch_chat_media_files(
    control: &DatabaseWatch, sink: StreamSink<ChatMediaSnapshot>,
) -> Result<()> {
    control
        .traced(watches::by_chat(
            get_twonly_flutter()?.app_db.clone(),
            control.cancellation.clone(),
            move |value| sink.add(value).is_ok(),
        ))
        .await
}

pub async fn missing_media_month_dates(transaction: &DatabaseSession) -> Result<Vec<i64>> {
    let mut tx = CommandTransaction::read(transaction).await?;

    let result = queries::missing_month_dates(tx.transaction()).await;

    tx.finish(result).await
}

pub async fn fill_media_months(
    labels: Vec<MediaMonthLabel>, transaction: &DatabaseSession,
) -> Result<()> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::fill_months(tx.transaction(), labels).await;

    tx.finish(result).await
}

pub async fn finish_memories_backup_disable(
    directory: String, transaction: &DatabaseSession,
) -> Result<i64> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = storage::finish_backup_disable(tx.transaction(), directory.into()).await;

    let removed = tx.finish(result).await?;

    if transaction.transaction.is_none() {
        if let Ok(ctx) = crate::context::Context::get_static() {
            if let Err(error) =
                crate::services::mediafiles::cleanup_pending_file_removals(ctx).await
            {
                tracing::warn!(%error, "media cleanup will be retried");
            }
        }
    }

    Ok(removed)
}

pub async fn get_media_file(
    id: String, transaction: &DatabaseSession,
) -> Result<Option<MediaFile>> {
    let mut tx = CommandTransaction::read(transaction).await?;

    let result = queries::get(tx.transaction(), &id).await;

    tx.finish(result).await
}
