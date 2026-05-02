use crate::bridge::callbacks::{get_callbacks, log::DartWriter};
use std::sync::{Mutex, OnceLock};
use tracing_appender::non_blocking::{NonBlocking, WorkerGuard};
use tracing_subscriber::{
    fmt::Layer, layer::SubscriberExt, util::SubscriberInitExt, EnvFilter, Registry,
};

static TRACING_GUARDS: OnceLock<Mutex<Option<(WorkerGuard, WorkerGuard)>>> = OnceLock::new();
static TRACING_INIT: OnceLock<()> = OnceLock::new();

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
            .with_target(true);

        // let file_layer = Layer::new()
        //     .with_writer(non_blocking_file)
        //     .with_ansi(false)
        //     .with_target(true);

        // Replace stdout with our new DartWriter!

        let registry = Registry::default()
            .with(
                EnvFilter::try_from_default_env()
                    .unwrap_or_else(|_| EnvFilter::new("debug,refinery_core=warn,refinery=warn")),
            )
            .with(stdout_layer);

        if let Some(sink) = dart_sink {
            let dart_writer = DartWriter { sink };
            let dart_layer = tracing_subscriber::fmt::Layer::new()
                .with_writer(dart_writer)
                .with_ansi(false)
                .with_target(true);
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
            let (nb, guard) = tracing_appender::non_blocking(std::io::sink());
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
