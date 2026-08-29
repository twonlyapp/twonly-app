/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::frb_generated::StreamSink;
use std::sync::RwLock;
use tracing_subscriber::fmt::MakeWriter;

/// The sink is bound to the native port of the Dart isolate that handed it to
/// us. That isolate can go away while the process (and therefore the tracing
/// subscriber) lives on -- a hot restart, an engine restart, or a background
/// isolate that finished its task. Keeping the sink behind a lock lets a newly
/// initialized isolate take over the log stream instead of writing into a dead
/// port forever.
static DART_SINK: RwLock<Option<StreamSink<String>>> = RwLock::new(None);

pub(crate) fn set_dart_sink(sink: StreamSink<String>) {
    if let Ok(mut guard) = DART_SINK.write() {
        *guard = Some(sink);
    }
}

pub fn strip_ansi(input: &str) -> String {
    let mut out = String::with_capacity(input.len());
    let mut chars = input.chars().peekable();

    while let Some(c) = chars.next() {
        if c == '\x1b' {
            if let Some(&next) = chars.peek() {
                if next == '[' {
                    // CSI sequence: ESC [ ... [final byte 0x40..=0x7e]
                    chars.next(); // consume '['
                    while let Some(&ch) = chars.peek() {
                        chars.next();
                        if ('@'..='~').contains(&ch) {
                            break;
                        }
                    }
                    continue;
                } else if next == ']' {
                    // OSC sequence: ESC ] ... (BEL \x07 or ESC \)
                    chars.next(); // consume ']'
                    while let Some(ch) = chars.next() {
                        if ch == '\x07' {
                            break;
                        }
                        if ch == '\x1b' && chars.peek() == Some(&'\\') {
                            chars.next();
                            break;
                        }
                    }
                    continue;
                } else if ('@'..='_').contains(&next) {
                    // 2-character escape sequence
                    chars.next();
                    continue;
                }
            }
        } else if c == '\\' && chars.peek() == Some(&'^') {
            let mut clone = chars.clone();
            clone.next(); // '^'
            if clone.next() == Some('[') {
                if clone.peek() == Some(&'[') {
                    clone.next();
                }
                let mut valid = false;
                while let Some(ch) = clone.next() {
                    if ('@'..='~').contains(&ch) {
                        valid = true;
                        break;
                    } else if !('0'..='?').contains(&ch) && !(' '..='/').contains(&ch) {
                        break;
                    }
                }
                if valid {
                    chars.next(); // consume '^'
                    chars.next(); // consume '['
                    if chars.peek() == Some(&'[') {
                        chars.next();
                    }
                    while let Some(&ch) = chars.peek() {
                        chars.next();
                        if ('@'..='~').contains(&ch) {
                            break;
                        }
                    }
                    continue;
                }
            }
        } else if c == '^' && chars.peek() == Some(&'[') {
            let mut clone = chars.clone();
            clone.next(); // '['
            if clone.peek() == Some(&'[') {
                clone.next();
            }
            let mut valid = false;
            while let Some(ch) = clone.next() {
                if ('@'..='~').contains(&ch) {
                    valid = true;
                    break;
                } else if !('0'..='?').contains(&ch) && !(' '..='/').contains(&ch) {
                    break;
                }
            }
            if valid {
                chars.next(); // consume '['
                if chars.peek() == Some(&'[') {
                    chars.next();
                }
                while let Some(&ch) = chars.peek() {
                    chars.next();
                    if ('@'..='~').contains(&ch) {
                        break;
                    }
                }
                continue;
            }
        }
        out.push(c);
    }
    out
}

#[derive(Clone, Copy)]
pub(crate) struct DartWriter;

impl std::io::Write for DartWriter {
    fn write(&mut self, buf: &[u8]) -> std::io::Result<usize> {
        if let Ok(msg) = std::str::from_utf8(buf) {
            let clean = strip_ansi(msg.trim_end());
            let failed = match DART_SINK.read() {
                Ok(guard) => match guard.as_ref() {
                    Some(sink) => sink.add(clean).is_err(),
                    None => false,
                },
                Err(_) => false,
            };
            // The isolate behind the sink is gone. Drop it so we stop paying
            // for a send on every log line until a new isolate registers.
            if failed {
                if let Ok(mut guard) = DART_SINK.write() {
                    *guard = None;
                }
            }
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
        *self
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_strip_ansi_raw() {
        let input =
            "\x1b[3mreceipt_id\x1b[0m\x1b[2m=\x1b[0m\"d9891084-0f7c-4f30-958d-d8619df5a91c\"";
        assert_eq!(
            strip_ansi(input),
            "receipt_id=\"d9891084-0f7c-4f30-958d-d8619df5a91c\""
        );
    }

    #[test]
    fn test_strip_ansi_escaped_caret() {
        let input = r#"\^[[3mreceipt_id\^[[0m\^[[2m=\^[[0m"d9891084-0f7c-4f30-958d-d8619df5a91c" \^[[3muser\^[[0m\^[[2m=\^[[0m2214489137315557376 \^[[3mkind\^[[0m\^[[2m=\^[[0m"FlameSync" Handling incoming message: FlameSync"#;
        assert_eq!(
            strip_ansi(input),
            r#"receipt_id="d9891084-0f7c-4f30-958d-d8619df5a91c" user=2214489137315557376 kind="FlameSync" Handling incoming message: FlameSync"#
        );
    }

    #[test]
    fn test_strip_ansi_caret() {
        let input = "^[[3mreceipt_id^[[0m^[[2m=^[[0m\"test\"";
        assert_eq!(strip_ansi(input), "receipt_id=\"test\"");
    }

    #[test]
    fn test_strip_ansi_plain_text() {
        assert_eq!(strip_ansi("hello world 123"), "hello world 123");
    }
}
