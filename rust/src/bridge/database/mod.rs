pub mod contact_groups;
pub mod contacts;
pub mod diagnostics;
pub mod groups;
pub mod key_verifications;
pub mod mediafiles;
pub mod messages;
pub mod reactions;
pub mod receipts;
pub mod recovery;
pub mod stickers;
pub mod stories;
pub(crate) mod transaction;
pub mod transactions;
pub mod user_discovery;
pub mod webxdc;

use flutter_rust_bridge::frb;
use tokio_util::sync::CancellationToken;

/// Explicit cancellation releases quiet database watches when Flutter leaves
/// a screen; no further write is needed to discover a disposed stream.
#[frb(opaque)]

pub struct DatabaseWatch {
    pub(super) cancellation: CancellationToken,
    trace_context: std::sync::Mutex<Option<String>>,
}

impl DatabaseWatch {
    #[frb(sync)]

    pub fn new() -> Self {
        Self {
            cancellation: CancellationToken::new(),
            trace_context: std::sync::Mutex::new(None),
        }
    }

    #[frb(sync)]
    pub fn set_trace_context(&self, context: String) {
        if crate::performance::enabled()
            && context.len() <= 128
            && context
                .bytes()
                .all(|byte| byte.is_ascii_hexdigit() || byte == b'-')
        {
            if let Ok(mut parent) = self.trace_context.lock() {
                *parent = Some(context);
            }
        }
    }

    pub(super) async fn traced<T>(&self, future: impl std::future::Future<Output = T>) -> T {
        let parent = self
            .trace_context
            .lock()
            .ok()
            .and_then(|mut context| context.take());
        crate::performance::with_parent(parent, future).await
    }

    #[frb(sync)]

    pub fn cancel(&self) {
        self.cancellation.cancel();
    }
}

/// Explicit caller context for typed commands.
/// A default session uses an independent transaction; a transaction session
/// joins the Rust handle owned by the caller, never an unrelated background
/// job.
#[frb(opaque)]

pub struct DatabaseSession {
    pub(crate) transaction:
        Option<std::sync::Arc<crate::database::app::transaction::TransactionScope>>,
}

impl DatabaseSession {
    #[frb(sync)]

    pub fn new() -> Self {
        Self { transaction: None }
    }
}

/// Refresh process-local watches after an external background commit/resume.
pub async fn refresh_database_watches() -> crate::error::Result<()> {
    let database = crate::bridge::get_twonly_flutter()?
        .app_db
        .read()
        .await
        .clone();

    database.refresh_watches();

    Ok(())
}
