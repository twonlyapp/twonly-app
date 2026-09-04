use super::{init_tracing, Tester};
use rust_lib_twonly::bridge::api::ApiConnectionState;
use rust_lib_twonly::database::app::tables::Group;
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
