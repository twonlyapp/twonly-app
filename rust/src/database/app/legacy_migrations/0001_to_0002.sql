-- Frozen from the historical Drift upgrade; do not edit.

ALTER TABLE "messages"
   
    ADD COLUMN "media_reopened" INTEGER NOT NULL DEFAULT (0) CHECK ("media_reopened" IN (0, 1));

ALTER TABLE "media_files" DROP COLUMN "reopen_by_contact";
