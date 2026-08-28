use super::Tester;
use rust_lib_twonly::bridge::api::ApiConnectionState;
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
async fn test_group_membership_error_healing() -> anyhow::Result<()> {
    let _ = tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| tracing_subscriber::EnvFilter::new("info")),
        )
        .with_ansi(true)
        .event_format(rust_lib_twonly::log::ShortEventFormatter::ansi())
        .try_init();

    let tester_a = create_authenticated_tester().await?;
    let tester_b = create_authenticated_tester().await?;

    // Tester A adds Tester B as contact
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

    // Tester A creates group with Tester B
    let group_service_a = GroupService::new(&tester_a.context);
    let group_name = "Resilient Group";
    group_service_a
        .create_group(group_name.into(), vec![tester_b.user_id])
        .await?;

    let group_id = {
        let db_a = tester_a.context.app_db.read().await.clone();
        sqlx::query_scalar!(
            "SELECT group_id FROM groups WHERE is_direct_chat = 0 ORDER BY rowid DESC LIMIT 1"
        )
        .fetch_one(&db_a.pool)
        .await?
    };

    tester_b
        .wait_for_group_exists(&group_id, group_name)
        .await?;

    // Tester B simulates local state wipe of this group (drops the group row)
    {
        let db_b = tester_b.context.app_db.read().await.clone();
        sqlx::query!("DELETE FROM group_members WHERE group_id = ?", group_id)
            .execute(&db_b.pool)
            .await?;
        sqlx::query!("DELETE FROM groups WHERE group_id = ?", group_id)
            .execute(&db_b.pool)
            .await?;
    }

    // Tester A sends a text message in the group
    let msg_id = MessageService::new(&tester_a.context)
        .insert_and_send_text(group_id.clone(), "Message triggering heal".into(), None)
        .await?;

    // Tester B will report error, Tester A will heal and re-send GroupCreate,
    // and Tester B will rejoin and receive the message.
    tester_b
        .wait_for_group_exists(&group_id, group_name)
        .await?;

    // Wait a brief moment for group join to be acknowledged, then ensure queued receipts are retransmitted
    tokio::time::sleep(std::time::Duration::from_millis(500)).await;
    let _ = rust_lib_twonly::api::messages::incoming::client2client::messages::retransmit_queued_receipts(&tester_a.context).await;

    tester_b
        .wait_for_text_message(&msg_id, tester_a.user_id, "Message triggering heal")
        .await?;

    Ok(())
}

#[tokio::test]
async fn test_add_hidden_contact() -> anyhow::Result<()> {
    let tester_a = create_authenticated_tester().await?;
    let tester_b = create_authenticated_tester().await?;

    // Tester A adds Tester B as hidden contact
    GroupService::new(&tester_a.context)
        .add_hidden_contact(tester_b.user_id)
        .await?;

    let db_a = tester_a.context.app_db.read().await.clone();
    let contact = sqlx::query!(
        "SELECT username, deleted_by_user FROM contacts WHERE user_id = ?",
        tester_b.user_id
    )
    .fetch_one(&db_a.pool)
    .await?;

    assert_eq!(contact.username, tester_b.username);
    assert_eq!(contact.deleted_by_user, 1, "hidden contact must have deleted_by_user=1");

    Ok(())
}
