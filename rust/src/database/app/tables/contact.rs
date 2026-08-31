/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::{
    context::Context,
    error::{Result, TwonlyError},
    user_config::UserConfig,
};
use sqlx::{Sqlite, Transaction};

#[derive(sqlx::FromRow, Debug, Clone)]
pub struct Contact {
    pub user_id: i64,
    pub username: String,
    pub display_name: Option<String>,
    pub nick_name: Option<String>,
    pub avatar_svg_compressed: Option<Vec<u8>>,
    pub sender_profile_counter: i64,
    pub accepted: i64,
    pub deleted_by_user: i64,
    pub requested: i64,
    pub blocked: i64,
    pub verified: i64,
    pub account_deleted: i64,
    pub created_at: i64,
    pub signal_version: String,
    pub user_discovery_version: Option<Vec<u8>>,
    pub user_discovery_excluded: i64,
    pub user_discovery_manual_approved: Option<i64>,
    pub recovery_is_trusted_friend: i64,
    pub recovery_last_heartbeat: Option<i64>,
    pub recovery_secret_share: Option<Vec<u8>>,
    pub recovery_contacts_secret_share: Option<Vec<u8>>,
    pub recovery_contacts_last_heartbeat: Option<i64>,
    pub recovery_contacts_threshold: Option<i64>,
    pub ask_for_friend_promotions: Option<i64>,
    pub media_send_counter: i64,
    pub media_received_counter: i64,
}

#[derive(bon::Builder)]
pub struct UpdateContact {
    user_id: i64,
    username: Option<String>,
    display_name: Option<Option<String>>,
    avatar_svg_compressed: Option<Option<Vec<u8>>>,
    sender_profile_counter: Option<i64>,
    signal_version: Option<String>,
    #[builder(with = |value: bool| value as i64)]
    accepted: Option<i64>,
    #[builder(with = |value: bool| value as i64)]
    requested: Option<i64>,
    #[builder(with = |value: bool| value as i64)]
    deleted_by_user: Option<i64>,
    #[builder(with = |value: bool| value as i64)]
    blocked: Option<i64>,
    #[builder(default)]
    only_if_not_requested: bool,
}

impl UpdateContact {
    pub async fn update(self, tr: &mut Transaction<'_, Sqlite>) -> Result<()> {
        Contact::update(tr, self).await
    }

    pub async fn insert_on_conflict_update(self, tr: &mut Transaction<'_, Sqlite>) -> Result<()> {
        Contact::insert_on_conflict_update(tr, self).await
    }
}

impl Contact {
    pub fn get_group_name(&self) -> String {
        self.display_name
            .clone()
            .unwrap_or_else(|| self.username.clone())
    }

    pub async fn update(t: &mut Transaction<'_, Sqlite>, contact: UpdateContact) -> Result<()> {
        let update_display_name = contact.display_name.is_some();
        let display_name = contact.display_name.flatten();
        let update_avatar = contact.avatar_svg_compressed.is_some();
        let avatar_svg_compressed = contact.avatar_svg_compressed.flatten();
        sqlx::query!(
            r#"
            UPDATE contacts SET
                username = COALESCE(?, username),
                display_name = CASE WHEN ? THEN ? ELSE display_name END,
                avatar_svg_compressed = CASE WHEN ? THEN ? ELSE avatar_svg_compressed END,
                sender_profile_counter = COALESCE(?, sender_profile_counter),
                signal_version = COALESCE(?, signal_version),
                accepted = COALESCE(?, accepted),
                requested = COALESCE(?, requested),
                deleted_by_user = COALESCE(?, deleted_by_user),
                blocked = COALESCE(?, blocked)
            WHERE user_id = ? AND (? = 0 OR requested = 0)
            "#,
            contact.username,
            update_display_name,
            display_name,
            update_avatar,
            avatar_svg_compressed,
            contact.sender_profile_counter,
            contact.signal_version,
            contact.accepted,
            contact.requested,
            contact.deleted_by_user,
            contact.blocked,
            contact.user_id,
            contact.only_if_not_requested,
        )
        .execute(&mut **t)
        .await?;

        Ok(())
    }

    pub async fn insert_on_conflict_update(
        t: &mut Transaction<'_, Sqlite>,
        contact: UpdateContact,
    ) -> Result<()> {
        sqlx::query!(
            r#"
            INSERT INTO contacts(user_id, username, signal_version, accepted, requested, deleted_by_user, blocked)
            VALUES (?, COALESCE(?, '[Unknown]'), COALESCE(?, 'v2'), COALESCE(?, 0), COALESCE(?, 0), COALESCE(?, 0), COALESCE(?, 0))
            ON CONFLICT(user_id) DO UPDATE SET
                username = COALESCE(?, contacts.username),
                signal_version = COALESCE(?, contacts.signal_version),
                accepted = COALESCE(?, contacts.accepted),
                requested = COALESCE(?, contacts.requested),
                deleted_by_user = COALESCE(?, contacts.deleted_by_user),
                blocked = COALESCE(?, contacts.blocked)
            WHERE ? = 0 OR contacts.requested = 0
            "#,
            contact.user_id,
            contact.username,
            contact.signal_version,
            contact.accepted,
            contact.requested,
            contact.deleted_by_user,
            contact.blocked,
            contact.username,
            contact.signal_version,
            contact.accepted,
            contact.requested,
            contact.deleted_by_user,
            contact.blocked,
            contact.only_if_not_requested,
        )
        .execute(&mut **t)
        .await?;

        Ok(())
    }

    pub async fn get_contact_by_id(
        t: &mut Transaction<'_, Sqlite>,
        user_id: i64,
    ) -> Result<Option<Self>> {
        let contact = sqlx::query_as!(Self, "SELECT * FROM contacts WHERE user_id = ?", user_id)
            .fetch_optional(&mut **t)
            .await?;

        Ok(contact)
    }

    pub async fn update_ask_for_friend_promotions(
        t: &mut Transaction<'_, Sqlite>,
        user_id: i64,
    ) -> Result<()> {
        sqlx::query!(
            r#"
            UPDATE contacts
            SET ask_for_friend_promotions = COALESCE(ask_for_friend_promotions, 1)
            WHERE user_id = ?
            "#,
            user_id,
        )
        .execute(&mut **t)
        .await?;
        Ok(())
    }

    pub async fn is_user_discovery_allowed(
        context: &Context,
        t: &mut Transaction<'_, Sqlite>,
        contact_id: i64,
    ) -> Result<bool> {
        let config = UserConfig::load_required_from(context)?;
        let contact = sqlx::query!(
            r#"SELECT accepted, blocked, media_send_counter, user_discovery_excluded,
                      user_discovery_manual_approved
               FROM contacts WHERE user_id = ?"#,
            contact_id,
        )
        .fetch_optional(&mut **t)
        .await?;
        Ok(contact.is_some_and(|contact| {
            contact.accepted != 0
                && contact.blocked == 0
                && contact.media_send_counter >= config.required_send_images
                && contact.user_discovery_excluded == 0
                && (!config.user_discovery_requires_manual_approval
                    || contact.user_discovery_manual_approved.unwrap_or(0) != 0)
        }))
    }

    pub async fn exists(t: &mut Transaction<'_, Sqlite>, user_id: i64) -> Result<bool> {
        let exists = sqlx::query_scalar!(
            "SELECT EXISTS(SELECT 1 FROM contacts WHERE user_id = ?)",
            user_id
        )
        .fetch_one(&mut **t)
        .await?
            != 0;
        Ok(exists)
    }

    pub async fn ensure_exists(t: &mut Transaction<'_, Sqlite>, user_id: i64) -> Result<()> {
        if !Self::exists(t, user_id).await? {
            return Err(TwonlyError::Generic(format!(
                "contact {user_id} does not exist"
            )));
        }

        Ok(())
    }
}
