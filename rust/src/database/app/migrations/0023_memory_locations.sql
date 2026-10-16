-- Optional capture location for a locally stored Memory. Coordinates never
-- leave the device through the messaging path; they are only written to a
-- gallery export after the user explicitly enables the feature.
ALTER TABLE media_files ADD COLUMN location_latitude REAL;
ALTER TABLE media_files ADD COLUMN location_longitude REAL;
ALTER TABLE media_files ADD COLUMN location_accuracy REAL;
ALTER TABLE media_files ADD COLUMN location_status TEXT
    CHECK (location_status IN ('pending', 'resolved', 'timedOut'));
ALTER TABLE media_files ADD COLUMN location_deadline_at INTEGER;
ALTER TABLE media_files ADD COLUMN gallery_export_pending INTEGER NOT NULL DEFAULT 0
    CHECK (gallery_export_pending IN (0, 1));

CREATE INDEX idx_media_files_pending_location
    ON media_files(location_status, location_deadline_at)
    WHERE location_status = 'pending';

