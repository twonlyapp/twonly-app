use super::table::*;
use crate::database::app::contacts;
use crate::error::Result;
use sqlx::SqliteConnection;

pub async fn announcements(
    connection: &mut SqliteConnection,
) -> Result<Vec<UserDiscoveryAnnouncedUser>> {
    Ok(sqlx::query_as!(
        UserDiscoveryAnnouncedUser,
        r#"
            SELECT
            announced_user_id AS "announced_user_id!",
                announced_public_key AS "announced_public_key!",
                public_id AS "public_id!",
                username AS "username?",
                was_shown_to_the_user AS "was_shown_to_the_user!: bool",
                is_hidden AS "is_hidden!: bool",
                was_asked_friends AS "was_asked_friends!: bool"
            FROM user_discovery_announced_users
            ORDER BY announced_user_id
        "#,
    )
    .fetch_all(connection)
    .await?)
}

pub async fn get(
    connection: &mut SqliteConnection, id: i64,
) -> Result<Option<UserDiscoveryAnnouncedUser>> {
    Ok(sqlx::query_as!(
        UserDiscoveryAnnouncedUser,
        r#"
            SELECT
            announced_user_id AS "announced_user_id!",
                announced_public_key AS "announced_public_key!",
                public_id AS "public_id!",
                username AS "username?",
                was_shown_to_the_user AS "was_shown_to_the_user!: bool",
                is_hidden AS "is_hidden!: bool",
                was_asked_friends AS "was_asked_friends!: bool"
            FROM user_discovery_announced_users
            WHERE announced_user_id = ?
        "#,
        id,
    )
    .fetch_optional(connection)
    .await?)
}

pub async fn missing_data(
    connection: &mut SqliteConnection,
) -> Result<Vec<UserDiscoveryAnnouncedUser>> {
    Ok(sqlx::query_as!(
        UserDiscoveryAnnouncedUser,
        r#"
            SELECT
            announced_user_id AS "announced_user_id!",
                announced_public_key AS "announced_public_key!",
                public_id AS "public_id!",
                username AS "username?",
                was_shown_to_the_user AS "was_shown_to_the_user!: bool",
                is_hidden AS "is_hidden!: bool",
                was_asked_friends AS "was_asked_friends!: bool"
            FROM user_discovery_announced_users a
            WHERE a.username IS NULL
                AND NOT EXISTS(
                SELECT 1
                FROM contacts
                WHERE user_id = a.announced_user_id
            )
            ORDER BY a.announced_user_id
        "#,
    )
    .fetch_all(connection)
    .await?)
}

pub async fn relations(
    connection: &mut SqliteConnection,
) -> Result<Vec<UserDiscoveryUserRelation>> {
    Ok(sqlx::query_as!(
        UserDiscoveryUserRelation,
        r#"
            SELECT announced_user_id AS "announced_user_id!",
                from_contact_id AS "from_contact_id!",
                public_key_verified_timestamp AS "public_key_verified_timestamp?"
            FROM user_discovery_user_relations ORDER BY rowid
        "#,
    )
    .fetch_all(connection)
    .await?)
}

pub async fn own_promotions(
    connection: &mut SqliteConnection,
) -> Result<Vec<UserDiscoveryOwnPromotion>> {
    Ok(sqlx::query_as!(
        UserDiscoveryOwnPromotion,
        r#"
            SELECT version_id AS "version_id!",
                contact_id AS "contact_id!",
                promotion AS "promotion!"
            FROM user_discovery_own_promotions
            ORDER BY version_id
        "#,
    )
    .fetch_all(connection)
    .await?)
}

pub async fn other_promotions(
    connection: &mut SqliteConnection,
) -> Result<Vec<UserDiscoveryOtherPromotion>> {
    Ok(sqlx::query_as!(
        UserDiscoveryOtherPromotion,
        r#"
            SELECT from_contact_id AS "from_contact_id!",
                promotion_id AS "promotion_id!",
                public_id AS "public_id!",
                threshold AS "threshold!",
                announcement_share AS "announcement_share!",
                public_key_verified_timestamp AS "public_key_verified_timestamp?"
            FROM user_discovery_other_promotions
            ORDER BY rowid
        "#,
    )
    .fetch_all(connection)
    .await?)
}

pub async fn shares(connection: &mut SqliteConnection) -> Result<Vec<UserDiscoveryShare>> {
    Ok(sqlx::query_as!(
        UserDiscoveryShare,
        r#"
            SELECT share_id AS "share_id!",
                share AS "share!",
                contact_id AS "contact_id?"
            FROM user_discovery_shares ORDER BY share_id
        "#,
    )
    .fetch_all(connection)
    .await?)
}

pub async fn count_suggestions(connection: &mut SqliteConnection, threshold: i64) -> Result<i64> {
    Ok(sqlx::query_scalar!(
        r#"
            SELECT COUNT(*) AS "value!"
                FROM (
            SELECT a.announced_user_id
            FROM user_discovery_announced_users a
            JOIN user_discovery_user_relations r
            ON r.announced_user_id = a.announced_user_id
            JOIN contacts c
            ON c.user_id = r.from_contact_id
            WHERE a.username IS NOT NULL
                AND c.accepted = 1
                AND c.blocked = 0
                AND c.deleted_by_user = 0
                AND c.account_deleted = 0
                AND (? = 0
                    OR (a.is_hidden = 0
                        AND (NOT EXISTS(
                            SELECT 1
                            FROM contacts known
                            WHERE known.user_id = a.announced_user_id
                        )
                            OR EXISTS(
                            SELECT 1
                            FROM contacts known
                            WHERE known.user_id = a.announced_user_id
                                AND known.deleted_by_user = 1
                                AND known.accepted = 0
                                AND known.blocked = 0
                                AND known.account_deleted = 0
                        )
                    )
                )
            )
                AND (? = 0
                    OR a.was_shown_to_the_user = 0
            )
            GROUP BY a.announced_user_id
            HAVING COUNT(*) >= ?
            )
        "#,
        true,
        true,
        threshold.max(3),
    )
    .fetch_one(connection)
    .await?)
}

pub async fn suggestions(
    connection: &mut SqliteConnection, only_new: bool, threshold: i64,
) -> Result<DiscoverySuggestions> {
    let ids: Vec<i64> = sqlx::query_scalar!(
        r#"
            SELECT a.announced_user_id AS "value!"
                FROM user_discovery_announced_users a
            JOIN user_discovery_user_relations r
            ON r.announced_user_id = a.announced_user_id
            JOIN contacts c
            ON c.user_id = r.from_contact_id
            WHERE a.username IS NOT NULL
                AND c.accepted = 1
                AND c.blocked = 0
                AND c.deleted_by_user = 0
                AND c.account_deleted = 0
                AND (? = 0
                    OR (a.is_hidden = 0
                        AND (NOT EXISTS(
                            SELECT 1
                            FROM contacts known
                            WHERE known.user_id = a.announced_user_id
                        )
                            OR EXISTS(
                            SELECT 1
                            FROM contacts known
                            WHERE known.user_id = a.announced_user_id
                                AND known.deleted_by_user = 1
                                AND known.accepted = 0
                                AND known.blocked = 0
                                AND known.account_deleted = 0
                        )
                    )
                )
            )
                AND (? = 0
                    OR a.was_shown_to_the_user = 0
            )
            GROUP BY a.announced_user_id
            HAVING COUNT(*) >= ?
        "#,
        only_new,
        false,
        threshold.max(3),
    )
    .fetch_all(&mut *connection)
    .await?;

    if ids.is_empty() {
        return Ok(DiscoverySuggestions {
            users: vec![],
            relations: vec![],
            contacts: vec![],
        });
    }

    let ids = serde_json::to_string(&ids)?;

    let users = sqlx::query_as!(
        UserDiscoveryAnnouncedUser,
        r#"
            SELECT
            announced_user_id AS "announced_user_id!",
                announced_public_key AS "announced_public_key!",
                public_id AS "public_id!",
                username AS "username?",
                was_shown_to_the_user AS "was_shown_to_the_user!: bool",
                is_hidden AS "is_hidden!: bool",
                was_asked_friends AS "was_asked_friends!: bool"
            FROM user_discovery_announced_users
            WHERE announced_user_id IN (
                SELECT value
                FROM json_each(?)
            )
            ORDER BY announced_user_id
        "#,
        &ids,
    )
    .fetch_all(&mut *connection)
    .await?;

    let relations: Vec<UserDiscoveryUserRelation> = sqlx::query_as!(
        UserDiscoveryUserRelation,
        r#"
            SELECT announced_user_id AS "announced_user_id!",
                from_contact_id AS "from_contact_id!",
                public_key_verified_timestamp AS "public_key_verified_timestamp?"
            FROM user_discovery_user_relations r
            WHERE announced_user_id IN (
                SELECT value
                FROM json_each(?)
            )
                AND EXISTS(
                SELECT 1
                FROM contacts c
                WHERE c.user_id = r.from_contact_id
                    AND c.accepted = 1
                    AND c.blocked = 0
                    AND c.deleted_by_user = 0
                    AND c.account_deleted = 0
            )
            ORDER BY r.rowid
        "#,
        ids,
    )
    .fetch_all(&mut *connection)
    .await?;

    let contact_ids = relations.iter().map(|r| r.from_contact_id).collect();

    let contacts = contacts::queries::list(
        connection,
        &contacts::table::ContactQuery {
            filter: contacts::table::ContactFilter::Ids,
            ids: contact_ids,
            username: None,
            username2: None,
            required_send_images: 0,
            manual_approval: false,
        },
    )
    .await?;

    Ok(DiscoverySuggestions {
        users,
        relations,
        contacts,
    })
}
