# Bundled sticker segmentation model

`u2netp.onnx` is the source U²-Net portrait/object segmentation model. Android
ships the equivalent, portable `u2netp.nnef.tar` graph with only `tract-nnef`
(pinned to 0.23.8). The ONNX importer is a development dependency; the facade,
CLI helpers and extra operator registries are excluded from production builds.
The model and inference runtime are excluded from iOS builds. iOS uses Apple
Vision foreground instance masks (iOS 17 or later), followed by the same Rust
WebP encoder, size limits and validation. Older iOS versions return an
unsupported error without bundling a fallback model.

- Source: <https://github.com/danielgatis/rembg/releases/download/v0.0.0/u2netp.onnx>
- Architecture/source project: <https://github.com/xuebinqin/U-2-Net>
- License: Apache-2.0
- License text distributed with the app: `assets/licenses/u2net.txt`
- SHA-256: `309c8469258dda742793dce0ebea8e6dd393174f89934733ecc8b14c76f4ddd8`

## Regenerating the Android artifact

From the repository root:

```sh
cargo run --manifest-path rust/Cargo.toml --release --example prepare_sticker_model
cargo test --manifest-path rust/Cargo.toml bundled_nnef_matches_original_onnx_outputs
```

The converter verifies the source digest and writes a deterministic archive
after architecture-independent type inference and decluttering. Kernel
optimization still runs on the Android CPU when the app loads the model.
No weights are quantized or retrained.
The comparison test checks every output tensor for three deterministic inputs
against the original ONNX inference pipeline, with an absolute tolerance of
`1e-5`, and rejects non-finite output values.

- NNEF artifact size: 4,790,272 bytes
- NNEF SHA-256: `51f72210a9541ecbfb460bde4426cfdd321de603ef140180c3c54dd1da094106`

When replacing the source model or tract version, regenerate the artifact,
review the comparison test, and update the digests here and in the Android
loader. Run a release build and check sticker creation on an Android device.
