use super::table::*;
use super::{queries, writes};
use crate::database::app::AppDatabase;

#[tokio::test]

async fn recovery_selection_deduplicates_evidence_and_share_updates_roll_back_together() {
    let directory = tempfile::tempdir().unwrap();

    let database = AppDatabase::new(
        directory.path().join("app.sqlite").to_str().unwrap(),
        None,
        false,
    )
    .await
    .unwrap();

    database.run_migrations().await.unwrap();

    let mut tx = database.pool.begin().await.unwrap();

    sqlx::query(
        r#"
        INSERT INTO contacts(user_id, username, accepted, blocked, media_send_counter)
        VALUES (7, 'a', 1, 0, 1), (8, 'b', 1, 0, 9), (9, 'blocked', 1, 1, 100)
        "#,
    )
    .execute(&mut *tx)
    .await
    .unwrap();

    sqlx::query(
        r#"
        INSERT INTO key_verifications(contact_id, type)
        VALUES (7, 'link'), (7, 'qrScanned'), (9, 'link')
        "#,
    )
    .execute(&mut *tx)
    .await
    .unwrap();

    sqlx::query(
        r#"
        INSERT INTO user_discovery_announced_users(announced_user_id, announced_public_key, public_id)
        VALUES (8, X'01', 8)
        "#,
    ).execute(&mut *tx).await.unwrap();

    sqlx::query(
        r#"
        INSERT INTO user_discovery_user_relations(announced_user_id, from_contact_id, public_key_verified_timestamp)
        VALUES (8, 7, 0)
        "#,
    ).execute(&mut *tx).await.unwrap();

    assert_eq!(queries::verified_ids(&mut tx).await.unwrap(), vec![7, 8, 9]);

    assert_eq!(
        queries::count(&mut tx, RecoveryContacts::Eligible)
            .await
            .unwrap(),
        2
    );

    assert_eq!(
        queries::contacts(&mut tx, RecoveryContacts::Eligible, Some(1))
            .await
            .unwrap()[0]
            .user_id,
        8
    );

    assert!(
        queries::contacts(&mut tx, RecoveryContacts::Eligible, Some(0))
            .await
            .unwrap()
            .is_empty()
    );

    tx.commit().await.unwrap();

    let mut tx = database.pool.begin().await.unwrap();

    assert!(writes::store_shares(
        &mut tx,
        vec![
            RecoveryShare {
                contact_id: 7,
                secret: vec![1]
            },
            RecoveryShare {
                contact_id: 999,
                secret: vec![2]
            },
        ]
    )
    .await
    .is_err());

    tx.rollback().await.unwrap();

    assert!(
        queries::trusted_ids(&mut *database.pool.acquire().await.unwrap())
            .await
            .unwrap()
            .is_empty()
    );

    let mut tx = database.pool.begin().await.unwrap();

    writes::store_shares(
        &mut tx,
        vec![
            RecoveryShare {
                contact_id: 7,
                secret: vec![1, 255],
            },
            RecoveryShare {
                contact_id: 8,
                secret: vec![2],
            },
        ],
    )
    .await
    .unwrap();

    assert_eq!(queries::trusted_ids(&mut tx).await.unwrap(), vec![7, 8]);

    assert_eq!(
        queries::count(&mut tx, RecoveryContacts::Trusted)
            .await
            .unwrap(),
        2
    );

    assert_eq!(
        queries::contacts(&mut tx, RecoveryContacts::Trusted, None)
            .await
            .unwrap()[0]
            .recovery_secret_share
            .as_deref(),
        Some([1, 255].as_slice())
    );

    assert!(writes::store_shares(
        &mut tx,
        vec![
            RecoveryShare {
                contact_id: 7,
                secret: vec![3]
            },
            RecoveryShare {
                contact_id: 7,
                secret: vec![4]
            },
        ]
    )
    .await
    .is_err());

    assert!(writes::store_shares(
        &mut tx,
        vec![RecoveryShare {
            contact_id: 7,
            secret: vec![]
        }]
    )
    .await
    .is_err());
}
