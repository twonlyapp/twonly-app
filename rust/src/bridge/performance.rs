//! The existing persisted user preference remains the only opt-in.
use flutter_rust_bridge::frb;

#[frb(sync)]
pub fn set_enabled(enabled: bool) {
    crate::performance::set_enabled(enabled);
}

/// Continue a Dart avatar operation without changing existing untraced callers.
pub async fn resolve_avatar(
    contact_id: i64, trace_context: Option<String>,
) -> crate::error::Result<Option<String>> {
    crate::performance::with_parent(
        trace_context,
        crate::bridge::api::RustApi::ensure_avatar_png(contact_id),
    )
    .await
}

#[frb(sync)]
pub fn is_enabled() -> bool {
    crate::performance::enabled()
}
