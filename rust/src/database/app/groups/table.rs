use crate::database::app::patch::*;
use flutter_rust_bridge::frb;

#[derive(Debug, Clone, PartialEq, sqlx::FromRow)]
#[frb(name = "Group")]

pub struct Group {
    pub group_id: String,
    pub is_group_admin: bool,
    pub is_direct_chat: bool,
    pub pinned: bool,
    pub archived: bool,
    pub joined_group: bool,
    pub left_group: bool,
    pub deleted_content: bool,
    pub state_version_id: i64,
    pub state_encryption_key: Option<Vec<u8>>,
    pub my_group_private_key: Option<Vec<u8>>,
    pub group_name: String,
    pub draft_message: Option<String>,
    pub total_media_counter: i64,
    pub also_best_friend: bool,
    pub delete_messages_after_milliseconds: i64,
    #[frb(name = "createdAtSeconds")]
    pub created_at: i64,
    #[frb(name = "lastMessageSendSeconds")]
    pub last_message_send: Option<i64>,
    #[frb(name = "lastMessageReceivedSeconds")]
    pub last_message_received: Option<i64>,
    #[frb(name = "lastFlameCounterChangeSeconds")]
    pub last_flame_counter_change: Option<i64>,
    #[frb(name = "lastFlameSyncSeconds")]
    pub last_flame_sync: Option<i64>,
    pub flame_counter: i64,
    pub max_flame_counter: i64,
    #[frb(name = "maxFlameCounterFromSeconds")]
    pub max_flame_counter_from: Option<i64>,
    #[frb(name = "lastMessageExchangeSeconds")]
    pub last_message_exchange: i64,
}

#[derive(Debug, Clone, Default)]

pub struct GroupPatch {
    pub group_id: Option<String>,
    pub is_group_admin: Option<bool>,
    pub is_direct_chat: Option<bool>,
    pub pinned: Option<bool>,
    pub archived: Option<bool>,
    pub joined_group: Option<bool>,
    pub left_group: Option<bool>,
    pub deleted_content: Option<bool>,
    pub state_version_id: Option<i64>,
    pub state_encryption_key: Option<NullableBytes>,
    pub my_group_private_key: Option<NullableBytes>,
    pub group_name: Option<String>,
    pub draft_message: Option<NullableText>,
    pub total_media_counter: Option<i64>,
    pub also_best_friend: Option<bool>,
    pub delete_messages_after_milliseconds: Option<i64>,
    pub created_at: Option<i64>,
    pub last_message_send: Option<NullableInt>,
    pub last_message_received: Option<NullableInt>,
    pub last_flame_counter_change: Option<NullableInt>,
    pub last_flame_sync: Option<NullableInt>,
    pub flame_counter: Option<i64>,
    pub max_flame_counter: Option<i64>,
    pub max_flame_counter_from: Option<NullableInt>,
    pub last_message_exchange: Option<i64>,
}

#[derive(Debug, Clone, PartialEq, Eq, sqlx::FromRow)]
#[frb(name = "GroupMember")]

pub struct GroupMember {
    pub group_id: String,
    pub contact_id: i64,
    #[frb(name = "memberStateName")]
    pub member_state: Option<String>,
    pub group_public_key: Option<Vec<u8>>,
    #[frb(name = "lastChatOpenedSeconds")]
    pub last_chat_opened: Option<i64>,
    #[frb(name = "lastTypeIndicatorSeconds")]
    pub last_type_indicator: Option<i64>,
    #[frb(name = "lastMessageSeconds")]
    pub last_message: Option<i64>,
    #[frb(name = "createdAtSeconds")]
    pub created_at: i64,
}

#[derive(Debug, Clone, Default)]

pub struct GroupMemberPatch {
    pub group_id: Option<String>,
    pub contact_id: Option<i64>,
    pub member_state: Option<NullableText>,
    pub group_public_key: Option<NullableBytes>,
    pub last_chat_opened: Option<NullableInt>,
    pub last_type_indicator: Option<NullableInt>,
    pub last_message: Option<NullableInt>,
    pub created_at: Option<i64>,
}

#[derive(Debug, Clone, PartialEq, Eq, sqlx::FromRow)]
#[frb(name = "GroupHistory")]

pub struct GroupHistory {
    pub group_history_id: String,
    pub group_id: String,
    pub contact_id: Option<i64>,
    pub affected_contact_id: Option<i64>,
    pub old_group_name: Option<String>,
    pub new_group_name: Option<String>,
    pub new_delete_messages_after_milliseconds: Option<i64>,
    #[frb(name = "typeName")]
    pub r#type: String,
    #[frb(name = "actionAtSeconds")]
    pub action_at: i64,
}

#[derive(Debug, Clone, Default)]

pub struct GroupHistoryPatch {
    pub group_history_id: Option<String>,
    pub group_id: Option<String>,
    pub contact_id: Option<NullableInt>,
    pub affected_contact_id: Option<NullableInt>,
    pub old_group_name: Option<NullableText>,
    pub new_group_name: Option<NullableText>,
    pub new_delete_messages_after_milliseconds: Option<NullableInt>,
    pub r#type: Option<String>,
    pub action_at: Option<i64>,
}

#[derive(Debug, Clone, Copy)]

pub enum GroupFilter {
    All,
    ShareImage,
    WidgetShare,
    ChatList,
    StartNewChat,
    Direct,
    DirectContact,
    NonDirectForContact,
    Id,
}

#[derive(Debug, Clone)]

pub struct GroupQuery {
    pub filter: GroupFilter,
    pub group_id: Option<String>,
    pub contact_id: Option<i64>,
}

#[derive(Debug, Clone)]
#[frb]

pub struct GroupMembersQuery {
    pub group_id: Option<String>,
    pub contact_id: Option<i64>,
    #[frb(default = true)]
    pub active_only: bool,
    #[frb(default = false)]
    pub typing_only: bool,
    #[frb(default = false)]
    pub order_for_chats: bool,
}

#[derive(Debug, Clone, PartialEq)]

pub struct GroupMembersWithContacts {
    pub members: Vec<GroupMember>,
    pub contacts: Vec<crate::database::app::contacts::table::Contact>,
}
