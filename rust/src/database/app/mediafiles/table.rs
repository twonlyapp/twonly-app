use crate::database::app::patch::*;
use flutter_rust_bridge::frb;

#[derive(Debug, Clone, PartialEq, sqlx::FromRow)]
#[frb(name = "MediaFile")]

pub struct MediaFile {
    pub media_id: String,
    #[frb(name = "typeName")]
    pub r#type: String,
    #[frb(name = "uploadStateName")]
    pub upload_state: Option<String>,
    #[frb(name = "cloudStateName")]
    pub cloud_state: String,
    pub blurhash: Option<String>,
    #[frb(name = "downloadStateName")]
    pub download_state: Option<String>,
    pub requires_authentication: bool,
    pub stored: bool,
    pub is_draft_media: bool,
    pub is_widget_media: bool,
    pub is_favorite: bool,
    pub has_crop_analyzed: bool,
    pub pre_progressing_process: Option<i64>,
    #[frb(name = "reuploadRequestedByJson")]
    pub reupload_requested_by: Option<String>,
    pub display_limit_in_milliseconds: Option<i64>,
    pub remove_audio: Option<bool>,
    pub trim_start_ms: Option<i64>,
    pub trim_end_ms: Option<i64>,
    pub download_token: Option<Vec<u8>>,
    pub encryption_key: Option<Vec<u8>>,
    pub encryption_mac: Option<Vec<u8>>,
    pub encryption_nonce: Option<Vec<u8>>,
    pub stored_file_hash: Option<Vec<u8>>,
    pub has_thumbnail: bool,
    pub size_in_bytes: Option<i64>,
    pub location_latitude: Option<f64>,
    pub location_longitude: Option<f64>,
    pub location_accuracy: Option<f64>,
    pub location_status: Option<String>,
    pub location_deadline_at: Option<i64>,
    pub gallery_export_pending: bool,
    #[frb(name = "createdAtSeconds")]
    pub created_at: i64,
    pub created_at_month: Option<String>,
}

#[derive(Debug, Clone, Default)]

pub struct MediaFilePatch {
    pub media_id: Option<String>,
    pub r#type: Option<String>,
    pub upload_state: Option<NullableText>,
    pub cloud_state: Option<String>,
    pub blurhash: Option<NullableText>,
    pub download_state: Option<NullableText>,
    pub requires_authentication: Option<bool>,
    pub stored: Option<bool>,
    pub is_draft_media: Option<bool>,
    pub is_widget_media: Option<bool>,
    pub is_favorite: Option<bool>,
    pub has_crop_analyzed: Option<bool>,
    pub pre_progressing_process: Option<NullableInt>,
    pub reupload_requested_by: Option<NullableText>,
    pub display_limit_in_milliseconds: Option<NullableInt>,
    pub remove_audio: Option<NullableInt>,
    pub trim_start_ms: Option<NullableInt>,
    pub trim_end_ms: Option<NullableInt>,
    pub download_token: Option<NullableBytes>,
    pub encryption_key: Option<NullableBytes>,
    pub encryption_mac: Option<NullableBytes>,
    pub encryption_nonce: Option<NullableBytes>,
    pub stored_file_hash: Option<NullableBytes>,
    pub has_thumbnail: Option<bool>,
    pub size_in_bytes: Option<NullableInt>,
    pub location_latitude: Option<NullableReal>,
    pub location_longitude: Option<NullableReal>,
    pub location_accuracy: Option<NullableReal>,
    pub location_status: Option<NullableText>,
    pub location_deadline_at: Option<NullableInt>,
    pub gallery_export_pending: Option<bool>,
    pub created_at: Option<i64>,
    pub created_at_month: Option<NullableText>,
}

#[derive(Debug, Clone, Copy)]

pub enum MediaFilter {
    All,
    Ids,
    Draft,
    PendingDownload,
    ReuploadRequested,
    PendingMigration,
    PendingUpload,
    Stored,
    Geotagged,
    Group,
    ChatList,
    ByHash,
    MemoriesToBackup,
}

#[derive(Debug, Clone)]
#[frb]

pub struct MediaQuery {
    pub filter: MediaFilter,
    #[frb(default = "const []")]
    pub ids: Vec<String>,
    pub group_id: Option<String>,
    pub hash: Option<Vec<u8>>,
    #[frb(default = false)]
    pub favorites_only: bool,
}

#[derive(Debug, Clone, PartialEq, Eq, sqlx::FromRow)]

pub struct ChatMediaLink {
    pub group_id: String,
    pub media_id: String,
}

#[derive(Debug, Clone, PartialEq)]

pub struct ChatMediaSnapshot {
    pub groups: Vec<crate::database::app::groups::table::Group>,
    pub files: Vec<MediaFile>,
    pub links: Vec<ChatMediaLink>,
}

#[derive(Debug, Clone, PartialEq)]

pub struct MediaCollection {
    pub files: Vec<MediaFile>,
    pub order: Vec<String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]

pub struct MediaStorageStat {
    pub media_type: String,
    pub bytes: i64,
}

#[derive(Debug, Clone)]

pub struct MediaMonthLabel {
    pub created_at: i64,
    pub month: String,
}
