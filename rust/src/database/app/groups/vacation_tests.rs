use super::*;
use crate::database::app::groups::native::{FlameRow, FlameState};
use crate::database::app::AppDatabase;
use crate::utils::{current_time, start_of_local_day};
use chrono::{Local, TimeZone};

const HOUR: i64 = 60 * 60;

/// Local midnight of a day in May 2026, a month without a daylight saving
/// change, so day arithmetic in the expectations stays plain.
fn midnight(day: u32) -> i64 {
    Local
        .with_ymd_and_hms(2026, 5, day, 0, 0, 0)
        .earliest()
        .unwrap()
        .timestamp()
}

fn noon(day: u32) -> i64 {
    midnight(day) + 12 * HOUR
}

fn window(from: i64, until: i64, icon: &str) -> VacationWindow {
    VacationWindow {
        from,
        until,
        icon: icon.into(),
    }
}

/// A streak last exchanged in both directions at `exchanged`.
fn flame_row(
    counter: i64, exchanged: i64, own: Option<VacationWindow>, peer: Option<VacationWindow>,
) -> FlameRow {
    FlameRow {
        group_id: "chat".into(),
        flame_counter: counter,
        also_best_friend: 0,
        last_message_send: Some(exchanged),
        last_message_received: Some(exchanged),
        last_flame_counter_change: Some(exchanged),
        vacation_from: own.as_ref().map(|window| window.from),
        vacation_until: own.as_ref().map(|window| window.until),
        vacation_icon: own.map(|window| window.icon),
        peer_vacation_from: peer.as_ref().map(|window| window.from),
        peer_vacation_until: peer.as_ref().map(|window| window.until),
        peer_vacation_icon: peer.map(|window| window.icon),
    }
}

/// The state shown at noon of a day in May.
fn shown_on(row: &FlameRow, day: u32) -> (i64, bool, Option<String>) {
    let FlameState {
        counter,
        is_expiring,
        vacation_icon,
        ..
    } = row.derive(midnight(day), noon(day), false);

    (counter, is_expiring, vacation_icon)
}

fn frozen(icon: &str) -> (i64, bool, Option<String>) {
    (50, false, Some(icon.into()))
}

const ALIVE: (i64, bool, Option<String>) = (50, false, None);

const EXPIRING: (i64, bool, Option<String>) = (50, true, None);

const LOST: (i64, bool, Option<String>) = (0, false, None);

/// The example from the feature request: 50 flames, five days on vacation
/// starting on May 2. The streak stays at 50 through May 6, counts normally
/// again on May 7, shows the clock on May 8 without an exchange, and is gone
/// on May 9.
#[test]

fn a_five_day_vacation_freezes_the_streak_and_then_lets_it_run_out() {
    let vacation = window(midnight(2) + 10 * HOUR, midnight(7), "🏕️");

    let row = flame_row(50, midnight(1) + 20 * HOUR, Some(vacation), None);

    for day in 2..=6 {
        assert_eq!(shown_on(&row, day), frozen("🏕️"), "May {day}");
    }

    assert_eq!(shown_on(&row, 7), ALIVE);

    assert_eq!(shown_on(&row, 8), EXPIRING);

    assert_eq!(shown_on(&row, 9), LOST);

    // Without it the streak would have been lost on May 4.
    let without = flame_row(50, midnight(1) + 20 * HOUR, None, None);

    assert_eq!(shown_on(&without, 3), EXPIRING);

    assert_eq!(shown_on(&without, 4), LOST);
}

#[test]

fn a_vacation_on_the_last_day_still_saves_the_streak() {
    // Exchanged on May 1, so May 3 is the day it would end at midnight.
    let row = flame_row(
        50,
        noon(1),
        Some(window(noon(3), midnight(6), "✈️")),
        None,
    );

    assert_eq!(shown_on(&row, 3), frozen("✈️"));

    assert_eq!(shown_on(&row, 5), frozen("✈️"));

    assert_eq!(shown_on(&row, 6), ALIVE);
}

/// A vacation announced late, or by a peer who wants to, cannot bring back a
/// streak that was already gone when it began.
#[test]

fn a_vacation_cannot_bring_back_a_lost_streak() {
    let row = flame_row(
        50,
        noon(1),
        Some(window(noon(4), midnight(9), "🏕️")),
        None,
    );

    for day in 4..=10 {
        assert_eq!(shown_on(&row, day), LOST, "May {day}");
    }
}

#[test]

fn a_vacation_before_any_exchange_changes_nothing() {
    let mut row = flame_row(0, noon(1), Some(window(noon(1), midnight(5), "🏕️")), None);

    row.last_message_send = None;

    row.last_message_received = None;

    row.last_flame_counter_change = None;

    assert_eq!(shown_on(&row, 2), LOST);
}

#[test]

fn a_vacation_ended_on_its_first_day_is_undone() {
    let row = flame_row(50, noon(1), Some(window(noon(2), noon(2), "🏕️")), None);

    assert_eq!(shown_on(&row, 2), ALIVE);

    assert_eq!(shown_on(&row, 3), EXPIRING);

    assert_eq!(shown_on(&row, 4), LOST);
}

/// Ended on May 4: from then on the streak runs out as if the last exchange
/// was on May 3.
#[test]

fn a_vacation_ended_early_counts_up_to_the_day_before() {
    let row = flame_row(50, noon(1), Some(window(noon(2), midnight(4), "🏕️")), None);

    assert_eq!(shown_on(&row, 3), frozen("🏕️"));

    assert_eq!(shown_on(&row, 4), ALIVE);

    assert_eq!(shown_on(&row, 5), EXPIRING);

    assert_eq!(shown_on(&row, 6), LOST);
}

#[test]

fn the_peers_vacation_freezes_the_streak_the_same_way() {
    let row = flame_row(
        50,
        midnight(1) + 20 * HOUR,
        None,
        Some(window(midnight(2) + 10 * HOUR, midnight(7), "⛵")),
    );

    for day in 2..=6 {
        assert_eq!(shown_on(&row, day), frozen("⛵"), "May {day}");
    }

    assert_eq!(shown_on(&row, 7), ALIVE);

    assert_eq!(shown_on(&row, 8), EXPIRING);

    assert_eq!(shown_on(&row, 9), LOST);
}

/// One vacation ending May 4, the other starting May 6: the first one is what
/// keeps the streak alive when the second begins.
#[test]

fn one_vacation_carries_the_streak_into_the_next() {
    let own = window(noon(2), midnight(5), "🏕️");

    let peer = window(noon(6), midnight(9), "⛵");

    for (own, peer) in [
        (Some(own.clone()), Some(peer.clone())),
        // The order the windows are stored in must not matter.
        (Some(peer.clone()), Some(own.clone())),
    ] {
        let row = flame_row(50, noon(1), own, peer);

        assert_eq!(shown_on(&row, 5), ALIVE);

        for day in 6..=8 {
            assert_eq!(shown_on(&row, day).0, 50, "May {day}");

            assert!(shown_on(&row, day).2.is_some(), "May {day}");
        }

        assert_eq!(shown_on(&row, 9), ALIVE);

        assert_eq!(shown_on(&row, 10), EXPIRING);

        assert_eq!(shown_on(&row, 11), LOST);
    }

    // Starting a day later, the first vacation's streak is already gone.
    let late = flame_row(50, noon(1), Some(own), Some(window(noon(7), midnight(10), "⛵")));

    assert_eq!(shown_on(&late, 7), LOST);
}

#[test]

fn the_users_own_icon_wins_while_both_are_away() {
    let row = flame_row(
        50,
        noon(1),
        Some(window(noon(3), midnight(8), "🏕️")),
        Some(window(noon(2), midnight(6), "⛵")),
    );

    assert_eq!(shown_on(&row, 2), frozen("⛵"));

    assert_eq!(shown_on(&row, 4), frozen("🏕️"));

    // The peer is back, the user is still away.
    assert_eq!(shown_on(&row, 7), frozen("🏕️"));

    assert_eq!(shown_on(&row, 8), ALIVE);
}

/// Media exchanged during the vacation moves the real times forward, but the
/// streak still ends after the vacation, never earlier.
#[test]

fn exchanges_during_a_vacation_do_not_shorten_it() {
    let mut row = flame_row(50, noon(1), Some(window(noon(2), midnight(7), "🏕️")), None);

    row.last_message_send = Some(noon(3));

    assert_eq!(shown_on(&row, 6), frozen("🏕️"));

    assert_eq!(shown_on(&row, 7), ALIVE);

    assert_eq!(shown_on(&row, 8), EXPIRING);
}

#[test]

fn an_empty_streak_shows_no_vacation_icon() {
    let row = flame_row(0, noon(1), Some(window(noon(2), midnight(7), "🏕️")), None);

    assert_eq!(shown_on(&row, 3), LOST);
}

#[test]

fn a_window_is_active_from_its_start_up_to_its_end() {
    let window = window(100, 200, "🏕️");

    assert!(!window.is_active(99));

    assert!(window.is_active(100));

    assert!(window.is_active(199));

    assert!(!window.is_active(200));
}

#[test]

fn a_cap_ends_every_window_early() {
    let vacation = window(noon(2), midnight(7), "🏕️");

    let exchanged = Some(noon(1));

    let capped = freeze(
        exchanged,
        exchanged,
        exchanged,
        &[&vacation],
        noon(4),
        Some(noon(4)),
    );

    assert_eq!(
        (capped.sent, capped.received),
        (Some(noon(4) - 1), Some(noon(4) - 1))
    );

    // A cap at or before the start leaves nothing to freeze.
    let before = freeze(
        exchanged,
        exchanged,
        exchanged,
        &[&vacation],
        noon(2),
        Some(noon(2)),
    );

    assert_eq!((before.sent, before.received), (exchanged, exchanged));

    assert_eq!(before.active, None);
}

#[test]

fn an_announced_window_is_trimmed_to_a_real_vacation() {
    let from = noon(2);

    // Ending before it starts is an end on the first day.
    assert_eq!(VacationWindow::announced(from, from - 1, "🏕️").until, from);

    // Nine days at most: eight vacation days plus the rest of the first.
    assert_eq!(
        VacationWindow::announced(from, from + 30 * DAY, "🏕️").until,
        from + 9 * DAY
    );

    assert_eq!(
        VacationWindow::announced(from, i64::MAX, "🏕️").until,
        from + 9 * DAY
    );

    assert_eq!(
        VacationWindow::announced(i64::MAX - 1, i64::MAX, "🏕️").until,
        i64::MAX
    );

    assert_eq!(
        VacationWindow::announced(from, from + 5 * DAY, "🏕️").until,
        from + 5 * DAY
    );

    // An icon from a newer release is kept; junk is replaced.
    assert_eq!(VacationWindow::announced(from, from, " 🏝️ ").icon, "🏝️");

    assert_eq!(VacationWindow::announced(from, from, "").icon, "🏕️");

    assert_eq!(VacationWindow::announced(from, from, "   ").icon, "🏕️");

    assert_eq!(
        VacationWindow::announced(from, from, &"x".repeat(33)).icon,
        "🏕️"
    );
}

#[test]

fn only_the_paid_plans_include_vacations() {
    for plan in ["Pro", "pro", "Tester", "Family", "Plus", " PLUS "] {
        assert!(vacation_allowed(plan), "{plan}");
    }

    for plan in ["Free", "", "Premium", "pro+"] {
        assert!(!vacation_allowed(plan), "{plan}");
    }
}

async fn open_database() -> (tempfile::TempDir, AppDatabase) {
    let directory = tempfile::tempdir().unwrap();

    let path = directory.path().join("app.sqlite");

    let database = AppDatabase::new(path.to_str().unwrap(), None, false)
        .await
        .unwrap();

    database.run_migrations().await.unwrap();

    sqlx::query("INSERT INTO contacts(user_id, username) VALUES (7, 'alice')")
        .execute(&database.pool)
        .await
        .unwrap();

    sqlx::query("INSERT INTO groups(group_id, group_name, is_direct_chat) VALUES ('chat', 'Alice', 1)")
        .execute(&database.pool)
        .await
        .unwrap();

    sqlx::query("INSERT INTO group_members(group_id, contact_id) VALUES ('chat', 7)")
        .execute(&database.pool)
        .await
        .unwrap();

    (directory, database)
}

/// 50 flames, last exchanged in both directions at `exchanged`.
async fn set_streak(database: &AppDatabase, exchanged: i64) {
    sqlx::query(
        r#"UPDATE groups SET flame_counter = 50, max_flame_counter = 50,
                             last_message_send = ?, last_message_received = ?,
                             last_flame_counter_change = ?
           WHERE group_id = 'chat'"#,
    )
    .bind(exchanged)
    .bind(exchanged)
    .bind(exchanged)
    .execute(&database.pool)
    .await
    .unwrap();
}

async fn set_own(database: &AppDatabase, window: Option<&VacationWindow>) {
    sqlx::query(
        "UPDATE groups SET vacation_from = ?, vacation_until = ?, vacation_icon = ? \
         WHERE group_id = 'chat'",
    )
    .bind(window.map(|window| window.from))
    .bind(window.map(|window| window.until))
    .bind(window.map(|window| window.icon.clone()))
    .execute(&database.pool)
    .await
    .unwrap();
}

async fn peer(database: &AppDatabase) -> Option<VacationWindow> {
    let row: (Option<i64>, Option<i64>, Option<String>) = sqlx::query_as(
        "SELECT peer_vacation_from, peer_vacation_until, peer_vacation_icon FROM groups \
         WHERE group_id = 'chat'",
    )
    .fetch_one(&database.pool)
    .await
    .unwrap();

    VacationWindow::from_columns(row.0, row.1, row.2)
}

async fn exchange_both_ways(database: &AppDatabase) {
    let now = current_time().timestamp();

    let mut transaction = database.pool.begin().await.unwrap();

    Group::record_media_exchange(&mut transaction, "chat", true, now)
        .await
        .unwrap();

    Group::record_media_exchange(&mut transaction, "chat", false, now)
        .await
        .unwrap();

    transaction.commit().await.unwrap();
}

async fn counter(database: &AppDatabase) -> i64 {
    sqlx::query_scalar("SELECT flame_counter FROM groups WHERE group_id = 'chat'")
        .fetch_one(&database.pool)
        .await
        .unwrap()
}

/// Exchanged three days ago, which on its own lost the streak yesterday; a
/// vacation that began two days ago kept it.
async fn streak_kept_by_a_vacation_until(until: i64) -> (tempfile::TempDir, AppDatabase) {
    let (directory, database) = open_database().await;

    let today = start_of_local_day().unwrap();

    set_streak(&database, today - 3 * DAY + 12 * HOUR).await;

    set_own(
        &database,
        Some(&window(today - 2 * DAY + 12 * HOUR, until, "🏕️")),
    )
    .await;

    (directory, database)
}

#[tokio::test]

async fn media_during_a_vacation_never_grows_the_streak() {
    let tomorrow = start_of_local_day().unwrap() + DAY + 2 * HOUR;

    let (_directory, database) = streak_kept_by_a_vacation_until(tomorrow).await;

    exchange_both_ways(&database).await;

    exchange_both_ways(&database).await;

    assert_eq!(counter(&database).await, 50);

    let state = Group::flame_state(&database.pool, "chat").await.unwrap();

    assert_eq!(
        (state.counter, state.vacation_icon.as_deref()),
        (50, Some("🏕️"))
    );

    let total: i64 =
        sqlx::query_scalar("SELECT total_media_counter FROM groups WHERE group_id = 'chat'")
            .fetch_one(&database.pool)
            .await
            .unwrap();

    assert_eq!(total, 4);
}

/// The vacation ended at midnight; today's exchange is the first after it and
/// grows the frozen streak instead of starting over.
#[tokio::test]

async fn after_a_vacation_the_streak_grows_from_where_it_froze() {
    let today = start_of_local_day().unwrap();

    let (_directory, database) = streak_kept_by_a_vacation_until(today).await;

    let state = Group::flame_state(&database.pool, "chat").await.unwrap();

    assert_eq!((state.counter, state.vacation_icon), (50, None));

    exchange_both_ways(&database).await;

    assert_eq!(counter(&database).await, 51);

    // A second exchange the same day counts once, as always.
    exchange_both_ways(&database).await;

    assert_eq!(counter(&database).await, 51);

    // Without the vacation the same exchange starts a new streak.
    let (_directory, plain) = open_database().await;

    set_streak(&plain, today - 3 * DAY + 12 * HOUR).await;

    exchange_both_ways(&plain).await;

    assert_eq!(counter(&plain).await, 1);
}

#[tokio::test]

async fn the_peers_vacation_blocks_growth_on_this_side_too() {
    let (_directory, database) = open_database().await;

    let today = start_of_local_day().unwrap();

    set_streak(&database, today - 3 * DAY + 12 * HOUR).await;

    let mut transaction = database.pool.begin().await.unwrap();

    assert!(Group::apply_peer_vacation(
        &mut transaction,
        "chat",
        &window(today - 2 * DAY + 12 * HOUR, today + 3 * DAY, "⛵"),
    )
    .await
    .unwrap());

    transaction.commit().await.unwrap();

    exchange_both_ways(&database).await;

    assert_eq!(counter(&database).await, 50);

    let state = Group::flame_state(&database.pool, "chat").await.unwrap();

    assert_eq!(state.vacation_icon.as_deref(), Some("⛵"));
}

/// The rules a peer's announcements are merged by, including the ones that
/// arrive twice or out of order.
#[tokio::test]

async fn announcements_are_merged_by_their_start() {
    let (_directory, database) = open_database().await;

    let today = start_of_local_day().unwrap();

    set_streak(&database, today - 12 * HOUR).await;

    let start = today + HOUR;

    let apply = |window: VacationWindow| {
        let database = &database;

        async move {
            let mut transaction = database.pool.begin().await.unwrap();

            let taken = Group::apply_peer_vacation(&mut transaction, "chat", &window)
                .await
                .unwrap();

            transaction.commit().await.unwrap();

            taken
        }
    };

    assert!(apply(window(start, today + 5 * DAY, "🏕️")).await);

    assert_eq!(peer(&database).await, Some(window(start, today + 5 * DAY, "🏕️")));

    // Delivered twice: nothing changes.
    assert!(apply(window(start, today + 5 * DAY, "🏕️")).await);

    assert_eq!(peer(&database).await, Some(window(start, today + 5 * DAY, "🏕️")));

    // Ended early.
    assert!(apply(window(start, today + DAY, "🏕️")).await);

    assert_eq!(peer(&database).await, Some(window(start, today + DAY, "🏕️")));

    // The original announcement arriving after the end cannot undo it.
    assert!(apply(window(start, today + 5 * DAY, "🏕️")).await);

    assert_eq!(peer(&database).await, Some(window(start, today + DAY, "🏕️")));

    // An older vacation is stale.
    assert!(!apply(window(start - DAY, today + 8 * DAY, "✈️")).await);

    assert_eq!(peer(&database).await, Some(window(start, today + DAY, "🏕️")));

    // A newer one replaces it.
    assert!(apply(window(start + HOUR, today + 3 * DAY, "✈️")).await);

    assert_eq!(
        peer(&database).await,
        Some(window(start + HOUR, today + 3 * DAY, "✈️"))
    );

    // No such chat.
    let mut transaction = database.pool.begin().await.unwrap();

    assert!(!Group::apply_peer_vacation(
        &mut transaction,
        "missing",
        &window(start, today + DAY, "🏕️")
    )
    .await
    .unwrap());
}

/// The previous vacation ended two days ago and is all that keeps the streak
/// alive today. Replacing it with a new one must keep that, or the streak
/// would be lost the moment the new vacation starts.
#[tokio::test]

async fn a_new_vacation_keeps_what_the_previous_one_carried() {
    let today = start_of_local_day().unwrap();

    let previous = window(today - 5 * DAY + 12 * HOUR, today - DAY, "🏕️");

    let now = current_time().timestamp();

    for replace_own in [false, true] {
        let (_directory, database) = open_database().await;

        set_streak(&database, today - 6 * DAY + 12 * HOUR).await;

        let mut transaction = database.pool.begin().await.unwrap();

        if replace_own {
            sqlx::query(
                "UPDATE groups SET vacation_from = ?, vacation_until = ?, vacation_icon = ? \
                 WHERE group_id = 'chat'",
            )
            .bind(previous.from)
            .bind(previous.until)
            .bind(&previous.icon)
            .execute(&mut *transaction)
            .await
            .unwrap();
        } else {
            Group::apply_peer_vacation(&mut transaction, "chat", &previous)
                .await
                .unwrap();
        }

        transaction.commit().await.unwrap();

        let before = Group::flame_state(&database.pool, "chat").await.unwrap();

        assert_eq!((before.counter, before.is_expiring), (50, true));

        let next = window(now, today + 4 * DAY, "✈️");

        let mut transaction = database.pool.begin().await.unwrap();

        if replace_own {
            Group::start_own_vacation(&mut transaction, &["chat".to_owned()], &next)
                .await
                .unwrap();
        } else {
            assert!(Group::apply_peer_vacation(&mut transaction, "chat", &next)
                .await
                .unwrap());
        }

        transaction.commit().await.unwrap();

        let after = Group::flame_state(&database.pool, "chat").await.unwrap();

        assert_eq!(
            (after.counter, after.is_expiring, after.vacation_icon.as_deref()),
            (50, false, Some("✈️")),
            "replacing the {} window",
            if replace_own { "own" } else { "peer" }
        );

        let baked: (i64, i64) = sqlx::query_as(
            "SELECT last_message_send, last_message_received FROM groups WHERE group_id = 'chat'",
        )
        .fetch_one(&database.pool)
        .await
        .unwrap();

        assert_eq!(baked, (previous.until - 1, previous.until - 1));
    }
}

#[tokio::test]

async fn the_own_vacation_is_reported_while_it_lasts() {
    let (_directory, database) = open_database().await;

    let now = current_time().timestamp();

    assert_eq!(Group::own_vacation(&database.pool, now).await.unwrap(), None);

    let vacation = window(now - HOUR, now + DAY, "⛵");

    set_own(&database, Some(&vacation)).await;

    assert_eq!(
        Group::own_vacation(&database.pool, now).await.unwrap(),
        Some(vacation.clone())
    );

    assert_eq!(
        Group::own_vacation(&database.pool, now + DAY).await.unwrap(),
        None
    );

    // A peer's vacation is not the user's.
    set_own(&database, None).await;

    let mut transaction = database.pool.begin().await.unwrap();

    Group::apply_peer_vacation(&mut transaction, "chat", &vacation)
        .await
        .unwrap();

    transaction.commit().await.unwrap();

    assert_eq!(Group::own_vacation(&database.pool, now).await.unwrap(), None);
}

#[tokio::test]

async fn ending_a_vacation_keeps_the_days_already_spent() {
    let (_directory, database) = open_database().await;

    let today = start_of_local_day().unwrap();

    let now = current_time().timestamp();

    for (from, expected_until) in [
        // Begun two days ago: today counts again, yesterday stays frozen.
        (today - 2 * DAY + HOUR, today),
        // Begun today: nothing is left of it.
        (now, now),
    ] {
        set_own(&database, Some(&window(from, today + 5 * DAY, "🏕️"))).await;

        let mut transaction = database.pool.begin().await.unwrap();

        let ended = Group::end_own_vacation(&mut transaction, now, today)
            .await
            .unwrap();

        transaction.commit().await.unwrap();

        assert_eq!(
            ended,
            vec![("chat".to_owned(), window(from, expected_until, "🏕️"))]
        );

        assert_eq!(Group::own_vacation(&database.pool, now).await.unwrap(), None);

        // Ending again finds nothing to end.
        let mut transaction = database.pool.begin().await.unwrap();

        assert!(Group::end_own_vacation(&mut transaction, now, today)
            .await
            .unwrap()
            .is_empty());
    }
}
