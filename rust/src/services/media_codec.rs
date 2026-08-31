/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! Image codec work, previously done by `flutter_image_compress`.
//!
//! Both platforms encode WebP with libwebp — iOS has no system WebP encoder at
//! all and Android's `Bitmap.compress` routes through Skia to the same library
//! — so linking libwebp here is the identical code path without the Dart hop.
//! Only formats this crate cannot decode (HEIC/HEIF/AVIF) are handed to the
//! platform, which decodes them to PNG for us.

use crate::error::{Result, TwonlyError};
use crate::native::image as native_image;
use image::{DynamicImage, ImageReader};
use std::path::Path;

/// Quality the sender's media is encoded with, and the lower quality retried
/// when the first attempt is too large to be worth sending.
const SEND_QUALITY: f32 = 90.0;
const SEND_QUALITY_LARGE: f32 = 60.0;
const LARGE_IMAGE_BYTES: usize = 2_000_000;

const THUMBNAIL_MIN_EDGE: u32 = 300;
const THUMBNAIL_QUALITY: f32 = 50.0;
const CROP_QUALITY: f32 = 90.0;

/// Alpha at or below this counts as transparent when trimming borders. Matches
/// the threshold the Dart implementation used, so existing media crops the same.
const TRANSPARENT_ALPHA: u8 = 10;
/// Never crop down to a sliver; a result this small means the analysis was wrong.
const MIN_CROPPED_EDGE: u32 = 10;

/// Encodes with libwebp. RGB input is encoded without an alpha channel so
/// opaque photos do not pay for one.
fn encode_webp(image: &DynamicImage, quality: f32) -> Result<Vec<u8>> {
    let has_alpha = image.color().has_alpha();
    let encoder = if has_alpha {
        let rgba = image.to_rgba8();
        webp::Encoder::from_rgba(rgba.as_raw(), rgba.width(), rgba.height())
            .encode_simple(false, quality)
    } else {
        let rgb = image.to_rgb8();
        webp::Encoder::from_rgb(rgb.as_raw(), rgb.width(), rgb.height())
            .encode_simple(false, quality)
    };
    let memory = encoder
        .map_err(|error| TwonlyError::Generic(format!("webp encoding failed: {error:?}")))?;
    Ok(memory.to_vec())
}

/// Decodes any still image. The platform is only consulted for the formats this
/// crate has no decoder for, which in practice means HEIC/HEIF from an iPhone.
pub(crate) fn decode(path: &Path) -> Result<DynamicImage> {
    let reader = ImageReader::open(path)?
        .with_guessed_format()
        .map_err(|error| TwonlyError::Generic(error.to_string()))?;
    match reader.decode() {
        Ok(image) => Ok(image),
        Err(error) => {
            tracing::info!(
                path = %path.display(),
                %error,
                "asking the platform to decode an unsupported image format"
            );
            let decoded = path.with_extension("decoded.png");
            native_image::decode_to_png(path, &decoded)?;
            let image = ImageReader::open(&decoded)?
                .with_guessed_format()
                .map_err(|error| TwonlyError::Generic(error.to_string()))?
                .decode()
                .map_err(|error| TwonlyError::Generic(error.to_string()))?;
            let _ = std::fs::remove_file(&decoded);
            Ok(image)
        }
    }
}

/// Produces the file that actually gets encrypted and uploaded. A first pass at
/// high quality is re-encoded lower only when the result is big enough that the
/// quality loss is worth the transfer.
pub(crate) fn compress_for_send(source: &Path, destination: &Path) -> Result<()> {
    let image = decode(source)?;
    let mut encoded = encode_webp(&image, SEND_QUALITY)?;
    if encoded.len() >= LARGE_IMAGE_BYTES {
        match encode_webp(&image, SEND_QUALITY_LARGE) {
            Ok(smaller) => encoded = smaller,
            Err(error) => {
                tracing::warn!(%error, "keeping the high quality image after a failed re-encode");
            }
        }
    }
    write_atomically(destination, &encoded)
}

/// Scales down so the shorter edge lands on `THUMBNAIL_MIN_EDGE`, never scaling
/// an already small image up. A GIF decodes to its first frame, which is
/// exactly what its thumbnail should show.
pub(crate) fn create_image_thumbnail(source: &Path, destination: &Path) -> Result<()> {
    let image = decode(source)?;
    let thumbnail = downscale(&image, THUMBNAIL_MIN_EDGE);
    let encoded = encode_webp(&thumbnail, THUMBNAIL_QUALITY)?;
    write_atomically(destination, &encoded)
}

fn downscale(image: &DynamicImage, min_edge: u32) -> DynamicImage {
    let (width, height) = (image.width(), image.height());
    if width == 0 || height == 0 || (width <= min_edge && height <= min_edge) {
        return image.clone();
    }
    let scale = (min_edge as f32 / width as f32).max(min_edge as f32 / height as f32);
    if scale >= 1.0 {
        return image.clone();
    }
    let target_width = ((width as f32 * scale).round() as u32).max(1);
    let target_height = ((height as f32 * scale).round() as u32).max(1);
    image.resize_exact(
        target_width,
        target_height,
        image::imageops::FilterType::Lanczos3,
    )
}

/// Trims fully transparent borders left by the editor. Returns whether the
/// image was rewritten.
pub(crate) fn crop_transparent_borders(path: &Path) -> Result<bool> {
    let image = decode(path)?;
    if !image.color().has_alpha() {
        return Ok(false);
    }
    let rgba = image.to_rgba8();
    let Some(bounds) = opaque_bounds(&rgba) else {
        // Every pixel is transparent; there is nothing meaningful to keep.
        return Ok(false);
    };
    let (min_x, min_y, max_x, max_y) = bounds;
    if min_x == 0 && min_y == 0 && max_x == rgba.width() - 1 && max_y == rgba.height() - 1 {
        return Ok(false);
    }
    let width = max_x - min_x + 1;
    let height = max_y - min_y + 1;
    if width <= MIN_CROPPED_EDGE || height <= MIN_CROPPED_EDGE {
        return Ok(false);
    }
    let cropped = DynamicImage::ImageRgba8(rgba).crop_imm(min_x, min_y, width, height);
    let encoded = encode_webp(&cropped, CROP_QUALITY)?;
    write_atomically(path, &encoded)?;
    Ok(true)
}

/// Inclusive bounding box of every pixel that is not effectively transparent.
fn opaque_bounds(image: &image::RgbaImage) -> Option<(u32, u32, u32, u32)> {
    let (mut min_x, mut min_y) = (u32::MAX, u32::MAX);
    let (mut max_x, mut max_y) = (0_u32, 0_u32);
    let mut found = false;
    for (x, y, pixel) in image.enumerate_pixels() {
        if pixel.0[3] > TRANSPARENT_ALPHA {
            found = true;
            min_x = min_x.min(x);
            min_y = min_y.min(y);
            max_x = max_x.max(x);
            max_y = max_y.max(y);
        }
    }
    found.then_some((min_x, min_y, max_x, max_y))
}

/// The destination is often the file being read elsewhere, so it is replaced in
/// one step rather than being briefly truncated.
fn write_atomically(destination: &Path, bytes: &[u8]) -> Result<()> {
    if let Some(parent) = destination.parent() {
        std::fs::create_dir_all(parent)?;
    }
    let temporary = destination.with_extension("codec-tmp");
    std::fs::write(&temporary, bytes)?;
    std::fs::rename(&temporary, destination)?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use image::{Rgba, RgbaImage};

    fn transparent_bordered(width: u32, height: u32, inset: u32) -> RgbaImage {
        let mut image = RgbaImage::from_pixel(width, height, Rgba([0, 0, 0, 0]));
        for y in inset..height - inset {
            for x in inset..width - inset {
                image.put_pixel(x, y, Rgba([10, 200, 30, 255]));
            }
        }
        image
    }

    #[test]
    fn encodes_a_real_webp_that_decodes_back_to_the_same_size() {
        let directory = tempfile::tempdir().unwrap();
        let source = directory.path().join("source.png");
        let destination = directory.path().join("out.webp");
        DynamicImage::ImageRgba8(transparent_bordered(64, 48, 0))
            .save(&source)
            .unwrap();

        compress_for_send(&source, &destination).unwrap();

        let bytes = std::fs::read(&destination).unwrap();
        assert_eq!(&bytes[0..4], b"RIFF");
        assert_eq!(&bytes[8..12], b"WEBP");
        let decoded = decode(&destination).unwrap();
        assert_eq!((decoded.width(), decoded.height()), (64, 48));
    }

    #[test]
    fn thumbnails_shrink_the_shorter_edge_and_never_upscale() {
        let directory = tempfile::tempdir().unwrap();
        let source = directory.path().join("large.png");
        let destination = directory.path().join("thumb.webp");
        DynamicImage::ImageRgba8(transparent_bordered(1200, 600, 0))
            .save(&source)
            .unwrap();

        create_image_thumbnail(&source, &destination).unwrap();
        let thumbnail = decode(&destination).unwrap();
        assert_eq!(thumbnail.height(), THUMBNAIL_MIN_EDGE);
        assert_eq!(thumbnail.width(), 600);

        let small = directory.path().join("small.png");
        DynamicImage::ImageRgba8(transparent_bordered(64, 64, 0))
            .save(&small)
            .unwrap();
        create_image_thumbnail(&small, &destination).unwrap();
        assert_eq!(decode(&destination).unwrap().width(), 64);
    }

    #[test]
    fn crops_transparent_borders_only_when_it_changes_the_image() {
        let directory = tempfile::tempdir().unwrap();
        let path = directory.path().join("bordered.png");
        DynamicImage::ImageRgba8(transparent_bordered(100, 100, 20))
            .save(&path)
            .unwrap();

        assert!(crop_transparent_borders(&path).unwrap());
        let cropped = decode(&path).unwrap();
        assert_eq!((cropped.width(), cropped.height()), (60, 60));

        // A second pass has nothing left to trim.
        assert!(!crop_transparent_borders(&path).unwrap());
    }

    #[test]
    fn a_fully_opaque_image_is_never_cropped() {
        let directory = tempfile::tempdir().unwrap();
        let path = directory.path().join("opaque.png");
        DynamicImage::ImageRgb8(image::RgbImage::from_pixel(32, 32, image::Rgb([1, 2, 3])))
            .save(&path)
            .unwrap();
        assert!(!crop_transparent_borders(&path).unwrap());
    }
}
