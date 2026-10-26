use super::transaction::CommandTransaction;
use super::{DatabaseSession, DatabaseWatch};
use crate::bridge::get_twonly_flutter;
use crate::database::app::contacts::table::Contact;
pub use crate::database::app::recovery::table::{RecoveryContacts, RecoveryShare};
use crate::database::app::recovery::{queries, watches, writes};
use crate::error::Result;
use crate::frb_generated::StreamSink;

pub async fn verified_contact_ids(transaction: &DatabaseSession) -> Result<Vec<i64>> {
    let mut tx = CommandTransaction::read(transaction).await?;

    let result = queries::verified_ids(tx.transaction()).await;

    tx.finish(result).await
}

pub async fn recovery_friend_ids(transaction: &DatabaseSession) -> Result<Vec<i64>> {
    let mut tx = CommandTransaction::read(transaction).await?;

    let result = queries::trusted_ids(tx.transaction()).await;

    tx.finish(result).await
}

pub async fn recovery_contacts(
    selection: RecoveryContacts, limit: Option<i64>, transaction: &DatabaseSession,
) -> Result<Vec<Contact>> {
    let mut tx = CommandTransaction::read(transaction).await?;

    let result = queries::contacts(tx.transaction(), selection, limit).await;

    tx.finish(result).await
}

pub async fn store_recovery_shares(
    shares: Vec<RecoveryShare>, transaction: &DatabaseSession,
) -> Result<()> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::store_shares(tx.transaction(), shares).await;

    tx.finish(result).await
}

pub async fn watch_recovery_contacts(
    selection: RecoveryContacts, control: &DatabaseWatch, sink: StreamSink<Vec<Contact>>,
) -> Result<()> {
    control
        .traced(watches::contacts(
            get_twonly_flutter()?.app_db.clone(),
            selection,
            control.cancellation.clone(),
            move |value| sink.add(value).is_ok(),
        ))
        .await
}

pub async fn watch_recovery_count(
    selection: RecoveryContacts, control: &DatabaseWatch, sink: StreamSink<i64>,
) -> Result<()> {
    control
        .traced(watches::count(
            get_twonly_flutter()?.app_db.clone(),
            selection,
            control.cancellation.clone(),
            move |value| sink.add(value).is_ok(),
        ))
        .await
}
