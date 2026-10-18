-- The chat list follows every chat entry, including app announcements and
-- widget media. Both Rust and Dart insert rows, so record activity here rather
-- than relying on each feature's transport handler to remember it.
-- Unsaved stories are hidden from the conversation and do not count.
UPDATE groups
SET last_message_exchange = MAX(last_message_exchange, COALESCE((
    SELECT MAX(MIN(messages.created_at, CAST(strftime('%s','now') AS INTEGER)))
    FROM messages
    WHERE messages.group_id = groups.group_id
      AND (messages.is_story = 0 OR messages.media_stored = 1)
), last_message_exchange));

CREATE TRIGGER chat_message_activity
AFTER INSERT ON messages
WHEN NEW.is_story = 0 OR NEW.media_stored = 1
BEGIN
    UPDATE groups
    SET last_message_exchange = MAX(last_message_exchange,
        MIN(NEW.created_at, CAST(strftime('%s','now') AS INTEGER))),
        deleted_content = 0
    WHERE group_id = NEW.group_id;
END;
