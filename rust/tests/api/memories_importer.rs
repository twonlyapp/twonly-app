//! End to end: the memories importer page, the server and this app.
//!
//! The page runs for real in a headless browser (driven by the page repo's
//! `tests/e2e/page-driver.mjs`) on a synthetic Snapchat export made by its
//! `tests/helpers/make-snapchat-fixture.mjs`. This test is the app: it registers a
//! paid account, claims the page's QR link with the app's own sealing code,
//! lets the page upload, then discovers, checks and decrypts every imported
//! memory and compares it with the fixture's `expected.json`.
//!
//! Run it through the page repo's `tests/e2e/full-stack.sh` (against the dev
//! server by default), which serves the page and sets:
//!   TWONLY_TEST_API_ORIGIN         the API server under test
//!   TWONLY_IMPORTER_E2E_PAGE_URL   the locally served page
//!   TWONLY_IMPORTER_E2E_FIXTURE    the generated export (zips/, expected.json)
//!   TWONLY_IMPORTER_E2E_DRIVER     path to page-driver.mjs
//! Without them the test reports itself skipped.

use crate::Tester;
use rust_lib_twonly::api::Server;
use rust_lib_twonly::bridge::api::{ApiConnectionState, ServerResult};
use rust_lib_twonly::services::media_exif::read_exif;
use rust_lib_twonly::services::memory_importer;
use serde::Deserialize;
use sha2::{Digest, Sha256};
use std::collections::HashMap;
use std::io::Read;
use std::process::Stdio;
use std::time::Duration;
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader, Lines};
use tokio::process::{Child, ChildStdin, ChildStdout, Command};

#[derive(Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
struct ExpectedItem {
    source_item_id: String,
    kind: String,
    created_at: i64,
    location: Option<Location>,
    has_overlay: bool,
    overlay_composited: bool,
    imported: bool,
}

#[derive(Deserialize, Debug)]
struct Location {
    latitude: f64,
    longitude: f64,
}

#[derive(Deserialize, Debug)]
struct Expected {
    items: Vec<ExpectedItem>,
}

/// What the page's done screen shows.
#[derive(Deserialize, Debug)]
#[serde(rename_all = "camelCase")]
struct PageResult {
    heading: String,
    uploaded: usize,
    already_uploaded: usize,
    not_imported: usize,
    not_imported_list: Vec<Reason>,
}

impl PageResult {
    /// Finished, and every memory that was not imported is one the fixture
    /// makes too large: nothing failed and nothing hit an ownership conflict.
    fn assert_only_too_large_left_out(&self, expected: usize) {
        assert_eq!(self.heading, "Done", "{self:?}");
        assert_eq!(self.uploaded + self.already_uploaded + self.not_imported, expected, "{self:?}");
        assert_eq!(self.not_imported_list.len(), self.not_imported, "{self:?}");
        assert!(self.not_imported_list.iter().all(|r| r.reason.contains("too large")), "{:?}", self.not_imported_list);
        assert!(self.not_imported_list.iter().all(|r| r.path.starts_with("memories/")), "{:?}", self.not_imported_list);
    }
}

#[derive(Deserialize, Debug)]
struct Reason {
    path: String,
    reason: String,
}

struct Driver {
    child: Child,
    stdin: ChildStdin,
    lines: Lines<BufReader<ChildStdout>>,
}

impl Driver {
    async fn expect(&mut self, prefix: &str, timeout: Duration) -> anyhow::Result<String> {
        loop {
            let line = tokio::time::timeout(timeout, self.lines.next_line())
                .await
                .map_err(|_| anyhow::anyhow!("timed out waiting for {prefix} from the page"))??
                .ok_or_else(|| anyhow::anyhow!("the page driver exited while waiting for {prefix}"))?;
            if let Some(rest) = line.strip_prefix("ERROR ") {
                anyhow::bail!("page driver: {rest}");
            }
            if let Some(rest) = line.strip_prefix(prefix) {
                return Ok(rest.trim().to_owned());
            }
        }
    }

    async fn send(&mut self, command: &str) -> anyhow::Result<()> {
        self.stdin.write_all(format!("{command}\n").as_bytes()).await?;
        self.stdin.flush().await?;
        Ok(())
    }
}

fn env(name: &str) -> Option<String> {
    std::env::var(name).ok().filter(|value| !value.is_empty())
}

/// Every file of the export by path, read back from the ZIP parts.
fn export_files(zips: &std::path::Path) -> anyhow::Result<HashMap<String, Vec<u8>>> {
    let mut files = HashMap::new();
    for entry in std::fs::read_dir(zips)? {
        let path = entry?.path();
        if path.extension().and_then(|e| e.to_str()) != Some("zip") {
            continue;
        }
        let mut archive = zip::ZipArchive::new(std::fs::File::open(&path)?)?;
        for index in 0..archive.len() {
            let mut file = archive.by_index(index)?;
            let mut bytes = Vec::new();
            file.read_to_end(&mut bytes)?;
            files.insert(file.name()?.to_string(), bytes);
        }
    }
    Ok(files)
}

fn main_file<'a>(files: &'a HashMap<String, Vec<u8>>, mid: &str) -> &'a [u8] {
    files
        .iter()
        .find(|(name, _)| name.contains(mid) && name.contains("-main."))
        .map(|(_, bytes)| bytes.as_slice())
        .expect("the export holds every expected memory")
}

#[tokio::test]
async fn memories_importer_end_to_end() -> anyhow::Result<()> {
    crate::init_tracing();
    let (Some(page_url), Some(fixture), Some(driver_path)) = (
        env("TWONLY_IMPORTER_E2E_PAGE_URL"),
        env("TWONLY_IMPORTER_E2E_FIXTURE"),
        env("TWONLY_IMPORTER_E2E_DRIVER"),
    ) else {
        eprintln!("memories_importer_end_to_end skipped: run it through twonly-memories-import/tests/e2e/full-stack.sh");
        return Ok(());
    };
    let fixture = std::path::PathBuf::from(fixture);
    let expected: Expected = serde_json::from_slice(&std::fs::read(fixture.join("expected.json"))?)?;
    let importable: Vec<&ExpectedItem> = expected.items.iter().filter(|item| item.imported).collect();
    let export = export_files(&fixture.join("zips"))?;

    // A paid account ("tobi…" gets the Family plan on a testing server).
    let mut tester = Tester::new().await?;
    tester.wait_until(ApiConnectionState::Connected).await?;
    tester.username = format!("tobi{}", &uuid::Uuid::new_v4().simple().to_string()[..8]);
    tester.register_and_authenticate().await?;
    tester.update_profile(Some(tester.username.clone()), Some("Tobi <script>".into()), None)?;
    let ctx = tester.context.clone();

    // The page, in a browser.
    let mut child = Command::new("node")
        .arg(&driver_path)
        .args(["--url", &page_url, "--zips"])
        .arg(fixture.join("zips"))
        .args(["--username", &tester.username])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::inherit())
        .kill_on_drop(true)
        .spawn()?;
    let mut driver = Driver {
        stdin: child.stdin.take().expect("piped"),
        lines: BufReader::new(child.stdout.take().expect("piped")).lines(),
        child,
    };

    // Pairing: the app claims what the page shows.
    let link = driver.expect("PAIRING ", Duration::from_secs(120)).await?;
    let ServerResult::Ok(claimed) = memory_importer::claim(&ctx, &link).await? else {
        anyhow::bail!("the claim was refused");
    };
    // Claim-once: the same code cannot be claimed again.
    match memory_importer::claim(&ctx, &link).await? {
        ServerResult::ErrorCode(1040) => {}
        other => anyhow::bail!("a second claim must be refused, got {:?}", matches!(other, ServerResult::Ok(_))),
    }
    // The page shows the account the server saw claim, not a name from the envelope.
    let account = driver.expect("ACCOUNT ", Duration::from_secs(60)).await?;
    assert_eq!(account, format!("@{}", tester.username));

    // The upload.
    let result: PageResult = serde_json::from_str(&driver.expect("RESULT ", Duration::from_secs(900)).await?)?;
    result.assert_only_too_large_left_out(expected.items.len());
    assert_eq!(result.uploaded, importable.len(), "{result:?}");
    assert_eq!(result.not_imported, expected.items.len() - importable.len());

    driver.send("check-csp").await?;
    driver.expect("OK check-csp", Duration::from_secs(30)).await?;

    // The server's view.
    let ServerResult::Ok(importers) = Server::list_memory_importers(&ctx).await? else {
        anyhow::bail!("listing importers failed");
    };
    assert_eq!(importers.importers.len(), 1);
    let importer = &importers.importers[0];
    assert_eq!(importer.id, claimed.import_id);
    assert!(importer.active);
    assert_eq!(importer.uploaded_count as usize, importable.len());
    let ServerResult::Ok(usage) = Server::get_memories_usage(&ctx).await? else {
        anyhow::bail!("usage failed");
    };
    assert_eq!(usage.count as usize, importable.len());

    // Discovery on this device: every imported memory, checked and decrypted.
    // The `memoriesImported` push may already have started a background
    // pass, so some memories can be local before this one runs.
    let report = memory_importer::reconcile_imported_memories(&ctx).await?;
    assert!(report.failed.is_empty(), "{:?}", report.failed);
    assert_eq!(report.added.len() + report.already_local, importable.len());
    // Running it again adds nothing.
    let again = memory_importer::reconcile_imported_memories(&ctx).await?;
    assert!(again.added.is_empty());
    assert_eq!(again.already_local, importable.len());

    let database = ctx.app_db.read().await.clone();
    for item in &importable {
        let row: (String, String, String, Option<f64>, Option<f64>, i64, i64) = sqlx::query_as(
            "SELECT m.media_id, m.type, m.cloud_state, m.location_latitude, m.location_longitude, \
             m.has_thumbnail, m.stored FROM media_files m JOIN imported_memories i ON i.media_id = \
             m.media_id WHERE m.created_at = ? AND i.importer_id = ? AND i.source = 'snapchat'",
        )
        .bind(item.created_at)
        .bind(&claimed.import_id)
        .fetch_one(&database.pool)
        .await
        .map_err(|e| anyhow::anyhow!("memory {} not in the gallery: {e}", item.source_item_id))?;
        let (media_id, kind, cloud_state, latitude, longitude, has_thumbnail, stored) = row;
        assert_eq!(kind, item.kind, "{}", item.source_item_id);
        assert_eq!((cloud_state.as_str(), has_thumbnail, stored), ("uploaded", 1, 0));
        match &item.location {
            Some(location) => {
                assert!((latitude.unwrap() - location.latitude).abs() < 1e-9);
                assert!((longitude.unwrap() - location.longitude).abs() < 1e-9);
            }
            None => assert_eq!((latitude, longitude), (None, None), "{}", item.source_item_id),
        }

        // The thumbnail: a WebP of at most 400 px with the date in its EXIF.
        let thumbnail = memory_importer::local_thumbnail(&ctx, &media_id)?;
        assert!(thumbnail.len() <= 300_000);
        let decoded = image::load_from_memory_with_format(&thumbnail, image::ImageFormat::WebP)?;
        assert!(decoded.width().max(decoded.height()) <= 400);
        assert_eq!(read_exif(&thumbnail)?.created_at.map(|t| t.timestamp()), Some(item.created_at));

        // The full media through the same checks.
        let full = memory_importer::download_full_media(&ctx, &media_id).await?;
        if item.kind == "video" {
            // Videos are uploaded unchanged.
            assert_eq!(
                Sha256::digest(&full),
                Sha256::digest(main_file(&export, &item.source_item_id)),
                "video {}",
                item.source_item_id
            );
        } else {
            let exif = read_exif(&full)?;
            assert_eq!(exif.created_at.map(|t| t.timestamp()), Some(item.created_at));
            if let Some(location) = &item.location {
                assert!((exif.latitude.unwrap() - location.latitude).abs() < 1e-5);
                assert!((exif.longitude.unwrap() - location.longitude).abs() < 1e-5);
            }
            let image = image::load_from_memory_with_format(&full, image::ImageFormat::WebP)?.to_rgb8();
            if item.overlay_composited {
                // Magenta caption bar on top, the green photo below it.
                let top = image.get_pixel(image.width() / 2, image.height() / 20);
                let bottom = image.get_pixel(image.width() / 2, image.height() * 9 / 10);
                assert!(top[0] > 200 && top[1] < 80 && top[2] > 200, "overlay pixel {top:?}");
                assert!(bottom[1] > 130 && bottom[0] < 100, "photo pixel {bottom:?}");
            }
            let original = image::load_from_memory(main_file(&export, &item.source_item_id))?;
            assert_eq!((image.width(), image.height()), (original.width(), original.height()));
        }
        assert!(!item.has_overlay || item.kind == "video" || item.overlay_composited);
    }

    // Resume in the same browser: everything is already done.
    driver.send("rerun").await?;
    let rerun: PageResult = serde_json::from_str(&driver.expect("RESULT ", Duration::from_secs(300)).await?)?;
    rerun.assert_only_too_large_left_out(expected.items.len());
    assert_eq!((rerun.uploaded, rerun.already_uploaded), (0, importable.len()));

    // Without local progress the server deduplicates by the stable media ids.
    driver.send("forget-progress").await?;
    driver.expect("OK forget-progress", Duration::from_secs(30)).await?;
    driver.send("rerun").await?;
    let dedupe: PageResult = serde_json::from_str(&driver.expect("RESULT ", Duration::from_secs(600)).await?)?;
    dedupe.assert_only_too_large_left_out(expected.items.len());
    assert_eq!((dedupe.uploaded, dedupe.already_uploaded), (0, importable.len()));
    let ServerResult::Ok(usage) = Server::get_memories_usage(&ctx).await? else {
        anyhow::bail!("usage failed");
    };
    assert_eq!(usage.count as usize, importable.len(), "no duplicates");

    // Removing the importer in the app ends the page's connection.
    assert!(matches!(Server::revoke_memory_importer(&ctx, claimed.import_id.clone()).await?, ServerResult::Ok(())));
    driver.send("expect-pairing").await?;
    driver.expect("PAIRING_SCREEN", Duration::from_secs(60)).await?;

    // "Remove and delete everything it uploaded".
    assert!(matches!(
        Server::delete_memory_importer_uploads(&ctx, claimed.import_id.clone()).await?,
        ServerResult::Ok(())
    ));
    let ServerResult::Ok(usage) = Server::get_memories_usage(&ctx).await? else {
        anyhow::bail!("usage failed");
    };
    assert_eq!((usage.count, usage.current_bytes), (0, 0));

    driver.send("quit").await?;
    let _ = tokio::time::timeout(Duration::from_secs(10), driver.child.wait()).await;
    Ok(())
}
