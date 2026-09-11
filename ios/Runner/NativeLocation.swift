import CoreLocation
import Flutter
import Foundation

private let memoryLocationPurpose = "MemoryLocation"

/// Permission is requested only from the settings switch through this channel.
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
    for location in locations where location.horizontalAccuracy >= 0 {
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
func twonlyCurrentLocation(
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
