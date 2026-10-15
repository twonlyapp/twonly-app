-- Message deletion can originate in Dart, Rust, or a cascading chat deletion.
-- Update the outbox in the same transaction so badge subscribers see it too.
CREATE INDEX idx_notification_outbox_message
    ON notification_outbox(message_id) WHERE cleared_at IS NULL;

CREATE TRIGGER clear_deleted_message_notifications
AFTER DELETE ON messages
BEGIN
    UPDATE notification_outbox
    SET cleared_at = CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)
    WHERE message_id = OLD.message_id AND cleared_at IS NULL;
END;

CREATE TRIGGER clear_sender_deleted_message_notifications
AFTER UPDATE OF is_deleted_from_sender ON messages
WHEN NEW.is_deleted_from_sender = 1
BEGIN
    UPDATE notification_outbox
    SET cleared_at = CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)
    WHERE message_id = NEW.message_id AND cleared_at IS NULL;
END;
