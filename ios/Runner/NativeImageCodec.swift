import Foundation
import ImageIO
import UniformTypeIdentifiers

/// C ABI called directly by Rust for the container formats Rust has no decoder
/// for — HEIC/HEIF from the camera above all. ImageIO decodes every format the
/// OS knows; Rust re-encodes the result to WebP itself. Flutter is not involved.
@_cdecl("twonly_decode_image_to_png")
func twonlyDecodeImageToPng(
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
