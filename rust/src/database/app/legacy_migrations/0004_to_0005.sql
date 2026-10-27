-- Frozen from the historical Drift upgrade; do not edit.

ALTER TABLE "receipts" ADD COLUMN "mark_for_retry" INTEGER NULL;

ALTER TABLE "media_files" ADD COLUMN "stored_file_hash" BLOB NULL;
