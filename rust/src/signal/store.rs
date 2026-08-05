use async_trait::async_trait;
use libsignal_protocol::{
    Direction, GenericSignedPreKey, IdentityChange, IdentityKey, IdentityKeyPair, IdentityKeyStore,
    KyberPreKeyId, KyberPreKeyRecord, KyberPreKeyStore, PreKeyId, PreKeyRecord, PreKeyStore,
    ProtocolAddress, PublicKey, SessionRecord, SessionStore, SignalProtocolError, SignedPreKeyId,
    SignedPreKeyRecord, SignedPreKeyStore,
};
use sqlx::SqlitePool;

pub struct DbSignalProtocolStore {
    pub identity_store: DbIdentityKeyStore,
    pub pre_key_store: DbPreKeyStore,
    pub signed_pre_key_store: DbSignedPreKeyStore,
    pub kyber_pre_key_store: DbKyberPreKeyStore,
    pub session_store: DbSessionStore,
    pub pool: SqlitePool,
}

impl DbSignalProtocolStore {
    pub fn new(
        pool: SqlitePool,
        identity_key_pair: IdentityKeyPair,
        local_registration_id: u32,
    ) -> Self {
        Self {
            pool: pool.clone(),
            identity_store: DbIdentityKeyStore {
                pool: pool.clone(),
                identity_key_pair,
                local_registration_id,
            },
            pre_key_store: DbPreKeyStore { pool: pool.clone() },
            signed_pre_key_store: DbSignedPreKeyStore { pool: pool.clone() },
            kyber_pre_key_store: DbKyberPreKeyStore { pool: pool.clone() },
            session_store: DbSessionStore { pool },
        }
    }
}

pub struct DbIdentityKeyStore {
    pool: SqlitePool,
    identity_key_pair: IdentityKeyPair,
    local_registration_id: u32,
}

#[async_trait(?Send)]
impl IdentityKeyStore for DbIdentityKeyStore {
    async fn get_identity_key_pair(&self) -> Result<IdentityKeyPair, SignalProtocolError> {
        Ok(self.identity_key_pair.clone())
    }

    async fn get_local_registration_id(&self) -> Result<u32, SignalProtocolError> {
        Ok(self.local_registration_id)
    }

    async fn save_identity(
        &mut self,
        address: &ProtocolAddress,
        identity: &IdentityKey,
    ) -> Result<IdentityChange, SignalProtocolError> {
        let name = address.name();
        let identity_bytes = identity.serialize();
        let timestamp = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .map_err(|_| SignalProtocolError::UntrustedIdentity(address.clone()))?
            .as_millis() as i64;

        let existing: Option<(Vec<u8>,)> =
            sqlx::query_as("SELECT identity_key FROM signal_identities WHERE name = ?")
                .bind(name)
                .fetch_optional(&self.pool)
                .await
                .map_err(|_| SignalProtocolError::UntrustedIdentity(address.clone()))?;

        let changed = if let Some(row) = existing {
            row.0 != identity_bytes.as_ref()
        } else {
            false
        };

        sqlx::query("INSERT INTO signal_identities (name, identity_key, timestamp) VALUES (?, ?, ?) ON CONFLICT(name) DO UPDATE SET identity_key = excluded.identity_key, timestamp = excluded.timestamp")
            .bind(name)
            .bind(identity_bytes.as_ref())
            .bind(timestamp)
            .execute(&self.pool)
            .await
            .map_err(|_| SignalProtocolError::UntrustedIdentity(address.clone()))?;

        Ok(IdentityChange::from_changed(changed))
    }

    async fn is_trusted_identity(
        &self,
        address: &ProtocolAddress,
        identity: &IdentityKey,
        _direction: Direction,
    ) -> Result<bool, SignalProtocolError> {
        let name = address.name();
        let identity_bytes = identity.serialize();

        let row: Option<(Vec<u8>,)> =
            sqlx::query_as("SELECT identity_key FROM signal_identities WHERE name = ?")
                .bind(name)
                .fetch_optional(&self.pool)
                .await
                .map_err(|_| SignalProtocolError::UntrustedIdentity(address.clone()))?;

        if let Some((stored_key,)) = row {
            Ok(stored_key == identity_bytes.as_ref())
        } else {
            Ok(true)
        }
    }

    async fn get_identity(
        &self,
        address: &ProtocolAddress,
    ) -> Result<Option<IdentityKey>, SignalProtocolError> {
        let name = address.name();

        let row: Option<(Vec<u8>,)> =
            sqlx::query_as("SELECT identity_key FROM signal_identities WHERE name = ?")
                .bind(name)
                .fetch_optional(&self.pool)
                .await
                .map_err(|_| SignalProtocolError::UntrustedIdentity(address.clone()))?;

        if let Some((bytes,)) = row {
            let key = IdentityKey::decode(&bytes)
                .map_err(|_| SignalProtocolError::UntrustedIdentity(address.clone()))?;
            Ok(Some(key))
        } else {
            Ok(None)
        }
    }
}

pub struct DbPreKeyStore {
    pool: SqlitePool,
}

#[async_trait(?Send)]
impl PreKeyStore for DbPreKeyStore {
    async fn get_pre_key(&self, prekey_id: PreKeyId) -> Result<PreKeyRecord, SignalProtocolError> {
        let id: u32 = prekey_id.into();
        let row: Option<(Vec<u8>,)> =
            sqlx::query_as("SELECT record_bytes FROM signal_pre_keys WHERE pre_key_id = ?")
                .bind(id)
                .fetch_optional(&self.pool)
                .await
                .map_err(|_| SignalProtocolError::InvalidPreKeyId)?;

        if let Some((bytes,)) = row {
            PreKeyRecord::deserialize(&bytes).map_err(|_| SignalProtocolError::InvalidPreKeyId)
        } else {
            Err(SignalProtocolError::InvalidPreKeyId)
        }
    }

    async fn save_pre_key(
        &mut self,
        prekey_id: PreKeyId,
        record: &PreKeyRecord,
    ) -> Result<(), SignalProtocolError> {
        let id: u32 = prekey_id.into();
        let bytes = record
            .serialize()
            .map_err(|_| SignalProtocolError::InvalidPreKeyId)?;

        sqlx::query("INSERT INTO signal_pre_keys (pre_key_id, record_bytes) VALUES (?, ?) ON CONFLICT(pre_key_id) DO UPDATE SET record_bytes = excluded.record_bytes")
            .bind(id)
            .bind(bytes)
            .execute(&self.pool)
            .await
            .map_err(|_| SignalProtocolError::InvalidPreKeyId)?;
        Ok(())
    }

    async fn remove_pre_key(&mut self, prekey_id: PreKeyId) -> Result<(), SignalProtocolError> {
        let id: u32 = prekey_id.into();
        sqlx::query("DELETE FROM signal_pre_keys WHERE pre_key_id = ?")
            .bind(id)
            .execute(&self.pool)
            .await
            .map_err(|_| SignalProtocolError::InvalidPreKeyId)?;
        Ok(())
    }
}

pub struct DbSignedPreKeyStore {
    pool: SqlitePool,
}

#[async_trait(?Send)]
impl SignedPreKeyStore for DbSignedPreKeyStore {
    async fn get_signed_pre_key(
        &self,
        signed_prekey_id: SignedPreKeyId,
    ) -> Result<SignedPreKeyRecord, SignalProtocolError> {
        let id: u32 = signed_prekey_id.into();
        let row: Option<(Vec<u8>,)> = sqlx::query_as(
            "SELECT record_bytes FROM signal_signed_pre_keys WHERE signed_pre_key_id = ?",
        )
        .bind(id)
        .fetch_optional(&self.pool)
        .await
        .map_err(|_| SignalProtocolError::InvalidSignedPreKeyId)?;

        if let Some((bytes,)) = row {
            SignedPreKeyRecord::deserialize(&bytes)
                .map_err(|_| SignalProtocolError::InvalidSignedPreKeyId)
        } else {
            Err(SignalProtocolError::InvalidSignedPreKeyId)
        }
    }

    async fn save_signed_pre_key(
        &mut self,
        signed_prekey_id: SignedPreKeyId,
        record: &SignedPreKeyRecord,
    ) -> Result<(), SignalProtocolError> {
        let id: u32 = signed_prekey_id.into();
        let bytes = record
            .serialize()
            .map_err(|_| SignalProtocolError::InvalidSignedPreKeyId)?;

        sqlx::query("INSERT INTO signal_signed_pre_keys (signed_pre_key_id, record_bytes) VALUES (?, ?) ON CONFLICT(signed_pre_key_id) DO UPDATE SET record_bytes = excluded.record_bytes")
            .bind(id)
            .bind(bytes)
            .execute(&self.pool)
            .await
            .map_err(|_| SignalProtocolError::InvalidSignedPreKeyId)?;
        Ok(())
    }
}

pub struct DbKyberPreKeyStore {
    pool: SqlitePool,
}

#[async_trait(?Send)]
impl KyberPreKeyStore for DbKyberPreKeyStore {
    async fn get_kyber_pre_key(
        &self,
        kyber_prekey_id: KyberPreKeyId,
    ) -> Result<KyberPreKeyRecord, SignalProtocolError> {
        let id: u32 = kyber_prekey_id.into();
        let row: Option<(Vec<u8>,)> = sqlx::query_as(
            "SELECT record_bytes FROM signal_kyber_pre_keys WHERE kyber_pre_key_id = ?",
        )
        .bind(id)
        .fetch_optional(&self.pool)
        .await
        .map_err(|_| SignalProtocolError::InvalidKyberPreKeyId)?;

        if let Some((bytes,)) = row {
            KyberPreKeyRecord::deserialize(&bytes)
                .map_err(|_| SignalProtocolError::InvalidKyberPreKeyId)
        } else {
            Err(SignalProtocolError::InvalidKyberPreKeyId)
        }
    }

    async fn save_kyber_pre_key(
        &mut self,
        kyber_prekey_id: KyberPreKeyId,
        record: &KyberPreKeyRecord,
    ) -> Result<(), SignalProtocolError> {
        let id: u32 = kyber_prekey_id.into();
        let bytes = record
            .serialize()
            .map_err(|_| SignalProtocolError::InvalidKyberPreKeyId)?;

        sqlx::query("INSERT INTO signal_kyber_pre_keys (kyber_pre_key_id, record_bytes) VALUES (?, ?) ON CONFLICT(kyber_pre_key_id) DO UPDATE SET record_bytes = excluded.record_bytes")
            .bind(id)
            .bind(bytes)
            .execute(&self.pool)
            .await
            .map_err(|_| SignalProtocolError::InvalidKyberPreKeyId)?;
        Ok(())
    }

    async fn mark_kyber_pre_key_used(
        &mut self,
        _kyber_prekey_id: KyberPreKeyId,
        _ec_prekey_id: SignedPreKeyId,
        _base_key: &PublicKey,
    ) -> Result<(), SignalProtocolError> {
        Ok(())
    }
}

pub struct DbSessionStore {
    pool: SqlitePool,
}

#[async_trait(?Send)]
impl SessionStore for DbSessionStore {
    async fn load_session(
        &self,
        address: &ProtocolAddress,
    ) -> Result<Option<SessionRecord>, SignalProtocolError> {
        let name = address.name();
        let device_id: u32 = address.device_id().into();

        let row: Option<(Vec<u8>,)> = sqlx::query_as(
            "SELECT record_bytes FROM signal_sessions WHERE name = ? AND device_id = ?",
        )
        .bind(name)
        .bind(device_id)
        .fetch_optional(&self.pool)
        .await
        .map_err(|_| SignalProtocolError::UntrustedIdentity(address.clone()))?;

        if let Some((bytes,)) = row {
            let record = SessionRecord::deserialize(&bytes)
                .map_err(|_| SignalProtocolError::UntrustedIdentity(address.clone()))?;
            Ok(Some(record))
        } else {
            Ok(None)
        }
    }

    async fn store_session(
        &mut self,
        address: &ProtocolAddress,
        record: &SessionRecord,
    ) -> Result<(), SignalProtocolError> {
        let name = address.name();
        let device_id: u32 = address.device_id().into();
        let bytes = record
            .serialize()
            .map_err(|_| SignalProtocolError::UntrustedIdentity(address.clone()))?;

        sqlx::query("INSERT INTO signal_sessions (name, device_id, record_bytes) VALUES (?, ?, ?) ON CONFLICT(name, device_id) DO UPDATE SET record_bytes = excluded.record_bytes")
            .bind(name)
            .bind(device_id)
            .bind(bytes)
            .execute(&self.pool)
            .await
            .map_err(|_| SignalProtocolError::UntrustedIdentity(address.clone()))?;
        Ok(())
    }
}
