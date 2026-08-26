/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::bridge::callbacks::{get_callbacks, log::DartWriter};
use std::fmt;
use std::path::Path;
use std::sync::{Mutex, OnceLock};
use tracing::{Event, Subscriber};
use tracing_appender::non_blocking::{NonBlocking, WorkerGuard};
use tracing_subscriber::{
    fmt::{format::Writer, FmtContext, FormatEvent, FormatFields, FormattedFields, Layer},
    layer::SubscriberExt,
    registry::LookupSpan,
    util::SubscriberInitExt,
    EnvFilter, Registry,
};

static TRACING_GUARDS: OnceLock<Mutex<Option<(WorkerGuard, WorkerGuard)>>> = OnceLock::new();
static TRACING_INIT: OnceLock<()> = OnceLock::new();

#[derive(Clone, Copy, Debug, Default)]
pub struct ShortEventFormatter {
    ansi: bool,
}

impl ShortEventFormatter {
    pub const fn ansi() -> Self {
        Self { ansi: true }
    }

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
            write!(writer, "{level_color}{:<5}\x1b[0m ", metadata.level())?;
        } else {
            write!(writer, "{time} {:<5} ", metadata.level())?;
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

pub(crate) async fn init_tracing(logs_dir: &std::path::Path, is_dart_available: bool) {
    let _ = std::fs::create_dir_all(logs_dir);

    let mut dart_sink = None;

    if is_dart_available {
        if let Ok(callbacks) = get_callbacks() {
            dart_sink = Some((callbacks.logging.get_stream_sink)().await);
        }
    }

    TRACING_INIT.get_or_init(|| {
        let (non_blocking_stdout, _non_blocking_file) = build_writers(logs_dir);

        let stdout_layer = Layer::new()
            .with_writer(non_blocking_stdout)
            .with_ansi(true)
            .event_format(ShortEventFormatter::ansi());

        // let file_layer = Layer::new()
        //     .with_writer(non_blocking_file)
        //     .with_ansi(false)
        //     .with_target(true);

        // Replace stdout with our new DartWriter!

        let default_filter = if std::env::var("FLUTTER_TEST").is_ok() {
            "info,refinery_core=warn,refinery=warn"
        } else {
            "debug,refinery_core=warn,refinery=warn"
        };

        let registry = Registry::default()
            .with(
                EnvFilter::try_from_default_env()
                    .unwrap_or_else(|_| EnvFilter::new(default_filter)),
            )
            .with(stdout_layer);

        if let Some(sink) = dart_sink {
            let dart_writer = DartWriter { sink };
            let dart_layer = tracing_subscriber::fmt::Layer::new()
                .with_writer(dart_writer)
                .with_ansi(false)
                .event_format(ShortEventFormatter::plain());
            let _ = registry.with(dart_layer).try_init();
        } else {
            let _ = registry.try_init();
        }
    });
}

fn build_writers(logs_dir: &std::path::Path) -> (NonBlocking, NonBlocking) {
    let file_appender_res = tracing_appender::rolling::RollingFileAppender::builder()
        .rotation(tracing_appender::rolling::Rotation::DAILY)
        .filename_prefix("twonly")
        .filename_suffix("log")
        .build(logs_dir);

    let (non_blocking_file, file_guard) = match file_appender_res {
        Ok(file_appender) => {
            let (nb, guard) = tracing_appender::non_blocking(file_appender);
            (nb, Some(guard))
        }
        Err(e) => {
            eprintln!("Failed to create file appender: {}", e);
            let (nb, _guard) = tracing_appender::non_blocking(std::io::sink());
            (nb, None)
        }
    };
    let (non_blocking_stdout, stdout_guard) = tracing_appender::non_blocking(std::io::stdout());

    if let Some(fg) = file_guard {
        TRACING_GUARDS
            .set(Mutex::new(Some((fg, stdout_guard))))
            .ok();
    }

    (non_blocking_stdout, non_blocking_file)
}
