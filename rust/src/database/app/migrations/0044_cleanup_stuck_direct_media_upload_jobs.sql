-- A cached slot with a durable job is still owned by that upload. Preserve
-- its media, recipient scope and request files for normal reconciliation.
UPDATE direct_media_upload_slots SET state = 'reserved'
WHERE state = 'cached'
  AND attachment_id IN (SELECT attachment_id FROM direct_media_upload_jobs);

-- Migrations run before preparation starts. Unowned reservations left by a
-- terminated process are safe to return to the cache.
UPDATE direct_media_upload_slots SET state = 'cached'
WHERE state = 'reserved'
  AND attachment_id NOT IN (SELECT attachment_id FROM direct_media_upload_jobs);
