/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::error::Result;
use sqlx::{Sqlite, Transaction};

pub struct MediaFile;

impl MediaFile {
    /// Mark a media upload as successful when a receiver response proves that
    /// the message (and therefore the media) reached another client.
    pub async fn handle_response_from_receiver(
        transaction: &mut Transaction<'_, Sqlite>,
        message_id: &str,
    ) -> Result<()> {
        let media_id = sqlx::query_scalar!(
            "SELECT media_id FROM messages WHERE message_id = ?",
            message_id,
        )
        .fetch_optional(&mut **transaction)
        .await?
        .flatten();
        let Some(media_id) = media_id else {
            return Ok(());
        };

        Self::mark_uploaded(transaction, &media_id).await
    }

    /// Single owner of the "media reached the server" transition. The state
    /// change, the per-recipient message actions, and the receipt bookkeeping
    /// have to become visible together, so they share one transaction.
    ///
    /// Every statement below is written to touch only the rows that still need
    /// it, because this runs more than once for the same media: the upload
    /// settles it, and a receiver's response or reaction can arrive later and
    /// settle it again. It must not short-circuit on the media row already
    /// being `uploaded` - a message added to a media that was uploaded earlier
    /// would then never leave the "sending" state, however long ago the
    /// recipient received it.
    pub async fn mark_uploaded(
        transaction: &mut Transaction<'_, Sqlite>,
        media_id: &str,
    ) -> Result<()> {
        sqlx::query!(
            "UPDATE media_files SET upload_state = 'uploaded' WHERE media_id = ? AND upload_state IS NOT 'uploaded'",
            media_id,
        )
        .execute(&mut **transaction)
        .await?;

        let now = chrono::Utc::now().timestamp();
        sqlx::query!(
            r#"
            INSERT INTO message_actions(message_id, contact_id, type, action_at)
            SELECT messages.message_id, group_members.contact_id, 'ackByServerAt', ?
            FROM messages
            JOIN group_members ON group_members.group_id = messages.group_id
            WHERE messages.media_id = ?
              AND (group_members.member_state IS NULL OR group_members.member_state != 'leftGroup')
            -- The first acknowledgement is the true one; a later settle of the
            -- same media must not move a timestamp that already stands.
            ON CONFLICT(message_id, contact_id, type)
            DO NOTHING
            "#,
            now,
            media_id,
        )
        .execute(&mut **transaction)
        .await?;

        let acknowledged = sqlx::query!(
            "UPDATE messages SET ack_by_server = ? WHERE media_id = ? AND ack_by_server IS NULL",
            now,
            media_id,
        )
        .execute(&mut **transaction)
        .await?
        .rows_affected();

        sqlx::query!(
            r#"
            UPDATE receipts
            SET ack_by_server_at = ?, retry_count = 1, last_retry = ?, mark_for_retry = NULL
            WHERE ack_by_server_at IS NULL
              AND EXISTS(
                SELECT 1
                FROM messages
                JOIN group_members ON group_members.group_id = messages.group_id
                WHERE messages.message_id = receipts.message_id
                  AND messages.media_id = ?
                  AND group_members.contact_id = receipts.contact_id
                  AND (group_members.member_state IS NULL OR group_members.member_state != 'leftGroup')
            )
            "#,
            now,
            now,
            media_id,
        )
        .execute(&mut **transaction)
        .await?;

        if acknowledged > 0 {
            tracing::info!(
                media_id,
                acknowledged,
                "marked media upload as successful after receiver response"
            );
        }
        Ok(())
    }
}
