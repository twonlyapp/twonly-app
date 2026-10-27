-- Database deletion commits before removing files. The queue also survives a
-- crash between those steps; rolling back a caller transaction rolls it back.
CREATE TABLE pending_media_file_removals (
    media_id TEXT NOT NULL PRIMARY KEY,
    media_type TEXT NOT NULL
);
