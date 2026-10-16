import CoreLocation
import Flutter
import Foundation
import MapKit
import UIKit
import UserNotifications

private let memoryLocationPurpose = "MemoryLocation"

/// Shared permission flow for explicit settings and location-sharing actions.
final class NativeLocationPermission: NSObject, CLLocationManagerDelegate {
  private static var active: NativeLocationPermission?
  private let manager = CLLocationManager()
  private let completion: FlutterResult

  init(completion: @escaping FlutterResult) {
    self.completion = completion
    super.init()
    manager.delegate = self
  }

  static func register(with registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "TwonlyLocationMetadata") else { return }
    let channel = FlutterMethodChannel(
      name: "eu.twonly/location_metadata",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      if call.method == "startLiveLocation" || call.method == "stopLiveLocation" {
        guard let arguments = call.arguments as? [String: Any],
          let session = arguments["session_id"] as? String
        else { result(false); return }
        if call.method == "startLiveLocation" {
          NativeLiveLocation.shared.start(arguments: arguments, result: result)
        } else {
          NativeLiveLocation.shared.stop(expectedSession: session, completion: { result(true) })
        }
        return
      }
      if call.method == "hasPrecisePermission" {
        result(hasPreciseLocationPermission())
        return
      }
      if call.method == "resolveCity" {
        guard let arguments = call.arguments as? [String: Any],
          let latitude = arguments["latitude"] as? Double,
          let longitude = arguments["longitude"] as? Double,
          latitude.isFinite, longitude.isFinite,
          (-90...90).contains(latitude), (-180...180).contains(longitude),
          hasPreciseLocationPermission()
        else {
          result(nil)
          return
        }
        NativeCityRequest.start(
          location: CLLocation(latitude: latitude, longitude: longitude),
          locale: Locale(identifier: arguments["locale"] as? String ?? Locale.current.identifier),
          completion: result
        )
        return
      }
      guard call.method == "requestPrecisePermission" else {
        result(FlutterMethodNotImplemented)
        return
      }
      DispatchQueue.main.async {
        guard active == nil else {
          result(false)
          return
        }
        let request = NativeLocationPermission(completion: result)
        active = request
        request.begin()
      }
    }
  }

  private func begin() {
    switch manager.authorizationStatus {
    case .notDetermined:
      manager.requestWhenInUseAuthorization()
    case .authorizedAlways, .authorizedWhenInUse:
      ensureFullAccuracy()
    default:
      finish(false)
    }
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    switch manager.authorizationStatus {
    case .authorizedAlways, .authorizedWhenInUse: ensureFullAccuracy()
    case .denied, .restricted: finish(false)
    default: break
    }
  }

  private func ensureFullAccuracy() {
    guard manager.accuracyAuthorization != .fullAccuracy else {
      finish(true)
      return
    }
    manager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: memoryLocationPurpose) {
      [weak self] _ in
      guard let self else { return }
      self.finish(self.manager.accuracyAuthorization == .fullAccuracy)
    }
  }

  private func finish(_ granted: Bool) {
    guard Self.active === self else { return }
    Self.active = nil
    completion(granted)
  }
}

@_silgen_name("twonly_live_location_run")
private func liveLocationRun(_ directory: UnsafePointer<CChar>, _ request: UnsafePointer<CChar>) -> UnsafeMutablePointer<CChar>?
@_silgen_name("twonly_notification_string_free")
private func liveLocationFree(_ pointer: UnsafeMutablePointer<CChar>)

/// iOS runs a background Core Location session; force-quitting ends execution.
final class NativeLiveLocation: NSObject, CLLocationManagerDelegate {
  static let shared = NativeLiveLocation()
  static let stopAction = "TWONLY_STOP_LOCATION"
  private let manager = CLLocationManager()
  private let worker = DispatchQueue(label: "eu.twonly.live-location")
  private var session: String?
  private var directory: String?
  private var expiresAt: Int64 = 0
  private var latest: CLLocation?
  private var timer: Timer?
  private var expiryTimer: Timer?
  private var lastTick: Date = .distantPast
  private var busy = false
  private var stopping = false
  private static let notificationId = "twonly-live-location"

  override private init() {
    super.init()
    manager.delegate = self
  }

  func start(arguments: [String: Any], result: @escaping FlutterResult) {
    guard hasPreciseLocationPermission(),
      let session = arguments["session_id"] as? String,
      let directory = arguments["directory"] as? String,
      let deadline = arguments["expires_at_ms"] as? NSNumber,
      deadline.int64Value > Int64(Date().timeIntervalSince1970 * 1000)
    else { result(false); return }
    manager.stopUpdatingLocation()
    timer?.invalidate()
    expiryTimer?.invalidate()
    self.session = session
    self.directory = directory
    expiresAt = deadline.int64Value
    latest = nil
    stopping = false
    lastTick = .distantPast
    UserDefaults.standard.set(arguments, forKey: "twonly-live-location")
    manager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    manager.distanceFilter = kCLDistanceFilterNone
    manager.pausesLocationUpdatesAutomatically = false
    manager.allowsBackgroundLocationUpdates = true
    manager.showsBackgroundLocationIndicator = true
    manager.startUpdatingLocation()
    timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in self?.tick() }
    expiryTimer = Timer.scheduledTimer(withTimeInterval: max(0.1, Double(expiresAt) / 1000 - Date().timeIntervalSince1970), repeats: false) { [weak self] _ in
      self?.stop(expectedSession: session, completion: {})
    }
    let center = UNUserNotificationCenter.current()
    center.getNotificationCategories { categories in
      DispatchQueue.main.async {
        guard self.session == session, !self.stopping else { return }
        let action = UNNotificationAction(identifier: Self.stopAction, title: arguments["stop"] as? String ?? "Stop sharing", options: [.destructive])
        let category = UNNotificationCategory(identifier: "TWONLY_LIVE_LOCATION", actions: [action], intentIdentifiers: [])
        var categories = categories
        categories.update(with: category)
        center.setNotificationCategories(categories)
        let content = UNMutableNotificationContent()
        content.title = arguments["title"] as? String ?? "Sharing live location"
        content.body = arguments["body"] as? String ?? "Your current location is being shared"
        content.categoryIdentifier = category.identifier
        content.userInfo = ["live_location_session": session]
        center.add(UNNotificationRequest(identifier: Self.notificationId, content: content,
          trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)))
      }
    }
    tick()
    result(true)
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    if stopping { return }
    for location in locations where location.horizontalAccuracy >= 0 && location.horizontalAccuracy.isFinite {
      if latest == nil || location.timestamp >= latest!.timestamp { latest = location }
    }
    if Date().timeIntervalSince(lastTick) >= 30 { tick() }
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    if session != nil && !hasPreciseLocationPermission() {
      stop(expectedSession: session!, completion: {})
    }
  }

  private func tick() {
    guard !stopping, let session, let directory else { return }
    if Int64(Date().timeIntervalSince1970 * 1000) >= expiresAt || !hasPreciseLocationPermission() {
      stop(expectedSession: session, completion: {})
      return
    }
    if busy { return }
    busy = true
    lastTick = Date()
    var request: [String: Any] = ["action": "update", "session_id": session]
    if let location = latest, abs(location.timestamp.timeIntervalSinceNow) <= 120 {
      request["fix"] = [location.coordinate.latitude, location.coordinate.longitude,
        location.horizontalAccuracy, Int64(location.timestamp.timeIntervalSince1970 * 1000)] as [Any]
    }
    worker.async {
      let response = Self.run(directory: directory, request: request)
      DispatchQueue.main.async {
        self.busy = false
        if response?["ok"] as? Bool == true && response?["session"] is NSNull {
          self.stop(expectedSession: session, completion: {})
        }
      }
    }
  }

  func stop(expectedSession: String, completion: @escaping () -> Void) {
    let saved = UserDefaults.standard.dictionary(forKey: "twonly-live-location")
    guard (session ?? saved?["session_id"] as? String) == expectedSession else { completion(); return }
    stopping = true
    manager.stopUpdatingLocation()
    timer?.invalidate()
    expiryTimer?.invalidate()
    latest = nil
    let directory = self.directory ?? saved?["directory"] as? String
    session = nil
    UserDefaults.standard.removeObject(forKey: "twonly-live-location")
    let center = UNUserNotificationCenter.current()
    center.removeDeliveredNotifications(withIdentifiers: [Self.notificationId])
    center.removePendingNotificationRequests(withIdentifiers: [Self.notificationId])
    worker.async {
      if let directory { _ = Self.run(directory: directory, request: ["action": "stop", "session_id": expectedSession]) }
      DispatchQueue.main.async(execute: completion)
    }
  }

  private static func run(directory: String, request: [String: Any]) -> [String: Any]? {
    guard let data = try? JSONSerialization.data(withJSONObject: request),
      let json = String(data: data, encoding: .utf8)
    else { return nil }
    let pointer = directory.withCString { path in json.withCString { request in liveLocationRun(path, request) } }
    guard let pointer else { return nil }
    defer { liveLocationFree(pointer) }
    return try? JSONSerialization.jsonObject(with: Data(String(cString: pointer).utf8)) as? [String: Any]
  }
}

private func hasPreciseLocationPermission() -> Bool {
  let manager = CLLocationManager()
  return CLLocationManager.locationServicesEnabled()
    && [.authorizedAlways, .authorizedWhenInUse].contains(manager.authorizationStatus)
    && manager.accuracyAuthorization == .fullAccuracy
}

/// Retained until completion/timeout; a timeout cannot complete Flutter twice.
private final class NativeCityRequest {
  private static var active: [UUID: NativeCityRequest] = [:]
  private let id = UUID()
  private let completion: FlutterResult
  private var geocoder: CLGeocoder?
  private var mapRequest: AnyObject?
  private var timeout: DispatchWorkItem?
  private var finished = false

  private init(completion: @escaping FlutterResult) {
    self.completion = completion
  }

  static func start(location: CLLocation, locale: Locale, completion: @escaping FlutterResult) {
    let request = NativeCityRequest(completion: completion)
    active[request.id] = request
    request.begin(location: location, locale: locale)
  }

  private func begin(location: CLLocation, locale: Locale) {
    let timeout = DispatchWorkItem { [weak self] in self?.finish(nil) }
    self.timeout = timeout
    DispatchQueue.main.asyncAfter(deadline: .now() + 10, execute: timeout)
    if #available(iOS 26.0, *) {
      guard let request = MKReverseGeocodingRequest(location: location) else {
        finish(nil)
        return
      }
      mapRequest = request
      request.preferredLocale = locale
      request.getMapItems { [weak self] items, _ in
        let address = items?.first?.addressRepresentations
        self?.finish(Self.placeLabel(city: address?.cityName, country: address?.regionName))
      }
    } else {
      let geocoder = CLGeocoder()
      self.geocoder = geocoder
      geocoder.reverseGeocodeLocation(location, preferredLocale: locale) { [weak self] places, _ in
        let place = places?.first
        self?.finish(Self.placeLabel(city: place?.locality, country: place?.country))
      }
    }
  }

  private static func placeLabel(city: String?, country: String?) -> String? {
    for value in [city, country] {
      if let name = value?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
        return name
      }
    }
    return nil
  }

  private func finish(_ city: String?) {
    guard !finished else { return }
    finished = true
    timeout?.cancel()
    geocoder?.cancelGeocode()
    if #available(iOS 26.0, *), let request = mapRequest as? MKReverseGeocodingRequest {
      request.cancel()
    }
    Self.active.removeValue(forKey: id)
    completion(hasPreciseLocationPermission() ? city : nil)
  }
}

private final class NativeLocationRequest: NSObject, CLLocationManagerDelegate {
  private let manager = CLLocationManager()
  private let completion: (CLLocation?) -> Void
  private(set) var best: CLLocation?
  private var finished = false

  init(completion: @escaping (CLLocation?) -> Void) {
    self.completion = completion
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyBest
    manager.distanceFilter = kCLDistanceFilterNone
  }

  func start() {
    guard CLLocationManager.locationServicesEnabled(),
      [.authorizedAlways, .authorizedWhenInUse].contains(manager.authorizationStatus),
      manager.accuracyAuthorization == .fullAccuracy
    else {
      stop(returning: nil)
      return
    }
    manager.startUpdatingLocation()
  }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    for location in locations where location.horizontalAccuracy.isFinite
      && location.horizontalAccuracy >= 0 && abs(location.timestamp.timeIntervalSinceNow) <= 180 {
      if best == nil || location.horizontalAccuracy < best!.horizontalAccuracy {
        best = location
      }
    }
    if let best, best.horizontalAccuracy <= 50 {
      stop(returning: best)
    }
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    if (error as? CLError)?.code != .locationUnknown {
      stop(returning: best)
    }
  }

  func stop(returning location: CLLocation?) {
    guard !finished else { return }
    finished = true
    manager.stopUpdatingLocation()
    completion(location)
  }
}

private var activeNativeLocationRequest: NativeLocationRequest?

/// Synchronous C ABI used from Rust's blocking location worker.
@_cdecl("twonly_current_location")
public func twonlyCurrentLocation(
  _ timeoutMillis: Int64,
  _ latitude: UnsafeMutablePointer<Double>?,
  _ longitude: UnsafeMutablePointer<Double>?,
  _ accuracy: UnsafeMutablePointer<Double>?
) -> Bool {
  guard let latitude, let longitude, let accuracy else { return false }
  let finished = DispatchSemaphore(value: 0)
  var found: CLLocation?
  DispatchQueue.main.async {
    let request = NativeLocationRequest { location in
      found = location
      activeNativeLocationRequest = nil
      finished.signal()
    }
    activeNativeLocationRequest = request
    request.start()
  }
  if finished.wait(timeout: .now() + .milliseconds(Int(max(0, timeoutMillis)))) == .timedOut {
    DispatchQueue.main.sync {
      found = activeNativeLocationRequest?.best
      activeNativeLocationRequest?.stop(returning: found)
      activeNativeLocationRequest = nil
    }
  }
  guard let found else { return false }
  latitude.pointee = found.coordinate.latitude
  longitude.pointee = found.coordinate.longitude
  accuracy.pointee = found.horizontalAccuracy
  return true
}
