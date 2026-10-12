import Foundation
import Photos
import CoreLocation

/// Writes a finished media file into the user's photo library.
///
/// Called directly from Rust. Rust decides whether an export should happen,
/// embeds the EXIF metadata beforehand, and owns the resulting state; this only
/// hands the file to Photos.
@_cdecl("twonly_save_to_gallery")
public func twonlySaveToGallery(
  _ path: UnsafePointer<CChar>?,
  _ isVideo: Bool,
  _ createdAtMillis: Int64,
  _ hasLocation: Bool,
  _ latitude: Double,
  _ longitude: Double,
  _ accuracy: Double
) -> Bool {
  guard let path else { return false }
  let url = URL(fileURLWithPath: String(cString: path))
  guard FileManager.default.fileExists(atPath: url.path) else { return false }

  // Authorisation is requested for adding only; a denied library never blocks
  // the send itself, the export just fails.
  let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
  if status == .notDetermined {
    let waiting = DispatchSemaphore(value: 0)
    PHPhotoLibrary.requestAuthorization(for: .addOnly) { _ in waiting.signal() }
    waiting.wait()
  }
  switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
  case .authorized, .limited: break
  default: return false
  }

  var saved = false
  let finished = DispatchSemaphore(value: 0)
  PHPhotoLibrary.shared().performChanges {
    // Import the existing file as a resource; Photos need not materialise an
    // image just to create the asset. Rust keeps the file until this completes.
    let request = PHAssetCreationRequest.forAsset()
    let options = PHAssetResourceCreationOptions()
    options.originalFilename = url.lastPathComponent
    request.addResource(with: isVideo ? .video : .photo, fileURL: url, options: options)
    // Photos sorts on this, so it has to carry the capture time rather than
    // the moment the file was exported.
    request.creationDate = Date(timeIntervalSince1970: Double(createdAtMillis) / 1000)
    // Photos does not reliably derive PHAsset.location from WebP EXIF. Supply
    // it explicitly for every exported format, including videos.
    if hasLocation && latitude.isFinite && longitude.isFinite
      && (-90...90).contains(latitude) && (-180...180).contains(longitude) {
      request.location = accuracy.isFinite && accuracy >= 0
        ? CLLocation(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: 0, horizontalAccuracy: accuracy, verticalAccuracy: -1,
            timestamp: request.creationDate!)
        : CLLocation(latitude: latitude, longitude: longitude)
    }
  } completionHandler: { success, _ in
    saved = success
    finished.signal()
  }
  finished.wait()
  return saved
}
