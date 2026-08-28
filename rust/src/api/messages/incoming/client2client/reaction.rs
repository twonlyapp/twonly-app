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
