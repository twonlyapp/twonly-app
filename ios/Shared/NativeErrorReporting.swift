import Foundation
import Sentry

/// Shared by Runner and the notification service extension. Consent lives in
/// the App Group so a push can start crash reporting without opening Rust or
/// Flutter first. Missing/unreadable consent always means disabled.
enum NativeErrorReporting {
  private static let dsn = "https://6b24a012c85144c9b522440a1d17d01c@glitchtip.twonly.eu/4"
  private static let lock = NSRecursiveLock()

  private static var consentURL: URL? {
    FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: "group.eu.twonly.runtime"
    )?.appendingPathComponent("error-reporting-consent")
  }

  static var isAllowed: Bool {
    readConsent(at: consentURL)
  }

  static func readConsent(at url: URL?) -> Bool {
    guard let url, let data = try? Data(contentsOf: url) else { return false }
    return data == Data("true".utf8)
  }

  static func setEnabled(_ enabled: Bool) throws {
    guard let url = consentURL else {
      throw NSError(domain: "eu.twonly.error_reporting", code: 1)
    }
    try Data((enabled ? "true" : "false").utf8).write(
      to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication]
    )
    startIfAllowed()
  }

  static func startIfAllowed() {
    lock.lock()
    defer { lock.unlock() }
    guard isAllowed else {
      if SentrySDK.isEnabled { SentrySDK.close() }
      return
    }
    guard !SentrySDK.isEnabled else { return }
    let isExtension = Bundle.main.bundleURL.pathExtension == "appex"
    // Extensions currently have their own marketing/build version. Attribute
    // their reports to the containing app's actual TestFlight release.
    let appBundle = isExtension
      ? Bundle(url: Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent()) ?? .main
      : .main
    SentrySDK.start { options in
      options.dsn = dsn
      // Read the containing app's mode so extension reports use the same value.
      #if DEBUG
      let fallbackEnvironment = "debug"
      #else
      let fallbackEnvironment = "release"
      #endif
      options.environment = (appBundle.object(forInfoDictionaryKey: "TwonlyBuildMode") as? String)?
        .lowercased() ?? fallbackEnvironment
      let version = appBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown"
      let build = appBundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
      options.releaseName = "\(appBundle.bundleIdentifier ?? "eu.twonly")@\(version)+\(build)"
      options.dist = build
      options.sendDefaultPii = false
      options.enableAutoSessionTracking = false
      options.enableAutoPerformanceTracing = false
      options.enableCaptureFailedRequests = false
      options.enableSwizzling = false
      options.enableAutoBreadcrumbTracking = false
      options.enableAppHangTracking = !isExtension
      options.beforeSend = { event in isAllowed ? event : nil }
      options.initialScope = { scope in
        scope.setTag(value: isExtension ? "notification_extension" : "application", key: "native_component")
        return scope
      }
    }
  }

  static func breadcrumb(_ operation: String) {
    guard isAllowed else { return }
    let breadcrumb = Breadcrumb(level: .info, category: "native.background")
    breadcrumb.message = operation
    SentrySDK.addBreadcrumb(breadcrumb)
  }

  static func warning(_ operation: String) {
    NSLog("Twonly background operation deferred: %@", operation)
    guard isAllowed else { return }
    let breadcrumb = Breadcrumb(level: .warning, category: "native.background")
    breadcrumb.message = operation
    SentrySDK.addBreadcrumb(breadcrumb)
  }

  /// Only fixed categories leave the device. Worker errors may contain SQL,
  /// paths, credentials or message content.
  static func failureReason(_ error: String?) -> String {
    switch error {
    case "Database operation cancelled; retry when active",
         "Native database admission cancelled",
         "Database operation deferred until foreground",
         "Notification run cancelled",
         "Notification run is closing":
      return "cancelled"
    case "Notification run is closed or unknown":
      return "notification_run_closed"
    case "attempted to acquire a connection on a closed pool":
      return "database_pool_closed"
    case "pool timed out while waiting for an open connection":
      return "database_pool_timeout"
    case "main_key could not be loaded from the key_chain",
         "Storage error: database exists but master key could not be loaded from secure storage":
      return "secure_storage"
    case "background maintenance panicked", "notification worker panicked",
         "Notification worker panicked", "notification finalization panicked",
         "Notification cleanup panicked":
      return "panic"
    default:
      return "unknown"
    }
  }

  static func isDeferredFailure(_ operation: String, error: String?) -> Bool {
    let reason = failureReason(error)
    // The supervisor closes a notification run on its deadline, even if the
    // extension has not called finalize yet. Its durable work retries later.
    return reason == "cancelled" || operation.hasSuffix("_expired")
      || (operation == "notification_finalize" && reason == "notification_run_closed")
  }

  static func failure(_ operation: String, error: String? = nil) {
    if isDeferredFailure(operation, error: error) {
      warning("\(operation)_cancelled")
      return
    }
    guard isAllowed else { return }
    let reason = failureReason(error)
    SentrySDK.capture(message: "Native background operation failed: \(operation)") { scope in
      scope.setLevel(.error)
      scope.setTag(value: operation, key: "native_operation")
      scope.setTag(value: reason, key: "native_failure_reason")
      scope.setFingerprint(["native-background", operation, reason])
    }
    // Extensions can be reclaimed as soon as the alert handler returns.
    // Give the asynchronous transport a short chance to persist/send the
    // event, without blocking the main-thread expiration callback.
    if Bundle.main.bundleURL.pathExtension == "appex", !Thread.isMainThread {
      SentrySDK.flush(timeout: 0.25)
    }
  }
}
