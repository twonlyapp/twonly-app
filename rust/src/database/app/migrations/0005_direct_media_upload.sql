CREATE TABLE direct_media_upload_slots (
    attachment_id TEXT NOT NULL PRIMARY KEY,
    expires_at INTEGER NOT NULL,
    maximum_object_bytes INTEGER NOT NULL,
    upload_url TEXT NOT NULL,
    upload_fields_json TEXT NOT NULL,
    capability BLOB NOT NULL,
    state TEXT NOT NULL DEFAULT 'cached'
        CHECK (state IN ('cached', 'reserved', 'consumed', 'abandoned')),
    created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
);
CREATE INDEX direct_media_upload_slots_usable_idx
    ON direct_media_upload_slots(state, expires_at);

CREATE TABLE direct_media_upload_jobs (
    attachment_id TEXT NOT NULL PRIMARY KEY
        REFERENCES direct_media_upload_slots(attachment_id) ON DELETE CASCADE,
    media_id TEXT NOT NULL,
    multipart_path TEXT NOT NULL,
    manifest_path TEXT NOT NULL,
    complete_body_path TEXT NOT NULL,
    native_descriptor_json TEXT NOT NULL,
    state TEXT NOT NULL DEFAULT 'prepared'
        CHECK (state IN ('prepared', 'scheduled', 'waiting_for_server', 'ready', 'failed')),
    expires_at INTEGER NOT NULL,
    created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
    updated_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
);
