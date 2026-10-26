use super::table::MockGalleryItem;
use crate::database::app::AppDatabase;
use crate::error::{Result, TwonlyError};
use rand::Rng;
use sqlx::{Sqlite, Transaction};
use std::path::Path;

pub async fn seed_gallery(
    tx: &mut Transaction<'_, Sqlite>, items: Vec<MockGalleryItem>, opened_at: i64,
) -> Result<()> {
    if items.len() > 1000 {
        return Err(TwonlyError::Generic("too many mock gallery items".into()));
    }

    sqlx::query!(
        r#"
            INSERT INTO groups(group_id, group_name, is_direct_chat, joined_group)
            VALUES ('mock_group_gallery', 'Mock Gallery Group', 0, 1)
            ON CONFLICT(group_id) DO UPDATE SET group_name = excluded.group_name, joined_group = 1
        "#,
    )
    .execute(&mut **tx)
    .await?;

    for index in 0..12 {
        sqlx::query!(
            r#"
                INSERT INTO contacts(user_id, username, display_name)
                VALUES (?, ?, ?)
                ON CONFLICT(user_id) DO UPDATE
                SET username = excluded.username, display_name = excluded.display_name
            "#,
            9000000 + index,
            format!("mock_user_{index}"),
            format!("Author {index}"),
        )
        .execute(&mut **tx)
        .await?;
    }

    for (index, item) in items.into_iter().enumerate() {
        let id = format!("mock_gen_{index}");

        sqlx::query!(
            r#"
                INSERT INTO media_files(media_id, type, stored, created_at, created_at_month)
                VALUES (?, 'image', 1, ?, ?)
                ON CONFLICT(media_id) DO UPDATE
                SET type = 'image', stored = 1,
                    created_at = excluded.created_at, created_at_month = excluded.created_at_month
            "#,
            &id,
            item.created_at,
            item.month,
        )
        .execute(&mut **tx)
        .await?;

        sqlx::query!(
        r#"
            INSERT INTO messages(message_id, group_id, sender_id, type, media_id, media_stored, opened_at,
                created_at)
            VALUES (?, 'mock_group_gallery', ?, 'media', ?, 1, ?, ?)
            ON CONFLICT(message_id) DO UPDATE
            SET sender_id = excluded.sender_id, media_id = excluded.media_id,
                media_stored = 1, opened_at = excluded.opened_at, created_at = excluded.created_at
        "#,
        format!("mock_msg_{index}"),
        9000000 + (index % 12) as i64,
        id,
        opened_at,
        item.created_at,
    ).execute(&mut **tx).await?;
    }

    Ok(())
}

const SAMPLES: &[&str] = &[
    "Hey! How is everyone doing?",
    "This is a randomly generated debug message.",
    "Did anyone see this?",
    "Sounds good to me!",
    "I will check that later.",
    "That made me laugh 😄",
    "What do you think?",
    "Let’s do it!",
    "Quick update from my side.",
    "Testing a longer message to see how the chat bubble wraps across multiple lines in this \
     conversation.",
];

pub async fn seed_messages(
    tx: &mut Transaction<'_, Sqlite>, group: &str, count: i64, now: i64, prefix: &str,
) -> Result<i64> {
    if !(1..=1000).contains(&count) || prefix.is_empty() {
        return Err(TwonlyError::Generic("invalid mock message request".into()));
    }

    let members: Vec<i64> = sqlx::query_scalar!(
        r#"
            SELECT contact_id AS "value!"
            FROM group_members
            WHERE group_id = ? AND (member_state IS NULL OR member_state != 'leftGroup')
            ORDER BY contact_id
        "#,
        group,
    )
    .fetch_all(&mut **tx)
    .await?;

    if members.is_empty() {
        return Ok(0);
    }

    let rows: Vec<_> = {
        let mut random = rand::rng();

        (0..count)
            .map(|index| {
                (
                    members[random.random_range(0..members.len())],
                    format!(
                        "{} #{}",
                        SAMPLES[random.random_range(0..SAMPLES.len())],
                        index + 1
                    ),
                    format!("{prefix}_{index}"),
                    now - count + index,
                )
            })
            .collect()
    };

    for (sender, content, id, stamp) in rows {
        sqlx::query!(
            r#"
                INSERT INTO messages(message_id, group_id, sender_id, type, content, opened_at,
                    ack_by_server, ack_by_user, created_at)
                VALUES (?, ?, ?, 'text', ?, ?, ?, ?, ?)
            "#,
            id,
            group,
            sender,
            content,
            now,
            stamp,
            stamp,
            stamp,
        )
        .execute(&mut **tx)
        .await?;
    }

    sqlx::query!(
        r#"
            UPDATE groups
            SET archived = 0, deleted_content = 0, last_message_received = ?, last_message_exchange = ?
            WHERE group_id = ?
        "#,
        now,
        now,
        group,
    )
    .execute(&mut **tx)
    .await?;

    Ok(count)
}

/// A consistent inspection copy preserving the source encryption and SQLite
/// metadata. The bound path also supports quotes; existing files are refused.
pub async fn export_debug(database: &AppDatabase, path: &Path) -> Result<()> {
    if path.try_exists()? {
        return Err(TwonlyError::Generic(
            "debug export target already exists".into(),
        ));
    }

    let pool = database.pool.clone();

    let path = path.to_owned();

    crate::database::lifecycle::run(move |operation| async move {
        crate::database::snapshot::create(&pool, &path, &operation).await
    })
    .await
}
