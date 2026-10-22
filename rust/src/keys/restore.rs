//! Imported identities stay separate from the active database identity until
//! the file restore journal has durably committed the matching generation.

use super::{KeyManager, KEY_MANAGER_ID};
use crate::error::{Result, TwonlyError};
use crate::secure_storage::SecureStorage;
use serde::{Deserialize, Serialize};
use zeroize::{Zeroize, ZeroizeOnDrop, Zeroizing};

const RECORD: &str = "twonly_pending_restore_identity_v1";

#[derive(Deserialize, Serialize, Zeroize, ZeroizeOnDrop)]

pub(crate) struct Identity {
    version: u8,
    pub(crate) id: String,
    applied: bool,
    pub(crate) key_manager: KeyManager,
}

fn invalid() -> TwonlyError {
    TwonlyError::Generic("Restore identity is missing or inconsistent; recovery is required".into())
}

fn read(storage: &SecureStorage) -> Result<Option<Identity>> {
    let Some(value) = storage.read(RECORD)? else {
        return Ok(None);
    };

    let value = Zeroizing::new(value);

    let bytes = Zeroizing::new(hex::decode(&*value)?);

    let identity: Identity = postcard::from_bytes(&bytes)?;

    if identity.version != 1 || uuid::Uuid::parse_str(&identity.id).is_err() {
        return Err(invalid());
    }

    Ok(Some(identity))
}

fn write(storage: &SecureStorage, identity: &Identity) -> Result<()> {
    let bytes = Zeroizing::new(postcard::to_allocvec(identity)?);

    let value = Zeroizing::new(hex::encode(&*bytes));

    storage.write(RECORD, &value)?;

    Ok(())
}

/// Staging does not replace either the durable or the in-memory active key.

pub(crate) fn stage(storage: &SecureStorage, key_manager: KeyManager) -> Result<()> {
    let _access = storage.identity_access()?;

    write(
        storage,
        &Identity {
            version: 1,
            id: uuid::Uuid::new_v4().to_string(),
            applied: false,
            key_manager,
        },
    )
}

pub(crate) fn pending(storage: &SecureStorage) -> Result<Option<Identity>> {
    let _access = storage.identity_access()?;

    Ok(read(storage)?.filter(|identity| !identity.applied))
}

/// Called only while holding both exclusive database maintenance gates. It
/// deliberately bypasses ordinary key-write admission through the marker.

pub(crate) fn validate(storage: &SecureStorage, id: &str) -> Result<()> {
    let identity = read(storage)?.ok_or_else(invalid)?;

    if identity.id != id {
        return Err(invalid());
    }

    if identity.applied
        && KeyManager::try_from_keychain(storage)?.main_key != identity.key_manager.main_key
    {
        return Err(invalid());
    }

    Ok(())
}

pub(crate) fn apply(
    storage: &SecureStorage, id: &str, hook: &mut impl FnMut(&str) -> Result<()>,
) -> Result<()> {
    validate(storage, id)?;

    let mut identity = read(storage)?.ok_or_else(invalid)?;

    if !identity.applied {
        let bytes = Zeroizing::new(identity.key_manager.to_bytes()?);

        let value = Zeroizing::new(hex::encode(&*bytes));

        storage.write(KEY_MANAGER_ID, &value)?;

        hook("identity stored")?;

        // A token for the previous account cannot authenticate this identity.
        storage.delete("api_auth_token")?;

        // Acknowledgement precedes removal of the file journal. Replaying an
        // acknowledged record never overwrites later key-manager updates.
        identity.applied = true;

        write(storage, &identity)?;

        hook("identity acknowledged")?;
    }

    Ok(())
}

pub(crate) fn discard(storage: &SecureStorage) -> Result<()> {
    storage.delete(RECORD)?;

    Ok(())
}

#[cfg(test)]

mod tests {

    use super::*;

    #[test]

    fn staging_keeps_the_active_identity_and_acknowledged_replay_preserves_updates() {
        SecureStorage::init().unwrap();

        let storage = SecureStorage::new(&uuid::Uuid::new_v4().to_string());

        let original = KeyManager::generate().unwrap();

        original.store_to_keychain(&storage).unwrap();

        let mut imported = KeyManager::generate().unwrap();

        imported.user_id = Some(42);

        let imported_bytes = imported.to_bytes().unwrap();

        stage(&storage, imported).unwrap();

        assert_eq!(KeyManager::try_from_keychain(&storage).unwrap(), original);

        let id = pending(&storage).unwrap().unwrap().id.clone();

        apply(&storage, &id, &mut |_| Ok(())).unwrap();

        assert!(pending(&storage).unwrap().is_none());

        let mut active = KeyManager::try_from_keychain(&storage).unwrap();

        assert_eq!(active, KeyManager::from_bytes(&imported_bytes).unwrap());

        active.user_id = Some(99);

        active.store_to_keychain(&storage).unwrap();

        apply(&storage, &id, &mut |_| Ok(())).unwrap();

        assert_eq!(KeyManager::try_from_keychain(&storage).unwrap(), active);

        discard(&storage).unwrap();

        assert!(pending(&storage).unwrap().is_none());
    }

    #[test]

    fn an_old_context_cannot_overwrite_a_committed_identity() {
        SecureStorage::init().unwrap();

        let directory = tempfile::tempdir().unwrap();

        let storage = SecureStorage::new(&uuid::Uuid::new_v4().to_string())
            .with_database_dir(directory.path());

        let old = KeyManager::generate().unwrap();

        old.store_to_keychain(&storage).unwrap();

        stage(&storage, KeyManager::generate().unwrap()).unwrap();

        let id = pending(&storage).unwrap().unwrap().id.clone();

        apply(&storage, &id, &mut |_| Ok(())).unwrap();

        let active = KeyManager::try_from_keychain(&storage).unwrap();

        assert!(old.store_to_keychain(&storage).is_err());

        assert_eq!(KeyManager::try_from_keychain(&storage).unwrap(), active);
    }
}
