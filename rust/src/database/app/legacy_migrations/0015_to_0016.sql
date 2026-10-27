-- Frozen from the historical Drift upgrade; do not edit.

ALTER TABLE "media_files"
   
    ADD COLUMN "has_thumbnail" INTEGER NOT NULL DEFAULT 0 CHECK (has_thumbnail IN (0, 1));

ALTER TABLE "media_files" ADD COLUMN "size_in_bytes" INTEGER NULL;
