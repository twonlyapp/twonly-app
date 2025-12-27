import CryptoKit
import Flutter
import Foundation
import UIKit
import UserNotifications
import flutter_sharing_intent

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

    override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {

         let sharingIntent = SwiftFlutterSharingIntentPlugin.instance
         if sharingIntent.hasSameSchemePrefix(url: url) {
             return sharingIntent.application(app, open: url, options: options)
         }

         // Proceed url handling for other Flutter libraries like app_links
         return super.application(app, open: url, options:options)
       }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    NSLog(
      "Application delegate method userNotificationCenter:didReceive:withCompletionHandler: is called with user info: %@",
      response.notification.request.content.userInfo)
    //...
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    NSLog("userNotificationCenter:willPresent")

    /*
     debugging NotificationService
    let pushKeys = getPushKey();
    print(pushKeys)
    
    let bestAttemptContent = notification.request.content
    
    guard let _userInfo = bestAttemptContent.userInfo as? [String: Any],
          let push_data = bestAttemptContent.userInfo["push_data"] as? String else {
        return completionHandler([.alert, .sound])
    }
    
    let data = getPushNotificationData(pushDataJson: push_data)
    print(data)
    */

    completionHandler([.alert, .sound])
  }

}
