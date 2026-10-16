-- A story item is a hidden message row in the 1:1 chat: one per recipient on
-- the sender, all sharing one media file, and one per received item on the
-- receiver. Upload, receipts and opened tracking stay on the message path;
-- chats only show a story row once someone saved it, and unsaved story rows
-- are purged 24 hours after the sender's timestamp instead of by the chat
-- deletion timer.
ALTER TABLE messages ADD COLUMN is_story INTEGER NOT NULL DEFAULT 0
    CHECK (is_story IN (0, 1));
CREATE INDEX idx_messages_story ON messages(is_story, created_at)
    WHERE is_story = 1;

-- Contact groups whose members receive stories sent to that group.
ALTER TABLE contact_groups ADD COLUMN share_stories INTEGER NOT NULL DEFAULT 0
    CHECK (share_stories IN (0, 1));
