use crate::context::Context;
use crate::error::Result;
use crate::services::live_location;
use serde::Serialize;

#[derive(Clone, Debug, Serialize)]
pub struct LiveLocationSession {
    pub session_id: String,
    pub expires_at_ms: i64,
    pub group_ids: Vec<String>,
}

pub async fn start_live_location(
    group_ids: Vec<String>,
    duration_seconds: i64,
    text: String,
) -> Result<LiveLocationSession> {
    let ctx = Context::get_static()?;
    live_location::state(ctx).await?;
    live_location::start(ctx, group_ids, duration_seconds, text).await
}

pub async fn live_location_state() -> Result<Option<LiveLocationSession>> {
    live_location::state(Context::get_static()?).await
}

pub async fn stop_live_location(session_id: String) -> Result<()> {
    live_location::stop(Context::get_static()?, &session_id).await
}

pub async fn stop_live_location_in_chat(session_id: String, group_id: String) -> Result<()> {
    live_location::stop_chat(Context::get_static()?, &session_id, &group_id).await
}
