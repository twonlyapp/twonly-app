use super::{init_tracing, Tester};
use prost::Message as _;
use rust_lib_twonly::api::messages::outgoing::send_c2c_message_to_contact;
use rust_lib_twonly::api::proto::client::{self as proto, encrypted_content};
use rust_lib_twonly::api::Server;
use rust_lib_twonly::bridge::api::ApiConnectionState;
use rust_lib_twonly::database::app::tables::Group;
use rust_lib_twonly::services::contacts::ContactService;
use rust_lib_twonly::services::groups::GroupService;
use rust_lib_twonly::services::messages::MessageService;

async fn create_authenticated_tester() -> anyhow::Result<Tester> {
    let mut tester = Tester::new().await?;
    tester.wait_until(ApiConnectionState::Connected).await?;
    tester.register_and_authenticate().await?;
    tester.wait_until(ApiConnectionState::Authenticated).await?;
    Ok(tester)
}

#[tokio::test]
async fn test_contact_cross_request_auto_accept() -> anyhow::Result<()> {
    init_tracing();
    let tester_a = create_authenticated_tester().await?;
    let tester_b = create_authenticated_tester().await?;

    // Tester A requests Tester B
    ContactService::new(&tester_a.context)
        .request_by_username(tester_b.username.clone(), true)
        .await?;

    // Wait until Tester B sees the incoming request
    tester_b
        .wait_for_contact_state(tester_a.user_id, false, true)
        .await?;

    // Tester B also sends a request to Tester A (instead of explicitly clicking accept)
    ContactService::new(&tester_b.context)
        .request_by_username(tester_a.username.clone(), true)
        .await?;

    // Both should auto-accept and become accepted contacts
    tester_a
        .wait_for_contact_state(tester_b.user_id, true, false)
        .await?;
    tester_b
        .wait_for_contact_state(tester_a.user_id, true, false)
        .await?;

    // Verify direct chat group exists on both
    let group_id = Group::direct_chat_id(tester_a.user_id, tester_b.user_id);
    let msg_id = MessageService::new(&tester_a.context)
        .insert_and_send_text(
            group_id.clone(),
            "Hello after cross-request!".into(),
            None,
            None,
        )
        .await?;
    tester_b
        .wait_for_text_message(&msg_id, tester_a.user_id, "Hello after cross-request!")
        .await?;

    Ok(())
}

#[tokio::test]
async fn test_unknown_sender_auto_contact_discovery() -> anyhow::Result<()> {
    init_tracing();
    let tester_a = create_authenticated_tester().await?;
    let tester_b = create_authenticated_tester().await?;

    // Tester A requests Tester B by username and gets prekeys to establish session
    ContactService::new(&tester_a.context)
        .request_by_username(tester_b.username.clone(), true)
        .await?;

    // Verify Tester B now automatically has Tester A in contacts and signal_identities
    tester_b
        .wait_for_contact_username(tester_a.user_id, &tester_a.username)
        .await?;

    let signal_db_b = tester_b.context.rust_db.read().await.clone();
    let identity_exists = sqlx::query_scalar!(
        "SELECT EXISTS(SELECT 1 FROM signal_identities WHERE name = ?)",
        tester_a.user_id.to_string(),
    )
    .fetch_one(&signal_db_b.pool)
    .await?;
    assert_eq!(
        identity_exists, 1,
        "signal identity must be recorded for unknown sender"
    );

    Ok(())
}

#[tokio::test]
async fn test_check_for_deleted_usernames() -> anyhow::Result<()> {
    init_tracing();
    let tester_a = create_authenticated_tester().await?;
    let tester_b = create_authenticated_tester().await?;

    // Tester A manually inserts Tester B with '[deleted]' username placeholder
    {
        let db_a = tester_a.context.app_db.read().await.clone();
        sqlx::query!(
            "INSERT INTO contacts(user_id, username, accepted, requested) VALUES (?, '[deleted]', 1, 0)",
            tester_b.user_id,
        )
        .execute(&db_a.pool)
        .await?;
    }

    // Call check_for_deleted_usernames
    Server::check_for_deleted_usernames(&tester_a.context).await?;

    // Verify username was restored from the server
    tester_a
        .wait_for_contact_username(tester_b.user_id, &tester_b.username)
        .await?;

    Ok(())
}

/// Two users who met in a shared group must converge on a single accepted
/// contact when the requested side accepts. The group leaves both sides with a
/// hidden row for each other, and an unaccepted inbound message flips a row to
/// `requested`; keying the accept off either of those states dropped real
/// accepts, built only one half of the direct chat, and made the next message
/// across it bounce back as a fresh request.
#[tokio::test]
async fn test_accept_lands_for_contacts_met_in_a_group() -> anyhow::Result<()> {
    init_tracing();
    let tester_c = create_authenticated_tester().await?;
    let tester_a = create_authenticated_tester().await?;
    let tester_b = create_authenticated_tester().await?;

    // C befriends A and B so it can put both of them in one group.
    for tester in [&tester_a, &tester_b] {
        ContactService::new(&tester_c.context)
            .request_by_username(tester.username.clone(), true)
            .await?;
        tester
            .wait_for_contact_state(tester_c.user_id, false, true)
            .await?;
        ContactService::new(&tester.context)
            .accept_request(tester_c.user_id, true)
            .await?;
        tester_c
            .wait_for_contact_state(tester.user_id, true, false)
            .await?;
    }

    let group_name = "Met In A Group";
    GroupService::new(&tester_c.context)
        .create_group(group_name.into(), vec![tester_a.user_id, tester_b.user_id])
        .await?;

    let group_id = {
        let db_c = tester_c.context.app_db.read().await.clone();
        sqlx::query_scalar!(
            "SELECT group_id FROM groups WHERE is_direct_chat = 0 ORDER BY rowid DESC LIMIT 1"
        )
        .fetch_one(&db_c.pool)
        .await?
    };
    tester_a
        .wait_for_group_exists(&group_id, group_name)
        .await?;
    tester_b
        .wait_for_group_exists(&group_id, group_name)
        .await?;

    // Being put in a group with somebody is not a contact request from them.
    tester_a
        .wait_for_contact_state(tester_b.user_id, false, false)
        .await?;
    tester_b
        .wait_for_contact_state(tester_a.user_id, false, false)
        .await?;

    // A really does request B, then lands back in the state the group and an
    // unaccepted inbound message leave behind while the accept is in flight.
    ContactService::new(&tester_a.context)
        .request_by_username(tester_b.username.clone(), true)
        .await?;
    tester_b
        .wait_for_contact_state(tester_a.user_id, false, true)
        .await?;
    {
        let db_a = tester_a.context.app_db.read().await.clone();
        sqlx::query!(
            "UPDATE contacts SET requested = 1, deleted_by_user = 1 WHERE user_id = ?",
            tester_b.user_id,
        )
        .execute(&db_a.pool)
        .await?;
    }

    ContactService::new(&tester_b.context)
        .accept_request(tester_a.user_id, true)
        .await?;

    tester_a
        .wait_for_contact_state(tester_b.user_id, true, false)
        .await?;

    // Both halves of the direct chat exist now, so a message crosses it
    // instead of bouncing back as a fresh contact request.
    let direct_chat_id = Group::direct_chat_id(tester_a.user_id, tester_b.user_id);
    let msg_id = MessageService::new(&tester_b.context)
        .insert_and_send_text(direct_chat_id, "Hello from the group".into(), None, None)
        .await?;
    tester_a
        .wait_for_text_message(&msg_id, tester_b.user_id, "Hello from the group")
        .await?;
    tester_b
        .wait_for_contact_state(tester_a.user_id, true, false)
        .await?;

    Ok(())
}

/// An accept nobody asked for must not make its sender a contact.
#[tokio::test]
async fn test_unsolicited_accept_does_not_add_a_contact() -> anyhow::Result<()> {
    init_tracing();
    let tester_a = create_authenticated_tester().await?;
    let tester_b = create_authenticated_tester().await?;

    // B learns A's keys and claims A accepted a request A never sent.
    ContactService::new(&tester_b.context)
        .request_by_username(tester_a.username.clone(), true)
        .await?;
    tester_a
        .wait_for_contact_state(tester_b.user_id, false, true)
        .await?;
    let accept = proto::EncryptedContent {
        contact_request: Some(encrypted_content::ContactRequest {
            r#type: encrypted_content::contact_request::Type::Accept as i32,
        }),
        ..Default::default()
    };
    send_c2c_message_to_contact()
        .ctx(&tester_b.context)
        .contact_id(tester_a.user_id)
        .encrypted_content(accept.encode_to_vec())
        .blocking(true)
        .call()
        .await?;

    // The notification is recorded after the handler, in the same inbound
    // transaction, so its arrival means the accept has been dealt with.
    tester_a
        .wait_for_notification("accept_request", tester_b.user_id)
        .await?;

    // A keeps the pending request and gains neither an accepted contact nor a
    // direct chat off the back of it.
    tester_a
        .wait_for_contact_state(tester_b.user_id, false, true)
        .await?;
    let direct_chat_id = Group::direct_chat_id(tester_a.user_id, tester_b.user_id);
    let db_a = tester_a.context.app_db.read().await.clone();
    let direct_chat_exists = sqlx::query_scalar!(
        "SELECT EXISTS(SELECT 1 FROM groups WHERE group_id = ?)",
        direct_chat_id,
    )
    .fetch_one(&db_a.pool)
    .await?;
    assert_eq!(direct_chat_exists, 0, "unsolicited accept created a chat");

    Ok(())
}
