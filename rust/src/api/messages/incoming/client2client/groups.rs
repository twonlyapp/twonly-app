/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::proto::client::encrypted_content;
use crate::error::{Result, TwonlyError};
use crate::utils::{milliseconds_to_seconds, new_uuid_v4};
use rand::SeedableRng;
use sqlx::{Sqlite, Transaction};

pub(crate) async fn ensure_group_member(
    transaction: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    group_id: &str,
) -> Result<()> {
    let allowed = sqlx::query_scalar!(
        r#"
        SELECT EXISTS(
            SELECT 1
            FROM group_members
            WHERE group_id = ? AND contact_id = ?
        )
        "#,
        group_id,
        from_user_id,
    )
    .fetch_one(&mut **transaction)
    .await?
        != 0;
    if !allowed {
        return Err(TwonlyError::Generic(format!(
            "user {from_user_id} is not a member of group {group_id}"
        )));
    }
    Ok(())
}

pub(crate) async fn handle_group_create(
    transaction: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    group_id: &str,
    create: encrypted_content::GroupCreate,
) -> Result<()> {
    let contact_exists = sqlx::query_scalar!(
        r#"
        SELECT EXISTS(
            SELECT 1 FROM contacts WHERE user_id = ?
        )
        "#,
        from_user_id,
    )
    .fetch_one(&mut **transaction)
    .await?
        != 0;
    if !contact_exists {
        return Err(TwonlyError::Generic(
            "only known contacts may create a group".into(),
        ));
    }

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
    .execute(&mut **transaction)
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
    .execute(&mut **transaction)
    .await?;
    sqlx::query!(
        r#"INSERT INTO group_histories(group_history_id, group_id, contact_id, type)
           VALUES (?, ?, ?, 'addMember')"#,
        new_uuid_v4(),
        group_id,
        from_user_id,
    )
    .execute(&mut **transaction)
    .await?;
    if let Ok(callbacks) = crate::bridge::callbacks::get_callbacks() {
        let group_id = group_id.to_owned();
        tokio::spawn(async move {
            (callbacks.api.group_state_refresh)(group_id, true).await;
        });
    }
    Ok(())
}

pub(crate) async fn handle_group_join(
    transaction: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    group_id: &str,
    join: encrypted_content::GroupJoin,
) -> Result<()> {
    let group_exists = sqlx::query_scalar!(
        r#"SELECT EXISTS(SELECT 1 FROM groups WHERE group_id = ?)"#,
        group_id,
    )
    .fetch_one(&mut **transaction)
    .await?
        != 0;
    let contact_exists = sqlx::query_scalar!(
        r#"SELECT EXISTS(SELECT 1 FROM contacts WHERE user_id = ?)"#,
        from_user_id,
    )
    .fetch_one(&mut **transaction)
    .await?
        != 0;
    if !group_exists || !contact_exists {
        return Err(TwonlyError::Generic(
            "group join arrived before group/contact state".into(),
        ));
    }

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
    .execute(&mut **transaction)
    .await?;
    Ok(())
}

pub(crate) async fn handle_resend_group_public_key(
    transaction: &mut Transaction<'_, Sqlite>,
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
    .fetch_optional(&mut **transaction)
    .await?
    .flatten();
    let Some(private_key) = private_key else {
        return Err(TwonlyError::Generic(format!(
            "cannot resend the group public key for {group_id} to {from_user_id}"
        )));
    };
    let identity = libsignal_protocol::IdentityKeyPair::try_from(private_key.as_slice())
        .map_err(|error| TwonlyError::Signal(error.to_string()))?;
    super::messages::queue_encrypted_content(
        transaction,
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
    transaction: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    group_id: &str,
    update: encrypted_content::GroupUpdate,
) -> Result<()> {
    let is_direct = sqlx::query_scalar!(
        "SELECT is_direct_chat FROM groups WHERE group_id = ?",
        group_id
    )
    .fetch_optional(&mut **transaction)
    .await?
    .unwrap_or(0)
        != 0;
    if !is_direct {
        if let Ok(callbacks) = crate::bridge::callbacks::get_callbacks() {
            let group_id = group_id.to_owned();
            tokio::spawn(async move {
                (callbacks.api.group_state_refresh)(group_id, false).await;
            });
        }
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
        .execute(&mut **transaction)
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
        .execute(&mut **transaction)
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
    .execute(&mut **transaction)
    .await?;
    Ok(())
}

pub(crate) async fn handle_flame_sync(
    transaction: &mut Transaction<'_, Sqlite>,
    group_id: &str,
    flame: encrypted_content::FlameSync,
) -> Result<()> {
    let last_flame_counter_change = milliseconds_to_seconds(flame.last_flame_counter_change);
    sqlx::query!(
        r#"
        UPDATE groups
        SET also_best_friend = ?,
            flame_counter = CASE WHEN (
                (date(last_flame_counter_change, 'unixepoch', 'localtime') = date('now', 'localtime')
                 AND date(?, 'unixepoch', 'localtime') = date('now', 'localtime'))
                OR ?
            ) THEN MAX(flame_counter, ?) ELSE flame_counter END,
            max_flame_counter = CASE WHEN (
                (date(last_flame_counter_change, 'unixepoch', 'localtime') = date('now', 'localtime')
                 AND date(?, 'unixepoch', 'localtime') = date('now', 'localtime'))
                OR ?
            ) THEN MAX(max_flame_counter, ?) ELSE max_flame_counter END
        WHERE group_id = ? AND last_flame_counter_change IS NOT NULL
        "#,
        flame.best_friend,
        last_flame_counter_change,
        flame.force_update,
        flame.flame_counter,
        last_flame_counter_change,
        flame.force_update,
        flame.flame_counter,
        group_id,
    )
    .execute(&mut **transaction)
    .await?;
    Ok(())
}
