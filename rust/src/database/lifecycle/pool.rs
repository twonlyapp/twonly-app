//! Operation ownership follows each physical SQLite checkout. SQLite owns the
//! busy-handler data until explicit release or actual connection destruction.

use super::{ConnectionTicket, Operation};
use sqlx::SqliteConnection;
use std::ffi::c_void;
use std::sync::Mutex;
use std::time::{Duration, Instant};

const OWNER: &std::ffi::CStr = c"eu.twonly.database.operation";

const POOL_OWNER: &std::ffi::CStr = c"eu.twonly.database.native-pool";

const DEFAULT_BUSY_MS: i32 = 30_000;

pub(crate) struct PoolOperations {
    default: Mutex<Option<Operation>>,
    unscoped: std::sync::atomic::AtomicBool,
}

impl PoolOperations {
    pub(crate) fn new() -> Self {
        let operation = Operation::current();

        Self {
            unscoped: std::sync::atomic::AtomicBool::new(
                operation.as_ref().is_none_or(Operation::is_foreground),
            ),
            default: Mutex::new(operation),
        }
    }

    pub(crate) fn set_default(&self, operation: Option<Operation>) {
        self.unscoped.store(
            operation.as_ref().is_none_or(Operation::is_foreground),
            std::sync::atomic::Ordering::Release,
        );

        *self
            .default
            .lock()
            .unwrap_or_else(|error| error.into_inner()) = operation;
    }

    pub(crate) fn suspended(&self) -> bool {
        !self.unscoped.load(std::sync::atomic::Ordering::Acquire)
            || self
                .default
                .lock()
                .unwrap()
                .as_ref()
                .is_some_and(Operation::cancelled)
    }

    pub(crate) fn owned_by(&self, operation: &Operation) -> bool {
        self.default
            .lock()
            .unwrap_or_else(|error| error.into_inner())
            .as_ref()
            .is_some_and(|owner| std::sync::Arc::ptr_eq(&owner.0, &operation.0))
    }

    pub(crate) fn has_owner(&self) -> bool {
        self.default
            .lock()
            .unwrap_or_else(|error| error.into_inner())
            .is_some()
    }

    pub(crate) async fn acquire(&self, connection: &mut SqliteConnection) -> sqlx::Result<()> {
        self.install(connection).await
    }

    pub(crate) async fn connect(&self, connection: &mut SqliteConnection) -> sqlx::Result<()> {
        // SQLx retries after_connect failures. Install cancellation even if
        // already cancelled, then let the owned job cancel/close this pool.
        self.install(connection).await
    }

    async fn install(&self, connection: &mut SqliteConnection) -> sqlx::Result<()> {
        let inherited = self
            .default
            .lock()
            .unwrap_or_else(|error| error.into_inner())
            .clone();

        let current = Operation::current();

        let denied = current.is_none() && !self.unscoped.load(std::sync::atomic::Ordering::Acquire);

        let operation = if denied {
            Some(Operation::new(Duration::ZERO))
        } else {
            current.or_else(|| inherited.clone())
        };

        let Some(operation) = operation else {
            return Self::clear(connection).await;
        };

        let mut handle = connection.lock_handle().await?;

        let native = handle.as_raw_handle().as_ptr();

        unsafe { crate::database::maintenance::set_owner(native, inherited.clone()) };

        if let Some(inherited) = inherited {
            // Keep native-only pools owned while idle, including cancellation
            // during context initialization before a Context is published.
            let existing =
                unsafe { libsqlite3_sys::sqlite3_get_clientdata(native, POOL_OWNER.as_ptr()) }
                    .cast::<ConnectionTicket>();

            let same = !existing.is_null()
                && unsafe { std::sync::Arc::ptr_eq(&(*existing).0 .0, &inherited.0) };

            if !same {
                let pointer =
                    Box::into_raw(Box::new(ConnectionTicket::new(inherited))).cast::<c_void>();

                let code = unsafe {
                    libsqlite3_sys::sqlite3_set_clientdata(
                        native,
                        POOL_OWNER.as_ptr(),
                        pointer,
                        Some(destroy_ticket),
                    )
                };

                if code != libsqlite3_sys::SQLITE_OK {
                    return Err(sqlx::Error::Protocol(
                        "Could not register native pool lifetime".into(),
                    ));
                }
            }
        } else {
            unsafe {
                libsqlite3_sys::sqlite3_set_clientdata(
                    native,
                    POOL_OWNER.as_ptr(),
                    std::ptr::null_mut(),
                    None,
                );
            }
        }

        // SAFETY: lock_handle excludes SQLx execution. Disable the old busy
        // callback before replacing its client data and freeing its pointer.
        unsafe {
            libsqlite3_sys::sqlite3_busy_timeout(native, DEFAULT_BUSY_MS);
        }

        let state = Box::new(Busy {
            ticket: ConnectionTicket::new(operation.clone()),
            started: Mutex::new(Instant::now()),
        });

        let pointer = Box::into_raw(state).cast::<c_void>();

        // sqlite3_set_clientdata invokes destroy even on allocation failure.
        // Its destructor also covers explicit close and SQLx dropping a
        // connection before an after_release hook can run.
        let registered = unsafe {
            libsqlite3_sys::sqlite3_set_clientdata(native, OWNER.as_ptr(), pointer, Some(destroy))
        };

        if registered != libsqlite3_sys::SQLITE_OK {
            return Err(sqlx::Error::Protocol(
                "Could not register SQLite operation owner".into(),
            ));
        }

        let installed =
            unsafe { libsqlite3_sys::sqlite3_busy_handler(native, Some(busy), pointer) };

        if installed != libsqlite3_sys::SQLITE_OK {
            return Err(sqlx::Error::Protocol(
                "Could not register SQLite cancellation handler".into(),
            ));
        }

        // A hook error makes SQLx discard/reopen connections until its acquire
        // timeout. Interrupt before the first VM instruction instead when the
        // owner is already cancelled; never run SQL under that expired owner.
        let instructions = if operation.cancelled() { 1 } else { 1000 };

        handle.set_progress_handler(instructions, move || !operation.cancelled());

        Ok(())
    }

    pub(crate) async fn release(&self, connection: &mut SqliteConnection) -> sqlx::Result<bool> {
        let mut handle = connection.lock_handle().await?;

        // An unresolved transaction must be closed, retaining its owner until
        // SQLite has rolled back and destroyed the physical connection.
        if unsafe { libsqlite3_sys::sqlite3_get_autocommit(handle.as_raw_handle().as_ptr()) } == 0 {
            return Ok(false);
        }

        let native = handle.as_raw_handle().as_ptr();

        let mut statement =
            unsafe { libsqlite3_sys::sqlite3_next_stmt(native, std::ptr::null_mut()) };

        while !statement.is_null() {
            if unsafe { libsqlite3_sys::sqlite3_stmt_busy(statement) } != 0 {
                return Ok(false);
            }

            statement = unsafe { libsqlite3_sys::sqlite3_next_stmt(native, statement) };
        }

        drop(handle);

        let native_pool = self
            .default
            .lock()
            .unwrap_or_else(|error| error.into_inner())
            .is_some();

        Self::clear_borrow(connection, !native_pool).await?;

        Ok(true)
    }

    async fn clear(connection: &mut SqliteConnection) -> sqlx::Result<()> {
        Self::clear_borrow(connection, true).await
    }

    async fn clear_borrow(connection: &mut SqliteConnection, clear_pool: bool) -> sqlx::Result<()> {
        let mut handle = connection.lock_handle().await?;

        let native = handle.as_raw_handle().as_ptr();

        handle.remove_progress_handler();

        // SAFETY: the worker is idle under lock_handle. Unregister the busy
        // callback before releasing its owned data. No connection is reused
        // with a previous operation's cancellation flag.
        unsafe {
            libsqlite3_sys::sqlite3_busy_timeout(native, DEFAULT_BUSY_MS);

            libsqlite3_sys::sqlite3_set_clientdata(
                native,
                OWNER.as_ptr(),
                std::ptr::null_mut(),
                None,
            );

            if clear_pool {
                crate::database::maintenance::set_owner(native, None);

                libsqlite3_sys::sqlite3_set_clientdata(
                    native,
                    POOL_OWNER.as_ptr(),
                    std::ptr::null_mut(),
                    None,
                );
            }
        }

        Ok(())
    }
}

struct Busy {
    ticket: ConnectionTicket,
    started: Mutex<Instant>,
}

unsafe extern "C" fn destroy_ticket(pointer: *mut c_void) {
    // SAFETY: SQLite owns this Box and invokes its destructor exactly once.
    drop(unsafe { Box::from_raw(pointer.cast::<ConnectionTicket>()) });
}

unsafe extern "C" fn destroy(pointer: *mut c_void) {
    // SAFETY: only SQLite invokes this destructor for its single owned Box.
    drop(unsafe { Box::from_raw(pointer.cast::<Busy>()) });
}

unsafe extern "C" fn busy(pointer: *mut c_void, attempt: i32) -> i32 {
    // SAFETY: SQLite's client data owns this allocation, and SQLx's native
    // handle lock excludes replacement/destruction while execution is active.
    let state = unsafe { &*pointer.cast::<Busy>() };

    if state.ticket.0.cancelled() {
        return 0;
    }

    let mut started = state
        .started
        .lock()
        .unwrap_or_else(|error| error.into_inner());

    if attempt == 0 {
        *started = Instant::now();
    }

    if started.elapsed() >= Duration::from_millis(DEFAULT_BUSY_MS as u64) {
        return 0;
    }

    drop(started);

    // This runs on SQLite's dedicated worker, never the UI/Tokio thread.
    // Do not execute SQLite or access UIKit from this callback.
    std::thread::sleep(Duration::from_millis(5));

    i32::from(!state.ticket.0.cancelled())
}
