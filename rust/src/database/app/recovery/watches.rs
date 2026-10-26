use super::queries;
use super::table::RecoveryContacts;
use crate::database::app::contacts::table::Contact;
use crate::database::app::{watch, AppDatabase};
use crate::error::Result;
use std::sync::Arc;
use tokio::sync::RwLock;
use tokio_util::sync::CancellationToken;

const DEPENDENCIES: &[&str] = &[
    "contacts",
    "key_verifications",
    "user_discovery_user_relations",
];

pub async fn contacts(
    databases: Arc<RwLock<Arc<AppDatabase>>>, selection: RecoveryContacts,
    cancellation: CancellationToken, emit: impl Fn(Vec<Contact>) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        DEPENDENCIES,
        cancellation,
        move |database| async move {
            queries::contacts(
                &mut *crate::performance::acquire(&database.read_pool).await?,
                selection,
                None,
            )
            .await
        },
        emit,
    )
    .await
}

pub async fn count(
    databases: Arc<RwLock<Arc<AppDatabase>>>, selection: RecoveryContacts,
    cancellation: CancellationToken, emit: impl Fn(i64) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        DEPENDENCIES,
        cancellation,
        move |database| async move {
            queries::count(
                &mut *crate::performance::acquire(&database.read_pool).await?,
                selection,
            )
            .await
        },
        emit,
    )
    .await
}
