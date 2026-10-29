/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::proto::client::{self as proto, encrypted_content};
use crate::context::Context;
use crate::database::app::groups::native::Group;
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
