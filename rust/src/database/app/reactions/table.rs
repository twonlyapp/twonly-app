use crate::database::app::contacts::table::Contact;
use flutter_rust_bridge::frb;

#[derive(Debug, Clone, PartialEq, Eq, sqlx::FromRow)]
#[frb(name = "StoredReaction")]

pub struct StoredReaction {
    pub message_id: String,
    pub emoji: String,
    pub sender_id: Option<i64>,
    #[frb(name = "createdAtSeconds")]
    pub created_at: i64,
}

#[derive(Debug, Clone, PartialEq, Eq, sqlx::FromRow)]

pub struct GroupReaction {
    pub group_id: String,
    #[sqlx(flatten)]
    pub reaction: StoredReaction,
}

#[derive(Debug, Clone, PartialEq, Eq)]

pub struct ReactionsWithContacts {
    pub reactions: Vec<StoredReaction>,
    pub contacts: Vec<Contact>,
}
