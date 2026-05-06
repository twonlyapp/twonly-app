struct TwonlyIdentity {}

struct NostrIdentity {}

struct KeyManager {
    main_key: [u8; 32],
}

impl KeyManager {
    fn try_from_keychain() -> KeyManager {
        todo!();
    }

    fn create_new() {
        // generates main_key

        // generates signal identity
        // generates nostr identity
    }

    fn get_signal_identity() {}

    fn recover_from_trusted_friends() {
        //
    }

    fn generate_backup_key() {}

    fn recover_from_backup() {
        //
    }
}
