use keyring_core::{Entry, Error};
use rust_lib_twonly::bridge::wrapper::key_manager::RustKeyManager;
use rust_lib_twonly::bridge::{self, InitConfig};

#[tokio::test]
async fn reset_closes_an_active_runtime_before_removing_credentials() {
    let directory = tempfile::tempdir().unwrap();

    let config = || InitConfig {
        database_dir: directory.path().display().to_string(),
        data_dir: directory.path().display().to_string(),
    };

    bridge::initialize_twonly_flutter(config()).await.unwrap();

    let entry = Entry::new("eu.twonly", "twonly_key_manager").unwrap();

    assert!(entry.get_password().is_ok());

    tokio::time::timeout(
        std::time::Duration::from_secs(5),
        RustKeyManager::remove_local_credentials(),
    )
    .await
    .unwrap()
    .unwrap();

    assert!(matches!(entry.get_password(), Err(Error::NoEntry)));

    let error = bridge::initialize_twonly_flutter(config())
        .await
        .unwrap_err();

    assert!(error.to_string().contains("Restart required"));
    assert!(matches!(entry.get_password(), Err(Error::NoEntry)));
}
