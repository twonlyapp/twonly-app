/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::proto::client::encrypted_content;
use crate::database::app::groups::native::Group;
use crate::database::app::mediafiles::native::MediaFile;
use crate::database::app::messages::native::Message;
use crate::database::app::receipts::table::Receipt;
use crate::error::Result;
use sqlx::{Sqlite, Transaction};

pub(crate) async fn handle_reaction(
    t: &mut Transaction<'_, Sqlite>, from_user_id: i64, group_id: &str,
    reaction: encrypted_content::Reaction,
) -> Result<()> {
    // A delayed reaction may outlive the message's deletion timer. There is
    // nothing to update once that row is gone, but the receipt must still be
    // acknowledged so the reliable mailbox does not retry it forever.
    let target_chat = sqlx::query_scalar!(
        "SELECT group_id FROM messages WHERE message_id = ?",
        &reaction.target_message_id
    )
    .fetch_optional(&mut **t)
    .await?;

    let Some(target_chat) = target_chat else {
        tracing::info!(
            from_user_id,
            group_id,
            message_id = reaction.target_message_id,
            "Ignoring a reaction whose target message is no longer stored"
        );

        return Ok(());
    };

    // Membership was checked for the chat the reaction names, and message IDs
    // are unique across all chats, so the target has to be in that chat too.
    // Otherwise a member of one chat could react to a message in another.
    if target_chat != group_id {
        tracing::warn!(
            from_user_id,
            group_id,
            message_id = reaction.target_message_id,
            "ignoring a reaction to a message in another chat"
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
        let inserted = Receipt::insert_reaction(
            t,
            &reaction.target_message_id,
            from_user_id,
            &reaction.emoji,
        )
        .await?;

        // A peer resending its queue repeats reactions this device already
        // shows. Moving the chat up for one would put it first with nothing
        // new in it.
        if inserted {
            Group::increase_last_message_exchange_to_now(t, group_id).await?;
        }
    }

    // A reaction proves our media arrived only when the media is ours and the
    // reactor is someone it was sent to. Taken from anyone, it marked our
    // media uploaded and its queued copies accepted, which could skip the
    // upload and hold back the retries.
    if Message::was_sent_to(t, &reaction.target_message_id, from_user_id).await? {
        MediaFile::handle_response_from_receiver(t, &reaction.target_message_id).await?;
    }

    Ok(())
}
