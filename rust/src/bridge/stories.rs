/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! What the Flutter layer may ask of stories. Story rows themselves are read
//! straight from the database; sending goes through `send_media_to_groups`.

use crate::context::Context;
use crate::error::Result;
use crate::services::direct_media_upload::MAX_ATTACHMENT_DISPATCHES;
use crate::services::stories;
pub use crate::services::stories::StoryAudience;
use flutter_rust_bridge::frb;

#[frb(mirror(StoryAudience))]
pub struct _StoryAudience {
    pub all: bool,
    pub contact_group_ids: Vec<i64>,
}

/// The 1:1 chats a story sent to `audience` would go to right now, one per
/// contact. Together with the chats picked for a direct send, this is who a
/// send reaches.
pub async fn story_audience_chats(audience: StoryAudience) -> Result<Vec<String>> {
    let ctx = Context::get_static()?;
    stories::audience_chats(ctx, &audience).await
}

/// The most recipients one media send, story rows included, may reach.
#[frb(sync)]
pub fn max_media_recipients() -> u32 {
    MAX_ATTACHMENT_DISPATCHES as u32
}

/// Takes one of the user's own story items down for every recipient.
pub async fn delete_story_item(media_id: String) -> Result<()> {
    let ctx = Context::get_static()?;
    stories::delete_item(ctx, &media_id).await
}

/// Lets go of every story item older than 24 hours.
pub async fn purge_expired_stories() -> Result<()> {
    let ctx = Context::get_static()?;
    stories::purge_expired(ctx).await
}
