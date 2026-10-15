# Bundled sticker segmentation model

`u2netp.onnx` is the compact U²-Net portrait/object segmentation model used to
create stickers entirely on device on **Android only**. Its bytes and the
`tract` ONNX inference runtime are excluded from iOS builds. iOS uses Apple
Vision foreground instance masks (iOS 17 or later), followed by the same Rust
WebP encoder, size limits and validation. Older iOS versions return an
unsupported error without bundling a fallback model.

- Source: <https://github.com/danielgatis/rembg/releases/download/v0.0.0/u2netp.onnx>
- Architecture/source project: <https://github.com/xuebinqin/U-2-Net>
- License: Apache-2.0
- License text distributed with the app: `assets/licenses/u2net.txt`
- SHA-256: `309c8469258dda742793dce0ebea8e6dd393174f89934733ecc8b14c76f4ddd8`
