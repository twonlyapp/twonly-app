/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! On-device sticker creation and validation.
//!
//! iOS uses Apple Vision for foreground extraction. Only Android bundles the
//! U²-Net model and inference runtime; both share the same bounded WebP
//! encoder.

use crate::api::proto::client::{self as proto, additional_message_data};
use crate::error::{Result, TwonlyError};
use crate::services::media_codec;
use image::{imageops, DynamicImage, ImageDecoder, Rgba, RgbaImage};
use prost::Message as _;
use sha2::{Digest, Sha256};
use std::io::Cursor;
use std::path::Path;

#[cfg(any(target_os = "android", test))]
mod android;

const WORKING_EDGE: u32 = 900;

pub(crate) const MAX_STICKER_EDGE: u32 = 300;

pub(crate) const MAX_STICKER_BYTES: usize = 128 * 1024;

pub(crate) const STICKER_VERSION: u32 = 1;

const TRANSPARENT_ALPHA: u8 = 10;

/// A 300 px RGBA PNG stays far below this even without compression.
const MAX_EDITED_BYTES: usize = 1024 * 1024;

#[derive(Clone, Debug, PartialEq, Eq)]

pub struct StickerOutput {
    pub webp: Vec<u8>,
    pub sha256: Vec<u8>,
    pub content_hash: String,
    pub width: u32,
    pub height: u32,
}

fn sticker_error(message: impl Into<String>) -> TwonlyError {
    TwonlyError::Generic(message.into())
}

/// Removes the background from `source`, trims transparent borders and returns
/// a compact transparent WebP suitable for embedding in a text message.
pub(crate) fn create(source: &Path) -> Result<StickerOutput> {
    encode_foreground(remove_background(source)?)
}

#[cfg(target_os = "android")]
fn remove_background(source: &Path) -> Result<RgbaImage> {
    android::remove_background(source)
}

#[cfg(target_os = "ios")]
fn remove_background(source: &Path) -> Result<RgbaImage> {
    crate::native::image::extract_foreground(source)
}

#[cfg(not(any(target_os = "android", target_os = "ios")))]
fn remove_background(_source: &Path) -> Result<RgbaImage> {
    Err(sticker_error(
        "sticker creation is only available on Android and iOS",
    ))
}

fn encode_foreground(composited: RgbaImage) -> Result<StickerOutput> {
    let composited = DynamicImage::ImageRgba8(composited)
        .thumbnail(WORKING_EDGE, WORKING_EDGE)
        .to_rgba8();

    let padded = trim_and_pad(&composited)?;

    encode_sticker(DynamicImage::ImageRgba8(padded).thumbnail(MAX_STICKER_EDGE, MAX_STICKER_EDGE))
}

/// Re-encodes a sticker the user edited by hand, such as one with parts
/// erased. Flutter renders the edit as PNG at sticker size; trimming runs
/// again so a removed person leaves no empty space behind.
pub(crate) fn from_edited(png: &[u8]) -> Result<StickerOutput> {
    if png.is_empty() || png.len() > MAX_EDITED_BYTES {
        return Err(sticker_error("edited sticker has an invalid size"));
    }

    if image::guess_format(png).ok() != Some(image::ImageFormat::Png) {
        return Err(sticker_error("edited sticker is not PNG"));
    }

    let decoder = image::codecs::png::PngDecoder::new(Cursor::new(png))
        .map_err(|error| sticker_error(format!("invalid edited sticker: {error}")))?;

    let (width, height) = decoder.dimensions();

    if width == 0 || height == 0 || width > MAX_STICKER_EDGE || height > MAX_STICKER_EDGE {
        return Err(sticker_error(
            "edited sticker dimensions are outside the allowed bounds",
        ));
    }

    let edited = DynamicImage::from_decoder(decoder)
        .map_err(|error| sticker_error(format!("invalid edited sticker: {error}")))?
        .to_rgba8();

    // Unlike a fresh cutout, what remains must not be enlarged to fill the
    // sticker: it is already at its final resolution.
    encode_sticker(DynamicImage::ImageRgba8(trim_and_pad(&edited)?))
}

fn trim_and_pad(composited: &RgbaImage) -> Result<RgbaImage> {
    let bounds = visible_bounds(composited)
        .ok_or_else(|| sticker_error("no foreground was found in this image"))?;

    let cropped = imageops::crop_imm(
        composited,
        bounds.0,
        bounds.1,
        bounds.2 - bounds.0 + 1,
        bounds.3 - bounds.1 + 1,
    )
    .to_image();

    let padding =
        ((cropped.width().max(cropped.height()) as f32 * 0.025).round() as u32).clamp(2, 18);

    let mut padded = RgbaImage::from_pixel(
        cropped.width() + padding * 2,
        cropped.height() + padding * 2,
        Rgba([0, 0, 0, 0]),
    );

    imageops::overlay(
        &mut padded,
        &cropped,
        i64::from(padding),
        i64::from(padding),
    );

    Ok(padded)
}

fn encode_sticker(mut sticker: DynamicImage) -> Result<StickerOutput> {
    let mut encoded = Vec::new();

    'encode: for edge in [300_u32, 280, 256, 224, 192] {
        if sticker.width() > edge || sticker.height() > edge {
            sticker = sticker.thumbnail(edge, edge);
        }

        for quality in [90.0_f32, 80.0, 70.0, 60.0] {
            encoded = media_codec::encode_webp(&sticker, quality)?;

            if encoded.len() <= MAX_STICKER_BYTES {
                break 'encode;
            }
        }
    }

    if encoded.len() > MAX_STICKER_BYTES {
        return Err(sticker_error(format!(
            "sticker is too large after compression: {} bytes",
            encoded.len()
        )));
    }

    let sha256 = Sha256::digest(&encoded).to_vec();

    let output = StickerOutput {
        content_hash: hex::encode(&sha256),
        sha256,
        width: sticker.width(),
        height: sticker.height(),
        webp: encoded,
    };

    validate_sticker(&output.as_proto())?;

    Ok(output)
}

fn visible_bounds(image: &RgbaImage) -> Option<(u32, u32, u32, u32)> {
    let (mut left, mut top) = (image.width(), image.height());

    let (mut right, mut bottom) = (0, 0);

    let mut found = false;

    for (x, y, pixel) in image.enumerate_pixels() {
        if pixel[3] <= TRANSPARENT_ALPHA {
            continue;
        }

        found = true;

        left = left.min(x);

        top = top.min(y);

        right = right.max(x);

        bottom = bottom.max(y);
    }

    found.then_some((left, top, right, bottom))
}

/// Turns an existing sticker clockwise without running background removal
/// again.
pub(crate) fn rotate(webp: &[u8]) -> Result<StickerOutput> {
    if webp.is_empty() || webp.len() > MAX_STICKER_BYTES {
        return Err(sticker_error("sticker WebP has an invalid size"));
    }

    let decoder = image::codecs::webp::WebPDecoder::new(Cursor::new(webp))
        .map_err(|error| sticker_error(format!("invalid sticker WebP: {error}")))?;

    let (width, height) = decoder.dimensions();

    let sticker = proto::StickerData {
        version: STICKER_VERSION,
        webp: webp.to_vec(),
        sha256: Sha256::digest(webp).to_vec(),
        width,
        height,
    };

    validate_sticker(&sticker)?;

    let rotated = DynamicImage::from_decoder(decoder)
        .map_err(|error| sticker_error(format!("invalid sticker WebP: {error}")))?
        .rotate90()
        .to_rgba8();

    // Prefer lossless encoding so repeated turns do not degrade the image.
    // Detailed stickers can exceed the wire limit, so retain the usual bounded
    // lossy fallback without changing their dimensions.
    let mut encoded = webp::Encoder::from_rgba(rotated.as_raw(), height, width)
        .encode_simple(true, 100.0)
        .map_err(|error| sticker_error(format!("webp encoding failed: {error:?}")))?
        .to_vec();

    if encoded.len() > MAX_STICKER_BYTES {
        let image = DynamicImage::ImageRgba8(rotated);

        for quality in [90.0_f32, 80.0, 70.0, 60.0] {
            encoded = media_codec::encode_webp(&image, quality)?;

            if encoded.len() <= MAX_STICKER_BYTES {
                break;
            }
        }
    }

    let sha256 = Sha256::digest(&encoded).to_vec();

    let output = StickerOutput {
        content_hash: hex::encode(&sha256),
        sha256,
        webp: encoded,
        width: height,
        height: width,
    };

    validate_sticker(&output.as_proto())?;

    Ok(output)
}

impl StickerOutput {
    pub(crate) fn as_proto(&self) -> proto::StickerData {
        proto::StickerData {
            version: STICKER_VERSION,
            webp: self.webp.clone(),
            sha256: self.sha256.clone(),
            width: self.width,
            height: self.height,
        }
    }
}

/// Returns the sticker carried by additional message data after checking all
/// wire bounds and its content digest.
pub(crate) fn decode_additional(bytes: &[u8]) -> Result<Option<proto::StickerData>> {
    let data = proto::AdditionalMessageData::decode(bytes)?;

    if data.r#type != additional_message_data::Type::Sticker as i32 {
        return Ok(None);
    }

    let sticker = data
        .sticker
        .ok_or_else(|| sticker_error("sticker message is missing its image"))?;

    validate_sticker(&sticker)?;

    Ok(Some(sticker))
}

pub(crate) fn validate_additional_if_sticker(bytes: &[u8]) -> Result<()> {
    let _ = decode_additional(bytes)?;

    Ok(())
}

fn validate_sticker(sticker: &proto::StickerData) -> Result<()> {
    if sticker.version != STICKER_VERSION {
        return Err(sticker_error(format!(
            "unsupported sticker version {}",
            sticker.version
        )));
    }

    if sticker.webp.is_empty() || sticker.webp.len() > MAX_STICKER_BYTES {
        return Err(sticker_error("sticker WebP has an invalid size"));
    }

    if sticker.sha256.len() != 32 || Sha256::digest(&sticker.webp).as_slice() != sticker.sha256 {
        return Err(sticker_error("sticker digest does not match its bytes"));
    }

    if sticker.width == 0
        || sticker.height == 0
        || sticker.width > MAX_STICKER_EDGE
        || sticker.height > MAX_STICKER_EDGE
    {
        return Err(sticker_error(
            "sticker dimensions are outside the allowed bounds",
        ));
    }

    if image::guess_format(&sticker.webp).ok() != Some(image::ImageFormat::WebP) {
        return Err(sticker_error("sticker payload is not WebP"));
    }

    let decoder = image::codecs::webp::WebPDecoder::new(Cursor::new(&sticker.webp))
        .map_err(|error| sticker_error(format!("invalid sticker WebP: {error}")))?;

    // Read the actual dimensions before allocating pixels. Declared protobuf
    // dimensions cannot be trusted to bound a peer's image decoder allocation.
    if decoder.dimensions() != (sticker.width, sticker.height) {
        return Err(sticker_error("sticker dimensions do not match its WebP"));
    }

    if decoder.has_animation() {
        return Err(sticker_error("animated stickers are not supported"));
    }

    let decoded = DynamicImage::from_decoder(decoder)
        .map_err(|error| sticker_error(format!("invalid sticker WebP: {error}")))?;

    if !decoded.color().has_alpha() || !decoded.to_rgba8().pixels().any(|pixel| pixel[3] > 0) {
        return Err(sticker_error("sticker has no visible transparent image"));
    }

    Ok(())
}

#[cfg(test)]
mod tests {

    use super::*;

    fn png(image: &RgbaImage) -> Vec<u8> {
        let mut bytes = Vec::new();

        DynamicImage::ImageRgba8(image.clone())
            .write_to(&mut Cursor::new(&mut bytes), image::ImageFormat::Png)
            .unwrap();

        bytes
    }

    #[test]

    fn edited_sticker_is_trimmed_to_what_remains_without_enlarging_it() {
        // One subject is left on the left after the right one was erased.
        let edited = RgbaImage::from_fn(300, 200, |x, y| {
            if (10..100).contains(&x) && (20..180).contains(&y) {
                Rgba([20, 120, 240, 255])
            } else {
                Rgba([0, 0, 0, 0])
            }
        });

        let output = from_edited(&png(&edited)).unwrap();

        assert!(output.width > 90 && output.width < 110);

        assert!(output.height > 160 && output.height < 180);

        validate_sticker(&output.as_proto()).unwrap();
    }

    #[test]

    fn edited_sticker_rejects_empty_foreign_and_oversized_input() {
        let erased = RgbaImage::from_pixel(120, 80, Rgba([0, 0, 0, 0]));

        assert!(from_edited(&png(&erased)).is_err());

        let visible = RgbaImage::from_pixel(120, 80, Rgba([200, 30, 30, 255]));

        let webp = media_codec::encode_webp(&DynamicImage::ImageRgba8(visible), 90.0).unwrap();

        assert!(from_edited(&webp).is_err());

        let oversized = RgbaImage::from_pixel(MAX_STICKER_EDGE + 1, 10, Rgba([200, 30, 30, 255]));

        assert!(from_edited(&png(&oversized)).is_err());

        assert!(from_edited(&[]).is_err());
    }

    #[test]

    fn extracted_foreground_is_trimmed_padded_and_bounded_for_the_wire() {
        let foreground = RgbaImage::from_fn(1200, 800, |x, y| {
            if (200..1000).contains(&x) && (200..600).contains(&y) {
                Rgba([240, 50, 80, 255])
            } else {
                Rgba([0, 0, 0, 0])
            }
        });

        let output = encode_foreground(foreground).unwrap();

        assert_eq!(output.width, MAX_STICKER_EDGE);

        assert!(output.height > 150 && output.height < 170);

        assert!(output.webp.len() <= MAX_STICKER_BYTES);

        validate_sticker(&output.as_proto()).unwrap();

        let decoded = image::load_from_memory(&output.webp).unwrap().to_rgba8();

        assert_eq!(decoded.get_pixel(0, 0)[3], 0);

        assert_eq!(
            decoded.get_pixel(output.width / 2, output.height / 2)[3],
            255
        );
    }

    #[test]

    fn extracted_foreground_must_contain_a_visible_subject() {
        assert!(encode_foreground(RgbaImage::new(32, 24)).is_err());

        assert!(encode_foreground(RgbaImage::from_pixel(32, 24, Rgba([1, 2, 3, 10]))).is_err());
    }

    fn sample_sticker() -> proto::StickerData {
        let image = DynamicImage::ImageRgba8(RgbaImage::from_fn(32, 24, |x, y| {
            if x > 4 && x < 28 && y > 4 && y < 20 {
                Rgba([240, 50, 80, 255])
            } else {
                Rgba([0, 0, 0, 0])
            }
        }));

        let webp = media_codec::encode_webp(&image, 90.0).unwrap();

        proto::StickerData {
            version: STICKER_VERSION,
            sha256: Sha256::digest(&webp).to_vec(),
            webp,
            width: 32,
            height: 24,
        }
    }

    #[test]

    fn sticker_wire_data_round_trips_and_rejects_tampering() {
        let sticker = sample_sticker();

        let data = proto::AdditionalMessageData {
            r#type: additional_message_data::Type::Sticker as i32,
            sticker: Some(sticker.clone()),
            ..Default::default()
        };

        assert_eq!(
            decode_additional(&data.encode_to_vec()).unwrap(),
            Some(sticker.clone())
        );

        let mut changed = sticker.clone();

        changed.webp[20] ^= 1;

        assert!(validate_sticker(&changed).is_err());

        let mut changed = sticker.clone();

        changed.width = 300;

        assert!(validate_sticker(&changed).is_err());

        let mut changed = sticker;

        changed.version = 2;

        assert!(validate_sticker(&changed).is_err());
    }

    #[test]

    fn normal_additional_data_is_not_a_sticker() {
        let data = proto::AdditionalMessageData::default();

        assert!(decode_additional(&data.encode_to_vec()).unwrap().is_none());
    }

    #[test]

    fn rotation_preserves_pixels_alpha_and_wire_validity() {
        let original = sample_sticker();

        let original_pixels = image::load_from_memory(&original.webp).unwrap().to_rgba8();

        let rotated = rotate(&original.webp).unwrap();

        assert_eq!((rotated.width, rotated.height), (24, 32));

        assert_eq!(
            rotated.content_hash,
            hex::encode(Sha256::digest(&rotated.webp))
        );

        validate_sticker(&rotated.as_proto()).unwrap();

        let rotated_pixels = image::load_from_memory(&rotated.webp).unwrap().to_rgba8();

        for (x, y, pixel) in original_pixels.enumerate_pixels() {
            let actual = rotated_pixels.get_pixel(original.height - 1 - y, x);

            assert_eq!(actual[3], pixel[3]);

            if pixel[3] != 0 {
                assert_eq!(actual, pixel);
            }
        }

        let mut webp = rotated.webp;

        for _ in 0..3 {
            webp = rotate(&webp).unwrap().webp;
        }

        let restored = image::load_from_memory(&webp).unwrap().to_rgba8();

        assert_eq!(restored.dimensions(), original_pixels.dimensions());

        for (actual, expected) in restored.pixels().zip(original_pixels.pixels()) {
            assert_eq!(actual[3], expected[3]);

            if expected[3] != 0 {
                assert_eq!(actual, expected);
            }
        }
    }

    #[test]

    fn rotation_rejects_invalid_or_out_of_bounds_stickers() {
        assert!(rotate(&[]).is_err());

        assert!(rotate(b"not a WebP").is_err());

        assert!(rotate(&vec![0; MAX_STICKER_BYTES + 1]).is_err());

        let oversized = DynamicImage::ImageRgba8(RgbaImage::from_pixel(
            MAX_STICKER_EDGE + 1,
            1,
            Rgba([255, 0, 0, 255]),
        ));

        let webp = media_codec::encode_webp(&oversized, 90.0).unwrap();

        assert!(rotate(&webp).is_err());
    }

    #[cfg(target_os = "android")]
    #[test]

    fn bundled_model_creates_a_bounded_transparent_webp() {
        let directory = tempfile::tempdir().unwrap();

        let image = directory.path().join("logo.png");

        std::fs::write(&image, include_bytes!("../../../assets/images/logo.png")).unwrap();

        let sticker = create(&image).expect("bundled model must load and run");

        assert!(sticker.width <= 300 && sticker.height <= 300);

        assert!(sticker.webp.len() <= MAX_STICKER_BYTES);

        assert_eq!(
            sticker.content_hash,
            hex::encode(Sha256::digest(&sticker.webp))
        );

        validate_sticker(&sticker.as_proto()).unwrap();

        let image = image::load_from_memory(&sticker.webp).unwrap().to_rgba8();

        assert!(image.pixels().any(|pixel| pixel[3] == 0));

        assert!(image.pixels().any(|pixel| pixel[3] > 10));
    }
}
