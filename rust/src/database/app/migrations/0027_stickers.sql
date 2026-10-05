CREATE TABLE stickers (
    content_hash TEXT NOT NULL PRIMARY KEY CHECK(length(content_hash) = 64),
    webp BLOB NOT NULL CHECK(length(webp) BETWEEN 1 AND 131072),
    width INTEGER NOT NULL CHECK(width BETWEEN 1 AND 300),
    height INTEGER NOT NULL CHECK(height BETWEEN 1 AND 300),
    created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER)),
    last_used_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', 'now') AS INTEGER))
);

CREATE INDEX stickers_last_used_at ON stickers(last_used_at DESC);
