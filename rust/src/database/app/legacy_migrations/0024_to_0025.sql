-- Frozen from the historical Drift upgrade; do not edit.

ALTER TABLE "contacts" ADD COLUMN "signal_version" TEXT NOT NULL DEFAULT 'v1';
