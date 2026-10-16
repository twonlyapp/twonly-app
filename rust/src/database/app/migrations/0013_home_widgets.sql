-- Home-screen widget placement is device-local and deliberately excluded from
-- application backups.
CREATE TABLE home_widgets (
    widget_id TEXT NOT NULL PRIMARY KEY,
    platform TEXT NOT NULL,
    created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
);

CREATE TABLE home_widget_groups (
    widget_id TEXT NOT NULL REFERENCES home_widgets(widget_id) ON DELETE CASCADE,
    contact_group_id INTEGER NOT NULL REFERENCES contact_groups(id) ON DELETE CASCADE,
    PRIMARY KEY (widget_id, contact_group_id)
);

-- What a peer has granted us, and what we most recently announced to them.
ALTER TABLE contacts ADD COLUMN widget_sharing_allowed INTEGER NOT NULL DEFAULT 0
    CHECK (widget_sharing_allowed IN (0, 1));
ALTER TABLE contacts ADD COLUMN widget_sharing_granted INTEGER NOT NULL DEFAULT 0
    CHECK (widget_sharing_granted IN (0, 1));

-- Widget-only media is downloaded normally but never appears in chat.
ALTER TABLE media_files ADD COLUMN is_widget_media INTEGER NOT NULL DEFAULT 0
    CHECK (is_widget_media IN (0, 1));
ALTER TABLE messages ADD COLUMN is_widget_media INTEGER NOT NULL DEFAULT 0
    CHECK (is_widget_media IN (0, 1));
CREATE INDEX idx_messages_widget_media ON messages(is_widget_media, created_at)
    WHERE is_widget_media = 1;
