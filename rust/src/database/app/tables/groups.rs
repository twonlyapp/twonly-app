/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use chrono::{Local, TimeZone};
use sqlx::{Sqlite, Transaction};

use crate::context::Context;
use crate::error::{Result, TwonlyError};

use super::Contact;

const MAX_FUTURE_TIMESTAMP_SKEW_SECONDS: i64 = 10 * 60;

pub struct Group;

impl Group {
    pub async fn flame_sync_candidates(pool: &sqlx::Pool<Sqlite>) -> Result<Vec<FlameSyncGroup>> {
        Ok(sqlx::query_as!(
            FlameSyncGroup,
            r#"SELECT group_id, total_media_counter, last_flame_counter_change,
                      last_flame_sync, flame_counter
               FROM groups WHERE last_flame_counter_change IS NOT NULL"#
        )
        .fetch_all(pool)
        .await?)
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

        let now = Local::now();
        let start_of_today = Local
            .from_local_datetime(
                &now.date_naive()
                    .and_hms_opt(0, 0, 0)
                    .ok_or_else(|| TwonlyError::Generic("invalid local date".into()))?,
            )
            .earliest()
            .ok_or_else(|| TwonlyError::Generic("local day has no midnight".into()))?
            .timestamp();
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
            SET last_message_exchange = MAX(last_message_exchange, ?)
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
    pub flame_counter: i64,
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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::database::app::AppDatabase;

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
