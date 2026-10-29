use super::table::RecoveryContacts;
use crate::database::app::contacts::table::Contact;
use crate::error::Result;
use sqlx::SqliteConnection;

// Use the same validated evidence as badges and groups. Raw claims from an
// untrusted sender must not make somebody eligible to hold recovery shares.

pub async fn verified_ids(connection: &mut SqliteConnection) -> Result<Vec<i64>> {
    Ok(sqlx::query_scalar!(
        r#"
            SELECT contact_id AS "value!"
            FROM valid_key_verifications
            UNION
            SELECT announced_user_id AS user_id
            FROM valid_discovery_verifications
            ORDER BY user_id
        "#,
    )
    .fetch_all(connection)
    .await?)
}

pub async fn trusted_ids(connection: &mut SqliteConnection) -> Result<Vec<i64>> {
    Ok(sqlx::query_scalar!(
        r#"
            SELECT user_id AS "value!"
            FROM contacts
            WHERE recovery_is_trusted_friend = 1
            ORDER BY user_id
        "#,
    )
    .fetch_all(connection)
    .await?)
}

pub async fn count(connection: &mut SqliteConnection, selection: RecoveryContacts) -> Result<i64> {
    Ok(match selection {
        RecoveryContacts::Trusted => {
            sqlx::query_scalar!(
                r#"
                    SELECT COUNT(*) AS "count!" FROM contacts WHERE recovery_is_trusted_friend = 1
                "#,
            )
            .fetch_one(connection)
            .await?
        }
        RecoveryContacts::Eligible => {
            sqlx::query_scalar!(
                r#"
                    SELECT COUNT(*) AS "count!" FROM contacts WHERE
                    accepted = 1 AND blocked = 0 AND account_deleted = 0 AND deleted_by_user = 0
                    AND (
                        EXISTS (
                            SELECT 1
                            FROM valid_key_verifications v
                            WHERE v.contact_id = contacts.user_id
                        )
                        OR EXISTS (
                            SELECT 1
                            FROM valid_discovery_verifications r
                            WHERE r.announced_user_id = contacts.user_id
                        )
                    )
                "#,
            )
            .fetch_one(connection)
            .await?
        }
    })
}

pub async fn contacts(
    connection: &mut SqliteConnection, selection: RecoveryContacts, limit: Option<i64>,
) -> Result<Vec<Contact>> {
    Ok(match selection {
        RecoveryContacts::Trusted => sqlx::query_as!(
        Contact,
        r#"
            SELECT user_id AS "user_id!",
            username AS "username!",
            display_name AS "display_name?",
            nick_name AS "nick_name?",
            avatar_svg_compressed AS "avatar_svg_compressed?",
            prefer_photo_avatar AS "prefer_photo_avatar?",
            sender_profile_counter AS "sender_profile_counter!",
            accepted AS "accepted!",
            deleted_by_user AS "deleted_by_user!",
            requested AS "requested!",
            requested_by_user AS "requested_by_user!",
            blocked AS "blocked!",
            verified AS "verified!",
            account_deleted AS "account_deleted!",
            created_at AS "created_at!",
            signal_version AS "signal_version!",
            user_discovery_version AS "user_discovery_version?",
            user_discovery_excluded AS "user_discovery_excluded!",
            user_discovery_manual_approved AS "user_discovery_manual_approved?",
            recovery_is_trusted_friend AS "recovery_is_trusted_friend!",
            recovery_last_heartbeat AS "recovery_last_heartbeat?",
            recovery_secret_share AS "recovery_secret_share?",
            recovery_contacts_secret_share AS "recovery_contacts_secret_share?",
            recovery_contacts_last_heartbeat AS "recovery_contacts_last_heartbeat?",
            recovery_contacts_threshold AS "recovery_contacts_threshold?",
            ask_for_friend_promotions AS "ask_for_friend_promotions?",
            media_send_counter AS "media_send_counter!",
            media_received_counter AS "media_received_counter!",
            widget_sharing_allowed AS "widget_sharing_allowed!",
            widget_sharing_granted AS "widget_sharing_granted!",
            twonly_score AS "twonly_score?",
            joined_at AS "joined_at?" FROM contacts WHERE recovery_is_trusted_friend = 1 ORDER BY user_id LIMIT ?
        "#,
        limit.unwrap_or(-1),
    ).fetch_all(connection).await?,
        RecoveryContacts::Eligible => sqlx::query_as!(
        Contact,
        r#"
            SELECT user_id AS "user_id!",
                       username AS "username!",
                       display_name AS "display_name?",
                       nick_name AS "nick_name?",
                       avatar_svg_compressed AS "avatar_svg_compressed?",
                       prefer_photo_avatar AS "prefer_photo_avatar?",
                       sender_profile_counter AS "sender_profile_counter!",
                       accepted AS "accepted!",
                       deleted_by_user AS "deleted_by_user!",
                       requested AS "requested!",
                       requested_by_user AS "requested_by_user!",
                       blocked AS "blocked!",
                       verified AS "verified!",
                       account_deleted AS "account_deleted!",
                       created_at AS "created_at!",
                       signal_version AS "signal_version!",
                       user_discovery_version AS "user_discovery_version?",
                       user_discovery_excluded AS "user_discovery_excluded!",
                       user_discovery_manual_approved AS "user_discovery_manual_approved?",
                       recovery_is_trusted_friend AS "recovery_is_trusted_friend!",
                       recovery_last_heartbeat AS "recovery_last_heartbeat?",
                       recovery_secret_share AS "recovery_secret_share?",
                       recovery_contacts_secret_share AS "recovery_contacts_secret_share?",
                       recovery_contacts_last_heartbeat AS "recovery_contacts_last_heartbeat?",
                       recovery_contacts_threshold AS "recovery_contacts_threshold?",
                       ask_for_friend_promotions AS "ask_for_friend_promotions?",
                       media_send_counter AS "media_send_counter!",
                       media_received_counter AS "media_received_counter!",
                       widget_sharing_allowed AS "widget_sharing_allowed!",
                       widget_sharing_granted AS "widget_sharing_granted!",
                       twonly_score AS "twonly_score?",
                       joined_at AS "joined_at?" FROM contacts WHERE
               accepted = 1 AND blocked = 0 AND account_deleted = 0 AND deleted_by_user = 0
               AND (
                   EXISTS (
                       SELECT 1
                       FROM valid_key_verifications v
                       WHERE v.contact_id = contacts.user_id
                   )
                   OR EXISTS (
                       SELECT 1
                       FROM valid_discovery_verifications r
                       WHERE r.announced_user_id = contacts.user_id
                   )
               )
            ORDER BY media_send_counter DESC, user_id LIMIT ?
        "#,
        limit.unwrap_or(-1),
    ).fetch_all(connection).await?,
    })
}
