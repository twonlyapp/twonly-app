use super::table::*;
use crate::error::{Result, TwonlyError};
use sqlx::SqliteConnection;
use std::collections::BTreeMap;

pub async fn list(
    connection: &mut SqliteConnection, filter: ContactGroupFilter, user_id: Option<i64>,
    group_id: Option<&str>,
) -> Result<Vec<ContactGroup>> {
    // Each expansion contains only SQL literals; SQLx checks every filter at build
    // time.
    macro_rules! select {
        ($tail:literal $(, $arg:expr)* $(,)?) => {
            sqlx::query_as!(
                ContactGroup,
                r#"
                    SELECT cg.id AS "id!",
                        cg.name AS "name!",
                        cg.emoji AS "emoji?",
                        cg.text_color AS "text_color!",
                        cg.background_color AS "background_color!",
                        cg.show_as_shortcut AS "show_as_shortcut!: bool",
                        cg.show_as_label AS "show_as_label!: bool",
                        cg.share_stories AS "share_stories!: bool",
                        cg.usage_counter AS "usage_counter!",
                        cg.created_at AS "created_at!"
                    FROM contact_groups cg
                "# + $tail,
                $($arg),*
            ).fetch_all(&mut *connection).await?
        };
    }

    Ok(match filter {
        ContactGroupFilter::All => select!(
            r#"
                ORDER BY cg.name, cg.id
            "#
        ),
        ContactGroupFilter::Shortcuts => select!(
            r#"
                WHERE cg.show_as_shortcut = 1 ORDER BY cg.usage_counter DESC, cg.id
            "#
        ),
        ContactGroupFilter::Stories => select!(
            r#"
                WHERE cg.share_stories = 1 ORDER BY cg.usage_counter DESC, cg.name, cg.id
            "#
        ),
        ContactGroupFilter::User => {
            let id = user_id
                .ok_or_else(|| TwonlyError::Generic("Missing contact group user id".into()))?;

            select!(
                r#"
                    WHERE cg.show_as_label = 1 AND EXISTS (SELECT 1 FROM contact_group_members m
                    WHERE m.contact_group_id = cg.id AND m.user_id = ?) ORDER BY cg.name, cg.id
                "#,
                id
            )
        }
        ContactGroupFilter::Group => {
            let id = group_id
                .ok_or_else(|| TwonlyError::Generic("Missing contact group chat id".into()))?;

            select!(
                r#"
                    WHERE cg.show_as_label = 1 AND EXISTS (SELECT 1 FROM contact_group_members m
                    WHERE m.contact_group_id = cg.id AND m.group_id = ?) ORDER BY cg.name, cg.id
                "#,
                id
            )
        }
    })
}

pub async fn get(connection: &mut SqliteConnection, id: i64) -> Result<Option<ContactGroup>> {
    Ok(sqlx::query_as!(
        ContactGroup,
        r#"
            SELECT cg.id AS "id!",
            cg.name AS "name!",
            cg.emoji AS "emoji?",
            cg.text_color AS "text_color!",
            cg.background_color AS "background_color!",
            cg.show_as_shortcut AS "show_as_shortcut!: bool",
            cg.show_as_label AS "show_as_label!: bool",
            cg.share_stories AS "share_stories!: bool",
            cg.usage_counter AS "usage_counter!",
            cg.created_at AS "created_at!" FROM contact_groups cg WHERE cg.id = ?
        "#,
        id,
    )
    .fetch_optional(connection)
    .await?)
}

pub async fn members(
    connection: &mut SqliteConnection, id: i64,
) -> Result<Vec<ContactGroupMember>> {
    Ok(sqlx::query_as!(
        ContactGroupMember,
        r#"
            SELECT id AS "id!",
                contact_group_id AS "contact_group_id!",
                user_id AS "user_id?",
                group_id AS "group_id?"
            FROM contact_group_members
            WHERE contact_group_id = ?
            ORDER BY id
        "#,
        id,
    )
    .fetch_all(connection)
    .await?)
}

pub async fn membership_ids(
    connection: &mut SqliteConnection, user_id: Option<i64>, group_id: Option<&str>,
) -> Result<Vec<i64>> {
    Ok(sqlx::query_scalar!(
        r#"
            SELECT contact_group_id AS "value!"
            FROM contact_group_members
            WHERE user_id = ?
                OR group_id = ?
            ORDER BY contact_group_id
        "#,
        user_id,
        group_id,
    )
    .fetch_all(connection)
    .await?)
}

pub async fn labels(
    connection: &mut SqliteConnection, for_users: bool,
) -> Result<ContactGroupLabels> {
    let rows = sqlx::query!(
        r#"
            SELECT cg.id AS "id!",
            cg.name AS "name!",
            cg.emoji AS "emoji?",
            cg.text_color AS "text_color!",
            cg.background_color AS "background_color!",
            cg.show_as_shortcut AS "show_as_shortcut!: bool",
            cg.show_as_label AS "show_as_label!: bool",
            cg.share_stories AS "share_stories!: bool",
            cg.usage_counter AS "usage_counter!",
            cg.created_at AS "created_at!", m.id AS "member_id!", m.user_id, m.group_id FROM contact_groups cg
                JOIN contact_group_members m ON m.contact_group_id = cg.id WHERE cg.show_as_label = 1 AND ((? = 1
                AND m.user_id IS NOT NULL) OR (? = 0 AND m.group_id IS NOT NULL)) ORDER BY cg.id, m.id
        "#,
        for_users,
        for_users,
    ).fetch_all(connection).await?;

    let mut groups = BTreeMap::new();

    let mut members = Vec::with_capacity(rows.len());

    for row in rows {
        members.push(ContactGroupMember {
            id: row.member_id,
            contact_group_id: row.id,
            user_id: row.user_id,
            group_id: row.group_id,
        });

        groups.entry(row.id).or_insert(ContactGroup {
            id: row.id,
            name: row.name,
            emoji: row.emoji,
            text_color: row.text_color,
            background_color: row.background_color,
            show_as_shortcut: row.show_as_shortcut,
            show_as_label: row.show_as_label,
            share_stories: row.share_stories,
            usage_counter: row.usage_counter,
            created_at: row.created_at,
        });
    }

    Ok(ContactGroupLabels {
        groups: groups.into_values().collect(),
        members,
    })
}
