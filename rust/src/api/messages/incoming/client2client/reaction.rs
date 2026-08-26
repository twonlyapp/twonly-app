/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::proto::client::encrypted_content;
use crate::bridge::callbacks::get_callbacks;
use crate::database::app::tables::Group;
use crate::error::Result;
use sqlx::{Sqlite, Transaction};

pub(crate) async fn handle_reaction(
    t: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    group_id: &str,
    reaction: encrypted_content::Reaction,
) -> Result<()> {
    if reaction.remove {
        sqlx::query!(
            r#"
            DELETE FROM reactions
            WHERE message_id = ? AND sender_id = ? AND emoji = ?
            "#,
            reaction.target_message_id,
            from_user_id,
            reaction.emoji,
        )
        .execute(&mut **t)
        .await?;
    } else {
        sqlx::query!(
            r#"
            INSERT INTO reactions(message_id, emoji, sender_id)
            VALUES (?, ?, ?)
            ON CONFLICT(message_id, sender_id, emoji) DO NOTHING
            "#,
            reaction.target_message_id,
            reaction.emoji,
            from_user_id,
        )
        .execute(&mut **t)
        .await?;
    }

    if !reaction.remove {
        Group::increase_last_message_exchange_to_now(t, group_id).await?;
    }

    if let Ok(callbacks) = get_callbacks() {
        let message_id = reaction.target_message_id;
        tokio::spawn(async move {
            (callbacks.api.media_action)(
                "response".into(),
                String::new(),
                from_user_id,
                message_id,
            )
            .await;
        });
    }

    Ok(())
}
