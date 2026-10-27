-- Frozen from the historical Drift upgrade; do not edit.

CREATE TABLE IF NOT EXISTS "shortcuts" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "emoji" TEXT NOT NULL UNIQUE,
    "usage_counter" INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS "shortcut_members" (
    "shortcut_id" INTEGER NOT NULL REFERENCES shortcuts(id)ON DELETE CASCADE,
    "group_id" TEXT NOT NULL REFERENCES "groups"(group_id)ON DELETE CASCADE,
    PRIMARY KEY(shortcut_id, group_id)
);
