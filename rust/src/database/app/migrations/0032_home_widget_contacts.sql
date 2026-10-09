-- People selected directly in a home-screen widget, independently of groups.
-- Like widget placement, this is device-local and is not included in backups.
CREATE TABLE home_widget_contacts (
    widget_id TEXT NOT NULL REFERENCES home_widgets(widget_id) ON DELETE CASCADE,
    contact_id INTEGER NOT NULL REFERENCES contacts(user_id) ON DELETE CASCADE,
    PRIMARY KEY (widget_id, contact_id)
);
