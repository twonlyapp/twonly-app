use super::queries;
use super::table::ReceiptPatch;
use super::writes::{self, ReceiptTarget};
use crate::database::app::patch::{NullableInt, NullableText};
use crate::database::app::AppDatabase;

async fn open() -> (tempfile::TempDir, AppDatabase) {
    let directory = tempfile::tempdir().unwrap();

    let database = AppDatabase::new(
        directory.path().join("app.sqlite").to_str().unwrap(),
        None,
        false,
    )
    .await
    .unwrap();

    database.run_migrations().await.unwrap();

    sqlx::query(
        "INSERT INTO contacts(user_id,username,account_deleted) VALUES (1,'a',0),(2,'b',1)",
    )
    .execute(&database.pool)
    .await
    .unwrap();

    sqlx::query("INSERT INTO groups(group_id,group_name) VALUES ('g','g')")
        .execute(&database.pool)
        .await
        .unwrap();

    sqlx::query("INSERT INTO messages(message_id,group_id,type) VALUES ('m','g','text')")
        .execute(&database.pool)
        .await
        .unwrap();

    sqlx::query(r#"
        INSERT INTO receipts(receipt_id,contact_id,message_id,message,mark_for_retry,will_be_retried_by_media_upload)
        VALUES ('a',1,'m',X'0102',10,1),
            ('b',1,'m',X'03',20,1),
            ('c',2,NULL,X'04',1,0)
        "#,
)
    .execute(&database.pool).await.unwrap();

    (directory, database)
}

#[tokio::test]

async fn patches_distinguish_absent_null_and_false_and_scope_both_keys() {
    let (_directory, database) = open().await;

    let mut tx = database.pool.begin().await.unwrap();

    writes::update(
        &mut tx,
        ReceiptTarget::ContactMessage(1, "m"),
        ReceiptPatch {
            mark_for_retry: Some(NullableInt { value: None }),
            contact_will_sends_receipt: Some(false),
            ..Default::default()
        },
    )
    .await
    .unwrap();

    let row = queries::get(&mut tx, "a").await.unwrap().unwrap();

    assert_eq!(
        (
            row.mark_for_retry,
            row.contact_will_sends_receipt,
            row.message
        ),
        (None, 0, vec![1, 2])
    );

    assert_eq!(
        queries::get(&mut tx, "c")
            .await
            .unwrap()
            .unwrap()
            .mark_for_retry,
        Some(1)
    );

    writes::update(
        &mut tx,
        ReceiptTarget::Id("a"),
        ReceiptPatch {
            receipt_id: Some("renamed".into()),
            message_id: Some(NullableText { value: None }),
            ..Default::default()
        },
    )
    .await
    .unwrap();

    assert!(queries::get(&mut tx, "a").await.unwrap().is_none());

    writes::update(
        &mut tx,
        ReceiptTarget::Id("renamed"),
        ReceiptPatch::default(),
    )
    .await
    .unwrap();

    assert!(queries::get(&mut tx, "renamed")
        .await
        .unwrap()
        .unwrap()
        .message_id
        .is_none());
}

#[tokio::test]

async fn retry_cutoff_is_strict_and_purge_uses_deleted_contact_membership() {
    let (_directory, database) = open().await;

    let mut tx = database.pool.begin().await.unwrap();

    assert_eq!(
        queries::media_retransmissions(&mut tx, 20)
            .await
            .unwrap()
            .iter()
            .map(|r| r.receipt_id.as_str())
            .collect::<Vec<_>>(),
        vec!["a"]
    );

    sqlx::query(
        "INSERT INTO received_receipts(receipt_id,created_at) VALUES ('old',9),('boundary',10)",
    )
    .execute(&mut *tx)
    .await
    .unwrap();

    writes::purge(&mut tx, 10).await.unwrap();

    let remaining: Vec<String> = sqlx::query_scalar("SELECT receipt_id FROM received_receipts")
        .fetch_all(&mut *tx)
        .await
        .unwrap();

    assert_eq!(remaining, vec!["boundary"]);

    assert!(queries::get(&mut tx, "c").await.unwrap().is_none());

    writes::delete(&mut tx, ReceiptTarget::Message("m"))
        .await
        .unwrap();

    assert!(queries::list(&mut tx).await.unwrap().is_empty());

    tx.rollback().await.unwrap();

    assert_eq!(
        queries::list(&mut *database.pool.acquire().await.unwrap())
            .await
            .unwrap()
            .len(),
        3
    );
}
