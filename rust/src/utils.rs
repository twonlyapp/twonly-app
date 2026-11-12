/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use chrono::{DateTime, Local, TimeZone};
use std::sync::Arc;
use tokio::sync::{RwLock, RwLockReadGuard};

use crate::error::{Result, TwonlyError};

pub(crate) fn milliseconds_to_seconds(timestamp: i64) -> i64 {
    timestamp.div_euclid(1_000)
}

pub(crate) fn current_time() -> DateTime<Local> {
    Local::now()
}

pub(crate) fn is_today(timestamp: i64) -> bool {
    Local
        .timestamp_opt(timestamp, 0)
        .single()
        .is_some_and(|date| date.date_naive() == current_time().date_naive())
}

/// Midnight of the current day in the user's timezone. Flame counters roll over
/// at the local day boundary, so every comparison against "today" has to start
/// here instead of at a UTC boundary.
pub(crate) fn start_of_local_day() -> Result<i64> {
    Ok(Local
        .from_local_datetime(
            &current_time()
                .date_naive()
                .and_hms_opt(0, 0, 0)
                .ok_or_else(|| TwonlyError::Generic("invalid local date".into()))?,
        )
        .earliest()
        .ok_or_else(|| TwonlyError::Generic("local day has no midnight".into()))?
        .timestamp())
}

/// Midnight of the local day `timestamp` falls on.
pub(crate) fn start_of_local_day_at(timestamp: i64) -> Option<i64> {
    Local
        .from_local_datetime(
            &Local
                .timestamp_opt(timestamp, 0)
                .single()?
                .date_naive()
                .and_hms_opt(0, 0, 0)?,
        )
        .earliest()
        .map(|midnight| midnight.timestamp())
}

/// Midnight starting the local day `days` after today. Counted in calendar
/// days rather than seconds, so a daylight saving change in between still lands
/// on midnight.
pub(crate) fn start_of_local_day_in(days: u32) -> Result<i64> {
    let day = current_time()
        .date_naive()
        .checked_add_days(chrono::Days::new(days.into()))
        .ok_or_else(|| TwonlyError::Generic("local date out of range".into()))?;

    Ok(Local
        .from_local_datetime(
            &day.and_hms_opt(0, 0, 0)
                .ok_or_else(|| TwonlyError::Generic("invalid local date".into()))?,
        )
        .earliest()
        .ok_or_else(|| TwonlyError::Generic("local day has no midnight".into()))?
        .timestamp())
}

pub(crate) fn new_uuid_v4() -> String {
    uuid::Uuid::new_v4().to_string()
}

/// Media and message identifiers are time-ordered so that inserting them keeps
/// the primary-key index append-only, matching what Drift generated before.
pub(crate) fn new_uuid_v7() -> String {
    uuid::Uuid::now_v7().to_string()
}

#[derive(Default, Clone)]

pub(crate) struct Shared<T>(Arc<RwLock<T>>);

impl<T> Shared<T> {
    pub(crate) fn new(value: T) -> Self {
        Self(Arc::new(RwLock::new(value)))
    }

    pub(crate) async fn get(&self) -> RwLockReadGuard<'_, T> {
        self.0.read().await
    }

    // pub(crate) async fn set(&self, value: T) {
    //     *self.0.write().await = value;
    // }
}

#[cfg(test)]
mod tests {

    use super::{
        current_time, is_today, milliseconds_to_seconds, start_of_local_day, start_of_local_day_at,
        start_of_local_day_in,
    };

    #[test]

    fn converts_milliseconds_to_seconds() {
        assert_eq!(milliseconds_to_seconds(1_999), 1);

        assert_eq!(milliseconds_to_seconds(1_000), 1);

        assert_eq!(milliseconds_to_seconds(999), 0);
    }

    #[test]

    fn recognizes_current_day() {
        assert!(is_today(current_time().timestamp()));

        assert!(!is_today(i64::MAX));
    }

    #[test]

    fn finds_the_midnight_of_any_day() {
        let today = start_of_local_day().unwrap();

        assert_eq!(start_of_local_day_at(today), Some(today));

        assert_eq!(start_of_local_day_at(today + 60), Some(today));

        assert_eq!(
            start_of_local_day_at(today - 1),
            start_of_local_day_at(today - 3600)
        );

        assert!(start_of_local_day_at(today - 1).unwrap() < today);

        assert_eq!(start_of_local_day_at(i64::MAX), None);
    }

    #[test]

    fn counts_days_ahead_in_calendar_days() {
        assert_eq!(
            start_of_local_day_in(0).unwrap(),
            start_of_local_day().unwrap()
        );

        let in_five = start_of_local_day_in(5).unwrap();

        // Midnight, whatever daylight saving does in between.
        assert_eq!(start_of_local_day_at(in_five), Some(in_five));

        let hours = (in_five - start_of_local_day().unwrap()) / 3600;

        assert!((119..=121).contains(&hours), "{hours} hours");
    }
}
