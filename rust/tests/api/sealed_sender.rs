use crate::tester::{init_tracing, Tester};
use rust_lib_twonly::bridge::api::ApiConnectionState;
use rust_lib_twonly::database::app::tables::Group;
use rust_lib_twonly::services::contacts::ContactService;
use rust_lib_twonly::services::messages::MessageService;

async fn ready_tester() -> anyhow::Result<Tester> {
    let mut tester = Tester::new().await?;
    tester.set_sealed_sender_enabled(true)?;
    tester.wait_until(ApiConnectionState::Connected).await?;
    tester.register_and_authenticate().await?;
    tester.wait_until(ApiConnectionState::Authenticated).await?;
    Ok(tester)
}

/// Exercises the whole sealed-sender path against the running dev server:
/// Privacy Pass issuance, the capability announcement that gates it, the
/// anonymous upload, and delivery back to the recipient.
#[tokio::test]
async fn test_sealed_sender_end_to_end() -> anyhow::Result<()> {
    init_tracing();

    let tester_a = ready_tester().await?;
    let tester_b = ready_tester().await?;
    tracing::info!(
        sender = tester_a.user_id,
        recipient = tester_b.user_id,
        "Testers are ready"
    );

    let group_id = Group::direct_chat_id(tester_a.user_id, tester_b.user_id);

    // Tokens are minted right after authentication, so a message never has to
    // wait for a round trip before it can be sealed.
    tester_a.wait_for_privacy_pass_tokens().await?;

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

    // The contact request and its acceptance each carry the announcement, so
    // by now both sides know the other accepts sealed envelopes.
    tester_a
        .wait_for_contact_sealed_sender(tester_b.user_id, true)
        .await?;
    tester_b
        .wait_for_contact_sealed_sender(tester_a.user_id, true)
        .await?;

    // A sealed message arrives like any other, but the server never sees who
    // sent it.
    let sealed_id = MessageService::new(&tester_a.context)
        .insert_and_send_text(group_id.clone(), "Sealed hello".into(), None)
        .await?;
    tester_b
        .wait_for_text_message(&sealed_id, tester_a.user_id, "Sealed hello")
        .await?;
    tester_a.wait_for_message_ack_by_server(&sealed_id).await?;
    assert!(
        tester_a
            .was_sent_sealed(&sealed_id, tester_b.user_id)
            .await?,
        "message was not delivered over the sealed transport"
    );

    // Turning the feature off locally has to fall back to the named transport
    // without losing the message.
    tester_a.set_sealed_sender_enabled(false)?;
    let named_id = MessageService::new(&tester_a.context)
        .insert_and_send_text(group_id.clone(), "Named hello".into(), None)
        .await?;
    tester_b
        .wait_for_text_message(&named_id, tester_a.user_id, "Named hello")
        .await?;
    tester_a.wait_for_message_ack_by_server(&named_id).await?;
    assert!(
        !tester_a
            .was_sent_sealed(&named_id, tester_b.user_id)
            .await?,
        "message was sealed even though the local setting is off"
    );

    // Withdrawing the announcement has to stop the peer from sealing, too.
    tester_b
        .wait_for_contact_sealed_sender(tester_a.user_id, false)
        .await?;
    tester_a.set_sealed_sender_enabled(true)?;
    let back_id = MessageService::new(&tester_b.context)
        .insert_and_send_text(group_id.clone(), "Back to you".into(), None)
        .await?;
    tester_a
        .wait_for_text_message(&back_id, tester_b.user_id, "Back to you")
        .await?;
    assert!(
        !tester_b.was_sent_sealed(&back_id, tester_a.user_id).await?,
        "peer sealed a message to a contact that withdrew its announcement"
    );

    Ok(())
}
