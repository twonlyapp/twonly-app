use super::transaction::CommandTransaction;
use super::{DatabaseSession, DatabaseWatch};
use crate::bridge::get_twonly_flutter;
pub use crate::database::app::reactions::table::{
    GroupReaction, ReactionsWithContacts, StoredReaction,
};
use crate::database::app::reactions::{watches, writes};
use crate::error::Result;
use crate::frb_generated::StreamSink;

pub async fn update_own_reaction(
    message: String, emoji: String, remove: bool, transaction: &DatabaseSession,
) -> Result<()> {
    let mut tx = CommandTransaction::begin(transaction).await?;

    let result = writes::update_own(tx.transaction(), &message, &emoji, remove).await;

    tx.finish(result).await
}

pub async fn watch_reactions(
    messages: Vec<String>, control: &DatabaseWatch, sink: StreamSink<Vec<StoredReaction>>,
) -> Result<()> {
    control
        .traced(watches::messages(
            get_twonly_flutter()?.app_db.clone(),
            messages,
            control.cancellation.clone(),
            move |value| sink.add(value).is_ok(),
        ))
        .await
}

pub async fn watch_last_reaction(
    group: String, control: &DatabaseWatch, sink: StreamSink<Option<StoredReaction>>,
) -> Result<()> {
    control
        .traced(watches::last(
            get_twonly_flutter()?.app_db.clone(),
            group,
            control.cancellation.clone(),
            move |value| sink.add(value).is_ok(),
        ))
        .await
}

pub async fn watch_latest_group_reactions(
    control: &DatabaseWatch, sink: StreamSink<Vec<GroupReaction>>,
) -> Result<()> {
    control
        .traced(watches::latest(
            get_twonly_flutter()?.app_db.clone(),
            control.cancellation.clone(),
            move |value| sink.add(value).is_ok(),
        ))
        .await
}

pub async fn watch_reactions_with_contacts(
    message: String, control: &DatabaseWatch, sink: StreamSink<ReactionsWithContacts>,
) -> Result<()> {
    control
        .traced(watches::contacts(
            get_twonly_flutter()?.app_db.clone(),
            message,
            control.cancellation.clone(),
            move |value| sink.add(value).is_ok(),
        ))
        .await
}
