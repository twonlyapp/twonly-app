-- Message rows are inserted by both Rust and Dart. Restore the direct chat
-- in the same transaction so every receive/send path also refreshes the UI.
CREATE TRIGGER direct_chat_message_unarchive
AFTER INSERT ON messages
WHEN NEW.is_story = 0 AND NEW.is_widget_media = 0
BEGIN
    UPDATE groups
    SET archived = 0, deleted_content = 0
    WHERE group_id = NEW.group_id AND is_direct_chat = 1
      AND (archived = 1 OR deleted_content = 1);
END;
