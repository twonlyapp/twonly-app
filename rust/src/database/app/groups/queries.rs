use super::table::*;
use crate::database::app::contacts;
use crate::error::Result;
use sqlx::SqliteConnection;

pub async fn get(connection: &mut SqliteConnection, id: &str) -> Result<Option<Group>> {
    Ok(sqlx::query_as!(
        Group,
        r#"
            SELECT
            group_id AS "group_id!",
                    is_group_admin AS "is_group_admin!: bool",
                    is_direct_chat AS "is_direct_chat!: bool",
                    pinned AS "pinned!: bool",
                    archived AS "archived!: bool",
                    joined_group AS "joined_group!: bool",
                    left_group AS "left_group!: bool",
                    deleted_content AS "deleted_content!: bool",
                    state_version_id AS "state_version_id!",
                    state_encryption_key AS "state_encryption_key?",
                    my_group_private_key AS "my_group_private_key?",
                    group_name AS "group_name!",
                    draft_message AS "draft_message?",
                    total_media_counter AS "total_media_counter!",
                    also_best_friend AS "also_best_friend!: bool",
                    delete_messages_after_milliseconds AS "delete_messages_after_milliseconds!",
                    created_at AS "created_at!",
                    last_message_send AS "last_message_send?",
                    last_message_received AS "last_message_received?",
                    last_flame_counter_change AS "last_flame_counter_change?",
                    last_flame_sync AS "last_flame_sync?",
                    flame_counter AS "flame_counter!",
                    max_flame_counter AS "max_flame_counter!",
                    max_flame_counter_from AS "max_flame_counter_from?",
                    last_message_exchange AS "last_message_exchange!"
                FROM groups WHERE group_id = ?
        "#,
        id,
    )
    .fetch_optional(connection)
    .await?)
}

pub async fn list(connection: &mut SqliteConnection, input: &GroupQuery) -> Result<Vec<Group>> {
    // Each expansion contains only SQL literals; SQLx checks every filter at build
    // time.
    macro_rules! select {
        ($tail:literal $(, $arg:expr)* $(,)?) => {
            sqlx::query_as!(
                Group,
                r#"
                    SELECT g.group_id AS "group_id!",
                        g.is_group_admin AS "is_group_admin!: bool",
                        g.is_direct_chat AS "is_direct_chat!: bool",
                        g.pinned AS "pinned!: bool",
                        g.archived AS "archived!: bool",
                        g.joined_group AS "joined_group!: bool",
                        g.left_group AS "left_group!: bool",
                        g.deleted_content AS "deleted_content!: bool",
                        g.state_version_id AS "state_version_id!",
                        g.state_encryption_key AS "state_encryption_key?",
                        g.my_group_private_key AS "my_group_private_key?",
                        g.group_name AS "group_name!",
                        g.draft_message AS "draft_message?",
                        g.total_media_counter AS "total_media_counter!",
                        g.also_best_friend AS "also_best_friend!: bool",
                        g.delete_messages_after_milliseconds AS "delete_messages_after_milliseconds!",
                        g.created_at AS "created_at!",
                        g.last_message_send AS "last_message_send?",
                        g.last_message_received AS "last_message_received?",
                        g.last_flame_counter_change AS "last_flame_counter_change?",
                        g.last_flame_sync AS "last_flame_sync?",
                        g.flame_counter AS "flame_counter!",
                        g.max_flame_counter AS "max_flame_counter!",
                        g.max_flame_counter_from AS "max_flame_counter_from?",
                        g.last_message_exchange AS "last_message_exchange!"
                    FROM groups g
                "# + $tail,
                $($arg),*
            ).fetch_all(&mut *connection).await?
        };
    }

    Ok(match input.filter {
        GroupFilter::All => select!(
            r#"
                ORDER BY rowid
            "#
        ),
        GroupFilter::ShareImage => select!(
            r#"
                WHERE left_group = 0 AND deleted_content = 0 ORDER BY rowid
            "#
        ),
        GroupFilter::WidgetShare => select!(
            r#"
                WHERE is_direct_chat = 1 AND left_group = 0 AND deleted_content = 0 AND EXISTS (SELECT 1
                FROM group_members gm JOIN contacts c ON c.user_id = gm.contact_id WHERE gm.group_id = g.group_id
                AND c.widget_sharing_allowed = 1) ORDER BY rowid
            "#
        ),
        GroupFilter::ChatList => select!(
            r#"
                WHERE deleted_content = 0 ORDER BY last_message_exchange DESC, group_id
            "#
        ),
        GroupFilter::StartNewChat => select!(
            r#"
                WHERE is_direct_chat = 0 ORDER BY group_name, group_id
            "#
        ),
        GroupFilter::Direct => select!(
            r#"
                WHERE is_direct_chat = 1 ORDER BY rowid
            "#
        ),
        GroupFilter::DirectContact => select!(
            r#"
                WHERE is_direct_chat = 1 AND EXISTS (SELECT 1 FROM group_members gm WHERE gm.group_id = g.group_id
                AND gm.contact_id = ?) ORDER BY rowid
            "#,
            input.contact_id
        ),
        GroupFilter::NonDirectForContact => select!(
            r#"
                WHERE is_direct_chat = 0 AND EXISTS (SELECT 1 FROM group_members gm WHERE gm.group_id = g.group_id
                AND gm.contact_id = ? AND (gm.member_state IS NULL OR gm.member_state != 'leftGroup'))
                ORDER BY rowid
            "#,
            input.contact_id
        ),
        GroupFilter::Id => select!(
            r#"
                WHERE group_id = ? ORDER BY rowid
            "#,
            input.group_id.as_deref()
        ),
    })
}

pub async fn members(
    connection: &mut SqliteConnection, input: &GroupMembersQuery,
) -> Result<Vec<GroupMember>> {
    macro_rules! select {
        ($predicate:literal $(, $arg:expr)* $(,)?) => {
            if input.order_for_chats {
                sqlx::query_as!(GroupMember, r#"
                    SELECT group_id AS "group_id!",
                    contact_id AS "contact_id!",
                    member_state AS "member_state?",
                    group_public_key AS "group_public_key?",
                    last_chat_opened AS "last_chat_opened?",
                    last_type_indicator AS "last_type_indicator?",
                    last_message AS "last_message?",
                    created_at AS "created_at!" FROM group_members WHERE
                "# + $predicate + r#"
                    AND (? = 0 OR member_state IS NULL OR member_state != 'leftGroup') AND (? = 0
                    OR last_type_indicator IS NOT NULL) ORDER BY group_id, last_message DESC, contact_id
                "#, $($arg,)* input.active_only, input.typing_only).fetch_all(connection).await?
            } else {
                sqlx::query_as!(GroupMember, r#"
                    SELECT group_id AS "group_id!",
                    contact_id AS "contact_id!",
                    member_state AS "member_state?",
                    group_public_key AS "group_public_key?",
                    last_chat_opened AS "last_chat_opened?",
                    last_type_indicator AS "last_type_indicator?",
                    last_message AS "last_message?",
                    created_at AS "created_at!" FROM group_members WHERE
                "# + $predicate + r#"
                    AND (? = 0 OR member_state IS NULL OR member_state != 'leftGroup') AND (? = 0
                    OR last_type_indicator IS NOT NULL) ORDER BY rowid
                "#, $($arg,)* input.active_only, input.typing_only).fetch_all(connection).await?
            }
        };
    }

    Ok(match (&input.group_id, input.contact_id) {
        (Some(group), Some(contact)) => select!("group_id = ? AND contact_id = ?", group, contact),
        (Some(group), None) => select!("group_id = ?", group),
        (None, Some(contact)) => select!("contact_id = ?", contact),
        (None, None) => select!("1"),
    })
}

pub async fn members_with_contacts(
    connection: &mut SqliteConnection, input: &GroupMembersQuery,
) -> Result<GroupMembersWithContacts> {
    let members = members(connection, input).await?;

    let ids = members.iter().map(|m| m.contact_id).collect();

    let contacts = contacts::queries::list(
        connection,
        &contacts::table::ContactQuery {
            filter: contacts::table::ContactFilter::Ids,
            ids,
            username: None,
            username2: None,
            required_send_images: 0,
            manual_approval: false,
        },
    )
    .await?;

    Ok(GroupMembersWithContacts { members, contacts })
}

pub async fn history(
    connection: &mut SqliteConnection, group: &str, since: Option<i64>,
) -> Result<Vec<GroupHistory>> {
    Ok(sqlx::query_as!(
        GroupHistory,
        r#"
            SELECT
            group_history_id AS "group_history_id!",
                    group_id AS "group_id!",
                    contact_id AS "contact_id?",
                    affected_contact_id AS "affected_contact_id?",
                    old_group_name AS "old_group_name?",
                    new_group_name AS "new_group_name?",
                    new_delete_messages_after_milliseconds AS "new_delete_messages_after_milliseconds?",
                    type AS "type!",
                    action_at AS "action_at!"
                FROM group_histories
                WHERE group_id = ?
                    AND (? IS NULL
                        OR action_at >= ?
                )
                ORDER BY action_at,
                    rowid
        "#,
        group,
        since,
        since,
    )
    .fetch_all(connection)
    .await?)
}

pub async fn total_media(connection: &mut SqliteConnection) -> Result<i64> {
    Ok(sqlx::query_scalar!(
        r#"
            SELECT COALESCE(SUM(total_media_counter),0) AS "value!"
            FROM groups
        "#,
    )
    .fetch_one(connection)
    .await?)
}

pub async fn chat_list_contacts(connection: &mut SqliteConnection) -> Result<Vec<ChatListContact>> {
    Ok(sqlx::query_as!(
        ChatListContact,
        r#"SELECT gm.group_id, c.user_id, c.username, c.display_name, c.nick_name,
                  (c.avatar_svg_compressed IS NOT NULL AND length(c.avatar_svg_compressed) > 0)
                    AS "has_svg_avatar!: bool",
                  c.sender_profile_counter, c.prefer_photo_avatar AS "prefer_photo_avatar?: bool",
                  c.account_deleted AS "account_deleted!: bool"
           FROM group_members gm JOIN contacts c ON c.user_id = gm.contact_id
           ORDER BY gm.group_id, gm.last_message DESC, gm.contact_id"#,
    )
    .fetch_all(connection)
    .await?)
}
