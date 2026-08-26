/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::proto::client::encrypted_content;
use crate::error::Result;
use crate::utils::milliseconds_to_seconds;
use sqlx::{Sqlite, Transaction};

pub(crate) async fn handle_typing_indicator(
    t: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    group_id: &str,
    indicator: encrypted_content::TypingIndicator,
) -> Result<()> {
    let created_at = milliseconds_to_seconds(indicator.created_at);
    let typing = indicator.is_typing.then_some(created_at);
    sqlx::query!(
        r#"
        UPDATE group_members
        SET last_chat_opened = ?, last_type_indicator = ?
        WHERE group_id = ? AND contact_id = ?
        "#,
        created_at,
        typing,
        group_id,
        from_user_id,
    )
    .execute(&mut **t)
    .await?;
    Ok(())
}
