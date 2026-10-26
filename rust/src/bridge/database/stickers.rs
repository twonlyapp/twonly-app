use super::transaction::CommandTransaction;
use super::DatabaseWatch;
use crate::bridge::database::DatabaseSession;
use crate::bridge::get_twonly_flutter;
pub use crate::database::app::stickers::table::{
    LocalSticker, StickerAsset, StickerCollection, StickerMetadata,
};
use crate::database::app::stickers::{queries, watches, writes};
use crate::error::Result;
use crate::frb_generated::StreamSink;

pub async fn get_sticker(
    hash: String, transaction: &DatabaseSession,
) -> Result<Option<LocalSticker>> {
    let mut tx = CommandTransaction::read(transaction).await?;

    let result = queries::get(&mut **tx.transaction(), &hash).await;

    tx.finish(result).await
}

pub async fn save_sticker(
    webp: Vec<u8>, width: i64, height: i64, expected_hash: Option<String>,
    transaction: &DatabaseSession,
) -> Result<bool> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::save(
        tx.transaction(),
        &webp,
        width,
        height,
        expected_hash.as_deref(),
    )
    .await;

    tx.finish(result).await
}

pub async fn replace_sticker(
    hash: String, webp: Vec<u8>, width: i64, height: i64, expected_hash: String,
    transaction: &DatabaseSession,
) -> Result<LocalSticker> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::replace(
        tx.transaction(),
        &hash,
        &webp,
        width,
        height,
        &expected_hash,
    )
    .await;

    tx.finish(result).await
}

pub async fn record_sticker_use(hash: String, transaction: &DatabaseSession) -> Result<()> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::record_use(tx.transaction(), &hash).await;

    tx.finish(result).await
}

pub async fn remove_sticker(hash: String, transaction: &DatabaseSession) -> Result<()> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::remove(tx.transaction(), &hash).await;

    tx.finish(result).await
}

pub async fn watch_stickers(
    control: &DatabaseWatch, sink: StreamSink<StickerCollection>,
) -> Result<()> {
    control
        .traced(watches::collection(
            get_twonly_flutter()?.app_db.clone(),
            control.cancellation.clone(),
            move |value| sink.add(value).is_ok(),
        ))
        .await
}
