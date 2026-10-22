-- Frozen from the historical Drift upgrade; do not edit.

CREATE TABLE IF NOT EXISTS "tmp_for_copy_group_histories" (
    "group_history_id" TEXT NOT NULL,
    "group_id" TEXT NOT NULL REFERENCES "groups" (group_id) ON DELETE CASCADE,
    "contact_id" INTEGER NULL REFERENCES contacts (user_id),
    "affected_contact_id" INTEGER NULL,
    "old_group_name" TEXT NULL,
    "new_group_name" TEXT NULL,
    "new_delete_messages_after_milliseconds" INTEGER NULL,
    "type" TEXT NOT NULL,
    "action_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
    PRIMARY KEY(group_history_id)
);

INSERT INTO tmp_for_copy_group_histories (
    "group_history_id",
    "group_id",
    "contact_id",
    "affected_contact_id",
    "old_group_name",
    "new_group_name",
    "new_delete_messages_after_milliseconds",
    "type",
    "action_at"
) SELECT
    "group_history_id",
    "group_id",
    "contact_id",
    "affected_contact_id",
    "old_group_name",
    "new_group_name",
    "new_delete_messages_after_milliseconds",
    "type",
    "action_at"
FROM "group_histories";

DROP TABLE "group_histories";

ALTER TABLE "tmp_for_copy_group_histories" RENAME TO "group_histories";
