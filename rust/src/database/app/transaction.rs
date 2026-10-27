//! Explicit transaction ownership, independent of the Flutter query layer.
//!
//! Each nested scope owns a savepoint. Only the innermost live scope may issue
//! commands, so a delayed child or concurrent sibling cannot write into another
//! scope. Dropping the last owner rolls back the SQLx transaction.

use crate::database::lifecycle::Operation;
use crate::error::{Result, TwonlyError};
use sqlx::{Sqlite, SqlitePool, Transaction};
use std::sync::{Arc, LazyLock, Mutex as ScopeMutex, Weak};
use tokio::sync::{Mutex, MutexGuard};

struct ScopeState {
    active: Vec<u64>,
    next_id: u64,
}

struct TransactionOwner {
    operation: Option<Operation>,
    transaction: Mutex<Option<Transaction<'static, Sqlite>>>,
    // Accessed only while holding `transaction`. No synchronous guard crosses
    // an await; commands retain the ordinary SQLx-compatible transaction guard.
    scopes: ScopeMutex<ScopeState>,
}

static OWNERS: LazyLock<ScopeMutex<Vec<Weak<TransactionOwner>>>> =
    LazyLock::new(|| ScopeMutex::new(Vec::new()));

pub(crate) async fn abort_for_operation(operation: &Operation) {
    let owners = {
        let mut registry = OWNERS.lock().unwrap();

        registry.retain(|owner| owner.strong_count() > 0);

        registry
            .iter()
            .filter_map(Weak::upgrade)
            .filter(|owner| {
                owner
                    .operation
                    .as_ref()
                    .is_some_and(|current| current.same(operation))
            })
            .collect::<Vec<_>>()
    };

    for owner in owners {
        let mut transaction = owner.transaction.lock().await;

        owner.scopes.lock().unwrap().active.clear();

        if let Some(transaction) = transaction.take() {
            let _ = transaction.rollback().await;
        }
    }
}

pub struct TransactionScope {
    owner: Arc<TransactionOwner>,
    id: u64,
}

impl TransactionScope {
    pub async fn begin(pool: &SqlitePool) -> Result<Self> {
        let operation = Operation::inherited();

        if let Some(operation) = &operation {
            operation.check()?;
        }

        let transaction = pool.begin().await?;

        let owner = Arc::new(TransactionOwner {
            operation: operation.clone(),
            transaction: Mutex::new(Some(transaction)),
            scopes: ScopeMutex::new(ScopeState {
                active: vec![0],
                next_id: 1,
            }),
        });

        let cancelled = {
            let mut registry = OWNERS.lock().unwrap();

            if registry.len() > 128 {
                registry.retain(|owner| owner.strong_count() > 0);
            }

            if operation.as_ref().is_some_and(Operation::cancelled) {
                true
            } else {
                registry.push(Arc::downgrade(&owner));

                false
            }
        };

        if cancelled {
            if let Some(transaction) = owner.transaction.lock().await.take() {
                let _ = transaction.rollback().await;
            }

            return Err(TwonlyError::Generic(
                "Database transaction cancelled".into(),
            ));
        }

        Ok(Self { owner, id: 0 })
    }

    pub(crate) async fn lock(
        &self,
    ) -> Result<MutexGuard<'_, Option<Transaction<'static, Sqlite>>>> {
        let transaction = self.owner.transaction.lock().await;

        self.check_active(&transaction)?;

        Ok(transaction)
    }

    fn check_active(&self, transaction: &Option<Transaction<'static, Sqlite>>) -> Result<()> {
        if let Some(operation) = &self.owner.operation {
            operation.check()?;
        }

        let scopes = self.owner.scopes.lock().unwrap();

        if transaction.is_none() || !scopes.active.contains(&self.id) {
            return Err(TwonlyError::Generic(
                "Database transaction scope is closed".into(),
            ));
        }

        if scopes.active.last() != Some(&self.id) {
            return Err(TwonlyError::Generic(
                "A nested database transaction is still active".into(),
            ));
        }

        Ok(())
    }

    pub async fn begin_nested(&self) -> Result<Self> {
        let mut transaction = self.lock().await?;

        let id = {
            let mut scopes = self.owner.scopes.lock().unwrap();

            let id = scopes.next_id;

            scopes.next_id = id.checked_add(1).ok_or_else(|| {
                TwonlyError::Generic("Database savepoint counter exhausted".into())
            })?;

            id
        };

        // Ownership IDs are validated by the scope stack. SQLite resolves the
        // nearest savepoint with this literal name, so nesting needs no SQL generation.
        sqlx::query!(
            r#"
                SAVEPOINT app_scope
            "#,
        )
        .execute(&mut **transaction.as_mut().unwrap())
        .await?;

        self.owner.scopes.lock().unwrap().active.push(id);

        Ok(Self {
            owner: self.owner.clone(),
            id,
        })
    }

    pub fn is_root(&self) -> bool {
        self.id == 0
    }

    pub async fn commit(&self) -> Result<()> {
        let mut guard = self.lock().await?;

        if self.is_root() {
            let transaction = guard.take().unwrap();

            self.owner.scopes.lock().unwrap().active.clear();

            drop(guard);

            transaction.commit().await?;
        } else {
            let result = sqlx::query!(
                r#"
                    RELEASE app_scope
                "#,
            )
            .execute(&mut **guard.as_mut().unwrap())
            .await;

            if let Err(error) = result {
                self.abort(&mut guard).await;

                return Err(error.into());
            }

            self.owner.scopes.lock().unwrap().active.pop();
        }

        Ok(())
    }

    pub async fn rollback(&self) -> Result<()> {
        let mut guard = self.owner.transaction.lock().await;

        if guard.is_none() {
            return Ok(());
        }

        if self.is_root() {
            let transaction = guard.take().unwrap();

            self.owner.scopes.lock().unwrap().active.clear();

            drop(guard);

            transaction.rollback().await?;
        } else {
            self.check_active(&guard)?;

            let result = async {
                let transaction = &mut **guard.as_mut().unwrap();

                sqlx::query!(
                    r#"
                        ROLLBACK TO app_scope
                    "#,
                )
                .execute(&mut *transaction)
                .await?;

                sqlx::query!(
                    r#"
                        RELEASE app_scope
                    "#,
                )
                .execute(transaction)
                .await?;

                Ok::<_, sqlx::Error>(())
            }
            .await;

            if let Err(error) = result {
                self.abort(&mut guard).await;

                return Err(error.into());
            }

            self.owner.scopes.lock().unwrap().active.pop();
        }

        Ok(())
    }

    async fn abort(&self, guard: &mut Option<Transaction<'static, Sqlite>>) {
        self.owner.scopes.lock().unwrap().active.clear();

        if let Some(transaction) = guard.take() {
            // SQLx's drop path still rolls back if an explicit rollback fails.
            let _ = transaction.rollback().await;
        }
    }
}

#[cfg(test)]
mod tests;
