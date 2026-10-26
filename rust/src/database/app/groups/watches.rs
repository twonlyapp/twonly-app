use super::native::{FlameState, Group};
use super::queries;
use super::table::*;
use crate::database::app::{watch, AppDatabase};
use crate::error::Result;
use std::sync::Arc;
use tokio::sync::RwLock;
use tokio_util::sync::CancellationToken;

pub async fn groups(
    databases: Arc<RwLock<Arc<AppDatabase>>>, input: GroupQuery, cancellation: CancellationToken,
    emit: impl Fn(Vec<Group>) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["groups", "group_members", "contacts"],
        cancellation,
        move |database| {
            let input = input.clone();

            async move { queries::list(&mut *database.read_pool.acquire().await?, &input).await }
        },
        emit,
    )
    .await
}

pub async fn members(
    databases: Arc<RwLock<Arc<AppDatabase>>>, input: GroupMembersQuery,
    cancellation: CancellationToken, emit: impl Fn(Vec<GroupMember>) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["group_members"],
        cancellation,
        move |database| {
            let input = input.clone();

            async move { queries::members(&mut *database.read_pool.acquire().await?, &input).await }
        },
        emit,
    )
    .await
}

pub async fn contacts(
    databases: Arc<RwLock<Arc<AppDatabase>>>, input: GroupMembersQuery,
    cancellation: CancellationToken, emit: impl Fn(GroupMembersWithContacts) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["group_members", "contacts"],
        cancellation,
        move |database| {
            let input = input.clone();

            async move {
                let mut tx = database.read_pool.begin().await?;

                let value = queries::members_with_contacts(&mut tx, &input).await?;

                tx.commit().await?;

                Ok(value)
            }
        },
        emit,
    )
    .await
}

pub async fn history(
    databases: Arc<RwLock<Arc<AppDatabase>>>, group: String, since: Option<i64>,
    cancellation: CancellationToken, emit: impl Fn(Vec<GroupHistory>) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["group_histories"],
        cancellation,
        move |database| {
            let group = group.clone();

            async move {
                queries::history(&mut *database.read_pool.acquire().await?, &group, since).await
            }
        },
        emit,
    )
    .await
}

pub async fn total_media(
    databases: Arc<RwLock<Arc<AppDatabase>>>, cancellation: CancellationToken,
    emit: impl Fn(i64) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["groups"],
        cancellation,
        |database| async move {

            queries::total_media(&mut *database.read_pool.acquire().await?).await
        },
        emit,
    )
    .await
}

pub async fn flame(
    databases: Arc<RwLock<Arc<AppDatabase>>>, group: String, cancellation: CancellationToken,
    emit: impl Fn(FlameState) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["groups"],
        cancellation,
        move |database| {
            let group = group.clone();

            async move {
                let eligible: bool = sqlx::query_scalar!(
                    r#"
                        SELECT EXISTS(
                            SELECT 1
                            FROM groups
                            WHERE group_id = ?
                                AND last_message_send IS NOT NULL
                                AND last_message_received IS NOT NULL
                        ) AS "value!: bool"
                    "#,
                    &group,
                )
                .fetch_one(&database.read_pool)
                .await?;

                if !eligible {
                    return Ok(FlameState::default());
                }

                Group::flame_state(&database.read_pool, &group).await
            }
        },
        emit,
    )
    .await
}

/// Contact blobs, counters and typing timestamps never cross this stream.
pub async fn chat_list_contacts(
    databases: Arc<RwLock<Arc<AppDatabase>>>, cancellation: CancellationToken,
    emit: impl Fn(Vec<ChatListContact>) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["group_members", "contacts"],
        cancellation,
        |database| async move {
            queries::chat_list_contacts(&mut *database.read_pool.acquire().await?).await
        },
        emit,
    )
    .await
}

/// Resolve the global best friend once for every chat-list refresh.
pub async fn flames(
    databases: Arc<RwLock<Arc<AppDatabase>>>, cancellation: CancellationToken,
    emit: impl Fn(std::collections::HashMap<String, FlameState>) -> bool,
) -> Result<()> {
    watch::snapshots(
        databases,
        &["groups"],
        cancellation,
        |database| async move { Group::flame_states(&database.read_pool, None).await },
        emit,
    )
    .await
}
