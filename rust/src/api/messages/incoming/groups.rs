/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use std::sync::Arc;

use crate::api::messages::incoming::messages::queue_encrypted_content;
use crate::api::proto::client::encrypted_content;
use crate::context::Context;
use crate::database::app::contacts::table::Contact;
use crate::database::app::groups::native::{Group, MAX_FUTURE_TIMESTAMP_SKEW_SECONDS};
use crate::error::{Result, TwonlyError};
use crate::services::groups::GroupService;
use crate::utils::{current_time, is_today, milliseconds_to_seconds, new_uuid_v4};
use rand::SeedableRng;
use sqlx::{Sqlite, Transaction};

pub(crate) async fn ensure_group_member(
    t: &mut Transaction<'_, Sqlite>, from_user_id: i64, group_id: &str,
) -> Result<()> {
    let allowed = Group::is_member(t, group_id, from_user_id).await?;

    if !allowed {
        return Err(TwonlyError::Generic(format!(
            "user {from_user_id} is not a member of group {group_id}"
        )));
    }

    Ok(())
}

pub(crate) async fn handle_group_create(
    ctx: &std::sync::Arc<crate::context::Context>, t: &mut Transaction<'_, Sqlite>,
    from_user_id: i64, group_id: &str, create: encrypted_content::GroupCreate,
) -> Result<()> {
    match store_group_invitation(t, from_user_id, group_id, create).await? {
        Invitation::Accepted => {
            GroupService::spawn_state_refresh_and_announce(ctx, group_id.to_owned());

            crate::services::webxdc::WebxdcService::spawn_sync_request(
                ctx,
                group_id.to_owned(),
                from_user_id,
            );
        }
        Invitation::Repeated => {
            // Our existing key is already announced through the reliable outbox.
            // A repair must not fan out another GroupJoin to every member, or
            // restart app sync. A peer missing our key can request it directly.
            tracing::info!(
                group_id,
                from_user_id,
                "received a repeated group invitation"
            );

            GroupService::spawn_state_refresh(ctx, Some(group_id.to_owned()));
        }
        Invitation::Ignored => {}
    }

    Ok(())
}

/// What an invitation changed.
#[derive(Debug, PartialEq)]
enum Invitation {
    /// Dropped: it came from a blocked contact, or carried a state key other
    /// than the one this group already has.
    Ignored,
    /// For a group already held with our key: nothing to announce.
    Repeated,
    /// A new membership, or our first key for this group: it needs an initial
    /// key announcement and sync.
    Accepted,
}

async fn store_group_invitation(
    t: &mut Transaction<'_, Sqlite>, from_user_id: i64, group_id: &str,
    create: encrypted_content::GroupCreate,
) -> Result<Invitation> {
    Contact::ensure_exists(t, from_user_id).await?;

    let blocked = sqlx::query_scalar!(
        "SELECT blocked FROM contacts WHERE user_id = ?",
        from_user_id
    )
    .fetch_one(&mut **t)
    .await?
        != 0;

    if blocked {
        tracing::warn!(
            group_id,
            from_user_id,
            "ignored a group invitation from a blocked contact"
        );

        return Ok(Invitation::Ignored);
    }

    let existing = sqlx::query!(
        "SELECT state_encryption_key, my_group_private_key, left_group FROM groups WHERE \
         group_id = ?",
        group_id,
    )
    .fetch_optional(&mut **t)
    .await?;

    // The state key is what makes the group server's member list authoritative:
    // whoever chose it can write any membership they like. A group keeps the key
    // it was created with, so an invitation carrying another one is not from
    // this group, and taking it would hand the group to its sender.
    let other_key = existing
        .as_ref()
        .and_then(|group| group.state_encryption_key.as_deref())
        .is_some_and(|key| key != create.state_key.as_slice());

    if other_key {
        tracing::warn!(
            group_id,
            from_user_id,
            "ignored a group invitation carrying a different state key"
        );

        return Ok(Invitation::Ignored);
    }

    // Membership repair sends GroupCreate too, potentially from several peers.
    // It must neither invent another join nor replace the key peers already
    // know (an admin's key also authorizes updates on the group server).
    let is_new_membership = existing.as_ref().is_none_or(|group| group.left_group != 0);

    let needs_key = existing
        .as_ref()
        .is_none_or(|group| group.my_group_private_key.is_none());

    let private_key = existing
        .and_then(|group| group.my_group_private_key)
        .unwrap_or_else(|| {
            let mut rng = rand::rngs::StdRng::from_os_rng();

            libsignal_protocol::IdentityKeyPair::generate(&mut rng)
                .serialize()
                .to_vec()
        });

    let group_name = create.group_name.unwrap_or_default();

    sqlx::query!(
        r#"
        INSERT INTO groups(
            group_id,
            state_encryption_key,
            my_group_private_key,
            group_name,
            joined_group
        ) VALUES (?, ?, ?, ?, 0)
        ON CONFLICT(group_id) DO UPDATE SET
            state_encryption_key = COALESCE(state_encryption_key, excluded.state_encryption_key),
            my_group_private_key = excluded.my_group_private_key,
            deleted_content = CASE WHEN left_group = 1 THEN 0 ELSE deleted_content END,
            left_group = 0
        "#,
        group_id,
        create.state_key,
        private_key,
        group_name,
    )
    .execute(&mut **t)
    .await?;

    // Membership comes only from the group server's state, which the refresh
    // after this applies. A member it already lists may update the key it signs
    // with; anyone else is added by that refresh if the state names them, and
    // asked for their key then.
    sqlx::query!(
        "UPDATE group_members SET group_public_key = ? WHERE group_id = ? AND contact_id = ?",
        create.group_public_key,
        group_id,
        from_user_id,
    )
    .execute(&mut **t)
    .await?;

    if is_new_membership {
        sqlx::query!(
            r#"INSERT INTO group_histories(group_history_id, group_id, contact_id, type)
               VALUES (?, ?, ?, 'addMember')"#,
            new_uuid_v4(),
            group_id,
            from_user_id,
        )
        .execute(&mut **t)
        .await?;
    }

    Ok(if is_new_membership || needs_key {
        Invitation::Accepted
    } else {
        Invitation::Repeated
    })
}

/// Stores the group public key a member announces.
///
/// A join never adds anyone. Members come only from the group server's state,
/// so this updates the key of a member row that already exists.
pub(crate) async fn handle_group_join(
    t: &mut Transaction<'_, Sqlite>, from_user_id: i64, group_id: &str,
    join: encrypted_content::GroupJoin,
) -> Result<bool> {
    Group::ensure_exists(t, group_id).await?;

    // A direct chat has no group keys, so a key naming one is never applied.
    let updated = sqlx::query!(
        r#"UPDATE group_members SET group_public_key = ?
           WHERE group_id = ? AND contact_id = ?
             AND group_id IN (SELECT group_id FROM groups WHERE is_direct_chat = 0)"#,
        join.group_public_key,
        group_id,
        from_user_id,
    )
    .execute(&mut **t)
    .await?
    .rows_affected();

    if updated == 0 {
        tracing::warn!(
            group_id,
            from_user_id,
            "ignored a group public key from someone who is not a member, or for a direct chat"
        );

        return Ok(true);
    }

    Ok(false)
}

pub(crate) async fn handle_resend_group_public_key(
    t: &mut Transaction<'_, Sqlite>, from_user_id: i64, group_id: &str,
) -> Result<()> {
    let private_key = sqlx::query_scalar!(
        r#"
        SELECT my_group_private_key
        FROM groups
        WHERE group_id = ?
        "#,
        group_id,
    )
    .fetch_optional(&mut **t)
    .await?
    .flatten();

    let Some(private_key) = private_key else {
        return Err(TwonlyError::Generic(format!(
            "cannot resend the group public key for {group_id} to {from_user_id}"
        )));
    };

    let identity = libsignal_protocol::IdentityKeyPair::try_from(private_key.as_slice())?;

    queue_encrypted_content(
        t,
        from_user_id,
        crate::api::proto::client::EncryptedContent {
            group_id: Some(group_id.to_owned()),
            group_join: Some(encrypted_content::GroupJoin {
                group_public_key: identity.identity_key().serialize().to_vec(),
            }),
            ..Default::default()
        },
        true,
    )
    .await?;

    Ok(())
}

pub(crate) async fn handle_group_update(
    ctx: &Arc<Context>, t: &mut Transaction<'_, Sqlite>, from_user_id: i64, group_id: &str,
    update: encrypted_content::GroupUpdate,
) -> Result<()> {
    let is_direct = Group::is_direct_chat(t, group_id).await?;

    if !is_direct {
        GroupService::spawn_state_refresh(ctx, Some(group_id.to_owned()));
    }

    if !could_have_made(t, from_user_id, group_id, is_direct, &update).await? {
        tracing::warn!(
            group_id,
            from_user_id,
            action = update.group_action_type,
            "ignored a group update its sender could not have made"
        );

        return Ok(());
    }

    if update.group_action_type == "updatedGroupName" {
        sqlx::query!(
            r#"
            UPDATE groups
            SET group_name = ?
            WHERE group_id = ?
            "#,
            update.new_group_name,
            group_id,
        )
        .execute(&mut **t)
        .await?;
    } else if update.group_action_type == "changeDisplayMaxTime" && is_direct {
        sqlx::query!(
            r#"
            UPDATE groups
            SET delete_messages_after_milliseconds = COALESCE(
                ?, delete_messages_after_milliseconds
            )
            WHERE group_id = ?
            "#,
            update.new_delete_messages_after_milliseconds,
            group_id,
        )
        .execute(&mut **t)
        .await?;
    }

    sqlx::query!(
        r#"
        INSERT INTO group_histories(
            group_history_id,
            group_id,
            contact_id,
            affected_contact_id,
            new_group_name,
            new_delete_messages_after_milliseconds,
            type
        ) VALUES (?, ?, ?, ?, ?, ?, ?)
        "#,
        new_uuid_v4(),
        group_id,
        from_user_id,
        update.affected_contact_id,
        update.new_group_name,
        update.new_delete_messages_after_milliseconds,
        update.group_action_type,
    )
    .execute(&mut **t)
    .await?;

    Ok(())
}

/// Whether `update` is an action its sender could have taken, and so may be
/// shown in the chat's history under their name.
///
/// The history shows a row as it was written, so it only takes the actions
/// `GroupService` announces. A direct chat has no group state: its timer is
/// all either side changes. In a group, changing its state takes an admin's
/// key on the group server, while leaving is open to every member.
async fn could_have_made(
    t: &mut Transaction<'_, Sqlite>, from_user_id: i64, group_id: &str, is_direct: bool,
    update: &encrypted_content::GroupUpdate,
) -> Result<bool> {
    let action = update.group_action_type.as_str();

    if is_direct {
        return Ok(action == "changeDisplayMaxTime");
    }

    match action {
        // An admin leaves by removing themselves.
        "leftGroup" => Ok(true),
        "removedMember" if update.affected_contact_id == Some(from_user_id) => Ok(true),
        "updatedGroupName" if update.new_group_name.is_none() => Ok(false),
        "updatedGroupName"
        | "changeDisplayMaxTime"
        | "addMember"
        | "removedMember"
        | "promoteToAdmin"
        | "demoteToMember" => Ok(sqlx::query_scalar!(
            r#"SELECT EXISTS(
                SELECT 1 FROM group_members
                WHERE group_id = ? AND contact_id = ? AND member_state = 'admin'
            ) AS "admin!: bool""#,
            group_id,
            from_user_id,
        )
        .fetch_one(&mut **t)
        .await?),
        _ => Ok(false),
    }
}

pub(crate) async fn handle_flame_sync(
    t: &mut Transaction<'_, Sqlite>, group_id: &str, flame: encrypted_content::FlameSync,
) -> Result<()> {
    // The peer chooses this timestamp, and a future one would keep the streak
    // alive past its real expiry once it is merged into the exchange times.
    let last_flame_counter_change = milliseconds_to_seconds(flame.last_flame_counter_change).min(
        current_time()
            .timestamp()
            .saturating_add(MAX_FUTURE_TIMESTAMP_SKEW_SECONDS),
    );

    let Some(group) = sqlx::query!(
        r#"
        SELECT last_flame_counter_change, last_message_send, last_message_received,
               flame_counter, max_flame_counter
        FROM groups
        WHERE group_id = ?
        "#,
        group_id,
    )
    .fetch_optional(&mut **t)
    .await?
    else {
        return Ok(());
    };

    let update_counters = flame.force_update
        || (group.last_flame_counter_change.is_some_and(is_today)
            && is_today(last_flame_counter_change));

    // A restore marks both directions exchanged on the sender. Apply that same
    // baseline here: copying only the count leaves it expired in flame_state,
    // and the next media exchange would reset it to zero again. Use the original
    // restore time so delayed delivery cannot grant extra days or undo newer media.
    let restored_at = flame.force_update.then_some(last_flame_counter_change);

    let last_flame_counter_change = group.last_flame_counter_change.max(restored_at);

    let last_message_send = group.last_message_send.max(restored_at);

    let last_message_received = group.last_message_received.max(restored_at);

    let flame_counter = if update_counters {
        group.flame_counter.max(flame.flame_counter)
    } else {
        group.flame_counter
    };

    let max_flame_counter = if update_counters {
        group.max_flame_counter.max(flame.flame_counter)
    } else {
        group.max_flame_counter
    };

    sqlx::query!(
        r#"
        UPDATE groups
        SET also_best_friend = ?,
            flame_counter = ?,
            max_flame_counter = ?,
            last_flame_counter_change = ?,
            last_message_send = ?,
            last_message_received = ?
        WHERE group_id = ?
        "#,
        flame.best_friend,
        flame_counter,
        max_flame_counter,
        last_flame_counter_change,
        last_message_send,
        last_message_received,
        group_id,
    )
    .execute(&mut **t)
    .await?;

    Ok(())
}

#[cfg(test)]
mod invitation_tests {

    use super::*;
    use crate::database::app::AppDatabase;

    async fn database() -> Result<(tempfile::TempDir, AppDatabase)> {
        let directory = tempfile::tempdir()?;

        let db = AppDatabase::new(
            directory.path().join("app.sqlite").to_str().unwrap(),
            None,
            false,
        )
        .await?;

        db.run_migrations().await?;

        sqlx::query("INSERT INTO contacts(user_id, username) VALUES (7, 'alice'), (8, 'bob')")
            .execute(&db.pool)
            .await?;

        Ok((directory, db))
    }

    async fn invite(db: &AppDatabase, sender: i64, public_key: Vec<u8>) -> Result<Invitation> {
        invite_with_state_key(db, sender, public_key, vec![1; 32]).await
    }

    async fn invite_with_state_key(
        db: &AppDatabase, sender: i64, public_key: Vec<u8>, state_key: Vec<u8>,
    ) -> Result<Invitation> {
        let mut t = db.pool.begin().await?;

        let invitation = store_group_invitation(
            &mut t,
            sender,
            "chat",
            encrypted_content::GroupCreate {
                state_key,
                group_public_key: public_key,
                group_name: Some("Chat".into()),
            },
        )
        .await?;

        t.commit().await?;

        Ok(invitation)
    }

    /// What the refresh after an invitation does once the group server lists
    /// these members.
    async fn refreshed_with(db: &AppDatabase, members: &[i64]) -> Result<()> {
        for member in members {
            sqlx::query("INSERT INTO group_members(group_id, contact_id) VALUES ('chat', ?)")
                .bind(member)
                .execute(&db.pool)
                .await?;
        }

        Ok(())
    }

    async fn private_key(db: &AppDatabase) -> Result<Vec<u8>> {
        Ok(
            sqlx::query_scalar("SELECT my_group_private_key FROM groups WHERE group_id = 'chat'")
                .fetch_one(&db.pool)
                .await?,
        )
    }

    #[tokio::test]

    async fn repeated_invitations_repair_members_without_repeating_history_or_rotating_keys(
    ) -> Result<()> {
        let (_directory, db) = database().await?;

        assert_eq!(invite(&db, 7, vec![7]).await?, Invitation::Accepted);

        refreshed_with(&db, &[7, 8]).await?;

        let identity = private_key(&db).await?;

        libsignal_protocol::IdentityKeyPair::try_from(identity.as_slice())?;

        sqlx::query(
            "UPDATE groups SET joined_group = 1, is_group_admin = 1,
                               state_version_id = 42, deleted_content = 1 WHERE group_id = 'chat'",
        )
        .execute(&db.pool)
        .await?;

        for _ in 0..69 {
            assert_eq!(invite(&db, 7, vec![9]).await?, Invitation::Repeated);
        }

        assert_eq!(invite(&db, 8, vec![9]).await?, Invitation::Repeated);

        assert_eq!(private_key(&db).await?, identity);

        let histories: Vec<(i64, Option<i64>)> = sqlx::query_as(
            "SELECT contact_id, affected_contact_id FROM group_histories WHERE group_id = 'chat'",
        )
        .fetch_all(&db.pool)
        .await?;

        assert_eq!(histories, vec![(7, None)]);

        let state: (i64, i64, i64, i64) = sqlx::query_as(
            "SELECT joined_group, is_group_admin, state_version_id, deleted_content
             FROM groups WHERE group_id = 'chat'",
        )
        .fetch_one(&db.pool)
        .await?;

        assert_eq!(state, (1, 1, 42, 1));

        let keys: Vec<Vec<u8>> = sqlx::query_scalar(
            "SELECT group_public_key FROM group_members WHERE group_id = 'chat'",
        )
        .fetch_all(&db.pool)
        .await?;

        assert_eq!(keys, vec![vec![9], vec![9]]);

        // Expiring the original action must not make a repair look like a join.
        sqlx::query("DELETE FROM group_histories WHERE group_id = 'chat'")
            .execute(&db.pool)
            .await?;

        assert_eq!(invite(&db, 8, vec![8]).await?, Invitation::Repeated);

        let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM group_histories")
            .fetch_one(&db.pool)
            .await?;

        assert_eq!(count, 0);

        Ok(())
    }

    #[tokio::test]

    async fn rejoining_records_one_new_action_and_restores_the_chat() -> Result<()> {
        let (_directory, db) = database().await?;

        assert_eq!(invite(&db, 7, vec![7]).await?, Invitation::Accepted);

        sqlx::query(
            "UPDATE groups SET left_group = 1, deleted_content = 1 WHERE group_id = 'chat'",
        )
        .execute(&db.pool)
        .await?;

        assert_eq!(invite(&db, 8, vec![8]).await?, Invitation::Accepted);

        assert_eq!(invite(&db, 8, vec![8]).await?, Invitation::Repeated);

        let senders: Vec<i64> = sqlx::query_scalar("SELECT contact_id FROM group_histories")
            .fetch_all(&db.pool)
            .await?;

        assert_eq!(senders, vec![7, 8]);

        let flags: (i64, i64) = sqlx::query_as(
            "SELECT left_group, deleted_content FROM groups WHERE group_id = 'chat'",
        )
        .fetch_one(&db.pool)
        .await?;

        assert_eq!(flags, (0, 0));

        Ok(())
    }

    #[tokio::test]

    async fn incomplete_group_gets_a_key_without_a_false_join_action() -> Result<()> {
        let (_directory, db) = database().await?;

        sqlx::query("INSERT INTO groups(group_id, group_name) VALUES ('chat', 'Chat')")
            .execute(&db.pool)
            .await?;

        assert_eq!(invite(&db, 7, vec![7]).await?, Invitation::Accepted);

        let identity = private_key(&db).await?;

        libsignal_protocol::IdentityKeyPair::try_from(identity.as_slice())?;

        let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM group_histories")
            .fetch_one(&db.pool)
            .await?;

        assert_eq!(count, 0);

        Ok(())
    }

    #[tokio::test]

    async fn incoming_key_announcements_do_not_generate_more_announcements() -> Result<()> {
        let (_directory, db) = database().await?;

        assert_eq!(invite(&db, 7, vec![7]).await?, Invitation::Accepted);

        refreshed_with(&db, &[7]).await?;

        let identity = private_key(&db).await?;

        let mut t = db.pool.begin().await?;

        for _ in 0..69 {
            handle_group_join(
                &mut t,
                7,
                "chat",
                encrypted_content::GroupJoin {
                    group_public_key: vec![7],
                },
            )
            .await?;
        }

        let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM receipts")
            .fetch_one(&mut *t)
            .await?;

        assert_eq!(count, 0);

        // An explicit resend request still gets a targeted response.
        handle_resend_group_public_key(&mut t, 7, "chat").await?;

        let replies: Vec<(i64, Vec<u8>)> =
            sqlx::query_as("SELECT contact_id, message FROM receipts")
                .fetch_all(&mut *t)
                .await?;

        assert_eq!(replies.len(), 1);

        assert_eq!(replies[0].0, 7);

        use prost::Message as _;

        let envelope = crate::api::proto::client::Message::decode(replies[0].1.as_slice())?;

        let content = crate::api::proto::client::EncryptedContent::decode(
            envelope.encrypted_content.unwrap().as_slice(),
        )?;

        assert_eq!(content.group_id.as_deref(), Some("chat"));

        assert_eq!(
            content.group_join.unwrap().group_public_key,
            libsignal_protocol::IdentityKeyPair::try_from(identity.as_slice())?
                .identity_key()
                .serialize()
                .to_vec(),
        );

        t.commit().await?;

        assert_eq!(private_key(&db).await?, identity);

        Ok(())
    }

    async fn join(db: &AppDatabase, sender: i64, group_id: &str, key: Vec<u8>) -> Result<bool> {
        let mut t = db.pool.begin().await?;

        let unknown = handle_group_join(
            &mut t,
            sender,
            group_id,
            encrypted_content::GroupJoin {
                group_public_key: key,
            },
        )
        .await?;

        t.commit().await?;

        Ok(unknown)
    }

    async fn members(db: &AppDatabase, group_id: &str) -> Result<Vec<(i64, Option<Vec<u8>>)>> {
        Ok(sqlx::query_as(
            "SELECT contact_id, group_public_key FROM group_members WHERE group_id = ? ORDER BY \
             contact_id",
        )
        .bind(group_id)
        .fetch_all(&db.pool)
        .await?)
    }

    #[tokio::test]

    async fn a_group_key_updates_a_member_but_never_adds_one() -> Result<()> {
        let (_directory, db) = database().await?;

        assert_eq!(invite(&db, 7, vec![7]).await?, Invitation::Accepted);

        refreshed_with(&db, &[7]).await?;

        // 8 is not in the group: nothing is stored, and the caller is told to
        // let the group server settle it.
        assert!(join(&db, 8, "chat", vec![8]).await?);

        assert_eq!(members(&db, "chat").await?, vec![(7, None)]);

        assert!(!join(&db, 7, "chat", vec![9]).await?);

        assert_eq!(members(&db, "chat").await?, vec![(7, Some(vec![9]))]);

        Ok(())
    }

    #[tokio::test]

    async fn an_invitation_adds_no_member_and_never_replaces_the_state_key() -> Result<()> {
        let (_directory, db) = database().await?;

        assert_eq!(invite(&db, 7, vec![7]).await?, Invitation::Accepted);

        // Only the refresh, from the group server's state, adds members.
        assert_eq!(members(&db, "chat").await?, vec![]);

        // Someone holding another key is not from this group, whoever they are.
        assert_eq!(
            invite_with_state_key(&db, 8, vec![8], vec![2; 32]).await?,
            Invitation::Ignored
        );

        let state_key: Vec<u8> =
            sqlx::query_scalar("SELECT state_encryption_key FROM groups WHERE group_id = 'chat'")
                .fetch_one(&db.pool)
                .await?;

        assert_eq!(state_key, vec![1; 32]);

        assert_eq!(members(&db, "chat").await?, vec![]);

        Ok(())
    }

    #[tokio::test]

    async fn an_invitation_from_a_blocked_contact_is_ignored() -> Result<()> {
        let (_directory, db) = database().await?;

        sqlx::query("UPDATE contacts SET blocked = 1 WHERE user_id = 8")
            .execute(&db.pool)
            .await?;

        assert_eq!(invite(&db, 8, vec![8]).await?, Invitation::Ignored);

        let groups: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM groups")
            .fetch_one(&db.pool)
            .await?;

        assert_eq!(groups, 0);

        Ok(())
    }

    #[tokio::test]

    async fn a_group_key_does_not_add_anyone_to_a_direct_chat() -> Result<()> {
        let (_directory, db) = database().await?;

        sqlx::query(
            "INSERT INTO groups(group_id, group_name, is_direct_chat, joined_group)
             VALUES ('direct', 'alice', 1, 1)",
        )
        .execute(&db.pool)
        .await?;

        sqlx::query("INSERT INTO group_members(group_id, contact_id) VALUES ('direct', 7)")
            .execute(&db.pool)
            .await?;

        assert!(join(&db, 8, "direct", vec![8]).await?);

        // Not even the person the chat is with: a direct chat has no group keys.
        assert!(join(&db, 7, "direct", vec![7]).await?);

        assert_eq!(members(&db, "direct").await?, vec![(7, None)]);

        Ok(())
    }
}

#[cfg(test)]
mod flame_tests {

    use super::*;
    use crate::database::app::AppDatabase;
    use crate::utils::start_of_local_day;

    const DAY: i64 = 86_400;

    #[tokio::test]

    async fn forced_sync_cannot_date_a_restore_into_the_future() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let path = directory.path().join("app.sqlite");

        let db = AppDatabase::new(path.to_str().unwrap(), None, false).await?;

        db.run_migrations().await?;

        let lapsed = start_of_local_day()? - 4 * DAY;

        sqlx::query(
            "INSERT INTO groups(group_id, group_name, flame_counter,
                                last_message_send, last_message_received, \
             last_flame_counter_change)
             VALUES ('chat', 'Chat', 0, ?, ?, ?)",
        )
        .bind(lapsed)
        .bind(lapsed)
        .bind(lapsed)
        .execute(&db.pool)
        .await?;

        let before = current_time().timestamp();

        let mut t = db.pool.begin().await?;

        handle_flame_sync(
            &mut t,
            "chat",
            encrypted_content::FlameSync {
                flame_counter: 12,
                last_flame_counter_change: (before + 30 * DAY) * 1000,
                force_update: true,
                best_friend: false,
            },
        )
        .await?;

        t.commit().await?;

        let after = current_time().timestamp();

        let dates: (i64, i64, i64) = sqlx::query_as(
            "SELECT last_message_send, last_message_received, last_flame_counter_change
             FROM groups WHERE group_id = 'chat'",
        )
        .fetch_one(&db.pool)
        .await?;

        for date in [dates.0, dates.1, dates.2] {
            assert!(date >= before + MAX_FUTURE_TIMESTAMP_SKEW_SECONDS);

            assert!(date <= after + MAX_FUTURE_TIMESTAMP_SKEW_SECONDS);
        }

        Ok(())
    }

    #[tokio::test]

    async fn forced_sync_keeps_the_original_restore_time_across_delays_and_replays() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let path = directory.path().join("app.sqlite");

        let db = AppDatabase::new(path.to_str().unwrap(), None, false).await?;

        db.run_migrations().await?;

        let now = current_time().timestamp();

        let old_restore = start_of_local_day()? - 4 * DAY;

        for (id, local_time, local_count, restored_at, expected_time, expected_count) in [
            (
                "delayed",
                Some(old_restore - DAY),
                0,
                old_restore,
                old_restore,
                0,
            ),
            ("newer", Some(now), 20, now - DAY, now, 20),
            ("empty", None, 0, now, now, 12),
        ] {
            sqlx::query(
                "INSERT INTO groups(group_id, group_name, flame_counter,
                                    last_message_send, last_message_received, \
                 last_flame_counter_change)
                 VALUES (?, 'Chat', ?, ?, ?, ?)",
            )
            .bind(id)
            .bind(local_count)
            .bind(local_time)
            .bind(local_time)
            .bind(local_time)
            .execute(&db.pool)
            .await?;

            for _ in 0..2 {
                let mut t = db.pool.begin().await?;

                handle_flame_sync(
                    &mut t,
                    id,
                    encrypted_content::FlameSync {
                        flame_counter: 12,
                        last_flame_counter_change: restored_at * 1000,
                        force_update: true,
                        best_friend: false,
                    },
                )
                .await?;

                t.commit().await?;

                let dates: (i64, i64, i64) = sqlx::query_as(
                    "SELECT last_message_send, last_message_received, last_flame_counter_change
                     FROM groups WHERE group_id = ?",
                )
                .bind(id)
                .fetch_one(&db.pool)
                .await?;

                assert_eq!(dates, (expected_time, expected_time, expected_time), "{id}");

                assert_eq!(
                    Group::flame_state(&db.pool, id).await?.counter,
                    expected_count,
                    "{id}"
                );
            }
        }

        Ok(())
    }

    #[tokio::test]

    async fn ordinary_sync_does_not_extend_a_streaks_lifetime() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let path = directory.path().join("app.sqlite");

        let db = AppDatabase::new(path.to_str().unwrap(), None, false).await?;

        db.run_migrations().await?;

        let now = current_time().timestamp();

        let last_exchange = start_of_local_day()? - 4 * DAY;

        sqlx::query(
            "INSERT INTO groups(group_id, group_name, flame_counter,
                                last_message_send, last_message_received, \
             last_flame_counter_change)
             VALUES ('chat', 'Chat', 0, ?, ?, ?)",
        )
        .bind(now)
        .bind(last_exchange)
        .bind(last_exchange)
        .execute(&db.pool)
        .await?;

        let mut t = db.pool.begin().await?;

        handle_flame_sync(
            &mut t,
            "chat",
            encrypted_content::FlameSync {
                flame_counter: 12,
                last_flame_counter_change: now * 1000,
                force_update: false,
                best_friend: true,
            },
        )
        .await?;

        t.commit().await?;

        let state = Group::flame_state(&db.pool, "chat").await?;

        assert_eq!(state.counter, 0);

        assert!(state.is_best_friend);

        let dates: (i64, i64, i64) = sqlx::query_as(
            "SELECT last_message_send, last_message_received, last_flame_counter_change
             FROM groups WHERE group_id = 'chat'",
        )
        .fetch_one(&db.pool)
        .await?;

        assert_eq!(dates, (now, last_exchange, last_exchange));

        Ok(())
    }

    #[tokio::test]

    async fn one_restore_revives_both_sides_of_a_one_sided_exchange() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let now = current_time().timestamp();

        let lapsed = start_of_local_day()? - 4 * DAY;

        // Either participant can restore, including the one who stopped sending.
        for restorer_sent_recently in [true, false] {
            let mut databases = Vec::new();

            for (side, sent_recently) in [restorer_sent_recently, !restorer_sent_recently]
                .into_iter()
                .enumerate()
            {
                let path = directory
                    .path()
                    .join(format!("{restorer_sent_recently}-{side}.sqlite"));

                let db = AppDatabase::new(path.to_str().unwrap(), None, false).await?;

                db.run_migrations().await?;

                sqlx::query(
                    "INSERT INTO groups(group_id, group_name, flame_counter, max_flame_counter,
                                        max_flame_counter_from, last_message_send,
                                        last_message_received, last_flame_counter_change)
                     VALUES ('chat', 'Chat', 0, 12, ?, ?, ?, ?)",
                )
                .bind(lapsed)
                .bind(if sent_recently { now } else { lapsed })
                .bind(if sent_recently { lapsed } else { now })
                .bind(lapsed)
                .execute(&db.pool)
                .await?;

                assert!(Group::can_restore_flames(&db.pool, "chat").await?);

                databases.push(db);
            }

            let sender = &databases[0];

            let receiver = &databases[1];

            let mut t = sender.pool.begin().await?;

            let restored = Group::restore_flames(&mut t, "chat").await?.unwrap();

            t.commit().await?;

            let changed: i64 = sqlx::query_scalar(
                "SELECT last_flame_counter_change FROM groups WHERE group_id = 'chat'",
            )
            .fetch_one(&sender.pool)
            .await?;

            let mut t = receiver.pool.begin().await?;

            handle_flame_sync(
                &mut t,
                "chat",
                encrypted_content::FlameSync {
                    flame_counter: restored,
                    last_flame_counter_change: changed * 1000,
                    force_update: true,
                    best_friend: false,
                },
            )
            .await?;

            t.commit().await?;

            for db in &databases {
                let state = Group::flame_state(&db.pool, "chat").await?;

                assert_eq!((state.counter, state.is_expiring), (12, false));

                assert!(!Group::can_restore_flames(&db.pool, "chat").await?);

                // The next real image must keep the restored streak intact.
                let mut t = db.pool.begin().await?;

                Group::record_media_exchange(&mut t, "chat", true, changed).await?;

                Group::record_media_exchange(&mut t, "chat", false, changed).await?;

                t.commit().await?;

                assert_eq!(Group::flame_state(&db.pool, "chat").await?.counter, 12);
            }
        }

        Ok(())
    }
}
