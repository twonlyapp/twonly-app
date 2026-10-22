use crate::database::app::contacts::table::Contact;
use crate::database::app::patch::NullableText;
use flutter_rust_bridge::frb;

#[derive(Debug, Clone, PartialEq, Eq, sqlx::FromRow)]
#[frb(name = "UserDiscoveryAnnouncedUser")]

pub struct UserDiscoveryAnnouncedUser {
    pub announced_user_id: i64,
    pub announced_public_key: Vec<u8>,
    pub public_id: i64,
    pub username: Option<String>,
    pub was_shown_to_the_user: bool,
    pub is_hidden: bool,
    pub was_asked_friends: bool,
}

#[derive(Debug, Clone, PartialEq, Eq, sqlx::FromRow)]
#[frb(name = "UserDiscoveryUserRelation")]

pub struct UserDiscoveryUserRelation {
    pub announced_user_id: i64,
    pub from_contact_id: i64,
    #[frb(name = "publicKeyVerifiedTimestampSeconds")]
    pub public_key_verified_timestamp: Option<i64>,
}

#[derive(Debug, Clone, PartialEq, Eq, sqlx::FromRow)]
#[frb(name = "UserDiscoveryOwnPromotion")]

pub struct UserDiscoveryOwnPromotion {
    pub version_id: i64,
    pub contact_id: i64,
    pub promotion: Vec<u8>,
}

#[derive(Debug, Clone, PartialEq, Eq, sqlx::FromRow)]
#[frb(name = "UserDiscoveryOtherPromotion")]

pub struct UserDiscoveryOtherPromotion {
    pub from_contact_id: i64,
    pub promotion_id: i64,
    pub public_id: i64,
    pub threshold: i64,
    pub announcement_share: Vec<u8>,
    #[frb(name = "publicKeyVerifiedTimestampSeconds")]
    pub public_key_verified_timestamp: Option<i64>,
}

#[derive(Debug, Clone, PartialEq, Eq, sqlx::FromRow)]
#[frb(name = "UserDiscoveryShare")]

pub struct UserDiscoveryShare {
    pub share_id: i64,
    pub share: Vec<u8>,
    pub contact_id: Option<i64>,
}

#[derive(Debug, Clone, PartialEq, Eq)]

pub struct DiscoverySuggestions {
    pub users: Vec<UserDiscoveryAnnouncedUser>,
    pub relations: Vec<UserDiscoveryUserRelation>,
    pub contacts: Vec<Contact>,
}

#[derive(Debug, Clone, Default)]

pub struct UserDiscoveryAnnouncedUserPatch {
    pub announced_user_id: Option<i64>,
    pub announced_public_key: Option<Vec<u8>>,
    pub public_id: Option<i64>,
    pub username: Option<NullableText>,
    pub was_shown_to_the_user: Option<bool>,
    pub is_hidden: Option<bool>,
    pub was_asked_friends: Option<bool>,
}
