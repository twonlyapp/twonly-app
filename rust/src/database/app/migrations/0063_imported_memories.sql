-- Memories added from another platform through the memories importer page.
-- The importer a memory came from decides which payload `addition` its cloud
-- copy must carry ("import_<importer_id>"); a memory without a row here must
-- carry "app". The app's own re-upload deletes the row.
CREATE TABLE imported_memories (
    media_id TEXT PRIMARY KEY NOT NULL REFERENCES media_files(media_id) ON DELETE CASCADE,
    importer_id TEXT NOT NULL,
    source TEXT NOT NULL
);

-- Imported memories that could not be read, kept for retry and so the user
-- can delete them on purpose. Never deleted automatically.
CREATE TABLE imported_memory_failures (
    media_id TEXT PRIMARY KEY NOT NULL,
    importer_id TEXT,
    reason TEXT NOT NULL,
    permanent INTEGER NOT NULL DEFAULT 0,
    attempts INTEGER NOT NULL DEFAULT 1,
    next_attempt_at INTEGER NOT NULL
);
