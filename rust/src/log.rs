/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::bridge::logging::LogLevel;
use crate::error::{Result, TwonlyError};
use std::borrow::Cow;
use std::fmt;
use std::fs::{File, OpenOptions};
use std::io::{Seek, Write as IoWrite};
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicU8, Ordering};
use std::sync::{Mutex, OnceLock};
use tracing::{Event, Subscriber};
use tracing_log::NormalizeEvent;
use tracing_subscriber::fmt::format::Writer;
use tracing_subscriber::fmt::{
    FmtContext, FormatEvent, FormatFields, FormattedFields, Layer, MakeWriter,
};
use tracing_subscriber::layer::SubscriberExt;
use tracing_subscriber::registry::LookupSpan;
use tracing_subscriber::util::SubscriberInitExt;
use tracing_subscriber::{EnvFilter, Registry};

static TRACING_INIT: OnceLock<()> = OnceLock::new();

static APP_LOG: OnceLock<AppLog> = OnceLock::new();

static RUST_LOG_SOURCE: AtomicU8 = AtomicU8::new(b'f');

tokio::task_local! {
    static SCOPED_LOG_SOURCE: LogSource;
}

const LOG_SIZE_CLEANUP_THRESHOLD_BYTES: usize = 5 * 1024 * 1024;

const LOG_SIZE_CLEANUP_TARGET_BYTES: usize = 4 * 1024 * 1024;

// Keep dependency diagnostics and routine HTTP connection activity out of the
// application log while preserving their warnings and errors.
const DEFAULT_LOG_FILTER: &str =
    "debug,refinery_core=warn,refinery=warn,tract=warn,hyper=warn,hyper_util=warn,reqwest=warn,\
     keyring_core=warn,apple_native_keyring_store=warn,android_native_keyring_store=warn";

const TEST_LOG_FILTER: &str = "info,refinery_core=warn,refinery=warn,tract=warn,hyper=warn,\
                               hyper_util=warn,reqwest=warn,keyring_core=warn,\
                               apple_native_keyring_store=warn,android_native_keyring_store=warn";

/// The execution that owns a record, independent of other work in the process.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
#[repr(u8)]

pub(crate) enum LogSource {
    Foreground = b'f',
    Notification = b'n',
    ForegroundService = b's',
    Background = b'b',
}

impl LogSource {
    // Cleanup supervisors need a log source without acquiring database
    // ownership or inheriting the cancelled operation's execution scope.
    pub(crate) async fn scope<T>(self, work: impl std::future::Future<Output = T>) -> T {
        SCOPED_LOG_SOURCE.scope(self, work).await
    }

    pub(crate) fn scope_sync<T>(self, work: impl FnOnce() -> T) -> T {
        SCOPED_LOG_SOURCE.sync_scope(self, work)
    }

    fn marker(self) -> char {
        match self {
            Self::Foreground if crate::database::lifecycle::foreground::active() => 'f',
            Self::Foreground | Self::Background => 'b',
            Self::Notification => 'n',
            Self::ForegroundService => 's',
        }
    }
}

pub(crate) fn current_log_source() -> LogSource {
    SCOPED_LOG_SOURCE
        .try_with(|source| *source)
        .ok()
        .or_else(|| {
            crate::database::lifecycle::Operation::current().map(|operation| operation.log_source())
        })
        .unwrap_or_else(|| match RUST_LOG_SOURCE.load(Ordering::Relaxed) {
            b'n' => LogSource::Notification,
            b's' => LogSource::ForegroundService,
            b'b' => LogSource::Background,
            _ => LogSource::Foreground,
        })
}

struct AppLog {
    path: PathBuf,
    file: Mutex<File>,
}

impl AppLog {
    fn open(path: PathBuf) -> std::io::Result<Self> {
        if let Some(parent) = path.parent() {
            std::fs::create_dir_all(parent)?;
        }

        let file = OpenOptions::new().create(true).append(true).open(&path)?;

        Ok(Self {
            path,
            file: Mutex::new(file),
        })
    }

    fn append(&self, bytes: &[u8]) -> std::io::Result<()> {
        let mut file = self
            .file
            .lock()
            .map_err(|_| std::io::Error::other("app.log lock was poisoned"))?;

        file.write_all(bytes)
    }

    fn read(&self) -> std::io::Result<String> {
        let _file = self
            .file
            .lock()
            .map_err(|_| std::io::Error::other("app.log lock was poisoned"))?;

        // An interrupted write can leave an incomplete UTF-8 character in the
        // log. Diagnostics and cleanup should still be able to read it.
        let bytes = std::fs::read(&self.path)?;

        Ok(String::from_utf8_lossy(&bytes).into_owned())
    }

    fn replace(&self, contents: &str) -> std::io::Result<()> {
        let mut file = self
            .file
            .lock()
            .map_err(|_| std::io::Error::other("app.log lock was poisoned"))?;

        file.set_len(0)?;

        file.seek(std::io::SeekFrom::Start(0))?;

        file.write_all(contents.as_bytes())?;

        file.seek(std::io::SeekFrom::End(0))?;

        Ok(())
    }
}

#[derive(Clone, Copy)]

struct AppLogWriter;

struct AppLogBuffer(Vec<u8>);

impl std::io::Write for AppLogBuffer {
    fn write(&mut self, buf: &[u8]) -> std::io::Result<usize> {
        self.0.extend_from_slice(buf);

        Ok(buf.len())
    }

    fn flush(&mut self) -> std::io::Result<()> {
        Ok(())
    }
}

impl Drop for AppLogBuffer {
    fn drop(&mut self) {
        if !self.0.is_empty() {
            if let Some(log) = APP_LOG.get() {
                if let Err(error) = log.append(&self.0) {
                    eprintln!("Failed to append to app.log: {error}");
                }
            }
        }
    }
}

impl<'a> MakeWriter<'a> for AppLogWriter {
    type Writer = AppLogBuffer;

    fn make_writer(&'a self) -> Self::Writer {
        AppLogBuffer(Vec::new())
    }
}

/// Android sends a native library's stdout to `/dev/null`; only `liblog`
/// reaches logcat, so the console layer has to go through it there.
#[cfg(target_os = "android")]

mod logcat {

    use std::ffi::CString;
    use std::os::raw::{c_char, c_int};
    use tracing::Metadata;
    use tracing_subscriber::fmt::MakeWriter;

    #[link(name = "log")]

    extern "C" {

        fn __android_log_write(prio: c_int, tag: *const c_char, text: *const c_char) -> c_int;

    }

    const TAG: &[u8] = b"twonly\0";

    /// logcat truncates a record at ~4 KiB, so split before it does.

    const MAX_PAYLOAD: usize = 3800;

    const PRIO_VERBOSE: c_int = 2;

    const PRIO_DEBUG: c_int = 3;

    const PRIO_INFO: c_int = 4;

    const PRIO_WARN: c_int = 5;

    const PRIO_ERROR: c_int = 6;

    #[derive(Clone, Copy)]

    pub(super) struct LogcatWriter;

    pub(super) struct LogcatBuffer {
        priority: c_int,
        buffer: Vec<u8>,
    }

    impl LogcatBuffer {
        const fn new(priority: c_int) -> Self {
            Self {
                priority,
                buffer: Vec::new(),
            }
        }

        fn emit(&self, message: &str) {
            let Ok(text) = CString::new(message) else {
                return;
            };

            // SAFETY: both pointers are NUL-terminated and outlive the call.
            unsafe {
                __android_log_write(self.priority, TAG.as_ptr().cast::<c_char>(), text.as_ptr());
            }
        }
    }

    impl std::io::Write for LogcatBuffer {
        fn write(&mut self, buf: &[u8]) -> std::io::Result<usize> {
            self.buffer.extend_from_slice(buf);

            Ok(buf.len())
        }

        fn flush(&mut self) -> std::io::Result<()> {
            Ok(())
        }
    }

    impl Drop for LogcatBuffer {
        fn drop(&mut self) {
            if self.buffer.is_empty() {
                return;
            }

            let text = String::from_utf8_lossy(&self.buffer);

            for line in text.lines() {
                // An interior NUL would silently cut the record short.
                let line = line.replace('\0', "");

                let mut rest = line.as_str();

                while !rest.is_empty() {
                    let split = if rest.len() <= MAX_PAYLOAD {
                        rest.len()
                    } else {
                        let mut index = MAX_PAYLOAD;

                        while index > 0 && !rest.is_char_boundary(index) {
                            index -= 1;
                        }

                        index.max(1)
                    };

                    let (chunk, remainder) = rest.split_at(split);

                    self.emit(chunk);

                    rest = remainder;
                }
            }
        }
    }

    impl<'a> MakeWriter<'a> for LogcatWriter {
        type Writer = LogcatBuffer;

        fn make_writer(&'a self) -> Self::Writer {
            LogcatBuffer::new(PRIO_INFO)
        }

        fn make_writer_for(&'a self, meta: &Metadata<'_>) -> Self::Writer {
            LogcatBuffer::new(match *meta.level() {
                tracing::Level::TRACE => PRIO_VERBOSE,
                tracing::Level::DEBUG => PRIO_DEBUG,
                tracing::Level::INFO => PRIO_INFO,
                tracing::Level::WARN => PRIO_WARN,
                tracing::Level::ERROR => PRIO_ERROR,
            })
        }
    }
}

/// Drops the warnings dependencies raise about situations twonly expects and
/// already handles, so the log keeps its attention for the ones it does not.
///
/// - flutter_rust_bridge reports every post to a Dart isolate that is gone.
///   Android starts a new isolate in a process that still holds the old one's
///   streams; each stream ends on its first failed post, so a burst of these
///   follows every such start and names nothing to act on.
/// - stream-tungstenite logs any handshake the handshaker ended as an error,
///   including the two that end on purpose: a newer connection overtaking the
///   one being authenticated, and the server refusing a background session
///   while the app holds the foreground one.

#[derive(Clone, Copy, Debug, Default)]

pub(crate) struct ExpectedNoise;

impl<S: Subscriber> tracing_subscriber::Layer<S> for ExpectedNoise {
    fn event_enabled(
        &self, event: &Event<'_>, _context: tracing_subscriber::layer::Context<'_, S>,
    ) -> bool {
        !is_expected_noise(event)
    }
}

fn is_expected_noise(event: &Event<'_>) -> bool {
    let normalized = event.normalized_metadata();
    let metadata = normalized.as_ref().unwrap_or_else(|| event.metadata());
    let target = metadata.target();

    let bridge = target.starts_with("flutter_rust_bridge");

    if !bridge && !target.starts_with("stream_tungstenite") {
        return false;
    }

    #[derive(Default)]

    struct Fields {
        message: String,
        error: String,
    }

    impl tracing::field::Visit for Fields {
        fn record_debug(&mut self, field: &tracing::field::Field, value: &dyn fmt::Debug) {
            match field.name() {
                "message" => self.message = format!("{value:?}"),
                "error" => self.error = format!("{value:?}"),
                _ => {}
            }
        }
    }

    let mut fields = Fields::default();
    event.record(&mut fields);

    if bridge {
        return fields.message.starts_with("Fail to post message to Dart")
            || fields
                .message
                .starts_with("Drop DartOpaque after closing the port");
    }

    fields.message == "Handshake failed" && is_expected_handshake_failure(&fields.error)
}

fn is_expected_handshake_failure(error: &str) -> bool {
    if error.contains(crate::api::runtime::auth::CONNECTION_REPLACED) {
        return true;
    }

    let refused = format!(
        "Server returned error code: {}",
        crate::api::proto::error::ErrorCode::ForegroundSessionConnected as i32
    );

    // The code must end there: 1036 is not a prefix of another code's match.
    error
        .match_indices(&refused)
        .any(|(index, _)| !error[index + refused.len()..].starts_with(|c: char| c.is_ascii_digit()))
}

#[derive(Clone, Copy, Debug, Default)]

pub struct PlainFields;

/// SQLx logs its connection PRAGMAs when setup is slow. Those statements
/// contain the SQLCipher key even when normal statement logging is disabled.
fn format_event_fields<'writer, N: FormatFields<'writer>>(
    fields: &N, mut writer: Writer<'writer>, event: &Event<'_>,
) -> fmt::Result {
    let normalized = event.normalized_metadata();
    let metadata = normalized.as_ref().unwrap_or_else(|| event.metadata());
    if !metadata.target().starts_with("sqlx") {
        return fields.format_fields(writer, event);
    }

    struct KeyStatement(bool);

    impl tracing::field::Visit for KeyStatement {
        fn record_debug(&mut self, _field: &tracing::field::Field, value: &dyn fmt::Debug) {
            let value = format!("{value:?}").to_ascii_lowercase();
            self.0 |= value.contains("pragma key") || value.contains("pragma rekey");
        }
    }

    let mut sensitive = KeyStatement(false);
    event.record(&mut sensitive);

    if sensitive.0 {
        write!(writer, "SQLCipher key statement [SQL redacted]")
    } else {
        fields.format_fields(writer, event)
    }
}

impl<'writer> FormatFields<'writer> for PlainFields {
    fn format_fields<R: tracing_subscriber::field::RecordFields>(
        &self, writer: Writer<'writer>, fields: R,
    ) -> fmt::Result {
        tracing_subscriber::fmt::format::DefaultFields::new().format_fields(writer, fields)
    }
}

#[derive(Clone, Copy, Debug, Default)]

pub struct ShortEventFormatter {
    ansi: bool,
}

impl ShortEventFormatter {
    pub const fn ansi() -> Self {
        Self { ansi: true }
    }

    /// The same format without escape codes, for a sink that is not a terminal.

    pub const fn plain() -> Self {
        Self { ansi: false }
    }
}

impl<S, N> FormatEvent<S, N> for ShortEventFormatter
where
    S: Subscriber + for<'lookup> LookupSpan<'lookup>,
    N: for<'writer> FormatFields<'writer> + 'static,
{
    fn format_event(
        &self, ctx: &FmtContext<'_, S, N>, mut writer: Writer<'_>, event: &Event<'_>,
    ) -> fmt::Result {
        let normalized_metadata = event.normalized_metadata();

        let metadata = normalized_metadata
            .as_ref()
            .unwrap_or_else(|| event.metadata());

        let (parent, name) = match metadata.file() {
            Some(file) => {
                let path = Path::new(file);

                match (path.parent().and_then(Path::file_name), path.file_name()) {
                    (Some(p), Some(n)) => (p, n),
                    _ => return Ok(()),
                }
            }
            None => return Ok(()),
        };

        let ansi = self.ansi;

        let time = chrono::Local::now().format("%H:%M:%S");

        if ansi {
            write!(writer, "\x1b[2m{time}\x1b[0m ")?;

            let level_color = match *metadata.level() {
                tracing::Level::TRACE => "\x1b[35m",
                tracing::Level::DEBUG => "\x1b[34m",
                tracing::Level::INFO => "\x1b[32m",
                tracing::Level::WARN => "\x1b[33m",
                tracing::Level::ERROR => "\x1b[31m",
            };

            write!(
                writer,
                "{level_color}{:<5}\x1b[0m [{}] [twonly] ",
                metadata.level(),
                current_log_source().marker()
            )?;
        } else {
            write!(
                writer,
                "{time} {:<5} [{}] [twonly] ",
                metadata.level(),
                current_log_source().marker()
            )?;
        }

        if ansi {
            write!(writer, "\x1b[2m")?;
        }

        write!(
            writer,
            "{}/{}:{}",
            parent.to_string_lossy(),
            name.to_string_lossy(),
            metadata.line().unwrap_or_default()
        )?;

        if ansi {
            write!(writer, "\x1b[0m")?;
        }

        write!(writer, " ")?;

        if let Some(scope) = ctx.event_scope() {
            for span in scope.from_root() {
                let extensions = span.extensions();

                if let Some(fields) = extensions.get::<FormattedFields<N>>() {
                    if !fields.is_empty() {
                        if ansi {
                            for field in fields.fields.split_whitespace() {
                                let color = if field.starts_with("receipt_id=") {
                                    "\x1b[36m"
                                } else if field.starts_with("local_user_id=") {
                                    "\x1b[35m"
                                } else {
                                    ""
                                };

                                write!(writer, "{color}{field}\x1b[0m ")?;
                            }
                        } else {
                            write!(writer, "{fields} ")?;
                        }
                    }
                }
            }
        }

        format_event_fields(ctx.field_format(), writer.by_ref(), event)?;

        writeln!(writer)
    }
}

#[derive(Clone, Copy, Debug, Default)]

struct AppLogEventFormatter;

impl<S, N> FormatEvent<S, N> for AppLogEventFormatter
where
    S: Subscriber + for<'lookup> LookupSpan<'lookup>,
    N: for<'writer> FormatFields<'writer> + 'static,
{
    fn format_event(
        &self, ctx: &FmtContext<'_, S, N>, mut writer: Writer<'_>, event: &Event<'_>,
    ) -> fmt::Result {
        let normalized_metadata = event.normalized_metadata();

        let metadata = normalized_metadata
            .as_ref()
            .unwrap_or_else(|| event.metadata());

        let source = metadata
            .file()
            .map(Path::new)
            .and_then(|path| {
                let parent = path.parent()?.file_name()?;

                let file = path.file_name()?;

                Some(format!(
                    "{}/{}:{}",
                    parent.to_string_lossy(),
                    file.to_string_lossy(),
                    metadata.line().unwrap_or_default()
                ))
            })
            .unwrap_or_else(|| metadata.target().to_owned());

        let level = match *metadata.level() {
            tracing::Level::TRACE => "FINEST",
            tracing::Level::DEBUG => "FINE",
            tracing::Level::INFO => "INFO",
            tracing::Level::WARN => "WARNING",
            tracing::Level::ERROR => "SHOUT",
        };

        let task = current_log_source().marker();

        write!(
            writer,
            "{} {level} [{task}] [twonly] {source} > ",
            chrono::Local::now().format("%Y-%m-%d %H:%M:%S%.6f")
        )?;

        if let Some(scope) = ctx.event_scope() {
            for span in scope.from_root() {
                let extensions = span.extensions();

                if let Some(fields) = extensions.get::<FormattedFields<N>>() {
                    if !fields.is_empty() {
                        write!(writer, "{fields} ")?;
                    }
                }
            }
        }

        format_event_fields(ctx.field_format(), writer.by_ref(), event)?;

        writeln!(writer)
    }
}

pub(crate) fn init_tracing(data_dir: &Path, source: LogSource) {
    RUST_LOG_SOURCE.store(source as u8, Ordering::Relaxed);

    if APP_LOG.get().is_none() {
        match AppLog::open(data_dir.join("app.log")) {
            Ok(log) => {
                let _ = APP_LOG.set(log);
            }
            Err(error) => eprintln!("Failed to open app.log: {error}"),
        }
    }

    TRACING_INIT.get_or_init(|| {
        #[cfg(not(target_os = "android"))]
        let console_layer = Layer::new()
            .with_writer(std::io::stdout)
            .with_ansi(false)
            .event_format(ShortEventFormatter::ansi());

        #[cfg(target_os = "android")]
        let console_layer = Layer::new()
            .with_writer(logcat::LogcatWriter)
            .with_ansi(false)
            .fmt_fields(PlainFields)
            .event_format(ShortEventFormatter::plain());

        let default_filter = if std::env::var("FLUTTER_TEST").is_ok() {
            TEST_LOG_FILTER
        } else {
            DEFAULT_LOG_FILTER
        };

        let file_layer = Layer::new()
            .with_writer(AppLogWriter)
            .with_ansi(false)
            .fmt_fields(PlainFields)
            .event_format(AppLogEventFormatter);

        let _ = Registry::default()
            .with(
                EnvFilter::try_from_default_env()
                    .unwrap_or_else(|_| EnvFilter::new(default_filter)),
            )
            .with(ExpectedNoise)
            .with(console_layer)
            .with(file_layer)
            .try_init();
    });

    tracing::info!(
        app_version = env!("TWONLY_APP_FULL_VERSION"),
        platform = std::env::consts::OS,
        "twonly runtime initialized"
    );
}

fn app_log() -> Result<&'static AppLog> {
    APP_LOG.get().ok_or(TwonlyError::Initialization)
}

pub(crate) fn write_dart_log(
    level: LogLevel, source: &str, message: &str, in_background: bool,
) -> Result<()> {
    let log = app_log()?;

    let level = match level {
        LogLevel::Finest => "FINEST",
        LogLevel::Fine => "FINE",
        LogLevel::Info => "INFO",
        LogLevel::Warning => "WARNING",
        LogLevel::Shout => "SHOUT",
    };

    // Dart captures visibility with the record, including buffered startup logs.
    let task = if in_background { 'b' } else { 'f' };

    let line = format!(
        "{} {level} [{task}] [twonly] {source} > {message}\n",
        chrono::Local::now().format("%Y-%m-%d %H:%M:%S%.6f")
    );

    log.append(line.as_bytes())?;

    Ok(())
}

pub(crate) fn load_log_file() -> Result<String> {
    Ok(app_log()?.read()?)
}

pub(crate) fn read_last_log_lines(line_count: usize) -> Result<String> {
    let contents = app_log()?.read()?;

    let lines: Vec<_> = contents.lines().collect();

    let start = lines.len().saturating_sub(line_count);

    Ok(lines[start..].join("\n"))
}

pub(crate) fn clean_log_file() -> Result<()> {
    let log = app_log()?;

    let contents = log.read()?;

    let cutoff = chrono::Local::now().naive_local() - chrono::Duration::days(3);

    let keep_from = contents.lines().position(|line| {
        line.get(..26)
            .and_then(|timestamp| {
                chrono::NaiveDateTime::parse_from_str(timestamp, "%Y-%m-%d %H:%M:%S%.f").ok()
            })
            .is_some_and(|timestamp| timestamp > cutoff)
    });

    let mut replacement = match keep_from {
        Some(0) => Cow::Borrowed(contents.as_str()),
        Some(index) => {
            let mut retained = contents.lines().skip(index).collect::<Vec<_>>().join("\n");

            if !retained.is_empty() {
                retained.push('\n');
            }

            Cow::Owned(retained)
        }
        None => Cow::Owned(String::new()),
    };

    if replacement.len() > LOG_SIZE_CLEANUP_THRESHOLD_BYTES {
        replacement = Cow::Owned(retain_latest_log_bytes(
            replacement.as_ref(),
            LOG_SIZE_CLEANUP_TARGET_BYTES,
        ));
    }

    if let Cow::Owned(replacement) = replacement {
        log.replace(&replacement)?;
    }

    Ok(())
}

/// Keeps approximately `target_bytes` from the end while avoiding a partial
/// first log entry. The result can be slightly smaller by up to one log line.

fn retain_latest_log_bytes(contents: &str, target_bytes: usize) -> String {
    if contents.len() <= target_bytes {
        return contents.to_owned();
    }

    let estimated_start = contents.len() - target_bytes;

    let bytes = contents.as_bytes();

    let start = if estimated_start == 0 || bytes[estimated_start - 1] == b'\n' {
        estimated_start
    } else if let Some(offset) = bytes[estimated_start..]
        .iter()
        .position(|byte| *byte == b'\n')
    {
        estimated_start + offset + 1
    } else {
        let mut boundary = estimated_start;

        while boundary < contents.len() && !contents.is_char_boundary(boundary) {
            boundary += 1;
        }

        boundary
    };

    contents[start..].to_owned()
}

pub(crate) fn clear_log_file() -> Result<bool> {
    let log = app_log()?;

    let had_contents = log
        .path
        .metadata()
        .map(|metadata| metadata.len() > 0)
        .unwrap_or(false);

    log.replace("")?;

    Ok(had_contents)
}

#[cfg(test)]

mod tests {

    use super::{
        retain_latest_log_bytes, AppLog, AppLogEventFormatter, PlainFields, ShortEventFormatter,
        DEFAULT_LOG_FILTER, LOG_SIZE_CLEANUP_TARGET_BYTES, LOG_SIZE_CLEANUP_THRESHOLD_BYTES,
        TEST_LOG_FILTER,
    };
    use std::sync::{Arc, Mutex};
    use tracing_subscriber::layer::SubscriberExt;
    use tracing_subscriber::{EnvFilter, Registry};

    #[derive(Clone, Default)]

    struct TestWriter(Arc<Mutex<Vec<u8>>>);

    impl std::io::Write for TestWriter {
        fn write(&mut self, bytes: &[u8]) -> std::io::Result<usize> {
            self.0.lock().unwrap().extend_from_slice(bytes);

            Ok(bytes.len())
        }

        fn flush(&mut self) -> std::io::Result<()> {
            Ok(())
        }
    }

    fn capture_logs(filter: &str, emit: impl FnOnce()) -> (String, String) {
        let app = TestWriter::default();

        let console = TestWriter::default();

        let app_writer = app.clone();

        let console_writer = console.clone();

        let subscriber = Registry::default()
            .with(EnvFilter::new(filter))
            .with(super::ExpectedNoise)
            // Production disables ANSI on both sinks. Left on, field
            // formatting wraps `=` in escape codes and no `key=value` matches.
            .with(
                tracing_subscriber::fmt::layer()
                    .with_writer(move || app_writer.clone())
                    .with_ansi(false)
                    .fmt_fields(PlainFields)
                    .event_format(AppLogEventFormatter),
            )
            .with(
                tracing_subscriber::fmt::layer()
                    .with_writer(move || console_writer.clone())
                    .with_ansi(false)
                    .event_format(ShortEventFormatter::plain()),
            );

        tracing::subscriber::with_default(subscriber, emit);

        let app = String::from_utf8(app.0.lock().unwrap().clone()).unwrap();

        let console = String::from_utf8(console.0.lock().unwrap().clone()).unwrap();

        (app, console)
    }

    fn emit_bridged_log(target: &str, level: tracing::log::Level, message: &str) {
        tracing_log::format_trace(
            &tracing::log::Record::builder()
                .args(format_args!("{message}"))
                .level(level)
                .target(target)
                .file(Some("dependency/src/diagnostics.rs"))
                .line(Some(42))
                .build(),
        )
        .unwrap();
    }

    #[test]

    fn sqlcipher_key_statements_are_redacted_in_both_sinks() {
        let (app, console) = capture_logs(DEFAULT_LOG_FILTER, || {
            for statement in [
                "PRAGMA key = 'test-key-secret';",
                "PRAGMA rekey = \"x'test-rekey-secret'\";",
            ] {
                tracing::warn!(target: "sqlx::query", summary = statement, db.statement = statement,
                    "slow statement: execution time exceeded alert threshold");
            }
            tracing::warn!(target: "sqlx::query", summary = "SELECT COUNT(*) FROM messages", elapsed_ms = 501,
                "slow statement: execution time exceeded alert threshold");
        });
        for log in [app, console] {
            assert!(log.contains("SQLCipher key statement [SQL redacted]"));
            assert!(!log.contains("test-key-secret"));
            assert!(!log.contains("test-rekey-secret"));
            assert!(log.contains("SELECT COUNT(*) FROM messages"));
            assert!(log.contains("elapsed_ms=501"));
        }
    }

    #[test]
    fn bridged_logs_include_the_original_filename_in_both_sinks() {
        let (app, console) = capture_logs(DEFAULT_LOG_FILTER, || {
            emit_bridged_log(
                "dependency",
                tracing::log::Level::Warn,
                "dependency warning",
            );

            tracing::info!("native tracing message");
        });

        for output in [app, console] {
            assert!(output.contains("src/diagnostics.rs:42"), "{output}");

            assert!(output.contains("dependency warning"), "{output}");

            assert!(output.contains("src/log.rs:"), "{output}");

            assert!(output.contains("native tracing message"), "{output}");

            assert!(!output.contains("[twonly] log >"), "{output}");
        }
    }

    #[test]

    fn default_filters_suppress_tract_diagnostics_and_keep_warnings() {
        for filter in [DEFAULT_LOG_FILTER, TEST_LOG_FILTER] {
            let (app, console) = capture_logs(filter, || {
                for target in [
                    "tract_hir::infer::analyser",
                    "tract_core::optim::change_axes",
                ] {
                    emit_bridged_log(target, tracing::log::Level::Debug, "model diagnostics");

                    emit_bridged_log(target, tracing::log::Level::Info, "model progress");

                    emit_bridged_log(target, tracing::log::Level::Warn, "model warning");

                    emit_bridged_log(target, tracing::log::Level::Error, "model error");
                }

                tracing::info!("application message");
            });

            for output in [app, console] {
                assert!(!output.contains("model diagnostics"), "{output}");

                assert!(!output.contains("model progress"), "{output}");

                assert!(output.contains("model warning"), "{output}");

                assert!(output.contains("model error"), "{output}");

                assert!(output.contains("application message"), "{output}");
            }
        }
    }

    #[test]

    fn expected_dependency_noise_is_dropped_and_real_failures_are_kept() {
        let (app, console) = capture_logs(DEFAULT_LOG_FILTER, || {
            emit_bridged_log(
                "flutter_rust_bridge::misc::logs",
                tracing::log::Level::Warn,
                "Fail to post message to Dart. (If happen during Flutter hot restart, this may \
                 not be a problem.)",
            );

            emit_bridged_log(
                "flutter_rust_bridge::misc::logs",
                tracing::log::Level::Warn,
                "Drop DartOpaque after closing the port, thus the object will be leaked forever.",
            );

            emit_bridged_log(
                "flutter_rust_bridge::misc::logs",
                tracing::log::Level::Warn,
                "another bridge warning",
            );

            for (error, keep) in [
                ("Protocol(\"connection was replaced\")", false),
                (
                    "Protocol(\"Protocol error: Server returned error code: 1036\")",
                    false,
                ),
                (
                    "Protocol(\"Protocol error: Server returned error code: 10360\")",
                    true,
                ),
                (
                    "Protocol(\"Protocol error: Server returned error code: 1004\")",
                    true,
                ),
            ] {
                tracing::error!(
                    target: "stream_tungstenite::client",
                    error = %error,
                    keep,
                    "Handshake failed"
                );
            }

            tracing::error!(error = "connection was replaced", "Handshake failed");
        });

        for output in [app, console] {
            assert!(!output.contains("Fail to post message to Dart"), "{output}");

            assert!(!output.contains("Drop DartOpaque"), "{output}");

            assert!(output.contains("another bridge warning"), "{output}");

            assert!(!output.contains("keep=false"), "{output}");

            assert_eq!(output.matches("keep=true").count(), 2, "{output}");

            // Only the connection library's report is noise; twonly's own is not.
            assert_eq!(output.matches("Handshake failed").count(), 3, "{output}");
        }
    }

    #[test]

    fn default_filters_suppress_http_diagnostics_and_keep_warnings() {
        for filter in [DEFAULT_LOG_FILTER, TEST_LOG_FILTER] {
            let (app, console) = capture_logs(filter, || {
                for target in [
                    "hyper::client::connect::http",
                    "hyper_util::client::legacy::pool",
                    "reqwest::connect",
                ] {
                    emit_bridged_log(
                        target,
                        tracing::log::Level::Debug,
                        "HTTP connection activity",
                    );

                    emit_bridged_log(target, tracing::log::Level::Warn, "HTTP warning");

                    emit_bridged_log(target, tracing::log::Level::Error, "HTTP error");
                }

                tracing::debug!("application debug message");

                tracing::warn!(target: "hyper_util::client::legacy::pool", "native HTTP warning");

                tracing::debug!(target: "hyper_util::client::legacy::pool", "native HTTP activity");
            });

            for output in [app, console] {
                assert!(!output.contains("HTTP connection activity"), "{output}");

                assert!(!output.contains("native HTTP activity"), "{output}");

                assert!(output.contains("HTTP warning"), "{output}");

                assert!(output.contains("HTTP error"), "{output}");

                assert!(output.contains("native HTTP warning"), "{output}");

                assert_eq!(
                    output.contains("application debug message"),
                    filter == DEFAULT_LOG_FILTER,
                    "{output}"
                );
            }
        }
    }

    #[test]

    fn default_filters_suppress_credential_diagnostics() {
        for filter in [DEFAULT_LOG_FILTER, TEST_LOG_FILTER] {
            let (app, console) = capture_logs(filter, || {
                for target in [
                    "keyring_core",
                    "apple_native_keyring_store::protected",
                    "android_native_keyring_store",
                ] {
                    emit_bridged_log(
                        target,
                        tracing::log::Level::Debug,
                        "credential entry details",
                    );

                    emit_bridged_log(
                        target,
                        tracing::log::Level::Info,
                        "credential store details",
                    );

                    emit_bridged_log(target, tracing::log::Level::Warn, "keyring warning");

                    emit_bridged_log(target, tracing::log::Level::Error, "keyring error");
                }
            });

            for output in [app, console] {
                assert!(!output.contains("credential entry details"), "{output}");

                assert!(!output.contains("credential store details"), "{output}");

                assert!(output.contains("keyring warning"), "{output}");

                assert!(output.contains("keyring error"), "{output}");
            }
        }
    }

    #[test]

    fn log_markers_follow_nested_execution_in_both_sinks() {
        use crate::database::lifecycle::Operation;
        use crate::log::LogSource;
        use std::time::Duration;

        let notification =
            Operation::with_log_source(Duration::from_secs(10), LogSource::Notification);

        let service =
            Operation::with_log_source(Duration::from_secs(10), LogSource::ForegroundService);

        let background = Operation::new(Duration::from_secs(10));

        let (app, console) = capture_logs(DEFAULT_LOG_FILTER, || {
            notification.scope_sync(|| {
                tracing::info!("notification before service");

                service.scope_sync(|| tracing::info!("foreground service"));

                tracing::info!("notification after service");
            });

            background.scope_sync(|| tracing::info!("background maintenance"));
        });

        for output in [app, console] {
            for (message, marker) in [
                ("notification before service", "[n]"),
                ("foreground service", "[s]"),
                ("notification after service", "[n]"),
                ("background maintenance", "[b]"),
            ] {
                let line = output.lines().find(|line| line.contains(message)).unwrap();

                assert!(line.contains(marker), "{line}");
            }
        }
    }

    #[tokio::test]

    async fn log_sources_survive_async_and_blocking_descendants() {
        use crate::database::lifecycle::{self, Operation};
        use crate::log::LogSource;
        use std::time::Duration;

        for source in [
            LogSource::Notification,
            LogSource::ForegroundService,
            LogSource::Background,
        ] {
            let operation = Operation::with_log_source(Duration::from_secs(10), source);

            operation
                .scope(async {
                    assert_eq!(super::current_log_source(), source);

                    lifecycle::spawn(async move {
                        assert_eq!(super::current_log_source(), source);

                        lifecycle::spawn_blocking(move || {
                            assert_eq!(super::current_log_source(), source);
                        })
                        .await
                        .unwrap();
                    })
                    .await
                    .unwrap();

                    assert_eq!(super::current_log_source(), source);
                })
                .await;

            operation.drain().await;
        }

        Operation::foreground()
            .scope(async {
                assert_eq!(super::current_log_source(), LogSource::Foreground);
            })
            .await;
    }

    #[test]

    fn app_log_serializes_reads_and_truncation() {
        let temp = tempfile::tempdir().unwrap();

        let path = temp.path().join("app.log");

        let log = AppLog::open(path.clone()).unwrap();

        log.append(b"first\n").unwrap();

        log.append(b"second\n").unwrap();

        assert_eq!(log.read().unwrap(), "first\nsecond\n");

        log.replace("retained\n").unwrap();

        log.append(b"new\n").unwrap();

        assert_eq!(std::fs::read_to_string(path).unwrap(), "retained\nnew\n");
    }

    #[test]

    fn app_log_reads_invalid_utf8_without_changing_the_file() {
        let temp = tempfile::tempdir().unwrap();

        let path = temp.path().join("app.log");

        let bytes = b"first\ninvalid: \xff\xfe\nlast\n";

        std::fs::write(&path, bytes).unwrap();

        let log = AppLog::open(path.clone()).unwrap();

        // Reproduce the error previously returned through the Flutter bridge.
        assert_eq!(
            std::fs::read_to_string(&path).unwrap_err().kind(),
            std::io::ErrorKind::InvalidData
        );

        assert_eq!(
            log.read().unwrap(),
            "first\ninvalid: \u{fffd}\u{fffd}\nlast\n"
        );

        assert_eq!(std::fs::read(path).unwrap(), bytes);
    }

    #[test]

    fn app_log_reads_an_incomplete_utf8_character_at_the_end() {
        let temp = tempfile::tempdir().unwrap();

        let log = AppLog::open(temp.path().join("app.log")).unwrap();

        log.append(b"complete line\ninterrupted: \xf0\x9f\x98")
            .unwrap();

        assert_eq!(log.read().unwrap(), "complete line\ninterrupted: \u{fffd}");
    }

    #[test]

    fn app_log_preserves_valid_unicode() {
        let temp = tempfile::tempdir().unwrap();

        let log = AppLog::open(temp.path().join("app.log")).unwrap();

        let contents = "Grüße 👋\n日本語\n";

        log.append(contents.as_bytes()).unwrap();

        assert_eq!(log.read().unwrap(), contents);
    }

    #[test]

    fn app_log_read_still_reports_file_errors() {
        let temp = tempfile::tempdir().unwrap();

        let path = temp.path().join("app.log");

        let log = AppLog::open(path.clone()).unwrap();

        std::fs::remove_file(path).unwrap();

        assert_eq!(log.read().unwrap_err().kind(), std::io::ErrorKind::NotFound);
    }

    #[test]

    fn size_cleanup_keeps_the_latest_complete_log_lines() {
        let contents = "oldest\nmiddle\nnewest\n";

        assert_eq!(retain_latest_log_bytes(contents, 14), "middle\nnewest\n");

        assert_eq!(retain_latest_log_bytes(contents, 12), "newest\n");
    }

    #[test]

    fn size_cleanup_reduces_a_five_mib_log_to_about_four_mib() {
        let line = format!("{}\n", "x".repeat(127));

        let contents = line.repeat(LOG_SIZE_CLEANUP_THRESHOLD_BYTES / line.len() + 1);

        assert!(contents.len() > LOG_SIZE_CLEANUP_THRESHOLD_BYTES);

        let retained = retain_latest_log_bytes(&contents, LOG_SIZE_CLEANUP_TARGET_BYTES);

        assert!(retained.len() <= LOG_SIZE_CLEANUP_TARGET_BYTES);

        assert!(retained.len() > LOG_SIZE_CLEANUP_TARGET_BYTES - line.len());

        assert!(retained.ends_with('\n'));
    }
}
