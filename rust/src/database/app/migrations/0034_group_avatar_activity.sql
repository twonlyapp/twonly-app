-- Preserve activity even after old messages expire. Repair the missing Rust
-- receive updates from messages still present at migration time.
UPDATE group_members
SET last_message = MAX(COALESCE(last_message, 0), (
    SELECT MAX(MIN(messages.created_at, CAST(strftime('%s','now') AS INTEGER)))
    FROM messages
    WHERE messages.group_id = group_members.group_id
      AND messages.sender_id = group_members.contact_id
      AND messages.type IN ('text', 'media')
      AND messages.is_story = 0 AND messages.is_widget_media = 0
))
WHERE EXISTS (
    SELECT 1 FROM messages
    WHERE messages.group_id = group_members.group_id
      AND messages.sender_id = group_members.contact_id
      AND messages.type IN ('text', 'media')
      AND messages.is_story = 0 AND messages.is_widget_media = 0
);

-- Both Rust and Dart insert messages. Keeping activity in the same transaction
-- covers text, media and stickers regardless of which runtime receives them.
CREATE TRIGGER group_member_message_activity
AFTER INSERT ON messages
WHEN NEW.sender_id IS NOT NULL AND NEW.type IN ('text', 'media')
     AND NEW.is_story = 0 AND NEW.is_widget_media = 0
BEGIN
    UPDATE group_members
    SET last_message = MAX(COALESCE(last_message, 0),
        MIN(NEW.created_at, CAST(strftime('%s','now') AS INTEGER)))
    WHERE group_id = NEW.group_id AND contact_id = NEW.sender_id;
END;
