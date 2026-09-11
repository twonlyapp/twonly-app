/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! Writes EXIF metadata into a WebP file.
//!
//! A WebP that carries metadata has to use the extended layout: a `VP8X` chunk
//! declares which optional chunks follow, and the metadata lives in its own
//! `EXIF` chunk. Neither the `image` crate nor libwebp will write that, so the
//! RIFF container is assembled here.
//!
//! Only the fields the gallery needs exist today. `ExifMetadata` is the place to
//! add more: give it a field, then a matching entry in `tiff_block`.

use crate::error::{Result, TwonlyError};
use chrono::{DateTime, Utc};

/// EXIF stores timestamps as local wall-clock text with no zone.
const DATE_FORMAT: &str = "%Y:%m:%d %H:%M:%S";

const TAG_DATE_TIME: u16 = 0x0132;
const TAG_EXIF_IFD: u16 = 0x8769;
const TAG_GPS_IFD: u16 = 0x8825;
const TAG_DATE_TIME_ORIGINAL: u16 = 0x9003;
const TAG_DATE_TIME_DIGITIZED: u16 = 0x9004;
const TAG_GPS_VERSION: u16 = 0x0000;
const TAG_GPS_LATITUDE_REF: u16 = 0x0001;
const TAG_GPS_LATITUDE: u16 = 0x0002;
const TAG_GPS_LONGITUDE_REF: u16 = 0x0003;
const TAG_GPS_LONGITUDE: u16 = 0x0004;
const TAG_GPS_HORIZONTAL_ERROR: u16 = 0x001f;
const TYPE_BYTE: u16 = 1;
const TYPE_ASCII: u16 = 2;
const TYPE_LONG: u16 = 4;
const TYPE_RATIONAL: u16 = 5;

/// The `VP8X` flag bit that says an `EXIF` chunk is present.
const FLAG_EXIF: u8 = 0b0000_1000;
/// The `VP8X` flag bit that says the image has transparency.
const FLAG_ALPHA: u8 = 0b0001_0000;

#[derive(Default)]
pub(crate) struct ExifMetadata {
    pub created_at: Option<DateTime<Utc>>,
    pub latitude: Option<f64>,
    pub longitude: Option<f64>,
    pub accuracy: Option<f64>,
}

impl ExifMetadata {
    fn is_empty(&self) -> bool {
        self.created_at.is_none() && (self.latitude.is_none() || self.longitude.is_none())
    }
}

/// Removes the complete EXIF block from the WebP upload copy without decoding
/// or recompressing its pixels.
pub(crate) fn remove_exif_from_file(path: &std::path::Path) -> Result<()> {
    let bytes = std::fs::read(path)?;
    let stripped = without_exif(&bytes)?;
    if stripped != bytes {
        std::fs::write(path, stripped)?;
    }
    Ok(())
}

fn without_exif(webp: &[u8]) -> Result<Vec<u8>> {
    let chunks = parse_chunks(webp)?;
    if !chunks.iter().any(|chunk| chunk.id == *b"EXIF") {
        return Ok(webp.to_vec());
    }
    let mut body = Vec::new();
    for chunk in chunks {
        if chunk.id == *b"EXIF" {
            continue;
        }
        if chunk.id == *b"VP8X" {
            let mut header = chunk.payload.to_vec();
            if let Some(flags) = header.first_mut() {
                *flags &= !FLAG_EXIF;
            }
            write_chunk(&mut body, &chunk.id, &header);
        } else {
            write_chunk(&mut body, &chunk.id, chunk.payload);
        }
    }
    let mut output = Vec::with_capacity(body.len() + 12);
    output.extend_from_slice(b"RIFF");
    output.extend_from_slice(&((body.len() + 4) as u32).to_le_bytes());
    output.extend_from_slice(b"WEBP");
    output.extend_from_slice(&body);
    Ok(output)
}

/// Returns the WebP bytes with an `EXIF` chunk attached, converting a simple
/// file to the extended layout when needed.
pub(crate) fn with_exif(webp: &[u8], metadata: &ExifMetadata) -> Result<Vec<u8>> {
    if metadata.is_empty() {
        return Ok(webp.to_vec());
    }
    let chunks = parse_chunks(webp)?;
    let (width, height) = dimensions(&chunks)?;
    let has_alpha = chunks.iter().any(has_alpha_channel);

    let mut body = Vec::new();
    let mut flags = FLAG_EXIF;
    if has_alpha {
        flags |= FLAG_ALPHA;
    }
    // VP8X carries the canvas size as width-1/height-1 in 24 bits each.
    let mut vp8x = Vec::with_capacity(10);
    vp8x.push(flags);
    vp8x.extend_from_slice(&[0, 0, 0]);
    vp8x.extend_from_slice(&(width - 1).to_le_bytes()[0..3]);
    vp8x.extend_from_slice(&(height - 1).to_le_bytes()[0..3]);
    write_chunk(&mut body, b"VP8X", &vp8x);

    for chunk in &chunks {
        // A stale header or metadata block from the source is replaced.
        if chunk.id == *b"VP8X" || chunk.id == *b"EXIF" {
            continue;
        }
        write_chunk(&mut body, &chunk.id, chunk.payload);
    }
    write_chunk(&mut body, b"EXIF", &tiff_block(metadata));

    let mut output = Vec::with_capacity(body.len() + 12);
    output.extend_from_slice(b"RIFF");
    output.extend_from_slice(&((body.len() + 4) as u32).to_le_bytes());
    output.extend_from_slice(b"WEBP");
    output.extend_from_slice(&body);
    Ok(output)
}

struct Chunk<'a> {
    id: [u8; 4],
    payload: &'a [u8],
}

fn parse_chunks(webp: &[u8]) -> Result<Vec<Chunk<'_>>> {
    if webp.len() < 12 || &webp[0..4] != b"RIFF" || &webp[8..12] != b"WEBP" {
        return Err(TwonlyError::Generic("not a WebP file".into()));
    }
    let mut chunks = Vec::new();
    let mut offset = 12;
    while offset + 8 <= webp.len() {
        let mut id = [0_u8; 4];
        id.copy_from_slice(&webp[offset..offset + 4]);
        let size = u32::from_le_bytes(webp[offset + 4..offset + 8].try_into().unwrap()) as usize;
        let start = offset + 8;
        let end = start
            .checked_add(size)
            .filter(|end| *end <= webp.len())
            .ok_or_else(|| {
                TwonlyError::Generic("WebP chunk runs past the end of the file".into())
            })?;
        chunks.push(Chunk {
            id,
            payload: &webp[start..end],
        });
        // Chunks are padded to an even length.
        offset = end + (size & 1);
    }
    Ok(chunks)
}

/// Lossy WebP keeps transparency in a separate `ALPH` chunk, while lossless
/// declares it with a flag inside its own header.
fn has_alpha_channel(chunk: &Chunk<'_>) -> bool {
    if chunk.id == *b"ALPH" {
        return true;
    }
    if chunk.id == *b"VP8L" && chunk.payload.len() >= 5 {
        let bits = u32::from_le_bytes(chunk.payload[1..5].try_into().unwrap());
        // width(14) height(14) alpha(1) version(3)
        return (bits >> 28) & 1 == 1;
    }
    false
}

/// Canvas size, read from whichever bitstream chunk this file uses.
fn dimensions(chunks: &[Chunk<'_>]) -> Result<(u32, u32)> {
    for chunk in chunks {
        match &chunk.id {
            b"VP8X" if chunk.payload.len() >= 10 => {
                let width =
                    u32::from_le_bytes([chunk.payload[4], chunk.payload[5], chunk.payload[6], 0])
                        + 1;
                let height =
                    u32::from_le_bytes([chunk.payload[7], chunk.payload[8], chunk.payload[9], 0])
                        + 1;
                return Ok((width, height));
            }
            // Lossy: the dimensions sit after the 3-byte start code and sync.
            b"VP8 " if chunk.payload.len() >= 10 => {
                let width = u16::from_le_bytes([chunk.payload[6], chunk.payload[7]]) & 0x3FFF;
                let height = u16::from_le_bytes([chunk.payload[8], chunk.payload[9]]) & 0x3FFF;
                return Ok((u32::from(width), u32::from(height)));
            }
            // Lossless: 14-bit width and height packed after the signature byte.
            b"VP8L" if chunk.payload.len() >= 5 => {
                let bits = u32::from_le_bytes(chunk.payload[1..5].try_into().unwrap());
                return Ok(((bits & 0x3FFF) + 1, ((bits >> 14) & 0x3FFF) + 1));
            }
            _ => {}
        }
    }
    Err(TwonlyError::Generic(
        "WebP file has no bitstream chunk".into(),
    ))
}

fn write_chunk(output: &mut Vec<u8>, id: &[u8; 4], payload: &[u8]) {
    output.extend_from_slice(id);
    output.extend_from_slice(&(payload.len() as u32).to_le_bytes());
    output.extend_from_slice(payload);
    if payload.len() % 2 == 1 {
        output.push(0);
    }
}

/// Builds a little-endian TIFF header with Exif and GPS sub-IFDs.
fn tiff_block(metadata: &ExifMetadata) -> Vec<u8> {
    let mut ifd0: Vec<(u16, u16, Vec<u8>)> = Vec::new();
    let mut exif: Vec<(u16, u16, Vec<u8>)> = Vec::new();
    let mut gps: Vec<(u16, u16, Vec<u8>)> = Vec::new();
    if let Some(created_at) = metadata.created_at {
        let text = format!("{}\0", created_at.format(DATE_FORMAT)).into_bytes();
        ifd0.push((TAG_DATE_TIME, TYPE_ASCII, text.clone()));
        exif.push((TAG_DATE_TIME_ORIGINAL, TYPE_ASCII, text.clone()));
        exif.push((TAG_DATE_TIME_DIGITIZED, TYPE_ASCII, text));
    }
    if let (Some(latitude), Some(longitude)) = (metadata.latitude, metadata.longitude) {
        gps.push((TAG_GPS_VERSION, TYPE_BYTE, vec![2, 3, 0, 0]));
        gps.push((
            TAG_GPS_LATITUDE_REF,
            TYPE_ASCII,
            vec![if latitude < 0.0 { b'S' } else { b'N' }, 0],
        ));
        gps.push((TAG_GPS_LATITUDE, TYPE_RATIONAL, coordinate(latitude)));
        gps.push((
            TAG_GPS_LONGITUDE_REF,
            TYPE_ASCII,
            vec![if longitude < 0.0 { b'W' } else { b'E' }, 0],
        ));
        gps.push((TAG_GPS_LONGITUDE, TYPE_RATIONAL, coordinate(longitude)));
        if let Some(accuracy) = metadata
            .accuracy
            .filter(|value| value.is_finite() && *value >= 0.0)
        {
            gps.push((TAG_GPS_HORIZONTAL_ERROR, TYPE_RATIONAL, rational(accuracy)));
        }
    }

    let mut output = Vec::new();
    output.extend_from_slice(b"II\x2a\x00");
    output.extend_from_slice(&8_u32.to_le_bytes());

    let pointer_count = usize::from(!exif.is_empty()) + usize::from(!gps.is_empty());
    let ifd0_size = ifd_size(&ifd0, pointer_count);
    let exif_ifd_offset = 8 + ifd0_size;
    let gps_ifd_offset = exif_ifd_offset + ifd_size(&exif, 0);
    if !exif.is_empty() {
        ifd0.push((
            TAG_EXIF_IFD,
            TYPE_LONG,
            (exif_ifd_offset as u32).to_le_bytes().to_vec(),
        ));
    }
    if !gps.is_empty() {
        ifd0.push((
            TAG_GPS_IFD,
            TYPE_LONG,
            (gps_ifd_offset as u32).to_le_bytes().to_vec(),
        ));
    }
    output.extend_from_slice(&serialize_ifd(&ifd0, 8));
    output.extend_from_slice(&serialize_ifd(&exif, exif_ifd_offset));
    output.extend_from_slice(&serialize_ifd(&gps, gps_ifd_offset));
    output
}

fn ifd_size(entries: &[(u16, u16, Vec<u8>)], extra_entries: usize) -> usize {
    if entries.is_empty() && extra_entries == 0 {
        return 0;
    }
    2 + (entries.len() + extra_entries) * 12
        + 4
        + entries
            .iter()
            .filter(|(_, _, data)| data.len() > 4)
            .map(|(_, _, data)| data.len() + (data.len() & 1))
            .sum::<usize>()
}

fn serialize_ifd(entries: &[(u16, u16, Vec<u8>)], start: usize) -> Vec<u8> {
    if entries.is_empty() {
        return Vec::new();
    }
    let mut values = Vec::new();
    let mut encoded = Vec::new();
    let mut value_offset = start + 2 + entries.len() * 12 + 4;
    encoded.extend_from_slice(&(entries.len() as u16).to_le_bytes());
    for (tag, kind, data) in entries {
        encoded.extend_from_slice(&entry(*tag, *kind, data, &mut values, &mut value_offset));
    }
    encoded.extend_from_slice(&0_u32.to_le_bytes());
    encoded.extend_from_slice(&values);
    encoded
}

fn coordinate(value: f64) -> Vec<u8> {
    let value = value.abs();
    let degrees = value.floor();
    let minutes_full = (value - degrees) * 60.0;
    let minutes = minutes_full.floor();
    let seconds = (minutes_full - minutes) * 60.0;
    let mut bytes = Vec::with_capacity(24);
    bytes.extend_from_slice(&rational(degrees));
    bytes.extend_from_slice(&rational(minutes));
    bytes.extend_from_slice(&rational(seconds));
    bytes
}

fn rational(value: f64) -> Vec<u8> {
    const DENOMINATOR: u32 = 1_000_000;
    let numerator = (value * f64::from(DENOMINATOR))
        .round()
        .clamp(0.0, f64::from(u32::MAX)) as u32;
    let mut bytes = Vec::with_capacity(8);
    bytes.extend_from_slice(&numerator.to_le_bytes());
    bytes.extend_from_slice(&DENOMINATOR.to_le_bytes());
    bytes
}

/// One 12-byte IFD entry. Values longer than four bytes live in the value block
/// and the entry stores their offset instead.
fn entry(
    tag: u16,
    kind: u16,
    data: &[u8],
    values: &mut Vec<u8>,
    value_offset: &mut usize,
) -> [u8; 12] {
    if data.len() <= 4 {
        let mut inline = [0_u8; 4];
        inline[..data.len()].copy_from_slice(data);
        return entry_inline(tag, kind, component_count(kind, data), inline);
    }
    let offset = *value_offset;
    values.extend_from_slice(data);
    if data.len() % 2 == 1 {
        values.push(0);
        *value_offset += 1;
    }
    *value_offset += data.len();
    entry_inline(
        tag,
        kind,
        component_count(kind, data),
        (offset as u32).to_le_bytes(),
    )
}

fn component_count(kind: u16, data: &[u8]) -> u32 {
    match kind {
        TYPE_LONG => (data.len() / 4) as u32,
        TYPE_RATIONAL => (data.len() / 8) as u32,
        _ => data.len() as u32,
    }
}

fn entry_inline(tag: u16, kind: u16, count: u32, value: [u8; 4]) -> [u8; 12] {
    let mut bytes = [0_u8; 12];
    bytes[0..2].copy_from_slice(&tag.to_le_bytes());
    bytes[2..4].copy_from_slice(&kind.to_le_bytes());
    bytes[4..8].copy_from_slice(&count.to_le_bytes());
    bytes[8..12].copy_from_slice(&value);
    bytes
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::TimeZone;

    fn sample_webp() -> Vec<u8> {
        let image = image::DynamicImage::ImageRgb8(image::RgbImage::from_pixel(
            8,
            6,
            image::Rgb([9, 9, 9]),
        ));
        let rgb = image.to_rgb8();
        webp::Encoder::from_rgb(rgb.as_raw(), 8, 6)
            .encode_simple(false, 80.0)
            .unwrap()
            .to_vec()
    }

    #[test]
    fn without_metadata_the_file_is_untouched() {
        let webp = sample_webp();
        let written = with_exif(&webp, &ExifMetadata::default()).unwrap();
        assert_eq!(written, webp);
    }

    #[test]
    fn adds_an_extended_header_and_an_exif_chunk_that_still_decodes() {
        let webp = sample_webp();
        let metadata = ExifMetadata {
            created_at: Some(Utc.with_ymd_and_hms(2026, 8, 30, 12, 34, 56).unwrap()),
            ..Default::default()
        };
        let written = with_exif(&webp, &metadata).unwrap();

        let chunks = parse_chunks(&written).unwrap();
        assert_eq!(chunks[0].id, *b"VP8X", "VP8X has to come first");
        assert_eq!(chunks[0].payload[0] & FLAG_EXIF, FLAG_EXIF);
        assert_eq!(dimensions(&chunks).unwrap(), (8, 6));

        let exif = chunks
            .iter()
            .find(|chunk| chunk.id == *b"EXIF")
            .expect("EXIF chunk");
        assert_eq!(&exif.payload[0..4], b"II\x2a\x00");
        let text = b"2026:08:30 12:34:56";
        assert!(
            exif.payload
                .windows(text.len())
                .any(|window| window == text),
            "the timestamp has to be stored verbatim"
        );

        // The result must still be a readable image.
        let decoded = image::load_from_memory(&written).unwrap();
        assert_eq!((decoded.width(), decoded.height()), (8, 6));
    }

    #[test]
    fn writing_twice_replaces_rather_than_appends() {
        let metadata = ExifMetadata {
            created_at: Some(Utc.with_ymd_and_hms(2026, 1, 2, 3, 4, 5).unwrap()),
            ..Default::default()
        };
        let once = with_exif(&sample_webp(), &metadata).unwrap();
        let twice = with_exif(&once, &metadata).unwrap();
        assert_eq!(once, twice);
        let chunks = parse_chunks(&twice).unwrap();
        assert_eq!(chunks.iter().filter(|c| c.id == *b"EXIF").count(), 1);
        assert_eq!(chunks.iter().filter(|c| c.id == *b"VP8X").count(), 1);
    }

    #[test]
    fn writes_gps_metadata_and_removes_it_from_the_send_copy() {
        let metadata = ExifMetadata {
            created_at: Some(Utc.with_ymd_and_hms(2026, 9, 10, 12, 0, 0).unwrap()),
            latitude: Some(52.520_008),
            longitude: Some(13.404_954),
            accuracy: Some(8.5),
        };
        let exported = with_exif(&sample_webp(), &metadata).unwrap();
        let chunks = parse_chunks(&exported).unwrap();
        let exif = chunks
            .iter()
            .find(|chunk| chunk.id == *b"EXIF")
            .expect("EXIF chunk");
        assert!(
            exif.payload.windows(2).any(|value| value == [0x25, 0x88]),
            "IFD0 must point at a GPS IFD"
        );
        assert!(
            exif.payload.windows(2).any(|value| value == [0x02, 0x00]),
            "GPS IFD must contain latitude"
        );

        let upload = without_exif(&exported).unwrap();
        let upload_chunks = parse_chunks(&upload).unwrap();
        assert!(!upload_chunks.iter().any(|chunk| chunk.id == *b"EXIF"));
        assert_eq!(upload_chunks[0].payload[0] & FLAG_EXIF, 0);
        image::load_from_memory(&upload).expect("stripped image remains decodable");
    }
}
