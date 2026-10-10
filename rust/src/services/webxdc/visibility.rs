//! A foreground app's visibility, shared with native notification processes.
//!
//! The file lock is held only while an instance is on screen. The OS releases
//! it on process death, so a crash cannot leave future turn alerts suppressed.

use std::fs::{File, OpenOptions, TryLockError};
use std::io::{Read, Seek, Write};
use std::path::Path;
use std::sync::Mutex;

const FILE_NAME: &str = "webxdc-visible-instance";

#[derive(Default)]
pub(crate) struct Visibility {
    lease: Mutex<Option<(String, File)>>,
}

impl Visibility {
    pub(crate) fn set(&self, directory: &Path, instance_id: Option<&str>) -> std::io::Result<()> {
        let mut lease = self.lease.lock().unwrap();
        if lease.as_ref().map(|(id, _)| id.as_str()) == instance_id {
            return Ok(());
        }
        if let Some(instance_id) = instance_id {
            if let Some((id, file)) = lease.as_mut() {
                file.set_len(0)?;
                file.rewind()?;
                file.write_all(instance_id.as_bytes())?;
                *id = instance_id.to_owned();
                return Ok(());
            }
            // Never delete the file: every process must open the same inode
            // to observe the lock, which the OS releases on process death.
            let mut file = OpenOptions::new()
                .create(true)
                .truncate(false)
                .read(true)
                .write(true)
                .open(directory.join(FILE_NAME))?;
            file.try_lock().map_err(std::io::Error::from)?;
            file.set_len(0)?;
            file.write_all(instance_id.as_bytes())?;
            *lease = Some((instance_id.to_owned(), file));
        } else {
            *lease = None;
        }
        Ok(())
    }
}

pub(crate) fn visible_instance(directory: &Path) -> Option<String> {
    let mut file = File::open(directory.join(FILE_NAME)).ok()?;
    // Unlocked files are old state from a closed or killed app.
    if !matches!(file.try_lock(), Err(TryLockError::WouldBlock)) {
        return None;
    }
    let mut instance_id = String::new();
    file.read_to_string(&mut instance_id).ok()?;
    (!instance_id.is_empty()).then_some(instance_id)
}

#[cfg(test)]
mod tests {
    use super::*;

    // Spawning the probe briefly forks this process before exec closes inherited
    // descriptors. Keep that fork from extending the other test's file locks.
    static TEST_LOCK: Mutex<()> = Mutex::new(());

    #[test]
    fn visibility_is_shared_with_notification_processes() -> std::io::Result<()> {
        let _guard = TEST_LOCK.lock().unwrap();
        const PROBE_DIRECTORY: &str = "TWONLY_WEBXDC_VISIBILITY_PROBE_DIRECTORY";
        if let Some(directory) = std::env::var_os(PROBE_DIRECTORY) {
            assert_eq!(
                visible_instance(Path::new(&directory)).as_deref(),
                Some("game")
            );
            return Ok(());
        }
        let directory = tempfile::tempdir()?;
        let visibility = Visibility::default();
        visibility.set(directory.path(), Some("game"))?;
        let result = std::process::Command::new(std::env::current_exe()?)
            .arg("--exact")
            .arg("services::webxdc::visibility::tests::visibility_is_shared_with_notification_processes")
            .env(PROBE_DIRECTORY, directory.path())
            .output()?;
        assert!(
            result.status.success(),
            "{}",
            String::from_utf8_lossy(&result.stdout)
        );
        Ok(())
    }

    #[test]
    fn visibility_requires_a_live_lease_and_tracks_the_instance() -> std::io::Result<()> {
        let _guard = TEST_LOCK.lock().unwrap();
        let directory = tempfile::tempdir()?;
        let visibility = Visibility::default();
        assert_eq!(visible_instance(directory.path()), None);
        visibility.set(directory.path(), Some("connect4-chat-a"))?;
        assert_eq!(
            visible_instance(directory.path()).as_deref(),
            Some("connect4-chat-a")
        );
        visibility.set(directory.path(), Some("mills-chat-b"))?;
        assert_eq!(
            visible_instance(directory.path()).as_deref(),
            Some("mills-chat-b")
        );
        visibility.set(directory.path(), None)?;
        assert_eq!(visible_instance(directory.path()), None);
        visibility.set(directory.path(), Some("connect4-chat-a"))?;
        drop(visibility);
        assert_eq!(visible_instance(directory.path()), None);
        Ok(())
    }
}
