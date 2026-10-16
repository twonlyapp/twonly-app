/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use std::sync::Arc;

use crate::api::messages::incoming::messages::queue_encrypted_content;
use crate::api::proto::client::encrypted_content;
use crate::context::Context;
use crate::database::app::tables::{Contact, Group};
use crate::error::{Result, TwonlyError};
use crate::services::groups::GroupService;
use crate::utils::{is_today, milliseconds_to_seconds, new_uuid_v4};
use rand::SeedableRng;
use sqlx::{Sqlite, Transaction};

pub(crate) async fn ensure_group_member(
    t: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    group_id: &str,
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
    ctx: &std::sync::Arc<crate::context::Context>,
    t: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    group_id: &str,
    create: encrypted_content::GroupCreate,
) -> Result<()> {
    Contact::ensure_exists(t, from_user_id).await?;

    let mut rng = rand::rngs::StdRng::from_os_rng();
    let identity = libsignal_protocol::IdentityKeyPair::generate(&mut rng);
    let private_key = identity.serialize().to_vec();
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
            state_encryption_key = excluded.state_encryption_key,
            my_group_private_key = excluded.my_group_private_key,
            left_group = 0,
            deleted_content = 0
        "#,
        group_id,
        create.state_key,
        private_key,
        group_name,
    )
    .execute(&mut **t)
    .await?;

    sqlx::query!(
        r#"
        INSERT INTO group_members(group_id, contact_id, group_public_key)
        VALUES (?, ?, ?)
        ON CONFLICT(group_id, contact_id)
        DO UPDATE SET group_public_key = excluded.group_public_key
        "#,
        group_id,
        from_user_id,
        create.group_public_key,
    )
    .execute(&mut **t)
    .await?;

    sqlx::query!(
        r#"INSERT INTO group_histories(group_history_id, group_id, contact_id, type)
           VALUES (?, ?, ?, 'addMember')"#,
        new_uuid_v4(),
        group_id,
        from_user_id,
    )
    .execute(&mut **t)
    .await?;

    GroupService::spawn_state_refresh_and_announce(ctx, group_id.to_owned());
    crate::services::webxdc::WebxdcService::spawn_sync_request(
        ctx,
        group_id.to_owned(),
        from_user_id,
    );

    Ok(())
}

pub(crate) async fn handle_group_join(
    t: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    group_id: &str,
    join: encrypted_content::GroupJoin,
) -> Result<()> {
    Contact::ensure_exists(t, from_user_id).await?;
    Group::ensure_exists(t, group_id).await?;

    sqlx::query!(
        r#"
        INSERT INTO group_members(group_id, contact_id, group_public_key)
        VALUES (?, ?, ?)
        ON CONFLICT(group_id, contact_id)
        DO UPDATE SET group_public_key = excluded.group_public_key
        "#,
        group_id,
        from_user_id,
        join.group_public_key,
    )
    .execute(&mut **t)
    .await?;

    Ok(())
}

pub(crate) async fn handle_resend_group_public_key(
    t: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    group_id: &str,
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
    ctx: &Arc<Context>,
    t: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    group_id: &str,
    update: encrypted_content::GroupUpdate,
) -> Result<()> {
    let is_direct = Group::is_direct_chat(t, group_id).await?;

    if !is_direct {
        GroupService::spawn_state_refresh(ctx, Some(group_id.to_owned()));
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

pub(crate) async fn handle_flame_sync(
    t: &mut Transaction<'_, Sqlite>,
    group_id: &str,
    flame: encrypted_content::FlameSync,
) -> Result<()> {
    let last_flame_counter_change = milliseconds_to_seconds(flame.last_flame_counter_change);

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
mod flame_tests {
    use super::*;
    use crate::database::app::AppDatabase;
    use crate::utils::{current_time, start_of_local_day};

    const DAY: i64 = 86_400;

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
                                    last_message_send, last_message_received, last_flame_counter_change)
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
                                last_message_send, last_message_received, last_flame_counter_change)
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
