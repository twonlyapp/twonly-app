//! UIKit is owned by the app executable. No Flutter engine is needed.

use crate::error::{Result, TwonlyError};

pub(crate) fn active() -> Result<bool> {
    let symbol = unsafe {
        libc::dlsym(
            libc::RTLD_DEFAULT,
            c"twonly_database_is_foreground".as_ptr(),
        )
    };

    if symbol.is_null() {
        return Err(TwonlyError::Generic(
            "Native database lifecycle unavailable".into(),
        ));
    }

    let callback: unsafe extern "C" fn() -> bool = unsafe { std::mem::transmute(symbol) };

    Ok(unsafe { callback() })
}

pub(crate) fn begin(operation: u64) -> Result<u64> {
    let symbol = unsafe {
        libc::dlsym(
            libc::RTLD_DEFAULT,
            c"twonly_begin_database_operation".as_ptr(),
        )
    };

    if symbol.is_null() {
        return Err(TwonlyError::Generic(
            "Native database execution protection unavailable".into(),
        ));
    }

    // SAFETY: the Swift @_cdecl function has exactly this signature.
    let callback: unsafe extern "C" fn(u64) -> u64 = unsafe { std::mem::transmute(symbol) };

    let lease = unsafe { callback(operation) };

    if lease == 0 {
        Err(TwonlyError::Generic(
            "Database operation deferred until foreground".into(),
        ))
    } else {
        Ok(lease)
    }
}

pub(crate) fn end(lease: u64) {
    let symbol = unsafe { libc::dlsym(libc::RTLD_DEFAULT, c"twonly_end_background_task".as_ptr()) };

    if !symbol.is_null() {
        // SAFETY: the Swift @_cdecl function has exactly this signature.
        let callback: unsafe extern "C" fn(u64) = unsafe { std::mem::transmute(symbol) };

        unsafe { callback(lease) };
    }
}
