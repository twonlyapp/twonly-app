/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

//! "On Vacation" freezes the streaks of a direct chat while one side is away:
//! a frozen streak can neither be lost nor grow. Afterwards it runs out like
//! any other, as if both sides had exchanged media on the last vacation day.
//!
//! Each chat keeps two windows, the user's own and the one its peer announced.
//! Nothing is written into the exchange times while a window lasts, so a
//! vacation can still be ended early; [`freeze`] folds the windows in whenever
//! a streak is judged.

use sqlx::{Sqlite, Transaction};

use crate::error::Result;
use crate::utils::start_of_local_day_at;

use super::native::{flame_alive_on, Group};

const DAY: i64 = 24 * 60 * 60;

/// The icons a vacation can be shown with, in the order the picker offers
/// them. A peer on a newer release may announce one missing here; it is kept
/// as sent and shown as a plain emoji.
pub const VACATION_ICONS: &[&str] = &["🏕️", "✈️", "⛵"];

pub const MIN_VACATION_DAYS: u32 = 3;

pub const MAX_VACATION_DAYS: u32 = 8;

/// Only streaks above four flames are frozen, and only their chats hear about
/// the vacation.
pub const MIN_FLAMES_TO_FREEZE: i64 = 5;

/// The longest window a peer can announce: the longest vacation plus the rest
/// of the day it began on.
const MAX_WINDOW_SECONDS: i64 = (MAX_VACATION_DAYS as i64 + 1) * DAY;

const MAX_ICON_BYTES: usize = 32;

/// The plans that include "On Vacation". The receiving side never checks this:
/// a friend on the free plan still sees and honours the vacation.
pub fn vacation_allowed(plan: &str) -> bool {
    ["pro", "tester", "family", "plus"]
        .iter()
        .any(|allowed| plan.trim().eq_ignore_ascii_case(allowed))
}

#[derive(Clone, Debug, PartialEq, Eq)]

pub struct VacationWindow {
    pub from: i64,
    /// Local midnight after the last vacation day. A window ended on the day
    /// it began has `until == from` and freezes nothing.
    pub until: i64,
    pub icon: String,
}

impl VacationWindow {
    pub(crate) fn from_columns(
        from: Option<i64>, until: Option<i64>, icon: Option<String>,
    ) -> Option<Self> {
        Some(Self {
            from: from?,
            until: until?,
            icon: icon.unwrap_or_else(|| VACATION_ICONS[0].to_owned()),
        })
    }

    /// A window as a peer announced it, trimmed to what a real vacation can
    /// be. The peer picks every value here.
    pub(crate) fn announced(from: i64, until: i64, icon: &str) -> Self {
        let until = until.clamp(from, from.saturating_add(MAX_WINDOW_SECONDS));

        let icon = icon.trim();

        let icon = if icon.is_empty() || icon.len() > MAX_ICON_BYTES {
            VACATION_ICONS[0]
        } else {
            icon
        };

        Self {
            from,
            until,
            icon: icon.to_owned(),
        }
    }

    pub(crate) fn is_active(&self, now: i64) -> bool {
        self.from <= now && now < self.until
    }
}

/// The exchange times a streak is judged by once vacations are folded in, and
/// the vacation freezing it right now.
#[derive(Debug, PartialEq, Eq)]

pub(crate) struct Frozen<'a> {
    pub sent: Option<i64>,
    pub received: Option<i64>,
    pub active: Option<&'a VacationWindow>,
}

/// A vacation that began while the streak was alive counts as an exchange in
/// both directions at its last second. That keeps the streak alive through it
/// and lets it run out normally afterwards: alive the day after, expiring the
/// day after that, gone on the third.
///
/// A vacation that began on a streak already lost changes nothing, so a late
/// or forged announcement cannot bring one back. Windows are applied in the
/// order they began, which lets one vacation carry a streak into the next.
///
/// `windows` is in order of preference: the first one freezing the streak at
/// `now` is reported as `active`. `cap` ends every window there at the latest,
/// see [`Group::bake_vacations`].
pub(crate) fn freeze<'a>(
    sent: Option<i64>, received: Option<i64>, changed: Option<i64>, windows: &[&'a VacationWindow],
    now: i64, cap: Option<i64>,
) -> Frozen<'a> {
    let mut order: Vec<usize> = (0..windows.len()).collect();

    order.sort_by_key(|&index| windows[index].from);

    let mut sent = sent;

    let mut received = received;

    let mut freezing = vec![false; windows.len()];

    for index in order {
        let window = windows[index];

        let until = cap.map_or(window.until, |cap| window.until.min(cap));

        if until <= window.from {
            continue;
        }

        let Some(start_of_day) = start_of_local_day_at(window.from) else {
            continue;
        };

        if !flame_alive_on(sent, received, changed, start_of_day) {
            continue;
        }

        let last_second = Some(until - 1);

        sent = sent.max(last_second);

        received = received.max(last_second);

        freezing[index] = window.is_active(now);
    }

    let active = windows
        .iter()
        .zip(freezing)
        .find_map(|(window, freezing)| freezing.then_some(*window));

    Frozen {
        sent,
        received,
        active,
    }
}

struct VacationRow {
    last_message_send: Option<i64>,
    last_message_received: Option<i64>,
    last_flame_counter_change: Option<i64>,
    vacation_from: Option<i64>,
    vacation_until: Option<i64>,
    vacation_icon: Option<String>,
    peer_vacation_from: Option<i64>,
    peer_vacation_until: Option<i64>,
    peer_vacation_icon: Option<String>,
}

impl VacationRow {
    fn own(&self) -> Option<VacationWindow> {
        VacationWindow::from_columns(
            self.vacation_from,
            self.vacation_until,
            self.vacation_icon.clone(),
        )
    }

    fn peer(&self) -> Option<VacationWindow> {
        VacationWindow::from_columns(
            self.peer_vacation_from,
            self.peer_vacation_until,
            self.peer_vacation_icon.clone(),
        )
    }
}

impl Group {
    async fn vacation_row(
        tr: &mut Transaction<'_, Sqlite>, group_id: &str,
    ) -> Result<Option<VacationRow>> {
        Ok(sqlx::query_as!(
            VacationRow,
            r#"SELECT last_message_send, last_message_received, last_flame_counter_change,
                      vacation_from, vacation_until, vacation_icon,
                      peer_vacation_from, peer_vacation_until, peer_vacation_icon
               FROM groups WHERE group_id = ?"#,
            group_id,
        )
        .fetch_optional(&mut **tr)
        .await?)
    }

    /// The direct chats a vacation starting now would freeze: a streak above
    /// four flames with someone the user still talks to.
    pub async fn vacation_candidates(pool: &sqlx::Pool<Sqlite>) -> Result<Vec<String>> {
        let direct = sqlx::query_scalar!(
            r#"SELECT DISTINCT g.group_id
               FROM groups g
               JOIN group_members m ON m.group_id = g.group_id
               JOIN contacts c ON c.user_id = m.contact_id
               WHERE g.is_direct_chat = 1
                 AND g.left_group = 0
                 AND c.blocked = 0
                 AND c.account_deleted = 0
               ORDER BY g.group_id"#
        )
        .fetch_all(pool)
        .await?;

        let states = Self::flame_states(pool, Some(direct.clone())).await?;

        Ok(direct
            .into_iter()
            .filter(|group_id| {
                states
                    .get(group_id)
                    .is_some_and(|state| state.counter >= MIN_FLAMES_TO_FREEZE)
            })
            .collect())
    }

    /// The user's own vacation while it lasts.
    pub async fn own_vacation(
        executor: impl sqlx::Executor<'_, Database = Sqlite>, now: i64,
    ) -> Result<Option<VacationWindow>> {
        Ok(sqlx::query!(
            r#"SELECT vacation_from AS "from!", vacation_until AS "until!", vacation_icon
               FROM groups
               WHERE vacation_from IS NOT NULL AND vacation_until > ?
               ORDER BY vacation_until DESC
               LIMIT 1"#,
            now,
        )
        .fetch_optional(executor)
        .await?
        .map(|row| VacationWindow {
            from: row.from,
            until: row.until,
            icon: row
                .vacation_icon
                .unwrap_or_else(|| VACATION_ICONS[0].to_owned()),
        }))
    }

    /// Writes what the vacations have done to a streak up to `cap` into its
    /// exchange times. A window about to be replaced may be what carries the
    /// streak right now; dropping it without this could lose the streak the
    /// moment the next vacation begins.
    async fn bake_vacations(
        tr: &mut Transaction<'_, Sqlite>, group_id: &str, row: &VacationRow, cap: i64,
    ) -> Result<()> {
        let own = row.own();

        let peer = row.peer();

        let windows: Vec<&VacationWindow> = own.iter().chain(peer.iter()).collect();

        let frozen = freeze(
            row.last_message_send,
            row.last_message_received,
            row.last_flame_counter_change,
            &windows,
            cap,
            Some(cap),
        );

        if frozen.sent == row.last_message_send && frozen.received == row.last_message_received {
            return Ok(());
        }

        sqlx::query!(
            "UPDATE groups SET last_message_send = ?, last_message_received = ? WHERE group_id = ?",
            frozen.sent,
            frozen.received,
            group_id,
        )
        .execute(&mut **tr)
        .await?;

        Ok(())
    }

    pub async fn start_own_vacation(
        tr: &mut Transaction<'_, Sqlite>, group_ids: &[String], window: &VacationWindow,
    ) -> Result<()> {
        for group_id in group_ids {
            let Some(row) = Self::vacation_row(tr, group_id).await? else {
                continue;
            };

            if row.own().is_some() {
                Self::bake_vacations(tr, group_id, &row, window.from).await?;
            }

            sqlx::query!(
                r#"UPDATE groups
                   SET vacation_from = ?, vacation_until = ?, vacation_icon = ?
                   WHERE group_id = ?"#,
                window.from,
                window.until,
                window.icon,
                group_id,
            )
            .execute(&mut **tr)
            .await?;
        }

        Ok(())
    }

    /// Ends the user's vacation before today, so streaks count again from
    /// today on and run out as if the last exchange was yesterday. A vacation
    /// ended on the day it began is undone completely. Returns the shortened
    /// window of every chat, for the peers to be told.
    pub async fn end_own_vacation(
        tr: &mut Transaction<'_, Sqlite>, now: i64, start_of_today: i64,
    ) -> Result<Vec<(String, VacationWindow)>> {
        let rows = sqlx::query!(
            r#"SELECT group_id, vacation_from AS "from!", vacation_until AS "until!", vacation_icon
               FROM groups
               WHERE vacation_from IS NOT NULL AND vacation_until > ?
               ORDER BY group_id"#,
            now,
        )
        .fetch_all(&mut **tr)
        .await?;

        let mut ended = Vec::with_capacity(rows.len());

        for row in rows {
            let until = start_of_today.max(row.from).min(row.until);

            sqlx::query!(
                "UPDATE groups SET vacation_until = ? WHERE group_id = ?",
                until,
                row.group_id,
            )
            .execute(&mut **tr)
            .await?;

            ended.push((
                row.group_id,
                VacationWindow {
                    from: row.from,
                    until,
                    icon: row
                        .vacation_icon
                        .unwrap_or_else(|| VACATION_ICONS[0].to_owned()),
                },
            ));
        }

        Ok(ended)
    }

    /// Records a vacation the peer of a direct chat announced. A vacation is
    /// identified by its start: the same start again can only shorten it,
    /// which is how an early end arrives and why a delayed copy of the first
    /// announcement cannot undo that end. An older start than the one stored
    /// is stale and ignored. Returns whether the window was taken.
    pub async fn apply_peer_vacation(
        tr: &mut Transaction<'_, Sqlite>, group_id: &str, window: &VacationWindow,
    ) -> Result<bool> {
        let Some(row) = Self::vacation_row(tr, group_id).await? else {
            return Ok(false);
        };

        let until = match row.peer() {
            Some(stored) if window.from < stored.from => return Ok(false),
            Some(stored) if window.from == stored.from => window.until.min(stored.until),
            Some(_) => {
                Self::bake_vacations(tr, group_id, &row, window.from).await?;

                window.until
            }
            None => window.until,
        };

        sqlx::query!(
            r#"UPDATE groups
               SET peer_vacation_from = ?, peer_vacation_until = ?, peer_vacation_icon = ?
               WHERE group_id = ?"#,
            window.from,
            until,
            window.icon,
            group_id,
        )
        .execute(&mut **tr)
        .await?;

        Ok(true)
    }
}

#[cfg(test)]
#[path = "vacation_tests.rs"]
mod tests;
