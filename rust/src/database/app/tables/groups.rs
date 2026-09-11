/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use sqlx::{Sqlite, Transaction};
use std::collections::{HashMap, HashSet};

use crate::context::Context;
use crate::error::{Result, TwonlyError};
use crate::utils::{current_time, start_of_local_day};

use super::Contact;

const MAX_FUTURE_TIMESTAMP_SKEW_SECONDS: i64 = 10 * 60;

pub struct Group;

impl Group {
    pub async fn flame_sync_candidates(pool: &sqlx::Pool<Sqlite>) -> Result<Vec<FlameSyncGroup>> {
        Ok(sqlx::query_as!(
            FlameSyncGroup,
            r#"SELECT group_id, total_media_counter, last_flame_counter_change, last_flame_sync
               FROM groups WHERE last_flame_counter_change IS NOT NULL"#
        )
        .fetch_all(pool)
        .await?)
    }

    /// The chat the user exchanges the most media with. Derived rather than
    /// stored: it is a pure function of `total_media_counter`, and persisting it
    /// in the user configuration would leave Flutter's in-memory copy stale,
    /// because nothing tells Dart when Rust rewrites that file.
    pub async fn best_friend_group_id(pool: &sqlx::Pool<Sqlite>) -> Result<Option<String>> {
        Ok(sqlx::query_scalar!(
            "SELECT group_id FROM groups ORDER BY total_media_counter DESC LIMIT 1"
        )
        .fetch_optional(pool)
        .await?)
    }

    /// The flame counter as it is shown, which is not what the column holds: a
    /// streak survives in the database until the next media exchange rewrites
    /// it, so whether it still counts has to be decided against today.
    ///
    /// Passing `None` derives the state of every group; the best friend is
    /// resolved once either way.
    pub async fn flame_states(
        pool: &sqlx::Pool<Sqlite>,
        group_ids: Option<Vec<String>>,
    ) -> Result<HashMap<String, FlameState>> {
        let rows = sqlx::query_as!(
            FlameRow,
            r#"SELECT group_id, flame_counter, also_best_friend,
                      last_message_send, last_message_received, last_flame_counter_change
               FROM groups"#
        )
        .fetch_all(pool)
        .await?;

        let best_friend = Self::best_friend_group_id(pool).await?;
        let start_of_today = start_of_local_day()?;

        let wanted = group_ids.map(|ids| ids.into_iter().collect::<HashSet<_>>());
        Ok(rows
            .into_iter()
            .filter(|row| {
                wanted
                    .as_ref()
                    .is_none_or(|ids| ids.contains(&row.group_id))
            })
            .map(|row| {
                let is_best_friend = row.also_best_friend != 0
                    && best_friend.as_deref() == Some(row.group_id.as_str());
                let state = row.derive(start_of_today, is_best_friend);
                (row.group_id, state)
            })
            .collect())
    }

    pub async fn flame_state(pool: &sqlx::Pool<Sqlite>, group_id: &str) -> Result<FlameState> {
        Ok(Self::flame_states(pool, Some(vec![group_id.to_string()]))
            .await?
            .remove(group_id)
            .unwrap_or_default())
    }

    /// Whether the "restore flames" offer makes sense: a streak worth restoring
    /// was lost recently enough that the user still remembers having it.
    pub async fn can_restore_flames(pool: &sqlx::Pool<Sqlite>, group_id: &str) -> Result<bool> {
        let Some(group) = sqlx::query!(
            "SELECT max_flame_counter, max_flame_counter_from FROM groups WHERE group_id = ?",
            group_id,
        )
        .fetch_optional(pool)
        .await?
        else {
            return Ok(false);
        };

        let counter = Self::flame_state(pool, group_id).await?.counter;
        Ok(can_restore(
            group.max_flame_counter,
            group.max_flame_counter_from,
            counter,
            current_time().timestamp(),
        ))
    }

    /// Puts the lost streak back and marks today as exchanged in both
    /// directions, so the restored counter survives the next derivation.
    /// Returns the restored value, or `None` when there was nothing to restore.
    pub async fn restore_flames(
        tr: &mut Transaction<'_, Sqlite>,
        group_id: &str,
    ) -> Result<Option<i64>> {
        let Some(group) = sqlx::query!(
            r#"SELECT flame_counter, max_flame_counter, max_flame_counter_from,
                      last_message_send, last_message_received, last_flame_counter_change
               FROM groups WHERE group_id = ?"#,
            group_id,
        )
        .fetch_optional(&mut **tr)
        .await?
        else {
            return Ok(None);
        };

        let now = current_time().timestamp();
        let state = FlameRow {
            group_id: group_id.to_string(),
            flame_counter: group.flame_counter,
            also_best_friend: 0,
            last_message_send: group.last_message_send,
            last_message_received: group.last_message_received,
            last_flame_counter_change: group.last_flame_counter_change,
        }
        .derive(start_of_local_day()?, false);
        if !can_restore(
            group.max_flame_counter,
            group.max_flame_counter_from,
            state.counter,
            now,
        ) {
            return Ok(None);
        }

        sqlx::query!(
            r#"UPDATE groups SET
                   flame_counter = ?,
                   last_flame_counter_change = ?,
                   last_message_send = ?,
                   last_message_received = ?
               WHERE group_id = ?"#,
            group.max_flame_counter,
            now,
            now,
            now,
            group_id,
        )
        .execute(&mut **tr)
        .await?;

        Ok(Some(group.max_flame_counter))
    }

    pub async fn set_last_flame_sync(
        pool: &sqlx::Pool<Sqlite>,
        group_id: &str,
        timestamp: i64,
    ) -> Result<()> {
        sqlx::query!(
            "UPDATE groups SET last_flame_sync = ? WHERE group_id = ?",
            timestamp,
            group_id,
        )
        .execute(pool)
        .await?;
        Ok(())
    }

    /// Records one successfully created media message and updates the flame
    /// state in the same transaction. This used to round-trip through Dart,
    /// which made the counters non-atomic and unavailable to headless Rust
    /// runtimes.
    pub async fn record_media_exchange(
        tr: &mut Transaction<'_, Sqlite>,
        group_id: &str,
        received: bool,
        timestamp: i64,
    ) -> Result<()> {
        let Some(group) = sqlx::query!(
            r#"SELECT last_message_send, last_message_received,
                      last_flame_counter_change, flame_counter,
                      max_flame_counter, max_flame_counter_from
               FROM groups WHERE group_id = ?"#,
            group_id,
        )
        .fetch_optional(&mut **tr)
        .await?
        else {
            return Ok(());
        };

        if received {
            sqlx::query!(
                r#"UPDATE contacts
                   SET media_received_counter = media_received_counter + 1
                   WHERE user_id IN (
                       SELECT contact_id FROM group_members WHERE group_id = ?
                   )"#,
                group_id,
            )
            .execute(&mut **tr)
            .await?;
        } else {
            sqlx::query!(
                r#"UPDATE contacts
                   SET media_send_counter = media_send_counter + 1
                   WHERE user_id IN (
                       SELECT contact_id FROM group_members WHERE group_id = ?
                   )"#,
                group_id,
            )
            .execute(&mut **tr)
            .await?;
        }

        let now = current_time();
        let start_of_today = start_of_local_day()?;
        let two_days_ago = start_of_today - 2 * 24 * 60 * 60;

        let mut flame_counter = group.flame_counter;
        let mut max_flame_counter = group.max_flame_counter;
        let mut max_flame_counter_from = group.max_flame_counter_from;
        let mut last_flame_counter_change = group.last_flame_counter_change;

        if group
            .last_message_send
            .zip(group.last_message_received)
            .is_some_and(|(sent, received)| sent < two_days_ago || received < two_days_ago)
        {
            flame_counter = 0;
        }

        if last_flame_counter_change.is_none_or(|changed| changed < start_of_today) {
            let completes_today = if received {
                group
                    .last_message_send
                    .is_some_and(|sent| sent > start_of_today)
            } else {
                group
                    .last_message_received
                    .is_some_and(|received| received > start_of_today)
            };
            if completes_today {
                flame_counter += 1;
                if last_flame_counter_change.is_none_or(|changed| changed < timestamp) {
                    last_flame_counter_change = Some(timestamp);
                }
                if flame_counter >= max_flame_counter
                    || max_flame_counter_from
                        .is_none_or(|from| from < now.timestamp() - 5 * 24 * 60 * 60)
                {
                    max_flame_counter = flame_counter;
                    max_flame_counter_from = Some(now.timestamp());
                }
            }
        }

        let last_message_send = if !received
            && group
                .last_message_send
                .is_none_or(|previous| previous < timestamp)
        {
            Some(timestamp)
        } else {
            group.last_message_send
        };
        let last_message_received = if received
            && group
                .last_message_received
                .is_none_or(|previous| previous < timestamp)
        {
            Some(timestamp)
        } else {
            group.last_message_received
        };

        sqlx::query!(
            r#"UPDATE groups SET
                   total_media_counter = total_media_counter + 1,
                   last_flame_counter_change = ?,
                   last_message_received = ?,
                   last_message_send = ?,
                   flame_counter = ?,
                   max_flame_counter = ?,
                   max_flame_counter_from = ?
               WHERE group_id = ?"#,
            last_flame_counter_change,
            last_message_received,
            last_message_send,
            flame_counter,
            max_flame_counter,
            max_flame_counter_from,
            group_id,
        )
        .execute(&mut **tr)
        .await?;

        Ok(())
    }

    pub async fn ensure_exists(tr: &mut Transaction<'_, Sqlite>, group_id: &str) -> Result<()> {
        let exists = sqlx::query_scalar!(
            "SELECT EXISTS(SELECT 1 FROM groups WHERE group_id = ?)",
            group_id
        )
        .fetch_one(&mut **tr)
        .await?
            != 0;

        if !exists {
            return Err(TwonlyError::Generic(format!(
                "group {group_id} does not exist"
            )));
        }

        Ok(())
    }

    pub async fn create_direct_chat(
        ctx: &Context,
        tr: &mut Transaction<'_, Sqlite>,
        contact: Contact,
    ) -> Result<()> {
        let local_user_id = ctx.user_id().await?;
        let contact_id = contact.user_id;
        let group_id = Self::direct_chat_id(local_user_id, contact_id);
        let group_name = contact.get_group_name();

        sqlx::query!(
            r#"
            INSERT INTO groups(group_id, group_name, is_direct_chat, is_group_admin, joined_group)
            VALUES (?, ?, 1, 1, 1)
            ON CONFLICT(group_id) DO UPDATE SET joined_group = 1
            "#,
            group_id,
            group_name,
        )
        .execute(&mut **tr)
        .await?;

        sqlx::query!(
            "INSERT OR IGNORE INTO group_members(group_id, contact_id) VALUES (?, ?)",
            group_id,
            contact_id,
        )
        .execute(&mut **tr)
        .await?;

        Ok(())
    }

    pub fn direct_chat_id(a: i64, b: i64) -> String {
        let (high, low) = if a >= b {
            (a as u64, b as u64)
        } else {
            (b as u64, a as u64)
        };
        let hex = format!("{high:016x}{low:016x}");
        format!(
            "{}-{}-{}-{}-{}",
            &hex[0..8],
            &hex[8..12],
            &hex[12..16],
            &hex[16..20],
            &hex[20..32]
        )
    }

    pub async fn is_direct_chat(tr: &mut Transaction<'_, Sqlite>, group_id: &str) -> Result<bool> {
        let is_direct = sqlx::query_scalar!(
            "SELECT is_direct_chat FROM groups WHERE group_id = ?",
            group_id
        )
        .fetch_optional(&mut **tr)
        .await?
        .unwrap_or(0)
            != 0;
        Ok(is_direct)
    }

    /// Whether this member is recorded as having left the group.
    ///
    /// [`Self::is_member`] deliberately ignores `member_state` so a member who
    /// left can still be seen to have written; the outgoing fan-out does not.
    /// This is the seam between the two, for callers that need to know the
    /// directions disagree.
    pub async fn has_member_left(
        tr: &mut Transaction<'_, Sqlite>,
        group_id: &str,
        contact_id: i64,
    ) -> Result<bool> {
        Ok(sqlx::query_scalar!(
            r#"
            SELECT EXISTS(
                SELECT 1
                FROM group_members
                WHERE group_id = ? AND contact_id = ? AND member_state = 'leftGroup'
            )
            "#,
            group_id,
            contact_id,
        )
        .fetch_one(&mut **tr)
        .await?
            != 0)
    }

    pub async fn is_member(
        tr: &mut Transaction<'_, Sqlite>,
        group_id: &str,
        contact_id: i64,
    ) -> Result<bool> {
        let is_member = sqlx::query_scalar!(
            r#"
            SELECT EXISTS(
                SELECT 1
                FROM group_members
                WHERE group_id = ? AND contact_id = ?
            )
            "#,
            group_id,
            contact_id,
        )
        .fetch_one(&mut **tr)
        .await?
            != 0;
        Ok(is_member)
    }

    pub async fn increase_last_message_exchange_to_now(
        tr: &mut Transaction<'_, Sqlite>,
        group_id: &str,
    ) -> Result<()> {
        let now = current_unix_timestamp()?;
        Self::increase_last_message_exchange(tr, group_id, now).await
    }

    pub async fn increase_last_message_exchange(
        tr: &mut Transaction<'_, Sqlite>,
        group_id: &str,
        timestamp: i64,
    ) -> Result<()> {
        let now = current_unix_timestamp()?;
        let timestamp = timestamp.min(now.saturating_add(MAX_FUTURE_TIMESTAMP_SKEW_SECONDS));

        sqlx::query!(
            r#"
            UPDATE groups
            SET last_message_exchange = MAX(last_message_exchange, ?),
                deleted_content = 0
            WHERE group_id = ?
            "#,
            timestamp,
            group_id,
        )
        .execute(&mut **tr)
        .await?;

        Ok(())
    }
}

pub struct FlameSyncGroup {
    pub group_id: String,
    pub total_media_counter: i64,
    pub last_flame_counter_change: Option<i64>,
    pub last_flame_sync: Option<i64>,
}

/// The flame counter as the UI shows it. Everything here is derived from the
/// group row against the current local day, never read straight out of a column.
#[derive(Default, Clone, Copy, Debug, PartialEq, Eq)]
pub struct FlameState {
    pub counter: i64,
    /// No exchange yet today, so the streak ends at midnight.
    pub is_expiring: bool,
    /// Mutual: our most-exchanged chat, and they said the same about us.
    pub is_best_friend: bool,
}

struct FlameRow {
    group_id: String,
    flame_counter: i64,
    also_best_friend: i64,
    last_message_send: Option<i64>,
    last_message_received: Option<i64>,
    last_flame_counter_change: Option<i64>,
}

impl FlameRow {
    fn derive(&self, start_of_today: i64, is_best_friend: bool) -> FlameState {
        let expired = FlameState {
            is_best_friend,
            ..FlameState::default()
        };
        let (Some(sent), Some(received), Some(changed)) = (
            self.last_message_send,
            self.last_message_received,
            self.last_flame_counter_change,
        ) else {
            return expired;
        };

        let two_days_ago = start_of_today - 2 * 24 * 60 * 60;
        let one_day_ago = start_of_today - 24 * 60 * 60;

        if sent > two_days_ago && received > two_days_ago || changed > one_day_ago {
            FlameState {
                counter: self.flame_counter,
                is_expiring: sent < one_day_ago || received < one_day_ago,
                is_best_friend,
            }
        } else {
            expired
        }
    }
}

#[derive(bon::Builder)]
pub struct InsertGroup {
    group_id: String,
    group_name: String,
    state_encryption_key: Vec<u8>,
    my_group_private_key: Vec<u8>,
}

impl InsertGroup {
    pub async fn execute(self, tr: &mut Transaction<'_, Sqlite>) -> Result<()> {
        sqlx::query!(
            r#"
            INSERT INTO groups(
                group_id,
                group_name,
                is_group_admin,
                state_encryption_key,
                state_version_id,
                my_group_private_key,
                joined_group
            ) VALUES (?, ?, 1, ?, 1, ?, 1)
            "#,
            self.group_id,
            self.group_name,
            self.state_encryption_key,
            self.my_group_private_key
        )
        .execute(&mut **tr)
        .await?;
        Ok(())
    }
}

#[derive(bon::Builder)]
pub struct UpdateGroup {
    group_id: String,
    group_name: Option<String>,
    delete_messages_after_milliseconds: Option<Option<i64>>,
    is_group_admin: Option<bool>,
    joined_group: Option<bool>,
    left_group: Option<bool>,
    state_version_id: Option<u64>,
}

impl UpdateGroup {
    pub async fn execute(self, tr: &mut Transaction<'_, Sqlite>) -> Result<()> {
        let is_group_admin = self.is_group_admin.map(|v| v as i64);
        let joined_group = self.joined_group.map(|v| v as i64);
        let left_group = self.left_group.map(|v| v as i64);
        let state_version_id = self.state_version_id.map(|v| v as i64);
        // Note: For partial updates, it's easier to coalesce in SQL, but sqlx query! requires static queries.
        // If we want to dynamically update, we might need a specific query for apply_state and others.
        // For apply_state:
        if let (
            Some(group_name),
            Some(delete_ms),
            Some(is_admin),
            Some(joined),
            Some(left),
            Some(version),
        ) = (
            self.group_name,
            self.delete_messages_after_milliseconds,
            is_group_admin,
            joined_group,
            left_group,
            state_version_id,
        ) {
            sqlx::query!(
                r#"
                UPDATE groups 
                SET group_name = ?, 
                    delete_messages_after_milliseconds = COALESCE(?, delete_messages_after_milliseconds), 
                    is_group_admin = ?, 
                    joined_group = ?, 
                    left_group = ?, 
                    state_version_id = ? 
                WHERE group_id = ?
                "#,
                group_name,
                delete_ms,
                is_admin,
                joined,
                left,
                version,
                self.group_id
            )
            .execute(&mut **tr)
            .await?;
        } else if let Some(left_group) = left_group {
            sqlx::query!(
                "UPDATE groups SET left_group = ? WHERE group_id = ?",
                left_group,
                self.group_id
            )
            .execute(&mut **tr)
            .await?;
        }
        Ok(())
    }
}

#[derive(bon::Builder)]
pub struct InsertGroupMember {
    group_id: String,
    contact_id: i64,
    member_state: String,
    #[builder(default)]
    on_conflict_update: bool,
}

impl InsertGroupMember {
    pub async fn execute(self, tr: &mut Transaction<'_, Sqlite>) -> Result<()> {
        if self.on_conflict_update {
            sqlx::query!(
                r#"
                INSERT INTO group_members(group_id, contact_id, member_state)
                VALUES (?, ?, ?)
                ON CONFLICT(group_id, contact_id)
                DO UPDATE SET member_state = excluded.member_state
                "#,
                self.group_id,
                self.contact_id,
                self.member_state
            )
            .execute(&mut **tr)
            .await?;
        } else {
            sqlx::query!(
                "INSERT INTO group_members(group_id, contact_id, member_state) VALUES (?, ?, ?)",
                self.group_id,
                self.contact_id,
                self.member_state
            )
            .execute(&mut **tr)
            .await?;
        }
        Ok(())
    }
}

#[derive(bon::Builder)]
pub struct DeleteGroupMembers {
    group_id: String,
}

impl DeleteGroupMembers {
    pub async fn execute(self, tr: &mut Transaction<'_, Sqlite>) -> Result<()> {
        sqlx::query!(
            "DELETE FROM group_members WHERE group_id = ?",
            self.group_id
        )
        .execute(&mut **tr)
        .await?;
        Ok(())
    }
}

#[derive(bon::Builder)]
pub struct UpdateGroupMemberState {
    group_id: String,
    member_state: String,
}

impl UpdateGroupMemberState {
    pub async fn execute(self, tr: &mut Transaction<'_, Sqlite>) -> Result<()> {
        sqlx::query!(
            "UPDATE group_members SET member_state = ? WHERE group_id = ?",
            self.member_state,
            self.group_id
        )
        .execute(&mut **tr)
        .await?;
        Ok(())
    }
}

#[derive(bon::Builder)]
pub struct GetGroupPublicKey {
    group_id: String,
    contact_id: i64,
}

impl GetGroupPublicKey {
    pub async fn fetch(self, tr: &mut Transaction<'_, Sqlite>) -> Result<Option<Vec<u8>>> {
        let key = sqlx::query_scalar!(
            "SELECT group_public_key FROM group_members WHERE group_id = ? AND contact_id = ?",
            self.group_id,
            self.contact_id
        )
        .fetch_optional(&mut **tr)
        .await?
        .flatten();
        Ok(key)
    }

    // For pool query compatibility
    pub async fn fetch_pool(self, pool: &sqlx::Pool<Sqlite>) -> Result<Option<Vec<u8>>> {
        let key = sqlx::query_scalar!(
            "SELECT group_public_key FROM group_members WHERE group_id = ? AND contact_id = ?",
            self.group_id,
            self.contact_id
        )
        .fetch_optional(pool)
        .await?
        .flatten();
        Ok(key)
    }
}

#[derive(bon::Builder)]
pub struct UpdateGroupPublicKey {
    group_id: String,
    contact_id: i64,
    group_public_key: Vec<u8>,
}

impl UpdateGroupPublicKey {
    pub async fn execute(self, tr: &mut Transaction<'_, Sqlite>) -> Result<()> {
        sqlx::query!(
            "UPDATE group_members SET group_public_key = ? WHERE group_id = ? AND contact_id = ?",
            self.group_public_key,
            self.group_id,
            self.contact_id
        )
        .execute(&mut **tr)
        .await?;
        Ok(())
    }
}

#[derive(bon::Builder)]
pub struct InsertGroupHistory {
    group_id: String,
    affected_contact_id: Option<i64>,
    new_group_name: Option<String>,
    new_delete_messages_after_milliseconds: Option<i64>,
    r#type: String,
}

impl InsertGroupHistory {
    pub async fn execute(self, tr: &mut Transaction<'_, Sqlite>) -> Result<()> {
        let history_id = crate::utils::new_uuid_v4();
        sqlx::query!(
            r#"
            INSERT INTO group_histories(
                group_history_id, 
                group_id, 
                affected_contact_id, 
                new_group_name, 
                new_delete_messages_after_milliseconds, 
                type
            ) VALUES (?, ?, ?, ?, ?, ?)
            "#,
            history_id,
            self.group_id,
            self.affected_contact_id,
            self.new_group_name,
            self.new_delete_messages_after_milliseconds,
            self.r#type
        )
        .execute(&mut **tr)
        .await?;
        Ok(())
    }
}

#[derive(bon::Builder)]
pub struct GetUnjoinedGroups {}

impl GetUnjoinedGroups {
    pub async fn fetch_all(
        self,
        pool: impl sqlx::Executor<'_, Database = sqlx::Sqlite>,
    ) -> Result<Vec<String>> {
        let ids = sqlx::query_scalar!(
            "SELECT group_id FROM groups WHERE joined_group = 0 AND left_group = 0"
        )
        .fetch_all(pool)
        .await?;
        Ok(ids)
    }
}

pub struct MissingGroupPublicKeyRow {
    pub group_id: String,
    pub contact_id: i64,
}

/// Lists the members whose group public key is still unknown.
///
/// Direct chats are excluded: they never carry a group identity, so the peer
/// has no key to resend and would answer every request with an error. Left
/// groups and members who left are excluded for the same reason -- their key
/// is of no use any more.
#[derive(bon::Builder)]
pub struct GetMissingGroupPublicKeys {
    group_id: Option<String>,
}

impl GetMissingGroupPublicKeys {
    pub async fn fetch_all(
        self,
        pool: &sqlx::Pool<Sqlite>,
    ) -> Result<Vec<MissingGroupPublicKeyRow>> {
        let group_id = self.group_id.as_deref();
        let rows = sqlx::query_as!(
            MissingGroupPublicKeyRow,
            r#"
            SELECT members.group_id, members.contact_id
            FROM group_members AS members
            JOIN groups ON groups.group_id = members.group_id
            WHERE members.group_public_key IS NULL
              AND (members.member_state IS NULL OR members.member_state != 'leftGroup')
              AND groups.is_direct_chat = 0
              AND groups.left_group = 0
              AND (? IS NULL OR members.group_id = ?)
            "#,
            group_id,
            group_id,
        )
        .fetch_all(pool)
        .await?;
        Ok(rows)
    }

    pub async fn fetch_all_in_transaction(
        self,
        tr: &mut Transaction<'_, Sqlite>,
    ) -> Result<Vec<MissingGroupPublicKeyRow>> {
        let group_id = self.group_id.as_deref();
        let rows = sqlx::query_as!(
            MissingGroupPublicKeyRow,
            r#"
            SELECT members.group_id, members.contact_id
            FROM group_members AS members
            JOIN groups ON groups.group_id = members.group_id
            WHERE members.group_public_key IS NULL
              AND (members.member_state IS NULL OR members.member_state != 'leftGroup')
              AND groups.is_direct_chat = 0
              AND groups.left_group = 0
              AND (? IS NULL OR members.group_id = ?)
            "#,
            group_id,
            group_id,
        )
        .fetch_all(&mut **tr)
        .await?;
        Ok(rows)
    }
}

fn current_unix_timestamp() -> Result<i64> {
    Ok(crate::utils::current_time().timestamp())
}

/// A streak is worth offering back while it was big enough to miss and recent
/// enough to still be remembered. Pure so the boundaries stay testable without
/// a controllable clock.
fn can_restore(
    max_flame_counter: i64,
    max_flame_counter_from: Option<i64>,
    counter: i64,
    now: i64,
) -> bool {
    let seven_days_ago = now - 7 * 24 * 60 * 60;
    max_flame_counter > 2
        && counter < max_flame_counter
        && max_flame_counter_from.is_some_and(|from| from > seven_days_ago)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::database::app::AppDatabase;
    use chrono::{Local, TimeZone};

    const DAY: i64 = 24 * 60 * 60;

    /// Local midnight of the given date, which is what the derivation compares
    /// against. Mirrors the `DateTime(2026, 2, 2)` literals the Dart tests used.
    fn local_midnight(year: i32, month: u32, day: u32) -> i64 {
        Local
            .with_ymd_and_hms(year, month, day, 0, 0, 0)
            .earliest()
            .unwrap()
            .timestamp()
    }

    fn row(counter: i64, sent: i64, received: i64, changed: i64) -> FlameRow {
        FlameRow {
            group_id: "group".into(),
            flame_counter: counter,
            also_best_friend: 0,
            last_message_send: Some(sent),
            last_message_received: Some(received),
            last_flame_counter_change: Some(changed),
        }
    }

    #[test]
    fn a_streak_without_any_exchange_is_zero() {
        let empty = FlameRow {
            group_id: "group".into(),
            flame_counter: 7,
            also_best_friend: 0,
            last_message_send: None,
            last_message_received: None,
            last_flame_counter_change: None,
        };
        assert_eq!(empty.derive(local_midnight(2026, 2, 3), false).counter, 0);
    }

    /// The day-by-day walk the Dart `normal flame expiring` test performed: one
    /// exchange on Feb 2 stays visible through Feb 4 and is gone on Feb 5.
    #[test]
    fn a_streak_survives_two_days_then_expires() {
        let sent = local_midnight(2026, 2, 2) + 15 * 3600;
        let received = local_midnight(2026, 2, 2) + 10 * 3600;
        let row = row(1, sent, received, sent);

        assert_eq!(row.derive(local_midnight(2026, 2, 2), false).counter, 1);
        assert_eq!(row.derive(local_midnight(2026, 2, 3), false).counter, 1);
        assert_eq!(row.derive(local_midnight(2026, 2, 4), false).counter, 1);
        assert_eq!(row.derive(local_midnight(2026, 2, 5), false).counter, 0);
        assert_eq!(row.derive(local_midnight(2026, 3, 1), false).counter, 0);
    }

    /// The `isExpiring` half of the same Dart test: an exchange from two days
    /// back still counts, but warns that it ends at midnight.
    #[test]
    fn a_streak_warns_on_the_day_before_it_lapses() {
        let exchange = local_midnight(2026, 2, 7) + 11 * 3600;
        let row = row(3, exchange, exchange - 3600, exchange);

        let same_day = row.derive(local_midnight(2026, 2, 7), false);
        assert_eq!((same_day.counter, same_day.is_expiring), (3, false));

        let next_day = row.derive(local_midnight(2026, 2, 8), false);
        assert_eq!((next_day.counter, next_day.is_expiring), (3, false));

        let last_day = row.derive(local_midnight(2026, 2, 9), false);
        assert_eq!((last_day.counter, last_day.is_expiring), (3, true));

        let lapsed = row.derive(local_midnight(2026, 2, 10), false);
        assert_eq!((lapsed.counter, lapsed.is_expiring), (0, false));
    }

    /// The Dart `isRestore Possible` test walked March 24 to 27 against a max
    /// set on March 20; the offer stops exactly seven days after that.
    #[test]
    fn restoring_is_offered_for_seven_days() {
        let max_from = local_midnight(2026, 3, 20) + 3 * 3600;

        for days in 4..=6 {
            assert!(
                can_restore(20, Some(max_from), 0, max_from + days * DAY),
                "expected the offer {days} days after the streak was lost"
            );
        }
        assert!(!can_restore(20, Some(max_from), 0, max_from + 7 * DAY + 1));
    }

    #[test]
    fn restoring_is_not_offered_without_a_streak_worth_restoring() {
        let now = local_midnight(2026, 3, 24);
        // Too short to miss.
        assert!(!can_restore(2, Some(now - DAY), 0, now));
        // Nothing was lost.
        assert!(!can_restore(20, Some(now - DAY), 20, now));
        // Never reached a maximum.
        assert!(!can_restore(20, None, 0, now));
    }

    #[tokio::test]
    async fn restoring_brings_the_streak_back_to_its_maximum() {
        let directory = tempfile::tempdir().unwrap();
        let path = directory.path().join("app.sqlite");
        let database = AppDatabase::new(path.to_str().unwrap(), None, false)
            .await
            .unwrap();
        database.run_migrations().await.unwrap();

        let lapsed = current_time().timestamp() - 4 * DAY;
        sqlx::query(
            r#"INSERT INTO groups(group_id, group_name, flame_counter, max_flame_counter,
                                  max_flame_counter_from, last_message_send,
                                  last_message_received, last_flame_counter_change)
               VALUES ('group', 'Group', 0, 5, ?, ?, ?, ?)"#,
        )
        .bind(lapsed)
        .bind(lapsed)
        .bind(lapsed)
        .bind(lapsed)
        .execute(&database.pool)
        .await
        .unwrap();

        assert_eq!(
            Group::flame_state(&database.pool, "group")
                .await
                .unwrap()
                .counter,
            0
        );
        assert!(Group::can_restore_flames(&database.pool, "group")
            .await
            .unwrap());

        let mut transaction = database.pool.begin().await.unwrap();
        let restored = Group::restore_flames(&mut transaction, "group")
            .await
            .unwrap();
        transaction.commit().await.unwrap();
        assert_eq!(restored, Some(5));

        let state = Group::flame_state(&database.pool, "group").await.unwrap();
        assert_eq!((state.counter, state.is_expiring), (5, false));
        // Nothing is left to restore once it is back.
        assert!(!Group::can_restore_flames(&database.pool, "group")
            .await
            .unwrap());

        // The write path enforces the same rule, so a rapid second tap cannot
        // create another restoration message after the first one succeeded.
        let mut transaction = database.pool.begin().await.unwrap();
        let restored_again = Group::restore_flames(&mut transaction, "group")
            .await
            .unwrap();
        transaction.commit().await.unwrap();
        assert_eq!(restored_again, None);
    }

    /// The heart emoji needs both halves: our most-exchanged chat, and their
    /// `also_best_friend` flag saying they picked us too.
    #[tokio::test]
    async fn the_best_friend_is_the_most_exchanged_chat_and_has_to_be_mutual() {
        let directory = tempfile::tempdir().unwrap();
        let path = directory.path().join("app.sqlite");
        let database = AppDatabase::new(path.to_str().unwrap(), None, false)
            .await
            .unwrap();
        database.run_migrations().await.unwrap();

        let now = current_time().timestamp();
        for (group_id, media, mutual) in [("top", 50, 1), ("second", 10, 1), ("onesided", 5, 0)] {
            sqlx::query(
                r#"INSERT INTO groups(group_id, group_name, total_media_counter, also_best_friend,
                                      flame_counter, last_message_send, last_message_received,
                                      last_flame_counter_change)
                   VALUES (?, 'Group', ?, ?, 9, ?, ?, ?)"#,
            )
            .bind(group_id)
            .bind(media)
            .bind(mutual)
            .bind(now)
            .bind(now)
            .bind(now)
            .execute(&database.pool)
            .await
            .unwrap();
        }

        assert_eq!(
            Group::best_friend_group_id(&database.pool).await.unwrap(),
            Some("top".to_string())
        );

        let states = Group::flame_states(&database.pool, None).await.unwrap();
        assert!(states["top"].is_best_friend);
        assert!(!states["second"].is_best_friend);
        assert!(!states["onesided"].is_best_friend);

        // A requested subset still resolves the best friend across all groups.
        let subset = Group::flame_states(&database.pool, Some(vec!["top".into()]))
            .await
            .unwrap();
        assert_eq!(subset.len(), 1);
        assert!(subset["top"].is_best_friend);
    }

    #[tokio::test]
    async fn media_exchange_updates_contact_and_flame_counters_atomically() {
        let directory = tempfile::tempdir().unwrap();
        let path = directory.path().join("app.sqlite");
        let database = AppDatabase::new(path.to_str().unwrap(), None, false)
            .await
            .unwrap();
        database.run_migrations().await.unwrap();

        sqlx::query("INSERT INTO contacts(user_id, username) VALUES (7, 'alice')")
            .execute(&database.pool)
            .await
            .unwrap();
        sqlx::query("INSERT INTO groups(group_id, group_name) VALUES ('group', 'Group')")
            .execute(&database.pool)
            .await
            .unwrap();
        sqlx::query("INSERT INTO group_members(group_id, contact_id) VALUES ('group', 7)")
            .execute(&database.pool)
            .await
            .unwrap();

        let now = Local::now();
        let start_of_today = Local
            .from_local_datetime(&now.date_naive().and_hms_opt(0, 0, 0).unwrap())
            .earliest()
            .unwrap()
            .timestamp();
        let mut transaction = database.pool.begin().await.unwrap();
        Group::record_media_exchange(&mut transaction, "group", true, start_of_today + 60)
            .await
            .unwrap();
        Group::record_media_exchange(&mut transaction, "group", false, start_of_today + 120)
            .await
            .unwrap();
        transaction.commit().await.unwrap();

        let contact = sqlx::query!(
            "SELECT media_send_counter, media_received_counter FROM contacts WHERE user_id = 7"
        )
        .fetch_one(&database.pool)
        .await
        .unwrap();
        assert_eq!(contact.media_send_counter, 1);
        assert_eq!(contact.media_received_counter, 1);

        let group = sqlx::query!(
            r#"SELECT total_media_counter, flame_counter, max_flame_counter,
                      last_message_send, last_message_received,
                      last_flame_counter_change
               FROM groups WHERE group_id = 'group'"#
        )
        .fetch_one(&database.pool)
        .await
        .unwrap();
        assert_eq!(group.total_media_counter, 2);
        assert_eq!(group.flame_counter, 1);
        assert_eq!(group.max_flame_counter, 1);
        assert_eq!(group.last_message_send, Some(start_of_today + 120));
        assert_eq!(group.last_message_received, Some(start_of_today + 60));
        assert_eq!(group.last_flame_counter_change, Some(start_of_today + 120));
    }
}
