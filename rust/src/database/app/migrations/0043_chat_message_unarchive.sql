-- Both send and receive paths insert message rows through Rust and Dart.
-- Any new chat entry restores the conversation, including groups and widget
-- media. Hidden, unsaved story rows do not count as chat messages.
DROP TRIGGER direct_chat_message_unarchive;

CREATE TRIGGER chat_message_unarchive
AFTER INSERT ON messages
WHEN NEW.is_story = 0 OR NEW.media_stored = 1
BEGIN
    UPDATE groups
    SET archived = 0, deleted_content = 0
    WHERE group_id = NEW.group_id
      AND (archived = 1 OR deleted_content = 1);
END;
