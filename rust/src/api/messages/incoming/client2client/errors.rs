/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::proto::client::encrypted_content;
use crate::database::app::tables::UpdateContact;
use crate::error::Result;
use encrypted_content::error_messages::Type;
use sqlx::{Sqlite, Transaction};

pub(crate) async fn handle_error_message(
    transaction: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    _receipt_id: &str,
    group_id: Option<&str>,
    error: encrypted_content::ErrorMessages,
) -> Result<()> {
    match Type::try_from(error.r#type)? {
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
            .execute(&mut **transaction)
            .await?;
            UpdateContact::builder()
                .user_id(from_user_id)
                .accepted(false)
                .requested(true)
                .build()
                .update(transaction)
                .await?;
        }
        Type::GroupNotFoundOrNotAMember => {
            if let Some(group_id) = group_id {
                if let Ok(callbacks) = crate::bridge::callbacks::get_callbacks() {
                    let group_id = group_id.to_owned();
                    let related_receipt_id = error.related_receipt_id.clone();
                    tokio::spawn(async move {
                        (callbacks.api.group_membership_error)(
                            from_user_id,
                            group_id,
                            related_receipt_id,
                        )
                        .await;
                    });
                }
            }
        }
        Type::SessionOutOfSync | Type::UnknownMessageType => {}
    }
    Ok(())
}
