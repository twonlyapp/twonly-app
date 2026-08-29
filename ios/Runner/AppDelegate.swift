import CryptoKit
import Flutter
import Foundation
import UIKit
import UserNotifications
import flutter_sharing_intent
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self

    if let registrar = self.registrar(forPlugin: "VideoCompressionChannel") {
      VideoCompressionChannel.register(with: registrar.messenger())
    }

    WorkmanagerDebug.setCurrent(LoggingDebugHandler())

    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
      // Background tasks call AppEnvironment.init() too, so this engine needs
      // the runtime storage channel just as much as the implicit one.
      RuntimeStorageChannel.register(with: registry)
    }

    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "eu.twonly.periodic_task",
      frequency: NSNumber(value: 20 * 60)
    )

    WorkmanagerPlugin.registerBGProcessingTask(
      withIdentifier: "eu.twonly.processing_task"
    )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {

    let sharingIntent = SwiftFlutterSharingIntentPlugin.instance
    if sharingIntent.hasSameSchemePrefix(url: url) {
      return sharingIntent.application(app, open: url, options: options)
    }

    // Proceed url handling for other Flutter libraries like app_links
    return super.application(app, open: url, options: options)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    RuntimeStorageChannel.register(with: engineBridge.pluginRegistry)
    NativeNotificationChannel.register(with: engineBridge.pluginRegistry)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    NSLog(
      "Application delegate method userNotificationCenter:didReceive:withCompletionHandler: is called with user info: %@",
      response.notification.request.content.userInfo)
    super.userNotificationCenter(
      center, didReceive: response, withCompletionHandler: completionHandler)
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    NSLog("userNotificationCenter:willPresent")

    completionHandler([.alert, .sound])
  }

}

/// Withdraws only the native notifications whose message IDs Dart reports as
/// opened. The notification service extension's final alert keeps APNs' request
/// identifier, so both the identifier and our `notification_id` user-info field
/// have to be considered.
class NativeNotificationChannel {
  private static let channelName = "eu.twonly/notificationTap"
  private static let notificationIdsKey = "notification_ids"

  static func register(with registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "TwonlyNativeNotifications") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "cancelNotifications" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let arguments = call.arguments as? [String: Any],
        let values = arguments[notificationIdsKey] as? [String]
      else {
        result(
          FlutterError(
            code: "invalid_notification_ids",
            message: "notification_ids must be a list of strings",
            details: nil
          ))
        return
      }
      removeNotifications(Set(values), completion: result)
    }
  }

  private static func removeNotifications(
    _ notificationIds: Set<String>,
    completion: @escaping FlutterResult
  ) {
    guard !notificationIds.isEmpty else {
      completion(nil)
      return
    }
    let center = UNUserNotificationCenter.current()
    center.getDeliveredNotifications { delivered in
      let requestIds = delivered.compactMap { notification -> String? in
        let request = notification.request
        let notificationId = request.content.userInfo["notification_id"] as? String
        return notificationIds.contains(request.identifier)
          || notificationId.map(notificationIds.contains) == true
          ? request.identifier
          : nil
      }
      center.removeDeliveredNotifications(withIdentifiers: requestIds)
      center.getPendingNotificationRequests { pending in
        let pendingIds = pending.compactMap { request -> String? in
          let notificationId = request.content.userInfo["notification_id"] as? String
          return notificationIds.contains(request.identifier)
            || notificationId.map(notificationIds.contains) == true
            ? request.identifier
            : nil
        }
        center.removePendingNotificationRequests(withIdentifiers: pendingIds)
        DispatchQueue.main.async {
          completion(nil)
        }
      }
    }
  }
}

/// Hands Dart the App Group container shared between the app and its
/// extensions. Must be registered on every Flutter engine that runs
/// `AppEnvironment.init()`, not just the implicit one.
class RuntimeStorageChannel {
  private static let appGroupIdentifier = "group.eu.twonly.runtime"

  static func register(with registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "TwonlyRuntimeStorage") else {
      return
    }
    register(with: registrar.messenger())
  }

  static func register(with messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "eu.twonly/runtime_storage",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "runtimeSupportDirectory" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let container = FileManager.default.containerURL(
          forSecurityApplicationGroupIdentifier: appGroupIdentifier
        )
      else {
        result(
          FlutterError(
            code: "runtime_app_group_unavailable",
            message: "Could not open \(appGroupIdentifier)",
            details: nil
          ))
        return
      }
      let runtimeDirectory = container.appendingPathComponent("runtime", isDirectory: true)
      do {
        try FileManager.default.createDirectory(
          at: runtimeDirectory,
          withIntermediateDirectories: true
        )
        try (runtimeDirectory as NSURL).setResourceValue(
          URLFileProtection.completeUntilFirstUserAuthentication,
          forKey: .fileProtectionKey
        )
        result(runtimeDirectory.path)
      } catch {
        result(
          FlutterError(
            code: "runtime_directory_failed",
            message: error.localizedDescription,
            details: nil
          ))
      }
    }
  }
}
