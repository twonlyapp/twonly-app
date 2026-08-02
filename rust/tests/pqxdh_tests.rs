#[tokio::test]
async fn test_twonly_api_100_messages() -> Result<(), Box<dyn std::error::Error>> {
    use rust_lib_twonly::database::Database;
    use rust_lib_twonly::signal::engine::RustSignalEngine;

    let _ = pretty_env_logger::try_init();

    // 1. Setup in-memory databases
    let alice_db = Database::new(&"sqlite::memory:".to_string(), None, false).await?;
    alice_db.run_migrations().await?;

    let bob_db = Database::new(&"sqlite::memory:".to_string(), None, false).await?;
    bob_db.run_migrations().await?;

    // 2. Setup Alice and Bob identity keys
    let alice_identity_bytes = RustSignalEngine::generate_identity_key_pair()?;
    let bob_identity_bytes = RustSignalEngine::generate_identity_key_pair()?;

    // 3. Initialize engines with the DB pools
    let alice_engine = RustSignalEngine::new_with_pool(
        alice_db.pool.clone(),
        alice_identity_bytes,
        1234,
        "alice".to_string(),
    )?;
    let bob_engine = RustSignalEngine::new_with_pool(
        bob_db.pool.clone(),
        bob_identity_bytes,
        5678,
        "bob".to_string(),
    )?;

    // 4. Bob generates a bundle
    let bob_bundle = bob_engine.generate_bundle(1, 1, 1).await?;

    // 5. Alice processes Bob's bundle
    alice_engine
        .process_prekey_bundle("bob".to_string(), 1, bob_bundle)
        .await?;

    // 6. Exchange 100 messages
    let mut alice_to_bob = true;
    for i in 1..=100 {
        if alice_to_bob {
            let plaintext = format!("Message {} from Alice to Bob", i).into_bytes();

            let ciphertext = alice_engine
                .encrypt_message("bob".to_string(), 1, plaintext.clone())
                .await?;

            let is_prekey = i == 1; // Only the first message is a PreKeySignalMessage
            let decrypted = bob_engine
                .decrypt_message("alice".to_string(), 1, ciphertext, is_prekey)
                .await?;

            assert_eq!(plaintext, decrypted);
        } else {
            let plaintext = format!("Message {} from Bob to Alice", i).into_bytes();

            let ciphertext = bob_engine
                .encrypt_message("alice".to_string(), 1, plaintext.clone())
                .await?;

            let decrypted = alice_engine
                .decrypt_message("bob".to_string(), 1, ciphertext, false)
                .await?;

            assert_eq!(plaintext, decrypted);
        }
        alice_to_bob = !alice_to_bob;
    }

    Ok(())
}
