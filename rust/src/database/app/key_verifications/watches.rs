use super::queries;
use super::table::*;
use crate::database::app::{watch, AppDatabase};
use crate::error::Result;
use std::sync::Arc;
use tokio::sync::RwLock;
use tokio_util::sync::CancellationToken;

pub async fn contact(
    databases: Arc<RwLock<Arc<AppDatabase>>>, id: i64, cancellation: CancellationToken,
    emit: impl Fn(ContactVerifications) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["contacts", "key_verifications"],
        cancellation,
        move |database| async move {
            let mut tx = database.read_pool.begin().await?;

            let result = queries::contact(&mut tx, id).await?;

            tx.commit().await?;

            Ok(result)
        },
        emit,
    )
    .await
}

pub async fn transferred(
    databases: Arc<RwLock<Arc<AppDatabase>>>, id: i64, cancellation: CancellationToken,
    emit: impl Fn(TransferredVerifications) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &[
            "contacts",
            "key_verifications",
            "user_discovery_user_relations",
            "user_discovery_announced_users",
        ],
        cancellation,
        move |database| async move {
            let mut tx = database.read_pool.begin().await?;

            let result = queries::transferred(&mut tx, id).await?;

            tx.commit().await?;

            Ok(result)
        },
        emit,
    )
    .await
}

pub async fn groups(
    databases: Arc<RwLock<Arc<AppDatabase>>>, group: Option<String>,
    cancellation: CancellationToken, emit: impl Fn(Vec<GroupVerification>) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &[
            "contacts",
            "group_members",
            "key_verifications",
            "user_discovery_user_relations",
            "user_discovery_announced_users",
        ],
        cancellation,
        move |database| {
            let group = group.clone();

            async move {
                queries::groups(
                    &mut *crate::performance::acquire(&database.read_pool).await?,
                    group.as_deref(),
                )
                .await
            }
        },
        emit,
    )
    .await
}
