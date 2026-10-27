-- Keep recipient-specific notification metadata even when a live update
-- arrives before its app card. Older pending updates retain their plain info.
ALTER TABLE webxdc_pending_updates ADD COLUMN notification_content TEXT;

-- Project the latest announcement as well as its author and delivery state.
DROP VIEW chat_messages;
CREATE VIEW chat_messages AS
SELECT m.rowid AS rowid,
       m.group_id, m.message_id, m.sender_id AS original_sender_id,
       CASE WHEN activity.message_id IS NOT NULL THEN activity.sender_id ELSE m.sender_id END AS sender_id,
       m.type,
       CASE WHEN activity.message_id IS NOT NULL THEN activity.content ELSE m.content END AS content,
       m.media_id,
       CASE WHEN activity.message_id IS NOT NULL THEN activity.additional_message_data ELSE m.additional_message_data END AS additional_message_data,
       m.media_stored, m.media_reopened, m.download_token, m.quotes_message_id,
       m.is_deleted_from_sender, m.is_widget_media, m.is_story,
       CASE WHEN activity.message_id IS NOT NULL THEN activity.opened_at ELSE m.opened_at END AS opened_at,
       CASE WHEN activity.message_id IS NOT NULL THEN activity.opened_by_all ELSE m.opened_by_all END AS opened_by_all,
       m.created_at, m.modified_at,
       CASE WHEN activity.message_id IS NOT NULL THEN activity.ack_by_user ELSE m.ack_by_user END AS ack_by_user,
       CASE WHEN activity.message_id IS NOT NULL THEN activity.ack_by_server ELSE m.ack_by_server END AS ack_by_server,
       activity.message_id AS activity_message_id
FROM messages m
LEFT JOIN messages activity ON m.type = 'webxdcApp'
    AND activity.group_id = m.group_id AND activity.type = 'text'
    AND activity.message_id = (
        SELECT u.message_id || '-info' FROM webxdc_updates u
        WHERE u.instance_id = m.message_id AND u.info IS NOT NULL
        ORDER BY u.received_at DESC, u.serial DESC LIMIT 1
    )
WHERE NOT (
    m.type = 'text' AND substr(m.message_id, -5) = '-info'
    AND EXISTS (
        SELECT 1 FROM webxdc_updates u
        WHERE u.message_id = substr(m.message_id, 1, length(m.message_id) - 5)
          AND u.info IS NOT NULL
    )
);
