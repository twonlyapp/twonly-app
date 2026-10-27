-- Frozen from the historical Drift upgrade; do not edit.

CREATE TABLE IF NOT EXISTS "labels" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "name" TEXT NOT NULL,
    "text_color" INTEGER NOT NULL,
    "background_color" INTEGER NOT NULL,
    "created_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
);

CREATE TABLE IF NOT EXISTS "contact_labels" (
    "contact_id" INTEGER NOT NULL REFERENCES contacts(user_id)ON DELETE CASCADE,
    "label_id" INTEGER NOT NULL REFERENCES labels(id)ON DELETE CASCADE,
    PRIMARY KEY(contact_id, label_id)
);
