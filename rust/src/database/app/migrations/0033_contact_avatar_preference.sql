ALTER TABLE contacts ADD COLUMN prefer_photo_avatar INTEGER
    CHECK(prefer_photo_avatar IN (0, 1));
