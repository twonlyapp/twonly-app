-- Webxdc apps are distributed through the twonly store rather than sent
-- between clients: a message carries only the app id and the version its
-- sender pinned, and the bundle itself is fetched from the API server.

-- Catalog metadata mirrored from the API. Purely a cache: rows may be replaced
-- wholesale on every refresh, so nothing outside this table may reference it.
CREATE TABLE webxdc_apps (
    app_id TEXT NOT NULL,
    version INTEGER NOT NULL,
    name TEXT NOT NULL,
    source_code_url TEXT,
    icon BLOB,
    bundle_sha256 TEXT NOT NULL,
    bundle_bytes INTEGER NOT NULL,
    revoked INTEGER NOT NULL DEFAULT 0 CHECK (revoked IN (0, 1)),
    cached_at INTEGER NOT NULL,
    PRIMARY KEY (app_id, version)
);

-- One row per app placed into a chat.
--
-- `origin_token` is the host the bundle is served from inside the webview. The
-- browser's origin model is what isolates one instance's localStorage and
-- IndexedDB from every other instance, so the token is per instance rather
-- than per app, and is never derived from anything a peer controls.
--
-- Addresses handed to the app are derived from the instance id, which every
-- participant knows and nobody outside the chat does. That keeps one peer's
-- address identical on every device without sending anything, while staying
-- uncorrelatable with the same user in another chat.
--
-- `bundle_sha256` is pinned when the instance first starts. The catalog is
-- consulted to resolve it, but never again afterwards: a later catalog change
-- must not swap the code out from under a game that is already being played.
CREATE TABLE webxdc_instances (
    instance_id TEXT NOT NULL PRIMARY KEY REFERENCES messages(message_id) ON DELETE CASCADE,
    group_id TEXT NOT NULL REFERENCES groups(group_id) ON DELETE CASCADE,
    app_id TEXT NOT NULL,
    version INTEGER NOT NULL,
    bundle_sha256 TEXT,
    origin_token TEXT NOT NULL UNIQUE,
    summary TEXT,
    document TEXT,
    created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
    last_update_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
);

CREATE INDEX idx_webxdc_instances_group_id ON webxdc_instances(group_id);

-- The update log, deliberately kept out of `messages`.
--
-- `purgeMessageTable` deletes message rows individually once the chat's
-- deletion timer has passed. An update log purged that way loses a prefix or
-- an arbitrary subset of its entries, and an app replaying serials with holes
-- in them rebuilds a state that is silently wrong rather than obviously empty.
-- Instances are therefore deleted whole, by the webxdc code, or not at all --
-- the same exemption stored media has from that purge.
--
-- `serial` is local to this device: assigned on arrival, gap free, and never
-- reused, which is what `setUpdateListener` promises the app.
CREATE TABLE webxdc_updates (
    instance_id TEXT NOT NULL REFERENCES webxdc_instances(instance_id) ON DELETE CASCADE,
    serial INTEGER NOT NULL,
    message_id TEXT NOT NULL UNIQUE,
    sender_id INTEGER REFERENCES contacts(user_id),
    payload TEXT NOT NULL,
    info TEXT,
    href TEXT,
    received_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
    PRIMARY KEY (instance_id, serial)
);
