CREATE TABLE own_custom_avatar (
    singleton INTEGER NOT NULL PRIMARY KEY CHECK(singleton = 1),
    webp BLOB CHECK(webp IS NULL OR length(webp) BETWEEN 1 AND 131072),
    sha256 BLOB CHECK(sha256 IS NULL OR length(sha256) = 32),
    width INTEGER CHECK(width IS NULL OR width BETWEEN 1 AND 300),
    height INTEGER CHECK(height IS NULL OR height BETWEEN 1 AND 300),
    accepted_contacts_only INTEGER NOT NULL DEFAULT 1 CHECK(accepted_contacts_only IN (0, 1)),
    source_revision INTEGER NOT NULL DEFAULT 0 CHECK(source_revision >= 0),
    CHECK((webp IS NULL AND sha256 IS NULL AND width IS NULL AND height IS NULL) OR
          (webp IS NOT NULL AND sha256 IS NOT NULL AND width IS NOT NULL AND height IS NOT NULL))
);

INSERT INTO own_custom_avatar(singleton) VALUES (1);

CREATE TABLE custom_avatar_publications (
    contact_id INTEGER NOT NULL PRIMARY KEY REFERENCES contacts(user_id) ON DELETE CASCADE,
    publication_counter INTEGER NOT NULL DEFAULT 0 CHECK(publication_counter >= 0),
    visible_source_revision INTEGER,
    shows_photo INTEGER NOT NULL DEFAULT 0 CHECK(shows_photo IN (0, 1))
);

CREATE TABLE received_custom_avatars (
    contact_id INTEGER NOT NULL PRIMARY KEY REFERENCES contacts(user_id) ON DELETE CASCADE,
    applied_counter INTEGER NOT NULL DEFAULT 0 CHECK(applied_counter >= 0),
    webp BLOB CHECK(webp IS NULL OR length(webp) BETWEEN 1 AND 131072),
    sha256 BLOB CHECK(sha256 IS NULL OR length(sha256) = 32),
    width INTEGER CHECK(width IS NULL OR width BETWEEN 1 AND 300),
    height INTEGER CHECK(height IS NULL OR height BETWEEN 1 AND 300),
    CHECK((webp IS NULL AND sha256 IS NULL AND width IS NULL AND height IS NULL) OR
          (webp IS NOT NULL AND sha256 IS NOT NULL AND width IS NOT NULL AND height IS NOT NULL))
);
