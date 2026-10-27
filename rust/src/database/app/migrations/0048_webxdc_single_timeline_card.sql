-- One visible card per app instance. Automatic info rows remain internal so
-- existing delivery/read receipts keep their stable per-update message IDs.
-- The original message author stays immutable for protocol ownership checks.
CREATE TRIGGER webxdc_activity_cleanup
BEFORE DELETE ON webxdc_instances
BEGIN
    DELETE FROM messages
    WHERE type = 'text' AND message_id IN (
        SELECT message_id || '-info' FROM webxdc_updates
        WHERE instance_id = OLD.instance_id AND info IS NOT NULL
    );
END;

CREATE VIEW chat_messages AS
SELECT m.rowid AS rowid,
       m.group_id, m.message_id, m.sender_id AS original_sender_id,
       CASE WHEN activity.message_id IS NOT NULL THEN activity.sender_id ELSE m.sender_id END AS sender_id,
       m.type, m.content, m.media_id, m.additional_message_data,
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
