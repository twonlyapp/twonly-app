/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use super::messages::queue_encrypted_content;
use crate::api::proto::client::encrypted_content;
use crate::api::proto::client::EncryptedContent;
use crate::api::Server;
use crate::bridge::api::ServerResult;
use crate::context::Context;
use crate::database::app::tables::{
    Contact, Group, GroupHistoryType, InsertGroupHistories, UpdateContact,
};
use crate::error::{Result, TwonlyError};
use crate::user_config::UserConfig;
use encrypted_content::contact_request::Type;
use sqlx::{Sqlite, Transaction};
use std::collections::HashMap;
use std::io::Write as _;
use std::sync::{Arc, Mutex, OnceLock};

static REQUESTED_PROFILES: OnceLock<Mutex<HashMap<i64, i64>>> = OnceLock::new();

pub(crate) async fn check_for_profile_update(
    t: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    content: &EncryptedContent,
) -> Result<()> {
    let Some(sender_profile_counter) = content.sender_profile_counter else {
        return Ok(());
    };

    let current_counter = sqlx::query_scalar!(
        "SELECT sender_profile_counter FROM contacts WHERE user_id = ?",
        from_user_id,
    )
    .fetch_optional(&mut **t)
    .await?
    .unwrap_or(0);

    if content.contact_update.is_some() || sender_profile_counter <= current_counter {
        return Ok(());
    }

    let should_request = {
        let mut requested = REQUESTED_PROFILES
            .get_or_init(|| Mutex::new(HashMap::new()))
            .lock()
            .unwrap();
        let last_requested = requested.get(&from_user_id).copied().unwrap_or(0);

        if sender_profile_counter > last_requested {
            requested.insert(from_user_id, sender_profile_counter);
            true
        } else {
            false
        }
    };

    if should_request {
        queue_encrypted_content(
            t,
            from_user_id,
            EncryptedContent {
                contact_update: Some(encrypted_content::ContactUpdate {
                    r#type: encrypted_content::contact_update::Type::Request as i32,
                    username: None,
                    display_name: None,
                    avatar_svg_compressed: None,
                }),
                ..Default::default()
            },
            true,
        )
        .await?;
    }

    Ok(())
}

pub(crate) async fn handle_contact_request(
    ctx: &Arc<Context>,
    tr: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    request: encrypted_content::ContactRequest,
) -> Result<()> {
    match Type::try_from(request.r#type)? {
        Type::Request => {
            let contact = Contact::get_contact_by_id(tr, from_user_id).await?;

            // Either the contact has accepted the fromUserId already: Then just blindly accept the request.
            // Or the user has also requested fromUserId. This means that both user have requested each other (while been
            // offline for example): In this case the contact can also be accepted blindly.
            let auto_accept = contact.as_ref().is_some_and(|contact| {
                contact.blocked == 0 && (contact.accepted != 0 || contact.requested_by_user != 0)
            });

            if auto_accept {
                UpdateContact::builder()
                    .user_id(from_user_id)
                    .requested(false)
                    .requested_by_user(false)
                    .accepted(true)
                    .deleted_by_user(false)
                    .build()
                    .update(tr)
                    .await?;

                if let Some(contact) = contact {
                    Group::create_direct_chat(ctx, tr, contact).await?;
                }

                queue_encrypted_content(
                    tr,
                    from_user_id,
                    EncryptedContent {
                        contact_request: Some(encrypted_content::ContactRequest {
                            r#type: Type::Accept as i32,
                        }),
                        ..Default::default()
                    },
                    true,
                )
                .await?;
            } else {
                let user = match Server::get_user_by_id(ctx, from_user_id).await? {
                    ServerResult::Ok(u) => u,
                    ServerResult::ErrorCode(code) => {
                        return Err(TwonlyError::Generic(format!(
                            "Failed to get user by id: {}",
                            code
                        )));
                    }
                };

                let username = user
                    .username
                    .ok_or_else(|| TwonlyError::Generic("user response has no username".into()))?;

                UpdateContact::builder()
                    .user_id(from_user_id)
                    .username(String::from_utf8(username)?)
                    .requested(true)
                    .deleted_by_user(false)
                    .build()
                    .insert_on_conflict_update(tr)
                    .await?;
            }
        }
        Type::Accept => {
            let Some(contact) = Contact::get_contact_by_id(tr, from_user_id).await? else {
                return Ok(());
            };

            // An accept is only ours to honour if we actually asked. Keying
            // that off `requested`/`deleted_by_user` instead -- both routine
            // for someone met in a shared group -- dropped real accepts and
            // left the two sides permanently out of step.
            if contact.blocked != 0 || (contact.requested_by_user == 0 && contact.accepted == 0) {
                return Ok(());
            }

            UpdateContact::builder()
                .user_id(from_user_id)
                .requested(false)
                .requested_by_user(false)
                .accepted(true)
                .deleted_by_user(false)
                .build()
                .update(tr)
                .await?;

            Group::create_direct_chat(ctx, tr, contact).await?;
        }
        Type::Reject => {
            UpdateContact::builder()
                .user_id(from_user_id)
                .requested(false)
                .requested_by_user(false)
                .accepted(false)
                .deleted_by_user(true)
                .build()
                .update(tr)
                .await?;
        }
    }
    Ok(())
}

pub(crate) async fn handle_contact_update(
    ctx: &Arc<Context>,
    tr: &mut Transaction<'_, Sqlite>,
    from_user_id: i64,
    sender_profile_counter: Option<i64>,
    update: encrypted_content::ContactUpdate,
) -> Result<()> {
    if update.r#type == encrypted_content::contact_update::Type::Request as i32 {
        let user = UserConfig::load_required_from(ctx)?;

        let avatar_svg_compressed = user
            .avatar_svg
            .as_deref()
            .map(|avatar| {
                let mut encoder =
                    flate2::write::GzEncoder::new(Vec::new(), flate2::Compression::default());
                encoder.write_all(avatar.as_bytes())?;
                encoder.finish()
            })
            .transpose()?;

        queue_encrypted_content(
            tr,
            from_user_id,
            EncryptedContent {
                contact_update: Some(encrypted_content::ContactUpdate {
                    r#type: encrypted_content::contact_update::Type::Update as i32,
                    username: Some(user.username),
                    display_name: Some(user.display_name),
                    avatar_svg_compressed,
                }),
                sender_profile_counter: Some(user.avatar_counter),
                ..Default::default()
            },
            true,
        )
        .await?;
        return Ok(());
    }

    if update.r#type != encrypted_content::contact_update::Type::Update as i32 {
        return Err(TwonlyError::Generic("invalid contact update".into()));
    }

    let avatar_svg_compressed = update.avatar_svg_compressed.clone();

    let previous = sqlx::query!(
        "SELECT username, display_name FROM contacts WHERE user_id = ?",
        from_user_id,
    )
    .fetch_optional(&mut **tr)
    .await?;

    if let (Some(previous), Some(username), Some(display_name), Some(_)) = (
        previous,
        update.username.as_ref(),
        update.display_name.as_ref(),
        sender_profile_counter,
    ) {
        if previous.username != *username {
            InsertGroupHistories::new(
                from_user_id,
                &previous.username,
                username,
                GroupHistoryType::UpdatedContactUsername,
            )
            .insert(tr)
            .await?;
        }
        let old_display = previous
            .display_name
            .unwrap_or_else(|| previous.username.clone());
        if old_display != *display_name {
            InsertGroupHistories::new(
                from_user_id,
                &old_display,
                display_name,
                GroupHistoryType::UpdatedContactDisplayName,
            )
            .insert(tr)
            .await?;
        }
    }

    UpdateContact::builder()
        .user_id(from_user_id)
        .maybe_username(update.username)
        .display_name(update.display_name)
        .avatar_svg_compressed(update.avatar_svg_compressed)
        .maybe_sender_profile_counter(sender_profile_counter)
        .build()
        .update(tr)
        .await?;

    if let (Some(profile_counter), Some(avatar)) =
        (sender_profile_counter, avatar_svg_compressed.as_deref())
    {
        if let Err(error) = crate::services::notifications::notification_avatar_path(
            ctx,
            from_user_id,
            profile_counter,
            Some(avatar),
        ) {
            tracing::warn!(from_user_id, %error, "failed to render updated contact avatar");
        }
    }

    Ok(())
}
