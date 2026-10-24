/// Keep this token grammar in sync with lib/src/utils/mentions.dart.
/// An extra leading @ escapes a literal token, so @@[user:42] never pings 42.
pub fn mentions_user(text: &str, user_id: i64) -> bool {
    let bytes = text.as_bytes();
    let mut offset = 0;
    while offset < bytes.len() {
        if bytes[offset] != b'@' {
            offset += 1;
            continue;
        }
        let start = offset;
        while offset < bytes.len() && bytes[offset] == b'@' {
            offset += 1;
        }
        let single_at = offset == start + 1;
        if !bytes[offset..].starts_with(b"[user:") {
            continue;
        }
        let id_start = offset + 6;
        let mut end = id_start;
        while end < bytes.len() && bytes[end].is_ascii_digit() {
            end += 1;
        }
        if end > id_start
            && end - id_start <= 19
            && bytes[id_start] != b'0'
            && bytes.get(end) == Some(&b']')
        {
            if single_at && text[id_start..end].parse::<i64>().ok() == Some(user_id) {
                return true;
            }
            offset = end + 1;
        }
    }
    false
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn recognizes_only_canonical_unescaped_ids() {
        for text in ["@[user:42]", "Hi @[user:7] and @[user:42]!", "👋@[user:42]"] {
            assert!(mentions_user(text, 42), "{text}");
        }
        for text in [
            "@Alice",
            "@[user:420]",
            "@[user:042]",
            "@[user:-42]",
            "@[user:0]",
            "@[user:42",
            "@@[user:42]",
            "@@@[user:42]",
            "@[user:9223372036854775808]",
        ] {
            assert!(!mentions_user(text, 42), "{text}");
        }
        assert!(mentions_user("@@[user:42] @[user:42]", 42));
        assert!(mentions_user("@[user:9223372036854775807]", i64::MAX));
    }
}
