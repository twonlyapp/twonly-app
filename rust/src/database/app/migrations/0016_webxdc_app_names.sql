-- Names are translated, the way descriptions already are.
--
-- `name` keeps its meaning: the one name every row has, which the store orders
-- by and which a reader falls back to when the app was not translated into
-- their language. The translations sit beside it in the same shape as
-- `description`, so choosing one stays a decision this device makes.
ALTER TABLE webxdc_apps
    ADD COLUMN name_translations TEXT NOT NULL DEFAULT '{}';
