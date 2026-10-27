-- Frozen from the historical Drift upgrade; do not edit.

ALTER TABLE "receipts"
   
    ADD COLUMN "will_be_retried_by_media_upload" INTEGER NOT NULL DEFAULT 0 CHECK (will_be_retried_by_media_upload IN (0, 1));
