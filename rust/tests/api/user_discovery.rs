use std::time::Duration;

use rust_lib_twonly::bridge::api::ApiConnectionState;
use rust_lib_twonly::services::contacts::ContactService;
use rust_lib_twonly::services::messages::MessageService;
use tokio::time::sleep;

use super::{init_tracing, Tester};

async fn create_tester() -> anyhow::Result<Tester> {
    let mut tester = Tester::new().await?;
    tester.wait_until(ApiConnectionState::Connected).await?;
    tester.register_and_authenticate().await?;
    tester.wait_until(ApiConnectionState::Authenticated).await?;
    Ok(tester)
}

async fn connect_contacts(requester: &Tester, accepter: &Tester) -> anyhow::Result<()> {
    ContactService::new(&requester.context)
        .request_by_username(accepter.username.clone(), true)
        .await?;
    accepter
        .wait_for_contact_state(requester.user_id, false, true)
        .await?;
    ContactService::new(&accepter.context)
        .accept_request(requester.user_id, true)
        .await?;
    requester
        .wait_for_contact_state(accepter.user_id, true, false)
        .await?;
    Ok(())
}

async fn send_trigger(from: &Tester, to: &Tester, label: &str) -> anyhow::Result<()> {
    let group_id =
        rust_lib_twonly::database::app::tables::Group::direct_chat_id(from.user_id, to.user_id);
    MessageService::new(&from.context)
        .insert_and_send_text(group_id, label.to_owned(), None)
        .await?;
    Ok(())
}

async fn wait_for_promotion(relay: &Tester, contact_id: i64) -> anyhow::Result<()> {
    for _ in 0..300 {
        let database = relay.context.app_db.read().await.clone();
        let exists = sqlx::query_scalar!(
            r#"SELECT EXISTS(
                SELECT 1 FROM user_discovery_own_promotions
                WHERE contact_id = ? AND length(promotion) > 0
            )"#,
            contact_id,
        )
        .fetch_one(&database.pool)
        .await?
            != 0;
        if exists {
            return Ok(());
        }
        sleep(Duration::from_millis(100)).await;
    }
    Err(anyhow::anyhow!(
        "relay {} did not create a promotion for user {contact_id}",
        relay.user_id
    ))
}

async fn wait_for_discovery(
    observer: &Tester,
    discovered_user_id: i64,
    expected_relations: i64,
) -> anyhow::Result<()> {
    for _ in 0..300 {
        let database = observer.context.app_db.read().await.clone();
        let announced = sqlx::query_scalar!(
            "SELECT EXISTS(SELECT 1 FROM user_discovery_announced_users WHERE announced_user_id = ?)",
            discovered_user_id,
        )
        .fetch_one(&database.pool)
        .await?
            != 0;
        let relations = sqlx::query_scalar!(
            "SELECT COUNT(*) FROM user_discovery_user_relations WHERE announced_user_id = ?",
            discovered_user_id,
        )
        .fetch_one(&database.pool)
        .await?;
        if announced && relations >= expected_relations {
            return Ok(());
        }
        sleep(Duration::from_millis(100)).await;
    }
    Err(anyhow::anyhow!(
        "user {discovered_user_id} was not discovered with {expected_relations} relations"
    ))
}

#[tokio::test]
async fn user_discovery_reconstructs_an_unknown_user_from_three_contacts() -> anyhow::Result<()> {
    init_tracing();
    let observer = create_tester().await?;
    let relay_a = create_tester().await?;
    let relay_b = create_tester().await?;
    let relay_c = create_tester().await?;
    let discoverable = create_tester().await?;

    for tester in [&observer, &relay_a, &relay_b, &relay_c, &discoverable] {
        let database = tester.context.app_db.read().await.clone();
        let share_count = sqlx::query_scalar!("SELECT COUNT(*) FROM user_discovery_shares")
            .fetch_one(&database.pool)
            .await?;
        assert_eq!(
            share_count, 253,
            "threshold 3 keeps two verification shares"
        );
    }

    connect_contacts(&observer, &relay_a).await?;
    connect_contacts(&observer, &relay_b).await?;
    connect_contacts(&observer, &relay_c).await?;
    connect_contacts(&discoverable, &relay_a).await?;
    connect_contacts(&discoverable, &relay_b).await?;
    connect_contacts(&discoverable, &relay_c).await?;

    send_trigger(&discoverable, &relay_a, "discovery source a").await?;
    send_trigger(&discoverable, &relay_b, "discovery source b").await?;
    send_trigger(&discoverable, &relay_c, "discovery source c").await?;

    wait_for_promotion(&relay_a, discoverable.user_id).await?;
    wait_for_promotion(&relay_b, discoverable.user_id).await?;
    wait_for_promotion(&relay_c, discoverable.user_id).await?;

    send_trigger(&relay_a, &observer, "discovery relay a").await?;
    send_trigger(&relay_b, &observer, "discovery relay b").await?;
    send_trigger(&relay_c, &observer, "discovery relay c").await?;

    wait_for_discovery(&observer, discoverable.user_id, 3).await?;

    let database = observer.context.app_db.read().await.clone();
    let direct_contact = sqlx::query_scalar!(
        "SELECT EXISTS(SELECT 1 FROM contacts WHERE user_id = ?)",
        discoverable.user_id,
    )
    .fetch_one(&database.pool)
    .await?;
    assert_eq!(direct_contact, 0, "discovery must not create a contact");

    let unique_relations = sqlx::query_scalar!(
        "SELECT COUNT(DISTINCT from_contact_id) FROM user_discovery_user_relations WHERE announced_user_id = ?",
        discoverable.user_id,
    )
    .fetch_one(&database.pool)
    .await?;
    assert_eq!(unique_relations, 3);

    send_trigger(&relay_a, &observer, "duplicate discovery relay").await?;
    sleep(Duration::from_secs(1)).await;
    let relations_after_duplicate = sqlx::query_scalar!(
        "SELECT COUNT(*) FROM user_discovery_user_relations WHERE announced_user_id = ?",
        discoverable.user_id,
    )
    .fetch_one(&database.pool)
    .await?;
    assert_eq!(relations_after_duplicate, 3, "updates must be idempotent");

    Ok(())
}
