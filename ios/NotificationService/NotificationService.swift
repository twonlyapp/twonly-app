//
//  NotificationService.swift
//  NotificationService
//
//  Created by Tobi on 03.04.25.
//

import UserNotifications
import CryptoKit
import Foundation

class NotificationService: UNNotificationServiceExtension {
    
    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        
        
        if let bestAttemptContent = bestAttemptContent {
            
            
            // Extract the ciphertext and nonce from the notification's userInfo
            guard let _userInfo = bestAttemptContent.userInfo as? [String: Any],
                  let ciphertextString = bestAttemptContent.userInfo["ciphertext"] as? String,
                  let nonceString = bestAttemptContent.userInfo["nonce"] as? String else {
                return
            }
            
            // Convert the base64 encoded strings to Data
            guard let ciphertextData = Data(base64Encoded: ciphertextString),
                  let nonceData = Data(base64Encoded: nonceString) else {
                return
            }
            
            // Create the key (32 bytes of "A")
            let keyString = String(repeating: "A", count: 32)
            guard let keyData = keyString.data(using: .utf8) else {
                return
            }
            
            // Ensure the key is 32 bytes
            guard keyData.count == 32 else {
                return
            }
            
            // Ensure the ciphertext is more than 16 Bytes
            guard ciphertextData.count >= 16 else {
                return
            }
            
            // Split the ciphertextData into the actual ciphertext and the tag
            let tagLength = 16
            let ciphertext = ciphertextData.prefix(ciphertextData.count - tagLength)
            let tag = ciphertextData.suffix(tagLength)
            
            // Create a SymmetricKey from the key data
            let key = SymmetricKey(data: keyData)
            
            // Decrypt the ciphertext using ChaCha20
            do {
                let nonce = try ChaChaPoly.Nonce(data: nonceData)
                let sealedBox = try ChaChaPoly.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: Data(tag))
                let decryptedData = try ChaChaPoly.open(sealedBox, using: key)
                
                // Convert decrypted data to a string
                if let decryptedMessage = String(data: decryptedData, encoding: .utf8) {
                    NSLog("Decrypted message: \(decryptedMessage)")
                    
                    bestAttemptContent.title = "\(bestAttemptContent.title)"
                    bestAttemptContent.body = decryptedMessage
                    
                }
            } catch {
                NSLog("Decryption failed: \(error)")
            }
            
            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
}
