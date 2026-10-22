-- Frozen from the historical Drift upgrade; do not edit.

CREATE TABLE IF NOT EXISTS "signal_signed_pre_key_stores" (
    "signed_pre_key_id" INTEGER NOT NULL,
    "signed_pre_key" BLOB NOT NULL,
    "created_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
    PRIMARY KEY(signed_pre_key_id)
);
