use crate::database::app::patch::*;
use flutter_rust_bridge::frb;

#[derive(Debug, Clone, PartialEq, sqlx::FromRow)]
#[frb(name = "StoredMessage")]

pub struct StoredMessage {
    pub group_id: String,
    pub message_id: String,
    /// Current game move's receipt identity; the card's message ID stays fixed.
    pub activity_message_id: Option<String>,
    /// Protocol author, retained when a game's displayed player changes.
    pub original_sender_id: Option<i64>,
    pub sender_id: Option<i64>,
    pub r#type: String,
    pub content: Option<String>,
    pub media_id: Option<String>,
    pub additional_message_data: Option<Vec<u8>>,
    pub media_stored: bool,
    pub media_reopened: bool,
    pub download_token: Option<Vec<u8>>,
    pub quotes_message_id: Option<String>,
    pub is_deleted_from_sender: bool,
    pub is_widget_media: bool,
    pub is_story: bool,
    #[frb(name = "openedAtSeconds")]
    pub opened_at: Option<i64>,
    #[frb(name = "openedByAllSeconds")]
    pub opened_by_all: Option<i64>,
    #[frb(name = "createdAtSeconds")]
    pub created_at: i64,
    #[frb(name = "modifiedAtSeconds")]
    pub modified_at: Option<i64>,
    #[frb(name = "ackByUserSeconds")]
    pub ack_by_user: Option<i64>,
    #[frb(name = "ackByServerSeconds")]
    pub ack_by_server: Option<i64>,
}

#[derive(Debug, Clone, Default)]

pub struct MessagePatch {
    pub group_id: Option<String>,
    pub message_id: Option<String>,
    pub sender_id: Option<NullableInt>,
    pub r#type: Option<String>,
    pub content: Option<NullableText>,
    pub media_id: Option<NullableText>,
    pub additional_message_data: Option<NullableBytes>,
    pub media_stored: Option<bool>,
    pub media_reopened: Option<bool>,
    pub download_token: Option<NullableBytes>,
    pub quotes_message_id: Option<NullableText>,
    pub is_deleted_from_sender: Option<bool>,
    pub is_widget_media: Option<bool>,
    pub is_story: Option<bool>,
    pub opened_at: Option<NullableInt>,
    pub opened_by_all: Option<NullableInt>,
    pub created_at: Option<i64>,
    pub modified_at: Option<NullableInt>,
    pub ack_by_user: Option<NullableInt>,
    pub ack_by_server: Option<NullableInt>,
}

#[derive(Debug, Clone, PartialEq, Eq, sqlx::FromRow)]
#[frb(name = "MessageAction")]

pub struct MessageAction {
    pub message_id: String,
    pub contact_id: i64,
    #[frb(name = "typeName")]
    pub r#type: String,
    #[frb(name = "actionAtSeconds")]
    pub action_at: i64,
}

#[derive(Debug, Clone, Default)]

pub struct MessageActionPatch {
    pub message_id: Option<String>,
    pub contact_id: Option<i64>,
    pub r#type: Option<String>,
    pub action_at: Option<i64>,
}

#[derive(Debug, Clone, PartialEq, Eq, sqlx::FromRow)]
#[frb(name = "MessageHistory")]

pub struct MessageHistory {
    pub id: i64,
    pub message_id: String,
    pub contact_id: Option<i64>,
    pub content: Option<String>,
    #[frb(name = "createdAtSeconds")]
    pub created_at: i64,
}

#[derive(Debug, Clone, Default)]

pub struct MessageHistoryPatch {
    pub id: Option<i64>,
    pub message_id: Option<String>,
    pub contact_id: Option<NullableInt>,
    pub content: Option<NullableText>,
    pub created_at: Option<i64>,
}

#[derive(Debug, Clone, Copy)]

pub enum MessageFilter {
    Unopened,
    MediaUnopened,
    Last,
    LatestByGroup,
    Page,
    Ids,
    MediaIds,
}

#[derive(Debug, Clone)]
#[frb]

pub struct MessageQuery {
    pub filter: MessageFilter,
    pub group_id: Option<String>,
    #[frb(default = "const []")]
    pub ids: Vec<String>,
    #[frb(default = 100)]
    pub limit: i64,
    pub before: Option<i64>,
    pub before_message_id: Option<String>,
    pub now_ms: i64,
}

#[derive(Debug, Clone, PartialEq)]

pub struct MessageActionsWithContacts {
    pub actions: Vec<MessageAction>,
    pub contacts: Vec<crate::database::app::contacts::table::Contact>,
}
