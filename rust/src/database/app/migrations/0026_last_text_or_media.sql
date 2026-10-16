-- When this chat last carried a text or media message, in either direction.
-- Unlike last_message_exchange it ignores reactions, shared data and the
-- chat's creation, and unlike the messages themselves it outlives the chat's
-- deletion timer. A story is announced only between people who wrote to each
-- other within the last two weeks, and this is what that is measured by.
ALTER TABLE groups ADD COLUMN last_text_or_media_at INTEGER;

-- Existing chats start from what is still known: the newest text or media
-- message left, and the media timestamps the flames keep.
UPDATE groups SET last_text_or_media_at = NULLIF(MAX(
    COALESCE((SELECT MAX(created_at) FROM messages
              WHERE messages.group_id = groups.group_id
                AND messages.type IN ('text', 'media')
                AND messages.is_story = 0), 0),
    COALESCE(last_message_send, 0),
    COALESCE(last_message_received, 0)
), 0);
