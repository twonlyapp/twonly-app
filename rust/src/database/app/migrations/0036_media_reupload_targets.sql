-- Keep reuploads scoped to the original message as well as the requesting
-- contact. Jobs retain their snapshot so an older upload cannot clear a newer
-- request when it finishes.
ALTER TABLE media_files ADD COLUMN reupload_targets TEXT;
ALTER TABLE direct_media_upload_jobs ADD COLUMN reupload_targets TEXT;
ALTER TABLE direct_media_upload_jobs ADD COLUMN reupload_requested_by TEXT;
