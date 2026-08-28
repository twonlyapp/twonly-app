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

    GroupService::new(ctx)
        .refresh_group_state(t, group_id.to_owned(), true)
        .await;

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
        GroupService::new(ctx)
            .refresh_group_state(t, group_id.to_owned(), false)
            .await;
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
        SELECT last_flame_counter_change, flame_counter, max_flame_counter
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

    let Some(group_last_flame_counter_change) = group.last_flame_counter_change else {
        return Ok(());
    };

    let update_counters = flame.force_update
        || (is_today(group_last_flame_counter_change) & is_today(last_flame_counter_change));

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
            max_flame_counter = ?
        WHERE group_id = ?
        "#,
        flame.best_friend,
        flame_counter,
        max_flame_counter,
        group_id,
    )
    .execute(&mut **t)
    .await?;

    Ok(())
}
