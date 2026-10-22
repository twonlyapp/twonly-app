-- Preserve the update log, but keep only its newest automatic chat announcement.
CREATE INDEX idx_webxdc_updates_announcements
    ON webxdc_updates(instance_id, received_at DESC, serial DESC)
    WHERE info IS NOT NULL;

DELETE FROM messages
WHERE type = 'text' AND message_id IN (
    SELECT old.message_id || '-info'
    FROM webxdc_updates AS old
    WHERE old.info IS NOT NULL AND old.message_id != (
        SELECT latest.message_id FROM webxdc_updates AS latest
        WHERE latest.instance_id = old.instance_id AND latest.info IS NOT NULL
        ORDER BY latest.received_at DESC, latest.serial DESC LIMIT 1
    )
);

UPDATE messages
SET created_at = MAX(created_at, COALESCE((
    SELECT announcement.created_at
    FROM webxdc_updates AS latest
    JOIN messages AS announcement ON announcement.message_id = latest.message_id || '-info'
    WHERE latest.instance_id = messages.message_id AND latest.info IS NOT NULL
    ORDER BY latest.received_at DESC, latest.serial DESC LIMIT 1
), created_at))
WHERE type = 'webxdcApp';
