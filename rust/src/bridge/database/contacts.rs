use super::transaction::CommandTransaction;
use super::{DatabaseSession, DatabaseWatch};
use crate::bridge::get_twonly_flutter;
pub use crate::database::app::contacts::table::{
    Contact, ContactCount, ContactFilter, ContactPatch, ContactQuery,
};
use crate::database::app::contacts::{queries, watches, writes};
use crate::error::Result;
use crate::frb_generated::StreamSink;

pub async fn get_contact(id: i64, transaction: &DatabaseSession) -> Result<Option<Contact>> {
    let mut tx = CommandTransaction::read(transaction).await?;

    let result = queries::get(&mut **tx.transaction(), id).await;

    tx.finish(result).await
}

pub async fn list_contacts(
    input: ContactQuery, transaction: &DatabaseSession,
) -> Result<Vec<Contact>> {
    let mut tx = CommandTransaction::read(transaction).await?;

    let result = queries::list(&mut **tx.transaction(), &input).await;

    tx.finish(result).await
}

pub async fn count_contacts(metric: ContactCount, transaction: &DatabaseSession) -> Result<i64> {
    let mut tx = CommandTransaction::read(transaction).await?;

    let result = queries::count(&mut **tx.transaction(), metric).await;

    tx.finish(result).await
}

pub async fn upsert_contact(patch: ContactPatch, transaction: &DatabaseSession) -> Result<i64> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::upsert(tx.transaction(), patch).await;

    tx.finish(result).await
}

pub async fn update_contact(
    id: i64, patch: ContactPatch, transaction: &DatabaseSession,
) -> Result<()> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::update(tx.transaction(), id, patch).await;

    tx.finish(result).await
}

pub async fn delete_contact(id: i64, transaction: &DatabaseSession) -> Result<()> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::delete(tx.transaction(), id).await;

    tx.finish(result).await
}

pub async fn reset_contacts_recovery(transaction: &DatabaseSession) -> Result<()> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::reset_recovery(tx.transaction()).await;

    tx.finish(result).await
}

pub async fn watch_contacts(
    input: ContactQuery, control: &DatabaseWatch, sink: StreamSink<Vec<Contact>>,
) -> Result<()> {
    watches::contacts(
        get_twonly_flutter()?.app_db.clone(),
        input,
        control.cancellation.clone(),
        move |value| sink.add(value).is_ok(),
    )
    .await
}

pub async fn watch_contacts_count(
    metric: ContactCount, control: &DatabaseWatch, sink: StreamSink<i64>,
) -> Result<()> {
    watches::count(
        get_twonly_flutter()?.app_db.clone(),
        metric,
        control.cancellation.clone(),
        move |value| sink.add(value).is_ok(),
    )
    .await
}

pub async fn watch_contact_photo(
    id: i64, control: &DatabaseWatch, sink: StreamSink<bool>,
) -> Result<()> {
    watches::photo(
        get_twonly_flutter()?.app_db.clone(),
        id,
        control.cancellation.clone(),
        move |value| sink.add(value).is_ok(),
    )
    .await
}
