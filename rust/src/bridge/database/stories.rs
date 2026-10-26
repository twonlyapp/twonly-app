use super::transaction::CommandTransaction;
use super::{DatabaseSession, DatabaseWatch};
use crate::bridge::get_twonly_flutter;
pub use crate::database::app::stories::table::{
    OwnStories, OwnStorySummary, ReceivedStories, StoryViewerLink, StoryViewers,
};
use crate::database::app::stories::{queries, watches};
use crate::error::Result;
use crate::frb_generated::StreamSink;

pub async fn get_received_stories(
    contact: i64, cutoff: i64, transaction: &DatabaseSession,
) -> Result<ReceivedStories> {
    let mut tx = CommandTransaction::read(transaction).await?;

    let result = queries::received(tx.transaction(), cutoff, None, Some(contact)).await;

    tx.finish(result).await
}

pub async fn watch_received_stories(
    cutoff: i64, group: Option<String>, control: &DatabaseWatch, sink: StreamSink<ReceivedStories>,
) -> Result<()> {
    control
        .traced(watches::received(
            get_twonly_flutter()?.app_db.clone(),
            cutoff,
            group,
            control.cancellation.clone(),
            move |value| sink.add(value).is_ok(),
        ))
        .await
}

pub async fn watch_own_stories(
    cutoff: i64, control: &DatabaseWatch, sink: StreamSink<OwnStories>,
) -> Result<()> {
    control
        .traced(watches::own(
            get_twonly_flutter()?.app_db.clone(),
            cutoff,
            control.cancellation.clone(),
            move |value| sink.add(value).is_ok(),
        ))
        .await
}

pub async fn watch_story_viewers(
    media: String, control: &DatabaseWatch, sink: StreamSink<StoryViewers>,
) -> Result<()> {
    control
        .traced(watches::viewers(
            get_twonly_flutter()?.app_db.clone(),
            media,
            control.cancellation.clone(),
            move |value| sink.add(value).is_ok(),
        ))
        .await
}
