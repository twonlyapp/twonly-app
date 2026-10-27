/// Month labels are formatted by Flutter in the reader's locale/time zone.
#[derive(Debug, Clone)]

pub struct MockGalleryItem {
    pub created_at: i64,
    pub month: String,
}
