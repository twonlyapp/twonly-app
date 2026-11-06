/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::proto::client::{self as proto, encrypted_content};
use crate::context::Context;
use crate::database::app::groups::native::Group;
use crate::database::app::groups::vacation::VacationWindow;
use crate::database::app::key_verifications::table::{KeyVerificationType, NewKeyVerification};
use crate::database::app::messages::native::{Message, MessageType, NewMessage};
use crate::error::Result;
use crate::services::webxdc::WebxdcService;
use crate::utils::milliseconds_to_seconds;
use prost::Message as ProstMessage;
use sqlx::{Sqlite, Transaction};

pub(crate) async fn handle_additional_data_message(
    ctx: &std::sync::Arc<Context>, tr: &mut Transaction<'_, Sqlite>, from_user_id: i64,
    group_id: &str, message: encrypted_content::AdditionalDataMessage,
) -> Result<()> {
    Message::check_message_owner(tr, &message.sender_message_id, from_user_id).await?;

    let timestamp = milliseconds_to_seconds(message.timestamp);

    // Additional metadata is optional. Keep accepting the containing message if
    // it is malformed or a handler cannot complete.
    let data = match message.additional_message_data.as_deref() {
        Some(bytes) => match proto::AdditionalMessageData::decode(bytes) {
            Ok(data) => Some(data),
            Err(error) => {
                tracing::warn!("failed to decode additional message data: {error}");

                None
            }
        },
        None => None,
    };

    if let Some(data) = data.as_ref() {
        if data.r#type == proto::additional_message_data::Type::LiveLocation as i32 {
            if message.hidden {
                if let Some(location) = data.live_location.as_ref() {
                    crate::services::live_location::incoming(tr, group_id, from_user_id, location)
                        .await?;
                }
            }

            return Ok(());
        } else if data.webxdc_sync_request.is_some() {
            let ctx = ctx.clone();

            let group_id = group_id.to_owned();

            crate::database::lifecycle::spawn(async move {
                if let Err(error) = WebxdcService::new(&ctx)
                    .send_one_time_apps_to_contact(&group_id, from_user_id)
                    .await
                {
                    tracing::warn!(%error, "could not answer one-time app sync request");
                }
            });
        } else if let Some(sync) = data.webxdc_sync.as_ref() {
            WebxdcService::handle_sync_chunk(tr, group_id, from_user_id, sync).await?;
        } else if let Some(update) = data.webxdc_update.as_ref() {
            // App state belongs in the instance's own log, which is ordered,
            // gap free, and outside the reach of the chat's deletion timer.
            WebxdcService::handle_incoming_update(
                tr,
                &message.sender_message_id,
                group_id,
                from_user_id,
                update,
                timestamp,
                crate::user_config::UserConfig::load_required_from(ctx)?.user_id,
            )
            .await?;
        } else if let Some(vacation) = data.vacation.as_ref() {
            apply_vacation(ctx, tr, from_user_id, group_id, vacation).await?;
        } else if let Err(error) = verify_shared_contacts(ctx, tr, from_user_id, data).await {
            tracing::warn!("failed to handle additional message data: {error}");
        }
    }

    // A hidden message carries state a feature exchanges rather than something
    // a person sent. The feature may have created a visible announcement above;
    // that row updates chat activity through the database trigger. The hidden
    // payload itself needs no additional chat row.
    if message.hidden {
        return Ok(());
    }

    NewMessage::builder()
        .group_id(group_id)
        .message_id(&message.sender_message_id)
        .message_type(MessageType::Other(&message.r#type))
        .created_at(timestamp)
        .sender_id(from_user_id)
        .maybe_additional_message_data(message.additional_message_data.as_deref())
        .ack_by_server(chrono::Utc::now().timestamp())
        .build()
        .insert(tr)
        .await?;

    if let Some(app) = data.as_ref().and_then(|data| data.webxdc_app.as_ref()) {
        // Recorded only once the card exists: the instance is keyed by that
        // message and cascades from it.
        WebxdcService::handle_incoming_app(tr, &message.sender_message_id, group_id, app).await?;
    }

    Group::increase_last_message_exchange(tr, group_id, timestamp).await?;

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::database::app::key_verifications::{queries, writes};
    use crate::services::groups::vacation::{vacation_data, VACATION_MESSAGE_TYPE};

    /// A friend's vacation freezes only the streak of the chat it belongs to:
    /// the friend's direct chat with us. The same announcement anywhere else
    /// still shows up, but freezes nothing.
    #[tokio::test]

    async fn a_vacation_is_taken_only_from_the_senders_direct_chat() -> Result<()> {
        let directory = tempfile::tempdir()?;

        let data_dir = directory.path().join("data");

        std::fs::create_dir_all(data_dir.join("keyvalue"))?;

        std::fs::write(
            data_dir.join("keyvalue/user.json"),
            serde_json::to_vec(&crate::user_config::UserConfig {
                user_id: 1,
                username: "me".into(),
                display_name: "Me".into(),
                is_user_discovery_enabled: false,
                ..Default::default()
            })
            .unwrap(),
        )?;

        let ctx = Context::init_for_testing(directory.path().join("db"), data_dir).await?;

        crate::api::ApiRuntime::close(&ctx).await?;

        let database = ctx.app_db.read().await.clone();

        let with_alice = Group::direct_chat_id(1, 7);

        let with_bob = Group::direct_chat_id(1, 8);

        let now = crate::utils::current_time().timestamp();

        let mut tx = database.pool.begin().await?;

        sqlx::query("INSERT INTO contacts(user_id, username) VALUES (7, 'alice'), (8, 'bob')")
            .execute(&mut *tx)
            .await?;

        sqlx::query(
            "INSERT INTO groups(group_id, group_name, is_direct_chat) VALUES (?, 'Alice', 1), \
             (?, 'Bob', 1), ('friends', 'Friends', 0)",
        )
        .bind(&with_alice)
        .bind(&with_bob)
        .execute(&mut *tx)
        .await?;

        sqlx::query(
            "INSERT INTO group_members(group_id, contact_id) VALUES (?, 7), (?, 8), \
             ('friends', 7)",
        )
        .bind(&with_alice)
        .bind(&with_bob)
        .execute(&mut *tx)
        .await?;

        let announce =
            |id: &str, window: VacationWindow| encrypted_content::AdditionalDataMessage {
                sender_message_id: id.into(),
                timestamp: now * 1000,
                r#type: VACATION_MESSAGE_TYPE.into(),
                additional_message_data: Some(vacation_data(&window)),
                hidden: false,
            };

        let window = VacationWindow {
            from: now,
            until: now + 5 * 24 * 3600,
            icon: "✈️".into(),
        };

        for (id, group_id) in [("in-group", "friends"), ("in-bobs-chat", with_bob.as_str())] {
            handle_additional_data_message(
                &ctx,
                &mut tx,
                7,
                group_id,
                announce(id, window.clone()),
            )
            .await?;
        }

        handle_additional_data_message(
            &ctx,
            &mut tx,
            7,
            &with_alice,
            announce("direct", window.clone()),
        )
        .await?;

        let peer_windows: Vec<(String, Option<i64>, Option<i64>, Option<String>)> = sqlx::query_as(
            "SELECT group_id, peer_vacation_from, peer_vacation_until, peer_vacation_icon \
                 FROM groups ORDER BY group_id",
        )
        .fetch_all(&mut *tx)
        .await?;

        for (group_id, from, until, icon) in peer_windows {
            if group_id == with_alice {
                assert_eq!(
                    (from, until, icon.as_deref()),
                    (Some(window.from), Some(window.until), Some("✈️"))
                );
            } else {
                assert_eq!((from, until, icon), (None, None, None), "{group_id}");
            }
        }

        // Every announcement became a chat entry, wherever it was sent.
        let entries: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM messages WHERE type = ?")
            .bind(VACATION_MESSAGE_TYPE)
            .fetch_one(&mut *tx)
            .await?;

        assert_eq!(entries, 3);

        // A forged window is trimmed to a real vacation.
        handle_additional_data_message(
            &ctx,
            &mut tx,
            7,
            &with_alice,
            announce(
                "forged",
                VacationWindow {
                    from: now + 60,
                    until: now + 365 * 24 * 3600,
                    icon: "x".repeat(100),
                },
            ),
        )
        .await?;

        let forged: (i64, i64, String) = sqlx::query_as(
            "SELECT peer_vacation_from, peer_vacation_until, peer_vacation_icon FROM groups \
             WHERE group_id = ?",
        )
        .bind(&with_alice)
        .fetch_one(&mut *tx)
        .await?;

        assert_eq!(
            forged,
            (now + 60, now + 60 + 9 * 24 * 3600, "🏕️".to_owned())
        );

        Ok(())
    }

    #[tokio::test]

    async fn shared_contacts_require_a_personally_verified_sender_and_matching_keys() -> Result<()>
    {
        let directory = tempfile::tempdir()?;
        let ctx =
            Context::init_for_testing(directory.path().join("db"), directory.path().join("data"))
                .await?;
        crate::api::ApiRuntime::close(&ctx).await?;
        let database = ctx.app_db.read().await.clone();
        let signal = ctx.rust_db.read().await.clone();
        sqlx::raw_sql(
            "INSERT INTO signal_identities(name,identity_key,timestamp)
             VALUES ('7',X'01',0),('8',X'02',0),('9',X'03',0);",
        )
        .execute(&signal.pool)
        .await?;
        let mut tx = database.pool.begin().await?;
        sqlx::raw_sql(
            "INSERT INTO contacts(user_id,username) VALUES (7,'sender'),(8,'target'),(9,'other');",
        )
        .execute(&mut *tx)
        .await?;
        let contact = |user_id, key| proto::SharedContact {
            user_id,
            public_identity_key: vec![key],
            display_name: "shared".into(),
        };
        let data = proto::AdditionalMessageData {
            r#type: proto::additional_message_data::Type::Contacts as i32,
            contacts: vec![contact(7, 1), contact(8, 2), contact(8, 2), contact(9, 99)],
            ..Default::default()
        };
        verify_shared_contacts(&ctx, &mut tx, 7, &data).await?;
        assert!(!queries::is_verified(&mut tx, 8).await?);
        writes::insert(&mut tx, 7, "manual", None).await?;
        verify_shared_contacts(&ctx, &mut tx, 7, &data).await?;
        verify_shared_contacts(&ctx, &mut tx, 7, &data).await?;
        assert_eq!(queries::contact(&mut tx, 8).await?.verifications.len(), 1);
        assert_eq!(queries::contact(&mut tx, 7).await?.verifications.len(), 1);
        assert!(!queries::is_verified(&mut tx, 9).await?);
        assert!(!queries::can_attest(&mut tx, 8).await?);
        Ok(())
    }
}

/// A vacation freezes the streak of the direct chat between the sender and
/// us, so it is taken from that chat only. Anywhere else the entry still
/// appears, but changes nothing.
async fn apply_vacation(
    ctx: &Context, tr: &mut Transaction<'_, Sqlite>, from_user_id: i64, group_id: &str,
    vacation: &proto::VacationData,
) -> Result<()> {
    let self_id = crate::user_config::UserConfig::load_required_from(ctx)?.user_id;

    if Group::direct_chat_id(self_id, from_user_id) != group_id {
        tracing::warn!("ignoring a vacation announced outside the sender's direct chat");

        return Ok(());
    }

    let window = VacationWindow::announced(
        milliseconds_to_seconds(vacation.starts_at_ms),
        milliseconds_to_seconds(vacation.ends_at_ms),
        &vacation.icon,
    );

    if !Group::apply_peer_vacation(tr, group_id, &window).await? {
        tracing::info!("ignoring a stale vacation announcement");
    }

    Ok(())
}

async fn verify_shared_contacts(
    ctx: &Context, tr: &mut Transaction<'_, Sqlite>, from_user_id: i64,
    data: &proto::AdditionalMessageData,
) -> Result<()> {
    if data.r#type != proto::additional_message_data::Type::Contacts as i32 {
        return Ok(());
    }

    if !crate::database::app::key_verifications::queries::can_attest(tr, from_user_id).await? {
        return Ok(());
    }

    let signal_database = ctx.rust_db.read().await.clone();

    for contact in &data.contacts {
        if contact.user_id == from_user_id {
            continue;
        }

        if contact.public_identity_key.is_empty() {
            tracing::info!("shared contact carries no public key, skipping verification");

            continue;
        }

        let stored_identity = sqlx::query_scalar!(
            "SELECT identity_key FROM signal_identities WHERE name = ?",
            contact.user_id.to_string(),
        )
        .fetch_optional(&signal_database.pool)
        .await?;

        let Some(stored_identity) = stored_identity else {
            tracing::info!("no public key stored for contact");

            continue;
        };

        if stored_identity != contact.public_identity_key {
            tracing::warn!("shared contact public identity key does not match");

            continue;
        }

        NewKeyVerification::new(
            contact.user_id,
            KeyVerificationType::ContactSharedByVerified,
        )
        .verified_by(from_user_id)
        .insert(tr)
        .await?;

        // Inherited evidence is local to this recipient. Advertising it as a
        // personal verification would launder a second-hand claim into trust.
        tracing::info!("recorded inherited verification from shared additional data");
    }

    Ok(())
}
