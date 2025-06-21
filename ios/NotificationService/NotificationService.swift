//
//  NotificationService.swift
//  NotificationService
//
//  Created by Tobi on 03.04.25.
//

// import UserNotifications
// import CryptoKit
// import Foundation

// class NotificationService: UNNotificationServiceExtension {

//     var contentHandler: ((UNNotificationContent) -> Void)?
//     var bestAttemptContent: UNMutableNotificationContent?

//     override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
//         self.contentHandler = contentHandler
//         bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

//         if let bestAttemptContent = bestAttemptContent {

//             guard let _ = bestAttemptContent.userInfo as? [String: Any],
//                   let push_data = bestAttemptContent.userInfo["push_data"] as? String else {
//                 return contentHandler(bestAttemptContent);
//             }

//             let data = getPushNotificationData(pushDataJson: push_data)

//             if data != nil {
//                 if data!.title == "blocked" {
//                     NSLog("Block message because user is blocked!")
//                     // https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.usernotifications.filtering
//                     return contentHandler(UNNotificationContent())
//                 }
//                 bestAttemptContent.title = data!.title;
//                 bestAttemptContent.body = data!.body;
//                 bestAttemptContent.threadIdentifier = String(format: "%d", data!.notificationId)
//             } else {
//                 bestAttemptContent.title = "\(bestAttemptContent.title)"
//             }

//             contentHandler(bestAttemptContent)
//         }
//     }

//     override func serviceExtensionTimeWillExpire() {
//         // Called just before the extension will be terminated by the system.
//         // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
//         if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
//             contentHandler(bestAttemptContent)
//         }
//     }

// }

// enum PushKind: String, Codable {
//     case text
//     case twonly
//     case video
//     case image
//     case contactRequest
//     case acceptRequest
//     case storedMediaFile
//     case reaction
//     case testNotification
//     case reopenedMedia
//     case reactionToVideo
//     case reactionToText
//     case reactionToImage
//     case response
// }

// import CryptoKit
// import Foundation
// import Security

// func getPushNotificationData(pushDataJson: String) -> (title: String, body: String, notificationId: Int)? {
//     // Decode the pushDataJson
//     guard let pushData = decodePushData(pushDataJson) else {
//         NSLog("Failed to decode push data")
//         return nil
//     }

//     var pushKind: PushKind?
//     var displayName: String?
//     var fromUserId: Int?
//     var blocked: Bool?

//     // Check the keyId
//     if pushData.keyId == 0 {
//         let key = "InsecureOnlyUsedForAddingContact".data(using: .utf8)!.map { Int($0) }
//         pushKind = tryDecryptMessage(key: key, pushData: pushData)
//     } else {
//         let pushKeys = getPushKey()
//         if pushKeys != nil {
//             for (userId, userKeys) in pushKeys! {
//                 for key in userKeys.keys {
//                     if key.id == pushData.keyId {
//                         pushKind = tryDecryptMessage(key: key.key, pushData: pushData)
//                         if pushKind != nil {
//                             displayName = userKeys.displayName
//                             fromUserId = userId
//                             blocked = userKeys.blocked
//                             break
//                         }
//                     }
//                 }
//                 // Found correct key and user
//                 if displayName != nil { break }
//             }
//         } else {
//             NSLog("pushKeys are empty")
//         }
//     }

//     if blocked == true {
//         return ("blocked", "blocked", 0)
//     }

//     // Handle the push notification based on the pushKind
//     if let pushKind = pushKind {

//         if pushKind == .testNotification {
//             return ("Test Notification", "This is a test notification.", 0)
//         } else if displayName != nil && fromUserId != nil {
//             return (displayName!, getPushNotificationText(pushKind: pushKind), fromUserId!)
//         } else {
//             return ("", getPushNotificationTextWithoutUserId(pushKind: pushKind), 1)
//         }

//     } else {
//         NSLog("Failed to decrypt message or pushKind is nil")
//     }
//     return nil
// }

// func tryDecryptMessage(key: [Int], pushData: PushNotification) -> PushKind? {
//     // Convert the key from [Int] to Data
//     let keyData = Data(key.map { UInt8($0) }) // Convert Int to UInt8

//     guard let nonceData = Data(base64Encoded: pushData.nonce),
//               let cipherTextData = Data(base64Encoded: pushData.cipherText),
//               let macData = Data(base64Encoded: pushData.mac) else {
//         NSLog("Failed to decode base64 strings")
//         return nil
//     }

//     do {
//         // Create a nonce for ChaChaPoly
//         let nonce = try ChaChaPoly.Nonce(data: nonceData)

//         // Create a sealed box for ChaChaPoly
//         let sealedBox = try ChaChaPoly.SealedBox(nonce: nonce, ciphertext: cipherTextData, tag: macData)

//         // Decrypt the data using the key
//         let decryptedData = try ChaChaPoly.open(sealedBox, using: SymmetricKey(data: keyData))

//         // Convert decrypted data to a string
//         if let decryptedMessage = String(data: decryptedData, encoding: .utf8) {
//             NSLog("Decrypted message: \(decryptedMessage)")

//             // Here you can determine the PushKind based on the decrypted message
//             return determinePushKind(from: decryptedMessage)
//         }
//     } catch {
//         NSLog("Decryption failed: \(error)")
//     }

//     return nil
// }

// // Placeholder function to determine PushKind from the decrypted message
// func determinePushKind(from message: String) -> PushKind? {
//     // Implement your logic to determine the PushKind based on the message content
//     // For example, you might check for specific keywords or formats in the message
//     // This is just a placeholder implementation
//     if message.contains("text") {
//         return .text
//     } else if message.contains("video") {
//         return .video
//     } else if message.contains("image") {
//         return .image
//     } else if message.contains("twonly") {
//         return .twonly
//     } else if message.contains("contactRequest") {
//         return .contactRequest
//     } else if message.contains("acceptRequest") {
//         return .acceptRequest
//     } else if message.contains("storedMediaFile") {
//         return .storedMediaFile
//     } else if message.contains("reaction") {
//         return .reaction
//     } else if message.contains("testNotification") {
//         return .testNotification
//     } else if message.contains("reopenedMedia") {
//         return .reopenedMedia
//     } else if message.contains("reactionToVideo") {
//         return .reactionToVideo
//     } else if message.contains("reactionToText") {
//         return .reactionToText
//     } else if message.contains("reactionToImage") {
//         return .reactionToImage
//     } else if message.contains("response") {
//         return .response
//     } else {
//         return nil // Unknown PushKind
//     }
// }

// func decodePushData(_ json: String) -> PushNotification? {
//     // First, decode the base64 string
//     guard let base64Data = Data(base64Encoded: json) else {
//         NSLog("Failed to decode base64 string")
//         return nil
//     }

//     // Convert the base64 decoded data to a JSON string
//     guard let jsonString = String(data: base64Data, encoding: .utf8) else {
//         NSLog("Failed to convert base64 data to JSON string")
//         return nil
//     }

//     // Convert the JSON string to Data
//     guard let jsonData = jsonString.data(using: .utf8) else {
//         NSLog("Failed to convert JSON string to Data")
//         return nil
//     }

//     do {
//         // Use JSONDecoder to decode the JSON data into a PushNotification instance
//         let decoder = JSONDecoder()
//         let pushNotification = try decoder.decode(PushNotification.self, from: jsonData)
//         return pushNotification
//     } catch {
//         NSLog("Error decoding JSON: \(error)")
//         return nil
//     }
// }

// struct PushNotification: Codable {
//     let keyId: Int
//     let nonce: String
//     let cipherText: String
//     let mac: String

//     // You can add custom coding keys if the JSON keys differ from the property names
//     enum CodingKeys: String, CodingKey {
//         case keyId
//         case nonce
//         case cipherText
//         case mac
//     }
// }

// struct PushKeyMeta: Codable {
//     let id: Int
//     let key: [Int]
//     let createdAt: Date

//     enum CodingKeys: String, CodingKey {
//         case id
//         case key
//         case createdAt
//     }
// }

// struct PushUser: Codable {
//     let displayName: String
//     let keys: [PushKeyMeta]
//     let blocked: Bool?

//     enum CodingKeys: String, CodingKey {
//         case displayName
//         case keys
//         case blocked
//     }
// }

// func getPushKey() -> [Int: PushUser]? {
//     // Retrieve the data from secure storage (Keychain)
//     guard let data = readFromKeychain(key: "receivingPushKeys") else {
//         NSLog("No data found for key: receivingPushKeys")
//         return nil
//     }

//     do {
//         // Decode the JSON data into a dictionary
//         let jsonData = data.data(using: .utf8)!
//         let jsonMap = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]

//         var pushKeys: [Int: PushUser] = [:]

//         // Iterate through the JSON map and decode each PushUser
//         for (key, value) in jsonMap ?? [:] {
//                 if let userData = try? JSONSerialization.data(withJSONObject: value, options: []),
//                    let pushUser = try? JSONDecoder().decode(PushUser.self, from: userData) {
//                     pushKeys[Int(key)!] = pushUser
//                 }
//         }

//         return pushKeys
//     } catch {
//         NSLog("Error decoding JSON: \(error)")
//         return nil
//     }
// }

// // Helper function to read from Keychain
// func readFromKeychain(key: String) -> String? {
//     let query: [String: Any] = [
//         kSecClass as String: kSecClassGenericPassword,
//         kSecAttrAccount as String: key,
//         kSecReturnData as String: kCFBooleanTrue!,
//         kSecMatchLimit as String: kSecMatchLimitOne,
//         kSecAttrAccessGroup as String: "CN332ZUGRP.eu.twonly.shared" // Use your access group
//     ]

//     var dataTypeRef: AnyObject? = nil
//     let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

//     if status == errSecSuccess {
//         if let data = dataTypeRef as? Data {
//             return String(data: data, encoding: .utf8)
//         }
//     }

//     return nil
// }

// func getPushNotificationText(pushKind: PushKind) -> String {
//     let systemLanguage = Locale.current.languageCode ?? "en" // Get the current system language

//     var pushNotificationText: [PushKind: String] = [:]

//     // Define the messages based on the system language
//     if systemLanguage.contains("de") { // German
//         pushNotificationText = [
//             .text: "hat dir eine Nachricht gesendet.",
//             .twonly: "hat dir ein twonly gesendet.",
//             .video: "hat dir ein Video gesendet.",
//             .image: "hat dir ein Bild gesendet.",
//             .contactRequest: "möchte sich mit dir vernetzen.",
//             .acceptRequest: "ist jetzt mit dir vernetzt.",
//             .storedMediaFile: "hat dein Bild gespeichert.",
//             .reaction: "hat auf dein Bild reagiert.",
//             .testNotification: "Das ist eine Testbenachrichtigung.",
//             .reopenedMedia: "hat dein Bild erneut geöffnet.",
//             .reactionToVideo: "hat auf dein Video reagiert.",
//             .reactionToText: "hat auf deinen Text reagiert.",
//             .reactionToImage: "hat auf dein Bild reagiert.",
//             .response: "hat dir geantwortet."
//         ]
//     } else { // Default to English
//         pushNotificationText = [
//             .text: "has sent you a message.",
//             .twonly: "has sent you a twonly.",
//             .video: "has sent you a video.",
//             .image: "has sent you an image.",
//             .contactRequest: "wants to connect with you.",
//             .acceptRequest: "is now connected with you.",
//             .storedMediaFile: "has stored your image.",
//             .reaction: "has reacted to your image.",
//             .testNotification: "This is a test notification.",
//             .reopenedMedia: "has reopened your image.",
//             .reactionToVideo: "has reacted to your video.",
//             .reactionToText: "has reacted to your text.",
//             .reactionToImage: "has reacted to your image.",
//             .response: "has responded."
//         ]
//     }

//     // Return the corresponding message or an empty string if not found
//     return pushNotificationText[pushKind] ?? ""
// }

// func getPushNotificationTextWithoutUserId(pushKind: PushKind) -> String {
//     let systemLanguage = Locale.current.languageCode ?? "en" // Get the current system language

//     var pushNotificationText: [PushKind: String] = [:]

//     // Define the messages based on the system language
//     if systemLanguage.contains("de") { // German
//         pushNotificationText = [
//             .text: "Du hast eine Nachricht erhalten.",
//             .twonly: "Du hast ein twonly erhalten.",
//             .video: "Du hast ein Video erhalten.",
//             .image: "Du hast ein Bild erhalten.",
//             .contactRequest: "Du hast eine Kontaktanfrage erhalten.",
//             .acceptRequest: "Deine Kontaktanfrage wurde angenommen.",
//             .storedMediaFile: "Dein Bild wurde gespeichert.",
//             .reaction: "Du hast eine Reaktion auf dein Bild erhalten.",
//             .testNotification: "Das ist eine Testbenachrichtigung.",
//             .reopenedMedia: "hat dein Bild erneut geöffnet.",
//             .reactionToVideo: "Du hast eine Reaktion auf dein Video erhalten.",
//             .reactionToText: "Du hast eine Reaktion auf deinen Text erhalten.",
//             .reactionToImage: "Du hast eine Reaktion auf dein Bild erhalten.",
//             .response: "Du hast eine Antwort erhalten."
//         ]
//     } else { // Default to English
//         pushNotificationText = [
//             .text: "You got a message.",
//             .twonly: "You got a twonly.",
//             .video: "You got a video.",
//             .image: "You got an image.",
//             .contactRequest: "You got a contact request.",
//             .acceptRequest: "Your contact request has been accepted.",
//             .storedMediaFile: "Your image has been saved.",
//             .reaction: "You got a reaction to your image.",
//             .testNotification: "This is a test notification.",
//             .reopenedMedia: "has reopened your image.",
//             .reactionToVideo: "You got a reaction to your video.",
//             .reactionToText: "You got a reaction to your text.",
//             .reactionToImage: "You got a reaction to your image.",
//             .response: "You got a response."
//         ]
//     }

//     // Return the corresponding message or an empty string if not found
//     return pushNotificationText[pushKind] ?? ""
// }
