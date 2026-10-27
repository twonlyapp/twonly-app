-- Frozen from the historical Drift upgrade; do not edit.

ALTER TABLE "media_files" ADD COLUMN "created_at_month" TEXT NULL;

ALTER TABLE "media_files" ADD COLUMN "is_favorite" INTEGER NOT NULL DEFAULT 0 CHECK (is_favorite IN (0, 1));

ALTER TABLE "media_files"
   
    ADD COLUMN "has_crop_analyzed" INTEGER NOT NULL DEFAULT 0 CHECK (has_crop_analyzed IN (0, 1));
