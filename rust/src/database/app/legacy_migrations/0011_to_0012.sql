-- Frozen from the historical Drift upgrade; do not edit.

CREATE TABLE IF NOT EXISTS "verification_tokens" (
    "token_id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "token" BLOB NOT NULL,
    "created_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
);

CREATE TABLE IF NOT EXISTS "key_verifications" (
    "verification_id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "contact_id" INTEGER NOT NULL REFERENCES contacts(user_id)ON DELETE CASCADE,
    "type" TEXT NOT NULL,
    "created_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
);

CREATE TABLE IF NOT EXISTS "user_discovery_announced_users" (
    "announced_user_id" INTEGER NOT NULL,
    "announced_public_key" BLOB NOT NULL,
    "public_id" INTEGER NOT NULL UNIQUE,
    "username" TEXT NULL,
    "was_shown_to_the_user" INTEGER NOT NULL DEFAULT 0 CHECK (was_shown_to_the_user IN (0, 1)),
    "is_hidden" INTEGER NOT NULL DEFAULT 0 CHECK (is_hidden IN (0, 1)),
    PRIMARY KEY(announced_user_id)
);

CREATE TABLE IF NOT EXISTS "user_discovery_own_promotions" (
    "version_id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "contact_id" INTEGER NOT NULL REFERENCES contacts(user_id)ON DELETE CASCADE,
    "promotion" BLOB NOT NULL
);

CREATE TABLE IF NOT EXISTS "user_discovery_other_promotions" (
    "from_contact_id" INTEGER NOT NULL REFERENCES contacts(user_id)ON DELETE CASCADE,
    "promotion_id" INTEGER NOT NULL,
    "public_id" INTEGER NOT NULL,
    "threshold" INTEGER NOT NULL,
    "announcement_share" BLOB NOT NULL,
    "public_key_verified_timestamp" INTEGER NULL,
    PRIMARY KEY(from_contact_id, public_id)
);

CREATE TABLE IF NOT EXISTS "user_discovery_shares" (
    "share_id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    "share" BLOB NOT NULL,
    "contact_id" INTEGER NULL REFERENCES contacts(user_id)ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS "user_discovery_user_relations" (
    "announced_user_id" INTEGER NOT NULL REFERENCES user_discovery_announced_users(announced_user_id)ON DELETE CASCADE,
    "from_contact_id" INTEGER NOT NULL REFERENCES contacts(user_id)ON DELETE CASCADE,
    "public_key_verified_timestamp" INTEGER NULL,
    PRIMARY KEY(announced_user_id, from_contact_id)
);

ALTER TABLE "contacts" ADD COLUMN "user_discovery_version" BLOB NULL;

ALTER TABLE "contacts" ADD COLUMN "media_received_counter" INTEGER NOT NULL DEFAULT 0;

ALTER TABLE "contacts" ADD COLUMN "media_send_counter" INTEGER NOT NULL DEFAULT 0;

ALTER TABLE "contacts"
   
    ADD COLUMN "user_discovery_excluded" INTEGER NOT NULL DEFAULT 0 CHECK (user_discovery_excluded IN (0, 1));

ALTER TABLE "contacts"
   
    ADD COLUMN "user_discovery_manual_approved" INTEGER NULL DEFAULT 0 CHECK (user_discovery_manual_approved IN (0, 1));
