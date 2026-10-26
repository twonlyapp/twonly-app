use super::transaction::CommandTransaction;
use super::{DatabaseSession, DatabaseWatch};
use crate::bridge::callbacks::CURRENT_CALLBACK_ID;
use crate::bridge::get_twonly_flutter;
pub use crate::database::app::key_verifications::table::{
    ContactVerifications, FirstVerificationType, GroupVerification, KeyVerification,
    TransferredVerification, TransferredVerifications, VerificationStatus,
};
use crate::database::app::key_verifications::{queries, watches, writes};
use crate::error::Result;
use crate::frb_generated::StreamSink;

pub async fn insert_verification_token(
    token: Vec<u8>, transaction: &DatabaseSession,
) -> Result<i64> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::insert_token(tx.transaction(), &token).await;

    tx.finish(result).await
}

pub async fn first_verification_types(
    transaction: &DatabaseSession,
) -> Result<Vec<FirstVerificationType>> {
    let mut tx = CommandTransaction::read(transaction).await?;

    let result = queries::first_types(&mut **tx.transaction()).await;

    tx.finish(result).await
}

pub async fn is_contact_verified(contact: i64, transaction: &DatabaseSession) -> Result<bool> {
    let mut tx = CommandTransaction::read(transaction).await?;

    let result = queries::is_verified(&mut **tx.transaction(), contact).await;

    tx.finish(result).await
}

pub async fn get_contact_verifications(
    contact: i64, transaction: &DatabaseSession,
) -> Result<Vec<KeyVerification>> {
    let mut tx = CommandTransaction::read(transaction).await?;

    let result = queries::list(&mut **tx.transaction(), contact).await;

    tx.finish(result).await
}

pub async fn change_key_verification(
    contact: i64, kind: Option<String>, verified_by: Option<i64>, verification_id: Option<i64>,
    update_discovery: bool, verified_at: Option<i64>, callback_id: u32,
    transaction: &DatabaseSession,
) -> Result<()> {
    CURRENT_CALLBACK_ID
        .scope(callback_id, async move {
            let mut tx = CommandTransaction::begin(transaction).await?;

            let result = async {
                let refresh = if let Some(kind) = kind.as_deref() {
                    writes::insert(tx.transaction(), contact, kind, verified_by).await?;

                    true
                } else {
                    writes::delete(tx.transaction(), contact, verification_id).await?
                };

                if update_discovery && refresh {
                    get_twonly_flutter()?
                        .user_discovery
                        .get()
                        .await
                        .update_verification_state_for_user(
                            contact,
                            if kind.is_some() { verified_at } else { None },
                            tx.transaction(),
                        )
                        .await?;
                }

                Ok(())
            }
            .await;

            tx.finish(result).await
        })
        .await
}

pub async fn watch_contact_verifications(
    contact: i64, control: &DatabaseWatch, sink: StreamSink<ContactVerifications>,
) -> Result<()> {
    control
        .traced(watches::contact(
            get_twonly_flutter()?.app_db.clone(),
            contact,
            control.cancellation.clone(),
            move |value| sink.add(value).is_ok(),
        ))
        .await
}

pub async fn watch_transferred_verifications(
    contact: i64, control: &DatabaseWatch, sink: StreamSink<TransferredVerifications>,
) -> Result<()> {
    control
        .traced(watches::transferred(
            get_twonly_flutter()?.app_db.clone(),
            contact,
            control.cancellation.clone(),
            move |value| sink.add(value).is_ok(),
        ))
        .await
}

pub async fn watch_groups_verification(
    group: Option<String>, control: &DatabaseWatch, sink: StreamSink<Vec<GroupVerification>>,
) -> Result<()> {
    control
        .traced(watches::groups(
            get_twonly_flutter()?.app_db.clone(),
            group,
            control.cancellation.clone(),
            move |value| sink.add(value).is_ok(),
        ))
        .await
}
