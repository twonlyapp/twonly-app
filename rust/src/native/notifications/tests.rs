use super::*;

unsafe fn response(pointer: *mut c_char) -> serde_json::Value {
    let json = unsafe { CStr::from_ptr(pointer) }
        .to_str()
        .unwrap()
        .to_owned();

    unsafe { twonly_notification_string_free(pointer) };

    serde_json::from_str(&json).unwrap()
}

#[test]

fn cancelled_queued_notification_never_creates_a_database_directory() {
    let directory = tempfile::tempdir().unwrap();

    let missing = directory.path().join("not-opened");

    let path = CString::new(missing.to_str().unwrap()).unwrap();

    let locale = CString::new("en").unwrap();

    let run = twonly_notification_run_create(5_000);

    assert_ne!(run, 0);

    twonly_database_operation_cancel(run);

    let result = unsafe {
        response(twonly_notification_process_with_id(
            run,
            path.as_ptr(),
            path.as_ptr(),
            locale.as_ptr(),
            1_000,
        ))
    };

    assert_eq!(result["ok"], false);

    twonly_notification_run_finish(run);

    assert!(!missing.exists());
}

#[test]

fn late_acknowledgement_and_expiration_cannot_enter_the_next_run() {
    let old = twonly_notification_run_create(5_000);

    twonly_notification_run_finish(old);

    let next = twonly_notification_run_create(5_000);

    twonly_database_operation_cancel(old);

    let result = unsafe {
        response(twonly_notification_acknowledge_with_id(
            old,
            std::ptr::null(),
        ))
    };

    assert_eq!(result["ok"], false);

    let session = Session::find(next).unwrap();

    assert_eq!(
        runtime()
            .unwrap()
            .block_on(session.execute(async { Ok(42) }, true))
            .unwrap(),
        42
    );

    twonly_notification_run_finish(next);
}
