/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use prost::Message;

use super::GroupService;
use crate::api::proto::client as proto;
use crate::database::app::groups::native::Group;
use crate::database::app::groups::vacation::{
    vacation_allowed, VacationWindow, MAX_VACATION_DAYS, MIN_VACATION_DAYS, VACATION_ICONS,
};
use crate::error::{Result, TwonlyError};
use crate::services::messages::MessageService;
use crate::user_config::UserConfig;
use crate::utils::{current_time, start_of_local_day, start_of_local_day_in};

/// The chat entry both sides show for a vacation, and the message type it is
/// stored under.
pub(crate) const VACATION_MESSAGE_TYPE: &str = "onVacation";

pub(crate) fn vacation_data(window: &VacationWindow) -> Vec<u8> {
    proto::AdditionalMessageData {
        r#type: proto::additional_message_data::Type::Vacation as i32,
        vacation: Some(proto::VacationData {
            starts_at_ms: window.from.saturating_mul(1000),
            ends_at_ms: window.until.saturating_mul(1000),
            icon: window.icon.clone(),
        }),
        ..Default::default()
    }
    .encode_to_vec()
}

impl GroupService {
    /// Freezes every streak above four flames for `days` days, today counted
    /// as the first, and tells each of those chats. Returns how many chats
    /// were frozen; none means there was nothing to freeze and no vacation
    /// was started.
    pub(crate) async fn start_vacation(&self, days: u32, icon: String) -> Result<u32> {
        let config = UserConfig::load_required_from(&self.ctx)?;

        if !vacation_allowed(&config.subscription_plan) {
            return Err(TwonlyError::Generic(
                "On Vacation is not part of the current plan".into(),
            ));
        }

        if !(MIN_VACATION_DAYS..=MAX_VACATION_DAYS).contains(&days) {
            return Err(TwonlyError::Generic(format!(
                "a vacation lasts {MIN_VACATION_DAYS} to {MAX_VACATION_DAYS} days, not {days}"
            )));
        }

        if !VACATION_ICONS.contains(&icon.as_str()) {
            return Err(TwonlyError::Generic(format!(
                "unknown vacation icon {icon}"
            )));
        }

        let database = self.ctx.app_db.read().await.clone();

        // Read before the transaction: the app database has a single writer
        // connection, and asking the pool from inside would wait on itself.
        let group_ids = Group::vacation_candidates(&database.pool).await?;

        if group_ids.is_empty() {
            return Ok(0);
        }

        let now = current_time().timestamp();

        let window = VacationWindow {
            from: now,
            until: start_of_local_day_in(days)?,
            icon,
        };

        let mut transaction = database.pool.begin().await?;

        // Checked inside the transaction so a second tap cannot start a second
        // vacation over the first.
        if Group::own_vacation(&mut *transaction, now).await?.is_some() {
            return Err(TwonlyError::Generic("already on vacation".into()));
        }

        Group::start_own_vacation(&mut transaction, &group_ids, &window).await?;

        transaction.commit().await?;

        for group_id in &group_ids {
            self.announce_vacation(group_id, &window).await;
        }

        Ok(group_ids.len() as u32)
    }

    /// Ends the user's vacation early and tells the chats it froze. Returns
    /// how many there were.
    pub(crate) async fn end_vacation(&self) -> Result<u32> {
        let database = self.ctx.app_db.read().await.clone();

        let mut transaction = database.pool.begin().await?;

        let ended = Group::end_own_vacation(
            &mut transaction,
            current_time().timestamp(),
            start_of_local_day()?,
        )
        .await?;

        transaction.commit().await?;

        for (group_id, window) in &ended {
            self.announce_vacation(group_id, window).await;
        }

        Ok(ended.len() as u32)
    }

    /// The window is already in effect locally; a chat that cannot be told
    /// must not stop the others from hearing about it.
    async fn announce_vacation(&self, group_id: &str, window: &VacationWindow) {
        if let Err(error) = MessageService::new(&self.ctx)
            .insert_and_send_additional_data(
                group_id.to_owned(),
                VACATION_MESSAGE_TYPE.into(),
                vacation_data(window),
                false,
            )
            .await
        {
            tracing::warn!(%error, "could not announce the vacation to a chat");
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::context::Context;
    use crate::database::app::groups::native::Group;
    use std::sync::Arc;

    const DAY: i64 = 24 * 60 * 60;

    async fn service(plan: &str) -> anyhow::Result<(tempfile::TempDir, Arc<Context>)> {
        let directory = tempfile::tempdir()?;

        let data_dir = directory.path().join("data");

        std::fs::create_dir_all(data_dir.join("keyvalue"))?;

        std::fs::write(
            data_dir.join("keyvalue/user.json"),
            serde_json::to_vec(&UserConfig {
                user_id: 1,
                username: "me".into(),
                display_name: "Me".into(),
                is_user_discovery_enabled: false,
                subscription_plan: plan.into(),
                ..Default::default()
            })?,
        )?;

        let ctx = Context::init_for_testing(directory.path().join("database"), data_dir).await?;

        crate::api::ApiRuntime::close(&ctx).await?;

        ctx.inject_test_user_id(1).await?;

        Ok((directory, ctx))
    }

    /// A direct chat with a live streak of `flames`, exchanged an hour ago.
    async fn streak(ctx: &Context, contact_id: i64, flames: i64) -> anyhow::Result<String> {
        let database = ctx.app_db.read().await.clone();

        let group_id = Group::direct_chat_id(1, contact_id);

        let exchanged = current_time().timestamp() - 3600;

        sqlx::query("INSERT INTO contacts(user_id, username, accepted) VALUES (?, ?, 1)")
            .bind(contact_id)
            .bind(format!("user{contact_id}"))
            .execute(&database.pool)
            .await?;

        sqlx::query(
            r#"INSERT INTO groups(group_id, group_name, is_direct_chat, joined_group,
                                  flame_counter, last_message_send, last_message_received,
                                  last_flame_counter_change)
               VALUES (?, 'Chat', 1, 1, ?, ?, ?, ?)"#,
        )
        .bind(&group_id)
        .bind(flames)
        .bind(exchanged)
        .bind(exchanged)
        .bind(exchanged)
        .execute(&database.pool)
        .await?;

        sqlx::query("INSERT INTO group_members(group_id, contact_id) VALUES (?, ?)")
            .bind(&group_id)
            .bind(contact_id)
            .execute(&database.pool)
            .await?;

        Ok(group_id)
    }

    async fn announcements(ctx: &Context, group_id: &str) -> anyhow::Result<Vec<VacationWindow>> {
        let database = ctx.app_db.read().await.clone();

        let rows: Vec<Vec<u8>> = sqlx::query_scalar(
            "SELECT additional_message_data FROM messages WHERE group_id = ? AND type = ? \
             ORDER BY rowid",
        )
        .bind(group_id)
        .bind(VACATION_MESSAGE_TYPE)
        .fetch_all(&database.pool)
        .await?;

        Ok(rows
            .iter()
            .map(|bytes| {
                let data = proto::AdditionalMessageData::decode(bytes.as_slice()).unwrap();

                assert_eq!(
                    data.r#type,
                    proto::additional_message_data::Type::Vacation as i32
                );

                let vacation = data.vacation.unwrap();

                VacationWindow {
                    from: vacation.starts_at_ms / 1000,
                    until: vacation.ends_at_ms / 1000,
                    icon: vacation.icon,
                }
            })
            .collect())
    }

    #[tokio::test]

    async fn only_the_paid_plans_can_go_on_vacation() -> anyhow::Result<()> {
        for plan in ["Free", "", "unknown"] {
            let (_directory, ctx) = service(plan).await?;

            streak(&ctx, 7, 50).await?;

            let result = GroupService::new(&ctx)
                .start_vacation(5, "🏕️".into())
                .await;

            assert!(result.is_err(), "{plan} must not go on vacation");

            let database = ctx.app_db.read().await.clone();

            assert_eq!(
                Group::own_vacation(&database.pool, current_time().timestamp()).await?,
                None
            );
        }

        for plan in ["Pro", "Tester", "Family", "Plus", "pro"] {
            let (_directory, ctx) = service(plan).await?;

            streak(&ctx, 7, 50).await?;

            assert_eq!(
                GroupService::new(&ctx)
                    .start_vacation(5, "🏕️".into())
                    .await?,
                1,
                "{plan} can go on vacation"
            );
        }

        Ok(())
    }

    #[tokio::test]

    async fn the_length_and_icon_are_checked() -> anyhow::Result<()> {
        let (_directory, ctx) = service("Pro").await?;

        streak(&ctx, 7, 50).await?;

        let service = GroupService::new(&ctx);

        for days in [0, 2, 9, 30] {
            assert!(service.start_vacation(days, "🏕️".into()).await.is_err());
        }

        for icon in ["", "🔥", "beach", "🏕"] {
            assert!(service.start_vacation(5, icon.into()).await.is_err());
        }

        for (days, icon) in [(3, "✈️"), (8, "⛵")] {
            assert_eq!(service.start_vacation(days, icon.into()).await?, 1);

            service.end_vacation().await?;
        }

        Ok(())
    }

    /// The scenario from the feature request: five days on vacation, then the
    /// streak counts again from the sixth.
    #[tokio::test]

    async fn a_vacation_freezes_and_announces_the_big_streaks_only() -> anyhow::Result<()> {
        let (_directory, ctx) = service("Tester").await?;

        let big = streak(&ctx, 7, 50).await?;

        let threshold = streak(&ctx, 8, 5).await?;

        let small = streak(&ctx, 9, 4).await?;

        let service = GroupService::new(&ctx);

        let before = current_time().timestamp();

        assert_eq!(service.start_vacation(5, "✈️".into()).await?, 2);

        let database = ctx.app_db.read().await.clone();

        let own = Group::own_vacation(&database.pool, current_time().timestamp())
            .await?
            .unwrap();

        assert!(own.from >= before);

        assert_eq!(own.until, start_of_local_day_in(5)?);

        assert_eq!(own.icon, "✈️");

        assert_eq!(announcements(&ctx, &big).await?, vec![own.clone()]);

        assert_eq!(announcements(&ctx, &threshold).await?, vec![own.clone()]);

        assert!(announcements(&ctx, &small).await?.is_empty());

        let states = Group::flame_states(&database.pool, None).await?;

        assert_eq!(states[&big].vacation_icon.as_deref(), Some("✈️"));

        assert_eq!(states[&small].vacation_icon, None);

        // The announcement is queued for the peer like any chat message.
        let queued: i64 = sqlx::query_scalar(
            "SELECT COUNT(*) FROM receipts r JOIN messages m ON m.message_id = r.message_id \
             WHERE m.type = ? AND r.contact_id = 7",
        )
        .bind(VACATION_MESSAGE_TYPE)
        .fetch_one(&database.pool)
        .await?;

        assert_eq!(queued, 1);

        Ok(())
    }

    #[tokio::test]

    async fn a_second_vacation_cannot_start_over_the_first() -> anyhow::Result<()> {
        let (_directory, ctx) = service("Pro").await?;

        let group_id = streak(&ctx, 7, 50).await?;

        let service = GroupService::new(&ctx);

        service.start_vacation(5, "🏕️".into()).await?;

        assert!(service.start_vacation(8, "⛵".into()).await.is_err());

        let database = ctx.app_db.read().await.clone();

        let own = Group::own_vacation(&database.pool, current_time().timestamp())
            .await?
            .unwrap();

        assert_eq!(own.icon, "🏕️");

        assert_eq!(announcements(&ctx, &group_id).await?.len(), 1);

        Ok(())
    }

    #[tokio::test]

    async fn nothing_to_freeze_starts_no_vacation() -> anyhow::Result<()> {
        let (_directory, ctx) = service("Pro").await?;

        let small = streak(&ctx, 7, 4).await?;

        let lost = streak(&ctx, 8, 50).await?;

        let database = ctx.app_db.read().await.clone();

        let long_ago = current_time().timestamp() - 10 * DAY;

        sqlx::query(
            "UPDATE groups SET last_message_send = ?, last_message_received = ?, \
             last_flame_counter_change = ? WHERE group_id = ?",
        )
        .bind(long_ago)
        .bind(long_ago)
        .bind(long_ago)
        .bind(&lost)
        .execute(&database.pool)
        .await?;

        assert_eq!(
            GroupService::new(&ctx)
                .start_vacation(5, "🏕️".into())
                .await?,
            0
        );

        assert_eq!(
            Group::own_vacation(&database.pool, current_time().timestamp()).await?,
            None
        );

        assert!(announcements(&ctx, &small).await?.is_empty());

        assert!(announcements(&ctx, &lost).await?.is_empty());

        Ok(())
    }

    /// Ending on the day it began undoes the vacation, and the peer is told
    /// with the same start so it can match the two announcements.
    #[tokio::test]

    async fn ending_early_shortens_the_window_and_tells_the_peer() -> anyhow::Result<()> {
        let (_directory, ctx) = service("Pro").await?;

        let group_id = streak(&ctx, 7, 50).await?;

        let service = GroupService::new(&ctx);

        assert_eq!(service.end_vacation().await?, 0);

        service.start_vacation(5, "⛵".into()).await?;

        assert_eq!(service.end_vacation().await?, 1);

        let database = ctx.app_db.read().await.clone();

        assert_eq!(
            Group::own_vacation(&database.pool, current_time().timestamp()).await?,
            None
        );

        let sent = announcements(&ctx, &group_id).await?;

        assert_eq!(sent.len(), 2);

        assert_eq!(sent[1].from, sent[0].from);

        assert_eq!(sent[1].until, sent[0].from);

        assert_eq!(
            Group::flame_state(&database.pool, &group_id)
                .await?
                .vacation_icon,
            None
        );

        // Ending twice tells nobody again.
        assert_eq!(service.end_vacation().await?, 0);

        // And a new vacation can start right away.
        assert_eq!(service.start_vacation(3, "🏕️".into()).await?, 1);

        Ok(())
    }

    #[tokio::test]

    async fn blocked_deleted_and_group_chats_are_left_out() -> anyhow::Result<()> {
        let (_directory, ctx) = service("Pro").await?;

        let kept = streak(&ctx, 7, 50).await?;

        let blocked = streak(&ctx, 8, 50).await?;

        let deleted = streak(&ctx, 9, 50).await?;

        let left = streak(&ctx, 10, 50).await?;

        let database = ctx.app_db.read().await.clone();

        sqlx::query("UPDATE contacts SET blocked = 1 WHERE user_id = 8")
            .execute(&database.pool)
            .await?;

        sqlx::query("UPDATE contacts SET account_deleted = 1 WHERE user_id = 9")
            .execute(&database.pool)
            .await?;

        sqlx::query("UPDATE groups SET left_group = 1 WHERE group_id = ?")
            .bind(&left)
            .execute(&database.pool)
            .await?;

        let now = current_time().timestamp();

        sqlx::query(
            r#"INSERT INTO groups(group_id, group_name, is_direct_chat, joined_group,
                                  flame_counter, last_message_send, last_message_received,
                                  last_flame_counter_change)
               VALUES ('group', 'Friends', 0, 1, 50, ?, ?, ?)"#,
        )
        .bind(now)
        .bind(now)
        .bind(now)
        .execute(&database.pool)
        .await?;

        sqlx::query("INSERT INTO group_members(group_id, contact_id) VALUES ('group', 7)")
            .execute(&database.pool)
            .await?;

        assert_eq!(Group::vacation_candidates(&database.pool).await?, vec![kept]);

        assert_eq!(
            GroupService::new(&ctx)
                .start_vacation(5, "🏕️".into())
                .await?,
            1
        );

        for group_id in [blocked, deleted, left, "group".to_owned()] {
            assert!(announcements(&ctx, &group_id).await?.is_empty());
        }

        Ok(())
    }
}
