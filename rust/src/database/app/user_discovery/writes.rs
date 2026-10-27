use super::table::UserDiscoveryAnnouncedUserPatch;
use crate::error::Result;
use sqlx::{Sqlite, Transaction};

pub async fn mark_shown(tx: &mut Transaction<'_, Sqlite>) -> Result<()> {
    sqlx::query!(
        r#"
            UPDATE user_discovery_announced_users
            SET was_shown_to_the_user = 1
            WHERE username IS NOT NULL
                AND was_shown_to_the_user = 0
                AND is_hidden = 0
        "#,
    )
    .execute(&mut **tx)
    .await?;

    Ok(())
}

pub async fn update(
    tx: &mut Transaction<'_, Sqlite>, id: i64, patch: UserDiscoveryAnnouncedUserPatch,
) -> Result<()> {
    if !(patch.announced_user_id.is_some()
        || patch.announced_public_key.is_some()
        || patch.public_id.is_some()
        || patch.username.is_some()
        || patch.was_shown_to_the_user.is_some()
        || patch.is_hidden.is_some()
        || patch.was_asked_friends.is_some())
    {
        return Ok(());
    }

    sqlx::query!(
        r#"
            UPDATE user_discovery_announced_users
            SET announced_user_id = CASE WHEN ? THEN ? ELSE announced_user_id END,
                announced_public_key = CASE WHEN ? THEN ? ELSE announced_public_key END,
                public_id = CASE WHEN ? THEN ? ELSE public_id END,
                username = CASE WHEN ? THEN ? ELSE username END,
                was_shown_to_the_user = CASE WHEN ? THEN ? ELSE was_shown_to_the_user END,
                is_hidden = CASE WHEN ? THEN ? ELSE is_hidden END,
                was_asked_friends = CASE WHEN ? THEN ? ELSE was_asked_friends END
            WHERE announced_user_id = ?
        "#,
        patch.announced_user_id.is_some(),
        patch.announced_user_id,
        patch.announced_public_key.is_some(),
        patch.announced_public_key.as_deref(),
        patch.public_id.is_some(),
        patch.public_id,
        patch.username.is_some(),
        patch
            .username
            .as_ref()
            .and_then(|value| value.value.as_deref()),
        patch.was_shown_to_the_user.is_some(),
        patch.was_shown_to_the_user,
        patch.is_hidden.is_some(),
        patch.is_hidden,
        patch.was_asked_friends.is_some(),
        patch.was_asked_friends,
        id,
    )
    .execute(&mut **tx)
    .await?;

    Ok(())
}
