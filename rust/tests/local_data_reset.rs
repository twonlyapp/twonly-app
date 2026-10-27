use keyring_core::{Entry, Error};
use rust_lib_twonly::bridge::wrapper::key_manager::RustKeyManager;
use rust_lib_twonly::bridge::{self, InitConfig};

#[tokio::test]
async fn reset_clears_corrupt_credentials_after_failed_startup_and_requires_restart() {
    keyring_core::set_default_store(keyring_core::mock::Store::new().unwrap());

    let entries = [
        "twonly_key_manager",
        "twonly_pending_restore_identity_v1",
        "api_auth_token",
    ]
    .map(|key| Entry::new("eu.twonly", key).unwrap());

    for entry in &entries {
        entry.set_password("corrupt credential").unwrap();
    }

    let directory = tempfile::tempdir().unwrap();

    std::fs::write(directory.path().join("rust_db.sqlite"), b"corrupt database").unwrap();

    let config = || InitConfig {
        database_dir: directory.path().display().to_string(),
        data_dir: directory.path().display().to_string(),
    };

    assert!(bridge::initialize_twonly_flutter(config()).await.is_err());

    RustKeyManager::remove_local_credentials().await.unwrap();

    for entry in &entries {
        assert!(matches!(entry.get_password(), Err(Error::NoEntry)));
    }

    // Reset can be retried if deleting files or restarting failed afterward.
    RustKeyManager::remove_local_credentials().await.unwrap();

    let error = bridge::initialize_twonly_flutter(config())
        .await
        .unwrap_err();

    assert!(error.to_string().contains("Restart required"));
}
