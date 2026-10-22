//! Test-only shim over the linked engine's normal VFS. It preserves the native
//! file layout, locking and shared-memory methods; only selected I/O calls
//! fail. https://www.sqlite.org/vfs.html#vfs_shims

use libsqlite3_sys::*;
use std::collections::HashMap;
use std::ffi::{c_char, c_int, c_void, CString};
use std::sync::{Arc, LazyLock, Mutex};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]

pub(super) enum Fault {
    Read,
    Write,
    Sync,
    Full,
}

impl Fault {
    fn code(self) -> c_int {
        match self {
            Self::Read => SQLITE_IOERR_READ,
            Self::Write => SQLITE_IOERR_WRITE,
            Self::Sync => SQLITE_IOERR_FSYNC,
            Self::Full => SQLITE_FULL,
        }
    }
}

#[derive(Default)]

struct Injection {
    pending: Option<(Fault, usize)>,
    triggered: Option<Fault>,
}

struct VfsState {
    base: usize,
    injection: Mutex<Injection>,
}

struct FileState {
    original: sqlite3_io_methods,
    // SQLite borrows this stable allocation until xClose finishes.
    methods: Box<sqlite3_io_methods>,
    vfs: Arc<VfsState>,
}

static VFS: LazyLock<Mutex<HashMap<usize, Arc<VfsState>>>> =
    LazyLock::new(|| Mutex::new(HashMap::new()));

static FILES: LazyLock<Mutex<HashMap<usize, Arc<FileState>>>> =
    LazyLock::new(|| Mutex::new(HashMap::new()));

pub(super) struct FaultVfs {
    name: String,
    state: Arc<VfsState>,
}

impl FaultVfs {
    pub(super) fn new() -> Self {
        // SAFETY: SQLite initialization is thread-safe, and the built-in VFS
        // outlives this test registration. Never replace the process default.
        unsafe {
            assert_eq!(sqlite3_initialize(), SQLITE_OK);

            let base = sqlite3_vfs_find(std::ptr::null());

            assert!(!base.is_null());

            let name = format!("twonly-fault-{}", uuid::Uuid::new_v4());

            let mut native = Box::new(*base);

            // Registrations deliberately live until the test process exits.
            // Even a panicking async test can leave a SQLx worker closing in
            // the background; its VFS/name must never become dangling data.
            native.zName = CString::new(name.clone()).unwrap().into_raw();

            native.pNext = std::ptr::null_mut();

            native.xOpen = Some(open);

            let state = Arc::new(VfsState {
                base: base as usize,
                injection: Mutex::new(Injection::default()),
            });

            VFS.lock()
                .unwrap()
                .insert(&*native as *const _ as usize, state.clone());

            assert_eq!(sqlite3_vfs_register(&mut *native, 0), SQLITE_OK);

            Box::leak(native);

            Self { name, state }
        }
    }

    pub(super) fn name(&self) -> String {
        self.name.clone()
    }

    pub(super) fn arm(&self, fault: Fault, nth: usize) {
        assert!(nth > 0);

        *self.state.injection.lock().unwrap() = Injection {
            pending: Some((fault, nth)),
            triggered: None,
        };
    }

    pub(super) fn disarm(&self) -> Option<Fault> {
        let mut injection = self.state.injection.lock().unwrap();

        injection.pending = None;

        injection.triggered
    }

    pub(super) fn assert_closed(&self) {
        assert!(!FILES
            .lock()
            .unwrap()
            .values()
            .any(|file| Arc::ptr_eq(&file.vfs, &self.state)));
    }
}

fn state(file: *mut sqlite3_file) -> Option<Arc<FileState>> {
    FILES
        .lock()
        .unwrap_or_else(|error| error.into_inner())
        .get(&(file as usize))
        .cloned()
}

fn fault(file: &FileState, operation: Fault) -> Option<c_int> {
    let mut injection = file
        .vfs
        .injection
        .lock()
        .unwrap_or_else(|error| error.into_inner());

    let (selected, remaining) = injection.pending.as_mut()?;

    if *selected != operation && !(*selected == Fault::Full && operation == Fault::Write) {
        return None;
    }

    *remaining -= 1;

    if *remaining != 0 {
        return None;
    }

    let selected = *selected;

    injection.pending = None;

    injection.triggered = Some(selected);

    Some(selected.code())
}

unsafe extern "C" fn open(
    vfs: *mut sqlite3_vfs, name: *const c_char, file: *mut sqlite3_file, flags: c_int,
    out_flags: *mut c_int,
) -> c_int {
    let state = VFS
        .lock()
        .unwrap_or_else(|error| error.into_inner())
        .get(&(vfs as usize))
        .cloned();

    let Some(vfs) = state else {
        return SQLITE_CANTOPEN;
    };

    let base = vfs.base as *mut sqlite3_vfs;

    let Some(original_open) = (*base).xOpen else {
        return SQLITE_CANTOPEN;
    };

    let result = original_open(base, name, file, flags, out_flags);

    if !(*file).pMethods.is_null() {
        let original = *(*file).pMethods;

        let mut methods = Box::new(original);

        methods.xClose = Some(close);

        methods.xRead = Some(read);

        methods.xWrite = Some(write);

        methods.xSync = Some(sync);

        let state = Arc::new(FileState {
            original,
            methods,
            vfs,
        });

        (*file).pMethods = &*state.methods;

        FILES
            .lock()
            .unwrap_or_else(|error| error.into_inner())
            .insert(file as usize, state);
    }

    result
}

unsafe extern "C" fn close(file: *mut sqlite3_file) -> c_int {
    let Some(state) = state(file) else {
        return SQLITE_IOERR_CLOSE;
    };

    let result = state
        .original
        .xClose
        .map_or(SQLITE_IOERR_CLOSE, |close| close(file));

    FILES
        .lock()
        .unwrap_or_else(|error| error.into_inner())
        .remove(&(file as usize));

    result
}

unsafe extern "C" fn read(
    file: *mut sqlite3_file, buffer: *mut c_void, size: c_int, offset: i64,
) -> c_int {
    let Some(state) = state(file) else {
        return SQLITE_IOERR_READ;
    };

    if let Some(code) = fault(&state, Fault::Read) {
        std::ptr::write_bytes(buffer.cast::<u8>(), 0, size as usize);

        return code;
    }

    state
        .original
        .xRead
        .map_or(SQLITE_IOERR_READ, |read| read(file, buffer, size, offset))
}

unsafe extern "C" fn write(
    file: *mut sqlite3_file, buffer: *const c_void, size: c_int, offset: i64,
) -> c_int {
    let Some(state) = state(file) else {
        return SQLITE_IOERR_WRITE;
    };

    if let Some(code) = fault(&state, Fault::Write) {
        return code;
    }

    state.original.xWrite.map_or(SQLITE_IOERR_WRITE, |write| {
        write(file, buffer, size, offset)
    })
}

unsafe extern "C" fn sync(file: *mut sqlite3_file, flags: c_int) -> c_int {
    let Some(state) = state(file) else {
        return SQLITE_IOERR_FSYNC;
    };

    if let Some(code) = fault(&state, Fault::Sync) {
        return code;
    }

    state
        .original
        .xSync
        .map_or(SQLITE_IOERR_FSYNC, |sync| sync(file, flags))
}
