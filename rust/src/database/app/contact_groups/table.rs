use flutter_rust_bridge::frb;

#[derive(Clone, Debug, PartialEq, Eq, sqlx::FromRow)]
#[frb]

pub struct ContactGroup {
    pub id: i64,
    pub name: String,
    pub emoji: Option<String>,
    pub text_color: i64,
    pub background_color: i64,
    pub show_as_shortcut: bool,
    pub show_as_label: bool,
    pub share_stories: bool,
    pub usage_counter: i64,
    /// Unix seconds, matching the existing Drift column.
    #[frb(name = "createdAtSeconds")]
    pub created_at: i64,
}

#[derive(Clone, Debug, PartialEq, Eq, sqlx::FromRow)]

pub struct ContactGroupMember {
    pub id: i64,
    pub contact_group_id: i64,
    pub user_id: Option<i64>,
    pub group_id: Option<String>,
}

#[derive(Clone, Debug)]

pub struct ContactGroupInput {
    pub name: String,
    pub emoji: Option<String>,
    pub text_color: i64,
    pub background_color: i64,
    pub show_as_shortcut: bool,
    pub show_as_label: bool,
    pub share_stories: bool,
}

#[derive(Clone, Copy, Debug)]

pub enum ContactGroupFilter {
    All,
    Shortcuts,
    Stories,
    User,
    Group,
}

/// Normalized labels avoid repeating each group's name/style for every member.
#[derive(Clone, Debug, PartialEq, Eq)]

pub struct ContactGroupLabels {
    pub groups: Vec<ContactGroup>,
    pub members: Vec<ContactGroupMember>,
}
