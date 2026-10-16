/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use std::collections::HashMap;

use crate::{
    database::app::tables::{FlameState, Group},
    error::Result,
    services::groups::GroupService,
};

/// The flame counter for one chat, derived against today rather than read from
/// the stored column. See `Group::flame_states`.
pub async fn flame_state(group_id: String) -> Result<FlameState> {
    let ctx = crate::context::Context::get_static()?;
    let database = ctx.app_db.read().await.clone();
    Group::flame_state(&database.pool, &group_id).await
}

/// The same derivation for several chats at once. Sorting a contact list by
/// streak needs every value up front, because a comparator cannot await.
pub async fn flame_states(group_ids: Vec<String>) -> Result<HashMap<String, FlameState>> {
    let ctx = crate::context::Context::get_static()?;
    let database = ctx.app_db.read().await.clone();
    Group::flame_states(&database.pool, Some(group_ids)).await
}

/// Whether to offer the user a restore for this chat.
pub async fn can_restore_flames(group_id: String) -> Result<bool> {
    let ctx = crate::context::Context::get_static()?;
    let database = ctx.app_db.read().await.clone();
    Group::can_restore_flames(&database.pool, &group_id).await
}

/// Restores the lost streak, posts the chat entry, and syncs the peer.
pub async fn restore_flames(group_id: String) -> Result<bool> {
    let ctx = crate::context::Context::get_static()?;
    GroupService::new(ctx).restore_flames(group_id).await
}

pub async fn create_new_group(group_name: String, member_ids: Vec<i64>) -> Result<bool> {
    let ctx = crate::context::Context::get_static()?;
    GroupService::new(ctx)
        .create_group(group_name, member_ids)
        .await
}

pub async fn fetch_group_state(group_id: String) -> Result<bool> {
    let ctx = crate::context::Context::get_static()?;
    GroupService::new(ctx).fetch_group_state(group_id).await
}

pub async fn add_hidden_contact(contact_id: i64) -> Result<bool> {
    let ctx = crate::context::Context::get_static()?;
    GroupService::new(ctx).add_hidden_contact(contact_id).await
}

pub async fn fetch_group_states_for_unjoined_groups() -> Result<()> {
    let ctx = crate::context::Context::get_static()?;
    GroupService::new(ctx)
        .fetch_group_states_for_unjoined_groups()
        .await
}

pub async fn fetch_missing_group_public_keys(group_id: Option<String>, force: bool) -> Result<()> {
    let ctx = crate::context::Context::get_static()?;
    GroupService::new(ctx)
        .fetch_missing_group_public_keys(group_id, force)
        .await
}

pub async fn manage_admin_state(group_id: String, contact_id: i64, remove: bool) -> Result<bool> {
    let ctx = crate::context::Context::get_static()?;
    GroupService::new(ctx)
        .manage_admin(group_id, contact_id, remove)
        .await
}

pub async fn update_group_name(group_id: String, group_name: String) -> Result<bool> {
    let ctx = crate::context::Context::get_static()?;
    GroupService::new(ctx)
        .update_group_name(group_id, group_name)
        .await
}

pub async fn update_chat_deletion_time(
    group_id: String,
    delete_messages_after_milliseconds: i64,
) -> Result<bool> {
    let ctx = crate::context::Context::get_static()?;
    GroupService::new(ctx)
        .update_chat_deletion_time(group_id, delete_messages_after_milliseconds)
        .await
}

pub async fn add_new_group_members(group_id: String, member_ids: Vec<i64>) -> Result<bool> {
    let ctx = crate::context::Context::get_static()?;
    GroupService::new(ctx)
        .add_members(group_id, member_ids)
        .await
}

pub async fn remove_member_from_group(group_id: String, contact_id: i64) -> Result<bool> {
    let ctx = crate::context::Context::get_static()?;
    GroupService::new(ctx)
        .remove_member(group_id, contact_id)
        .await
}

pub async fn leave_group(group_id: String) -> Result<bool> {
    let ctx = crate::context::Context::get_static()?;
    GroupService::new(ctx).leave_group(group_id).await
}
