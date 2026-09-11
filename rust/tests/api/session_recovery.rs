use super::{init_tracing, Tester};
use prost::Message as _;
use rust_lib_twonly::api::messages::incoming::handle_decoded_server_message;
use rust_lib_twonly::api::messages::outgoing::send_c2c_message_to_contact;
use rust_lib_twonly::api::proto::client::{self as proto, encrypted_content};
use rust_lib_twonly::bridge::api::ApiConnectionState;
use rust_lib_twonly::database::app::tables::{Group, Receipt};
use rust_lib_twonly::services::contacts::ContactService;
use rust_lib_twonly::services::messages::MessageService;

async fn create_authenticated_tester() -> anyhow::Result<Tester> {
    let mut tester = Tester::new().await?;
    tester.wait_until(ApiConnectionState::Connected).await?;
    tester.register_and_authenticate().await?;
    tester.wait_until(ApiConnectionState::Authenticated).await?;
    Ok(tester)
}

#[tokio::test]
async fn test_signal_session_auto_recovery_on_missing_session() -> anyhow::Result<()> {
    init_tracing();
    let tester_a = create_authenticated_tester().await?;
    let tester_b = create_authenticated_tester().await?;

    // Connect contacts A and B
    ContactService::new(&tester_a.context)
        .request_by_username(tester_b.username.clone(), true)
        .await?;
    tester_b
        .wait_for_contact_state(tester_a.user_id, false, true)
        .await?;
    ContactService::new(&tester_b.context)
        .accept_request(tester_a.user_id, true)
        .await?;
    tester_a
        .wait_for_contact_state(tester_b.user_id, true, false)
        .await?;

    let group_id = Group::direct_chat_id(tester_a.user_id, tester_b.user_id);

    // Initial message
    let msg1_id = MessageService::new(&tester_a.context)
        .insert_and_send_text(group_id.clone(), "Initial message".into(), None, None)
        .await?;
    tester_b
        .wait_for_text_message(&msg1_id, tester_a.user_id, "Initial message")
        .await?;

    // Tester A deletes the Signal session from its database
    {
        let rust_db_a = tester_a.context.rust_db.read().await.clone();
        sqlx::query!(
            "DELETE FROM signal_sessions WHERE name = ?",
            tester_b.user_id.to_string(),
        )
        .execute(&rust_db_a.pool)
        .await?;
    }

    // Tester A sends a second message.
    // `encrypt_v2_with_session_recovery` should catch the missing session error,
    // fetch Tester B's prekey bundle from the server, rebuild the session, and deliver.
    let msg2_id = MessageService::new(&tester_a.context)
        .insert_and_send_text(group_id.clone(), "Recovered message".into(), None, None)
        .await?;

    tester_b
        .wait_for_text_message(&msg2_id, tester_a.user_id, "Recovered message")
        .await?;

    Ok(())
}

/// Archive recovery deliberately discards the receiver's restored sessions.
/// A sender may still have its pre-recovery half and send one stale ciphertext;
/// the receiver must request a reset and receive the re-encrypted message over
/// the fresh prekey session without user intervention.
#[tokio::test]
async fn test_signal_session_recovers_after_receiver_sessions_are_purged() -> anyhow::Result<()> {
    init_tracing();
    let tester_a = create_authenticated_tester().await?;
    let tester_b = create_authenticated_tester().await?;

    ContactService::new(&tester_a.context)
        .request_by_username(tester_b.username.clone(), true)
        .await?;
    tester_b
        .wait_for_contact_state(tester_a.user_id, false, true)
        .await?;
    ContactService::new(&tester_b.context)
        .accept_request(tester_a.user_id, true)
        .await?;
    tester_a
        .wait_for_contact_state(tester_b.user_id, true, false)
        .await?;

    let group_id = Group::direct_chat_id(tester_a.user_id, tester_b.user_id);
    let initial_id = MessageService::new(&tester_a.context)
        .insert_and_send_text(group_id.clone(), "Before session purge".into(), None, None)
        .await?;
    tester_b
        .wait_for_text_message(&initial_id, tester_a.user_id, "Before session purge")
        .await?;

    // This is the Signal-state result of restoring an archive: B retains its
    // identity and prekeys, but no peer session survives.
    let rust_db_b = tester_b.context.rust_db.read().await.clone();
    sqlx::query!("DELETE FROM signal_sessions")
        .execute(&rust_db_b.pool)
        .await?;
    sqlx::query!("DELETE FROM signal_session_resets")
        .execute(&rust_db_b.pool)
        .await?;

    // A still encrypts with the old half. B reports that it cannot use that
    // session, A rebuilds from B's current bundle, and the queued plaintext is
    // re-encrypted and delivered over a PreKey message.
    let recovered_id = MessageService::new(&tester_a.context)
        .insert_and_send_text(group_id.clone(), "After session purge".into(), None, None)
        .await?;
    tester_b
        .wait_for_text_message(&recovered_id, tester_a.user_id, "After session purge")
        .await?;

    // The newly established session works in the restored user's direction as
    // well, proving that the repair converged rather than only delivering the
    // retried message.
    let reply_id = MessageService::new(&tester_b.context)
        .insert_and_send_text(group_id, "Reply after session purge".into(), None, None)
        .await?;
    tester_a
        .wait_for_text_message(&reply_id, tester_b.user_id, "Reply after session purge")
        .await?;

    Ok(())
}

/// A restored backup rewinds one side's ratchet behind the peer's, so nothing
/// the peer sends afterwards decrypts and resending it never helps. The
/// receiver has to retire its session, the sender has to build a new one from
/// a fresh prekey bundle, and the parked message has to arrive over it.
#[tokio::test]
async fn test_signal_session_reset_after_a_restored_backup() -> anyhow::Result<()> {
    init_tracing();
    let tester_a = create_authenticated_tester().await?;
    let tester_b = create_authenticated_tester().await?;

    ContactService::new(&tester_a.context)
        .request_by_username(tester_b.username.clone(), true)
        .await?;
    tester_b
        .wait_for_contact_state(tester_a.user_id, false, true)
        .await?;
    ContactService::new(&tester_b.context)
        .accept_request(tester_a.user_id, true)
        .await?;
    tester_a
        .wait_for_contact_state(tester_b.user_id, true, false)
        .await?;

    let group_id = Group::direct_chat_id(tester_a.user_id, tester_b.user_id);

    let message_id = MessageService::new(&tester_a.context)
        .insert_and_send_text(group_id.clone(), "Before the backup".into(), None, None)
        .await?;
    tester_b
        .wait_for_text_message(&message_id, tester_a.user_id, "Before the backup")
        .await?;

    // The session state a backup taken at this point would hold.
    let name_a = tester_a.user_id.to_string();
    let rust_db_b = tester_b.context.rust_db.read().await.clone();
    let backup = sqlx::query_scalar!(
        "SELECT record_bytes FROM signal_sessions WHERE name = ? AND device_id = 1",
        name_a,
    )
    .fetch_one(&rust_db_b.pool)
    .await?;

    // Both sides ratchet on, past the step the archive was taken at.
    for round in 0..2 {
        let from_b = MessageService::new(&tester_b.context)
            .insert_and_send_text(group_id.clone(), format!("B {round}"), None, None)
            .await?;
        tester_a
            .wait_for_text_message(&from_b, tester_b.user_id, &format!("B {round}"))
            .await?;
        let from_a = MessageService::new(&tester_a.context)
            .insert_and_send_text(group_id.clone(), format!("A {round}"), None, None)
            .await?;
        tester_b
            .wait_for_text_message(&from_a, tester_a.user_id, &format!("A {round}"))
            .await?;
    }

    // B restores the backup, putting its half of the session back in the past.
    sqlx::query!(
        "UPDATE signal_sessions SET record_bytes = ? WHERE name = ? AND device_id = 1",
        backup,
        name_a,
    )
    .execute(&rust_db_b.pool)
    .await?;

    // B cannot decrypt this and cannot be helped by a resend: it resets its
    // session and asks A for a new one, A rebuilds from B's prekey bundle and
    // sends the parked message over it.
    let message_id = MessageService::new(&tester_a.context)
        .insert_and_send_text(group_id.clone(), "After the restore".into(), None, None)
        .await?;
    tester_b
        .wait_for_text_message(&message_id, tester_a.user_id, "After the restore")
        .await?;

    // The repaired session carries traffic in both directions.
    let message_id = MessageService::new(&tester_b.context)
        .insert_and_send_text(
            group_id.clone(),
            "Reply on the new session".into(),
            None,
            None,
        )
        .await?;
    tester_a
        .wait_for_text_message(&message_id, tester_b.user_id, "Reply on the new session")
        .await?;

    Ok(())
}

/// A claim whose message was never handled -- the trace a failed decryption
/// leaves -- must not swallow the redelivery.
///
/// The claim exists to stop a message being processed twice, but it is written
/// before the message is handled, so a decryption that failed leaves exactly
/// the same trace as one that succeeded. Dropping the redelivery on that
/// ambiguity loses the message, and answers the peer with nothing, so they
/// resend the same receipt indefinitely.
#[tokio::test]
async fn test_a_claimed_but_unhandled_message_is_delivered_on_redelivery() -> anyhow::Result<()> {
    init_tracing();
    let tester_a = create_authenticated_tester().await?;
    let tester_b = create_authenticated_tester().await?;

    ContactService::new(&tester_a.context)
        .request_by_username(tester_b.username.clone(), true)
        .await?;
    tester_b
        .wait_for_contact_state(tester_a.user_id, false, true)
        .await?;
    ContactService::new(&tester_b.context)
        .accept_request(tester_a.user_id, true)
        .await?;
    tester_a
        .wait_for_contact_state(tester_b.user_id, true, false)
        .await?;

    let group_id = Group::direct_chat_id(tester_a.user_id, tester_b.user_id);
    let sender_message_id = uuid::Uuid::new_v4().to_string();

    // A encrypts the message without sending it, so the test controls when B
    // sees it and can claim its receipt first.
    let content = proto::EncryptedContent {
        group_id: Some(group_id.clone()),
        text_message: Some(encrypted_content::TextMessage {
            sender_message_id: sender_message_id.clone(),
            text: "Claimed but never handled".into(),
            timestamp: chrono::Utc::now().timestamp_millis(),
            quote_message_id: None,
            additional_message_data: None,
        }),
        ..Default::default()
    };
    let encoded = send_c2c_message_to_contact()
        .ctx(&tester_a.context)
        .contact_id(tester_b.user_id)
        .encrypted_content(content.encode_to_vec())
        .only_return_encrypted_data(true)
        .call()
        .await?
        .expect("the encrypted message is returned rather than sent");
    let message = proto::Message::decode(encoded.as_slice())?;

    // B claims the receipt and handles nothing, exactly as a decryption that
    // failed leaves it.
    {
        let database = tester_b.context.app_db.read().await.clone();
        let mut t = database.pool.begin().await?;
        assert!(Receipt::claim_received(&mut t, &message.receipt_id).await?);
        t.commit().await?;
    }

    // The claim must not swallow it: this content has never been handled.
    handle_decoded_server_message(&tester_b.context, tester_a.user_id, message.clone()).await?;
    tester_b
        .wait_for_text_message(
            &sender_message_id,
            tester_a.user_id,
            "Claimed but never handled",
        )
        .await?;

    // Now it genuinely has been handled, and a further copy is the duplicate it
    // looks like: the ratchet has consumed it, so it is acknowledged rather
    // than delivered a second time.
    handle_decoded_server_message(&tester_b.context, tester_a.user_id, message).await?;
    let database = tester_b.context.app_db.read().await.clone();
    let copies = sqlx::query_scalar!(
        "SELECT COUNT(*) FROM messages WHERE message_id = ?",
        sender_message_id,
    )
    .fetch_one(&database.pool)
    .await?;
    assert_eq!(copies, 1, "a redelivered message must not be stored twice");

    Ok(())
}
