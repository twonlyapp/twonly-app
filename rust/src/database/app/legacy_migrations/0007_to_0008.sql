-- Frozen from the historical Drift upgrade; do not edit.

DROP TABLE IF EXISTS "signal_contact_pre_keys";

DROP TABLE IF EXISTS "signal_contact_signed_pre_keys";

CREATE TABLE IF NOT EXISTS "tmp_for_copy_message_histories" (
    "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "message_id" TEXT NOT NULL REFERENCES messages(message_id)ON DELETE CASCADE,
    "contact_id" INTEGER NULL REFERENCES contacts(user_id)ON DELETE CASCADE,
    "content" TEXT NULL,
    "created_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
);

INSERT INTO tmp_for_copy_message_histories (
    "id",
    "message_id",
    "contact_id",
    "content",
    "created_at"
) SELECT
    "id",
    "message_id",
    "contact_id",
    "content",
    "created_at"
FROM "message_histories";

DROP TABLE "message_histories";

ALTER TABLE "tmp_for_copy_message_histories" RENAME TO "message_histories";

CREATE TABLE IF NOT EXISTS "tmp_for_copy_message_actions" (
    "message_id" TEXT NOT NULL REFERENCES messages(message_id)ON DELETE CASCADE,
    "contact_id" INTEGER NOT NULL REFERENCES contacts(user_id)ON DELETE CASCADE,
    "type" TEXT NOT NULL,
    "action_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
    PRIMARY KEY(message_id, contact_id, type)
);

INSERT INTO tmp_for_copy_message_actions (
    "message_id",
    "contact_id",
    "type",
    "action_at"
) SELECT
    "message_id",
    "contact_id",
    "type",
    "action_at"
FROM "message_actions";

DROP TABLE "message_actions";

ALTER TABLE "tmp_for_copy_message_actions" RENAME TO "message_actions";
