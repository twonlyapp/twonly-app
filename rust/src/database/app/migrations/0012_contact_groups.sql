CREATE TABLE contact_groups (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    emoji TEXT,
    text_color INTEGER NOT NULL,
    background_color INTEGER NOT NULL,
    show_as_shortcut INTEGER NOT NULL DEFAULT 0 CHECK (show_as_shortcut IN (0, 1)),
    show_as_label INTEGER NOT NULL DEFAULT 1 CHECK (show_as_label IN (0, 1)),
    usage_counter INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
);

CREATE TABLE contact_group_members (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    contact_group_id INTEGER NOT NULL REFERENCES contact_groups(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES contacts(user_id) ON DELETE CASCADE,
    group_id TEXT REFERENCES groups(group_id) ON DELETE CASCADE,
    UNIQUE (contact_group_id, user_id),
    UNIQUE (contact_group_id, group_id),
    CHECK ((user_id IS NOT NULL) != (group_id IS NOT NULL))
);

-- Existing labels remain visible contact groups with their current styling.
INSERT INTO contact_groups (
    id,
    name,
    emoji,
    text_color,
    background_color,
    show_as_shortcut,
    show_as_label,
    usage_counter,
    created_at
)
SELECT
    id,
    name,
    NULL,
    text_color,
    background_color,
    0,
    1,
    0,
    created_at
FROM labels;

INSERT OR IGNORE INTO contact_group_members (contact_group_id, user_id, group_id)
SELECT label_id, contact_id, NULL
FROM contact_labels;

-- Existing shortcuts become shortcut-only contact groups. Their emoji is
-- retained and their label appearance has a transparent background.
INSERT INTO contact_groups (
    id,
    name,
    emoji,
    text_color,
    background_color,
    show_as_shortcut,
    show_as_label,
    usage_counter,
    created_at
)
SELECT
    COALESCE((SELECT MAX(id) FROM labels), 0) + id,
    emoji,
    emoji,
    4278190080,
    0,
    1,
    0,
    usage_counter,
    CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)
FROM shortcuts;

-- A shortcut's direct-chat target is represented by its contact user id.
INSERT OR IGNORE INTO contact_group_members (contact_group_id, user_id, group_id)
SELECT
    COALESCE((SELECT MAX(id) FROM labels), 0) + sm.shortcut_id,
    gm.contact_id,
    NULL
FROM shortcut_members sm
INNER JOIN groups g ON g.group_id = sm.group_id
INNER JOIN group_members gm ON gm.group_id = g.group_id
WHERE g.is_direct_chat = 1;

-- Only actual, non-direct groups are represented by group id.
INSERT OR IGNORE INTO contact_group_members (contact_group_id, user_id, group_id)
SELECT
    COALESCE((SELECT MAX(id) FROM labels), 0) + sm.shortcut_id,
    NULL,
    sm.group_id
FROM shortcut_members sm
INNER JOIN groups g ON g.group_id = sm.group_id
WHERE g.is_direct_chat = 0;

DROP TABLE contact_labels;
DROP TABLE shortcut_members;
DROP TABLE labels;
DROP TABLE shortcuts;
