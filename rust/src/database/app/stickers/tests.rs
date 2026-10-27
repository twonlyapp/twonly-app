use super::{queries, watches, writes};
use crate::database::app::AppDatabase;
use sha2::{Digest, Sha256};
use std::sync::Arc;

async fn open() -> (tempfile::TempDir, Arc<AppDatabase>) {
    let directory = tempfile::tempdir().unwrap();

    let database = AppDatabase::new(
        directory.path().join("app.sqlite").to_str().unwrap(),
        None,
        false,
    )
    .await
    .unwrap();

    database.run_migrations().await.unwrap();

    (directory, Arc::new(database))
}

fn hash(bytes: &[u8]) -> String {
    hex::encode(Sha256::digest(bytes))
}

#[tokio::test]

async fn verified_insert_deduplicates_and_checks_all_bounds() {
    let (_directory, database) = open().await;

    let mut tx = database.pool.begin().await.unwrap();

    for (bytes, width, height, expected) in [
        (&[][..], 1, 1, None),
        (&[1][..], 0, 1, None),
        (&[1][..], 1, 301, None),
        (&[1][..], 1, 1, Some("false")),
    ] {
        assert!(writes::save(&mut tx, bytes, width, height, expected)
            .await
            .is_err());
    }

    assert!(writes::save(&mut tx, &vec![1; 131073], 1, 1, None)
        .await
        .is_err());

    assert!(writes::save(&mut tx, &[1], 300, 1, Some(&hash(&[1])))
        .await
        .unwrap());

    writes::record_use(&mut tx, &hash(&[1])).await.unwrap();

    assert!(!writes::save(&mut tx, &[1], 1, 1, None).await.unwrap());

    let value = queries::get(&mut tx, &hash(&[1])).await.unwrap().unwrap();

    assert_eq!((value.metadata.width, value.metadata.usage_count), (300, 1));

    tx.commit().await.unwrap();
}

#[tokio::test]

async fn replacement_merges_usage_preserves_dates_and_rolls_back() {
    let (_directory, database) = open().await;

    let mut tx = database.pool.begin().await.unwrap();

    for bytes in [&[1][..], &[2][..]] {
        writes::save(&mut tx, bytes, 20, 30, None).await.unwrap();
    }

    sqlx::query(
        r#"
        UPDATE stickers
        SET created_at = 11,
            last_used_at = 22,
            usage_count = 3
        WHERE content_hash = ?
        "#,
    )
    .bind(hash(&[1]))
    .execute(&mut *tx)
    .await
    .unwrap();

    sqlx::query(
        r#"
        UPDATE stickers
        SET created_at = 33,
            last_used_at = 44,
            usage_count = 5
        WHERE content_hash = ?
        "#,
    )
    .bind(hash(&[2]))
    .execute(&mut *tx)
    .await
    .unwrap();

    tx.commit().await.unwrap();

    let mut tx = database.pool.begin().await.unwrap();

    let value = writes::replace(&mut tx, &hash(&[1]), &[2], 30, 20, &hash(&[2]))
        .await
        .unwrap();

    assert_eq!(
        (
            value.metadata.usage_count,
            value.metadata.created_at,
            value.metadata.last_used_at
        ),
        (8, 33, 44)
    );

    assert!(queries::get(&mut tx, &hash(&[1])).await.unwrap().is_none());

    tx.rollback().await.unwrap();

    assert_eq!(
        queries::list(&mut database.pool.acquire().await.unwrap())
            .await
            .unwrap()
            .len(),
        2
    );

    let mut tx = database.pool.begin().await.unwrap();

    let value = writes::replace(&mut tx, &hash(&[1]), &[3], 30, 20, &hash(&[3]))
        .await
        .unwrap();

    assert_eq!(
        (
            value.metadata.usage_count,
            value.metadata.created_at,
            value.metadata.last_used_at
        ),
        (3, 11, 22)
    );

    assert!(writes::replace(&mut tx, &hash(&[3]), &[4], 30, 20, "false")
        .await
        .is_err());

    assert!(queries::get(&mut tx, &hash(&[3])).await.unwrap().is_some());
}

#[tokio::test]

async fn concurrent_duplicate_saves_have_one_winner() {
    let (_directory, database) = open().await;

    let mut tasks = Vec::new();

    for _ in 0..8 {
        let database = database.clone();

        tasks.push(tokio::spawn(async move {
            let mut tx = database.pool.begin().await.unwrap();

            let inserted = writes::save(&mut tx, &[7], 1, 1, None).await.unwrap();

            tx.commit().await.unwrap();

            inserted as usize
        }));
    }

    let mut inserted = 0;

    for task in tasks {
        inserted += task.await.unwrap();
    }

    assert_eq!(inserted, 1);
}

#[tokio::test]

async fn usage_watch_sends_no_image_bytes_and_readdition_refetches() {
    let (_directory, database) = open().await;

    let holder = Arc::new(tokio::sync::RwLock::new(database.clone()));

    let cancellation = tokio_util::sync::CancellationToken::new();

    let (sender, mut receiver) = tokio::sync::mpsc::unbounded_channel();

    let cancel = cancellation.clone();

    let task = tokio::spawn(async move {
        watches::collection(holder, cancel, |value| sender.send(value).is_ok())
            .await
            .unwrap();
    });

    assert!(receiver.recv().await.unwrap().items.is_empty());

    let mut tx = database.pool.begin().await.unwrap();

    writes::save(&mut tx, &[8], 1, 1, None).await.unwrap();

    tx.commit().await.unwrap();

    let added = receiver.recv().await.unwrap();

    assert_eq!(added.assets[0].webp, vec![8]);

    let mut tx = database.pool.begin().await.unwrap();

    writes::record_use(&mut tx, &hash(&[8])).await.unwrap();

    tx.commit().await.unwrap();

    let used = receiver.recv().await.unwrap();

    assert_eq!(used.items[0].usage_count, 1);

    assert!(used.assets.is_empty());

    let mut tx = database.pool.begin().await.unwrap();

    writes::remove(&mut tx, &hash(&[8])).await.unwrap();

    tx.commit().await.unwrap();

    assert!(receiver.recv().await.unwrap().items.is_empty());

    let mut tx = database.pool.begin().await.unwrap();

    writes::save(&mut tx, &[8], 1, 1, None).await.unwrap();

    tx.commit().await.unwrap();

    assert_eq!(receiver.recv().await.unwrap().assets.len(), 1);

    cancellation.cancel();

    task.await.unwrap();
}
