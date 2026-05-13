# Cryptographic Architecture

## 1. Main Key
A cryptographically secure, immutable master key. Loss of this key, in the absence of valid backups, results in permanent loss of account access.

*Key Derivation*: Utilizes HKDF to derive subordinate keys.

- Authentication Token: Uploaded to the server for session authentication.
- Backup Key: Used to encrypt a backup
    - Backup Content: The encrypted backup encompasses 
        - Main Key
        - Identity keys
        - Local database (including contacts, public identities, memories (only references), and messages).
    - Lifecycle: Backups are refreshed daily and deleted after one year.
- Media Main Key: Used to wrap media-specific keys.
    - A new, cryptographically secure key is generated for every media file.
    - The media key is wrapped using AES-GCM and the Main Media Key and stored in the online database along side to the uploaded media file database entry.
    - The original media file is encrypted using AES-GCM and uploaded to the designated storage bucket.

## 3. Identity Keys
- Signal Identity
    - Generates a private and public key pair for secure communication.
- Nostr Identity
    - Generates a private and public key pair for Nostr network interactions.


## 1. Backup Keys
Independent, securely generated keys used to wrap the primary backup key.

### 1.1. Password-Based Backup
1. Derivation
    - Utilizes scrypt with the username as the salt (cost 65536) to derive a 64-byte sequence.
2. Allocation:
    - 32 bytes: Backup ID, used as the identifier to locate the backup on the server.
    - 32 bytes: Backup wrapper key.
3. Content
    - The payload contains the main key required to generate the auth token and the backup key.
4. Operation
    - The backup wrapper key encrypts the main key. The ciphertext is uploaded anonymously to the server, indexed by the Backup ID.
5. Security Measures
    - The server enforces strict rate limiting per IP address to prevent brute-force attacks.
6. Lifecycle    
    - These backup keys require a monthly refresh; otherwise, they are scheduled for deletion after two years.

### 1.2. Trusted Friends Keys (Passwordless Recovery)
1. Initiation
    - The recovering user generates a temporary ID (TempID) and a new ephemeral asymmetric key pair.
2. Request
    - A recovery request containing the TempID and the public key is transmitted to a trusted contact via a secure link.
3. Verification
    - The contact manually verifies the requestor's identity within their application to mitigate phishing risks.
4. Share Transmission
    - The contact encrypts a trusted friend share using the provided public key. This share includes the user IDs, the minimum threshold required for decryption, and the cryptographic share (utilizing Shamir's Secret Sharing).
5. Reconstruction
    - Upon receiving the required threshold of shares, the user reconstructs the shared secret data.
6. Second Factor (Optional)
    - The shared secret data may mandate an additional factor (PIN or Email). For a PIN factor, an unlock token and a PIN seed are used to securely retrieve the remaining share from the server without exposing the raw PIN.
7. Final Recovery
    - The decrypted recovery data provides the User ID, private key, and the backup master key necessary to restore the account and its backups.

## 4. Web Portal Upload Protocol
1. Initialization
    - The web portal generates a cryptographically secure symmetric key for end-to-end encrypted (E2EE) communication with the mobile application, alongside a newly registered session token.
2. Handshake
    - The mobile application scans the QR code containing the session token and the symmetric key.
3. Authorization
    - The application signals readiness via the server using the session token and securely provisions a temporary authentication token for media uploads over the established symmetric E2EE channel.
4. Key Exchange
    - The web portal encrypts the media file using a newly generated media key. It transmits this media key to the application (encrypted via the E2EE symmetric key) and receives the wrapped media key in return.
5. Upload
    - The web portal uploads the encrypted media file to the server, assigning it a device ID of 0.
6. Synchronization
    - Finally, the application requests all memories with a device ID lower than its current one (the device ID increments after a backup restoration).
