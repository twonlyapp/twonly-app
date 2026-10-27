use crate::database::app::contacts::table::Contact;
use crate::database::app::mediafiles::table::MediaFile;
use crate::database::app::messages::table::StoredMessage;

#[derive(Debug, Clone, PartialEq)]

pub struct ReceivedStories {
    pub messages: Vec<StoredMessage>,
    pub files: Vec<MediaFile>,
}

#[derive(Debug, Clone, PartialEq, Eq, sqlx::FromRow)]

pub struct OwnStorySummary {
    pub media_id: String,
    pub posted_at: i64,
    pub recipient_count: i64,
    pub viewer_count: i64,
}

#[derive(Debug, Clone, PartialEq)]

pub struct OwnStories {
    pub items: Vec<OwnStorySummary>,
    pub files: Vec<MediaFile>,
}

#[derive(Debug, Clone, PartialEq, Eq, sqlx::FromRow)]

pub struct StoryViewerLink {
    pub message_id: String,
    pub contact_id: i64,
    pub opened_at: Option<i64>,
    pub received_at: Option<i64>,
}

#[derive(Debug, Clone, PartialEq)]

pub struct StoryViewers {
    pub links: Vec<StoryViewerLink>,
    pub messages: Vec<StoredMessage>,
    pub contacts: Vec<Contact>,
}
