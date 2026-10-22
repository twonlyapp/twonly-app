-- Frozen from the historical Drift upgrade; do not edit.

ALTER TABLE "contacts"
   
    ADD COLUMN "recovery_is_trusted_friend" INTEGER NOT NULL DEFAULT 0 CHECK (recovery_is_trusted_friend IN (0, 1));

ALTER TABLE "contacts" ADD COLUMN "recovery_last_heartbeat" INTEGER NULL;

ALTER TABLE "contacts" ADD COLUMN "recovery_secret_share" BLOB NULL;
