import CoreImage
import Foundation
import ImageIO
import UniformTypeIdentifiers
import Vision

/// C ABI called directly by Rust for the container formats Rust has no decoder
/// for — HEIC/HEIF from the camera above all. ImageIO decodes every format the
/// OS knows; Rust re-encodes the result to WebP itself. Flutter is not involved.
@_cdecl("twonly_decode_image_to_png")
public func twonlyDecodeImageToPng(
  _ input: UnsafePointer<CChar>?,
  _ output: UnsafePointer<CChar>?
) -> Bool {
  guard let input, let output else { return false }
  let inputURL = URL(fileURLWithPath: String(cString: input))
  let outputURL = URL(fileURLWithPath: String(cString: output))

  guard
    let source = CGImageSourceCreateWithURL(inputURL as CFURL, nil),
    let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
  else { return false }

  try? FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
  )
  // PNG is lossless, so the quality decision stays with Rust's WebP encode.
  let type: CFString
  if #available(iOS 14.0, *) {
    type = UTType.png.identifier as CFString
  } else {
    type = "public.png" as CFString
  }
  guard
    let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, type, 1, nil)
  else { return false }
  CGImageDestinationAddImage(destination, image, nil)
  return CGImageDestinationFinalize(destination)
}

/// Extracts subjects with the system model. Called on a Rust worker thread;
/// the temporary PNG keeps pixel buffers and their ownership inside Swift.
/// Returns 1 on success, -1 on older iOS, -2 for no subject, and 0 on failure.
@_cdecl("twonly_extract_sticker_foreground")
public func twonlyExtractStickerForeground(
  _ input: UnsafePointer<CChar>?,
  _ output: UnsafePointer<CChar>?
) -> Int32 {
  guard let input, let output else { return 0 }
  guard #available(iOS 17.0, *) else { return -1 }

  return autoreleasepool {
    let inputURL = URL(fileURLWithPath: String(cString: input))
    let outputURL = URL(fileURLWithPath: String(cString: output))
    guard var image = CIImage(contentsOf: inputURL, options: [.applyOrientationProperty: true])
    else { return 0 }

    // Match the Rust working size before allocating the instance mask. Apply
    // EXIF orientation first so portraits from the gallery stay upright.
    let edge = max(image.extent.width, image.extent.height)
    guard edge.isFinite, edge > 0 else { return 0 }
    if edge > 900 {
      let scale = 900 / edge
      image = image.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    }

    do {
      let handler = VNImageRequestHandler(ciImage: image, options: [:])
      let request = VNGenerateForegroundInstanceMaskRequest()
      try handler.perform([request])
      guard let observation = request.results?.first, !observation.allInstances.isEmpty
      else { return -2 }
      let foreground = try observation.generateMaskedImage(
        ofInstances: observation.allInstances,
        from: handler,
        croppedToInstancesExtent: true
      )
      let context = CIContext()
      try context.writePNGRepresentation(
        of: CIImage(cvPixelBuffer: foreground),
        to: outputURL,
        format: .RGBA8,
        colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!,
        options: [:]
      )
      return 1
    } catch {
      NSLog("Sticker foreground extraction failed: %@", error.localizedDescription)
      return 0
    }
  }
}
