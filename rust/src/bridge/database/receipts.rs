use super::transaction::CommandTransaction;
use super::DatabaseWatch;
use crate::bridge::database::DatabaseSession;
use crate::bridge::get_twonly_flutter;
pub use crate::database::app::patch::{NullableBytes, NullableInt, NullableText};
pub use crate::database::app::receipts::table::{Receipt, ReceiptPatch};
use crate::database::app::receipts::writes::{self, ReceiptTarget};
use crate::database::app::receipts::{queries, watches};
use crate::error::Result;
use crate::frb_generated::StreamSink;

pub enum ReceiptSelection {
    Id,
    Message,
    Contact,
    ContactMessage,
}

fn selection<'a>(selection: ReceiptSelection, id: &'a str, contact: i64) -> ReceiptTarget<'a> {
    match selection {
        ReceiptSelection::Id => ReceiptTarget::Id(id),
        ReceiptSelection::Message => ReceiptTarget::Message(id),
        ReceiptSelection::Contact => ReceiptTarget::Contact(contact),
        ReceiptSelection::ContactMessage => ReceiptTarget::ContactMessage(contact, id),
    }
}

pub async fn delete_receipts(
    target: ReceiptSelection, id: String, contact: i64, transaction: &DatabaseSession,
) -> Result<()> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::delete(tx.transaction(), selection(target, &id, contact)).await;

    tx.finish(result).await
}

pub async fn purge_received_receipts(cutoff: i64, transaction: &DatabaseSession) -> Result<()> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::purge(tx.transaction(), cutoff).await;

    tx.finish(result).await
}

pub async fn get_receipt(id: String, transaction: &DatabaseSession) -> Result<Option<Receipt>> {
    let mut tx = CommandTransaction::read(transaction).await?;

    let result = queries::get(&mut **tx.transaction(), &id).await;

    tx.finish(result).await
}

pub async fn get_media_retransmission_receipts(
    cutoff: i64, transaction: &DatabaseSession,
) -> Result<Vec<Receipt>> {
    let mut tx = CommandTransaction::read(transaction).await?;

    let result = queries::media_retransmissions(&mut **tx.transaction(), cutoff).await;

    tx.finish(result).await
}

pub async fn update_receipts(
    target: ReceiptSelection, id: String, contact: i64, patch: ReceiptPatch,
    transaction: &DatabaseSession,
) -> Result<()> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::update(tx.transaction(), selection(target, &id, contact), patch).await;

    tx.finish(result).await
}

pub async fn watch_receipts(control: &DatabaseWatch, sink: StreamSink<Vec<Receipt>>) -> Result<()> {
    control
        .traced(watches::all(
            get_twonly_flutter()?.app_db.clone(),
            control.cancellation.clone(),
            move |value| sink.add(value).is_ok(),
        ))
        .await
}
