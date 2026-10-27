//! A separate process owns the real Flutter singleton and keyring.

use rust_lib_twonly::bridge::api::RustApi;
use rust_lib_twonly::bridge::database::contact_groups::{self, ContactGroupInput};
use rust_lib_twonly::bridge::database::transactions::DatabaseTransaction;
use rust_lib_twonly::bridge::database::DatabaseSession;
use rust_lib_twonly::bridge::wrapper::backup::RustBackupArchive;
use rust_lib_twonly::bridge::{initialize_twonly_flutter, InitConfig};
use std::time::Duration;

fn input(name: &str) -> ContactGroupInput {
    ContactGroupInput {
        name: name.into(),
        emoji: None,
        text_color: 0,
        background_color: 0,
        show_as_shortcut: true,
        show_as_label: true,
        share_stories: false,
    }
}

#[tokio::test]

async fn restore_retires_a_live_epoch_and_its_retained_transaction_before_reopening() {
    let directory = tempfile::tempdir().unwrap();

    initialize_twonly_flutter(InitConfig {
        database_dir: directory.path().display().to_string(),
        data_dir: directory.path().display().to_string(),
    })
    .await
    .unwrap();

    let session = DatabaseSession::new();

    let original = contact_groups::create_contact_group(input("original"), &session)
        .await
        .unwrap();

    let (_, archive) = RustBackupArchive::create_backup_archive().await.unwrap();

    let retained = DatabaseTransaction::begin().await.unwrap();

    contact_groups::create_contact_group(input("rolled back"), &retained.session())
        .await
        .unwrap();

    tokio::time::timeout(
        Duration::from_secs(15),
        RustBackupArchive::restore_backup_archive(archive),
    )
    .await
    .unwrap()
    .unwrap();

    assert!(retained.commit().await.is_err());

    assert!(contact_groups::get_contact_group(original, &session)
        .await
        .unwrap()
        .is_some());

    contact_groups::create_contact_group(input("after restore"), &session)
        .await
        .unwrap();

    RustApi::set_background(true).await.unwrap();
}
