//! Rekey is a native SQLCipher API boundary, with exclusive access from before
//! sqlite3_open_v2 until the actual native close finishes.

use crate::database::lifecycle;
use crate::database::maintenance::Exclusive;
use crate::error::{Result, TwonlyError};
use std::ffi::{c_char, CString};
use zeroize::Zeroizing;

struct NativeDatabase(*mut libsqlite3_sys::sqlite3);

impl Drop for NativeDatabase {
    fn drop(&mut self) {
        unsafe { crate::database::maintenance::sqlite3_close_v2(self.0) };
    }
}

fn checked(code: i32) -> Result<()> {
    if code == libsqlite3_sys::SQLITE_OK {
        Ok(())
    } else {
        // Never include SQLCipher key material or generated PRAGMA text.
        Err(TwonlyError::Generic(format!(
            "Exclusive SQLCipher rekey failed ({code})"
        )))
    }
}

pub(super) async fn run(path: &str, key: &str, exclusive: Exclusive) -> Result<()> {
    let path =
        CString::new(path).map_err(|_| TwonlyError::Generic("Invalid database filename".into()))?;

    let key = Zeroizing::new(key.to_owned());

    let operation = lifecycle::Operation::current();

    // The owned closure retains exclusive protection even if its async caller
    // disappears. It cannot finish before SQLCipher and native close finish.
    lifecycle::spawn_blocking(move || {
        exclusive.scope(|| {
            if let Some(operation) = &operation {
                operation.check()?;
            }

            let mut pointer = std::ptr::null_mut();

            let code = unsafe {
                libsqlite3_sys::sqlite3_open_v2(
                    path.as_ptr(),
                    &mut pointer,
                    libsqlite3_sys::SQLITE_OPEN_READWRITE | libsqlite3_sys::SQLITE_OPEN_NOMUTEX,
                    std::ptr::null(),
                )
            };

            let database = NativeDatabase(pointer);

            checked(code)?;

            checked(unsafe { libsqlite3_sys::sqlite3_busy_timeout(database.0, 50) })?;

            checked(unsafe {
                libsqlite3_sys::sqlite3_key(database.0, key.as_ptr().cast(), key.len() as i32)
            })?;

            let raw = Zeroizing::new(format!("x'{}'", key.as_str()));

            checked(unsafe {
                libsqlite3_sys::sqlite3_rekey(
                    database.0,
                    raw.as_ptr().cast::<c_char>().cast(),
                    raw.len() as i32,
                )
            })?;

            // There are no prepared statements/backup handles here. close_v2 in
            // Drop still protects the error path; successful close is acknowledged.
            let code = unsafe { libsqlite3_sys::sqlite3_close(database.0) };

            if code == libsqlite3_sys::SQLITE_OK {
                std::mem::forget(database);
            }

            checked(code)
        })
    })
    .await
    .map_err(|error| TwonlyError::Generic(format!("SQLCipher rekey worker failed: {error}")))?
}
