use super::transaction::CommandTransaction;
use super::{DatabaseSession, DatabaseWatch};
use crate::bridge::get_twonly_flutter;
pub use crate::database::app::user_discovery::table::{
    DiscoverySuggestions, UserDiscoveryAnnouncedUser, UserDiscoveryAnnouncedUserPatch,
    UserDiscoveryOtherPromotion, UserDiscoveryOwnPromotion, UserDiscoveryShare,
    UserDiscoveryUserRelation,
};
use crate::database::app::user_discovery::{queries, watches, writes};
use crate::error::Result;
use crate::frb_generated::StreamSink;

pub async fn missing_discovery_data(
    transaction: &DatabaseSession,
) -> Result<Vec<UserDiscoveryAnnouncedUser>> {
    let mut tx = CommandTransaction::read(transaction).await?;

    let result = queries::missing_data(&mut **tx.transaction()).await;

    tx.finish(result).await
}

pub async fn get_discovery_announcement(
    id: i64, transaction: &DatabaseSession,
) -> Result<Option<UserDiscoveryAnnouncedUser>> {
    let mut tx = CommandTransaction::read(transaction).await?;

    let result = queries::get(&mut **tx.transaction(), id).await;

    tx.finish(result).await
}

pub async fn update_discovery_announcement(
    id: i64, patch: UserDiscoveryAnnouncedUserPatch, transaction: &DatabaseSession,
) -> Result<()> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::update(tx.transaction(), id, patch).await;

    tx.finish(result).await
}

pub async fn mark_discovery_announcements_shown(transaction: &DatabaseSession) -> Result<()> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::mark_shown(tx.transaction()).await;

    tx.finish(result).await
}

pub async fn watch_discovery_suggestions(
    only_new: bool, threshold: i64, control: &DatabaseWatch, sink: StreamSink<DiscoverySuggestions>,
) -> Result<()> {
    watches::suggestions(
        get_twonly_flutter()?.app_db.clone(),
        only_new,
        threshold,
        control.cancellation.clone(),
        move |value| sink.add(value).is_ok(),
    )
    .await
}

pub async fn watch_discovery_count(
    threshold: i64, control: &DatabaseWatch, sink: StreamSink<i64>,
) -> Result<()> {
    watches::count(
        get_twonly_flutter()?.app_db.clone(),
        threshold,
        control.cancellation.clone(),
        move |value| sink.add(value).is_ok(),
    )
    .await
}

pub async fn watch_discovery_announcement(
    id: i64, control: &DatabaseWatch, sink: StreamSink<Option<UserDiscoveryAnnouncedUser>>,
) -> Result<()> {
    watches::announcement(
        get_twonly_flutter()?.app_db.clone(),
        id,
        control.cancellation.clone(),
        move |value| sink.add(value).is_ok(),
    )
    .await
}

pub async fn watch_discovery_announcements(
    control: &DatabaseWatch, sink: StreamSink<Vec<UserDiscoveryAnnouncedUser>>,
) -> Result<()> {
    watches::announcements(
        get_twonly_flutter()?.app_db.clone(),
        control.cancellation.clone(),
        move |value| sink.add(value).is_ok(),
    )
    .await
}

pub async fn watch_discovery_relations(
    control: &DatabaseWatch, sink: StreamSink<Vec<UserDiscoveryUserRelation>>,
) -> Result<()> {
    watches::relations(
        get_twonly_flutter()?.app_db.clone(),
        control.cancellation.clone(),
        move |value| sink.add(value).is_ok(),
    )
    .await
}

pub async fn watch_discovery_own_promotions(
    control: &DatabaseWatch, sink: StreamSink<Vec<UserDiscoveryOwnPromotion>>,
) -> Result<()> {
    watches::own_promotions(
        get_twonly_flutter()?.app_db.clone(),
        control.cancellation.clone(),
        move |value| sink.add(value).is_ok(),
    )
    .await
}

pub async fn watch_discovery_other_promotions(
    control: &DatabaseWatch, sink: StreamSink<Vec<UserDiscoveryOtherPromotion>>,
) -> Result<()> {
    watches::other_promotions(
        get_twonly_flutter()?.app_db.clone(),
        control.cancellation.clone(),
        move |value| sink.add(value).is_ok(),
    )
    .await
}

pub async fn watch_discovery_shares(
    control: &DatabaseWatch, sink: StreamSink<Vec<UserDiscoveryShare>>,
) -> Result<()> {
    watches::shares(
        get_twonly_flutter()?.app_db.clone(),
        control.cancellation.clone(),
        move |value| sink.add(value).is_ok(),
    )
    .await
}
