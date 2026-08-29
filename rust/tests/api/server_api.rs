use super::Tester;
use rust_lib_twonly::api::Server;
use rust_lib_twonly::bridge::api::{ApiConnectionState, ServerResult};

async fn create_authenticated_tester() -> anyhow::Result<Tester> {
    let mut tester = Tester::new().await?;
    tester.wait_until(ApiConnectionState::Connected).await?;
    tester.register_and_authenticate().await?;
    tester.wait_until(ApiConnectionState::Authenticated).await?;
    Ok(tester)
}

#[tokio::test]
async fn test_server_account_and_user_endpoints() -> anyhow::Result<()> {
    let tester_a = create_authenticated_tester().await?;
    let tester_b = create_authenticated_tester().await?;

    // 1. get_user_by_id
    let user_data = Server::get_user_by_id(&tester_a.context, tester_b.user_id).await?;
    match user_data {
        ServerResult::Ok(data) => {
            assert_eq!(data.user_id, tester_b.user_id);
            assert_eq!(
                data.username.map(String::from_utf8).transpose()?,
                Some(tester_b.username.clone())
            );
        }
        ServerResult::ErrorCode(code) => panic!("get_user_by_id failed with code: {code}"),
    }

    // 2. get_user_id_from_username (handshake endpoint)
    {
        let tester_handshake = Tester::new().await?;
        tester_handshake
            .wait_until(ApiConnectionState::Connected)
            .await?;
        let user_id =
            Server::get_user_id_from_username(&tester_handshake.context, tester_b.username.clone())
                .await?;
        match user_id {
            ServerResult::Ok(id) => assert_eq!(id, tester_b.user_id),
            ServerResult::ErrorCode(code) => {
                panic!("get_user_id_from_username failed with code: {code}")
            }
        }
    }

    // 3. get_user_by_username
    let user_by_name =
        Server::get_user_by_username(&tester_a.context, tester_b.username.clone()).await?;
    match user_by_name {
        ServerResult::Ok(data) => assert_eq!(data.user_id, tester_b.user_id),
        ServerResult::ErrorCode(code) => panic!("get_user_by_username failed with code: {code}"),
    }

    // 4. update_fcm_token
    let res = Server::update_fcm_token(&tester_a.context, "sample_fcm_token_123".into()).await?;
    assert!(matches!(res, ServerResult::Ok(())));

    // 5. set_login_token
    let res = Server::set_login_token(&tester_a.context, vec![1, 2, 3, 4, 5]).await?;
    assert!(matches!(res, ServerResult::Ok(())));

    // 6. get_plan_balance / load_plan_balance
    let balance_bytes = Server::get_plan_balance(&tester_a.context).await?;
    assert!(!balance_bytes.is_empty());

    // 7. report_user
    let res = Server::report_user(
        &tester_a.context,
        tester_b.user_id,
        "testing spam reporting".into(),
    )
    .await?;
    assert!(matches!(res, ServerResult::Ok(())));

    Ok(())
}
