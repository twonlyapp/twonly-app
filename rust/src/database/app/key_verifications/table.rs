use flutter_rust_bridge::frb;

/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

use sqlx::{Sqlite, Transaction};

use crate::error::Result;

#[derive(Clone, Copy, Debug, Eq, PartialEq)]

pub enum KeyVerificationType {
    ContactSharedByVerified,
    SecretQrToken,
}

impl KeyVerificationType {
    fn as_str(self) -> &'static str {
        match self {
            Self::ContactSharedByVerified => "contactSharedByVerified",
            Self::SecretQrToken => "secretQrToken",
        }
    }
}

pub struct NewKeyVerification {
    contact_id: i64,
    verification_type: KeyVerificationType,
    verified_by: Option<i64>,
}

impl NewKeyVerification {
    pub fn new(contact_id: i64, verification_type: KeyVerificationType) -> Self {
        Self {
            contact_id,
            verification_type,
            verified_by: None,
        }
    }

    pub fn verified_by(mut self, contact_id: i64) -> Self {
        self.verified_by = Some(contact_id);

        self
    }

    pub async fn insert(self, tr: &mut Transaction<'_, Sqlite>) -> Result<bool> {
        KeyVerification::insert(tr, self).await
    }
}

#[derive(Debug, Clone, PartialEq, Eq, sqlx::FromRow)]
#[frb]

pub struct KeyVerification {
    pub verification_id: i64,
    pub contact_id: i64,
    #[frb(name = "typeName")]
    pub r#type: String,
    pub verified_by: Option<i64>,
    #[frb(name = "createdAtSeconds")]
    pub created_at: i64,
}

impl KeyVerification {
    pub async fn insert(
        tr: &mut Transaction<'_, Sqlite>, verification: NewKeyVerification,
    ) -> Result<bool> {
        super::writes::insert(
            tr,
            verification.contact_id,
            verification.verification_type.as_str(),
            verification.verified_by,
        )
        .await
    }
}

use crate::database::app::contacts::table::Contact;

#[derive(Debug, Clone, PartialEq, Eq, sqlx::FromRow)]

pub struct FirstVerificationType {
    pub contact_id: i64,
    pub r#type: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]

pub struct ContactVerifications {
    pub verifications: Vec<KeyVerification>,
    pub contacts: Vec<Contact>,
}

#[derive(Debug, Clone, PartialEq, Eq, sqlx::FromRow)]

pub struct TransferredVerification {
    pub contact_id: i64,
    pub verified_at: i64,
}

#[derive(Debug, Clone, PartialEq, Eq)]

pub struct TransferredVerifications {
    pub relations: Vec<TransferredVerification>,
    pub contacts: Vec<Contact>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]

pub enum VerificationStatus {
    Trusted,
    PartialTrusted,
    NotTrusted,
}

#[derive(Debug, Clone, PartialEq, Eq)]

pub struct GroupVerification {
    pub group_id: String,
    pub status: VerificationStatus,
    pub unverified_count: i64,
}
