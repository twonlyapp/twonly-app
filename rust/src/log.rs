/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::bridge::logging::LogLevel;
use crate::error::{Result, TwonlyError};
use std::fmt;
use std::fs::{File, OpenOptions};
use std::io::{Seek, Write as IoWrite};
use std::path::{Path, PathBuf};
use std::sync::{
    atomic::{AtomicBool, Ordering},
    Mutex, OnceLock,
};
use tracing::{Event, Subscriber};
use tracing_subscriber::{
    fmt::{
        format::Writer, FmtContext, FormatEvent, FormatFields, FormattedFields, Layer, MakeWriter,
    },
    layer::SubscriberExt,
    registry::LookupSpan,
    util::SubscriberInitExt,
    EnvFilter, Registry,
};

static TRACING_INIT: OnceLock<()> = OnceLock::new();
static APP_LOG: OnceLock<AppLog> = OnceLock::new();
static RUST_LOG_IN_BACKGROUND: AtomicBool = AtomicBool::new(false);

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
        std::fs::read_to_string(&self.path)
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

#[derive(Clone, Copy, Debug, Default)]
pub struct PlainFields;

impl<'writer> FormatFields<'writer> for PlainFields {
    fn format_fields<R: tracing_subscriber::field::RecordFields>(
        &self,
        writer: Writer<'writer>,
        fields: R,
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
        &self,
        ctx: &FmtContext<'_, S, N>,
        mut writer: Writer<'_>,
        event: &Event<'_>,
    ) -> fmt::Result {
        let metadata = event.metadata();

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
                "{level_color}{:<5}\x1b[0m [twonly] ",
                metadata.level()
            )?;
        } else {
            write!(writer, "{time} {:<5} [twonly] ", metadata.level())?;
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

        ctx.field_format().format_fields(writer.by_ref(), event)?;
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
        &self,
        ctx: &FmtContext<'_, S, N>,
        mut writer: Writer<'_>,
        event: &Event<'_>,
    ) -> fmt::Result {
        let metadata = event.metadata();
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
        let task = if RUST_LOG_IN_BACKGROUND.load(Ordering::Relaxed) {
            'b'
        } else {
            'f'
        };

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

        ctx.field_format().format_fields(writer.by_ref(), event)?;
        writeln!(writer)
    }
}

pub(crate) fn init_tracing(data_dir: &Path, in_background: bool) {
    RUST_LOG_IN_BACKGROUND.store(in_background, Ordering::Relaxed);

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
            "info,refinery_core=warn,refinery=warn"
        } else {
            "debug,refinery_core=warn,refinery=warn"
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
            .with(console_layer)
            .with(file_layer)
            .try_init();
    });
}

fn app_log() -> Result<&'static AppLog> {
    APP_LOG.get().ok_or(TwonlyError::Initialization)
}

pub(crate) fn write_dart_log(
    level: LogLevel,
    source: &str,
    message: &str,
    in_background: bool,
) -> Result<()> {
    let log = app_log()?;
    let level = match level {
        LogLevel::Finest => "FINEST",
        LogLevel::Fine => "FINE",
        LogLevel::Info => "INFO",
        LogLevel::Warning => "WARNING",
        LogLevel::Shout => "SHOUT",
    };
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

    let replacement = match keep_from {
        Some(0) => return Ok(()),
        Some(index) => {
            let mut retained = contents.lines().skip(index).collect::<Vec<_>>().join("\n");
            if !retained.is_empty() {
                retained.push('\n');
            }
            retained
        }
        None => String::new(),
    };
    log.replace(&replacement)?;
    Ok(())
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
    use super::AppLog;

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
}
