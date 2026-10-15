//! Android-only U²-Net inference. Neither the model nor tract is built for iOS.

use super::{sticker_error, WORKING_EDGE};
use crate::error::Result;
use crate::services::media_codec;
use image::imageops::{self, FilterType};
use image::{DynamicImage, GrayImage, Luma, RgbaImage};
use sha2::{Digest, Sha256};
use std::path::Path;
use std::sync::OnceLock;
use tract::prelude::*;

const MODEL_BYTES: &[u8] = include_bytes!("../../../models/u2netp.onnx");
const MODEL_SHA256: &str = "309c8469258dda742793dce0ebea8e6dd393174f89934733ecc8b14c76f4ddd8";
const MODEL_EDGE: u32 = 320;

static MODEL: OnceLock<std::result::Result<Runnable, String>> = OnceLock::new();

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

pub(super) fn remove_background(source: &Path) -> Result<RgbaImage> {
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

    Ok(composited)
}
