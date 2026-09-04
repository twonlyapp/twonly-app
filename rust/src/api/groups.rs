/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use crate::api::proto::client::EncryptedGroupState;
use crate::api::proto::http_requests::update_group_state;
use crate::api::proto::http_requests::{
    AppendGroupState, GroupState, NewGroupState, UpdateGroupState,
};
use crate::bridge::api::RustApi;
use crate::error::{Result, TwonlyError};
use crate::services::groups::crypto;
use crate::services::groups::model::GroupRecord;
use prost::Message;
use rand::SeedableRng;

pub struct GroupApi;

impl GroupApi {
    pub(crate) async fn fetch_group_state(group_id: &str) -> Result<Option<GroupState>> {
        let response = client()?
            .get(url(&format!("state/{group_id}")))
            .send()
            .await
            .map_err(|e| TwonlyError::Generic(e.to_string()))?;
        if response.status() == reqwest::StatusCode::NOT_FOUND {
            return Ok(None);
        }

        if !response.status().is_success() {
            return Err(TwonlyError::Generic(format!(
                "group state returned {}",
                response.status()
            )));
        }

        Ok(Some(
            GroupState::decode(
                response
                    .bytes()
                    .await
                    .map_err(|e| TwonlyError::Generic(e.to_string()))?,
            )
            .map_err(|e| TwonlyError::Generic(e.to_string()))?,
        ))
    }

    pub(crate) async fn update_remote(
        group: &GroupRecord,
        version: u64,
        state: &EncryptedGroupState,
        add_admin: Option<Vec<u8>>,
        remove_admin: Option<Vec<u8>>,
    ) -> Result<()> {
        let identity = group.identity()?;
        let public_key = identity.identity_key().serialize().to_vec();
        let update = update_group_state::UpdateTbs {
            version_id: version + 1,
            encrypted_group_state: crypto::encrypt(group.state_key()?, &state.encode_to_vec())?,
            public_key: public_key.clone(),
            remove_admin,
            add_admin,
            nonce: Self::get_challenge(&public_key).await?,
        };
        let mut rng = rand::rngs::StdRng::from_os_rng();
        let signature = identity
            .private_key()
            .calculate_signature(&update.encode_to_vec(), &mut rng)
            .map_err(|e| TwonlyError::Signal(e.to_string()))?
            .into_vec();
        update_state(UpdateGroupState {
            update: Some(update),
            signature,
        })
        .await
    }

    pub(crate) async fn load_state(group: &GroupRecord) -> Result<(u64, EncryptedGroupState)> {
        let server = GroupApi::fetch_group_state(&group.group_id)
            .await?
            .ok_or_else(|| TwonlyError::Generic("group state does not exist".into()))?;
        let raw = crypto::decrypt(group.state_key()?, &server.encrypted_group_state)?;
        Ok((
            server.version_id,
            EncryptedGroupState::decode(raw.as_slice())
                .map_err(|error| TwonlyError::Generic(error.to_string()))?,
        ))
    }

    pub(crate) async fn create(value: NewGroupState) -> Result<()> {
        success(
            client()?
                .post(url("state"))
                .body(value.encode_to_vec())
                .send()
                .await
                .map_err(|e| TwonlyError::Generic(e.to_string()))?,
        )
        .await
    }
    pub(crate) async fn append(value: AppendGroupState) -> Result<()> {
        success(
            client()?
                .post(url("state/append"))
                .body(value.encode_to_vec())
                .send()
                .await
                .map_err(|e| TwonlyError::Generic(e.to_string()))?,
        )
        .await
    }

    pub(crate) async fn get_challenge(public_key: &[u8]) -> Result<Vec<u8>> {
        let response = client()?
            .get(url(&format!("challenge/{}", hex::encode(public_key))))
            .send()
            .await
            .map_err(|e| TwonlyError::Generic(e.to_string()))?;
        if !response.status().is_success() {
            return Err(TwonlyError::Generic(format!(
                "group challenge returned {}",
                response.status()
            )));
        }
        response
            .bytes()
            .await
            .map(|v| v.to_vec())
            .map_err(|e| TwonlyError::Generic(e.to_string()))
    }
}

fn url(path: &str) -> String {
    format!("{}group/{path}", RustApi::api_base_url("https".into()))
}

fn client() -> Result<reqwest::Client> {
    reqwest::Client::builder()
        .timeout(std::time::Duration::from_secs(10))
        .build()
        .map_err(|e| TwonlyError::Generic(e.to_string()))
}

async fn success(response: reqwest::Response) -> Result<()> {
    if response.status().is_success() {
        Ok(())
    } else if response.status() == reqwest::StatusCode::CONFLICT {
        // The one status a caller can act on: the state moved while the
        // request was being prepared, and re-applying the change to the new
        // version is all that is needed.
        Err(TwonlyError::GroupStateConflict)
    } else {
        Err(TwonlyError::Generic(format!(
            "group server returned {}",
            response.status()
        )))
    }
}

async fn update_state(value: UpdateGroupState) -> Result<()> {
    success(
        client()?
            .patch(url("state"))
            .body(value.encode_to_vec())
            .send()
            .await
            .map_err(|e| TwonlyError::Generic(e.to_string()))?,
    )
    .await
}
