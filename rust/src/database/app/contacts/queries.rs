use super::table::*;
use crate::error::Result;
use sqlx::SqliteConnection;

pub async fn get(connection: &mut SqliteConnection, id: i64) -> Result<Option<Contact>> {
    Ok(sqlx::query_as!(
        Contact,
        r#"
            SELECT
            user_id AS "user_id!",
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
                joined_at AS "joined_at?"
            FROM contacts WHERE user_id = ?
        "#,
        id,
    )
    .fetch_optional(connection)
    .await?)
}

pub async fn list(connection: &mut SqliteConnection, input: &ContactQuery) -> Result<Vec<Contact>> {
    if matches!(input.filter, ContactFilter::Ids) && input.ids.is_empty() {
        return Ok(Vec::new());
    }

    // Each expansion contains only SQL literals; SQLx checks every filter at build
    // time.
    macro_rules! select {
        ($tail:literal $(, $arg:expr)* $(,)?) => {
            sqlx::query_as!(
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
                        joined_at AS "joined_at?"
                    FROM contacts
                "# + $tail,
                $($arg),*
            ).fetch_all(&mut *connection).await?
        };
    }

    Ok(match input.filter {
        ContactFilter::All => select!(
            r#"
                ORDER BY user_id
            "#
        ),
        ContactFilter::NotAccepted => select!(
            r#"
                WHERE accepted = 0 AND blocked = 0 AND deleted_by_user = 0
                  AND account_deleted = 0 AND (requested = 1 OR requested_by_user = 1)
                ORDER BY user_id
            "#
        ),
        ContactFilter::Accepted => select!(
            r#"
                WHERE blocked = 0 AND accepted = 1 AND account_deleted = 0 ORDER BY user_id
            "#
        ),
        ContactFilter::Ids => select!(
            r#"
                WHERE user_id IN (SELECT value FROM json_each(?)) ORDER BY user_id
            "#,
            serde_json::to_string(&input.ids)?
        ),
        ContactFilter::Usernames => select!(
            r#"
                WHERE username IN (?, ?) ORDER BY user_id
            "#,
            input.username.as_deref(),
            input.username2.as_deref()
        ),
        ContactFilter::Discovery => select!(
            r#"
                WHERE user_discovery_version IS NOT NULL AND user_discovery_excluded = 0 AND account_deleted = 0
                AND media_send_counter >= ? AND (? = 0 OR user_discovery_manual_approved = 1) ORDER BY user_id
            "#,
            input.required_send_images,
            input.manual_approval
        ),
    })
}

pub async fn count(connection: &mut SqliteConnection, metric: ContactCount) -> Result<i64> {
    Ok(match metric {
        ContactCount::All => {
            sqlx::query_scalar!(
                r#"
            SELECT COUNT(*) AS "count!" FROM contacts
        "#,
            )
            .fetch_one(connection)
            .await?
        }
        ContactCount::Blocked => {
            sqlx::query_scalar!(
                r#"
            SELECT COUNT(*) AS "count!" FROM contacts WHERE blocked = 1
        "#,
            )
            .fetch_one(connection)
            .await?
        }
        ContactCount::Accepted => {
            sqlx::query_scalar!(
                r#"SELECT COUNT(*) AS "count!" FROM contacts
                   WHERE blocked = 0 AND accepted = 1 AND account_deleted = 0"#,
            )
            .fetch_one(connection)
            .await?
        }
        ContactCount::Requested => {
            sqlx::query_scalar!(
                r#"
            SELECT COUNT(*) AS "count!"
            FROM contacts
            WHERE requested = 1
                AND accepted = 0
                AND deleted_by_user = 0
                AND blocked = 0
                AND account_deleted = 0
        "#,
            )
            .fetch_one(connection)
            .await?
        }
    })
}

pub async fn has_photo(connection: &mut SqliteConnection, id: i64) -> Result<bool> {
    Ok(sqlx::query_scalar!(
        r#"
            SELECT EXISTS(
                SELECT 1
                FROM received_custom_avatars
                WHERE contact_id = ?
                    AND webp IS NOT NULL
            ) AS "value!: bool"
        "#,
        id,
    )
    .fetch_one(connection)
    .await?)
}
