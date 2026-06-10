
# User Discovery

User Discovery is a feature that allows users to discover other users in a decentralized system without any central authority. It uses Shamir's Secret Sharing to securely share and discover user information.

## Getting started

The User Discovery module is composed of the following components:

- **UserDiscovery** - The main struct which initializes the user discovery and provides access to the user discovery functionality.

- **UserDiscoveryStore** - A trait which has to be implemented. It is used to store and retrieve the user discovery data.
- **UserDiscoveryUtils** - A trait which has to be implemented. It is used to perform signature verification and signing.

```rust
use crate::user_discovery::{UserDiscovery, UserID};
use crate::user_discovery::stores::InMemoryStore; // Replace with your persistent store
use crate::user_discovery::traits::tests::TestingUtils; // Replace with your utils

const THRESHOLD: u8 = 2;

// Initialize user discovery for Alice
const ALICE_ID: UserID = 1;
let alice_ud = UserDiscovery::new(InMemoryStore::default(), TestingUtils::default()).unwrap();

// Set threshold, user ID, and the user's public key
alice_ud.initialize_or_update(THRESHOLD, ALICE_ID, vec![0; 32]).unwrap();

// Initialize user discovery for Bob
const BOB_ID: UserID = 2;
let bob_ud = UserDiscovery::new(InMemoryStore::default(), TestingUtils::default()).unwrap();
bob_ud.initialize_or_update(THRESHOLD, BOB_ID, vec![0; 32]).unwrap();



// Simulate network communication: Alice sends her current version to Bob
let bob_received_version_from_alice = alice_ud.get_current_version().unwrap();

// SEND FROM ALICE TO BOB: bob_received_version_from_alice

// Bob checks if he should request new messages
if bob_ud.should_request_new_messages(ALICE_ID, &bob_received_version_from_alice).unwrap() {

    // Bob has a old version and must now request to get the new messages

    // Bob fetches his current known version and sends it via the network to Alice
    let bob_stored_alice_version = bob_ud.get_contact_version(ALICE_ID)
        .unwrap()
        .unwrap_or_else(|| vec![0, 0]); // Note: In practice use actual default encoded version

    // SEND FROM BOB TO ALICE: bob_stored_alice_version
    
    // Alice loads the new messages for Bob. These only conclude changes since the provided version.
    let new_messages = alice_ud.get_new_messages(BOB_ID, &bob_stored_alice_version).unwrap();

    // SEND FROM ALICE TO BOB: new_messages
    
    // Bob processes the received user discovery messages
    bob_ud.handle_user_discovery_messages(ALICE_ID, new_messages).unwrap();

    // BOB is now able to promote ALICE to his other contacts
}

// <Involve more users>

// 4. Retrieve all newly discovered users and relationships
// In this example now new users where discovered, to see a more comprehensive example 
// see the test in the `mod.rs` fil.
let discovered_users = bob_ud.get_all_announced_users().unwrap();
for (user, connections) in discovered_users {
    println!("Discovered User: {} (Public ID: {})", user.user_id, user.public_id);
}
```

