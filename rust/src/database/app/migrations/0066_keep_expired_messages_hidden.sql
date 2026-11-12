-- A chat hides an opened message once opened_at is older than the chat's
-- deletion timer, but keeps the row until the purge removes it. Raising the
-- timer moved that cutoff back, so messages that had already disappeared came
-- back into the chat. Move the open time of those messages behind the new
-- cutoff so they stay gone. Moving opened_by_all with it lets the purge remove
-- them on its next run. A NULL opened_by_all stays NULL: the row is kept
-- until every member has opened the message.
CREATE TRIGGER groups_keep_expired_messages_hidden
AFTER UPDATE OF delete_messages_after_milliseconds ON groups
WHEN NEW.delete_messages_after_milliseconds > OLD.delete_messages_after_milliseconds
BEGIN
    UPDATE messages
    SET opened_at = MIN(
            opened_at,
            CAST(strftime('%s', 'now') AS INTEGER)
                - NEW.delete_messages_after_milliseconds / 1000 - 1
        ),
        opened_by_all = CASE WHEN opened_by_all IS NULL THEN NULL ELSE MIN(
            opened_by_all,
            CAST(strftime('%s', 'now') AS INTEGER)
                - NEW.delete_messages_after_milliseconds / 1000 - 1
        ) END
    WHERE group_id = NEW.group_id
        AND opened_at IS NOT NULL
        AND media_stored = 0
        AND type != 'webxdcApp'
        AND opened_at <= CAST(strftime('%s', 'now') AS INTEGER)
            - OLD.delete_messages_after_milliseconds / 1000;
END;
