use libsignal_protocol::{
    message_decrypt, message_encrypt, process_prekey_bundle, CiphertextMessageType, DeviceId,
    GenericSignedPreKey, IdentityKeyPair, InMemSignalProtocolStore, KeyPair, KyberPreKeyStore,
    PreKeyBundle, PreKeyRecord, PreKeyStore, ProtocolAddress, SignedPreKeyStore, Timestamp,
};
use std::time::{SystemTime, UNIX_EPOCH};

#[tokio::test]
async fn libsignal_compatibility_test() -> Result<(), Box<dyn std::error::Error>> {
    let mut csprng = rand::rng();

    // ==========================================
    // 1. SETUP BOB (Receiver)
    // ==========================================
    let bob_identity = IdentityKeyPair::generate(&mut csprng);
    let bob_registration_id = 5678;
    let mut bob_store =
        InMemSignalProtocolStore::new(bob_identity.clone(), bob_registration_id).unwrap();
    let bob_address = ProtocolAddress::new("bob".to_string(), DeviceId::try_from(1).unwrap());

    // Bob generates PreKey
    let bob_pre_key_id = 1.into();
    let bob_pre_key_pair = KeyPair::generate(&mut csprng);
    bob_store
        .pre_key_store
        .save_pre_key(
            bob_pre_key_id,
            &PreKeyRecord::new(bob_pre_key_id, &bob_pre_key_pair),
        )
        .await?;

    // Bob generates SignedPreKey
    let bob_signed_pre_key_id = 1.into();
    let bob_signed_pre_key_pair = KeyPair::generate(&mut csprng);
    let bob_signed_pre_key_sig = bob_identity
        .private_key()
        .calculate_signature_for_multipart_message(
            &[&bob_signed_pre_key_pair.public_key.serialize()],
            &mut csprng,
        )?;
    let timestamp = Timestamp::from_epoch_millis(
        SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_millis() as u64,
    );
    bob_store
        .signed_pre_key_store
        .save_signed_pre_key(
            bob_signed_pre_key_id,
            &libsignal_protocol::SignedPreKeyRecord::new(
                bob_signed_pre_key_id,
                timestamp,
                &bob_signed_pre_key_pair,
                &bob_signed_pre_key_sig,
            ),
        )
        .await?;

    // Bob generates KyberPreKey (Post-Quantum!)
    let bob_kyber_pre_key_id = 1.into();
    let bob_kyber_key_pair = libsignal_protocol::kem::KeyPair::generate(
        libsignal_protocol::kem::KeyType::Kyber1024,
        &mut csprng,
    );
    let bob_kyber_sig = bob_identity
        .private_key()
        .calculate_signature_for_multipart_message(
            &[&bob_kyber_key_pair.public_key.serialize()],
            &mut csprng,
        )?;

    // Kyber signature must be exactly 64 bytes
    let kyber_sig_arr: [u8; 64] = bob_kyber_sig[..].try_into().unwrap();

    bob_store
        .kyber_pre_key_store
        .save_kyber_pre_key(
            bob_kyber_pre_key_id,
            &libsignal_protocol::KyberPreKeyRecord::new(
                bob_kyber_pre_key_id,
                timestamp,
                &bob_kyber_key_pair,
                &kyber_sig_arr,
            ),
        )
        .await?;

    let bob_bundle = PreKeyBundle::new(
        bob_registration_id,
        DeviceId::try_from(1).unwrap(),
        Some((bob_pre_key_id, bob_pre_key_pair.public_key)),
        bob_signed_pre_key_id,
        bob_signed_pre_key_pair.public_key,
        bob_signed_pre_key_sig.to_vec(),
        bob_kyber_pre_key_id,
        bob_kyber_key_pair.public_key,
        kyber_sig_arr.to_vec(),
        *bob_identity.identity_key(),
    )?;

    // ==========================================
    // 2. SETUP ALICE (Sender)
    // ==========================================
    let alice_identity = IdentityKeyPair::generate(&mut csprng);
    let alice_registration_id = 1234;
    let mut alice_store =
        InMemSignalProtocolStore::new(alice_identity, alice_registration_id).unwrap();
    let alice_address = ProtocolAddress::new("alice".to_string(), DeviceId::try_from(1).unwrap());

    // Alice processes Bob's bundle
    process_prekey_bundle(
        &bob_address,
        &alice_address,
        &mut alice_store.session_store,
        &mut alice_store.identity_store,
        &bob_bundle,
        SystemTime::now(),
        &mut csprng,
    )
    .await?;

    // ==========================================
    // 3. EXCHANGE 100 MESSAGES
    // ==========================================
    let mut alice_to_bob = true;
    for i in 1..=100 {
        if alice_to_bob {
            let plaintext = format!("Message {} from Alice to Bob", i).into_bytes();
            let ciphertext = message_encrypt(
                &plaintext,
                &bob_address,
                &alice_address,
                &mut alice_store.session_store,
                &mut alice_store.identity_store,
                SystemTime::now(),
                &mut csprng,
            )
            .await?;

            if i == 1 {
                assert_eq!(ciphertext.message_type(), CiphertextMessageType::PreKey);
            } else {
                assert_eq!(ciphertext.message_type(), CiphertextMessageType::Whisper);
            }

            let decrypted = message_decrypt(
                &ciphertext,
                &alice_address,
                &bob_address,
                &mut bob_store.session_store,
                &mut bob_store.identity_store,
                &mut bob_store.pre_key_store,
                &bob_store.signed_pre_key_store,
                &mut bob_store.kyber_pre_key_store,
                &mut csprng,
            )
            .await?;
            assert_eq!(plaintext, decrypted);
        } else {
            let plaintext = format!("Message {} from Bob to Alice", i).into_bytes();
            let ciphertext = message_encrypt(
                &plaintext,
                &alice_address,
                &bob_address,
                &mut bob_store.session_store,
                &mut bob_store.identity_store,
                SystemTime::now(),
                &mut csprng,
            )
            .await?;

            assert_eq!(ciphertext.message_type(), CiphertextMessageType::Whisper);

            let decrypted = message_decrypt(
                &ciphertext,
                &bob_address,
                &alice_address,
                &mut alice_store.session_store,
                &mut alice_store.identity_store,
                &mut alice_store.pre_key_store,
                &alice_store.signed_pre_key_store,
                &mut alice_store.kyber_pre_key_store,
                &mut csprng,
            )
            .await?;
            assert_eq!(plaintext, decrypted);
        }

        alice_to_bob = !alice_to_bob;
    }

    Ok(())
}
