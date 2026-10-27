/// Only fields consumed by a chat card. Store descriptions, policy flags and
/// bundle sizes stay inside Rust.
#[derive(Debug, Clone, PartialEq, Eq, sqlx::FromRow)]

pub struct WebxdcCardApp {
    pub app_id: String,
    pub version: i64,
    pub name: String,
    pub name_translations: String,
    pub icon: Option<Vec<u8>>,
}

#[derive(Debug, Clone, PartialEq, Eq, sqlx::FromRow)]

pub struct WebxdcCardInstance {
    pub instance_id: String,
    pub group_id: String,
    pub app_id: String,
    pub version: i64,
    pub bundle_sha256: Option<String>,
    pub origin_token: String,
    pub summary: Option<String>,
    pub document: Option<String>,
}
