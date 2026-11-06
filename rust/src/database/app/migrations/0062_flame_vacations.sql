-- "On Vacation" freezes a streak between `from` and `until`. Each side of a
-- direct chat can be on vacation independently, so the user's own window and
-- the peer's announced window are kept apart: ending one must not shorten the
-- other.
ALTER TABLE groups ADD COLUMN vacation_from INTEGER;
ALTER TABLE groups ADD COLUMN vacation_until INTEGER;
ALTER TABLE groups ADD COLUMN vacation_icon TEXT;
ALTER TABLE groups ADD COLUMN peer_vacation_from INTEGER;
ALTER TABLE groups ADD COLUMN peer_vacation_until INTEGER;
ALTER TABLE groups ADD COLUMN peer_vacation_icon TEXT;
