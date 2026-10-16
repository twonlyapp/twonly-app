-- Signal Identities (Stores remote IdentityKeys)
CREATE TABLE IF NOT EXISTS signal_identities (
    name TEXT NOT NULL,
    identity_key BLOB NOT NULL,
    timestamp INTEGER NOT NULL,
    PRIMARY KEY (name)
);

-- Signal PreKeys (Stores local one-time prekeys)
CREATE TABLE IF NOT EXISTS signal_pre_keys (
    pre_key_id INTEGER PRIMARY KEY,
    record_bytes BLOB NOT NULL
);

-- Signal Signed PreKeys (Stores local signed prekeys)
CREATE TABLE IF NOT EXISTS signal_signed_pre_keys (
    signed_pre_key_id INTEGER PRIMARY KEY,
    record_bytes BLOB NOT NULL
);

-- Signal Kyber PreKeys (Stores local PQC Kyber prekeys)
CREATE TABLE IF NOT EXISTS signal_kyber_pre_keys (
    kyber_pre_key_id INTEGER PRIMARY KEY,
    record_bytes BLOB NOT NULL
);

-- Signal Sessions (Stores active sessions with remote devices)
CREATE TABLE IF NOT EXISTS signal_sessions (
    name TEXT NOT NULL,
    device_id INTEGER NOT NULL,
    record_bytes BLOB NOT NULL,
    PRIMARY KEY (name, device_id)
);
