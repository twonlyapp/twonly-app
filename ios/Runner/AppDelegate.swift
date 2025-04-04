import Flutter
import UIKit
import UserNotifications
import CryptoKit
import Foundation


@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    if #available(iOS 10.0, *) {
        //UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
      
      UNUserNotificationCenter.current().delegate = self

    // if (@available(iOS 10.0, *)) {
    //   [UNUserNotificationCenter currentNotificationCenter].delegate = (id<UNUserNotificationCenterDelegate>) self;
    // }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
    override func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        NSLog("Application delegate method userNotificationCenter:didReceive:withCompletionHandler: is called with user info: %@", response.notification.request.content.userInfo)
        //...
    }

    override func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        NSLog("userNotificationCenter:willPresent")
        completionHandler([.alert, .sound])
    }

    
}


import Security
import CommonCrypto
import Foundation
import CryptoKit

class KeychainHelper {
    static func save(key: String, data: Data) -> OSStatus {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        SecItemDelete(query as CFDictionary) // Delete any existing item
        return SecItemAdd(query as CFDictionary, nil)
    }

    static func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var dataTypeRef: AnyObject? = nil
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)

        if status == errSecSuccess {
            return dataTypeRef as? Data
        } else {
            return nil
        }
    }
}

// Function to decrypt data
func decrypt(data: Data, key: SymmetricKey) -> Data? {
    do {
        // Extract nonce, ciphertext, and tag
        let nonceData = data.prefix(12) // ChaCha20-Poly1305 nonce is 12 bytes
        let ciphertext = data.dropFirst(12).dropLast(16) // Exclude nonce and tag
        let tag = data.suffix(16) // Last 16 bytes are the tag
        
        // Create a nonce from the extracted nonce data
        let nonce = try ChaChaPoly.Nonce(data: nonceData)
        
        // Create a sealed box with the ciphertext and tag
        let sealedBox = try ChaChaPoly.SealedBox(nonce: nonce, ciphertext: ciphertext, tag: tag)
        
        // Decrypt the data
        let decryptedData = try ChaChaPoly.open(sealedBox, using: key)
        return decryptedData
    } catch {
        print("Decryption error: \(error)")
        return nil
    }
}


func handleReceivedMessage(encryptedMessage: Data, keyID: String) {
    // Load the AES key from Keychain
    guard let keyData = KeychainHelper.load(key: keyID) else {
        print("Key not found")
        return
    }
    
    let key = SymmetricKey(data: keyData);

    // Decrypt the message
    if let decryptedData = decrypt(data: encryptedMessage, key: key) {
        let decryptedMessage = String(data: decryptedData, encoding: .utf8)
        print("Decrypted message: \(decryptedMessage ?? "nil")")
    } else {
        print("Decryption failed")
    }
}
