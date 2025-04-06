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
