ALTER TABLE stickers ADD COLUMN usage_count INTEGER NOT NULL DEFAULT 0 CHECK(usage_count >= 0);
CREATE INDEX stickers_usage ON stickers(usage_count DESC, last_used_at DESC);
