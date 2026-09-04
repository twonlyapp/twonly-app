-- The store drops revocation, gains per-language descriptions, and lets an app
-- move to a newer version when it is started.
--
-- `webxdc_apps` is rebuilt rather than altered. It is a cache of the catalog,
-- so the next refresh fills it again, and rebuilding says what the table is
-- now in one piece instead of leaving the shape to be read as a diff.
DROP TABLE webxdc_apps;

-- Catalog metadata mirrored from the API.
--
-- A cache, but not a disposable one: a refresh keeps the rows an instance on
-- this device points at, even once the store stops offering them. Unpublishing
-- an app takes it out of the store and nothing more -- it keeps working where
-- it was already downloaded, and the card in the chat keeps its name and icon.
CREATE TABLE webxdc_apps (
    app_id TEXT NOT NULL,
    version INTEGER NOT NULL,
    name TEXT NOT NULL,
    source_code_url TEXT,
    -- One short line per language, as a JSON object keyed by language tag:
    -- `{"en": "...", "de": "..."}`. The catalog carries every translation, so
    -- which one a device shows is decided here and never asked for.
    description TEXT NOT NULL DEFAULT '{}',
    icon BLOB,
    bundle_sha256 TEXT NOT NULL,
    bundle_bytes INTEGER NOT NULL,
    -- Whether the last catalog we saw still offered this version. Rows kept for
    -- an instance after the store dropped them are `0`: they may still be
    -- started, but the store must not offer them for placing into a new chat.
    published INTEGER NOT NULL DEFAULT 1 CHECK (published IN (0, 1)),
    cached_at INTEGER NOT NULL,
    PRIMARY KEY (app_id, version)
);

-- `webxdc_instances.bundle_sha256` keeps its meaning but not its lifetime: it is
-- re-pinned when the app is started and the store has published a newer
-- version, and never in between. An update lands between two runs of an app, so
-- a catalog change still cannot swap the code out from under a game that is
-- being played.
