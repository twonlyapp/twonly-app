use crate::user_discovery::stores::InMemoryStore;
use crate::user_discovery::traits::tests::TestingUtils;
use crate::user_discovery::{UserDiscovery, UserDiscoveryStore, UserDiscoveryVersion, UserID};
use prost::Message;
use rand::seq::SliceRandom;
use std::collections::{HashMap, HashSet};
use std::vec;

struct TestUsers<S: UserDiscoveryStore> {
    names: Vec<&'static str>,
    friends: Vec<Vec<usize>>,
    message_flows: Vec<(usize, usize)>,
    announced_users_expected: Vec<Vec<(usize, Vec<usize>)>>,
    uds: Vec<UserDiscovery<S, TestingUtils>>,
}

async fn get_with_five_users<S: UserDiscoveryStore + Default + Clone>() -> TestUsers<S> {
    const ALICE: usize = 0;
    const BOB: usize = 1;
    const CHARLIE: usize = 2;
    const DAVID: usize = 3;
    const FRANK: usize = 4;

    let names = vec!["ALICE", "BOB", "CHARLIE", "DAVID", "FRANK"];
    let mut uds = vec![];

    for index in 0..names.len() {
        let store = S::default();
        uds.push(get_ud(index, 2, store).await);
    }

    TestUsers {
        names,
        uds,
        friends: vec![
            vec![BOB, CHARLIE],
            vec![ALICE, CHARLIE, DAVID],
            vec![ALICE, BOB, DAVID, FRANK],
            vec![BOB, CHARLIE],
            vec![CHARLIE],
        ],
        message_flows: vec![
            (ALICE, 1),   // ALICE: own announcement sending to BOB and CHARLIE
            (BOB, 2),     // BOB: own announcement + promotion for ALICE
            (BOB, 0),     // BOBs version should not have any new messages for his friends
            (ALICE, 1),   // ALICE: promotion for BOB
            (CHARLIE, 3), // CHARLIE: own announcement + promotion for ALICE, BOB
            (DAVID, 3),   // DAVID: own announcement + promotion for BOB, CHARLIE
            (BOB, 2),     // BOB: promotion for CHARLIE, DAVID
            (CHARLIE, 1), // CHARLIE: promotion for DAVID
            (FRANK, 2),   // FRANK: own announcement +  promotion for CHARLIE
            (CHARLIE, 1), // CHARLIE: promotion for FRANK
            (ALICE, 1),   // ALICE: promotion for CHARLIE
        ],
        announced_users_expected: vec![
            // ALICE should now know that BOB and CHARLIE, BOB and DAVID and CHARLIE and DAVID are friends.
            // Alice should also have one protected share from Frank.
            vec![
                (BOB, vec![CHARLIE]), // ALICE knows Bob and that CHARLIE is connected with BOB
                (CHARLIE, vec![BOB]), // ALICE knows CHARLIE and that BOB is connected with CHARLIE
                (DAVID, vec![BOB, CHARLIE]), // ALICE knows DAVID and that BOB and CHARLIE are connected with DAVID
            ],
            vec![
                (ALICE, vec![CHARLIE]),
                (CHARLIE, vec![ALICE, DAVID]),
                (DAVID, vec![CHARLIE]),
            ],
            vec![
                (ALICE, vec![BOB]),
                (BOB, vec![ALICE, DAVID]),
                (DAVID, vec![BOB]),
                (FRANK, vec![]),
            ],
            vec![
                (ALICE, vec![BOB, CHARLIE]),
                (BOB, vec![CHARLIE]),
                (CHARLIE, vec![BOB]),
            ],
            vec![(CHARLIE, vec![])],
        ],
    }
}

#[tokio::test]
async fn test_user_discovery_in_memory_store() {
    let _ = pretty_env_logger::try_init();

    let users = get_with_five_users().await;
    step0_exchange_in_order::<InMemoryStore>(&users).await;
    step1_verify_no_new_messages::<InMemoryStore>(&users).await;
    step2_verify_announced_users_expected::<InMemoryStore>(&users).await;
}

#[tokio::test]
async fn test_user_discovery_random_order_in_memory_store() {
    let _ = pretty_env_logger::try_init();

    let users = get_with_five_users().await;
    step0_exchange_random::<InMemoryStore>(&users).await;
    step1_verify_no_new_messages::<InMemoryStore>(&users).await;
    step2_verify_announced_users_expected::<InMemoryStore>(&users).await;
}

async fn step0_exchange_in_order<S: UserDiscoveryStore + Clone + Default>(users: &TestUsers<S>) {
    for (i, (from, count)) in users.message_flows.iter().enumerate() {
        tracing::debug!("MESSAGE FLOW: {i}");
        to_all_friends(*from, *count, &users).await;
    }
}

async fn step0_exchange_random<S: UserDiscoveryStore + Clone + Default>(users: &TestUsers<S>) {
    let mut user_ids: Vec<usize> = (0..users.names.len()).collect();

    for _ in 0..100 {
        user_ids.shuffle(&mut rand::rng());

        for from in user_ids.clone() {
            for friend in &users.friends[from] {
                request_and_handle_messages(
                    (from, &users.uds[from]),
                    (*friend, &users.uds[*friend]),
                    None,
                )
                .await;
            }
        }
    }
}

async fn step1_verify_no_new_messages<S: UserDiscoveryStore + Clone + Default>(
    users: &TestUsers<S>,
) {
    tracing::debug!("Now all users should have the newest version.");

    for from in 0..users.names.len() {
        for to in &users.friends[from] {
            tracing::debug!(
                "Does {} has open messages for {}?",
                &users.names[from],
                &users.names[*to]
            );
            assert_new_messages((from, &users.uds[from]), (*to, &users.uds[*to]), false).await;
        }
    }
}

async fn step2_verify_announced_users_expected<S: UserDiscoveryStore + Clone + Default>(
    users: &TestUsers<S>,
) {
    tracing::debug!("Test if all exchanges where successful.");

    for (user, announcements) in users.announced_users_expected.iter().enumerate() {
        let announced_users2 = users.uds[user].get_all_announced_users().await.unwrap();
        let mut announced_users = HashMap::new();
        for a in announced_users2 {
            announced_users.insert(a.0.user_id, a.1.iter().map(|x| x.0).collect::<Vec<_>>());
        }
        tracing::debug!("{} knows now: {}", users.names[user], announced_users.len());
        assert_eq!(announced_users.len(), announcements.len());
        for (contact_id, announced_users_expected) in announcements {
            let announced_users = announced_users.get(&(*contact_id as i64)).unwrap();
            tracing::debug!(
                "{} knows now that {} has the following friends: {}",
                users.names[user],
                users.names[*contact_id],
                announced_users
                    .iter()
                    .map(|x| users.names[*x as usize])
                    .collect::<Vec<_>>()
                    .join(", ")
            );
            let announced_users: HashSet<i64> = announced_users.iter().cloned().collect();
            let announced_users_expected: HashSet<i64> = announced_users_expected
                .iter()
                .cloned()
                .map(|x| x as i64)
                .collect();
            assert_eq!(announced_users, announced_users_expected);
        }
    }
}

async fn get_ud<S: UserDiscoveryStore + Clone + Default>(
    user_id: usize,
    threshold: u8,
    store: S,
) -> UserDiscovery<S, TestingUtils> {
    let ud = UserDiscovery::new(store.to_owned(), TestingUtils::default()).unwrap();

    ud.initialize_or_update(threshold, user_id as UserID, vec![user_id as u8; 32])
        .await
        .unwrap();

    let version = ud.get_current_version().await.unwrap();

    assert_eq!(version, get_version_bytes(1, 0));
    ud
}

async fn assert_new_messages<S: UserDiscoveryStore>(
    from: (usize, &UserDiscovery<S, TestingUtils>),
    to: (usize, &UserDiscovery<S, TestingUtils>),
    has_new_messages: bool,
) {
    // From sends a message with his current version to To
    let to_received_version = &from.1.get_current_version().await.unwrap();
    assert_eq!(
        to.1.should_request_new_messages(from.0 as UserID, to_received_version)
            .await
            .unwrap()
            .is_some(),
        has_new_messages
    );
}

async fn request_and_handle_messages<S: UserDiscoveryStore>(
    from: (usize, &UserDiscovery<S, TestingUtils>),
    to: (usize, &UserDiscovery<S, TestingUtils>),
    messages_count: Option<usize>,
) {
    // From sends a message with his current version to To

    if messages_count.is_some() {
        let to_received_version = &from.1.get_current_version().await.unwrap();
        assert_eq!(
            to.1.should_request_new_messages(from.0 as UserID, to_received_version)
                .await
                .unwrap()
                .is_some(),
            true
        );
    }

    // As To has a older version stored he sends a request to From: Give me all messages since version.
    let from_request_version_from_to =
        to.1.get_contact_version(from.0 as UserID)
            .await
            .unwrap()
            .unwrap_or(get_version_bytes(0, 0));

    let new_messages = from
        .1
        .get_new_messages(to.0 as UserID, &from_request_version_from_to)
        .await
        .unwrap();

    if let Some(messages_count) = messages_count {
        assert!(new_messages.len() <= messages_count);
    }

    to.1.handle_new_messages(from.0 as UserID, new_messages)
        .await
        .unwrap();

    if messages_count.is_some() {
        assert_eq!(
            to.1.should_request_new_messages(
                from.0 as UserID,
                &from.1.get_current_version().await.unwrap()
            )
            .await
            .unwrap()
            .is_some(),
            false
        );
    }
}

async fn to_all_friends<S: UserDiscoveryStore + Clone>(
    from: usize,
    message_count: usize,
    users: &TestUsers<S>,
) {
    for friend in &users.friends[from] {
        tracing::debug!("From {} to {}", users.names[from], users.names[*friend]);

        if message_count == 0 {
            assert_new_messages(
                (from, &users.uds[from]),
                (*friend, &users.uds[*friend]),
                false,
            )
            .await;
        } else {
            request_and_handle_messages(
                (from, &users.uds[from]),
                (*friend, &users.uds[*friend]),
                Some(message_count),
            )
            .await;
        }
    }
}

fn get_version_bytes(announcement: u32, promotion: u32) -> Vec<u8> {
    UserDiscoveryVersion {
        announcement,
        promotion,
    }
    .encode_to_vec()
}
