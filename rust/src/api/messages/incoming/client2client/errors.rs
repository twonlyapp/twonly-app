/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::proto::client::encrypted_content;
use crate::context::Context;
use crate::database::app::tables::UpdateContact;
use crate::error::Result;
use crate::services::groups::GroupService;
use encrypted_content::error_messages::Type;
use sqlx::{Sqlite, Transaction};
use std::sync::Arc;

pub(crate) async fn handle_error_message(
    ctx: &Arc<Context>,
    t: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    group_id: Option<&str>,
    error: encrypted_content::ErrorMessages,
) -> Result<()> {
    let error_type = Type::try_from(error.r#type)?;
    tracing::warn!(?error_type, from_user_id, "received client error message");

    match error_type {
        Type::ErrorProcessingMessageCreatedAccountRequestInstead => {
            sqlx::query!(
                r#"
                UPDATE receipts
                SET mark_for_retry_after_accepted = CAST(strftime('%s', 'now') AS INTEGER)
                WHERE receipt_id = ? AND contact_id = ?
                "#,
                error.related_receipt_id,
                from_user_id,
            )
            .execute(&mut **t)
            .await?;

            UpdateContact::builder()
                .user_id(from_user_id)
                .accepted(false)
                .requested(true)
                .build()
                .update(t)
                .await?;
        }
        Type::GroupNotFoundOrNotAMember => {
            if let Some(group_id) = group_id {
                GroupService::new(ctx)
                    .handle_membership_error(
                        t,
                        from_user_id,
                        group_id.to_owned(),
                        error.related_receipt_id,
                    )
                    .await?;
            }
        }
        Type::SessionOutOfSync | Type::UnknownMessageType => {}
    }
    Ok(())
}
