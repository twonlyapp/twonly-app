use super::table::{Group, GroupPatch};
use crate::error::{Result, TwonlyError};
use sqlx::{Sqlite, Transaction};

pub async fn upsert(tx: &mut Transaction<'_, Sqlite>, patch: GroupPatch) -> Result<Group> {
    if patch.group_id.is_none() {
        return Err(TwonlyError::Generic("groups.group_id is required".into()));
    }

    if patch.group_name.is_none() {
        return Err(TwonlyError::Generic("groups.group_name is required".into()));
    }

    let id = patch.group_id.clone().expect("primary key checked");

    sqlx::query!(
        r#"
            INSERT INTO groups (
                group_id,
                is_group_admin,
                is_direct_chat,
                pinned,
                archived,
                joined_group,
                left_group,
                deleted_content,
                state_version_id,
                state_encryption_key,
                my_group_private_key,
                group_name,
                draft_message,
                total_media_counter,
                also_best_friend,
                delete_messages_after_milliseconds,
                created_at,
                last_message_send,
                last_message_received,
                last_flame_counter_change,
                last_flame_sync,
                flame_counter,
                max_flame_counter,
                max_flame_counter_from,
                last_message_exchange
            ) VALUES (
                ?,
                COALESCE(?, 0),
                COALESCE(?, 0),
                COALESCE(?, 0),
                COALESCE(?, 0),
                COALESCE(?, 0),
                COALESCE(?, 0),
                COALESCE(?, 0),
                COALESCE(?, 0),
                ?,
                ?,
                ?,
                ?,
                COALESCE(?, 0),
                COALESCE(?, 0),
                COALESCE(?, 86400000),
                COALESCE(?, CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
                ?,
                ?,
                ?,
                ?,
                COALESCE(?, 0),
                COALESCE(?, 0),
                ?,
                COALESCE(?, CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
            )
            ON CONFLICT(group_id) DO UPDATE SET
                is_group_admin = CASE WHEN ? THEN excluded.is_group_admin ELSE groups.is_group_admin END,
                is_direct_chat = CASE WHEN ? THEN excluded.is_direct_chat ELSE groups.is_direct_chat END,
                pinned = CASE WHEN ? THEN excluded.pinned ELSE groups.pinned END,
                archived = CASE WHEN ? THEN excluded.archived ELSE groups.archived END,
                joined_group = CASE WHEN ? THEN excluded.joined_group ELSE groups.joined_group END,
                left_group = CASE WHEN ? THEN excluded.left_group ELSE groups.left_group END,
                deleted_content = CASE WHEN ? THEN excluded.deleted_content ELSE groups.deleted_content END,
                state_version_id = CASE WHEN ? THEN excluded.state_version_id ELSE groups.state_version_id END,
                state_encryption_key = CASE WHEN ? THEN excluded.state_encryption_key
                    ELSE groups.state_encryption_key END,
                my_group_private_key = CASE WHEN ? THEN excluded.my_group_private_key
                    ELSE groups.my_group_private_key END,
                group_name = CASE WHEN ? THEN excluded.group_name ELSE groups.group_name END,
                draft_message = CASE WHEN ? THEN excluded.draft_message ELSE groups.draft_message END,
                total_media_counter = CASE WHEN ? THEN excluded.total_media_counter ELSE groups.total_media_counter
                    END,
                also_best_friend = CASE WHEN ? THEN excluded.also_best_friend ELSE groups.also_best_friend END,
                delete_messages_after_milliseconds = CASE WHEN ? THEN excluded.delete_messages_after_milliseconds
                    ELSE groups.delete_messages_after_milliseconds END,
                created_at = CASE WHEN ? THEN excluded.created_at ELSE groups.created_at END,
                last_message_send = CASE WHEN ? THEN excluded.last_message_send ELSE groups.last_message_send END,
                last_message_received = CASE WHEN ? THEN excluded.last_message_received
                    ELSE groups.last_message_received END,
                last_flame_counter_change = CASE WHEN ? THEN excluded.last_flame_counter_change
                    ELSE groups.last_flame_counter_change END,
                last_flame_sync = CASE WHEN ? THEN excluded.last_flame_sync ELSE groups.last_flame_sync END,
                flame_counter = CASE WHEN ? THEN excluded.flame_counter ELSE groups.flame_counter END,
                max_flame_counter = CASE WHEN ? THEN excluded.max_flame_counter ELSE groups.max_flame_counter END,
                max_flame_counter_from = CASE WHEN ? THEN excluded.max_flame_counter_from
                    ELSE groups.max_flame_counter_from END,
                last_message_exchange = CASE WHEN ? THEN excluded.last_message_exchange
                    ELSE groups.last_message_exchange END
        "#,
        patch.group_id.as_deref(),
        patch.is_group_admin,
        patch.is_direct_chat,
        patch.pinned,
        patch.archived,
        patch.joined_group,
        patch.left_group,
        patch.deleted_content,
        patch.state_version_id,
        patch.state_encryption_key.as_ref().and_then(|value| value.value.as_deref()),
        patch.my_group_private_key.as_ref().and_then(|value| value.value.as_deref()),
        patch.group_name.as_deref(),
        patch.draft_message.as_ref().and_then(|value| value.value.as_deref()),
        patch.total_media_counter,
        patch.also_best_friend,
        patch.delete_messages_after_milliseconds,
        patch.created_at,
        patch.last_message_send.as_ref().and_then(|value| value.value),
        patch.last_message_received.as_ref().and_then(|value| value.value),
        patch.last_flame_counter_change.as_ref().and_then(|value| value.value),
        patch.last_flame_sync.as_ref().and_then(|value| value.value),
        patch.flame_counter,
        patch.max_flame_counter,
        patch.max_flame_counter_from.as_ref().and_then(|value| value.value),
        patch.last_message_exchange,
        patch.is_group_admin.is_some(),
        patch.is_direct_chat.is_some(),
        patch.pinned.is_some(),
        patch.archived.is_some(),
        patch.joined_group.is_some(),
        patch.left_group.is_some(),
        patch.deleted_content.is_some(),
        patch.state_version_id.is_some(),
        patch.state_encryption_key.is_some(),
        patch.my_group_private_key.is_some(),
        patch.group_name.is_some(),
        patch.draft_message.is_some(),
        patch.total_media_counter.is_some(),
        patch.also_best_friend.is_some(),
        patch.delete_messages_after_milliseconds.is_some(),
        patch.created_at.is_some(),
        patch.last_message_send.is_some(),
        patch.last_message_received.is_some(),
        patch.last_flame_counter_change.is_some(),
        patch.last_flame_sync.is_some(),
        patch.flame_counter.is_some(),
        patch.max_flame_counter.is_some(),
        patch.max_flame_counter_from.is_some(),
        patch.last_message_exchange.is_some(),
    ).execute(&mut **tx).await?;

    Ok(super::queries::get(tx, &id).await?.expect("row exists"))
}

pub async fn update(
    tx: &mut Transaction<'_, Sqlite>, id: Option<&str>, patch: GroupPatch,
) -> Result<()> {
    if !(patch.group_id.is_some()
        || patch.is_group_admin.is_some()
        || patch.is_direct_chat.is_some()
        || patch.pinned.is_some()
        || patch.archived.is_some()
        || patch.joined_group.is_some()
        || patch.left_group.is_some()
        || patch.deleted_content.is_some()
        || patch.state_version_id.is_some()
        || patch.state_encryption_key.is_some()
        || patch.my_group_private_key.is_some()
        || patch.group_name.is_some()
        || patch.draft_message.is_some()
        || patch.total_media_counter.is_some()
        || patch.also_best_friend.is_some()
        || patch.delete_messages_after_milliseconds.is_some()
        || patch.created_at.is_some()
        || patch.last_message_send.is_some()
        || patch.last_message_received.is_some()
        || patch.last_flame_counter_change.is_some()
        || patch.last_flame_sync.is_some()
        || patch.flame_counter.is_some()
        || patch.max_flame_counter.is_some()
        || patch.max_flame_counter_from.is_some()
        || patch.last_message_exchange.is_some())
    {
        return Ok(());
    }

    macro_rules! update {
        ($predicate:literal $(, $target:expr)* $(,)?) => {
            sqlx::query!(
                r#"
                    UPDATE groups
                    SET group_id = CASE WHEN ? THEN ? ELSE group_id END,
                        is_group_admin = CASE WHEN ? THEN ? ELSE is_group_admin END,
                        is_direct_chat = CASE WHEN ? THEN ? ELSE is_direct_chat END,
                        pinned = CASE WHEN ? THEN ? ELSE pinned END,
                        archived = CASE WHEN ? THEN ? ELSE archived END,
                        joined_group = CASE WHEN ? THEN ? ELSE joined_group END,
                        left_group = CASE WHEN ? THEN ? ELSE left_group END,
                        deleted_content = CASE WHEN ? THEN ? ELSE deleted_content END,
                        state_version_id = CASE WHEN ? THEN ? ELSE state_version_id END,
                        state_encryption_key = CASE WHEN ? THEN ? ELSE state_encryption_key END,
                        my_group_private_key = CASE WHEN ? THEN ? ELSE my_group_private_key END,
                        group_name = CASE WHEN ? THEN ? ELSE group_name END,
                        draft_message = CASE WHEN ? THEN ? ELSE draft_message END,
                        total_media_counter = CASE WHEN ? THEN ? ELSE total_media_counter END,
                        also_best_friend = CASE WHEN ? THEN ? ELSE also_best_friend END,
                        delete_messages_after_milliseconds = CASE WHEN ? THEN ? ELSE delete_messages_after_milliseconds END,
                        created_at = CASE WHEN ? THEN ? ELSE created_at END,
                        last_message_send = CASE WHEN ? THEN ? ELSE last_message_send END,
                        last_message_received = CASE WHEN ? THEN ? ELSE last_message_received END,
                        last_flame_counter_change = CASE WHEN ? THEN ? ELSE last_flame_counter_change END,
                        last_flame_sync = CASE WHEN ? THEN ? ELSE last_flame_sync END,
                        flame_counter = CASE WHEN ? THEN ? ELSE flame_counter END,
                        max_flame_counter = CASE WHEN ? THEN ? ELSE max_flame_counter END,
                        max_flame_counter_from = CASE WHEN ? THEN ? ELSE max_flame_counter_from END,
                        last_message_exchange = CASE WHEN ? THEN ? ELSE last_message_exchange END
                "# + $predicate,
                patch.group_id.is_some(),
                patch.group_id.as_deref(),
                patch.is_group_admin.is_some(),
                patch.is_group_admin,
                patch.is_direct_chat.is_some(),
                patch.is_direct_chat,
                patch.pinned.is_some(),
                patch.pinned,
                patch.archived.is_some(),
                patch.archived,
                patch.joined_group.is_some(),
                patch.joined_group,
                patch.left_group.is_some(),
                patch.left_group,
                patch.deleted_content.is_some(),
                patch.deleted_content,
                patch.state_version_id.is_some(),
                patch.state_version_id,
                patch.state_encryption_key.is_some(),
                patch.state_encryption_key.as_ref().and_then(|value| value.value.as_deref()),
                patch.my_group_private_key.is_some(),
                patch.my_group_private_key.as_ref().and_then(|value| value.value.as_deref()),
                patch.group_name.is_some(),
                patch.group_name.as_deref(),
                patch.draft_message.is_some(),
                patch.draft_message.as_ref().and_then(|value| value.value.as_deref()),
                patch.total_media_counter.is_some(),
                patch.total_media_counter,
                patch.also_best_friend.is_some(),
                patch.also_best_friend,
                patch.delete_messages_after_milliseconds.is_some(),
                patch.delete_messages_after_milliseconds,
                patch.created_at.is_some(),
                patch.created_at,
                patch.last_message_send.is_some(),
                patch.last_message_send.as_ref().and_then(|value| value.value),
                patch.last_message_received.is_some(),
                patch.last_message_received.as_ref().and_then(|value| value.value),
                patch.last_flame_counter_change.is_some(),
                patch.last_flame_counter_change.as_ref().and_then(|value| value.value),
                patch.last_flame_sync.is_some(),
                patch.last_flame_sync.as_ref().and_then(|value| value.value),
                patch.flame_counter.is_some(),
                patch.flame_counter,
                patch.max_flame_counter.is_some(),
                patch.max_flame_counter,
                patch.max_flame_counter_from.is_some(),
                patch.max_flame_counter_from.as_ref().and_then(|value| value.value),
                patch.last_message_exchange.is_some(),
                patch.last_message_exchange,
                $($target),*
            ).execute(&mut **tx).await?
        };
    }

    if let Some(id) = id {
        update!(" WHERE group_id = ?", id);
    } else {
        update!("");
    }

    Ok(())
}

pub async fn upsert_member(
    tx: &mut Transaction<'_, Sqlite>, patch: super::table::GroupMemberPatch,
) -> Result<()> {
    sqlx::query!(
        r#"
            INSERT INTO group_members (
                group_id,
                contact_id,
                member_state,
                group_public_key,
                last_chat_opened,
                last_type_indicator,
                last_message,
                created_at
            ) VALUES (
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                COALESCE(?, CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
            )
            ON CONFLICT(group_id, contact_id) DO UPDATE SET
                member_state = CASE WHEN ? THEN excluded.member_state ELSE group_members.member_state END,
                group_public_key = CASE WHEN ? THEN excluded.group_public_key ELSE group_members.group_public_key
                    END,
                last_chat_opened = CASE WHEN ? THEN excluded.last_chat_opened ELSE group_members.last_chat_opened
                    END,
                last_type_indicator = CASE WHEN ? THEN excluded.last_type_indicator
                    ELSE group_members.last_type_indicator END,
                last_message = CASE WHEN ? THEN excluded.last_message ELSE group_members.last_message END,
                created_at = CASE WHEN ? THEN excluded.created_at ELSE group_members.created_at END
            WHERE ? OR ? OR ? OR ? OR ? OR ?
        "#,
        patch.group_id.as_deref(),
        patch.contact_id,
        patch.member_state.as_ref().and_then(|value| value.value.as_deref()),
        patch.group_public_key.as_ref().and_then(|value| value.value.as_deref()),
        patch.last_chat_opened.as_ref().and_then(|value| value.value),
        patch.last_type_indicator.as_ref().and_then(|value| value.value),
        patch.last_message.as_ref().and_then(|value| value.value),
        patch.created_at,
        patch.member_state.is_some(),
        patch.group_public_key.is_some(),
        patch.last_chat_opened.is_some(),
        patch.last_type_indicator.is_some(),
        patch.last_message.is_some(),
        patch.created_at.is_some(),
        patch.member_state.is_some(),
        patch.group_public_key.is_some(),
        patch.last_chat_opened.is_some(),
        patch.last_type_indicator.is_some(),
        patch.last_message.is_some(),
        patch.created_at.is_some(),
    ).execute(&mut **tx).await?;

    Ok(())
}

pub async fn insert_history(
    tx: &mut Transaction<'_, Sqlite>, mut patch: super::table::GroupHistoryPatch,
) -> Result<()> {
    if patch.group_history_id.is_none() {
        patch.group_history_id = Some(uuid::Uuid::new_v4().to_string());
    }

    sqlx::query!(
        r#"
            INSERT INTO group_histories (
                group_history_id,
                group_id,
                contact_id,
                affected_contact_id,
                old_group_name,
                new_group_name,
                new_delete_messages_after_milliseconds,
                type,
                action_at
            ) VALUES (
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                COALESCE(?, CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
            )
        "#,
        patch.group_history_id.as_deref(),
        patch.group_id.as_deref(),
        patch.contact_id.as_ref().and_then(|value| value.value),
        patch
            .affected_contact_id
            .as_ref()
            .and_then(|value| value.value),
        patch
            .old_group_name
            .as_ref()
            .and_then(|value| value.value.as_deref()),
        patch
            .new_group_name
            .as_ref()
            .and_then(|value| value.value.as_deref()),
        patch
            .new_delete_messages_after_milliseconds
            .as_ref()
            .and_then(|value| value.value),
        patch.r#type.as_deref(),
        patch.action_at,
    )
    .execute(&mut **tx)
    .await?;

    Ok(())
}

pub async fn delete(tx: &mut Transaction<'_, Sqlite>, id: &str) -> Result<()> {
    sqlx::query!(
        r#"
            DELETE FROM groups WHERE group_id = ?
        "#,
        id,
    )
    .execute(&mut **tx)
    .await?;

    Ok(())
}

pub async fn direct_chat(
    tx: &mut Transaction<'_, Sqlite>, contact: i64, own_id: i64, mut patch: GroupPatch,
) -> Result<Group> {
    if contact < 0 || own_id < 0 {
        return Err(TwonlyError::Generic(
            "contact IDs must be non-negative".into(),
        ));
    }

    patch.group_id = Some(super::native::Group::direct_chat_id(contact, own_id));

    patch.is_direct_chat = Some(true);

    patch.is_group_admin = Some(true);

    patch.joined_group = Some(true);

    let row = upsert(tx, patch).await?;

    upsert_member(
        tx,
        super::table::GroupMemberPatch {
            group_id: Some(row.group_id.clone()),
            contact_id: Some(contact),
            ..Default::default()
        },
    )
    .await?;

    Ok(row)
}

pub async fn increase_exchange(
    tx: &mut Transaction<'_, Sqlite>, group: &str, contact: Option<i64>, timestamp: i64, now: i64,
) -> Result<()> {
    let timestamp = timestamp.min(now);

    if let Some(contact) = contact {
        sqlx::query!(
            r#"
                UPDATE group_members
                SET last_message = ?
                WHERE group_id = ?
                    AND contact_id = ?
                    AND (last_message IS NULL
                        OR last_message < ?
                )
            "#,
            timestamp,
            group,
            contact,
            timestamp,
        )
        .execute(&mut **tx)
        .await?;
    } else {
        sqlx::query!(
            r#"
                UPDATE groups
                SET last_message_exchange = ?
                WHERE group_id = ?
                    AND last_message_exchange < ?
            "#,
            timestamp,
            group,
            timestamp,
        )
        .execute(&mut **tx)
        .await?;
    }

    Ok(())
}
