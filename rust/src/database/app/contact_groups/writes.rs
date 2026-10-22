use super::table::ContactGroupInput;
use crate::error::Result;
use sqlx::{Sqlite, Transaction};
use std::collections::BTreeSet;

fn trim(value: &str) -> &str {
    value.trim_matches(|c: char| c.is_whitespace() || c == '\u{feff}')
}

fn name(value: &str) -> String {
    // Dart's length limit is in UTF-16 units. Preserve complete scalar values
    // instead of producing a dangling surrogate at the boundary.
    let mut units = 0;

    trim(value)
        .chars()
        .take_while(|c| {
            units += c.len_utf16();

            units <= 24
        })
        .collect()
}

fn emoji(value: Option<&str>) -> Option<&str> {
    value.map(trim).filter(|value| !value.is_empty())
}

pub async fn create(
    transaction: &mut Transaction<'_, Sqlite>, input: &ContactGroupInput,
) -> Result<i64> {
    Ok(sqlx::query_scalar!(
        r#"
            INSERT INTO contact_groups(name, emoji, text_color, background_color, show_as_shortcut,
                    show_as_label, share_stories
            )
            VALUES (?, ?, ?, ?, ?, ?, ?) RETURNING id AS "value!"
        "#,
        name(&input.name),
        emoji(input.emoji.as_deref()),
        input.text_color,
        input.background_color,
        input.show_as_shortcut,
        input.show_as_label,
        input.share_stories,
    )
    .fetch_one(&mut **transaction)
    .await?)
}

pub async fn update(
    transaction: &mut Transaction<'_, Sqlite>, id: i64, input: &ContactGroupInput,
) -> Result<bool> {
    Ok(sqlx::query!(
        r#"
            UPDATE contact_groups
            SET name = ?,
                emoji = ?,
                text_color = ?,
                background_color = ?,
                show_as_shortcut = ?,
                show_as_label = ?,
                share_stories = ?
            WHERE id = ?
        "#,
        name(&input.name),
        emoji(input.emoji.as_deref()),
        input.text_color,
        input.background_color,
        input.show_as_shortcut,
        input.show_as_label,
        input.share_stories,
        id,
    )
    .execute(&mut **transaction)
    .await?
    .rows_affected()
        > 0)
}

pub async fn set_user_membership(
    transaction: &mut Transaction<'_, Sqlite>, id: i64, user_id: i64, selected: bool,
) -> Result<()> {
    sqlx::query!(
        r#"
            DELETE FROM contact_group_members WHERE contact_group_id = ? AND user_id = ?
        "#,
        id,
        user_id,
    )
    .execute(&mut **transaction)
    .await?;

    if selected {
        sqlx::query!(
            r#"
                INSERT INTO contact_group_members(contact_group_id, user_id) VALUES (?, ?)
            "#,
            id,
            user_id,
        )
        .execute(&mut **transaction)
        .await?;
    }

    Ok(())
}

pub async fn set_group_membership(
    transaction: &mut Transaction<'_, Sqlite>, id: i64, group_id: &str, selected: bool,
) -> Result<()> {
    if selected
        && !sqlx::query_scalar!(
        r#"
            SELECT EXISTS(SELECT 1 FROM groups WHERE group_id = ? AND is_direct_chat = 0) AS "value!: bool"
        "#,
        group_id,
    )
        .fetch_one(&mut **transaction)
        .await?
    {
        return Ok(());
    }

    sqlx::query!(
        r#"
            DELETE FROM contact_group_members WHERE contact_group_id = ? AND group_id = ?
        "#,
        id,
        group_id,
    )
    .execute(&mut **transaction)
    .await?;

    if selected {
        sqlx::query!(
            r#"
                INSERT INTO contact_group_members(contact_group_id, group_id) VALUES (?, ?)
            "#,
            id,
            group_id,
        )
        .execute(&mut **transaction)
        .await?;
    }

    Ok(())
}

pub async fn replace_members(
    transaction: &mut Transaction<'_, Sqlite>, id: i64, user_ids: Vec<i64>, group_ids: Vec<String>,
) -> Result<()> {
    sqlx::query!(
        r#"
            DELETE FROM contact_group_members WHERE contact_group_id = ?
        "#,
        id,
    )
    .execute(&mut **transaction)
    .await?;

    for user_id in user_ids.into_iter().collect::<BTreeSet<_>>() {
        sqlx::query!(
            r#"
                INSERT INTO contact_group_members(contact_group_id, user_id) VALUES (?, ?)
            "#,
            id,
            user_id,
        )
        .execute(&mut **transaction)
        .await?;
    }

    for group_id in group_ids.into_iter().collect::<BTreeSet<_>>() {
        sqlx::query!(
            r#"
                INSERT INTO contact_group_members(contact_group_id, group_id)
                SELECT ?,
                    group_id
                FROM groups
                WHERE group_id = ?
                    AND is_direct_chat = 0
            "#,
            id,
            group_id,
        )
        .execute(&mut **transaction)
        .await?;
    }

    Ok(())
}

pub async fn increment_usage(transaction: &mut Transaction<'_, Sqlite>, id: i64) -> Result<()> {
    sqlx::query!(
        r#"
            UPDATE contact_groups SET usage_counter = usage_counter + 1 WHERE id = ?
        "#,
        id,
    )
    .execute(&mut **transaction)
    .await?;

    Ok(())
}

pub async fn delete(transaction: &mut Transaction<'_, Sqlite>, id: i64) -> Result<i64> {
    Ok(sqlx::query!(
        r#"
            DELETE FROM contact_groups WHERE id = ?
        "#,
        id,
    )
    .execute(&mut **transaction)
    .await?
    .rows_affected() as i64)
}
