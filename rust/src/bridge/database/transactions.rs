//! Typed lifetime and savepoint operations; Flutter never sends transaction
//! SQL.

use super::DatabaseSession;
use crate::bridge::get_twonly_flutter;
use crate::database::app::transaction::TransactionScope;
use crate::error::Result;
use flutter_rust_bridge::frb;
use std::sync::Arc;

#[frb(opaque)]

pub struct DatabaseTransaction {
    inner: Arc<TransactionScope>,
}

impl DatabaseTransaction {
    pub async fn begin() -> Result<Self> {
        let context = get_twonly_flutter()?;

        Ok(Self {
            inner: Arc::new(
                context
                    .foreground_database_call(|| async {
                        let database = context.app_db.read().await.clone();

                        TransactionScope::begin(&database.pool).await
                    })
                    .await?,
            ),
        })
    }

    pub async fn begin_nested(&self) -> Result<Self> {
        Ok(Self {
            inner: Arc::new(self.inner.begin_nested().await?),
        })
    }

    #[frb(sync)]

    pub fn session(&self) -> DatabaseSession {
        DatabaseSession {
            transaction: Some(self.inner.clone()),
        }
    }

    pub async fn commit(&self) -> Result<()> {
        self.inner.commit().await?;

        if self.inner.is_root() {
            if let Ok(ctx) = crate::context::Context::get_static() {
                if let Err(error) =
                    crate::services::mediafiles::cleanup_pending_file_removals(&ctx).await
                {
                    tracing::warn!(%error, "pending media file cleanup will be retried");
                }
            }
        }

        Ok(())
    }

    pub async fn rollback(&self) -> Result<()> {
        self.inner.rollback().await
    }
}
