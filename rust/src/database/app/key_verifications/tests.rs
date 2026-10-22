use super::table::VerificationStatus;
use super::{queries, writes};
use crate::database::app::AppDatabase;

#[tokio::test]

async fn trust_summaries_match_direct_transferred_missing_and_duplicate_verifiers() {
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

    sqlx::query("INSERT INTO contacts(user_id,username) VALUES (1,'a'),(2,'b'),(3,'c')")
        .execute(&mut *tx)
        .await
        .unwrap();

    sqlx::query("INSERT INTO groups(group_id,group_name) VALUES ('g','g')")
        .execute(&mut *tx)
        .await
        .unwrap();

    sqlx::query("INSERT INTO group_members(group_id,contact_id) VALUES ('g',1),('g',2)")
        .execute(&mut *tx)
        .await
        .unwrap();

    writes::insert(&mut tx, 1, "manual", None).await.unwrap();

    writes::insert(&mut tx, 1, "qrScanned", None).await.unwrap();

    writes::insert(&mut tx, 3, "contactSharedByVerified", Some(2))
        .await
        .unwrap();

    assert!(!queries::is_verified(&mut tx, 3).await.unwrap());

    assert_eq!(
        queries::contact(&mut tx, 3)
            .await
            .unwrap()
            .verifications
            .len(),
        0
    );

    sqlx::query(
        r#"
        INSERT INTO user_discovery_announced_users(announced_user_id,announced_public_key,public_id)
        VALUES (2,X'01',2)
        "#,
    )
    .execute(&mut *tx)
    .await
    .unwrap();

    sqlx::query(r#"
        INSERT INTO user_discovery_user_relations(announced_user_id,from_contact_id,public_key_verified_timestamp)
        VALUES (2,1,123)
        "#,
)
    .execute(&mut *tx).await.unwrap();

    let summary = queries::groups(&mut tx, Some("g")).await.unwrap();

    assert_eq!(
        (summary[0].status, summary[0].unverified_count),
        (VerificationStatus::PartialTrusted, 0)
    );

    let transferred = queries::transferred(&mut tx, 2).await.unwrap();

    assert_eq!(
        (transferred.relations.len(), transferred.contacts.len()),
        (1, 1)
    );

    writes::insert(&mut tx, 2, "manual", None).await.unwrap();

    assert!(queries::is_verified(&mut tx, 3).await.unwrap());

    assert_eq!(
        queries::contact(&mut tx, 3).await.unwrap().contacts.len(),
        1
    );

    assert_eq!(
        queries::groups(&mut tx, None).await.unwrap()[0].status,
        VerificationStatus::Trusted
    );

    assert_eq!(queries::first_types(&mut tx).await.unwrap().len(), 3);

    assert!(queries::groups(&mut tx, Some("empty"))
        .await
        .unwrap()
        .is_empty());

    assert!(writes::delete(&mut tx, 1, None).await.unwrap());

    assert_eq!(
        queries::groups(&mut tx, None).await.unwrap()[0].unverified_count,
        1
    );

    assert!(writes::insert_token(&mut tx, &[1, 2]).await.unwrap() > 0);
}
