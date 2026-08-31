import Foundation
import Photos

/// Writes a finished media file into the user's photo library.
///
/// Called directly from Rust. Rust decides whether an export should happen,
/// embeds the EXIF metadata beforehand, and owns the resulting state; this only
/// hands the file to Photos.
@_cdecl("twonly_save_to_gallery")
func twonlySaveToGallery(
  _ path: UnsafePointer<CChar>?,
  _ isVideo: Bool,
  _ createdAtMillis: Int64
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
    let request: PHAssetChangeRequest? =
      isVideo
      ? PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
      : PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
    // Photos sorts on this, so it has to carry the capture time rather than
    // the moment the file was exported.
    request?.creationDate = Date(timeIntervalSince1970: Double(createdAtMillis) / 1000)
  } completionHandler: { success, _ in
    saved = success
    finished.signal()
  }
  finished.wait()
  return saved
}
