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

    pub async fn insert(self, tr: &mut Transaction<'_, Sqlite>) -> Result<()> {
        KeyVerification::insert(tr, self).await
    }
}

pub struct KeyVerification;

impl KeyVerification {
    pub async fn insert(
        tr: &mut Transaction<'_, Sqlite>,
        verification: NewKeyVerification,
    ) -> Result<()> {
        let verification_type = verification.verification_type.as_str();
        sqlx::query!(
            r#"
            INSERT INTO key_verifications(contact_id, type, verified_by)
            VALUES (?, ?, ?)
            "#,
            verification.contact_id,
            verification_type,
            verification.verified_by,
        )
        .execute(&mut **tr)
        .await?;

        Ok(())
    }
}
