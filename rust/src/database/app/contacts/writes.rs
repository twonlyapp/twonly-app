use super::table::ContactPatch;
use crate::error::{Result, TwonlyError};
use sqlx::{Sqlite, Transaction};

pub async fn upsert(tx: &mut Transaction<'_, Sqlite>, patch: ContactPatch) -> Result<i64> {
    let id = patch
        .user_id
        .ok_or_else(|| TwonlyError::Generic("contact user_id is required".into()))?;

    if patch.username.is_none() {
        return Err(TwonlyError::Generic("contact username is required".into()));
    }

    sqlx::query!(
        r#"
            INSERT INTO contacts (
                user_id,
                username,
                display_name,
                nick_name,
                avatar_svg_compressed,
                prefer_photo_avatar,
                sender_profile_counter,
                accepted,
                deleted_by_user,
                requested,
                blocked,
                verified,
                account_deleted,
                created_at,
                signal_version,
                user_discovery_version,
                user_discovery_excluded,
                user_discovery_manual_approved,
                recovery_is_trusted_friend,
                recovery_last_heartbeat,
                recovery_secret_share,
                recovery_contacts_secret_share,
                recovery_contacts_last_heartbeat,
                recovery_contacts_threshold,
                ask_for_friend_promotions,
                widget_sharing_allowed,
                widget_sharing_granted,
                twonly_score,
                joined_at,
                media_send_counter,
                media_received_counter
            ) VALUES (
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                COALESCE(?, 0),
                COALESCE(?, 0),
                COALESCE(?, 0),
                COALESCE(?, 0),
                COALESCE(?, 0),
                COALESCE(?, 0),
                COALESCE(?, 0),
                COALESCE(?, CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
                COALESCE(?, 'v1'),
                ?,
                COALESCE(?, 0),
                CASE WHEN ? THEN ? ELSE 0 END,
                COALESCE(?, 0),
                ?,
                ?,
                ?,
                ?,
                ?,
                ?,
                COALESCE(?, 0),
                COALESCE(?, 0),
                ?,
                ?,
                COALESCE(?, 0),
                COALESCE(?, 0)
            )
            ON CONFLICT(user_id) DO UPDATE SET
                username = CASE WHEN ? THEN excluded.username ELSE contacts.username END,
                display_name = CASE WHEN ? THEN excluded.display_name ELSE contacts.display_name END,
                nick_name = CASE WHEN ? THEN excluded.nick_name ELSE contacts.nick_name END,
                avatar_svg_compressed = CASE WHEN ? THEN excluded.avatar_svg_compressed
                    ELSE contacts.avatar_svg_compressed END,
                prefer_photo_avatar = CASE WHEN ? THEN excluded.prefer_photo_avatar
                    ELSE contacts.prefer_photo_avatar END,
                sender_profile_counter = CASE WHEN ? THEN excluded.sender_profile_counter
                    ELSE contacts.sender_profile_counter END,
                accepted = CASE WHEN ? THEN excluded.accepted ELSE contacts.accepted END,
                deleted_by_user = CASE WHEN ? THEN excluded.deleted_by_user ELSE contacts.deleted_by_user END,
                requested = CASE WHEN ? THEN excluded.requested ELSE contacts.requested END,
                blocked = CASE WHEN ? THEN excluded.blocked ELSE contacts.blocked END,
                verified = CASE WHEN ? THEN excluded.verified ELSE contacts.verified END,
                account_deleted = CASE WHEN ? THEN excluded.account_deleted ELSE contacts.account_deleted END,
                created_at = CASE WHEN ? THEN excluded.created_at ELSE contacts.created_at END,
                signal_version = CASE WHEN ? THEN excluded.signal_version ELSE contacts.signal_version END,
                user_discovery_version = CASE WHEN ? THEN excluded.user_discovery_version
                    ELSE contacts.user_discovery_version END,
                user_discovery_excluded = CASE WHEN ? THEN excluded.user_discovery_excluded
                    ELSE contacts.user_discovery_excluded END,
                user_discovery_manual_approved = CASE WHEN ? THEN excluded.user_discovery_manual_approved
                    ELSE contacts.user_discovery_manual_approved END,
                recovery_is_trusted_friend = CASE WHEN ? THEN excluded.recovery_is_trusted_friend
                    ELSE contacts.recovery_is_trusted_friend END,
                recovery_last_heartbeat = CASE WHEN ? THEN excluded.recovery_last_heartbeat
                    ELSE contacts.recovery_last_heartbeat END,
                recovery_secret_share = CASE WHEN ? THEN excluded.recovery_secret_share
                    ELSE contacts.recovery_secret_share END,
                recovery_contacts_secret_share = CASE WHEN ? THEN excluded.recovery_contacts_secret_share
                    ELSE contacts.recovery_contacts_secret_share END,
                recovery_contacts_last_heartbeat = CASE WHEN ? THEN excluded.recovery_contacts_last_heartbeat
                    ELSE contacts.recovery_contacts_last_heartbeat END,
                recovery_contacts_threshold = CASE WHEN ? THEN excluded.recovery_contacts_threshold
                    ELSE contacts.recovery_contacts_threshold END,
                ask_for_friend_promotions = CASE WHEN ? THEN excluded.ask_for_friend_promotions
                    ELSE contacts.ask_for_friend_promotions END,
                widget_sharing_allowed = CASE WHEN ? THEN excluded.widget_sharing_allowed
                    ELSE contacts.widget_sharing_allowed END,
                widget_sharing_granted = CASE WHEN ? THEN excluded.widget_sharing_granted
                    ELSE contacts.widget_sharing_granted END,
                twonly_score = CASE WHEN ? THEN excluded.twonly_score ELSE contacts.twonly_score END,
                joined_at = CASE WHEN ? THEN excluded.joined_at ELSE contacts.joined_at END,
                media_send_counter = CASE WHEN ? THEN excluded.media_send_counter ELSE contacts.media_send_counter
                    END,
                media_received_counter = CASE WHEN ? THEN excluded.media_received_counter
                    ELSE contacts.media_received_counter END
        "#,
        patch.user_id,
        patch.username.as_deref(),
        patch.display_name.as_ref().and_then(|value| value.value.as_deref()),
        patch.nick_name.as_ref().and_then(|value| value.value.as_deref()),
        patch.avatar_svg_compressed.as_ref().and_then(|value| value.value.as_deref()),
        patch.prefer_photo_avatar.as_ref().and_then(|value| value.value),
        patch.sender_profile_counter,
        patch.accepted,
        patch.deleted_by_user,
        patch.requested,
        patch.blocked,
        patch.verified,
        patch.account_deleted,
        patch.created_at,
        patch.signal_version.as_deref(),
        patch.user_discovery_version.as_ref().and_then(|value| value.value.as_deref()),
        patch.user_discovery_excluded,
        patch.user_discovery_manual_approved.is_some(),
        patch.user_discovery_manual_approved.as_ref().and_then(|value| value.value),
        patch.recovery_is_trusted_friend,
        patch.recovery_last_heartbeat.as_ref().and_then(|value| value.value),
        patch.recovery_secret_share.as_ref().and_then(|value| value.value.as_deref()),
        patch.recovery_contacts_secret_share.as_ref().and_then(|value| value.value.as_deref()),
        patch.recovery_contacts_last_heartbeat.as_ref().and_then(|value| value.value),
        patch.recovery_contacts_threshold.as_ref().and_then(|value| value.value),
        patch.ask_for_friend_promotions.as_ref().and_then(|value| value.value),
        patch.widget_sharing_allowed,
        patch.widget_sharing_granted,
        patch.twonly_score.as_ref().and_then(|value| value.value),
        patch.joined_at.as_ref().and_then(|value| value.value),
        patch.media_send_counter,
        patch.media_received_counter,
        patch.username.is_some(),
        patch.display_name.is_some(),
        patch.nick_name.is_some(),
        patch.avatar_svg_compressed.is_some(),
        patch.prefer_photo_avatar.is_some(),
        patch.sender_profile_counter.is_some(),
        patch.accepted.is_some(),
        patch.deleted_by_user.is_some(),
        patch.requested.is_some(),
        patch.blocked.is_some(),
        patch.verified.is_some(),
        patch.account_deleted.is_some(),
        patch.created_at.is_some(),
        patch.signal_version.is_some(),
        patch.user_discovery_version.is_some(),
        patch.user_discovery_excluded.is_some(),
        patch.user_discovery_manual_approved.is_some(),
        patch.recovery_is_trusted_friend.is_some(),
        patch.recovery_last_heartbeat.is_some(),
        patch.recovery_secret_share.is_some(),
        patch.recovery_contacts_secret_share.is_some(),
        patch.recovery_contacts_last_heartbeat.is_some(),
        patch.recovery_contacts_threshold.is_some(),
        patch.ask_for_friend_promotions.is_some(),
        patch.widget_sharing_allowed.is_some(),
        patch.widget_sharing_granted.is_some(),
        patch.twonly_score.is_some(),
        patch.joined_at.is_some(),
        patch.media_send_counter.is_some(),
        patch.media_received_counter.is_some(),
    ).execute(&mut **tx).await?;

    Ok(id)
}

pub async fn update(tx: &mut Transaction<'_, Sqlite>, id: i64, patch: ContactPatch) -> Result<()> {
    let refresh_name = patch.blocked.is_some()
        || patch.display_name.is_some()
        || patch.nick_name.is_some()
        || patch.username.is_some();

    if !(patch.user_id.is_some()
        || patch.username.is_some()
        || patch.display_name.is_some()
        || patch.nick_name.is_some()
        || patch.avatar_svg_compressed.is_some()
        || patch.prefer_photo_avatar.is_some()
        || patch.sender_profile_counter.is_some()
        || patch.accepted.is_some()
        || patch.deleted_by_user.is_some()
        || patch.requested.is_some()
        || patch.blocked.is_some()
        || patch.verified.is_some()
        || patch.account_deleted.is_some()
        || patch.created_at.is_some()
        || patch.signal_version.is_some()
        || patch.user_discovery_version.is_some()
        || patch.user_discovery_excluded.is_some()
        || patch.user_discovery_manual_approved.is_some()
        || patch.recovery_is_trusted_friend.is_some()
        || patch.recovery_last_heartbeat.is_some()
        || patch.recovery_secret_share.is_some()
        || patch.recovery_contacts_secret_share.is_some()
        || patch.recovery_contacts_last_heartbeat.is_some()
        || patch.recovery_contacts_threshold.is_some()
        || patch.ask_for_friend_promotions.is_some()
        || patch.widget_sharing_allowed.is_some()
        || patch.widget_sharing_granted.is_some()
        || patch.twonly_score.is_some()
        || patch.joined_at.is_some()
        || patch.media_send_counter.is_some()
        || patch.media_received_counter.is_some())
    {
        return Ok(());
    }

    sqlx::query!(
        r#"
            UPDATE contacts
            SET user_id = CASE WHEN ? THEN ? ELSE user_id END,
                username = CASE WHEN ? THEN ? ELSE username END,
                display_name = CASE WHEN ? THEN ? ELSE display_name END,
                nick_name = CASE WHEN ? THEN ? ELSE nick_name END,
                avatar_svg_compressed = CASE WHEN ? THEN ? ELSE avatar_svg_compressed END,
                prefer_photo_avatar = CASE WHEN ? THEN ? ELSE prefer_photo_avatar END,
                sender_profile_counter = CASE WHEN ? THEN ? ELSE sender_profile_counter END,
                accepted = CASE WHEN ? THEN ? ELSE accepted END,
                deleted_by_user = CASE WHEN ? THEN ? ELSE deleted_by_user END,
                requested = CASE WHEN ? THEN ? ELSE requested END,
                blocked = CASE WHEN ? THEN ? ELSE blocked END,
                verified = CASE WHEN ? THEN ? ELSE verified END,
                account_deleted = CASE WHEN ? THEN ? ELSE account_deleted END,
                created_at = CASE WHEN ? THEN ? ELSE created_at END,
                signal_version = CASE WHEN ? THEN ? ELSE signal_version END,
                user_discovery_version = CASE WHEN ? THEN ? ELSE user_discovery_version END,
                user_discovery_excluded = CASE WHEN ? THEN ? ELSE user_discovery_excluded END,
                user_discovery_manual_approved = CASE WHEN ? THEN ? ELSE user_discovery_manual_approved END,
                recovery_is_trusted_friend = CASE WHEN ? THEN ? ELSE recovery_is_trusted_friend END,
                recovery_last_heartbeat = CASE WHEN ? THEN ? ELSE recovery_last_heartbeat END,
                recovery_secret_share = CASE WHEN ? THEN ? ELSE recovery_secret_share END,
                recovery_contacts_secret_share = CASE WHEN ? THEN ? ELSE recovery_contacts_secret_share END,
                recovery_contacts_last_heartbeat = CASE WHEN ? THEN ? ELSE recovery_contacts_last_heartbeat END,
                recovery_contacts_threshold = CASE WHEN ? THEN ? ELSE recovery_contacts_threshold END,
                ask_for_friend_promotions = CASE WHEN ? THEN ? ELSE ask_for_friend_promotions END,
                widget_sharing_allowed = CASE WHEN ? THEN ? ELSE widget_sharing_allowed END,
                widget_sharing_granted = CASE WHEN ? THEN ? ELSE widget_sharing_granted END,
                twonly_score = CASE WHEN ? THEN ? ELSE twonly_score END,
                joined_at = CASE WHEN ? THEN ? ELSE joined_at END,
                media_send_counter = CASE WHEN ? THEN ? ELSE media_send_counter END,
                media_received_counter = CASE WHEN ? THEN ? ELSE media_received_counter END
            WHERE user_id = ?
        "#,
        patch.user_id.is_some(),
        patch.user_id,
        patch.username.is_some(),
        patch.username.as_deref(),
        patch.display_name.is_some(),
        patch.display_name.as_ref().and_then(|value| value.value.as_deref()),
        patch.nick_name.is_some(),
        patch.nick_name.as_ref().and_then(|value| value.value.as_deref()),
        patch.avatar_svg_compressed.is_some(),
        patch.avatar_svg_compressed.as_ref().and_then(|value| value.value.as_deref()),
        patch.prefer_photo_avatar.is_some(),
        patch.prefer_photo_avatar.as_ref().and_then(|value| value.value),
        patch.sender_profile_counter.is_some(),
        patch.sender_profile_counter,
        patch.accepted.is_some(),
        patch.accepted,
        patch.deleted_by_user.is_some(),
        patch.deleted_by_user,
        patch.requested.is_some(),
        patch.requested,
        patch.blocked.is_some(),
        patch.blocked,
        patch.verified.is_some(),
        patch.verified,
        patch.account_deleted.is_some(),
        patch.account_deleted,
        patch.created_at.is_some(),
        patch.created_at,
        patch.signal_version.is_some(),
        patch.signal_version.as_deref(),
        patch.user_discovery_version.is_some(),
        patch.user_discovery_version.as_ref().and_then(|value| value.value.as_deref()),
        patch.user_discovery_excluded.is_some(),
        patch.user_discovery_excluded,
        patch.user_discovery_manual_approved.is_some(),
        patch.user_discovery_manual_approved.as_ref().and_then(|value| value.value),
        patch.recovery_is_trusted_friend.is_some(),
        patch.recovery_is_trusted_friend,
        patch.recovery_last_heartbeat.is_some(),
        patch.recovery_last_heartbeat.as_ref().and_then(|value| value.value),
        patch.recovery_secret_share.is_some(),
        patch.recovery_secret_share.as_ref().and_then(|value| value.value.as_deref()),
        patch.recovery_contacts_secret_share.is_some(),
        patch.recovery_contacts_secret_share.as_ref().and_then(|value| value.value.as_deref()),
        patch.recovery_contacts_last_heartbeat.is_some(),
        patch.recovery_contacts_last_heartbeat.as_ref().and_then(|value| value.value),
        patch.recovery_contacts_threshold.is_some(),
        patch.recovery_contacts_threshold.as_ref().and_then(|value| value.value),
        patch.ask_for_friend_promotions.is_some(),
        patch.ask_for_friend_promotions.as_ref().and_then(|value| value.value),
        patch.widget_sharing_allowed.is_some(),
        patch.widget_sharing_allowed,
        patch.widget_sharing_granted.is_some(),
        patch.widget_sharing_granted,
        patch.twonly_score.is_some(),
        patch.twonly_score.as_ref().and_then(|value| value.value),
        patch.joined_at.is_some(),
        patch.joined_at.as_ref().and_then(|value| value.value),
        patch.media_send_counter.is_some(),
        patch.media_send_counter,
        patch.media_received_counter.is_some(),
        patch.media_received_counter,
        id,
    ).execute(&mut **tx).await?;

    if refresh_name {
        let name = sqlx::query!(
            r#"
                SELECT COALESCE(NULLIF(nick_name, ''), display_name, username) AS "name!: String",
                    account_deleted AS "deleted!: bool"
                FROM contacts
                WHERE user_id = ?
            "#,
            id,
        )
        .fetch_optional(&mut **tx)
        .await?;

        if let Some(row) = name {
            let name = row.name;

            let name = if row.deleted {
                name.chars()
                    .flat_map(|character| [character, '\u{0336}'])
                    .collect()
            } else {
                name
            };

            sqlx::query!(
                r#"
                    UPDATE groups
                    SET group_name = ?
                    WHERE is_direct_chat = 1
                        AND EXISTS (
                        SELECT 1
                        FROM group_members
                        WHERE group_members.group_id = groups.group_id
                            AND contact_id = ?
                    )
                "#,
                name,
                id,
            )
            .execute(&mut **tx)
            .await?;
        }
    }

    Ok(())
}

pub async fn delete(tx: &mut Transaction<'_, Sqlite>, id: i64) -> Result<()> {
    sqlx::query!(
        r#"
            DELETE FROM contacts WHERE user_id = ?
        "#,
        id,
    )
    .execute(&mut **tx)
    .await?;

    Ok(())
}

pub async fn reset_recovery(tx: &mut Transaction<'_, Sqlite>) -> Result<()> {
    sqlx::query!(
        r#"
            UPDATE contacts
            SET recovery_is_trusted_friend = 0,
                recovery_last_heartbeat = NULL,
                recovery_secret_share = NULL
        "#,
    )
    .execute(&mut **tx)
    .await?;

    Ok(())
}
