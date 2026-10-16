/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::proto::client::encrypted_content;
use crate::database::app::tables::{Group, MediaFile, Receipt};
use crate::error::Result;
use sqlx::{Sqlite, Transaction};

pub(crate) async fn handle_reaction(
    t: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    group_id: &str,
    reaction: encrypted_content::Reaction,
) -> Result<()> {
    // A delayed reaction may outlive the message's deletion timer. There is
    // nothing to update once that row is gone, but the receipt must still be
    // acknowledged so the reliable mailbox does not retry it forever.
    let exists: i64 =
        sqlx::query_scalar("SELECT EXISTS(SELECT 1 FROM messages WHERE message_id = ?)")
            .bind(&reaction.target_message_id)
            .fetch_one(&mut **t)
            .await?;
    if exists == 0 {
        tracing::info!(
            from_user_id,
            group_id,
            message_id = reaction.target_message_id,
            "Ignoring a reaction whose target message is no longer stored"
        );
        return Ok(());
    }

    if reaction.remove {
        Receipt::delete_reaction(
            t,
            &reaction.target_message_id,
            from_user_id,
            &reaction.emoji,
        )
        .await?;
    } else {
        Receipt::insert_reaction(
            t,
            &reaction.target_message_id,
            from_user_id,
            &reaction.emoji,
        )
        .await?;
    }

    if !reaction.remove {
        Group::increase_last_message_exchange_to_now(t, group_id).await?;
    }

    MediaFile::handle_response_from_receiver(t, &reaction.target_message_id).await?;

    Ok(())
}
