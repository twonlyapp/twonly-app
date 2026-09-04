import AppIntents
import CryptoKit
import Flutter
import Foundation
import UIKit
import UserNotifications
import WidgetKit
import flutter_sharing_intent

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    // Must happen before launching finishes: BGTaskScheduler refuses an
    // identifier registered any later.
    BackgroundWork.register()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func applicationDidEnterBackground(_ application: UIApplication) {
    // The app is about to be suspended, and the socket with it. Reserve a later
    // slot so anything still queued is sent without the user coming back.
    BackgroundWork.scheduleFlush()
    super.applicationDidEnterBackground(application)
  }

  override func application(
    _ application: UIApplication,
    handleEventsForBackgroundURLSession identifier: String,
    completionHandler: @escaping () -> Void
  ) {
    if DirectMediaTransfer.shared.handleEvents(
      identifier: identifier,
      completion: completionHandler
    ) {
      return
    }
    super.application(
      application,
      handleEventsForBackgroundURLSession: identifier,
      completionHandler: completionHandler
    )
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
    WebxdcHostChannel.register(with: engineBridge.pluginRegistry)
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
/// opened, and keeps the app icon badge in step with them. The notification
/// service extension's final alert keeps APNs' request identifier, so both the
/// identifier and our `notification_id` user-info field have to be considered.
class NativeNotificationChannel {
  private static let channelName = "eu.twonly/notificationTap"
  private static let notificationIdsKey = "notification_ids"
  private static let badgeCountKey = "badge_count"

  static func register(with registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "TwonlyNativeNotifications") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "cancelNotifications":
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
      case "setBadgeCount":
        guard
          let arguments = call.arguments as? [String: Any],
          let count = arguments[badgeCountKey] as? Int
        else {
          result(
            FlutterError(
              code: "invalid_badge_count",
              message: "badge_count must be an integer",
              details: nil
            ))
          return
        }
        setBadgeCount(count, completion: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  /// iOS only takes an app icon badge from a notification payload, so a badge
  /// set by the notification service extension survives until the app itself
  /// overwrites it. Dart pushes the pending event count here whenever the
  /// notification outbox changes and on every resume.
  private static func setBadgeCount(_ count: Int, completion: @escaping FlutterResult) {
    let badge = max(0, count)
    guard #available(iOS 16.0, *) else {
      DispatchQueue.main.async {
        UIApplication.shared.applicationIconBadgeNumber = badge
        completion(nil)
      }
      return
    }
    UNUserNotificationCenter.current().setBadgeCount(badge) { error in
      DispatchQueue.main.async {
        if let error {
          completion(
            FlutterError(
              code: "badge_count_failed",
              message: error.localizedDescription,
              details: nil
            ))
        } else {
          completion(nil)
        }
      }
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
      // Rust rewrites the widget manifest from inside this process, and
      // WidgetKit only re-reads it when a timeline reload is requested. The
      // notification service extension covers pushes; this covers everything
      // the running app changes.
      if call.method == "reloadWidgets" {
        WidgetCenter.shared.reloadAllTimelines()
        result(nil)
        return
      }
      // Only the app can ask which widgets are actually on the home screen. A
      // widget extension is never told that its widget was removed, so without
      // this the placement file keeps describing widgets that are long gone.
      if call.method == "reconcileWidgets" {
        // Widgets need iOS 17; on anything older there is nothing to reconcile.
        guard #available(iOS 17.0, *) else {
          result(["supported": false, "matched": 0, "widgets": []])
          return
        }
        // `getCurrentConfigurations` answers on a background queue, but a
        // FlutterResult must be delivered on the platform thread — replying off
        // it is undefined and the reply can be dropped, leaving Dart awaiting a
        // future that never completes.
        let reply: (Any?) -> Void = { value in
          DispatchQueue.main.async { result(value) }
        }
        // Ask every widget that is really on a home screen to rebuild, then give
        // the extension a moment to answer. A widget the system merely still has
        // a record of is never displayed, so it is never asked for a timeline
        // and never stamps itself — which is what separates the two.
        let askedAt = Int(Date().timeIntervalSince1970)
        WidgetCenter.shared.reloadAllTimelines()
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 2) {
        WidgetCenter.shared.getCurrentConfigurations { configurations in
          switch configurations {
          case .success(let placed):
            var selections: [[Int64]] = []
            var report: [[String: Any]] = []
            // A widget that rebuilt just before the reload was asked for still
            // counts; the window only has to exclude records that never rebuild.
            let rebuilt = WidgetStorage.recentlyRebuiltIds(since: askedAt - 90)
            for (index, info) in placed.enumerated() {
              var entry: [String: Any] = [
                "kind": info.kind,
                "family": "\(info.family)",
                "mine": info.kind == widgetKind,
              ]
              if info.kind == widgetKind {
                if let intent = try? info.widgetConfigurationIntent(
                  of: TwonlyWidgetIntent.self)
                {
                  let ids = (intent.groups ?? []).compactMap { Int64($0.id) }
                  let live = rebuilt.contains("ios:\(WidgetStorage.selectionKey(ids))")
                  entry["group_ids"] = ids
                  entry["id"] = "ios:\(index):\(WidgetStorage.selectionKey(ids))"
                  entry["live"] = live
                  if live { selections.append(ids) }
                } else {
                  // The widget is placed even though its configuration will not
                  // decode. Recording it as unconfigured keeps it in the file:
                  // dropping it would report a removal that did not happen.
                  entry["configuration"] = "unreadable"
                  entry["group_ids"] = [Int64]()
                  entry["id"] = "ios:\(index)"
                  entry["live"] = false
                }
              }
              report.append(entry)
            }
            WidgetStorage.replaceIosSelections(selections)
            widgetLog.debug(
              "WidgetKit reports \(placed.count, privacy: .public) widget(s); \(selections.count, privacy: .public) rebuilt a timeline and are counted as placed"
            )
            reply([
              "supported": true,
              "matched": selections.count,
              "widgets": report,
            ])
          case .failure(let error):
            // Leave the file alone: a failed query is not evidence of removal.
            widgetLog.error(
              "getCurrentConfigurations failed: \(error.localizedDescription, privacy: .public)"
            )
            reply(
              FlutterError(
                code: "widget_configurations_unavailable",
                message: error.localizedDescription,
                details: nil
              ))
          }
        }
        }
        return
      }
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
