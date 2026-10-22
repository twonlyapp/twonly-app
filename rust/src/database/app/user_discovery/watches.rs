use super::queries;
use super::table::*;
use crate::database::app::{watch, AppDatabase};
use crate::error::Result;
use std::sync::Arc;
use tokio::sync::RwLock;
use tokio_util::sync::CancellationToken;

pub async fn suggestions(
    databases: Arc<RwLock<Arc<AppDatabase>>>, only_new: bool, threshold: i64,
    cancellation: CancellationToken, emit: impl Fn(DiscoverySuggestions) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &[
            "contacts",
            "user_discovery_announced_users",
            "user_discovery_user_relations",
        ],
        cancellation,
        move |database| async move {
            let mut tx = database.read_pool.begin().await?;

            let result = queries::suggestions(&mut tx, only_new, threshold).await?;

            tx.commit().await?;

            Ok(result)
        },
        emit,
    )
    .await
}

pub async fn count(
    databases: Arc<RwLock<Arc<AppDatabase>>>, threshold: i64, cancellation: CancellationToken,
    emit: impl Fn(i64) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &[
            "contacts",
            "user_discovery_announced_users",
            "user_discovery_user_relations",
        ],
        cancellation,
        move |database| async move {
            queries::count_suggestions(&mut *database.read_pool.acquire().await?, threshold).await
        },
        emit,
    )
    .await
}

pub async fn announcement(
    databases: Arc<RwLock<Arc<AppDatabase>>>, id: i64, cancellation: CancellationToken,
    emit: impl Fn(Option<UserDiscoveryAnnouncedUser>) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["user_discovery_announced_users"],
        cancellation,
        move |database| async move {

            queries::get(&mut *database.read_pool.acquire().await?, id).await
        },
        emit,
    )
    .await
}

macro_rules! table_watch {
    ($name:ident, $row:ty, $table:literal) => {
        pub async fn $name(
            databases: Arc<RwLock<Arc<AppDatabase>>>, cancellation: CancellationToken,
            emit: impl Fn(Vec<$row>) -> bool,
        ) -> Result<()> {
            watch::snapshots(
                databases,
                &[$table],
                cancellation,
                |database| async move {
                    queries::$name(&mut *database.read_pool.acquire().await?).await
                },
                emit,
            )
            .await
        }
    };
}

table_watch!(
    announcements,
    UserDiscoveryAnnouncedUser,
    "user_discovery_announced_users"
);

table_watch!(
    relations,
    UserDiscoveryUserRelation,
    "user_discovery_user_relations"
);

table_watch!(
    own_promotions,
    UserDiscoveryOwnPromotion,
    "user_discovery_own_promotions"
);

table_watch!(
    other_promotions,
    UserDiscoveryOtherPromotion,
    "user_discovery_other_promotions"
);

table_watch!(shares, UserDiscoveryShare, "user_discovery_shares");
