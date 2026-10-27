-- Seek the newest media in each chat without traversing text-only history.
CREATE INDEX idx_messages_chat_media
ON messages(group_id, created_at DESC, message_id DESC, media_id)
WHERE media_id IS NOT NULL AND (is_story = 0 OR media_stored = 1);

-- Webxdc cards inherit their effective opened state from their latest activity.
-- Keep all cards as candidates; the chat_messages view applies that state.
-- This index also serves the chat-list media query's unopened branch.
CREATE INDEX idx_messages_chat_unopened
ON messages(created_at DESC, message_id DESC, media_id)
WHERE opened_at IS NULL OR type = 'webxdcApp';

-- Include the deterministic tie-breaker in the existing history index. The
-- SQLCipher SQLite planner otherwise sorts candidates before applying LIMIT,
-- which can still traverse a whole chat even after removing the window query.
DROP INDEX idx_messages_group_id_created_at;
CREATE INDEX idx_messages_group_id_created_at
ON messages(group_id, created_at, message_id);
