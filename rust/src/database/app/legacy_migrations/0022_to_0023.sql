-- Frozen from the historical Drift upgrade; do not edit.

ALTER TABLE "media_files" ADD COLUMN "cloud_state" TEXT NOT NULL DEFAULT 'none';

ALTER TABLE "media_files" ADD COLUMN "blurhash" TEXT NULL;
