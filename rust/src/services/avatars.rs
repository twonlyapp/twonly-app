use crate::context::Context;
use crate::error::{Result, TwonlyError};
use crate::user_config::UserConfig;
use flate2::read::GzDecoder;
use image::{imageops, DynamicImage, ImageDecoder, Rgba, RgbaImage};
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

    fit_custom_avatar(decoded)
}

pub(crate) fn create_custom_avatar_from_sticker(webp: &[u8]) -> Result<stickers::StickerOutput> {
    if webp.is_empty() || webp.len() > stickers::MAX_STICKER_BYTES {
        return Err(TwonlyError::Generic("invalid avatar sticker size".into()));
    }

    let decoder = image::codecs::webp::WebPDecoder::new(Cursor::new(webp))
        .map_err(|error| TwonlyError::Generic(format!("invalid avatar sticker: {error}")))?;
    let (width, height) = decoder.dimensions();
    if width == 0 || height == 0 || width > 300 || height > 300 {
        return Err(TwonlyError::Generic(
            "invalid avatar sticker dimensions".into(),
        ));
    }
    let decoded = DynamicImage::from_decoder(decoder)
        .map_err(|error| TwonlyError::Generic(format!("invalid avatar sticker: {error}")))?;

    fit_custom_avatar(decoded)
}

fn fit_custom_avatar(decoded: DynamicImage) -> Result<stickers::StickerOutput> {
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
        "SELECT webp, sha256, width, height, accepted_contacts_only, source_revision FROM \
         own_custom_avatar WHERE singleton = 1",
    )
    .fetch_one(&database.read_pool)
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
    ctx: &Context, avatar: stickers::StickerOutput, accepted_contacts_only: bool,
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
    ctx: &Context, accepted_contacts_only: bool,
) -> Result<CustomAvatarInfo> {
    let database = ctx.app_db.read().await.clone();

    sqlx::query(
        "UPDATE own_custom_avatar SET accepted_contacts_only = ?, source_revision = \
         source_revision + CASE WHEN accepted_contacts_only != ? THEN 1 ELSE 0 END WHERE \
         singleton = 1",
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
         source_revision = source_revision + CASE WHEN webp IS NULL THEN 0 ELSE 1 END WHERE \
         singleton = 1",
    )
    .execute(&database.pool)
    .await?;

    own_custom_avatar(ctx).await
}

/// Materializes the avatar state visible to one recipient and returns its
/// counter. Private photo changes never advance excluded recipients' counters.
pub(crate) async fn prepare_publication(
    t: &mut Transaction<'_, Sqlite>, contact_id: i64,
) -> Result<i64> {
    let own = sqlx::query(
        "SELECT webp IS NOT NULL AS has_photo, accepted_contacts_only, source_revision FROM \
         own_custom_avatar WHERE singleton = 1",
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
        "SELECT publication_counter, visible_source_revision, shows_photo FROM \
         custom_avatar_publications WHERE contact_id = ?",
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
    t: &mut Transaction<'_, Sqlite>, contact_id: i64,
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
    t: &mut Transaction<'_, Sqlite>, contact_id: i64,
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
    t: &mut Transaction<'_, Sqlite>, contact_id: i64, avatar: encrypted_content::CustomAvatar,
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
        "INSERT INTO received_custom_avatars(contact_id, applied_counter, webp, sha256, width, \
         height) VALUES (?, ?, ?, ?, ?, ?) ON CONFLICT(contact_id) DO UPDATE SET applied_counter \
         = excluded.applied_counter, webp = excluded.webp, sha256 = excluded.sha256, width = \
         excluded.width, height = excluded.height",
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
    ctx: &Context, contact_id: i64, bytes: Vec<u8>,
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
    ctx: &Context, contact_id: i64,
) -> Result<Option<PathBuf>> {
    crate::performance::measure("avatar.resolve", "media.avatar", async {
        let database = ctx.app_db.read().await.clone();

        let row: Option<(Option<Vec<u8>>, i64, Option<i64>)> = sqlx::query_as(
        "SELECT avatar_svg_compressed, sender_profile_counter, prefer_photo_avatar FROM contacts \
         WHERE user_id = ?",
    )
    .bind(contact_id)
    .fetch_optional(&database.read_pool)
    .await?;

        let Some((svg, profile_counter, prefer_photo)) = row else {
            return Ok(None);
        };

        let svg = svg.filter(|bytes| !bytes.is_empty());

        // Preferences are local, just like nicknames. If the preferred kind is no
        // longer shared by this contact, continue to use whichever is available.
        if prefer_photo.unwrap_or(1) != 0 || svg.is_none() {
            let custom_path = |counter: i64| {
                Path::new(&ctx.config.data_dir)
                    .join("avatars")
                    .join(format!("contact_{contact_id}_custom_{counter}.webp"))
            };

            // Every visible avatar resolves itself again whenever its row changes.
            // The file name carries the counter, so an existing file already holds
            // this photo and the bytes need not be read out of the database.
            if let Some(counter) = sqlx::query_scalar::<_, i64>(
            "SELECT applied_counter FROM received_custom_avatars WHERE contact_id = ? AND webp IS \
             NOT NULL",
        )
        .bind(contact_id)
        .fetch_optional(&database.read_pool)
        .await?
        {
            let output = custom_path(counter);

            if output.exists() {
                return Ok(Some(output));
            }
        }

            // Counter and bytes are read together: the photo may have been
            // replaced since the lookup above.
            if let Some(custom) = sqlx::query(
            "SELECT applied_counter, webp FROM received_custom_avatars WHERE contact_id = ? AND \
             webp IS NOT NULL",
        )
        .bind(contact_id)
        .fetch_optional(&database.read_pool)
        .await?
        {
            let counter: i64 = custom.get("applied_counter");

            let webp: Vec<u8> = custom.get("webp");

            return cache_avatar_bytes(custom_path(counter), webp)
                .await
                .map(Some);
        }
        }

        let Some(svg) = svg else {
            return Ok(None);
        };

        let output = contact_avatar_path(ctx, contact_id, profile_counter);

        if output.exists() {
            return Ok(Some(output));
        }

        // Rasterising is CPU bound, so it must not run on an async worker.
        let render_output = output.clone();

        crate::database::lifecycle::spawn_blocking(move || {
            render_cached(&render_output, || render_with_max_dimension(&svg, 256.0))
        })
        .await
        .map_err(|error| TwonlyError::Generic(format!("avatar render task failed: {error}")))??;

        Ok(Some(output))
    })
    .await
}

/// Matches the group avatar in Flutter: up to three active members, ordered
/// by their latest message, with overlapping avatars and rounded corners.
/// Members without an avatar are left out, and a group in which no member has
/// one gets no avatar at all.
pub(crate) async fn ensure_group_avatar_png(
    ctx: &Context, group_id: &str,
) -> Result<Option<PathBuf>> {
    crate::performance::measure("avatar.group.resolve", "media.avatar", async {
        let database = ctx.app_db.read().await.clone();

        let members: Vec<i64> = sqlx::query_scalar(
        "SELECT c.user_id FROM contacts c JOIN group_members m ON m.contact_id = c.user_id WHERE \
         m.group_id = ? AND (m.member_state IS NULL OR m.member_state != 'leftGroup') ORDER BY \
         m.last_message DESC, c.user_id ASC",
    )
    .bind(group_id)
    .fetch_all(&database.pool)
    .await?;

        let mut paths = Vec::with_capacity(3);

        for member in members {
            match ensure_contact_avatar_png(ctx, member).await {
                Ok(Some(path)) => paths.push(path),
                Ok(None) => {}
                Err(error) => {
                    tracing::warn!(%error, member, "failed to prepare group member avatar");
                }
            }

            if paths.len() == 3 {
                break;
            }
        }

        if paths.is_empty() {
            return Ok(None);
        }

        let directory = Path::new(&ctx.config.data_dir).join("notification_avatars");

        let output =
            crate::database::lifecycle::spawn_blocking(move || -> Result<Option<PathBuf>> {
                let images: Vec<RgbaImage> = paths
                    .iter()
                    .filter_map(|path| image::open(path).ok().map(|image| image.to_rgba8()))
                    .collect();

                if images.is_empty() {
                    return Ok(None);
                }

                let png = compose_group_avatar(&images);

                let mut bytes = Cursor::new(Vec::new());

                DynamicImage::ImageRgba8(png)
                    .write_to(&mut bytes, image::ImageFormat::Png)
                    .map_err(|error| {
                        TwonlyError::Generic(format!("group avatar encoding failed: {error}"))
                    })?;

                let bytes = bytes.into_inner();

                let output =
                    directory.join(format!("group-{}.png", hex::encode(Sha256::digest(&bytes))));

                write_cached_bytes(&output, &bytes)?;

                Ok(Some(output))
            })
            .await
            .map_err(|error| {
                TwonlyError::Generic(format!("group avatar render task failed: {error}"))
            })??;

        Ok(output)
    })
    .await
}

fn compose_group_avatar(images: &[RgbaImage]) -> RgbaImage {
    let mut canvas = RgbaImage::new(256, 256);

    let mut place = |index: usize, size: u32, x: i64, y: i64| {
        let avatar = imageops::resize(&images[index], size, size, imageops::FilterType::Lanczos3);

        imageops::overlay(&mut canvas, &avatar, x, y);
    };

    match images.len() {
        1 => place(0, 256, 0, 0),
        2 => {
            place(1, 205, -38, 57);

            place(0, 256, 64, 0);
        }
        _ => {
            place(2, 205, -70, 57);

            place(1, 205, 122, 57);

            place(0, 256, 0, 0);
        }
    }

    // Flutter clips the 40px avatar with a 12px corner radius.
    let radius = 77.0_f32;

    for (x, y, pixel) in canvas.enumerate_pixels_mut() {
        let dx = (radius - (x as f32 + 0.5).min(255.5 - x as f32)).max(0.0);

        let dy = (radius - (y as f32 + 0.5).min(255.5 - y as f32)).max(0.0);

        if dx * dx + dy * dy > radius * radius {
            pixel[3] = 0;
        }
    }

    canvas
}

pub(crate) async fn current_custom_avatar_path(ctx: &Context) -> Result<Option<PathBuf>> {
    let avatar = own_custom_avatar(ctx).await?;

    let Some(webp) = avatar.webp else {
        return Ok(None);
    };

    let output = Path::new(&ctx.config.data_dir)
        .join("avatars")
        .join(format!("user_custom_{}.webp", avatar.source_revision));

    cache_avatar_bytes(output, webp).await.map(Some)
}

async fn cache_avatar_bytes(output: PathBuf, bytes: Vec<u8>) -> Result<PathBuf> {
    crate::database::lifecycle::spawn_blocking(move || {
        write_cached_bytes(&output, &bytes)?;
        Ok(output)
    })
    .await
    .map_err(|error| TwonlyError::Generic(format!("avatar cache task failed: {error}")))?
}

fn write_cached_bytes(output: &Path, bytes: &[u8]) -> Result<()> {
    // A cached photo must not wait behind another contact's SVG rasterizer.
    if output.exists() {
        return Ok(());
    }

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
    ctx: &Context, sender_id: i64, profile_counter: i64, svg: Option<&[u8]>,
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
    fn saved_sticker_becomes_avatar_without_foreground_extraction() {
        let source = DynamicImage::ImageRgba8(RgbaImage::from_fn(300, 150, |x, _| {
            if x < 100 {
                Rgba([0, 0, 0, 0])
            } else {
                Rgba([200, 50, 20, 255])
            }
        }));
        let webp = media_codec::encode_webp(&source, 90.0).unwrap();
        let avatar = create_custom_avatar_from_sticker(&webp).unwrap();
        assert_eq!((avatar.width, avatar.height), (300, 300));
        assert!(avatar.webp.len() <= stickers::MAX_STICKER_BYTES);
        assert_eq!(avatar.sha256, Sha256::digest(&avatar.webp).to_vec());

        let decoded = image::load_from_memory(&avatar.webp).unwrap().to_rgba8();
        assert_eq!(decoded.get_pixel(30, 150)[3], 0);
        assert_eq!(decoded.get_pixel(200, 150)[3], 255);
        assert_eq!(decoded.get_pixel(200, 230)[3], 0);
        assert_eq!(decoded.get_pixel(0, 0)[3], 0);
    }

    #[test]
    fn avatar_sticker_rejects_invalid_size_format_and_dimensions() {
        assert!(create_custom_avatar_from_sticker(&[]).is_err());
        assert!(
            create_custom_avatar_from_sticker(&vec![0; stickers::MAX_STICKER_BYTES + 1]).is_err()
        );
        assert!(create_custom_avatar_from_sticker(b"invalid WebP").is_err());
        let oversized =
            DynamicImage::ImageRgba8(RgbaImage::from_pixel(301, 1, Rgba([1, 2, 3, 255])));
        let webp = media_codec::encode_webp(&oversized, 90.0).unwrap();
        assert!(create_custom_avatar_from_sticker(&webp).is_err());
    }

    #[test]

    fn decodes_plain_and_gzipped_svg() {
        assert_eq!(decode_avatar_svg(SVG.as_bytes().to_vec()), SVG);

        let mut encoder = GzEncoder::new(Vec::new(), Compression::default());

        encoder.write_all(SVG.as_bytes()).unwrap();

        assert_eq!(decode_avatar_svg(encoder.finish().unwrap()), SVG);
    }

    #[test]

    fn cached_photo_does_not_wait_for_an_unrelated_svg_render() {
        let directory = tempfile::tempdir().unwrap();
        let output = directory.path().join("cached.webp");
        std::fs::write(&output, b"cached").unwrap();
        let rendering = AVATAR_RENDER_LOCK.lock().unwrap();
        let (sent, received) = std::sync::mpsc::channel();
        let worker = std::thread::spawn(move || {
            let result = write_cached_bytes(&output, b"cached");
            let _ = sent.send(result);
        });
        let cached = received.recv_timeout(std::time::Duration::from_millis(500));
        // Release before asserting so a failure never strands the worker.
        drop(rendering);
        worker.join().unwrap();
        cached
            .expect("a cached photo waited for the SVG render lock")
            .unwrap();
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

    async fn contact_avatar_preference_and_missing_kind_fallbacks() -> anyhow::Result<()> {
        let temp = tempfile::tempdir()?;

        let ctx = Context::init_for_testing(temp.path().join("database"), temp.path().join("data"))
            .await?;

        let db = ctx.app_db.read().await.clone();

        sqlx::query(
            "INSERT INTO contacts(user_id, username, avatar_svg_compressed) VALUES (7, 'peer', ?)",
        )
        .bind(SVG.as_bytes())
        .execute(&db.pool)
        .await?;

        let image = DynamicImage::ImageRgba8(RgbaImage::from_pixel(8, 8, Rgba([1, 2, 3, 255])));

        let webp = media_codec::encode_webp(&image, 90.0)?;

        sqlx::query(
            "INSERT INTO received_custom_avatars(contact_id, webp, sha256, width, height) VALUES \
             (7, ?, ?, 8, 8)",
        )
        .bind(&webp)
        .bind(vec![0_u8; 32])
        .execute(&db.pool)
        .await?;

        let photo = ensure_contact_avatar_png(&ctx, 7).await?.unwrap();

        assert_eq!(photo.extension().unwrap(), "webp");

        assert_eq!(std::fs::read(&photo)?, webp);

        sqlx::query("UPDATE contacts SET prefer_photo_avatar = 0 WHERE user_id = 7")
            .execute(&db.pool)
            .await?;

        let illustrated = ensure_contact_avatar_png(&ctx, 7).await?.unwrap();

        assert_eq!(illustrated, contact_avatar_path(&ctx, 7, 0));

        sqlx::query("UPDATE contacts SET avatar_svg_compressed = NULL WHERE user_id = 7")
            .execute(&db.pool)
            .await?;

        assert_eq!(
            ensure_contact_avatar_png(&ctx, 7).await?,
            Some(photo.clone())
        );

        sqlx::query(
            "UPDATE contacts SET prefer_photo_avatar = 1, avatar_svg_compressed = ? WHERE user_id \
             = 7",
        )
        .bind(SVG.as_bytes())
        .execute(&db.pool)
        .await?;

        assert_eq!(ensure_contact_avatar_png(&ctx, 7).await?, Some(photo));

        // A replaced photo has a new counter, so the cached file of the old
        // one must not answer for it.
        let replacement = media_codec::encode_webp(
            &DynamicImage::ImageRgba8(RgbaImage::from_pixel(8, 8, Rgba([4, 5, 6, 255]))),
            90.0,
        )?;

        sqlx::query(
            "UPDATE received_custom_avatars SET applied_counter = 1, webp = ? WHERE contact_id = 7",
        )
        .bind(&replacement)
        .execute(&db.pool)
        .await?;

        let replaced = ensure_contact_avatar_png(&ctx, 7).await?.unwrap();

        assert_eq!(replaced.file_name().unwrap(), "contact_7_custom_1.webp");

        assert_eq!(std::fs::read(&replaced)?, replacement);

        sqlx::query("DELETE FROM received_custom_avatars WHERE contact_id = 7")
            .execute(&db.pool)
            .await?;

        assert_eq!(ensure_contact_avatar_png(&ctx, 7).await?, Some(illustrated));

        Ok(())
    }

    #[tokio::test]

    async fn group_notification_avatar_uses_active_members_and_updates_with_their_avatars(
    ) -> Result<()> {
        let temporary = tempfile::tempdir()?;

        let ctx = Context::init_for_testing(
            temporary.path().join("database"),
            temporary.path().join("data"),
        )
        .await?;

        let db = ctx.app_db.read().await.clone();

        sqlx::query("INSERT INTO groups(group_id, group_name) VALUES ('g', 'Friends')")
            .execute(&db.pool)
            .await?;

        assert!(ensure_group_avatar_png(&ctx, "g").await?.is_none());

        sqlx::query(
            "INSERT INTO contacts(user_id, username, avatar_svg_compressed) VALUES (7, 'alice', ?)",
        )
        .bind(SVG.as_bytes())
        .execute(&db.pool)
        .await?;

        sqlx::query("INSERT INTO contacts(user_id, username) VALUES (8, 'bob')")
            .execute(&db.pool)
            .await?;

        sqlx::query(
            "INSERT INTO group_members(group_id, contact_id, last_message) VALUES ('g', 7, 2), \
             ('g', 8, 1)",
        )
        .execute(&db.pool)
        .await?;

        let first = ensure_group_avatar_png(&ctx, "g").await?.unwrap();

        let image = image::open(&first)
            .map_err(|error| TwonlyError::Generic(error.to_string()))?
            .to_rgba8();

        assert_eq!(image.dimensions(), (256, 256));

        assert_eq!(image.get_pixel(200, 128), &Rgba([255, 0, 0, 255]));

        // Bob has no avatar, so Alice fills the whole group avatar.
        assert_eq!(image.get_pixel(30, 128), &Rgba([255, 0, 0, 255]));

        assert_eq!(image.get_pixel(0, 0)[3], 0);

        assert_eq!(
            ensure_group_avatar_png(&ctx, "g").await?,
            Some(first.clone())
        );

        // A member without an avatar never appears, even after writing more
        // recently.
        sqlx::query("UPDATE group_members SET last_message = 3 WHERE contact_id = 8")
            .execute(&db.pool)
            .await?;

        assert_eq!(
            ensure_group_avatar_png(&ctx, "g").await?,
            Some(first.clone())
        );

        // A changed member avatar must produce a fresh file rather than reuse
        // a stale group shortcut icon.
        let blue = SVG.replace("red", "blue");

        sqlx::query(
            "UPDATE contacts SET avatar_svg_compressed = ?, sender_profile_counter = 1 WHERE \
             user_id = 7",
        )
        .bind(blue.as_bytes())
        .execute(&db.pool)
        .await?;

        let second = ensure_group_avatar_png(&ctx, "g").await?.unwrap();

        assert_ne!(first, second);

        let image = image::open(&second)
            .map_err(|error| TwonlyError::Generic(error.to_string()))?
            .to_rgba8();

        assert_eq!(image.get_pixel(200, 128), &Rgba([0, 0, 255, 255]));

        // A member who left no longer contributes an avatar, and the remaining
        // member has none.
        sqlx::query("UPDATE group_members SET member_state = 'leftGroup' WHERE contact_id = 7")
            .execute(&db.pool)
            .await?;

        assert!(ensure_group_avatar_png(&ctx, "g").await?.is_none());

        Ok(())
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
