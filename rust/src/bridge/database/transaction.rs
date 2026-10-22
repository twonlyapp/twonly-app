//! Typed commands explicitly join their caller's native transaction scope.
//! Unrelated native jobs continue to acquire their own connection. A savepoint
//! makes a failed command atomic even when Dart catches its error and
//! continues.

use crate::bridge::database::DatabaseSession;
use crate::bridge::get_twonly_flutter;
use crate::error::Result;
use sqlx::{Sqlite, Transaction};
use tokio::sync::MutexGuard;

pub(crate) enum CommandTransaction<'a> {
    Owned(Transaction<'static, Sqlite>),
    Borrowed(MutexGuard<'a, Option<Transaction<'static, Sqlite>>>),
}

impl<'a> CommandTransaction<'a> {
    pub async fn begin(owner: &'a DatabaseSession) -> Result<Self> {
        Self::start(owner, false).await
    }

    pub async fn read(owner: &'a DatabaseSession) -> Result<Self> {
        Self::start(owner, true).await
    }

    async fn start(owner: &'a DatabaseSession, read: bool) -> Result<Self> {
        if let Some(owner) = owner.transaction.as_ref() {
            let mut guard = owner.lock().await?;

            sqlx::query!(
                r#"
                    SAVEPOINT rust_domain_command
                "#,
            )
            .execute(&mut **guard.as_mut().unwrap())
            .await?;

            Ok(Self::Borrowed(guard))
        } else {
            get_twonly_flutter()?.wait_for_foreground().await?;

            let database = get_twonly_flutter()?.app_db.read().await.clone();

            Ok(Self::Owned(if read {
                database.read_pool.begin().await?
            } else {
                database.pool.begin().await?
            }))
        }
    }

    pub fn transaction(&mut self) -> &mut Transaction<'static, Sqlite> {
        match self {
            Self::Owned(transaction) => transaction,
            Self::Borrowed(guard) => guard.as_mut().unwrap(),
        }
    }

    pub async fn finish<T>(self, result: Result<T>) -> Result<T> {
        match self {
            Self::Owned(transaction) => {
                if result.is_ok() {
                    transaction.commit().await?;
                } else {
                    transaction.rollback().await?;
                }
            }
            Self::Borrowed(mut guard) => {
                let cleanup = async {
                    let connection = &mut **guard.as_mut().unwrap();

                    if result.is_err() {
                        sqlx::query!(
                            r#"
                                ROLLBACK TO rust_domain_command
                            "#,
                        )
                        .execute(&mut *connection)
                        .await?;
                    }

                    sqlx::query!(
                        r#"
                            RELEASE rust_domain_command
                        "#,
                    )
                    .execute(connection)
                    .await?;

                    Ok::<_, sqlx::Error>(())
                }
                .await;

                if let Err(error) = cleanup {
                    // Savepoint state is uncertain. A caught command error must
                    // never let the caller commit partially reverted changes.
                    if let Some(transaction) = guard.take() {
                        let _ = transaction.rollback().await;
                    }

                    return Err(error.into());
                }
            }
        }

        result
    }
}
