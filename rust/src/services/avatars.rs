use crate::context::Context;
use crate::error::{Result, TwonlyError};
use crate::user_config::UserConfig;
use flate2::read::GzDecoder;
use image::imageops;
use image::{DynamicImage, ImageDecoder, Rgba, RgbaImage};
use prost::Message as _;
use sha2::{Digest, Sha256};
use sqlx::{Row, Sqlite, Transaction};
use std::io::{Cursor, Read};
use std::path::{Path, PathBuf};
use std::sync::Mutex;

use crate::api::proto::client::encrypted_content;
use crate::services::{media_codec, stickers};

const DEFAULT_AVATAR_SVG: &str = r##"<!-- Taken from: https://getavataaars.com/ -->
<svg width="264px" height="280px" viewBox="0 0 264 280" version="1.1" xmlns="http://www.w3.org/2000/svg"
    xmlns:xlink="http://www.w3.org/1999/xlink">
    <defs>
        <path
            d="M124,144.610951 L124,163 L128,163 L128,163 C167.764502,163 200,195.235498 200,235 L200,244 L0,244 L0,235 C-4.86974701e-15,195.235498 32.235498,163 72,163 L72,163 L76,163 L76,144.610951 C58.7626345,136.422372 46.3722246,119.687011 44.3051388,99.8812385 C38.4803105,99.0577866 34,94.0521096 34,88 L34,74 C34,68.0540074 38.3245733,63.1180731 44,62.1659169 L44,56 L44,56 C44,25.072054 69.072054,5.68137151e-15 100,0 L100,0 L100,0 C130.927946,-5.68137151e-15 156,25.072054 156,56 L156,62.1659169 C161.675427,63.1180731 166,68.0540074 166,74 L166,88 C166,94.0521096 161.51969,99.0577866 155.694861,99.8812385 C153.627775,119.687011 141.237365,136.422372 124,144.610951 Z"
            id="react-path-3"></path>
    </defs>
    <g id="Avataaar" stroke="none" stroke-width="1" fill="none" fill-rule="evenodd">
        <g transform="translate(-825.000000, -1100.000000)">
            <g transform="translate(825.000000, 1100.000000)">
                <g id="Avataaar" stroke-width="1" fill-rule="evenodd">
                    <g id="Body" transform="translate(32.000000, 36.000000)">
                        <mask id="react-mask-6" fill="white">
                            <use xlink:href="#react-path-3"></use>
                        </mask>
                        <g id="Skin/👶🏽-03-Brown" mask="url(#react-mask-6)" fill="#57CC99">
                            <g transform="translate(0.000000, 0.000000)" id="Color">
                                <rect x="0" y="0" width="264" height="280"></rect>
                            </g>
                        </g>
                    </g>
                </g>
            </g>
        </g>
    </g>
</svg>"##;

static AVATAR_RENDER_LOCK: Mutex<()> = Mutex::new(());

pub(crate) const CUSTOM_AVATAR_PROTOCOL_VERSION: u32 = 1;

#[derive(Clone, Debug)]
pub struct CustomAvatarInfo {
    pub webp: Option<Vec<u8>>,
    pub sha256: Option<Vec<u8>>,
    pub width: Option<u32>,
    pub height: Option<u32>,
    pub accepted_contacts_only: bool,
    pub source_revision: i64,
}

pub(crate) fn create_custom_avatar(source: &Path) -> Result<stickers::StickerOutput> {
    let cutout = stickers::create(source)?;
    let decoded = image::load_from_memory_with_format(&cutout.webp, image::ImageFormat::WebP)
        .map_err(|error| TwonlyError::Generic(format!("invalid generated avatar: {error}")))?;
    let fitted = decoded.thumbnail(270, 270).to_rgba8();
    let mut canvas = RgbaImage::from_pixel(300, 300, Rgba([0, 0, 0, 0]));
    imageops::overlay(
        &mut canvas,
        &fitted,
        i64::from((300 - fitted.width()) / 2),
        i64::from((300 - fitted.height()) / 2),
    );

    // Bake the circular preview into the payload, including a one-pixel soft
    // edge. Consumers still clip defensively, but the file itself is circular.
    let center = 149.5_f32;
    for (x, y, pixel) in canvas.enumerate_pixels_mut() {
        let distance = ((x as f32 - center).powi(2) + (y as f32 - center).powi(2)).sqrt();
        let circle_alpha = (150.0 - distance).clamp(0.0, 1.0);
        pixel[3] = (f32::from(pixel[3]) * circle_alpha).round() as u8;
    }

    let image = DynamicImage::ImageRgba8(canvas);
    let mut webp = Vec::new();
    for quality in [90.0_f32, 82.0, 74.0, 66.0, 58.0] {
        webp = media_codec::encode_webp(&image, quality)?;
        if webp.len() <= stickers::MAX_STICKER_BYTES {
            break;
        }
    }
    if webp.len() > stickers::MAX_STICKER_BYTES {
        return Err(TwonlyError::Generic(
            "custom avatar is too large after compression".into(),
        ));
    }
    let sha256 = Sha256::digest(&webp).to_vec();
    Ok(stickers::StickerOutput {
        content_hash: hex::encode(&sha256),
        sha256,
        webp,
        width: 300,
        height: 300,
    })
}

pub(crate) async fn own_custom_avatar(ctx: &Context) -> Result<CustomAvatarInfo> {
    let database = ctx.app_db.read().await.clone();
    let row = sqlx::query(
        "SELECT webp, sha256, width, height, accepted_contacts_only, source_revision \
         FROM own_custom_avatar WHERE singleton = 1",
    )
    .fetch_one(&database.pool)
    .await?;
    Ok(CustomAvatarInfo {
        webp: row.try_get("webp")?,
        sha256: row.try_get("sha256")?,
        width: row
            .try_get::<Option<i64>, _>("width")?
            .map(|value| value as u32),
        height: row
            .try_get::<Option<i64>, _>("height")?
            .map(|value| value as u32),
        accepted_contacts_only: row.try_get::<i64, _>("accepted_contacts_only")? != 0,
        source_revision: row.try_get("source_revision")?,
    })
}

pub(crate) async fn store_own_custom_avatar(
    ctx: &Context,
    avatar: stickers::StickerOutput,
    accepted_contacts_only: bool,
) -> Result<CustomAvatarInfo> {
    let database = ctx.app_db.read().await.clone();
    sqlx::query(
        "UPDATE own_custom_avatar SET webp = ?, sha256 = ?, width = ?, height = ?, \
         accepted_contacts_only = ?, source_revision = source_revision + 1 WHERE singleton = 1",
    )
    .bind(avatar.webp)
    .bind(avatar.sha256)
    .bind(i64::from(avatar.width))
    .bind(i64::from(avatar.height))
    .bind(accepted_contacts_only)
    .execute(&database.pool)
    .await?;
    own_custom_avatar(ctx).await
}

pub(crate) async fn set_custom_avatar_audience(
    ctx: &Context,
    accepted_contacts_only: bool,
) -> Result<CustomAvatarInfo> {
    let database = ctx.app_db.read().await.clone();
    sqlx::query(
        "UPDATE own_custom_avatar SET accepted_contacts_only = ?, \
         source_revision = source_revision + CASE WHEN accepted_contacts_only != ? THEN 1 ELSE 0 END \
         WHERE singleton = 1",
    )
    .bind(accepted_contacts_only)
    .bind(accepted_contacts_only)
    .execute(&database.pool)
    .await?;
    own_custom_avatar(ctx).await
}

pub(crate) async fn remove_own_custom_avatar(ctx: &Context) -> Result<CustomAvatarInfo> {
    let database = ctx.app_db.read().await.clone();
    sqlx::query(
        "UPDATE own_custom_avatar SET webp = NULL, sha256 = NULL, width = NULL, height = NULL, \
         source_revision = source_revision + CASE WHEN webp IS NULL THEN 0 ELSE 1 END WHERE singleton = 1",
    )
    .execute(&database.pool)
    .await?;
    own_custom_avatar(ctx).await
}

/// Materializes the avatar state visible to one recipient and returns its
/// counter. Private photo changes never advance excluded recipients' counters.
pub(crate) async fn prepare_publication(
    t: &mut Transaction<'_, Sqlite>,
    contact_id: i64,
) -> Result<i64> {
    let own = sqlx::query(
        "SELECT webp IS NOT NULL AS has_photo, accepted_contacts_only, source_revision \
         FROM own_custom_avatar WHERE singleton = 1",
    )
    .fetch_one(&mut **t)
    .await?;
    let contact =
        sqlx::query("SELECT accepted, blocked, deleted_by_user FROM contacts WHERE user_id = ?")
            .bind(contact_id)
            .fetch_optional(&mut **t)
            .await?;
    let accepted = contact
        .as_ref()
        .is_some_and(|row| row.get::<i64, _>("accepted") != 0);
    let eligible = contact.as_ref().is_some_and(|row| {
        row.get::<i64, _>("blocked") == 0 && row.get::<i64, _>("deleted_by_user") == 0
    });
    let accepted_only = own.get::<i64, _>("accepted_contacts_only") != 0;
    let shows_photo =
        own.get::<i64, _>("has_photo") != 0 && eligible && (!accepted_only || accepted);
    let visible_revision = shows_photo.then(|| own.get::<i64, _>("source_revision"));

    let current = sqlx::query(
        "SELECT publication_counter, visible_source_revision, shows_photo \
         FROM custom_avatar_publications WHERE contact_id = ?",
    )
    .bind(contact_id)
    .fetch_optional(&mut **t)
    .await?;
    if let Some(row) = current {
        let old_photo = row.get::<i64, _>("shows_photo") != 0;
        let old_revision: Option<i64> = row.try_get("visible_source_revision")?;
        let counter: i64 = row.get("publication_counter");
        if old_photo == shows_photo && old_revision == visible_revision {
            return Ok(counter);
        }
        let counter = counter + 1;
        sqlx::query(
            "UPDATE custom_avatar_publications SET publication_counter = ?, \
             visible_source_revision = ?, shows_photo = ? WHERE contact_id = ?",
        )
        .bind(counter)
        .bind(visible_revision)
        .bind(shows_photo)
        .bind(contact_id)
        .execute(&mut **t)
        .await?;
        return Ok(counter);
    }

    let counter = i64::from(shows_photo);
    sqlx::query(
        "INSERT INTO custom_avatar_publications(contact_id, publication_counter, \
         visible_source_revision, shows_photo) VALUES (?, ?, ?, ?)",
    )
    .bind(contact_id)
    .bind(counter)
    .bind(visible_revision)
    .bind(shows_photo)
    .execute(&mut **t)
    .await?;
    Ok(counter)
}

pub(crate) async fn publication_payload(
    t: &mut Transaction<'_, Sqlite>,
    contact_id: i64,
) -> Result<encrypted_content::CustomAvatar> {
    let counter = prepare_publication(t, contact_id).await?;
    let publication =
        sqlx::query("SELECT shows_photo FROM custom_avatar_publications WHERE contact_id = ?")
            .bind(contact_id)
            .fetch_one(&mut **t)
            .await?;
    let shows_photo = publication.get::<i64, _>("shows_photo") != 0;
    if !shows_photo {
        return Ok(encrypted_content::CustomAvatar {
            version: CUSTOM_AVATAR_PROTOCOL_VERSION,
            publication_counter: counter,
            state: encrypted_content::custom_avatar::State::SvgOnly as i32,
            webp: None,
            sha256: None,
            width: None,
            height: None,
        });
    }
    let own = sqlx::query(
        "SELECT webp, sha256, width, height FROM own_custom_avatar WHERE singleton = 1",
    )
    .fetch_one(&mut **t)
    .await?;
    Ok(encrypted_content::CustomAvatar {
        version: CUSTOM_AVATAR_PROTOCOL_VERSION,
        publication_counter: counter,
        state: encrypted_content::custom_avatar::State::Photo as i32,
        webp: own.try_get("webp")?,
        sha256: own.try_get("sha256")?,
        width: own
            .try_get::<Option<i64>, _>("width")?
            .map(|value| value as u32),
        height: own
            .try_get::<Option<i64>, _>("height")?
            .map(|value| value as u32),
    })
}

pub(crate) async fn applied_counter(
    t: &mut Transaction<'_, Sqlite>,
    contact_id: i64,
) -> Result<i64> {
    Ok(sqlx::query_scalar::<_, i64>(
        "SELECT applied_counter FROM received_custom_avatars WHERE contact_id = ?",
    )
    .bind(contact_id)
    .fetch_optional(&mut **t)
    .await?
    .unwrap_or(0))
}

pub(crate) async fn apply_received(
    t: &mut Transaction<'_, Sqlite>,
    contact_id: i64,
    avatar: encrypted_content::CustomAvatar,
) -> Result<bool> {
    if avatar.version != CUSTOM_AVATAR_PROTOCOL_VERSION || avatar.publication_counter < 0 {
        return Err(TwonlyError::Generic(
            "invalid custom avatar version or counter".into(),
        ));
    }
    if avatar.publication_counter <= applied_counter(t, contact_id).await? {
        return Ok(false);
    }
    let state = encrypted_content::custom_avatar::State::try_from(avatar.state)?;
    let (webp, sha256, width, height) = match state {
        encrypted_content::custom_avatar::State::SvgOnly => (None, None, None, None),
        encrypted_content::custom_avatar::State::Photo => {
            let webp = avatar
                .webp
                .ok_or_else(|| TwonlyError::Generic("custom avatar has no image".into()))?;
            let sha256 = avatar
                .sha256
                .ok_or_else(|| TwonlyError::Generic("custom avatar has no digest".into()))?;
            let width = avatar.width.unwrap_or_default();
            let height = avatar.height.unwrap_or_default();
            validate_custom_webp(&webp, &sha256, width, height)?;
            (Some(webp), Some(sha256), Some(width), Some(height))
        }
    };
    sqlx::query(
        "INSERT INTO received_custom_avatars(contact_id, applied_counter, webp, sha256, width, height) \
         VALUES (?, ?, ?, ?, ?, ?) ON CONFLICT(contact_id) DO UPDATE SET \
         applied_counter = excluded.applied_counter, webp = excluded.webp, sha256 = excluded.sha256, \
         width = excluded.width, height = excluded.height",
    )
    .bind(contact_id)
    .bind(avatar.publication_counter)
    .bind(webp)
    .bind(sha256)
    .bind(width.map(i64::from))
    .bind(height.map(i64::from))
    .execute(&mut **t)
    .await?;
    // Notify existing contact streams without adding protocol fields to Drift.
    sqlx::query(
        "UPDATE contacts SET sender_profile_counter = sender_profile_counter WHERE user_id = ?",
    )
    .bind(contact_id)
    .execute(&mut **t)
    .await?;
    Ok(true)
}

/// Rebuilds an avatar response immediately before encryption. A photo queued
/// while a contact was authorized can therefore become an SVG-only withdrawal
/// if acceptance or audience changed before transmission.
pub(crate) async fn refresh_queued_response(
    ctx: &Context,
    contact_id: i64,
    bytes: Vec<u8>,
) -> Result<Vec<u8>> {
    let mut content = crate::api::proto::client::EncryptedContent::decode(bytes.as_slice())?;
    let is_avatar_response = content
        .contact_update
        .as_ref()
        .is_some_and(|update| update.custom_avatar.is_some());
    if !is_avatar_response {
        return Ok(bytes);
    }
    let database = ctx.app_db.read().await.clone();
    let mut transaction = database.pool.begin().await?;
    let avatar = publication_payload(&mut transaction, contact_id).await?;
    content.sender_custom_avatar_counter = Some(avatar.publication_counter);
    content.custom_avatar_protocol_version = Some(CUSTOM_AVATAR_PROTOCOL_VERSION);
    if let Some(update) = content.contact_update.as_mut() {
        update.custom_avatar = Some(avatar);
    }
    transaction.commit().await?;
    Ok(content.encode_to_vec())
}

fn validate_custom_webp(webp: &[u8], digest: &[u8], width: u32, height: u32) -> Result<()> {
    if webp.is_empty()
        || webp.len() > stickers::MAX_STICKER_BYTES
        || digest.len() != 32
        || Sha256::digest(webp).as_slice() != digest
        || width != 300
        || height != 300
        || image::guess_format(webp).ok() != Some(image::ImageFormat::WebP)
    {
        return Err(TwonlyError::Generic("invalid custom avatar payload".into()));
    }
    let decoder = image::codecs::webp::WebPDecoder::new(Cursor::new(webp))
        .map_err(|error| TwonlyError::Generic(format!("invalid custom avatar WebP: {error}")))?;
    if decoder.dimensions() != (width, height) || decoder.has_animation() {
        return Err(TwonlyError::Generic(
            "invalid or animated custom avatar WebP".into(),
        ));
    }
    let decoded = DynamicImage::from_decoder(decoder)
        .map_err(|error| TwonlyError::Generic(format!("invalid custom avatar WebP: {error}")))?;
    if !decoded.color().has_alpha() || !decoded.to_rgba8().pixels().any(|pixel| pixel[3] > 0) {
        return Err(TwonlyError::Generic(
            "invalid custom avatar dimensions".into(),
        ));
    }
    Ok(())
}

fn decode_svg_bytes(bytes: &[u8]) -> Result<Vec<u8>> {
    if bytes.starts_with(&[0x1f, 0x8b]) {
        let mut decoded = Vec::new();
        GzDecoder::new(bytes).read_to_end(&mut decoded)?;
        Ok(decoded)
    } else {
        Ok(bytes.to_vec())
    }
}

pub(crate) fn decode_avatar_svg(bytes: Vec<u8>) -> String {
    match decode_svg_bytes(&bytes).and_then(|decoded| Ok(String::from_utf8(decoded)?)) {
        Ok(svg) => svg,
        Err(error) => {
            tracing::error!(%error, "failed to decode avatar SVG");
            DEFAULT_AVATAR_SVG.to_owned()
        }
    }
}

pub(crate) fn contact_avatar_path(ctx: &Context, contact_id: i64, profile_counter: i64) -> PathBuf {
    Path::new(&ctx.config.data_dir)
        .join("notification_avatars")
        .join(format!("{contact_id}-{profile_counter}.png"))
}

pub(crate) fn current_user_avatar_path(ctx: &Context) -> Result<Option<PathBuf>> {
    let Some(user) = UserConfig::load_from(ctx)? else {
        return Ok(None);
    };
    let Some(svg) = user.avatar_svg else {
        return Ok(None);
    };

    let output = Path::new(&ctx.config.data_dir)
        .join("avatars")
        .join(format!("user_{}.png", user.avatar_counter));
    render_cached(&output, || render_at_size(svg.as_bytes(), 270, 300))?;
    Ok(Some(output))
}

/// Resolves a contact's avatar PNG, rendering it from the stored SVG when it is
/// not on disk yet. Avatars are only ever displayed as PNG, so a missing file
/// has to be produced here rather than fall back to rasterising SVG in the UI.
pub(crate) async fn ensure_contact_avatar_png(
    ctx: &Context,
    contact_id: i64,
) -> Result<Option<PathBuf>> {
    let database = ctx.app_db.read().await.clone();
    if let Some(custom) = sqlx::query(
        "SELECT applied_counter, webp FROM received_custom_avatars \
         WHERE contact_id = ? AND webp IS NOT NULL",
    )
    .bind(contact_id)
    .fetch_optional(&database.pool)
    .await?
    {
        let counter: i64 = custom.get("applied_counter");
        let webp: Vec<u8> = custom.get("webp");
        let output = Path::new(&ctx.config.data_dir)
            .join("avatars")
            .join(format!("contact_{contact_id}_custom_{counter}.webp"));
        write_cached_bytes(&output, &webp)?;
        return Ok(Some(output));
    }
    let row = sqlx::query!(
        r#"SELECT avatar_svg_compressed, sender_profile_counter FROM contacts WHERE user_id = ?"#,
        contact_id,
    )
    .fetch_optional(&database.pool)
    .await?;

    let Some(row) = row else {
        return Ok(None);
    };
    let Some(svg) = row.avatar_svg_compressed else {
        return Ok(None);
    };
    let profile_counter = row.sender_profile_counter;
    let output = contact_avatar_path(ctx, contact_id, profile_counter);
    if output.exists() {
        return Ok(Some(output));
    }

    // Rasterising is CPU bound, so it must not run on an async worker.
    let render_output = output.clone();
    tokio::task::spawn_blocking(move || {
        render_cached(&render_output, || render_with_max_dimension(&svg, 256.0))
    })
    .await
    .map_err(|error| TwonlyError::Generic(format!("avatar render task failed: {error}")))??;

    Ok(Some(output))
}

pub(crate) async fn current_custom_avatar_path(ctx: &Context) -> Result<Option<PathBuf>> {
    let avatar = own_custom_avatar(ctx).await?;
    let Some(webp) = avatar.webp else {
        return Ok(None);
    };
    let output = Path::new(&ctx.config.data_dir)
        .join("avatars")
        .join(format!("user_custom_{}.webp", avatar.source_revision));
    write_cached_bytes(&output, &webp)?;
    Ok(Some(output))
}

fn write_cached_bytes(output: &Path, bytes: &[u8]) -> Result<()> {
    let _guard = AVATAR_RENDER_LOCK
        .lock()
        .map_err(|_| TwonlyError::Generic("avatar render lock was poisoned".into()))?;
    if output.exists() {
        return Ok(());
    }
    let directory = output
        .parent()
        .ok_or_else(|| TwonlyError::Generic("avatar output has no parent directory".into()))?;
    std::fs::create_dir_all(directory)?;
    let temporary = output.with_extension("tmp");
    std::fs::write(&temporary, bytes)?;
    std::fs::rename(temporary, output)?;
    Ok(())
}

pub(crate) fn notification_avatar_path(
    ctx: &Context,
    sender_id: i64,
    profile_counter: i64,
    svg: Option<&[u8]>,
) -> Result<Option<PathBuf>> {
    let Some(svg) = svg else {
        return Ok(None);
    };
    let output = contact_avatar_path(ctx, sender_id, profile_counter);
    render_cached(&output, || render_with_max_dimension(svg, 256.0))?;
    Ok(Some(output))
}

fn render_cached<F>(output: &Path, render: F) -> Result<()>
where
    F: FnOnce() -> Result<Vec<u8>>,
{
    let _guard = AVATAR_RENDER_LOCK
        .lock()
        .map_err(|_| TwonlyError::Generic("avatar render lock was poisoned".into()))?;
    if output.exists() {
        return Ok(());
    }
    let directory = output
        .parent()
        .ok_or_else(|| TwonlyError::Generic("avatar output has no parent directory".into()))?;
    std::fs::create_dir_all(directory)?;
    let png = render()?;
    let file_name = output
        .file_name()
        .and_then(|name| name.to_str())
        .ok_or_else(|| TwonlyError::Generic("avatar output has an invalid file name".into()))?;
    let temporary = directory.join(format!(".{file_name}.tmp"));
    std::fs::write(&temporary, png)?;
    std::fs::rename(&temporary, output)?;
    Ok(())
}

fn svg_tree(svg: &[u8]) -> Result<resvg::usvg::Tree> {
    let decoded = decode_svg_bytes(svg)?;
    resvg::usvg::Tree::from_data(&decoded, &resvg::usvg::Options::default())
        .map_err(|error| TwonlyError::Generic(format!("invalid avatar SVG: {error}")))
}

fn render_at_size(svg: &[u8], width: u32, height: u32) -> Result<Vec<u8>> {
    let tree = svg_tree(svg)?;
    let mut pixmap = resvg::tiny_skia::Pixmap::new(width, height)
        .ok_or_else(|| TwonlyError::Generic("invalid avatar dimensions".into()))?;
    resvg::render(
        &tree,
        resvg::tiny_skia::Transform::identity(),
        &mut pixmap.as_mut(),
    );
    pixmap
        .encode_png()
        .map_err(|error| TwonlyError::Generic(format!("avatar PNG encoding failed: {error}")))
}

fn render_with_max_dimension(svg: &[u8], max_dimension: f32) -> Result<Vec<u8>> {
    let tree = svg_tree(svg)?;
    let original = tree.size();
    let scale = (max_dimension / original.width().max(original.height())).min(1.0);
    let width = (original.width() * scale).round().max(1.0) as u32;
    let height = (original.height() * scale).round().max(1.0) as u32;
    let mut pixmap = resvg::tiny_skia::Pixmap::new(width, height)
        .ok_or_else(|| TwonlyError::Generic("invalid avatar dimensions".into()))?;
    resvg::render(
        &tree,
        resvg::tiny_skia::Transform::from_scale(scale, scale),
        &mut pixmap.as_mut(),
    );
    pixmap
        .encode_png()
        .map_err(|error| TwonlyError::Generic(format!("avatar PNG encoding failed: {error}")))
}

#[cfg(test)]
mod tests {
    use super::*;
    use flate2::write::GzEncoder;
    use flate2::Compression;
    use std::io::Write;

    const SVG: &str = r#"<svg xmlns="http://www.w3.org/2000/svg" width="10" height="20"><rect width="10" height="20" fill="red"/></svg>"#;

    #[test]
    fn decodes_plain_and_gzipped_svg() {
        assert_eq!(decode_avatar_svg(SVG.as_bytes().to_vec()), SVG);

        let mut encoder = GzEncoder::new(Vec::new(), Compression::default());
        encoder.write_all(SVG.as_bytes()).unwrap();
        assert_eq!(decode_avatar_svg(encoder.finish().unwrap()), SVG);
    }

    #[test]
    fn invalid_svg_encoding_uses_default() {
        assert_eq!(decode_avatar_svg(vec![0xff]), DEFAULT_AVATAR_SVG);
    }

    #[tokio::test]
    async fn renders_a_missing_contact_avatar_png_on_demand() {
        let temporary_directory = tempfile::tempdir().unwrap();
        let context = Context::init_for_testing(
            temporary_directory.path().join("database"),
            temporary_directory.path().join("data"),
        )
        .await
        .unwrap();

        let database = context.app_db.read().await.clone();
        sqlx::query!(
            "INSERT INTO contacts(user_id, username, avatar_svg_compressed) VALUES (?, ?, ?)",
            7_i64,
            "peer",
            SVG.as_bytes(),
        )
        .execute(&database.pool)
        .await
        .unwrap();

        let expected = contact_avatar_path(&context, 7, 0);
        assert!(!expected.exists(), "no PNG should exist up front");

        let path = ensure_contact_avatar_png(&context, 7).await.unwrap();
        assert_eq!(path.as_deref(), Some(expected.as_path()));
        assert!(expected.exists(), "the PNG has to be rendered on demand");
        image::load_from_memory(&std::fs::read(&expected).unwrap()).unwrap();
    }

    #[tokio::test]
    async fn contacts_without_an_avatar_render_nothing() {
        let temporary_directory = tempfile::tempdir().unwrap();
        let context = Context::init_for_testing(
            temporary_directory.path().join("database"),
            temporary_directory.path().join("data"),
        )
        .await
        .unwrap();

        let database = context.app_db.read().await.clone();
        sqlx::query!(
            "INSERT INTO contacts(user_id, username) VALUES (?, ?)",
            8_i64,
            "peer",
        )
        .execute(&database.pool)
        .await
        .unwrap();

        assert!(ensure_contact_avatar_png(&context, 8)
            .await
            .unwrap()
            .is_none());
        assert!(ensure_contact_avatar_png(&context, 999)
            .await
            .unwrap()
            .is_none());
    }

    #[test]
    fn renders_current_user_avatar_dimensions() {
        let png = render_at_size(SVG.as_bytes(), 270, 300).unwrap();
        let image = image::load_from_memory(&png).unwrap();
        assert_eq!((image.width(), image.height()), (270, 300));
    }

    #[tokio::test]
    async fn publication_counter_only_changes_when_the_recipient_view_changes() {
        let temporary_directory = tempfile::tempdir().unwrap();
        let context = Context::init_for_testing(
            temporary_directory.path().join("database"),
            temporary_directory.path().join("data"),
        )
        .await
        .unwrap();
        let database = context.app_db.read().await.clone();
        sqlx::query("INSERT INTO contacts(user_id, username) VALUES (7, 'peer')")
            .execute(&database.pool)
            .await
            .unwrap();
        sqlx::query(
            "UPDATE own_custom_avatar SET webp = x'01', sha256 = zeroblob(32), width = 300, \
             height = 300, source_revision = 1, accepted_contacts_only = 1 WHERE singleton = 1",
        )
        .execute(&database.pool)
        .await
        .unwrap();

        let mut transaction = database.pool.begin().await.unwrap();
        assert_eq!(prepare_publication(&mut transaction, 7).await.unwrap(), 0);
        transaction.commit().await.unwrap();

        // A new private photo is invisible to an unaccepted peer.
        sqlx::query("UPDATE own_custom_avatar SET source_revision = 2 WHERE singleton = 1")
            .execute(&database.pool)
            .await
            .unwrap();
        let mut transaction = database.pool.begin().await.unwrap();
        assert_eq!(prepare_publication(&mut transaction, 7).await.unwrap(), 0);
        transaction.commit().await.unwrap();

        sqlx::query("UPDATE contacts SET accepted = 1 WHERE user_id = 7")
            .execute(&database.pool)
            .await
            .unwrap();
        let mut transaction = database.pool.begin().await.unwrap();
        assert_eq!(prepare_publication(&mut transaction, 7).await.unwrap(), 1);
        transaction.commit().await.unwrap();

        // Revoking acceptance creates a versioned SVG-only withdrawal.
        sqlx::query("UPDATE contacts SET accepted = 0 WHERE user_id = 7")
            .execute(&database.pool)
            .await
            .unwrap();
        let mut transaction = database.pool.begin().await.unwrap();
        assert_eq!(prepare_publication(&mut transaction, 7).await.unwrap(), 2);
        let payload = publication_payload(&mut transaction, 7).await.unwrap();
        assert_eq!(
            encrypted_content::custom_avatar::State::try_from(payload.state).unwrap(),
            encrypted_content::custom_avatar::State::SvgOnly
        );
        transaction.commit().await.unwrap();
    }

    #[tokio::test]
    async fn received_avatar_is_validated_and_ordered_by_publication_counter() {
        let temporary_directory = tempfile::tempdir().unwrap();
        let context = Context::init_for_testing(
            temporary_directory.path().join("database"),
            temporary_directory.path().join("data"),
        )
        .await
        .unwrap();
        let database = context.app_db.read().await.clone();
        sqlx::query("INSERT INTO contacts(user_id, username) VALUES (9, 'peer')")
            .execute(&database.pool)
            .await
            .unwrap();
        let image = DynamicImage::ImageRgba8(RgbaImage::from_fn(300, 300, |x, y| {
            if x < 4 || y < 4 {
                Rgba([0, 0, 0, 0])
            } else {
                Rgba([10, 20, 30, 255])
            }
        }));
        let webp = media_codec::encode_webp(&image, 80.0).unwrap();
        let digest = Sha256::digest(&webp).to_vec();
        let photo = encrypted_content::CustomAvatar {
            version: CUSTOM_AVATAR_PROTOCOL_VERSION,
            publication_counter: 2,
            state: encrypted_content::custom_avatar::State::Photo as i32,
            webp: Some(webp),
            sha256: Some(digest),
            width: Some(300),
            height: Some(300),
        };
        let mut transaction = database.pool.begin().await.unwrap();
        assert!(apply_received(&mut transaction, 9, photo).await.unwrap());
        transaction.commit().await.unwrap();

        let stale = encrypted_content::CustomAvatar {
            version: CUSTOM_AVATAR_PROTOCOL_VERSION,
            publication_counter: 1,
            state: encrypted_content::custom_avatar::State::SvgOnly as i32,
            webp: None,
            sha256: None,
            width: None,
            height: None,
        };
        let mut transaction = database.pool.begin().await.unwrap();
        assert!(!apply_received(&mut transaction, 9, stale).await.unwrap());
        assert_eq!(applied_counter(&mut transaction, 9).await.unwrap(), 2);
        transaction.commit().await.unwrap();
    }
}
