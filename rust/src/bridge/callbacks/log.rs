use crate::frb_generated::StreamSink;
use tracing_subscriber::fmt::MakeWriter;

#[derive(Clone)]
pub(crate) struct DartWriter {
    pub(crate) sink: StreamSink<String>,
}

impl std::io::Write for DartWriter {
    fn write(&mut self, buf: &[u8]) -> std::io::Result<usize> {
        if let Ok(msg) = std::str::from_utf8(buf) {
            let _ = self.sink.add(msg.trim_end().to_string());
        }
        Ok(buf.len())
    }

    fn flush(&mut self) -> std::io::Result<()> {
        Ok(())
    }
}

impl<'a> MakeWriter<'a> for DartWriter {
    type Writer = DartWriter;

    fn make_writer(&'a self) -> Self::Writer {
        self.clone()
    }
}
