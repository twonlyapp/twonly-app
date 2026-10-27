#[derive(Debug, Clone, PartialEq, Eq, sqlx::FromRow)]

pub struct StickerMetadata {
    pub content_hash: String,
    pub width: i64,
    pub height: i64,
    pub usage_count: i64,
    pub created_at: i64,
    pub last_used_at: i64,
}

#[derive(Debug, Clone, PartialEq, Eq, sqlx::FromRow)]

pub struct LocalSticker {
    #[sqlx(flatten)]
    pub metadata: StickerMetadata,
    pub webp: Vec<u8>,
}

#[derive(Debug, Clone, PartialEq, Eq)]

pub struct StickerAsset {
    pub content_hash: String,
    pub webp: Vec<u8>,
}

/// Complete ordered metadata, with bytes only for newly encountered hashes.
#[derive(Debug, Clone)]

pub struct StickerCollection {
    pub items: Vec<StickerMetadata>,
    pub assets: Vec<StickerAsset>,
}

// Assets are immutable and addressed by a verified SHA-256 digest. Only the
// metadata determines whether a new collection snapshot must cross the bridge.
impl PartialEq for StickerCollection {
    fn eq(&self, other: &Self) -> bool {
        self.items == other.items
    }
}
