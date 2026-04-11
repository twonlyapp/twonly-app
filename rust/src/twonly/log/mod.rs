static TRACING_INIT: OnceLock<()> = OnceLock::new();

pub(crate) fn init_tracing(logs_dir: &std::path::Path) {
    TRACING_INIT.get_or_init(|| {
        let (non_blocking_stdout, non_blocking_file) = build_writers(logs_dir);

        let stdout_layer = Layer::new()
            .with_writer(non_blocking_stdout)
            .with_ansi(true)
            .with_target(true);

        let file_layer = Layer::new()
            .with_writer(non_blocking_file)
            .with_ansi(false)
            .with_target(true);

        Registry::default()
            .with(
                EnvFilter::try_from_default_env()
                    .unwrap_or_else(|_| EnvFilter::new("info,refinery_core=warn,refinery=warn")),
            )
            .with(stdout_layer)
            .with(file_layer)
            .init();
    });
}

fn build_writers(logs_dir: &std::path::Path) -> (NonBlocking, NonBlocking) {
    let file_appender = tracing_appender::rolling::RollingFileAppender::builder()
        .rotation(tracing_appender::rolling::Rotation::DAILY)
        .filename_prefix("whitenoise")
        .filename_suffix("log")
        .build(logs_dir)
        .expect("Failed to create file appender");

    let (non_blocking_file, file_guard) = tracing_appender::non_blocking(file_appender);
    let (non_blocking_stdout, stdout_guard) = tracing_appender::non_blocking(std::io::stdout());

    TRACING_GUARDS
        .set(Mutex::new(Some((file_guard, stdout_guard))))
        .ok();

    (non_blocking_stdout, non_blocking_file)
}
