/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! Serving the contents of an `.xdc` bundle to a webview.
//!
//! The bundle is never unpacked. Every request the webview makes is answered by
//! an exact-name lookup in the zip's central directory, which is what makes
//! path traversal structurally impossible rather than merely filtered: there is
//! no filesystem path built from anything the app or a peer controls.
//!
//! This module is the only place bundle bytes reach the webview, so it is also
//! where the response headers that keep the app boxed in are attached.

use crate::error::{Result, TwonlyError};
use std::io::Read;
use std::path::Path;

/// Refuses to expand a single entry beyond this, whatever the zip claims.
const MAX_ENTRY_BYTES: u64 = 32 * 1024 * 1024;

/// Denies the app every way out of its own origin.
///
/// The scheme handler already answers requests for anything else with a 403
/// without touching the network, so this is defence in depth: CSP has a history
/// of gaps (WebRTC, prefetch, plugins) and is not load bearing on its own.
const CONTENT_SECURITY_POLICY: &str = "default-src 'self'; \
     script-src 'self' 'unsafe-inline' 'unsafe-eval'; \
     style-src 'self' 'unsafe-inline'; \
     img-src 'self' data: blob:; \
     media-src 'self' data: blob:; \
     font-src 'self' data:; \
     connect-src 'self' data: blob:; \
     worker-src 'self' blob:; \
     object-src 'none'; \
     base-uri 'none'; \
     form-action 'none'; \
     frame-src 'none'; \
     frame-ancestors 'none'";

/// Every powerful feature a webview can hand a page, switched off. The native
/// permission callbacks deny these too; a header costs nothing and covers the
/// features whose prompts a platform might answer on its own.
const PERMISSIONS_POLICY: &str = "accelerometer=(), ambient-light-sensor=(), autoplay=(), \
     camera=(), display-capture=(), encrypted-media=(), geolocation=(), gyroscope=(), \
     magnetometer=(), microphone=(), midi=(), payment=(), publickey-credentials-get=(), \
     screen-wake-lock=(), serial=(), usb=(), xr-spatial-tracking=()";

pub struct HttpResponse {
    pub status: u16,
    pub mime: String,
    pub headers: Vec<(String, String)>,
    pub body: Vec<u8>,
}

impl HttpResponse {
    fn new(status: u16, mime: &str, body: Vec<u8>) -> Self {
        Self {
            status,
            mime: mime.to_string(),
            headers: vec![
                (
                    "Content-Security-Policy".into(),
                    CONTENT_SECURITY_POLICY.into(),
                ),
                ("Permissions-Policy".into(), PERMISSIONS_POLICY.into()),
                ("X-Content-Type-Options".into(), "nosniff".into()),
                ("Referrer-Policy".into(), "no-referrer".into()),
                ("Cross-Origin-Opener-Policy".into(), "same-origin".into()),
                ("Cross-Origin-Embedder-Policy".into(), "require-corp".into()),
                ("Cross-Origin-Resource-Policy".into(), "same-origin".into()),
                ("Cache-Control".into(), "no-store".into()),
            ],
            body,
        }
    }

    fn forbidden() -> Self {
        Self::new(403, "text/plain", b"forbidden".to_vec())
    }

    fn not_found() -> Self {
        Self::new(404, "text/plain", b"not found".to_vec())
    }
}

/// The API implementation served in place of anything the bundle ships under
/// that name. Serving it from here rather than injecting it into the document
/// means it is subject to the same CSP as the rest of the app.
const WEBXDC_JS: &str = include_str!("webxdc.js");

/// Turns a URL path into the zip entry name it may read, or `None` if it may
/// not read anything.
///
/// Rejects rather than sanitises: a request that needed cleaning up is a
/// request no honest app makes, and rewriting it would only hide that.
fn entry_name(request_path: &str) -> Option<String> {
    let path = request_path
        .split(['?', '#'])
        .next()
        .unwrap_or_default()
        .trim_start_matches('/');
    let path = percent_decode(path)?;

    if path.is_empty() {
        return Some("index.html".to_string());
    }
    if path.len() > 512
        || path.contains('\\')
        || path.contains('\0')
        || path
            .split('/')
            .any(|segment| segment == ".." || segment == ".")
    {
        return None;
    }
    if path.ends_with('/') {
        return Some(format!("{path}index.html"));
    }
    Some(path)
}

fn percent_decode(input: &str) -> Option<String> {
    let bytes = input.as_bytes();
    let mut out = Vec::with_capacity(bytes.len());
    let mut index = 0;
    while index < bytes.len() {
        if bytes[index] == b'%' {
            let hex = input.get(index + 1..index + 3)?;
            out.push(u8::from_str_radix(hex, 16).ok()?);
            index += 3;
        } else {
            out.push(bytes[index]);
            index += 1;
        }
    }
    String::from_utf8(out).ok()
}

/// Only types a webxdc app has a reason to ship. Anything else is served as an
/// opaque download with `nosniff`, so an unexpected file cannot become script.
fn mime_for(name: &str) -> &'static str {
    let extension = name.rsplit('.').next().unwrap_or_default().to_lowercase();
    match extension.as_str() {
        "html" | "htm" => "text/html; charset=utf-8",
        "js" | "mjs" => "text/javascript; charset=utf-8",
        "css" => "text/css; charset=utf-8",
        "json" => "application/json; charset=utf-8",
        "txt" | "md" => "text/plain; charset=utf-8",
        "svg" => "image/svg+xml",
        "png" => "image/png",
        "jpg" | "jpeg" => "image/jpeg",
        "gif" => "image/gif",
        "webp" => "image/webp",
        "ico" => "image/x-icon",
        "wasm" => "application/wasm",
        "woff" => "font/woff",
        "woff2" => "font/woff2",
        "ttf" => "font/ttf",
        "otf" => "font/otf",
        "mp3" => "audio/mpeg",
        "ogg" | "oga" => "audio/ogg",
        "wav" => "audio/wav",
        "mp4" => "video/mp4",
        "webm" => "video/webm",
        _ => "application/octet-stream",
    }
}

/// Answers one webview request against one bundle.
///
/// `request_path` is the path component of the URL the webview asked for; the
/// caller has already established that the origin belongs to this instance.
/// `init` is the JSON object substituted into `webxdc.js`; it is produced by
/// the caller and never passes through the page.
pub fn serve(bundle_path: &Path, request_path: &str, init: &str) -> HttpResponse {
    let Some(name) = entry_name(request_path) else {
        return HttpResponse::forbidden();
    };

    if name == "webxdc.js" {
        // Served in place of anything the bundle ships under that name, and
        // subject to the same CSP as the rest of the app because it arrives as
        // a response rather than as an injected script. Serving it also removes
        // the race an injection at document start would have with the page's
        // own scripts.
        return HttpResponse::new(
            200,
            "text/javascript; charset=utf-8",
            WEBXDC_JS
                .replace("__TWONLY_WEBXDC_INIT__", init)
                .into_bytes(),
        );
    }

    match read_entry(bundle_path, &name) {
        Ok(Some(body)) => HttpResponse::new(200, mime_for(&name), body),
        Ok(None) => HttpResponse::not_found(),
        Err(error) => {
            tracing::warn!("serving {name} from a webxdc bundle failed: {error}");
            HttpResponse::not_found()
        }
    }
}

fn read_entry(bundle_path: &Path, name: &str) -> Result<Option<Vec<u8>>> {
    let file = std::fs::File::open(bundle_path)?;
    let mut archive = zip::ZipArchive::new(std::io::BufReader::new(file))?;
    let mut entry = match archive.by_name(name) {
        Ok(entry) => entry,
        Err(zip::result::ZipError::FileNotFound) => return Ok(None),
        Err(error) => return Err(error.into()),
    };
    if !entry.is_file() {
        return Ok(None);
    }
    if entry.size() > MAX_ENTRY_BYTES {
        return Err(TwonlyError::Generic(format!(
            "webxdc entry {name} declares {} bytes",
            entry.size()
        )));
    }

    // Reads through a limited reader as well as checking the declared size: the
    // declaration is attacker controlled and a lying header must not be able to
    // turn into an unbounded allocation.
    let mut body = Vec::with_capacity(entry.size().min(1024 * 1024) as usize);
    std::io::Read::take(&mut entry, MAX_ENTRY_BYTES + 1).read_to_end(&mut body)?;
    if body.len() as u64 > MAX_ENTRY_BYTES {
        return Err(TwonlyError::Generic(format!(
            "webxdc entry {name} expanded past the entry limit"
        )));
    }
    Ok(Some(body))
}

#[cfg(test)]
mod tests {
    use super::entry_name;

    #[test]
    fn empty_and_directory_paths_resolve_to_index() {
        assert_eq!(entry_name("/").as_deref(), Some("index.html"));
        assert_eq!(entry_name("").as_deref(), Some("index.html"));
        assert_eq!(entry_name("/sub/").as_deref(), Some("sub/index.html"));
        assert_eq!(
            entry_name("/index.html?v=2#top").as_deref(),
            Some("index.html")
        );
    }

    #[test]
    fn traversal_is_refused_in_every_encoding() {
        for path in [
            "/../secrets",
            "/a/../../b",
            "/%2e%2e/secrets",
            "/%2E%2E%2Fsecrets",
            "/a/./b",
            "/a\\b",
            "/a%00.png",
        ] {
            assert!(entry_name(path).is_none(), "{path} was not refused");
        }
    }

    #[test]
    fn ordinary_paths_survive() {
        assert_eq!(entry_name("/main.js").as_deref(), Some("main.js"));
        assert_eq!(
            entry_name("/assets/my%20image.png").as_deref(),
            Some("assets/my image.png")
        );
    }
}
