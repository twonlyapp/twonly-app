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

    writes::insert(&mut tx, 3, "contactSharedByVerified", Some(2))
        .await
        .unwrap();

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

    assert!(writes::insert_token(&mut tx, &[1; 16]).await.unwrap() > 0);
}

async fn fixture() -> (tempfile::TempDir, AppDatabase) {
    let directory = tempfile::tempdir().unwrap();
    let database = AppDatabase::new(
        directory.path().join("app.sqlite").to_str().unwrap(),
        None,
        false,
    )
    .await
    .unwrap();
    database.run_migrations().await.unwrap();
    sqlx::raw_sql(
        "INSERT INTO contacts(user_id, username, accepted) VALUES
         (1,'root',1),(2,'shared',1),(3,'untrusted',1),(4,'other',1);
         INSERT INTO groups(group_id, group_name) VALUES ('g','group');
         INSERT INTO group_members(group_id, contact_id) VALUES ('g',2),('g',3);
         INSERT INTO user_discovery_announced_users(announced_user_id, announced_public_key, public_id)
         VALUES (3,X'01',3),(4,X'02',4);",
    ).execute(&database.pool).await.unwrap();
    (directory, database)
}

#[tokio::test]

async fn self_attestations_cycles_and_untrusted_claims_never_bootstrap_trust() {
    let (_directory, database) = fixture().await;
    let mut tx = database.pool.begin().await.unwrap();

    for (target, verifier) in [(1, 1), (1, 2), (2, 1), (3, 2)] {
        assert!(
            !writes::insert(&mut tx, target, "contactSharedByVerified", Some(verifier))
                .await
                .unwrap()
        );
    }
    assert!(!writes::insert(&mut tx, 1, "contactSharedByVerified", None)
        .await
        .unwrap());
    assert!(writes::insert(&mut tx, 1, "manual", Some(2)).await.is_err());
    assert!(writes::insert(&mut tx, 1, "invented", None).await.is_err());

    // Rows from old builds, restored backups or legacy imports must be inert
    // even when they bypass the guarded write path.
    sqlx::raw_sql(
        "INSERT INTO key_verifications(contact_id,type,verified_by) VALUES
         (1,'contactSharedByVerified',1),(1,'contactSharedByVerified',2),
         (2,'contactSharedByVerified',1),(3,'contactSharedByVerified',2),
         (4,'invented',NULL),(4,'manual',3);
         INSERT INTO user_discovery_user_relations
         (announced_user_id,from_contact_id,public_key_verified_timestamp)
         VALUES (3,2,123),(4,4,123);",
    )
    .execute(&mut *tx)
    .await
    .unwrap();

    for id in 1..=4 {
        assert!(
            !queries::is_verified(&mut tx, id).await.unwrap(),
            "contact {id}"
        );
        assert!(!queries::can_attest(&mut tx, id).await.unwrap());
        assert!(queries::contact(&mut tx, id)
            .await
            .unwrap()
            .verifications
            .is_empty());
        assert!(queries::list(&mut tx, id).await.unwrap().is_empty());
        assert!(queries::transferred(&mut tx, id)
            .await
            .unwrap()
            .relations
            .is_empty());
    }
    assert!(queries::first_types(&mut tx).await.unwrap().is_empty());
    let groups = queries::groups(&mut tx, Some("g")).await.unwrap();
    assert_eq!(groups[0].status, VerificationStatus::NotTrusted);
    assert_eq!(groups[0].unverified_count, 2);
    assert!(
        crate::database::app::recovery::queries::verified_ids(&mut tx)
            .await
            .unwrap()
            .is_empty()
    );
    assert_eq!(
        crate::database::app::recovery::queries::count(
            &mut tx,
            crate::database::app::recovery::table::RecoveryContacts::Eligible,
        )
        .await
        .unwrap(),
        0
    );
}

#[tokio::test]

async fn inherited_trust_is_one_hop_and_revocation_and_blocking_remove_its_effect() {
    let (_directory, database) = fixture().await;
    let mut tx = database.pool.begin().await.unwrap();
    writes::insert(&mut tx, 1, "manual", None).await.unwrap();
    assert!(
        writes::insert(&mut tx, 2, "contactSharedByVerified", Some(1))
            .await
            .unwrap()
    );
    assert!(queries::is_verified(&mut tx, 2).await.unwrap());
    assert!(!queries::can_attest(&mut tx, 2).await.unwrap());
    assert!(
        !writes::insert(&mut tx, 3, "contactSharedByVerified", Some(2))
            .await
            .unwrap()
    );

    sqlx::raw_sql(
        "INSERT INTO key_verifications(contact_id,type,verified_by)
         VALUES (3,'contactSharedByVerified',2);
         INSERT INTO user_discovery_user_relations
         (announced_user_id,from_contact_id,public_key_verified_timestamp)
         VALUES (3,1,123),(4,2,123);",
    )
    .execute(&mut *tx)
    .await
    .unwrap();
    assert!(!queries::is_verified(&mut tx, 3).await.unwrap());
    assert_eq!(
        queries::transferred(&mut tx, 3)
            .await
            .unwrap()
            .relations
            .len(),
        1
    );
    assert!(queries::transferred(&mut tx, 4)
        .await
        .unwrap()
        .relations
        .is_empty());
    assert_eq!(
        queries::groups(&mut tx, Some("g")).await.unwrap()[0].status,
        VerificationStatus::PartialTrusted
    );

    for field in ["blocked", "deleted_by_user", "account_deleted"] {
        sqlx::query(sqlx::AssertSqlSafe(format!(
            "UPDATE contacts SET {field} = 1 WHERE user_id = 1"
        )))
        .execute(&mut *tx)
        .await
        .unwrap();
        assert!(!queries::can_attest(&mut tx, 1).await.unwrap());
        assert!(!queries::is_verified(&mut tx, 2).await.unwrap());
        assert!(queries::transferred(&mut tx, 3)
            .await
            .unwrap()
            .relations
            .is_empty());
        sqlx::query(sqlx::AssertSqlSafe(format!(
            "UPDATE contacts SET {field} = 0 WHERE user_id = 1"
        )))
        .execute(&mut *tx)
        .await
        .unwrap();
    }

    writes::delete(&mut tx, 1, None).await.unwrap();
    assert!(!queries::is_verified(&mut tx, 2).await.unwrap());
    assert!(!queries::is_verified(&mut tx, 3).await.unwrap());
    assert!(queries::transferred(&mut tx, 3)
        .await
        .unwrap()
        .relations
        .is_empty());
    assert!(
        crate::database::app::recovery::queries::verified_ids(&mut tx)
            .await
            .unwrap()
            .is_empty()
    );
    let groups = queries::groups(&mut tx, Some("g")).await.unwrap();
    assert_eq!(groups[0].status, VerificationStatus::NotTrusted);
    assert_eq!(groups[0].unverified_count, 2);
}

#[tokio::test]

async fn repeated_evidence_is_idempotent_and_deletion_is_scoped_to_the_contact() {
    use super::table::{KeyVerificationType, NewKeyVerification};
    let (_directory, database) = fixture().await;
    let mut tx = database.pool.begin().await.unwrap();
    assert!(writes::insert(&mut tx, 1, "manual", None).await.unwrap());
    assert!(!writes::insert(&mut tx, 1, "manual", None).await.unwrap());
    assert!(
        NewKeyVerification::new(2, KeyVerificationType::ContactSharedByVerified)
            .verified_by(1)
            .insert(&mut tx)
            .await
            .unwrap()
    );
    assert!(
        !writes::insert(&mut tx, 2, "contactSharedByVerified", Some(1))
            .await
            .unwrap()
    );
    assert!(
        !NewKeyVerification::new(2, KeyVerificationType::ContactSharedByVerified)
            .verified_by(1)
            .insert(&mut tx)
            .await
            .unwrap()
    );
    assert_eq!(
        queries::contact(&mut tx, 2)
            .await
            .unwrap()
            .verifications
            .len(),
        1
    );

    // Legacy imports retain their evidence IDs, so reads also deduplicate.
    sqlx::query("INSERT INTO key_verifications(contact_id,type,verified_by) VALUES (2,'contactSharedByVerified',1)")
        .execute(&mut *tx).await.unwrap();
    let evidence = queries::contact(&mut tx, 2).await.unwrap().verifications;
    assert_eq!(evidence.len(), 1);
    writes::delete(&mut tx, 3, Some(evidence[0].verification_id))
        .await
        .unwrap();
    assert!(queries::is_verified(&mut tx, 2).await.unwrap());
    writes::delete(&mut tx, 2, Some(evidence[0].verification_id))
        .await
        .unwrap();
    assert!(!queries::is_verified(&mut tx, 2).await.unwrap());
    assert!(writes::insert_token(&mut tx, &[1; 15]).await.is_err());

    let token = writes::insert_token(&mut tx, &[1; 16]).await.unwrap();
    sqlx::query("INSERT INTO verification_token_uses(token_id,contact_id) VALUES (?,1)")
        .bind(token)
        .execute(&mut *tx)
        .await
        .unwrap();
    sqlx::query("DELETE FROM contacts WHERE user_id = 1")
        .execute(&mut *tx)
        .await
        .unwrap();
    sqlx::query("INSERT INTO contacts(user_id,username) VALUES (1,'re-added')")
        .execute(&mut *tx)
        .await
        .unwrap();
    let reused = sqlx::query(
        "INSERT INTO verification_token_uses(token_id,contact_id) VALUES (?,1) ON CONFLICT DO NOTHING",
    ).bind(token).execute(&mut *tx).await.unwrap().rows_affected();
    assert_eq!(
        reused, 0,
        "removing a contact must not forget consumed proofs"
    );
}

#[tokio::test]

async fn upgrade_removes_invalid_and_duplicate_evidence_and_retires_replayable_tokens() {
    let directory = tempfile::tempdir().unwrap();
    let database = AppDatabase::new(
        directory.path().join("upgrade.sqlite").to_str().unwrap(),
        None,
        false,
    )
    .await
    .unwrap();
    let mut tx = database.pool.begin().await.unwrap();
    let migrations = sqlx::migrate!("./src/database/app/migrations");
    for migration in migrations.iter().filter(|migration| migration.version < 56) {
        sqlx::raw_sql(migration.sql.clone())
            .execute(&mut *tx)
            .await
            .unwrap();
    }
    sqlx::raw_sql(
        "INSERT INTO contacts(user_id,username) VALUES (1,'root'),(2,'shared');
         INSERT INTO key_verifications(contact_id,type,verified_by) VALUES
         (1,'manual',NULL),(1,'manual',NULL),(1,'contactSharedByVerified',1),
         (2,'contactSharedByVerified',1),(2,'contactSharedByVerified',1),
         (2,'invented',NULL),(2,'manual',1),(2,'contactSharedByVerified',NULL);
         INSERT INTO verification_tokens(token) VALUES (X'0102');",
    )
    .execute(&mut *tx)
    .await
    .unwrap();
    sqlx::raw_sql(include_str!(
        "../migrations/0056_key_verification_trust.sql"
    ))
    .execute(&mut *tx)
    .await
    .unwrap();
    let count: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM key_verifications")
        .fetch_one(&mut *tx)
        .await
        .unwrap();
    assert_eq!(count, 2);
    assert!(queries::can_attest(&mut tx, 1).await.unwrap());
    assert!(queries::is_verified(&mut tx, 2).await.unwrap());
    assert!(!queries::can_attest(&mut tx, 2).await.unwrap());
    let tokens: i64 = sqlx::query_scalar("SELECT COUNT(*) FROM verification_tokens")
        .fetch_one(&mut *tx)
        .await
        .unwrap();
    assert_eq!(tokens, 0);
}
