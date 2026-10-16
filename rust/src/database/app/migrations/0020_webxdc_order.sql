-- Retain the server catalog order when showing cached apps offline.
ALTER TABLE webxdc_apps ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0;
