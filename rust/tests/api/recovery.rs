use super::{init_tracing, Tester};
use prost::Message as _;
use rust_lib_twonly::api::messages::incoming::recovery::perform_heartbeat;
use rust_lib_twonly::api::messages::outgoing::send_c2c_message_to_contact;
use rust_lib_twonly::api::proto::client::{self as proto, encrypted_content};
use rust_lib_twonly::bridge::api::ApiConnectionState;
use rust_lib_twonly::services::contacts::ContactService;

async fn create_authenticated_tester() -> anyhow::Result<Tester> {
    let mut tester = Tester::new().await?;
    tester.wait_until(ApiConnectionState::Connected).await?;
    tester.register_and_authenticate().await?;
    tester.wait_until(ApiConnectionState::Authenticated).await?;
    Ok(tester)
}

#[tokio::test]
async fn test_passwordless_recovery_share_heartbeat_and_delete() -> anyhow::Result<()> {
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

    // 1. Tester A sends recovery share to Tester B
    let secret_share = vec![10, 20, 30, 40];
    let recovery_content = proto::EncryptedContent {
        passwordless_recovery: Some(encrypted_content::PasswordLessRecovery {
            recovery_secret_share: Some(secret_share.clone()),
            threshold: 2,
            delete: false,
        }),
        ..Default::default()
    };

    send_c2c_message_to_contact()
        .ctx(&tester_a.context)
        .contact_id(tester_b.user_id)
        .encrypted_content(recovery_content.encode_to_vec())
        .call()
        .await?;

    // Verify Tester B stores the share
    tester_b
        .wait_for_recovery_contacts_share(tester_a.user_id)
        .await?;

    // Configure Tester A's contact record for Tester B to track expected share for heartbeat verification
    {
        let db_a = tester_a.context.app_db.read().await.clone();
        sqlx::query!(
            "UPDATE contacts SET recovery_secret_share = ?, recovery_is_trusted_friend = 1 WHERE user_id = ?",
            secret_share,
            tester_b.user_id,
        )
        .execute(&db_a.pool)
        .await?;
    }

    // 2. Tester B performs heartbeat
    perform_heartbeat(&tester_b.context).await?;

    // Verify Tester A receives heartbeat and updates recovery_last_heartbeat
    tester_a
        .wait_for_recovery_last_heartbeat(tester_b.user_id)
        .await?;

    // 3. Tester A sends delete request for the recovery share
    let delete_content = proto::EncryptedContent {
        passwordless_recovery: Some(encrypted_content::PasswordLessRecovery {
            recovery_secret_share: None,
            threshold: 0,
            delete: true,
        }),
        ..Default::default()
    };

    send_c2c_message_to_contact()
        .ctx(&tester_a.context)
        .contact_id(tester_b.user_id)
        .encrypted_content(delete_content.encode_to_vec())
        .call()
        .await?;

    tester_b
        .wait_for_recovery_share_deleted(tester_a.user_id)
        .await?;

    Ok(())
}
