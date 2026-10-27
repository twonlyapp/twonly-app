use super::transaction::CommandTransaction;
use super::{DatabaseSession, DatabaseWatch};
use crate::bridge::get_twonly_flutter;
use crate::database::app::mediafiles::table::MediaCollection;
pub use crate::database::app::messages::table::{
    MessageAction, MessageActionsWithContacts, MessageFilter, MessageHistory, MessagePatch,
    MessageQuery, StoredMessage,
};
use crate::database::app::messages::{queries, watches, writes};
use crate::error::Result;
use crate::frb_generated::StreamSink;

pub async fn list_messages(
    input: MessageQuery, transaction: &DatabaseSession,
) -> Result<Vec<StoredMessage>> {
    let mut tx = CommandTransaction::read(transaction).await?;

    let result = queries::list(tx.transaction(), &input).await;

    tx.finish(result).await
}

pub async fn update_messages(
    id: String, by_media: bool, patch: MessagePatch, transaction: &DatabaseSession,
) -> Result<()> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = if by_media {
        writes::update_by_media(tx.transaction(), &id, patch).await
    } else {
        writes::update(tx.transaction(), &id, patch).await
    };

    tx.finish(result).await
}

pub async fn delete_message(id: String, transaction: &DatabaseSession) -> Result<()> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::delete(tx.transaction(), &id).await;

    tx.finish(result).await
}

pub async fn clear_chat_messages(group: String, transaction: &DatabaseSession) -> Result<()> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::clear_chat(tx.transaction(), &group).await;

    tx.finish(result).await
}

pub async fn purge_messages(now_ms: i64, transaction: &DatabaseSession) -> Result<()> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::purge(tx.transaction(), now_ms).await;

    tx.finish(result).await
}

pub async fn edit_message(
    sender: Option<i64>, id: String, text: String, timestamp: i64, transaction: &DatabaseSession,
) -> Result<()> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::edit(tx.transaction(), sender, &id, &text, timestamp).await;

    tx.finish(result).await
}

pub async fn delete_message_from_sender(
    sender: Option<i64>, id: String, transaction: &DatabaseSession,
) -> Result<()> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::delete_from_sender(tx.transaction(), sender, &id).await;

    tx.finish(result).await?;

    if transaction.transaction.is_none() {
        let ctx = crate::context::Context::get_static()?;

        if let Err(error) = crate::services::mediafiles::cleanup_pending_file_removals(ctx).await {
            tracing::warn!(%error, "pending media file cleanup will be retried");
        }
    }

    Ok(())
}

pub async fn watch_messages(
    input: MessageQuery, control: &DatabaseWatch, sink: StreamSink<Vec<StoredMessage>>,
) -> Result<()> {
    control
        .traced(watches::messages(
            get_twonly_flutter()?.app_db.clone(),
            input,
            control.cancellation.clone(),
            move |value| sink.add(value).is_ok(),
        ))
        .await
}

pub async fn watch_unopened_media(
    control: &DatabaseWatch, sink: StreamSink<MediaCollection>,
) -> Result<()> {
    control
        .traced(watches::unopened_media(
            get_twonly_flutter()?.app_db.clone(),
            control.cancellation.clone(),
            move |value| sink.add(value).is_ok(),
        ))
        .await
}

pub async fn watch_message_actions(
    id: String, control: &DatabaseWatch, sink: StreamSink<MessageActionsWithContacts>,
) -> Result<()> {
    control
        .traced(watches::actions(
            get_twonly_flutter()?.app_db.clone(),
            id,
            control.cancellation.clone(),
            move |value| sink.add(value).is_ok(),
        ))
        .await
}

pub async fn watch_delivery_actions(
    ids: Vec<String>, control: &DatabaseWatch, sink: StreamSink<Vec<MessageAction>>,
) -> Result<()> {
    control
        .traced(watches::delivery_actions(
            get_twonly_flutter()?.app_db.clone(),
            ids,
            control.cancellation.clone(),
            move |value| sink.add(value).is_ok(),
        ))
        .await
}

pub async fn watch_message_history(
    id: String, control: &DatabaseWatch, sink: StreamSink<Vec<MessageHistory>>,
) -> Result<()> {
    control
        .traced(watches::history(
            get_twonly_flutter()?.app_db.clone(),
            id,
            control.cancellation.clone(),
            move |value| sink.add(value).is_ok(),
        ))
        .await
}

pub async fn get_message(
    id: String, transaction: &DatabaseSession,
) -> Result<Option<StoredMessage>> {
    let mut tx = CommandTransaction::read(transaction).await?;

    let result = queries::get(tx.transaction(), &id).await;

    tx.finish(result).await
}
