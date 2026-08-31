use crate::context::Context;
use crate::error::{Result, TwonlyError};
use crate::user_config::UserConfig;
use flate2::read::GzDecoder;
use std::io::Read;
use std::path::{Path, PathBuf};
use std::sync::Mutex;

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
}
