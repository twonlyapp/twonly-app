use super::Tester;
use rust_lib_twonly::api::Server;
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
async fn test_contact_cross_request_auto_accept() -> anyhow::Result<()> {
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
        .insert_and_send_text(group_id.clone(), "Hello after cross-request!".into(), None)
        .await?;
    tester_b
        .wait_for_text_message(&msg_id, tester_a.user_id, "Hello after cross-request!")
        .await?;

    Ok(())
}

#[tokio::test]
async fn test_unknown_sender_auto_contact_discovery() -> anyhow::Result<()> {
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
