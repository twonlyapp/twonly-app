//! Cooperative file replacement/rekey protection, independent of SQLite's
//! transaction locks. Never unlink these lock files: their inode is the gate.

use crate::error::{Result, TwonlyError};
use std::cell::RefCell;
use std::ffi::{c_char, c_void, CStr};
use std::fs::{File, OpenOptions};
use std::path::{Path, PathBuf};
use std::sync::{Arc, OnceLock};

const SUFFIX: &str = ".twonly-maintenance.lock";

pub(crate) const RESTORE_JOURNAL: &str = ".twonly-restore.json";

static REGISTERED: OnceLock<std::result::Result<(), String>> = OnceLock::new();

// Present in the bundled engine but omitted by libsqlite3-sys's bindings.
unsafe extern "C" {

    pub(crate) fn sqlite3_close_v2(database: *mut libsqlite3_sys::sqlite3) -> i32;

}

thread_local! {
    // Only synchronous native maintenance runs under this authorization. It
    // never crosses an await or grants other workers permission to open.
    static AUTHORIZED: RefCell<Option<Arc<Access>>> = const { RefCell::new(None) };
}

pub(crate) struct Access {
    _file: File,
    path: PathBuf,
    _snapshot: Option<Arc<Access>>,
    // Drop the file/lock before acknowledging completion to the owner.
    _operation: Option<crate::database::lifecycle::ConnectionTicket>,
}

pub(crate) struct Exclusive(Arc<Access>);

struct NativeLease {
    _access: Arc<Access>,
    owner: std::sync::Mutex<Option<crate::database::lifecycle::ConnectionTicket>>,
}

const NATIVE_LEASE: &CStr = c"eu.twonly.database.physical-lifetime";

/// Called under SQLx's native handle lock. The scalar-function anchor keeps
/// this ticket alive beyond early client-data destruction and final rollback.

pub(crate) unsafe fn set_owner(
    database: *mut libsqlite3_sys::sqlite3,
    operation: Option<crate::database::lifecycle::Operation>,
) {
    let pointer =
        unsafe { libsqlite3_sys::sqlite3_get_clientdata(database, NATIVE_LEASE.as_ptr()) }
            .cast::<Arc<NativeLease>>();

    if !pointer.is_null() {
        let lease = unsafe { &*pointer };

        *lease.owner.lock().unwrap() =
            operation.map(crate::database::lifecycle::ConnectionTicket::new);
    }
}

fn failure(message: impl Into<String>) -> TwonlyError {
    TwonlyError::Generic(message.into())
}

pub(crate) fn ensure_no_restore(database_dir: &Path) -> Result<()> {
    if database_dir.join(RESTORE_JOURNAL).try_exists()? {
        return Err(failure(
            "Interrupted restore must be recovered before accessing the store",
        ));
    }

    Ok(())
}

/// Settings use the application database's maintenance gate too. A config-only
/// callback must not read or write through an unfinished file installation.

pub(crate) fn settings_access(database_dir: &Path) -> Result<Arc<Access>> {
    let operation = crate::database::lifecycle::Operation::inherited();

    // Register before checking admission: cancellation must either reject the
    // lock or wait for its actual release, including synchronous callbacks.
    let ticket = operation
        .as_ref()
        .map(|operation| crate::database::lifecycle::ConnectionTicket::new(operation.clone()));

    if let Some(operation) = operation {
        operation.check()?;
    }

    let mut access = lock(&database_dir.join(super::app::APP_DATABASE_FILE), false)?;

    let metadata = lock(&database_dir.join("snapshot-metadata"), false)?;

    Arc::get_mut(&mut access).unwrap()._snapshot = Some(metadata);

    Arc::get_mut(&mut access).unwrap()._operation = ticket;

    ensure_no_restore(database_dir)?;

    Ok(access)
}

pub(crate) fn freeze_settings(database_dir: &Path) -> Result<Exclusive> {
    Exclusive::try_acquire(&database_dir.join("snapshot-metadata"))?
        .ok_or_else(|| failure("Settings are changing; retry the backup"))
}

fn canonical(path: &Path) -> std::io::Result<PathBuf> {
    if path.exists() {
        path.canonicalize()
    } else {
        let parent = path
            .parent()
            .filter(|path| !path.as_os_str().is_empty())
            .unwrap_or(Path::new("."));

        Ok(parent.canonicalize()?.join(path.file_name().ok_or_else(|| {
            std::io::Error::new(
                std::io::ErrorKind::InvalidInput,
                "Database filename is missing",
            )
        })?))
    }
}

fn lock(path: &Path, exclusive: bool) -> std::io::Result<Arc<Access>> {
    let path = canonical(path)?;

    let mut name = path.file_name().unwrap().to_os_string();

    name.push(SUFFIX);

    let file = OpenOptions::new()
        .read(true)
        .write(true)
        .create(true)
        .truncate(false)
        .open(path.with_file_name(name))?;

    #[cfg(unix)]
    {
        use std::os::fd::AsRawFd;

        let mode = if exclusive {
            libc::LOCK_EX
        } else {
            libc::LOCK_SH
        };

        loop {
            if unsafe { libc::flock(file.as_raw_fd(), mode | libc::LOCK_NB) } == 0 {
                break;
            }

            let error = std::io::Error::last_os_error();

            if error.kind() != std::io::ErrorKind::Interrupted {
                return Err(error);
            }
        }
    }

    #[cfg(not(unix))]
    return Err(std::io::Error::new(
        std::io::ErrorKind::Unsupported,
        "Database maintenance locking requires a supported platform",
    ));

    Ok(Arc::new(Access {
        _file: file,
        _snapshot: None,
        path,
        _operation: None,
    }))
}

impl Exclusive {
    /// Fail promptly rather than waiting with locks while another process may
    /// be suspended. The caller preserves all live files on refusal.

    pub(crate) fn try_acquire(path: &Path) -> Result<Option<Self>> {
        initialize()?;

        match lock(path, true) {
            Ok(access) => Ok(Some(Self(access))),
            Err(error) if error.kind() == std::io::ErrorKind::WouldBlock => Ok(None),
            Err(error) => Err(error.into()),
        }
    }

    pub(crate) fn acquire_all(paths: impl IntoIterator<Item = PathBuf>) -> Result<Vec<Self>> {
        let paths = paths
            .into_iter()
            .map(|path| canonical(&path))
            .collect::<std::io::Result<std::collections::BTreeSet<_>>>()?;

        paths
            .into_iter()
            .map(|path| {
                Self::try_acquire(&path)?.ok_or_else(|| {
                    failure(
                        "Database maintenance deferred: another connection still has a database \
                         open",
                    )
                })
            })
            .collect()
    }

    pub(crate) fn scope<T>(&self, work: impl FnOnce() -> T) -> T {
        struct Reset(Option<Arc<Access>>);

        impl Drop for Reset {
            fn drop(&mut self) {
                AUTHORIZED.with(|slot| {
                    *slot.borrow_mut() = self.0.take();
                });
            }
        }

        let _reset = Reset(AUTHORIZED.with(|slot| slot.replace(Some(self.0.clone()))));

        work()
    }
}

pub(crate) fn is_lock_file(path: &Path) -> bool {
    path.file_name()
        .is_some_and(|name| name.to_string_lossy().ends_with(SUFFIX))
}

pub(crate) fn initialize() -> Result<()> {
    REGISTERED
        .get_or_init(|| {
            let code = unsafe { libsqlite3_sys::sqlite3_auto_extension(Some(opened)) };

            if code == libsqlite3_sys::SQLITE_OK {
                Ok(())
            } else {
                Err("Could not install database maintenance protection".into())
            }
        })
        .clone()
        .map_err(failure)
}

unsafe extern "C" fn destroy(pointer: *mut c_void) {
    // SQLite invokes this after closing its btrees, including rollback and
    // WAL cleanup. sqlite3_set_clientdata destructors run too early for this.
    drop(unsafe { Box::from_raw(pointer.cast::<Arc<NativeLease>>()) });
}

unsafe extern "C" fn lease_function(
    context: *mut libsqlite3_sys::sqlite3_context, _: i32,
    _: *mut *mut libsqlite3_sys::sqlite3_value,
) {
    unsafe { libsqlite3_sys::sqlite3_result_null(context) };
}

unsafe fn protect(database: *mut libsqlite3_sys::sqlite3) -> Result<()> {
    let filename = unsafe { libsqlite3_sys::sqlite3_db_filename(database, c"main".as_ptr()) };

    if filename.is_null() {
        return Ok(());
    }

    let filename = unsafe { CStr::from_ptr(filename) }.to_bytes();

    if filename.is_empty() {
        return Ok(());
    }

    #[cfg(unix)]
    let path = {
        use std::os::unix::ffi::OsStrExt;

        Path::new(std::ffi::OsStr::from_bytes(filename))
    };

    #[cfg(not(unix))]
    let path =
        Path::new(std::str::from_utf8(filename).map_err(|_| failure("Invalid database filename"))?);

    let canonical = canonical(path)?;

    let authorized = AUTHORIZED.with(|slot| {
        slot.borrow()
            .as_ref()
            .filter(|access| access.path == canonical)
            .cloned()
    });

    let access = match authorized {
        Some(access) => access,
        None => lock(&canonical, false)
            .map_err(|_| failure("Database maintenance in progress; retry when active"))?,
    };

    let lease = Arc::new(NativeLease {
        _access: access,
        owner: Default::default(),
    });

    let data = Box::into_raw(Box::new(lease.clone())).cast::<c_void>();

    // The private scalar function is a lifetime anchor, never used in SQL.
    // Its destructor survives sqlite3_close_v2 zombies and runs after the
    // actual file handles close, including abandoned initial SQLx setup.
    let code = unsafe {
        libsqlite3_sys::sqlite3_create_function_v2(
            database,
            c"twonly_maintenance_lease".as_ptr(),
            0,
            libsqlite3_sys::SQLITE_UTF8,
            data,
            Some(lease_function),
            None,
            None,
            Some(destroy),
        )
    };

    if code != libsqlite3_sys::SQLITE_OK {
        return Err(failure("Could not protect database handle"));
    }

    let data = Box::into_raw(Box::new(lease)).cast::<c_void>();

    let code = unsafe {
        libsqlite3_sys::sqlite3_set_clientdata(database, NATIVE_LEASE.as_ptr(), data, Some(destroy))
    };

    if code != libsqlite3_sys::SQLITE_OK {
        return Err(failure("Could not track physical database lifetime"));
    }

    if matches!(
        canonical.file_name().and_then(|name| name.to_str()),
        Some("app_db.sqlite" | "rust_db.sqlite")
    ) {
        ensure_no_restore(canonical.parent().unwrap())?;
    }

    Ok(())
}

unsafe extern "C" fn opened(
    database: *mut libsqlite3_sys::sqlite3, error: *mut *mut c_char,
    _: *const libsqlite3_sys::sqlite3_api_routines,
) -> i32 {
    match std::panic::catch_unwind(|| unsafe { protect(database) }) {
        Ok(Ok(())) => libsqlite3_sys::SQLITE_OK,
        _ => {
            let message = c"Database maintenance protection unavailable; retry when active";

            let pointer =
                unsafe { libsqlite3_sys::sqlite3_malloc(message.to_bytes_with_nul().len() as i32) }
                    .cast::<c_char>();

            if !pointer.is_null() {
                unsafe {
                    std::ptr::copy_nonoverlapping(
                        message.as_ptr(),
                        pointer,
                        message.to_bytes_with_nul().len(),
                    );

                    *error = pointer;
                }
            }

            libsqlite3_sys::SQLITE_CANTOPEN
        }
    }
}

#[cfg(test)]
mod tests;
