use super::transaction::CommandTransaction;
use super::{DatabaseSession, DatabaseWatch};
use crate::bridge::get_twonly_flutter;
pub use crate::database::app::groups::native::FlameState;
pub use crate::database::app::groups::table::{
    Group, GroupFilter, GroupHistory, GroupHistoryPatch, GroupMember, GroupMemberPatch,
    GroupMembersQuery, GroupMembersWithContacts, GroupPatch, GroupQuery,
};
use crate::database::app::groups::{queries, watches, writes};
use crate::error::Result;
use crate::frb_generated::StreamSink;

pub async fn list_groups(input: GroupQuery, transaction: &DatabaseSession) -> Result<Vec<Group>> {
    let mut tx = CommandTransaction::read(transaction).await?;

    let result = queries::list(&mut **tx.transaction(), &input).await;

    tx.finish(result).await
}

pub async fn list_group_members(
    input: GroupMembersQuery, transaction: &DatabaseSession,
) -> Result<Vec<GroupMember>> {
    let mut tx = CommandTransaction::read(transaction).await?;

    let result = queries::members(&mut **tx.transaction(), &input).await;

    tx.finish(result).await
}

pub async fn get_group_contacts(
    input: GroupMembersQuery, transaction: &DatabaseSession,
) -> Result<GroupMembersWithContacts> {
    let mut tx = CommandTransaction::read(transaction).await?;

    let result = queries::members_with_contacts(&mut **tx.transaction(), &input).await;

    tx.finish(result).await
}

pub async fn upsert_group(patch: GroupPatch, transaction: &DatabaseSession) -> Result<Group> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::upsert(tx.transaction(), patch).await;

    tx.finish(result).await
}

pub async fn create_direct_group(
    contact: i64, own_id: i64, patch: GroupPatch, transaction: &DatabaseSession,
) -> Result<Group> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::direct_chat(tx.transaction(), contact, own_id, patch).await;

    tx.finish(result).await
}

pub async fn update_group(
    id: String, patch: GroupPatch, transaction: &DatabaseSession,
) -> Result<()> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::update(tx.transaction(), Some(&id), patch).await;

    tx.finish(result).await
}

pub async fn delete_group(id: String, transaction: &DatabaseSession) -> Result<()> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::delete(tx.transaction(), &id).await;

    tx.finish(result).await
}

pub async fn upsert_group_member(
    patch: GroupMemberPatch, transaction: &DatabaseSession,
) -> Result<()> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::upsert_member(tx.transaction(), patch).await;

    tx.finish(result).await
}

pub async fn insert_group_history(
    patch: GroupHistoryPatch, transaction: &DatabaseSession,
) -> Result<()> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::insert_history(tx.transaction(), patch).await;

    tx.finish(result).await
}

pub async fn increase_group_exchange(
    group: String, contact: Option<i64>, timestamp: i64, now: i64, transaction: &DatabaseSession,
) -> Result<()> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::increase_exchange(tx.transaction(), &group, contact, timestamp, now).await;

    tx.finish(result).await
}

pub async fn watch_groups(
    input: GroupQuery, control: &DatabaseWatch, sink: StreamSink<Vec<Group>>,
) -> Result<()> {
    watches::groups(
        get_twonly_flutter()?.app_db.clone(),
        input,
        control.cancellation.clone(),
        move |value| sink.add(value).is_ok(),
    )
    .await
}

pub async fn watch_group_members(
    input: GroupMembersQuery, control: &DatabaseWatch, sink: StreamSink<Vec<GroupMember>>,
) -> Result<()> {
    watches::members(
        get_twonly_flutter()?.app_db.clone(),
        input,
        control.cancellation.clone(),
        move |value| sink.add(value).is_ok(),
    )
    .await
}

pub async fn watch_group_contacts(
    input: GroupMembersQuery, control: &DatabaseWatch, sink: StreamSink<GroupMembersWithContacts>,
) -> Result<()> {
    watches::contacts(
        get_twonly_flutter()?.app_db.clone(),
        input,
        control.cancellation.clone(),
        move |value| sink.add(value).is_ok(),
    )
    .await
}

pub async fn watch_group_history(
    group: String, since: Option<i64>, control: &DatabaseWatch, sink: StreamSink<Vec<GroupHistory>>,
) -> Result<()> {
    watches::history(
        get_twonly_flutter()?.app_db.clone(),
        group,
        since,
        control.cancellation.clone(),
        move |value| sink.add(value).is_ok(),
    )
    .await
}

pub async fn watch_groups_total_media(
    control: &DatabaseWatch, sink: StreamSink<i64>,
) -> Result<()> {
    watches::total_media(
        get_twonly_flutter()?.app_db.clone(),
        control.cancellation.clone(),
        move |value| sink.add(value).is_ok(),
    )
    .await
}

pub async fn watch_group_flame(
    group: String, control: &DatabaseWatch, sink: StreamSink<FlameState>,
) -> Result<()> {
    watches::flame(
        get_twonly_flutter()?.app_db.clone(),
        group,
        control.cancellation.clone(),
        move |value| sink.add(value).is_ok(),
    )
    .await
}

pub async fn get_group(id: String, transaction: &DatabaseSession) -> Result<Option<Group>> {
    let mut tx = CommandTransaction::read(transaction).await?;

    let result = queries::get(&mut **tx.transaction(), &id).await;

    tx.finish(result).await
}
