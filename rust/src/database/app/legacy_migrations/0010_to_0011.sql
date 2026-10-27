-- Frozen from the historical Drift upgrade; do not edit.

ALTER TABLE "group_members" ADD COLUMN "last_chat_opened" INTEGER NULL;

ALTER TABLE "group_members" ADD COLUMN "last_type_indicator" INTEGER NULL;
