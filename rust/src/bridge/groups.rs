/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use std::collections::HashMap;

use crate::database::app::groups::native::{FlameState, Group};
use crate::database::app::groups::vacation::{
    VacationWindow, MAX_VACATION_DAYS, MIN_FLAMES_TO_FREEZE, MIN_VACATION_DAYS, VACATION_ICONS,
};
use crate::error::Result;
use crate::services::groups::GroupService;

/// The group ID of the direct chat between two users. The app asks here instead
/// of deriving it itself, so both sides can never disagree on it.
#[flutter_rust_bridge::frb(sync)]
pub fn direct_chat_id(user_id: i64, other_user_id: i64) -> String {
    Group::direct_chat_id(user_id, other_user_id)
}

/// The flame counter for one chat, derived against today rather than read from
/// the stored column. See `Group::flame_states`.
pub async fn flame_state(group_id: String) -> Result<FlameState> {
    let ctx = crate::context::Context::get_static()?;

    ctx.foreground_database_call(|| async {
        let database = ctx.app_db.read().await.clone();

        Group::flame_state(&database.read_pool, &group_id).await
    })
    .await
}

/// The same derivation for several chats at once. Sorting a contact list by
/// streak needs every value up front, because a comparator cannot await.
pub async fn flame_states(group_ids: Vec<String>) -> Result<HashMap<String, FlameState>> {
    let ctx = crate::context::Context::get_static()?;

    ctx.foreground_database_call(|| async {
        let database = ctx.app_db.read().await.clone();

        Group::flame_states(&database.read_pool, Some(group_ids.clone())).await
    })
    .await
}

/// Whether to offer the user a restore for this chat.
pub async fn can_restore_flames(group_id: String) -> Result<bool> {
    let ctx = crate::context::Context::get_static()?;

    ctx.foreground_database_call(|| async {
        let database = ctx.app_db.read().await.clone();

        Group::can_restore_flames(&database.read_pool, &group_id).await
    })
    .await
}

/// Restores the lost streak, posts the chat entry, and syncs the peer.
pub async fn restore_flames(group_id: String) -> Result<bool> {
    let ctx = crate::context::Context::get_static()?;

    GroupService::new(ctx).restore_flames(group_id).await
}

/// What the "On Vacation" picker offers.
pub struct VacationOptions {
    pub icons: Vec<String>,
    pub min_days: u32,
    pub max_days: u32,
    pub min_flames: i64,
}

#[flutter_rust_bridge::frb(sync)]
pub fn vacation_options() -> VacationOptions {
    VacationOptions {
        icons: VACATION_ICONS.iter().map(|icon| (*icon).to_owned()).collect(),
        min_days: MIN_VACATION_DAYS,
        max_days: MAX_VACATION_DAYS,
        min_flames: MIN_FLAMES_TO_FREEZE,
    }
}

/// The user's own vacation while it lasts.
pub async fn own_vacation() -> Result<Option<VacationWindow>> {
    let ctx = crate::context::Context::get_static()?;

    ctx.foreground_database_call(|| async {
        let database = ctx.app_db.read().await.clone();

        Group::own_vacation(&database.read_pool, crate::utils::current_time().timestamp()).await
    })
    .await
}

/// How many chats a vacation starting now would freeze.
pub async fn vacation_candidate_count() -> Result<u32> {
    let ctx = crate::context::Context::get_static()?;

    ctx.foreground_database_call(|| async {
        let database = ctx.app_db.read().await.clone();

        Ok(Group::vacation_candidates(&database.read_pool).await?.len() as u32)
    })
    .await
}

/// Freezes the big streaks for `days` days and tells those chats. Returns how
/// many chats were frozen; zero means no vacation was started.
pub async fn start_vacation(days: u32, icon: String) -> Result<u32> {
    let ctx = crate::context::Context::get_static()?;

    GroupService::new(ctx).start_vacation(days, icon).await
}

/// Ends the user's vacation early. Returns how many chats were told.
pub async fn end_vacation() -> Result<u32> {
    let ctx = crate::context::Context::get_static()?;

    GroupService::new(ctx).end_vacation().await
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
    group_id: String, delete_messages_after_milliseconds: i64,
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
