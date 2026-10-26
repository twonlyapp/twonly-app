use super::transaction::CommandTransaction;
use super::{DatabaseSession, DatabaseWatch};
use crate::bridge::get_twonly_flutter;
pub use crate::database::app::webxdc::table::{WebxdcCardApp, WebxdcCardInstance};
use crate::database::app::webxdc::{queries, watches};
use crate::error::Result;
use crate::frb_generated::StreamSink;

pub async fn webxdc_card_app(
    id: String, version: i64, transaction: &DatabaseSession,
) -> Result<Option<WebxdcCardApp>> {
    let mut tx = CommandTransaction::read(transaction).await?;

    let result = queries::app(&mut **tx.transaction(), &id, version).await;

    tx.finish(result).await
}

pub async fn webxdc_card_instance(
    id: String, transaction: &DatabaseSession,
) -> Result<Option<WebxdcCardInstance>> {
    let mut tx = CommandTransaction::read(transaction).await?;

    let result = queries::instance(&mut **tx.transaction(), &id).await;

    tx.finish(result).await
}

pub async fn watch_webxdc_card(
    id: String, control: &DatabaseWatch, sink: StreamSink<Option<WebxdcCardInstance>>,
) -> Result<()> {
    control
        .traced(watches::instance(
            get_twonly_flutter()?.app_db.clone(),
            id,
            control.cancellation.clone(),
            move |value| sink.add(value).is_ok(),
        ))
        .await
}

pub async fn watch_webxdc_serial(
    id: String, control: &DatabaseWatch, sink: StreamSink<i64>,
) -> Result<()> {
    control
        .traced(watches::serial(
            get_twonly_flutter()?.app_db.clone(),
            id,
            control.cancellation.clone(),
            move |value| sink.add(value).is_ok(),
        ))
        .await
}
