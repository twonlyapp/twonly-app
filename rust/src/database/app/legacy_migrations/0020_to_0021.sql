-- Frozen from the historical Drift upgrade; do not edit.

ALTER TABLE "contacts" ADD COLUMN "recovery_contacts_secret_share" BLOB NULL;

ALTER TABLE "contacts" ADD COLUMN "recovery_contacts_last_heartbeat" INTEGER NULL;
