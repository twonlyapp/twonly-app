use super::transaction::CommandTransaction;
use super::DatabaseWatch;
use crate::bridge::database::DatabaseSession;
use crate::bridge::get_twonly_flutter;
use crate::database::app::contact_groups::{queries, watches, writes};
use crate::error::Result;
use crate::frb_generated::StreamSink;

pub use crate::database::app::contact_groups::table::{
    ContactGroup, ContactGroupFilter, ContactGroupInput, ContactGroupLabels, ContactGroupMember,
};

pub async fn list_contact_groups(
    filter: ContactGroupFilter, user_id: Option<i64>, group_id: Option<String>,
    transaction: &DatabaseSession,
) -> Result<Vec<ContactGroup>> {
    let mut tx = CommandTransaction::read(transaction).await?;

    let result = queries::list(
        &mut **tx.transaction(),
        filter,
        user_id,
        group_id.as_deref(),
    )
    .await;

    tx.finish(result).await
}

pub async fn get_contact_group(
    id: i64, transaction: &DatabaseSession,
) -> Result<Option<ContactGroup>> {
    let mut tx = CommandTransaction::read(transaction).await?;

    let result = queries::get(&mut **tx.transaction(), id).await;

    tx.finish(result).await
}

pub async fn get_contact_group_members(
    id: i64, transaction: &DatabaseSession,
) -> Result<Vec<ContactGroupMember>> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = queries::members(&mut **tx.transaction(), id).await;

    tx.finish(result).await
}

macro_rules! mutate {
    ($owner:expr, $operation:ident $(, $argument:expr)*) => {{
        let mut tx = CommandTransaction::begin($owner).await?;
        let result = writes::$operation(tx.transaction() $(, $argument)*).await;
        tx.finish(result).await
    }};
}

pub async fn create_contact_group(
    input: ContactGroupInput, transaction: &DatabaseSession,
) -> Result<i64> {
    mutate!(transaction, create, &input)
}

pub async fn update_contact_group(
    id: i64, input: ContactGroupInput, transaction: &DatabaseSession,
) -> Result<bool> {
    mutate!(transaction, update, id, &input)
}

pub async fn delete_contact_group(id: i64, transaction: &DatabaseSession) -> Result<i64> {
    mutate!(transaction, delete, id)
}

pub async fn increment_contact_group_usage(id: i64, transaction: &DatabaseSession) -> Result<()> {
    mutate!(transaction, increment_usage, id)
}

pub async fn set_contact_group_user(
    id: i64, user_id: i64, selected: bool, transaction: &DatabaseSession,
) -> Result<()> {
    mutate!(transaction, set_user_membership, id, user_id, selected)
}

pub async fn set_contact_group_chat(
    id: i64, group_id: String, selected: bool, transaction: &DatabaseSession,
) -> Result<()> {
    mutate!(transaction, set_group_membership, id, &group_id, selected)
}

pub async fn replace_contact_group_members(
    id: i64, user_ids: Vec<i64>, group_ids: Vec<String>, transaction: &DatabaseSession,
) -> Result<()> {
    mutate!(transaction, replace_members, id, user_ids, group_ids)
}

pub async fn watch_contact_groups(
    filter: ContactGroupFilter, user_id: Option<i64>, group_id: Option<String>,
    control: &DatabaseWatch, sink: StreamSink<Vec<ContactGroup>>,
) -> Result<()> {
    control
        .traced(watches::groups(
            get_twonly_flutter()?.app_db.clone(),
            filter,
            user_id,
            group_id,
            control.cancellation.clone(),
            move |value| sink.add(value).is_ok(),
        ))
        .await
}

pub async fn watch_contact_group_ids(
    user_id: Option<i64>, group_id: Option<String>, control: &DatabaseWatch,
    sink: StreamSink<Vec<i64>>,
) -> Result<()> {
    control
        .traced(watches::membership_ids(
            get_twonly_flutter()?.app_db.clone(),
            user_id,
            group_id,
            control.cancellation.clone(),
            move |value| sink.add(value).is_ok(),
        ))
        .await
}

pub async fn watch_contact_group_labels(
    for_users: bool, control: &DatabaseWatch, sink: StreamSink<ContactGroupLabels>,
) -> Result<()> {
    control
        .traced(watches::labels(
            get_twonly_flutter()?.app_db.clone(),
            for_users,
            control.cancellation.clone(),
            move |value| sink.add(value).is_ok(),
        ))
        .await
}
