/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

pub(crate) mod crypto;
pub(crate) mod model;

use crate::api::groups::GroupApi;
use crate::api::messages::incoming::messages::{
    queue_encrypted_content, retransmit_queued_receipts,
};
use crate::api::messages::outgoing::send_c2c_message_to_contact;
use crate::api::proto::client::encrypted_content::GroupJoin;
use crate::api::proto::client::{
    encrypted_appended_group_state, encrypted_content, EncryptedAppendedGroupState,
    EncryptedContent, EncryptedGroupState,
};
use crate::api::proto::http_requests::{append_group_state, AppendGroupState, NewGroupState};
use crate::api::server::Server;
use crate::bridge::api::ServerResult;
use crate::context::Context;
use crate::database::app::tables::{
    Contact, GetGroupPublicKey, GetMissingGroupPublicKeys, GetUnjoinedGroups, Group, InsertGroup,
    InsertGroupHistory, InsertGroupMember, UpdateContact, UpdateGroup, UpdateGroupMemberState,
};
use crate::error::{Result, TwonlyError};
use crate::services::messages::MessageService;
use crate::utils::{current_time, new_uuid_v4};
use model::GroupRecord;
use prost::Message;
use rand::{RngCore, SeedableRng};
use std::collections::{BTreeSet, HashMap};
use std::sync::{Arc, LazyLock, Mutex};
use std::time::{Duration, Instant};

const DEFAULT_DELETE_MS: i64 = 86_400_000;

/// How long to wait before asking the same member for its group public key
/// again. A peer that cannot answer -- an old client, a member who never comes
/// online -- would otherwise be re-asked on every reconnect and every group
/// update.
const PUBLIC_KEY_REQUEST_INTERVAL: Duration = Duration::from_secs(24 * 60 * 60);

pub struct GroupService {
    ctx: Arc<Context>,
}

/// Serializes group-state refreshes per group.
///
/// A refresh reads the server state, may repair it through `update_remote`, and
/// only then writes it locally. Two refreshes running at once read the same
/// `version_id`, so the second repair is rejected by the group server with 409.
/// The single app-database connection used to serialize this by accident, back
/// when the fetch ran inside the transaction; taking the network out of the
/// transaction is what makes an explicit lock necessary.
///
/// Acquire this *before* a database connection and never while holding one:
/// the reverse order deadlocks against the one-connection pool.
static GROUP_STATE_LOCKS: LazyLock<Mutex<HashMap<String, Arc<tokio::sync::Mutex<()>>>>> =
    LazyLock::new(|| Mutex::new(HashMap::new()));

fn group_state_lock(group_id: &str) -> Arc<tokio::sync::Mutex<()>> {
    let mut locks = match GROUP_STATE_LOCKS.lock() {
        Ok(locks) => locks,
        Err(poisoned) => poisoned.into_inner(),
    };
    locks.entry(group_id.to_owned()).or_default().clone()
}

/// How many versions a group-state update chases before it gives up.
const STATE_UPDATE_ATTEMPTS: usize = 3;

/// The admin rights a state update grants or revokes alongside the new state.
#[derive(Default)]
struct AdminKeys {
    add: Option<Vec<u8>>,
    remove: Option<Vec<u8>>,
}

/// A folded-down group state that still has to reach the group server.
///
/// Every admin that reads a member's leave-append removes them from its own
/// copy of the state; whoever pushes first wins, and the losers' rejections
/// are of no consequence. It is carried out of the inbound transaction because
/// pushing it is a network round trip and the app database has one connection.
struct PendingCompaction {
    group: GroupRecord,
    version_id: u64,
    state: EncryptedGroupState,
}

/// When each member was last asked to resend its group public key.
///
/// Process-local on purpose: the point is to keep one session from re-asking a
/// silent peer on every reconnect, not to remember the attempt across restarts.
/// `force` bypasses it, so the user can always retry by opening the group.
static PUBLIC_KEY_REQUESTS: LazyLock<Mutex<HashMap<(String, i64), Instant>>> =
    LazyLock::new(|| Mutex::new(HashMap::new()));

/// Records a request and reports whether it should be sent at all.
fn claim_public_key_request(group_id: &str, contact_id: i64, force: bool) -> bool {
    let mut requests = match PUBLIC_KEY_REQUESTS.lock() {
        Ok(requests) => requests,
        Err(poisoned) => poisoned.into_inner(),
    };
    let key = (group_id.to_owned(), contact_id);
    let now = Instant::now();
    if !force
        && requests
            .get(&key)
            .is_some_and(|sent| now.duration_since(*sent) < PUBLIC_KEY_REQUEST_INTERVAL)
    {
        return false;
    }
    requests.insert(key, now);
    true
}

impl GroupService {
    pub async fn on_connected(&self) -> Result<()> {
        self.fetch_group_states_for_unjoined_groups().await?;
        self.fetch_missing_group_public_keys(None, false).await?;
        self.sync_flame_counters().await
    }

    async fn sync_flame_counters(&self) -> Result<()> {
        let db = self.ctx.app_db.read().await.clone();
        let groups = Group::flame_sync_candidates(&db.pool).await?;

        let Some(best_friend) = groups.iter().max_by_key(|group| group.total_media_counter) else {
            return Ok(());
        };

        let best_friend_id = best_friend.group_id.clone();
        let now = current_time().timestamp();
        let start_today = now - now.rem_euclid(86_400);

        for group in groups {
            let Some(changed) = group.last_flame_counter_change else {
                continue;
            };

            if changed < start_today
                || group
                    .last_flame_sync
                    .is_some_and(|sync| sync >= start_today)
            {
                continue;
            }

            if group.flame_counter <= 2 && group.group_id != best_friend_id {
                continue;
            }

            MessageService::new(&self.ctx)
                .send_to_group(
                    group.group_id.clone(),
                    EncryptedContent {
                        flame_sync: Some(encrypted_content::FlameSync {
                            flame_counter: group.flame_counter,
                            last_flame_counter_change: changed * 1000,
                            best_friend: group.group_id == best_friend_id,
                            force_update: false,
                        }),
                        ..Default::default()
                    }
                    .encode_to_vec(),
                    None,
                    false,
                )
                .await?;

            Group::set_last_flame_sync(&db.pool, &group.group_id, now).await?;
        }
        Ok(())
    }

    pub fn new(ctx: &Arc<Context>) -> Self {
        Self { ctx: ctx.clone() }
    }

    /// Repairs a group after a peer reported that it does not know the group.
    ///
    /// Owns its transaction instead of borrowing the inbound one: the refresh
    /// below reaches the group server, which must not happen while the single
    /// app-database connection is held.
    pub(crate) async fn handle_membership_error(
        &self,
        from_user_id: i64,
        group_id: String,
        related_receipt_id: String,
    ) -> Result<()> {
        let _ = self.fetch_group_state(group_id.clone()).await;

        let database = self.ctx.app_db.read().await.clone();
        let mut transaction = database.pool.begin().await?;
        let t = &mut transaction;

        let group = GroupRecord::load_in_transaction(t, &group_id).await?;
        let is_still_member = sqlx::query_scalar!(
            r#"SELECT EXISTS(
                SELECT 1 FROM group_members
                WHERE group_id = ? AND contact_id = ? AND member_state != 'leftGroup'
            )"#,
            group_id,
            from_user_id,
        )
        .fetch_one(&mut **t)
        .await?
            != 0;

        if is_still_member {
            queue_encrypted_content(
                t,
                from_user_id,
                EncryptedContent {
                    group_id: Some(group_id.clone()),
                    group_create: Some(encrypted_content::GroupCreate {
                        state_key: group.state_key()?.to_vec(),
                        group_public_key: group.identity()?.identity_key().serialize().to_vec(),
                        group_name: Some(group.group_name.clone()),
                    }),
                    ..Default::default()
                },
                true,
            )
            .await?;
        }

        let new_receipt_id = new_uuid_v4();
        sqlx::query!(
            r#"UPDATE receipts
               SET receipt_id = ?,
                   mark_for_retry = ?,
                   retry_count = retry_count + 1,
                   ack_by_server_at = NULL
               WHERE receipt_id = ? AND contact_id = ?"#,
            new_receipt_id,
            current_time().timestamp(),
            related_receipt_id,
            from_user_id,
        )
        .execute(&mut **t)
        .await?;

        transaction.commit().await?;
        Ok(())
    }

    pub async fn create_group(&self, group_name: String, member_ids: Vec<i64>) -> Result<bool> {
        let local = self.ctx.user_id().await?;
        let group_id = new_uuid_v4();
        let mut key = vec![0; 32];
        rand::rng().fill_bytes(&mut key);
        let mut rng = rand::rngs::StdRng::from_os_rng();
        let identity = libsignal_protocol::IdentityKeyPair::generate(&mut rng);
        let members: Vec<i64> = std::iter::once(local)
            .chain(member_ids.iter().copied())
            .collect::<BTreeSet<_>>()
            .into_iter()
            .collect();
        let group_state = EncryptedGroupState {
            member_ids: members,
            admin_ids: vec![local],
            group_name: group_name.clone(),
            delete_messages_after_milliseconds: Some(DEFAULT_DELETE_MS),
            padding: vec![],
        };

        GroupApi::create(NewGroupState {
            group_id: group_id.clone(),
            version_id: 1,
            encrypted_group_state: crypto::encrypt(&key, &group_state.encode_to_vec())?,
            public_key: identity.identity_key().serialize().to_vec(),
        })
        .await?;

        let db = self.ctx.app_db.read().await.clone();
        let mut tr = db.pool.begin().await?;
        let serialized_identity = identity.serialize().to_vec();
        InsertGroup::builder()
            .group_id(group_id.clone())
            .group_name(group_name.clone())
            .state_encryption_key(key.clone())
            .my_group_private_key(serialized_identity)
            .build()
            .execute(&mut tr)
            .await?;
        for id in member_ids {
            InsertGroupMember::builder()
                .group_id(group_id.clone())
                .contact_id(id)
                .member_state("normal".into())
                .build()
                .execute(&mut tr)
                .await?;
        }
        Self::history(&mut tr, &group_id, "createdGroup", None, None, None).await?;
        tr.commit().await?;
        MessageService::new(&self.ctx)
            .send_to_group(
                group_id.clone(),
                EncryptedContent {
                    group_create: Some(encrypted_content::GroupCreate {
                        state_key: key,
                        group_public_key: identity.identity_key().serialize().to_vec(),
                        group_name: Some(group_name),
                    }),
                    ..Default::default()
                }
                .encode_to_vec(),
                None,
                true,
            )
            .await?;
        Ok(true)
    }

    /// Refreshes one group from the group server.
    ///
    /// The round-trip happens before the transaction opens, under the group's
    /// [`group_state_lock`]. The app database allows a single connection, so
    /// holding it across network I/O starves every other database user until
    /// the acquire timeout and surfaces as `pool timed out while waiting for an
    /// open connection`.
    pub async fn fetch_group_state(&self, group_id: String) -> Result<bool> {
        let lock = group_state_lock(&group_id);
        let _guard = lock.lock().await;

        let server = GroupApi::fetch_group_state(&group_id).await?;

        let database = self.ctx.app_db.read().await.clone();
        let mut t = database.pool.begin().await?;
        let (updated, compaction) = self
            .apply_fetched_group_state(&mut t, &group_id, server)
            .await?;
        t.commit().await?;

        if let Some(compaction) = compaction {
            // Every admin that reads the same leave-append folds it away, and
            // the group server takes whichever gets there first. A rejection
            // means another admin already did the work, so the state this
            // refresh applied stands either way and the next refresh reads the
            // folded version.
            if let Err(error) = GroupApi::update_remote(
                &compaction.group,
                compaction.version_id,
                &compaction.state,
                None,
                None,
            )
            .await
            {
                tracing::warn!(group_id, %error, "group-state compaction was not accepted");
            }
        }

        // `apply_state` may have queued public-key requests. Nothing else
        // flushes them here -- this is not an inbound-message path -- and they
        // would otherwise wait for the next reconnect.
        let ctx = self.ctx.clone();
        tokio::spawn(async move {
            if let Err(error) = retransmit_queued_receipts(&ctx).await {
                tracing::warn!("failed to flush messages queued by a group refresh: {error}");
            }
        });

        Ok(updated)
    }

    /// Applies a group state that has already been fetched. Database work
    /// only: the admin-side compaction of leave-appends is handed back to the
    /// caller instead of sent from here, because it is a network round trip
    /// and this runs while the caller holds the app database's one connection.
    async fn apply_fetched_group_state(
        &self,
        t: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
        group_id: &str,
        server: Option<crate::api::proto::http_requests::GroupState>,
    ) -> Result<(bool, Option<PendingCompaction>)> {
        let group = GroupRecord::load_in_transaction(t, group_id).await?;
        let Some(server) = server else {
            UpdateGroup::builder()
                .group_id(group_id.to_owned())
                .left_group(true)
                .build()
                .execute(t)
                .await?;
            return Ok((false, None));
        };
        let state_key = group.state_key()?;
        let raw = crypto::decrypt(state_key, &server.encrypted_group_state)?;
        let mut group_state = EncryptedGroupState::decode(raw.as_slice())
            .map_err(|error| TwonlyError::Generic(error.to_string()))?;
        let local_user_id = self.ctx.user_id().await?;
        let local_public_key = group.identity()?.identity_key().serialize();
        let mut appended_changes = false;
        // Every step below that touches `appended` skips the entry instead of
        // returning. The group server accepts appends without checking group
        // membership, and it stores them forever, so one malformed entry would
        // otherwise break this group's state sync on every later refresh.
        for appended in &server.appended_group_states {
            let Some(tbs) = &appended.append_tbs else {
                continue;
            };
            // Resolve the author first: an append signed by a key that is not a
            // member of this group is dropped before any of its bytes are parsed.
            let leaving_id = if tbs.public_key.as_slice() == local_public_key.as_ref() {
                Some(local_user_id)
            } else {
                sqlx::query_scalar!(
                    "SELECT contact_id FROM group_members WHERE group_id = ? AND group_public_key = ?",
                    group_id,
                    tbs.public_key,
                )
                .fetch_optional(&mut **t)
                .await?
            };
            let Some(leaving_id) = leaving_id else {
                tracing::warn!(group_id, "ignored group-state append from a non-member");
                continue;
            };
            let Ok(public_key) = libsignal_protocol::PublicKey::try_from(tbs.public_key.as_slice())
            else {
                tracing::warn!(group_id, "ignored group-state append with an unusable key");
                continue;
            };
            if !public_key.verify_signature(&tbs.encode_to_vec(), &appended.signature) {
                tracing::warn!(
                    group_id,
                    "ignored group-state append with invalid signature"
                );
                continue;
            }
            let raw = match crypto::decrypt(state_key, &tbs.encrypted_group_state_append) {
                Ok(raw) => raw,
                Err(error) => {
                    tracing::warn!(group_id, %error, "ignored undecryptable group-state append");
                    continue;
                }
            };
            let Ok(append) = EncryptedAppendedGroupState::decode(raw.as_slice()) else {
                tracing::warn!(
                    group_id,
                    "ignored group-state append with an invalid payload"
                );
                continue;
            };
            if append.r#type != encrypted_appended_group_state::Type::LeftGroup as i32 {
                continue;
            }
            group_state.member_ids.retain(|id| *id != leaving_id);
            group_state.admin_ids.retain(|id| *id != leaving_id);
            appended_changes = true;
        }
        let compaction =
            (appended_changes & group_state.admin_ids.contains(&local_user_id)).then(|| {
                PendingCompaction {
                    group: group.clone(),
                    version_id: server.version_id,
                    state: group_state.clone(),
                }
            });
        self.apply_state(t, group_id, server.version_id as i64, &group_state)
            .await?;
        Ok((true, compaction))
    }

    /// Reads the group state, applies `change`, and writes it back, re-reading
    /// and re-applying while the group server rejects the write as stale.
    ///
    /// The server accepts an update only against the version it currently
    /// holds, so two admins acting at once -- or one racing the compaction a
    /// member's leave-append triggers -- leave the loser holding a state the
    /// server has already moved past. The loser's intent is still valid; only
    /// the version it was expressed against is not. That is why `change` is a
    /// function of the state rather than a finished state: it can simply be
    /// applied again to the version that won.
    ///
    /// `change` returning `None` means there is nothing left to write.
    async fn update_state_with_retry(
        &self,
        group: &GroupRecord,
        mut change: impl FnMut(&mut EncryptedGroupState) -> Result<Option<AdminKeys>>,
    ) -> Result<()> {
        let mut attempt = 1;
        loop {
            let (version, mut state) = GroupApi::load_state(group).await?;
            let Some(keys) = change(&mut state)? else {
                return Ok(());
            };
            match GroupApi::update_remote(group, version, &state, keys.add, keys.remove).await {
                Ok(()) => return Ok(()),
                Err(TwonlyError::GroupStateConflict) if attempt < STATE_UPDATE_ATTEMPTS => {
                    attempt += 1;
                    tracing::info!(
                        group_id = group.group_id,
                        attempt,
                        "group state moved on while updating it, applying the change again"
                    );
                }
                Err(error) => return Err(error),
            }
        }
    }

    pub async fn update_group_name(&self, group_id: String, name: String) -> Result<bool> {
        let (db, g) = self.load_group(&group_id).await?;
        self.update_state_with_retry(&g, |state| {
            state.group_name = name.clone();
            Ok(Some(AdminKeys::default()))
        })
        .await?;
        self.announce(
            &group_id,
            "updatedGroupName",
            None,
            Some(name.clone()),
            None,
        )
        .await?;
        let mut tr = db.pool.begin().await?;
        Self::history(
            &mut tr,
            &group_id,
            "updatedGroupName",
            None,
            Some(&name),
            None,
        )
        .await?;
        tr.commit().await?;
        self.fetch_group_state(group_id).await
    }

    pub async fn update_chat_deletion_time(&self, group_id: String, ms: i64) -> Result<bool> {
        let (db, g) = self.load_group(&group_id).await?;
        self.update_state_with_retry(&g, |state| {
            state.delete_messages_after_milliseconds = Some(ms);
            Ok(Some(AdminKeys::default()))
        })
        .await?;
        self.announce(&group_id, "changeDisplayMaxTime", None, None, Some(ms))
            .await?;
        let mut tr = db.pool.begin().await?;
        Self::history(
            &mut tr,
            &group_id,
            "changeDisplayMaxTime",
            None,
            None,
            Some(ms),
        )
        .await?;
        tr.commit().await?;
        self.fetch_group_state(group_id).await
    }

    /// Resolves the group public key a member signs its group-state appends
    /// with. Our own key lives in the group record; everyone else's arrives
    /// through `group_join` and may still be missing.
    async fn member_public_key(
        &self,
        db: &Arc<crate::database::app::AppDatabase>,
        group: &GroupRecord,
        group_id: &str,
        contact_id: i64,
    ) -> Result<Vec<u8>> {
        if contact_id == self.ctx.user_id().await? {
            return Ok(group.identity()?.identity_key().serialize().to_vec());
        }
        GetGroupPublicKey::builder()
            .group_id(group_id.to_owned())
            .contact_id(contact_id)
            .build()
            .fetch_pool(&db.pool)
            .await?
            .ok_or_else(|| {
                TwonlyError::Generic(format!(
                    "group public key for contact {contact_id} not found"
                ))
            })
    }

    pub async fn manage_admin(
        &self,
        group_id: String,
        contact_id: i64,
        remove: bool,
    ) -> Result<bool> {
        let (db, g) = self.load_group(&group_id).await?;

        let public_key = self
            .member_public_key(&db, &g, &group_id, contact_id)
            .await?;

        let kind = if remove {
            "demoteToMember"
        } else {
            "promoteToAdmin"
        };
        self.update_state_with_retry(&g, |state| {
            if remove {
                state.admin_ids.retain(|x| *x != contact_id)
            } else if !state.admin_ids.contains(&contact_id) {
                state.admin_ids.push(contact_id)
            };
            Ok(Some(AdminKeys {
                add: (!remove).then(|| public_key.clone()),
                remove: remove.then(|| public_key.clone()),
            }))
        })
        .await?;
        self.announce(&group_id, kind, Some(contact_id), None, None)
            .await?;
        let mut tr = db.pool.begin().await?;
        Self::history(&mut tr, &group_id, kind, Some(contact_id), None, None).await?;
        tr.commit().await?;
        self.fetch_group_state(group_id).await
    }

    pub async fn add_members(&self, group_id: String, ids: Vec<i64>) -> Result<bool> {
        let (db, g) = self.load_group(&group_id).await?;
        self.update_state_with_retry(&g, |state| {
            for id in &ids {
                if !state.member_ids.contains(id) {
                    state.member_ids.push(*id)
                }
            }
            Ok(Some(AdminKeys::default()))
        })
        .await?;
        let identity = g.identity()?;
        for id in ids {
            self.announce(&group_id, "addMember", Some(id), None, None)
                .await?;
            let mut tr = db.pool.begin().await?;
            Self::history(&mut tr, &group_id, "addMember", Some(id), None, None).await?;
            tr.commit().await?;
            send_c2c_message_to_contact()
                .ctx(&self.ctx)
                .contact_id(id)
                .encrypted_content(
                    EncryptedContent {
                        group_id: Some(group_id.clone()),
                        group_create: Some(encrypted_content::GroupCreate {
                            state_key: g.state_key()?.to_vec(),
                            group_public_key: identity.identity_key().serialize().to_vec(),
                            group_name: Some(g.group_name.clone()),
                        }),
                        ..Default::default()
                    }
                    .encode_to_vec(),
                )
                .call()
                .await?;
        }
        self.fetch_group_state(group_id).await
    }

    /// Removes a member from the group.
    ///
    /// The member's group public key is only needed to revoke an admin's
    /// signing rights, so a plain member can be removed without it. That
    /// matters: a key that never arrived would otherwise make the member
    /// unremovable.
    pub async fn remove_member(&self, group_id: String, contact_id: i64) -> Result<bool> {
        let (db, g) = self.load_group(&group_id).await?;
        // Looked up before the state is read so the change below stays a plain
        // function of it. A member who is not an admin never has this key
        // consulted, which is what keeps one that never arrived from making
        // them unremovable.
        let public_key = self
            .member_public_key(&db, &g, &group_id, contact_id)
            .await
            .ok();
        self.update_state_with_retry(&g, |state| {
            if !state.member_ids.contains(&contact_id) {
                return Ok(None);
            }
            state.member_ids.retain(|x| *x != contact_id);
            let was_admin = state.admin_ids.contains(&contact_id);
            state.admin_ids.retain(|x| *x != contact_id);
            if !was_admin {
                return Ok(Some(AdminKeys::default()));
            }
            let revoked = public_key.clone().ok_or_else(|| {
                TwonlyError::Generic(format!(
                    "group public key for contact {contact_id} not found"
                ))
            })?;
            Ok(Some(AdminKeys {
                add: None,
                remove: Some(revoked),
            }))
        })
        .await?;
        self.announce(&group_id, "removedMember", Some(contact_id), None, None)
            .await?;
        let mut tr = db.pool.begin().await?;
        Self::history(
            &mut tr,
            &group_id,
            "removedMember",
            Some(contact_id),
            None,
            None,
        )
        .await?;
        tr.commit().await?;
        self.fetch_group_state(group_id).await
    }

    pub async fn leave_group(&self, group_id: String) -> Result<bool> {
        let (db, group) = self.load_group(&group_id).await?;
        let user_id = self.ctx.user_id().await?;
        let (_, group_state) = GroupApi::load_state(&group).await?;
        if group_state.admin_ids.contains(&user_id) {
            return self.remove_member(group_id, user_id).await;
        }

        let identity = group.identity()?;
        let public_key = identity.identity_key().serialize().to_vec();
        let append = EncryptedAppendedGroupState {
            r#type: encrypted_appended_group_state::Type::LeftGroup as i32,
        };
        let append_tbs = append_group_state::AppendTbs {
            encrypted_group_state_append: crypto::encrypt(
                group.state_key()?,
                &append.encode_to_vec(),
            )?,
            public_key: public_key.clone(),
            group_id: group_id.clone(),
            nonce: GroupApi::get_challenge(&public_key).await?,
        };
        let mut rng = rand::rngs::StdRng::from_os_rng();
        let signature = identity
            .private_key()
            .calculate_signature(&append_tbs.encode_to_vec(), &mut rng)
            .map_err(|error| TwonlyError::Signal(error.to_string()))?
            .into_vec();
        GroupApi::append(AppendGroupState {
            signature,
            append_tbs: Some(append_tbs),
            version_id: group.state_version_id as u64 + 1,
        })
        .await?;
        self.announce(&group_id, "leftGroup", None, None, None)
            .await?;
        let mut tr = db.pool.begin().await?;
        Self::history(&mut tr, &group_id, "leftGroup", None, None, None).await?;
        UpdateGroup::builder()
            .group_id(group_id.clone())
            .left_group(true)
            .build()
            .execute(&mut tr)
            .await?;
        tr.commit().await?;
        Ok(true)
    }

    pub async fn add_hidden_contact(&self, contact_id: i64) -> Result<bool> {
        let user = match Server::get_user_by_id(&self.ctx, contact_id).await? {
            ServerResult::Ok(u) => u,
            ServerResult::ErrorCode(code) => {
                return Err(TwonlyError::Generic(format!(
                    "Failed to get user by id: {}",
                    code
                )));
            }
        };
        let username = String::from_utf8(
            user.username
                .ok_or_else(|| TwonlyError::Generic("user response has no username".into()))?,
        )?;
        let database = self.ctx.app_db.read().await.clone();
        let mut tr = database.pool.begin().await?;
        UpdateContact::builder()
            .user_id(contact_id)
            .username(username)
            .deleted_by_user(true)
            .build()
            .insert_on_conflict_update(&mut tr)
            .await?;
        tr.commit().await?;
        Ok(true)
    }

    /// Refreshes one group and then announces our own group public key to it.
    ///
    /// The order matters: `broadcast_group_public_key` resolves its recipients
    /// from `group_members`, which holds nothing but the sender of the
    /// `group_create` until the refresh fills in the rest of the group.
    /// Announcing first would reach that one member and leave every other
    /// member unable to promote or remove us. The announcement still runs when
    /// the refresh fails, so an offline group server costs reach, not delivery.
    pub fn spawn_state_refresh_and_announce(ctx: &Arc<Context>, group_id: String) {
        let ctx = ctx.clone();
        tokio::spawn(async move {
            let service = Self::new(&ctx);
            if let Err(error) = service.fetch_group_state(group_id.clone()).await {
                tracing::warn!(
                    group_id,
                    "group state refresh before announce failed: {error}"
                );
            }
            if let Err(error) = service.announce_group_public_key(&group_id).await {
                tracing::warn!(group_id, "group public key announcement failed: {error}");
            }
        });
    }

    /// Sends our group public key to every current member of `group_id`.
    async fn announce_group_public_key(&self, group_id: &str) -> Result<()> {
        let database = self.ctx.app_db.read().await.clone();
        let mut transaction = database.pool.begin().await?;
        self.broadcast_group_public_key(&mut transaction, group_id)
            .await?;
        transaction.commit().await?;
        Ok(())
    }

    /// Schedules the server-side half of a group refresh.
    ///
    /// Callers reach this from inside the inbound transaction, and a refresh
    /// talks to the group server, so it cannot run there: it would pin the only
    /// app-database connection across the network and, once it takes a group
    /// lock, invert the lock order this module depends on. Running it detached
    /// lets the caller commit first; every call site treats the refresh as best
    /// effort already.
    pub fn spawn_state_refresh(ctx: &Arc<Context>, group_id: Option<String>) {
        let ctx = ctx.clone();
        tokio::spawn(async move {
            let service = Self::new(&ctx);
            let result = match group_id {
                Some(group_id) => service.fetch_group_state(group_id).await.map(|_| ()),
                None => service.fetch_group_states_for_unjoined_groups().await,
            };
            if let Err(error) = result {
                tracing::warn!("scheduled group state refresh failed: {error}");
            }
        });
    }

    pub async fn broadcast_group_public_key(
        &self,
        tr: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
        group_id: &str,
    ) -> Result<()> {
        let group = sqlx::query!(
            "SELECT my_group_private_key FROM groups WHERE group_id = ?",
            group_id
        )
        .fetch_optional(&mut **tr)
        .await
        .ok()
        .flatten();

        if let Some(record) = group {
            if let Some(private_key) = record.my_group_private_key {
                if let Ok(identity) =
                    libsignal_protocol::IdentityKeyPair::try_from(private_key.as_slice())
                {
                    let content = EncryptedContent {
                        group_join: Some(GroupJoin {
                            group_public_key: identity.identity_key().serialize().to_vec(),
                        }),
                        ..Default::default()
                    };
                    let _ = MessageService::new(&self.ctx)
                        .send_to_group_in_transaction(
                            tr,
                            group_id.to_string(),
                            content.encode_to_vec(),
                            None,
                            false,
                        )
                        .await;
                }
            }
        }
        Ok(())
    }

    /// Refreshes every group this client has not joined yet.
    ///
    /// The ids are read on their own connection and each group is then
    /// refreshed by [`Self::fetch_group_state`], so no connection is held
    /// across the per-group round-trips.
    pub async fn fetch_group_states_for_unjoined_groups(&self) -> Result<()> {
        let db = self.ctx.app_db.read().await.clone();
        let ids = GetUnjoinedGroups::builder()
            .build()
            .fetch_all(&db.pool)
            .await?;
        for id in ids {
            if let Err(e) = self.fetch_group_state(id.clone()).await {
                tracing::warn!(group_id = id, "group state refresh failed: {e}")
            }
        }
        Ok(())
    }

    /// Asks every member whose group public key is still unknown to resend it.
    ///
    /// Without the key an admin cannot promote or remove that member, because
    /// the group server needs it to authorize the member's future signed
    /// appends. Pass a `group_id` to limit the sweep to one group, and `force`
    /// to ignore [`PUBLIC_KEY_REQUEST_INTERVAL`] -- the group view does, so the
    /// user always has a way to retry by hand.
    pub async fn fetch_missing_group_public_keys(
        &self,
        group_id: Option<String>,
        force: bool,
    ) -> Result<()> {
        let db = self.ctx.app_db.read().await.clone();
        let rows = GetMissingGroupPublicKeys::builder()
            .maybe_group_id(group_id)
            .build()
            .fetch_all(&db.pool)
            .await?;
        for row in rows {
            if !claim_public_key_request(&row.group_id, row.contact_id, force) {
                continue;
            }
            send_c2c_message_to_contact()
                .ctx(&self.ctx)
                .contact_id(row.contact_id)
                .encrypted_content(
                    EncryptedContent {
                        group_id: Some(row.group_id),
                        resend_group_public_key: Some(encrypted_content::ResendGroupPublicKey {}),
                        ..Default::default()
                    }
                    .encode_to_vec(),
                )
                .call()
                .await?;
        }
        Ok(())
    }

    /// Same request, queued inside the caller's transaction.
    ///
    /// [`Self::fetch_missing_group_public_keys`] sends immediately, which needs
    /// its own database access and so cannot run while a transaction holds the
    /// single app-database connection.
    async fn queue_missing_group_public_key_requests(
        t: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
        group_id: &str,
    ) -> Result<()> {
        let rows = GetMissingGroupPublicKeys::builder()
            .group_id(group_id.to_owned())
            .build()
            .fetch_all_in_transaction(t)
            .await?;
        for row in rows {
            if !claim_public_key_request(&row.group_id, row.contact_id, false) {
                continue;
            }
            queue_encrypted_content(
                t,
                row.contact_id,
                EncryptedContent {
                    group_id: Some(row.group_id),
                    resend_group_public_key: Some(encrypted_content::ResendGroupPublicKey {}),
                    ..Default::default()
                },
                true,
            )
            .await?;
        }
        Ok(())
    }

    // --- Private helpers ---

    async fn load_group(
        &self,
        group_id: &str,
    ) -> Result<(Arc<crate::database::app::AppDatabase>, GroupRecord)> {
        let db = self.ctx.app_db.read().await.clone();
        let row = GroupRecord::load(&db.pool, group_id).await?;
        Ok((db, row))
    }

    async fn announce(
        &self,
        group_id: &str,
        action: &str,
        affected: Option<i64>,
        name: Option<String>,
        delete_ms: Option<i64>,
    ) -> Result<()> {
        MessageService::new(&self.ctx)
            .send_to_group(
                group_id.into(),
                EncryptedContent {
                    group_update: Some(encrypted_content::GroupUpdate {
                        group_action_type: action.into(),
                        affected_contact_id: affected,
                        new_group_name: name,
                        new_delete_messages_after_milliseconds: delete_ms,
                    }),
                    ..Default::default()
                }
                .encode_to_vec(),
                None,
                false,
            )
            .await
    }

    async fn history(
        t: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
        group_id: &str,
        kind: &str,
        affected: Option<i64>,
        name: Option<&str>,
        delete_ms: Option<i64>,
    ) -> Result<()> {
        InsertGroupHistory::builder()
            .group_id(group_id.to_string())
            .r#type(kind.to_string())
            .maybe_affected_contact_id(affected)
            .maybe_new_group_name(name.map(|n| n.to_string()))
            .maybe_new_delete_messages_after_milliseconds(delete_ms)
            .build()
            .execute(t)
            .await?;
        Ok(())
    }

    async fn apply_state(
        &self,
        t: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
        group_id: &str,
        version: i64,
        group_state: &EncryptedGroupState,
    ) -> Result<()> {
        let local_user_id = self.ctx.user_id().await?;
        let joined = group_state.member_ids.contains(&local_user_id);
        let admin = group_state.admin_ids.contains(&local_user_id);

        UpdateGroup::builder()
            .group_id(group_id.to_string())
            .group_name(group_state.group_name.clone())
            .delete_messages_after_milliseconds(group_state.delete_messages_after_milliseconds)
            .is_group_admin(admin)
            .joined_group(joined)
            .left_group(!joined)
            .state_version_id(version as u64)
            .build()
            .execute(t)
            .await?;

        UpdateGroupMemberState::builder()
            .group_id(group_id.to_string())
            .member_state("leftGroup".into())
            .build()
            .execute(t)
            .await?;

        for &contact_id in &group_state.member_ids {
            if contact_id == local_user_id {
                continue;
            }

            let exists = Contact::exists(t, contact_id).await?;

            if !exists {
                let user = match Server::get_user_by_id(&self.ctx, contact_id).await? {
                    ServerResult::Ok(u) => u,
                    ServerResult::ErrorCode(code) => {
                        return Err(TwonlyError::Generic(format!(
                            "Failed to get user by id: {}",
                            code
                        )));
                    }
                };
                let username = String::from_utf8(user.username.ok_or_else(|| {
                    TwonlyError::Generic("user response has no username".into())
                })?)?;
                UpdateContact::builder()
                    .user_id(contact_id)
                    .username(username)
                    .deleted_by_user(true)
                    .build()
                    .insert_on_conflict_update(t)
                    .await?;
            }

            let member_state = if group_state.admin_ids.contains(&contact_id) {
                "admin"
            } else {
                "normal"
            };

            InsertGroupMember::builder()
                .group_id(group_id.to_string())
                .contact_id(contact_id)
                .member_state(member_state.into())
                .on_conflict_update(true)
                .build()
                .execute(t)
                .await?;
        }

        // The server state carries member ids but no per-member keys, and a
        // member announces its own key only once, when it first learns the
        // group exists -- so nobody announces themselves to a member who joined
        // later. Asking here is what closes that gap for both sides: whoever
        // refreshes first discovers the other with an empty key and requests it.
        Self::queue_missing_group_public_key_requests(t, group_id).await?;

        Ok(())
    }
}
