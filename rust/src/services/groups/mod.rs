/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

pub(crate) mod crypto;
pub(crate) mod model;

use crate::api::groups::GroupApi;
use crate::api::messages::incoming::client2client::messages::queue_encrypted_content;
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
    Contact, GetGroupPublicKey, GetMissingGroupPublicKeys, GetUnjoinedGroups, InsertGroup,
    InsertGroupHistory, InsertGroupMember, UpdateContact, UpdateGroup, UpdateGroupMemberState,
};
use crate::error::{Result, TwonlyError};
use crate::services::messages::MessageService;
use crate::utils::{current_time, new_uuid_v4};
use model::GroupRecord;
use prost::Message;
use rand::{RngCore, SeedableRng};
use std::collections::BTreeSet;
use std::sync::Arc;

const DEFAULT_DELETE_MS: i64 = 86_400_000;

pub struct GroupService {
    ctx: Arc<Context>,
}

impl GroupService {
    pub fn new(ctx: &Arc<Context>) -> Self {
        Self { ctx: ctx.clone() }
    }

    pub(crate) async fn handle_membership_error(
        &self,
        t: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
        from_user_id: i64,
        group_id: String,
        related_receipt_id: String,
    ) -> Result<()> {
        if !self.fetch_group_state_in_transaction(t, &group_id).await? {
            return Ok(());
        }

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
                        group_name: None,
                    }),
                    ..Default::default()
                },
                true,
            )
            .await?;
        }

        sqlx::query!(
            r#"UPDATE receipts
               SET mark_for_retry = ?, retry_count = retry_count + 1
               WHERE receipt_id = ? AND contact_id = ?"#,
            current_time().timestamp(),
            related_receipt_id,
            from_user_id,
        )
        .execute(&mut **t)
        .await?;
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

        let db = self.ctx.get_app_database().await;
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
        db.notify_committed(["groups", "group_members", "group_histories"]);
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

    pub async fn fetch_group_state(&self, group_id: String) -> Result<bool> {
        let database = self.ctx.get_app_database().await;
        let mut t = database.pool.begin().await?;
        let updated = self
            .fetch_group_state_in_transaction(&mut t, &group_id)
            .await?;
        t.commit().await?;
        database.notify_committed(["groups", "group_members", "contacts"]);
        Ok(updated)
    }

    async fn fetch_group_state_in_transaction(
        &self,
        t: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
        group_id: &str,
    ) -> Result<bool> {
        let group = GroupRecord::load_in_transaction(t, group_id).await?;
        let Some(server) = GroupApi::fetch_group_state(&group_id).await? else {
            UpdateGroup::builder()
                .group_id(group_id.to_owned())
                .left_group(true)
                .build()
                .execute(t)
                .await?;
            return Ok(false);
        };
        let raw = crypto::decrypt(group.state_key()?, &server.encrypted_group_state)?;
        let mut group_state = EncryptedGroupState::decode(raw.as_slice())
            .map_err(|error| TwonlyError::Generic(error.to_string()))?;
        let mut appended_changes = false;
        for appended in &server.appended_group_states {
            let Some(tbs) = &appended.append_tbs else {
                continue;
            };
            let public_key = libsignal_protocol::PublicKey::try_from(tbs.public_key.as_slice())
                .map_err(|error| TwonlyError::Signal(error.to_string()))?;
            if !public_key.verify_signature(&tbs.encode_to_vec(), &appended.signature) {
                tracing::warn!(
                    group_id,
                    "ignored group-state append with invalid signature"
                );
                continue;
            }
            let raw = crypto::decrypt(group.state_key()?, &tbs.encrypted_group_state_append)?;
            let append = EncryptedAppendedGroupState::decode(raw.as_slice())
                .map_err(|error| TwonlyError::Generic(error.to_string()))?;
            if append.r#type != encrypted_appended_group_state::Type::LeftGroup as i32 {
                continue;
            }
            let local_public_key = group.identity()?.identity_key().serialize();
            let leaving_id = if tbs.public_key.as_slice() == local_public_key.as_ref() {
                Some(self.ctx.user_id().await?)
            } else {
                sqlx::query_scalar!(
                    "SELECT contact_id FROM group_members WHERE group_id = ? AND group_public_key = ?",
                    group_id,
                    tbs.public_key,
                )
                .fetch_optional(&mut **t)
                .await?
            };
            if let Some(leaving_id) = leaving_id {
                group_state.member_ids.retain(|id| *id != leaving_id);
                group_state.admin_ids.retain(|id| *id != leaving_id);
                appended_changes = true;
            }
        }
        if appended_changes && group_state.admin_ids.contains(&self.ctx.user_id().await?) {
            GroupApi::update_remote(&group, server.version_id, &group_state, None, None).await?;
        }
        self.apply_state(t, group_id, server.version_id as i64, &group_state)
            .await?;
        Ok(true)
    }

    pub async fn update_group_name(&self, group_id: String, name: String) -> Result<bool> {
        let (db, g) = self.load_group(&group_id).await?;
        let (v, mut s) = GroupApi::load_state(&g).await?;
        s.group_name = name.clone();
        GroupApi::update_remote(&g, v, &s, None, None).await?;
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
        let (v, mut s) = GroupApi::load_state(&g).await?;
        s.delete_messages_after_milliseconds = Some(ms);
        GroupApi::update_remote(&g, v, &s, None, None).await?;
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

    pub async fn manage_admin(
        &self,
        group_id: String,
        contact_id: i64,
        remove: bool,
    ) -> Result<bool> {
        let (db, g) = self.load_group(&group_id).await?;
        let (v, mut s) = GroupApi::load_state(&g).await?;

        let public_key = GetGroupPublicKey::builder()
            .group_id(group_id.clone())
            .contact_id(contact_id)
            .build()
            .fetch_pool(&db.pool)
            .await?
            .ok_or_else(|| {
                TwonlyError::Generic(format!(
                    "group public key for contact {contact_id} not found"
                ))
            })?;

        if remove {
            s.admin_ids.retain(|x| *x != contact_id)
        } else if !s.admin_ids.contains(&contact_id) {
            s.admin_ids.push(contact_id)
        };
        let kind = if remove {
            "demoteToMember"
        } else {
            "promoteToAdmin"
        };
        GroupApi::update_remote(
            &g,
            v,
            &s,
            (!remove).then_some(public_key.clone()),
            remove.then_some(public_key),
        )
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
        let (v, mut s) = GroupApi::load_state(&g).await?;
        for id in &ids {
            if !s.member_ids.contains(id) {
                s.member_ids.push(*id)
            }
        }
        GroupApi::update_remote(&g, v, &s, None, None).await?;
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

    pub async fn remove_member(
        &self,
        group_id: String,
        public_key: Vec<u8>,
        contact_id: i64,
    ) -> Result<bool> {
        let (db, g) = self.load_group(&group_id).await?;
        let (v, mut s) = GroupApi::load_state(&g).await?;
        if !s.member_ids.contains(&contact_id) {
            return Ok(true);
        }
        s.member_ids.retain(|x| *x != contact_id);
        let was_admin = s.admin_ids.contains(&contact_id);
        s.admin_ids.retain(|x| *x != contact_id);
        GroupApi::update_remote(&g, v, &s, None, was_admin.then_some(public_key)).await?;
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
        db.notify_committed(["groups", "group_histories"]);
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
        let database = self.ctx.get_app_database().await;
        let mut tr = database.pool.begin().await?;
        UpdateContact::builder()
            .user_id(contact_id)
            .username(username)
            .deleted_by_user(true)
            .build()
            .insert_on_conflict_update(&mut tr)
            .await?;
        tr.commit().await?;
        database.notify_committed(["contacts"]);
        Ok(true)
    }

    pub async fn refresh_group_state(
        &self,
        tr: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
        group_id: String,
        created: bool,
    ) {
        if created {
            let _ = self
                .fetch_group_states_for_unjoined_groups_in_transaction(tr)
                .await;
            let _ = self.broadcast_group_public_key(tr, &group_id).await;
        } else {
            let _ = self.fetch_group_state_in_transaction(tr, &group_id).await;
        }
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

    pub async fn fetch_group_states_for_unjoined_groups(&self) -> Result<()> {
        let db = self.ctx.get_app_database().await;
        let mut t = db.pool.begin().await?;
        self.fetch_group_states_for_unjoined_groups_in_transaction(&mut t)
            .await?;
        t.commit().await?;
        Ok(())
    }

    pub async fn fetch_group_states_for_unjoined_groups_in_transaction(
        &self,
        t: &mut sqlx::Transaction<'_, sqlx::Sqlite>,
    ) -> Result<()> {
        let ids = GetUnjoinedGroups::builder()
            .build()
            .fetch_all(&mut **t)
            .await?;
        for id in ids {
            if let Err(e) = self.fetch_group_state_in_transaction(t, &id).await {
                tracing::warn!(group_id = id, "group state refresh failed: {e}")
            }
        }
        Ok(())
    }

    pub async fn fetch_missing_group_public_keys(&self) -> Result<()> {
        let db = self.ctx.get_app_database().await;
        let rows = GetMissingGroupPublicKeys::builder()
            .build()
            .fetch_all(&db.pool)
            .await?;
        for row in rows {
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

    // --- Private helpers ---

    async fn load_group(
        &self,
        group_id: &str,
    ) -> Result<(Arc<crate::database::app::AppDatabase>, GroupRecord)> {
        let db = self.ctx.get_app_database().await;
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
        Ok(())
    }
}
