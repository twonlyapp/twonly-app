//! Android-only U²-Net inference. Host tests also exercise the exact runtime.

use super::{sticker_error, WORKING_EDGE};
use crate::error::Result;
use crate::services::media_codec;
use image::imageops::{self, FilterType};
use image::{DynamicImage, GrayImage, Luma, RgbaImage};
use sha2::{Digest, Sha256};
use std::io::Cursor;
use std::path::Path;
use std::sync::{Arc, OnceLock};
use tract_nnef::prelude::*;

const MODEL_BYTES: &[u8] = include_bytes!("../../../models/u2netp.nnef.tar");
const MODEL_SHA256: &str = "51f72210a9541ecbfb460bde4426cfdd321de603ef140180c3c54dd1da094106";
const MODEL_EDGE: u32 = 320;

static MODEL: OnceLock<std::result::Result<Arc<TypedRunnableModel>, String>> = OnceLock::new();

fn model() -> Result<&'static Arc<TypedRunnableModel>> {
    let loaded = MODEL.get_or_init(|| {
        let digest = hex::encode(Sha256::digest(MODEL_BYTES));
        if digest != MODEL_SHA256 {
            return Err(format!(
                "bundled sticker model digest mismatch: expected {MODEL_SHA256}, got {digest}"
            ));
        }
        tract_nnef::nnef()
            .model_for_read(&mut Cursor::new(MODEL_BYTES))
            .and_then(|model| model.into_optimized())
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

    let tensor = Tensor::from_shape(&[1, 3, MODEL_EDGE as usize, MODEL_EDGE as usize], &input)
        .map_err(|error| sticker_error(format!("could not create sticker input: {error}")))?;
    let outputs = model()?
        .run(tvec!(tensor.into()))
        .map_err(|error| sticker_error(format!("sticker background removal failed: {error}")))?;
    let foreground = outputs
        .first()
        .ok_or_else(|| sticker_error("sticker model returned no mask"))?;
    let foreground = foreground
        .try_as_plain_ram()
        .map_err(|error| sticker_error(format!("sticker mask is unavailable: {error}")))?
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

#[cfg(test)]
mod tests {
    use super::*;
    use tract_onnx::prelude::InferenceModelExt;

    #[test]
    fn foreground_inference_preserves_working_image_and_transparency() -> anyhow::Result<()> {
        let bytes = include_bytes!("../../../../assets/images/logo.png");
        let source = image::load_from_memory(bytes)?
            .thumbnail(WORKING_EDGE, WORKING_EDGE)
            .to_rgba8();
        let directory = tempfile::tempdir()?;
        let path = directory.path().join("source.png");
        std::fs::write(&path, bytes)?;
        let foreground = remove_background(&path)?;
        assert_eq!(foreground.dimensions(), source.dimensions());
        assert!(foreground.pixels().any(|pixel| pixel[3] > 10));
        for (actual, original) in foreground.pixels().zip(source.pixels()) {
            assert!(actual[3] <= original[3]);
            assert_eq!(&actual.0[..3], &original.0[..3]);
        }
        Ok(())
    }

    #[test]
    fn bundled_nnef_matches_original_onnx_outputs() -> anyhow::Result<()> {
        let source = include_bytes!("../../../models/u2netp.onnx");
        assert_eq!(
            hex::encode(Sha256::digest(source)),
            "309c8469258dda742793dce0ebea8e6dd393174f89934733ecc8b14c76f4ddd8",
        );
        // Match the former facade's ONNX -> typed -> declutter -> optimize
        // pipeline, independently of the checked-in converted NNEF artifact.
        let reference = tract_onnx::onnx()
            .model_for_read(&mut Cursor::new(source))?
            .into_typed()?
            .into_decluttered()?
            .into_optimized()?
            .into_runnable()?;
        for seed in [0, 1, 2] {
            let input: Vec<f32> = (0..3 * 320 * 320)
                .map(|n| {
                    if seed == 0 {
                        0.0
                    } else {
                        ((n * (seed * 17 + 1) % 251) as f32 / 125.0) - 1.0
                    }
                })
                .collect();
            let tensor = Tensor::from_shape(&[1, 3, 320, 320], &input)?;
            let expected = reference.run(tvec!(tensor.clone().into()))?;
            let actual = model()?.run(tvec!(tensor.into()))?;
            assert_eq!(actual.len(), expected.len());
            for (actual, expected) in actual.iter().zip(&expected) {
                assert_eq!(actual.shape(), expected.shape());
                let actual = actual.try_as_plain_ram()?.as_slice::<f32>()?;
                let expected = expected.try_as_plain_ram()?.as_slice::<f32>()?;
                for (&actual, &expected) in actual.iter().zip(expected) {
                    assert!(actual.is_finite() && expected.is_finite());
                    assert!((actual - expected).abs() < 1e-5);
                }
            }
        }
        Ok(())
    }
}
