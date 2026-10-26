use super::queries;
use super::table::*;
use crate::database::app::{watch, AppDatabase};
use crate::error::Result;
use std::sync::Arc;
use tokio::sync::RwLock;
use tokio_util::sync::CancellationToken;

pub async fn groups(
    databases: Arc<RwLock<Arc<AppDatabase>>>, filter: ContactGroupFilter, user_id: Option<i64>,
    group_id: Option<String>, cancellation: CancellationToken,
    emit: impl Fn(Vec<ContactGroup>) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["contact_groups", "contact_group_members"],
        cancellation,
        move |database| {
            let group_id = group_id.clone();

            async move {
                queries::list(
                    &mut *crate::performance::acquire(&database.read_pool).await?,
                    filter,
                    user_id,
                    group_id.as_deref(),
                )
                .await
            }
        },
        emit,
    )
    .await
}

pub async fn membership_ids(
    databases: Arc<RwLock<Arc<AppDatabase>>>, user_id: Option<i64>, group_id: Option<String>,
    cancellation: CancellationToken, emit: impl Fn(Vec<i64>) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["contact_group_members"],
        cancellation,
        move |database| {
            let group_id = group_id.clone();

            async move {
                queries::membership_ids(
                    &mut *crate::performance::acquire(&database.read_pool).await?,
                    user_id,
                    group_id.as_deref(),
                )
                .await
            }
        },
        emit,
    )
    .await
}

pub async fn labels(
    databases: Arc<RwLock<Arc<AppDatabase>>>, for_users: bool, cancellation: CancellationToken,
    emit: impl Fn(ContactGroupLabels) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["contact_groups", "contact_group_members"],
        cancellation,
        move |database| async move {
            queries::labels(
                &mut *crate::performance::acquire(&database.read_pool).await?,
                for_users,
            )
            .await
        },
        emit,
    )
    .await
}
