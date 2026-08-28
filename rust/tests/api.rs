#[path = "api/tester.rs"]
mod tester;
#[path = "api/user_discovery.rs"]
mod user_discovery;

use rust_lib_twonly::api::Server;
use rust_lib_twonly::bridge::api::ApiConnectionState;
use rust_lib_twonly::bridge::api::ServerResult;
use rust_lib_twonly::database::app::tables::Group;
use rust_lib_twonly::services::contacts::ContactService;
use rust_lib_twonly::services::groups::GroupService;
use rust_lib_twonly::services::messages::MessageService;
pub(crate) use tester::Tester;

#[tokio::test]
async fn test_connect_to_dev_server() -> anyhow::Result<()> {
    let _ = tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| tracing_subscriber::EnvFilter::new("info")),
        )
        .with_ansi(true)
        .event_format(rust_lib_twonly::log::ShortEventFormatter::ansi())
        .try_init();

    let mut tester_a = {
        let mut tester = Tester::new().await?;
        tester.wait_until(ApiConnectionState::Connected).await?;
        tester.register_and_authenticate().await?;
        tester.wait_until(ApiConnectionState::Authenticated).await?;
        tester
    };
    tracing::info!(tester = "a", user_id = tester_a.user_id, "Tester is ready");

    let tester_b = {
        let mut tester = Tester::new().await?;
        tester.wait_until(ApiConnectionState::Connected).await?;
        tester.register_and_authenticate().await?;
        tester.wait_until(ApiConnectionState::Authenticated).await?;
        tester
    };
    tracing::info!(tester = "b", user_id = tester_b.user_id, "Tester is ready");

    let group_id = Group::direct_chat_id(tester_a.user_id, tester_b.user_id);

    //
    // Testing: Contact related messages
    //
    {
        // Tester A requests Tester B
        ContactService::new(&tester_a.context)
            .request_by_username(tester_b.username.clone(), true)
            .await?;

        tester_b
            .wait_for_contact_state(tester_a.user_id, false, true)
            .await?;

        // Tester B rejects Tester A
        ContactService::new(&tester_b.context)
            .reject_request(tester_a.user_id, true)
            .await?;

        tester_a
            .wait_for_contact_state(tester_b.user_id, false, false)
            .await?;

        // Tester A requests Tester B again
        ContactService::new(&tester_a.context)
            .request_by_username(tester_b.username.clone(), true)
            .await?;

        tester_b
            .wait_for_contact_state(tester_a.user_id, false, true)
            .await?;

        // Tester B accepts Tester A
        ContactService::new(&tester_b.context)
            .accept_request(tester_a.user_id, true)
            .await?;

        tester_a
            .wait_for_contact_state(tester_b.user_id, true, false)
            .await?;
    }

    //
    // Testing: Profile updates
    //
    {
        // Tester A changes the username
        let new_username = format!(
            "usr_{}",
            &uuid::Uuid::new_v4().to_string().replace("-", "")[..8]
        );

        // 1. This requires an API call
        let res = Server::change_username(&tester_a.context, new_username.clone()).await?;
        match res {
            ServerResult::Ok(_) => {}
            ServerResult::ErrorCode(e) => panic!("change_username failed with error code: {}", e),
        }

        // We also need to update the local UserConfig so send_profile picks it up.
        tester_a.update_username(new_username.clone())?;

        // 2. Instead of directly sending the profile, we send a text message.
        // The sender_profile_counter is incremented in user.json, so the text message
        // will carry a higher counter, prompting Tester B to request a profile update.
        MessageService::new(&tester_a.context)
            .insert_and_send_text(group_id.clone(), "Hello with new profile!".into(), None)
            .await?;

        // 3. Wait until the Tester B username has the new username in the contact table
        tester_b
            .wait_for_contact_username(tester_a.user_id, &new_username)
            .await?;
    }

    //
    // Testing: Text message related messages
    //
    {
        // TesterA -> TesterB: Send a text message
        let message_id = MessageService::new(&tester_a.context)
            .insert_and_send_text(group_id.clone(), "Initial text".into(), None)
            .await?;
        tester_b
            .wait_for_text_message(&message_id, tester_a.user_id, "Initial text")
            .await?;

        // TesterA -> TesterB: Edit this text message
        MessageService::new(&tester_a.context)
            .edit_text(group_id.clone(), message_id.clone(), "Edited text".into())
            .await?;
        tester_b
            .wait_for_text_message(&message_id, tester_a.user_id, "Edited text")
            .await?;

        // TesterA -> TesterB: React to this message
        MessageService::new(&tester_a.context)
            .react(group_id.clone(), message_id.clone(), "👍".into(), false)
            .await?;
        tester_b
            .wait_for_reaction(&message_id, tester_a.user_id, "👍")
            .await?;

        // TesterB -> TesterA: React to this message
        MessageService::new(&tester_b.context)
            .react(group_id.clone(), message_id.clone(), "❤️".into(), false)
            .await?;
        tester_a
            .wait_for_reaction(&message_id, tester_b.user_id, "❤️")
            .await?;

        // TesterB -> TesterA: Delete reaction to this message
        MessageService::new(&tester_b.context)
            .react(group_id.clone(), message_id.clone(), "❤️".into(), true)
            .await?;
        tester_a
            .wait_for_reaction_deleted(&message_id, tester_b.user_id, "❤️")
            .await?;

        // TesterA -> TesterB: Delete this text message
        MessageService::new(&tester_a.context)
            .delete_message(group_id.clone(), message_id.clone())
            .await?;
        tester_b.wait_for_message_deleted(&message_id).await?;
    }

    // Setup tester_c for group and contact-sharing tests.
    let tester_c = {
        let mut tester = Tester::new().await?;
        tester.wait_until(ApiConnectionState::Connected).await?;
        tester.register_and_authenticate().await?;
        tester.wait_until(ApiConnectionState::Authenticated).await?;
        tester
    };
    tracing::info!(tester = "c", user_id = tester_c.user_id, "Tester is ready");

    //
    // Testing: Testing the group
    //
    {
        // Tester A adds Tester C as a contact (request → accept)
        {
            ContactService::new(&tester_a.context)
                .request_by_username(tester_c.username.clone(), true)
                .await?;
            tester_c
                .wait_for_contact_state(tester_a.user_id, false, true)
                .await?;
            ContactService::new(&tester_c.context)
                .accept_request(tester_a.user_id, true)
                .await?;
            tester_a
                .wait_for_contact_state(tester_c.user_id, true, false)
                .await?;
        }

        let group_service_a = GroupService::new(&tester_a.context);

        // 1. Create a group with tester_a, tester_b, tester_c
        let group_name = "Test Group";
        group_service_a
            .create_group(group_name.into(), vec![tester_b.user_id, tester_c.user_id])
            .await?;

        // Find the group_id that tester_a just created (it's the only non-direct-chat group)
        let group_id = {
            let database = tester_a.context.app_db.read().await.clone();
            sqlx::query_scalar!(
                "SELECT group_id FROM groups WHERE is_direct_chat = 0 ORDER BY rowid DESC LIMIT 1"
            )
            .fetch_one(&database.pool)
            .await?
        };
        tracing::info!(group_id, "Group created by tester_a");

        // Wait for tester_b and tester_c to receive the group
        tester_b
            .wait_for_group_exists(&group_id, group_name)
            .await?;
        tester_c
            .wait_for_group_exists(&group_id, group_name)
            .await?;
        tracing::info!("All testers see the group");

        // 2. Send a text message in the group
        let group_msg_id = MessageService::new(&tester_a.context)
            .insert_and_send_text(group_id.clone(), "Hello group!".into(), None)
            .await?;

        tester_b
            .wait_for_text_message(&group_msg_id, tester_a.user_id, "Hello group!")
            .await?;
        tester_c
            .wait_for_text_message(&group_msg_id, tester_a.user_id, "Hello group!")
            .await?;

        tracing::info!("Group text message received by all members");

        // 3. Update the group name
        let new_group_name = "Renamed Group";

        group_service_a
            .update_group_name(group_id.clone(), new_group_name.into())
            .await?;

        tester_b
            .wait_for_group_name(&group_id, new_group_name)
            .await?;
        tester_c
            .wait_for_group_name(&group_id, new_group_name)
            .await?;

        tracing::info!("Group name updated and visible to all members");

        // 4. Promote tester_b to admin
        // tester_a needs tester_b's public key to promote them. We simulate a message from tester_b
        // so that tester_a can request the missing public key.
        {
            let db_a = tester_a.context.app_db.read().await.clone();
            sqlx::query!(
                "UPDATE group_members SET last_message = CAST(strftime('%s','now') AS INTEGER) WHERE group_id = ? AND contact_id = ?",
                group_id,
                tester_b.user_id
            )
            .execute(&db_a.pool)
            .await?;
            group_service_a.fetch_missing_group_public_keys().await?;

            // Wait for tester_b to respond with the group join containing the public key
            // (We just wait a moment to let the messages exchange)
            tokio::time::sleep(std::time::Duration::from_millis(500)).await;
        }

        group_service_a
            .manage_admin(group_id.clone(), tester_b.user_id, false)
            .await?;

        // Fetch state on tester_b to verify admin status
        GroupService::new(&tester_b.context)
            .fetch_group_state(group_id.clone())
            .await?;
        {
            let database = tester_b.context.app_db.read().await.clone();
            let is_admin = sqlx::query_scalar!(
                "SELECT is_group_admin FROM groups WHERE group_id = ?",
                group_id
            )
            .fetch_one(&database.pool)
            .await?;
            assert_eq!(is_admin, 1, "tester_b should be admin after promotion");
        }

        tracing::info!("tester_b promoted to admin");

        // 5. Demote tester_b from admin
        group_service_a
            .manage_admin(group_id.clone(), tester_b.user_id, true)
            .await?;

        GroupService::new(&tester_b.context)
            .fetch_group_state(group_id.clone())
            .await?;
        {
            let database = tester_b.context.app_db.read().await.clone();
            let is_admin = sqlx::query_scalar!(
                "SELECT is_group_admin FROM groups WHERE group_id = ?",
                group_id
            )
            .fetch_one(&database.pool)
            .await?;
            assert_eq!(is_admin, 0, "tester_b should not be admin after demotion");
        }

        tracing::info!("tester_b demoted from admin");

        // 6. Remove tester_c from the group
        // Note: tester_c is not an admin, so their public key is not needed to remove them.
        // We pass an empty vec![] instead of waiting for a key exchange.
        group_service_a
            .remove_member(group_id.clone(), vec![], tester_c.user_id)
            .await?;

        // tester_b should see tester_c removed
        GroupService::new(&tester_b.context)
            .fetch_group_state(group_id.clone())
            .await?;
        tester_b
            .wait_for_group_member_removed(&group_id, tester_c.user_id)
            .await?;

        // tester_c should see themselves as left
        GroupService::new(&tester_c.context)
            .fetch_group_state(group_id.clone())
            .await?;

        tester_c.wait_for_group_left(&group_id).await?;
        tracing::info!("tester_c removed from the group");

        // 7. tester_b leaves the group
        GroupService::new(&tester_b.context)
            .leave_group(group_id.clone())
            .await?;
        tester_b.wait_for_group_left(&group_id).await?;

        // tester_a should see tester_b removed after fetching state
        group_service_a.fetch_group_state(group_id.clone()).await?;
        tester_a
            .wait_for_group_member_removed(&group_id, tester_b.user_id)
            .await?;

        tracing::info!("tester_b left the group");
    }

    //
    // Testing: Testing additional data
    //
    {
        // B must know C's identity key before it can verify the key shared by A.
        ContactService::new(&tester_b.context)
            .request_by_username(tester_c.username.clone(), true)
            .await?;
        tester_c
            .wait_for_contact_state(tester_b.user_id, false, true)
            .await?;
        ContactService::new(&tester_c.context)
            .accept_request(tester_b.user_id, true)
            .await?;
        tester_b
            .wait_for_contact_state(tester_c.user_id, true, false)
            .await?;

        // A shares C with B. Receiving the message stores both the opaque
        // additional data and a verification edge from C to A.
        let message_id = MessageService::new(&tester_a.context)
            .insert_and_send_contact_share(group_id.clone(), vec![tester_c.user_id])
            .await?;

        let additional_data = {
            let database = tester_a.context.app_db.read().await.clone();
            sqlx::query_scalar!(
                "SELECT additional_message_data FROM messages WHERE message_id = ?",
                message_id,
            )
            .fetch_one(&database.pool)
            .await?
            .expect("contact-share messages contain additional data")
        };
        tester_b
            .wait_for_additional_data_message(
                &message_id,
                tester_a.user_id,
                "contacts",
                &additional_data,
            )
            .await?;
        tester_b
            .wait_for_shared_contact_verification(tester_c.user_id, tester_a.user_id)
            .await?;

        // Shared-contact trust is only effective while the sender is verified.
        tester_b
            .set_contact_verified(tester_a.user_id, false)
            .await?;
        assert!(!tester_b.is_contact_verified(tester_c.user_id).await?);

        tester_b
            .set_contact_verified(tester_a.user_id, true)
            .await?;
        assert!(tester_b.is_contact_verified(tester_c.user_id).await?);

        tester_b
            .set_contact_verified(tester_a.user_id, false)
            .await?;
        assert!(!tester_b.is_contact_verified(tester_c.user_id).await?);
    }

    Ok(())
}
