/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! On-device sticker creation and validation.
//!
//! The compact U²-Net model is compiled into the native library for now. The
//! digest check is intentionally kept beside model loading so a future model
//! downloader can feed these same trusted bytes without changing inference.

use crate::api::proto::client::{self as proto, additional_message_data};
use crate::error::{Result, TwonlyError};
use crate::services::media_codec;
use image::imageops::{self, FilterType};
use image::{DynamicImage, GrayImage, ImageDecoder, Luma, Rgba, RgbaImage};
use prost::Message as _;
use sha2::{Digest, Sha256};
use std::io::Cursor;
use std::path::Path;
use std::sync::OnceLock;
use tract::prelude::*;

const MODEL_BYTES: &[u8] = include_bytes!("../../models/u2netp.onnx");
const MODEL_SHA256: &str = "309c8469258dda742793dce0ebea8e6dd393174f89934733ecc8b14c76f4ddd8";
const MODEL_EDGE: u32 = 320;
const WORKING_EDGE: u32 = 900;
pub(crate) const MAX_STICKER_EDGE: u32 = 300;
pub(crate) const MAX_STICKER_BYTES: usize = 128 * 1024;
pub(crate) const STICKER_VERSION: u32 = 1;
const TRANSPARENT_ALPHA: u8 = 10;

static MODEL: OnceLock<std::result::Result<Runnable, String>> = OnceLock::new();

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

fn model() -> Result<&'static Runnable> {
    let loaded = MODEL.get_or_init(|| {
        let digest = hex::encode(Sha256::digest(MODEL_BYTES));
        if digest != MODEL_SHA256 {
            return Err(format!(
                "bundled sticker model digest mismatch: expected {MODEL_SHA256}, got {digest}"
            ));
        }
        tract::onnx()
            .and_then(|onnx| onnx.load_buffer(MODEL_BYTES))
            .and_then(|model| model.into_model())
            .and_then(|model| model.into_runnable())
            .map_err(|error| format!("could not load bundled sticker model: {error}"))
    });
    loaded
        .as_ref()
        .map_err(|error| sticker_error(error.clone()))
}

/// Removes the background from `source`, trims transparent borders and returns
/// a compact transparent WebP suitable for embedding in a text message.
pub(crate) fn create(source: &Path) -> Result<StickerOutput> {
    let source = media_codec::decode(source)?;
    if source.width() == 0 || source.height() == 0 {
        return Err(sticker_error("the sticker source image is empty"));
    }

    // There is no visual value in carrying a multi-megapixel source through
    // compositing when the wire result is capped at 300 px. Keeping a 3x
    // working image still gives the resized segmentation mask room to soften.
    let source = source.thumbnail(WORKING_EDGE, WORKING_EDGE).to_rgba8();
    let input_image = imageops::resize(
        &DynamicImage::ImageRgba8(source.clone()).to_rgb8(),
        MODEL_EDGE,
        MODEL_EDGE,
        FilterType::Triangle,
    );

    let pixel_count = (MODEL_EDGE * MODEL_EDGE) as usize;
    let mut input = vec![0.0_f32; pixel_count * 3];
    const MEAN: [f32; 3] = [0.485, 0.456, 0.406];
    const STD: [f32; 3] = [0.229, 0.224, 0.225];
    for (index, pixel) in input_image.pixels().enumerate() {
        for channel in 0..3 {
            input[channel * pixel_count + index] =
                (f32::from(pixel[channel]) / 255.0 - MEAN[channel]) / STD[channel];
        }
    }

    let tensor = Tensor::from_slice(&[1, 3, MODEL_EDGE as usize, MODEL_EDGE as usize], &input)
        .map_err(|error| sticker_error(format!("could not create sticker input: {error}")))?;
    let outputs = model()?
        .run([tensor])
        .map_err(|error| sticker_error(format!("sticker background removal failed: {error}")))?;
    let foreground = outputs
        .first()
        .ok_or_else(|| sticker_error("sticker model returned no mask"))?
        .as_slice::<f32>()
        .map_err(|error| sticker_error(format!("sticker mask has an invalid type: {error}")))?;
    if foreground.len() < pixel_count {
        return Err(sticker_error("sticker model returned a truncated mask"));
    }

    let foreground = &foreground[..pixel_count];
    let (mut min, mut max) = (f32::INFINITY, f32::NEG_INFINITY);
    for value in foreground.iter().copied().filter(|value| value.is_finite()) {
        min = min.min(value);
        max = max.max(value);
    }
    if !min.is_finite() || !max.is_finite() || max - min < f32::EPSILON {
        return Err(sticker_error("sticker model produced an empty mask"));
    }

    let mask = GrayImage::from_fn(MODEL_EDGE, MODEL_EDGE, |x, y| {
        let value = foreground[(y * MODEL_EDGE + x) as usize];
        let normalized = ((value - min) / (max - min)).clamp(0.0, 1.0);
        Luma([(normalized * 255.0).round() as u8])
    });
    let mask = imageops::resize(
        &mask,
        source.width(),
        source.height(),
        FilterType::CatmullRom,
    );

    let mut composited = source;
    for (pixel, alpha) in composited.pixels_mut().zip(mask.pixels()) {
        pixel[3] = ((u16::from(pixel[3]) * u16::from(alpha[0])) / 255) as u8;
    }

    let bounds = visible_bounds(&composited)
        .ok_or_else(|| sticker_error("no foreground was found in this image"))?;
    let cropped = imageops::crop_imm(
        &composited,
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

    let mut sticker =
        DynamicImage::ImageRgba8(padded).thumbnail(MAX_STICKER_EDGE, MAX_STICKER_EDGE);
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
    fn bundled_model_creates_a_bounded_transparent_webp() {
        let image = Path::new(env!("CARGO_MANIFEST_DIR")).join("../assets/images/logo.png");
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
