import CryptoKit
import Foundation
import Security
import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        if let bestAttemptContent = bestAttemptContent {

            guard bestAttemptContent.userInfo as? [String: Any] != nil,
                let push_data = bestAttemptContent.userInfo["push_data"] as? String
            else {
                return contentHandler(bestAttemptContent)
            }

            let data = getPushNotificationData(pushData: push_data)

            if data != nil {
                if data!.title == "blocked" {
                    NSLog("Block message because user is blocked!")
                    // https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.usernotifications.filtering
                    return contentHandler(UNNotificationContent())
                }
                bestAttemptContent.title = data!.title
                bestAttemptContent.body = data!.body
                bestAttemptContent.threadIdentifier = String(format: "%d", data!.notificationId)
            } else {
                NSLog("Could not decrypt message. Show default.")
                bestAttemptContent.title = "\(bestAttemptContent.title)"
            }

            contentHandler(bestAttemptContent)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}

func getPushNotificationData(pushData: String) -> (
    title: String, body: String, notificationId: Int64
)? {

    guard let data = Data(base64Encoded: pushData) else {
        NSLog("Failed to decode base64 string")
        return nil
    }

    do {
        let pushData = try EncryptedPushNotification(serializedBytes: data)

        var pushNotification: PushNotification?
        var pushUser: PushUser?

        // Check the keyId
        if pushData.keyID == 0 {
            let key = "InsecureOnlyUsedForAddingContact".data(using: .utf8)!
            pushNotification = tryDecryptMessage(key: key, pushData: pushData)
        } else {
            let pushUsers = getPushUsers()
            if pushUsers != nil {
                for tryPushUser in pushUsers! {
                    for pushKey in tryPushUser.pushKeys {
                        if pushKey.id == pushData.keyID {
                            pushNotification = tryDecryptMessage(
                                key: pushKey.key, pushData: pushData)
                            if pushNotification != nil {
                                pushUser = tryPushUser
                                if isUUIDNewer(pushUser!.lastMessageID, pushNotification!.messageID)
                                {
                                    //return ("blocked", "blocked", 0)
                                }
                                break
                            }
                        }
                    }
                    if pushUser != nil { break }
                }
            } else {
                NSLog("pushKeys are empty")
            }
        }

        if pushUser?.blocked == true {
            return ("blocked", "blocked", 0)
        }

        // Handle the push notification based on the pushKind
        if let pushNotification = pushNotification {

            if pushNotification.kind == .testNotification {
                return ("Test Notification", "This is a test notification.", 0)
            } else if pushUser != nil {
                return (
                    pushUser!.displayName,
                    getPushNotificationText(pushNotification: pushNotification).0, pushUser!.userID
                )
            } else {
                let content = getPushNotificationText(pushNotification: pushNotification)
                return (
                    content.1, content.0, 1
                )
            }

        } else {
            NSLog("Failed to decrypt message or pushKind is nil")
        }
        return nil
    } catch {
        NSLog("Error decoding JSON: \(error)")
        return nil
    }
}

func isUUIDNewer(_ uuid1: String, _ uuid2: String) -> Bool {
    guard uuid1.count >= 8, uuid2.count >= 8 else { return true }
    let hex1 = String(uuid1.prefix(8))
    let hex2 = String(uuid2.prefix(8))
    guard let timestamp1 = UInt32(hex1, radix: 16),
        let timestamp2 = UInt32(hex2, radix: 16)
    else { return true }
    return timestamp1 > timestamp2
}

func tryDecryptMessage(key: Data, pushData: EncryptedPushNotification) -> PushNotification? {

    do {
        // Create a nonce for ChaChaPoly
        let nonce = try ChaChaPoly.Nonce(data: pushData.nonce)

        // Create a sealed box for ChaChaPoly
        let sealedBox = try ChaChaPoly.SealedBox(
            nonce: nonce,
            ciphertext: pushData.ciphertext,
            tag: pushData.mac
        )

        // Decrypt the data using the key
        let decryptedData = try ChaChaPoly.open(sealedBox, using: SymmetricKey(data: key))

        // Here you can determine the PushKind based on the decrypted message
        return try PushNotification(serializedBytes: decryptedData)
    } catch {
        NSLog("Decryption failed: \(error)")
    }

    return nil
}

func getPushUsers() -> [PushUser]? {
    // Retrieve the data from secure storage (Keychain)
    guard let pushUsersB64 = readFromKeychain(key: "push_keys_receiving") else {
        NSLog("No data found for key: push_keys_receiving")
        return nil
    }
    guard let pushUsersBytes = Data(base64Encoded: pushUsersB64) else {
        NSLog("Failed to decode base64 push users")
        return nil
    }

    do {
        let pushUsers = try PushUsers(serializedBytes: pushUsersBytes)
        return pushUsers.users
    } catch {
        NSLog("Error decoding JSON: \(error)")
        return nil
    }
}

// Helper function to read from Keychain
func readFromKeychain(key: String) -> String? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecReturnData as String: kCFBooleanTrue!,
        kSecMatchLimit as String: kSecMatchLimitOne,
        kSecAttrAccessGroup as String: "CN332ZUGRP.eu.twonly.shared",  // Use your access group
    ]

    var dataTypeRef: AnyObject? = nil
    let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

    if status == errSecSuccess {
        if let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
    }

    return nil
}

func getPushNotificationText(pushNotification: PushNotification) -> (String, String) {
    let systemLanguage = Locale.current.language.languageCode?.identifier ?? "en"  // Get the current system language

    var pushNotificationText: [PushKind: String] = [:]
    var title = "Someone"

    // Define the messages based on the system language
    if systemLanguage.contains("de") {  // German
        title = "Jemand"
        pushNotificationText = [
            .text: "hat eine Nachricht{inGroup} gesendet.",
            .twonly: "hat ein twonly{inGroup} gesendet.",
            .video: "hat ein Video{inGroup} gesendet.",
            .image: "hat ein Bild{inGroup} gesendet.",
            .audio: "hat eine Sprachnachricht{inGroup} gesendet.",
            .contactRequest: "möchte sich mit dir vernetzen.",
            .acceptRequest: "ist jetzt mit dir vernetzt.",
            .storedMediaFile: "hat dein Bild gespeichert.",
            .reaction: "hat auf dein Bild reagiert.",
            .testNotification: "Das ist eine Testbenachrichtigung.",
            .reopenedMedia: "hat dein Bild erneut geöffnet.",
            .reactionToVideo: "hat mit {{content}} auf dein Video reagiert.",
            .reactionToText: "hat mit {{content}} auf deinen Text reagiert.",
            .reactionToImage: "hat mit {{content}} auf dein Bild reagiert.",
            .reactionToAudio: "hat mit {{content}} auf deine Sprachnachricht reagiert.",
            .response: "hat dir{inGroup} geantwortet.",
            .addedToGroup: "hat dich zu \"{{content}}\" hinzugefügt.",
        ]
    } else {  // Default to English
        pushNotificationText = [
            .text: "sent a message{inGroup}.",
            .twonly: "sent a twonly{inGroup}.",
            .video: "sent a video{inGroup}.",
            .image: "sent a image{inGroup}.",
            .audio: "sent a voice message{inGroup}.",
            .contactRequest: "wants to connect with you.",
            .acceptRequest: "is now connected with you.",
            .storedMediaFile: "has stored your image.",
            .reaction: "has reacted to your image.",
            .testNotification: "This is a test notification.",
            .reopenedMedia: "has reopened your image.",
            .reactionToVideo: "has reacted with {{content}} to your video.",
            .reactionToText: "has reacted with {{content}} to your text.",
            .reactionToImage: "has reacted with {{content}} to your image.",
            .reactionToAudio: "has reacted with {{content}} to your voice message.",
            .response: "has responded{inGroup}.",
            .addedToGroup: "has added you to \"{{content}}\"",
        ]
    }

    var content = pushNotificationText[pushNotification.kind] ?? ""

    if pushNotification.hasAdditionalContent {
        content.replace("{{content}}", with: pushNotification.additionalContent)
        content.replace("{inGroup}", with: " in {inGroup}")
        content.replace("{inGroup}", with: pushNotification.additionalContent)
    } else {
        content.replace("{inGroup}", with: "")
    }

    // Return the corresponding message or an empty string if not found
    return (content, title)
}
