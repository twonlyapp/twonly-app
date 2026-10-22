//! Crash-recoverable replacement of the app/Signal databases and settings.
//! All live handles are closed before entry. A durable journal keeps readers
//! out until either the complete new generation or the old one is durable.

use super::lifecycle::Operation;
use super::maintenance::{Exclusive, RESTORE_JOURNAL};
use crate::bridge::InitConfig;
use crate::error::{Result, TwonlyError};
use crate::secure_storage::SecureStorage;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};
use std::fs::{self, File, OpenOptions};
use std::io::{Read, Write};
use std::path::{Path, PathBuf};

#[derive(Clone, Copy, Debug, Deserialize, Serialize, PartialEq, Eq, PartialOrd, Ord)]

enum Target {
    App,
    Signal,
    AppWal,
    SignalWal,
    AppJournal,
    SignalJournal,
    AppShm,
    SignalShm,
    User,
    Discovery,
}

const DATABASES: &[Target] = &[Target::App, Target::Signal];

const REQUIRED: &[Target] = &[
    Target::App,
    Target::Signal,
    Target::AppWal,
    Target::SignalWal,
    Target::AppJournal,
    Target::SignalJournal,
    Target::AppShm,
    Target::SignalShm,
];

impl Target {
    fn name(self) -> &'static str {
        match self {
            Self::App => "app_db.sqlite",
            Self::Signal => "rust_db.sqlite",
            Self::AppWal => "app_db.sqlite-wal",
            Self::SignalWal => "rust_db.sqlite-wal",
            Self::AppJournal => "app_db.sqlite-journal",
            Self::SignalJournal => "rust_db.sqlite-journal",
            Self::AppShm => "app_db.sqlite-shm",
            Self::SignalShm => "rust_db.sqlite-shm",
            Self::User => "user.json",
            Self::Discovery => "user_discovery_config.json",
        }
    }

    fn shm(self) -> bool {
        matches!(self, Self::AppShm | Self::SignalShm)
    }
}

#[derive(Clone, Copy, Debug, Deserialize, Serialize, PartialEq, Eq)]

enum Phase {
    Pending,
    Committed,
    RolledBack,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]

struct Entry {
    target: Target,
    original: bool,
    replacement: bool,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(deny_unknown_fields)]

struct Journal {
    version: u32,
    id: String,
    data_dir: PathBuf,
    phase: Phase,
    entries: Vec<Entry>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    identity: Option<String>,
}

#[derive(Deserialize, Serialize)]
#[serde(deny_unknown_fields)]

struct Envelope {
    journal: Journal,
    sha256: String,
}

struct Roots {
    database: PathBuf,
    data: PathBuf,
}

impl Roots {
    fn new(config: &InitConfig) -> Result<Self> {
        Ok(Self {
            database: fs::canonicalize(&config.database_dir)?,
            data: fs::canonicalize(&config.data_dir)?,
        })
    }

    fn target(&self, target: Target) -> PathBuf {
        match target {
            Target::User => self.data.join("keyvalue/user.json"),
            Target::Discovery => self.data.join(target.name()),
            _ => self.database.join(target.name()),
        }
    }

    fn journal(&self) -> PathBuf {
        self.database.join(RESTORE_JOURNAL)
    }

    fn shadow(&self, journal: &Journal, target: Target, suffix: &str) -> PathBuf {
        self.target(target).with_file_name(format!(
            ".twonly-restore-{}-{}.{suffix}",
            journal.id,
            target.name()
        ))
    }

    fn admission(&self) -> Result<Vec<Exclusive>> {
        Exclusive::acquire_all(DATABASES.iter().map(|target| self.target(*target)))
    }
}

fn invalid(message: impl Into<String>) -> TwonlyError {
    TwonlyError::Generic(message.into())
}

fn sync_parent(path: &Path) -> Result<()> {
    File::open(path.parent().unwrap())?.sync_all()?;

    Ok(())
}

fn remove(path: &Path) -> Result<()> {
    match fs::remove_file(path) {
        Ok(()) => {}
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => {}
        Err(error) => return Err(error.into()),
    }

    Ok(())
}

fn copy(source: &Path, destination: &Path, operation: Option<&Operation>) -> Result<()> {
    let mut input = File::open(source)?;

    let mut options = OpenOptions::new();

    options.write(true).create_new(true);

    #[cfg(unix)]
    {
        use std::os::unix::fs::OpenOptionsExt;

        options.mode(0o600);
    }

    let mut output = options.open(destination)?;

    let mut buffer = [0u8; 64 * 1024];

    loop {
        if let Some(operation) = operation {
            operation.check()?;
        }

        let read = input.read(&mut buffer)?;

        if read == 0 {
            break;
        }

        output.write_all(&buffer[..read])?;
    }

    output.sync_all()?;

    Ok(())
}

fn retain(source: &Path, destination: &Path, operation: Option<&Operation>) -> Result<()> {
    // These private links are never opened by SQLite and are removed before
    // admitting readers. Retaining an immutable, closed file is inexpensive.
    match fs::hard_link(source, destination) {
        Ok(()) => File::open(destination)?.sync_all()?,
        Err(error) if error.kind() == std::io::ErrorKind::AlreadyExists => return Err(error.into()),
        Err(_) => copy(source, destination, operation)?,
    }

    Ok(())
}

fn write_journal(
    roots: &Roots, journal: &Journal, hook: &mut impl FnMut(&str) -> Result<()>,
) -> Result<()> {
    let temporary = roots
        .database
        .join(format!(".twonly-restore-{}.journal", journal.id));

    let mut file = File::create(&temporary)?;

    let envelope = Envelope {
        journal: journal.clone(),
        sha256: hex::encode(Sha256::digest(serde_json::to_vec(journal)?)),
    };

    file.write_all(&serde_json::to_vec(&envelope)?)?;

    file.sync_all()?;

    fs::rename(&temporary, roots.journal())?;

    hook(match journal.phase {
        Phase::Pending => "pending published",
        Phase::Committed => "commit published",
        Phase::RolledBack => "rollback published",
    })?;

    sync_parent(&roots.journal())?;

    hook("journal directory synced")
}

fn read_journal(roots: &Roots) -> Result<Journal> {
    if fs::metadata(roots.journal())?.len() > 64 * 1024 {
        return Err(invalid(
            "Restore journal is too large; existing files were preserved",
        ));
    }

    let envelope: Envelope = serde_json::from_reader(File::open(roots.journal())?)?;

    if envelope.sha256 != hex::encode(Sha256::digest(serde_json::to_vec(&envelope.journal)?)) {
        return Err(invalid(
            "Restore journal checksum mismatch; existing files were preserved",
        ));
    }

    let journal = envelope.journal;

    let targets = journal
        .entries
        .iter()
        .map(|entry| entry.target)
        .collect::<std::collections::BTreeSet<_>>();

    if journal.version != 1
        || uuid::Uuid::parse_str(&journal.id).is_err()
        || journal
            .identity
            .as_ref()
            .is_some_and(|id| uuid::Uuid::parse_str(id).is_err())
        || journal.data_dir != roots.data
        || targets.len() != journal.entries.len()
        || REQUIRED.iter().any(|target| !targets.contains(target))
        || journal.entries.iter().any(|entry| {
            (matches!(
                entry.target,
                Target::App | Target::Signal | Target::User | Target::Discovery
            ) != entry.replacement)
                || (entry.target.shm() && entry.original)
        })
    {
        return Err(invalid(
            "Invalid restore journal; existing files were preserved",
        ));
    }

    Ok(journal)
}

fn remove_orphans(roots: &Roots, operation: Option<&Operation>) -> Result<()> {
    // Exclusive access and the absence of a journal establish that no other
    // process is preparing these siblings. Reclaim unpublished crash leftovers
    // before allocating another complete candidate set.
    let mut targets = REQUIRED.to_vec();

    targets.extend([Target::User, Target::Discovery]);

    let directories = targets
        .iter()
        .map(|target| roots.target(*target).parent().unwrap().to_owned())
        .collect::<std::collections::BTreeSet<_>>();

    for directory in directories {
        if !directory.exists() {
            continue;
        }

        for entry in fs::read_dir(directory)? {
            if let Some(operation) = operation {
                operation.check()?;
            }

            let entry = entry?;

            let name = entry.file_name();

            let Some(name) = name
                .to_str()
                .and_then(|name| name.strip_prefix(".twonly-restore-"))
            else {
                continue;
            };

            let Some((id, tail)) = name.split_at_checked(36) else {
                continue;
            };

            if uuid::Uuid::parse_str(id).is_err() {
                continue;
            }

            let known = tail == ".journal"
                || targets.iter().any(|target| {
                    ["old", "new", "rollback"]
                        .iter()
                        .any(|suffix| tail == format!("-{}.{suffix}", target.name()))
                });

            if known {
                remove(&entry.path())?;

                sync_parent(&entry.path())?;
            }
        }
    }

    Ok(())
}

fn cleanup(
    roots: &Roots, journal: &Journal, hook: &mut impl FnMut(&str) -> Result<()>,
) -> Result<()> {
    for entry in &journal.entries {
        for suffix in ["old", "new", "rollback"] {
            let path = roots.shadow(journal, entry.target, suffix);

            remove(&path)?;

            sync_parent(&path)?;

            hook("shadow removed")?;
        }
    }

    remove(
        &roots
            .database
            .join(format!(".twonly-restore-{}.journal", journal.id)),
    )?;

    remove(&roots.journal())?;

    hook("journal removed")?;

    sync_parent(&roots.journal())?;

    Ok(())
}

fn recover_locked(
    roots: &Roots, storage: Option<&SecureStorage>, hook: &mut impl FnMut(&str) -> Result<()>,
) -> Result<Option<Phase>> {
    if !roots.journal().try_exists()? {
        return Ok(None);
    }

    let mut journal = read_journal(roots)?;

    if journal.phase == Phase::Pending {
        // Check the complete rollback set before modifying any live target.
        for entry in &journal.entries {
            if entry.original && !roots.shadow(&journal, entry.target, "old").is_file() {
                return Err(invalid(
                    "Restore rollback file is missing; recovery remains required",
                ));
            }
        }

        for entry in &journal.entries {
            let target = roots.target(entry.target);

            if entry.original {
                let rollback = roots.shadow(&journal, entry.target, "rollback");

                remove(&rollback)?;

                retain(
                    &roots.shadow(&journal, entry.target, "old"),
                    &rollback,
                    None,
                )?;

                fs::rename(rollback, &target)?;
            } else {
                remove(&target)?;
            }

            hook("original restored")?;

            sync_parent(&target)?;

            hook("original directory synced")?;
        }

        journal.phase = Phase::RolledBack;

        write_journal(roots, &journal, hook)?;
    } else {
        // A terminal journal may outlive partial cleanup. Never overwrite
        // files again: configuration callbacks may have resumed after unlink.
        File::open(roots.journal())?.sync_all()?;

        sync_parent(&roots.journal())?;
    }

    if journal.phase == Phase::Committed {
        apply_identity(storage, &journal, hook)?;
    }

    let phase = journal.phase;

    cleanup(roots, &journal, hook)?;

    Ok(Some(phase))
}

fn apply_identity(
    storage: Option<&SecureStorage>, journal: &Journal, hook: &mut impl FnMut(&str) -> Result<()>,
) -> Result<()> {
    if let Some(id) = &journal.identity {
        let storage =
            storage.ok_or_else(|| invalid("Secure storage is required for restore recovery"))?;

        crate::keys::restore::apply(storage, id, hook)?;
    }

    Ok(())
}

/// Before any keys, SQLite handles or restored settings are read on startup.

pub(crate) async fn recover_before_open(config: &InitConfig) -> Result<()> {
    recover_with_storage(config, SecureStorage::new("eu.twonly")).await
}

pub(crate) async fn recover_with_storage(
    config: &InitConfig, storage: SecureStorage,
) -> Result<()> {
    if !Path::new(&config.database_dir)
        .join(RESTORE_JOURNAL)
        .try_exists()?
    {
        return Ok(());
    }

    SecureStorage::init()?;

    let roots = Roots::new(config)?;

    let operation = Operation::current();

    super::lifecycle::spawn_blocking(move || {
        if let Some(operation) = operation {
            operation.check()?;
        }

        let _admission = roots.admission()?;

        recover_locked(&roots, Some(&storage), &mut |_| Ok(())).map(|_| ())
    })
    .await
    .map_err(|error| invalid(format!("Restore recovery worker failed: {error}")))?
}

pub(crate) fn install(
    config: &InitConfig, staging: &Path, operation: Option<&Operation>, storage: &SecureStorage,
    identity: Option<&str>,
) -> Result<()> {
    install_coordinated(
        config,
        staging,
        operation,
        Some(storage),
        identity,
        &mut |_| Ok(()),
    )
}

#[cfg(test)]

fn install_with(
    config: &InitConfig, staging: &Path, operation: Option<&Operation>,
    hook: &mut impl FnMut(&str) -> Result<()>,
) -> Result<()> {
    install_coordinated(config, staging, operation, None, None, hook)
}

fn install_coordinated(
    config: &InitConfig, staging: &Path, operation: Option<&Operation>,
    storage: Option<&SecureStorage>, identity: Option<&str>,
    hook: &mut impl FnMut(&str) -> Result<()>,
) -> Result<()> {
    if let Some(operation) = operation {
        operation.check()?;
    }

    let roots = Roots::new(config)?;

    let _admission = roots.admission()?;

    recover_locked(&roots, storage, &mut |_| Ok(()))?;

    if let Some(id) = identity {
        crate::keys::restore::validate(
            storage.ok_or_else(|| invalid("Restore identity requires secure storage"))?,
            id,
        )?;
    }

    remove_orphans(&roots, operation)?;

    if let Some(operation) = operation {
        operation.check()?;
    }

    let mut journal = Journal {
        version: 1,
        id: uuid::Uuid::new_v4().to_string(),
        data_dir: roots.data.clone(),
        phase: Phase::Pending,
        entries: Vec::new(),
        identity: identity.map(str::to_owned),
    };

    let mut committed = false;

    let prepared = (|| {
        let mut targets = REQUIRED.to_vec();

        if staging.join(Target::User.name()).exists() || roots.target(Target::User).exists() {
            targets.push(Target::User);
        }

        if staging.join(Target::Discovery.name()).exists() {
            targets.push(Target::Discovery);
        }

        for target in targets {
            let destination = roots.target(target);

            fs::create_dir_all(destination.parent().unwrap())?;

            let exists = match fs::symlink_metadata(&destination) {
                Ok(metadata) if metadata.is_file() => true,
                Ok(_) => return Err(invalid("Restore target is not a regular file")),
                Err(error) if error.kind() == std::io::ErrorKind::NotFound => false,
                Err(error) => return Err(error.into()),
            };

            let replacement = matches!(
                target,
                Target::App | Target::Signal | Target::User | Target::Discovery
            );

            journal.entries.push(Entry {
                target,
                original: exists && !target.shm(),
                replacement,
            });

            if exists && !target.shm() {
                retain(
                    &destination,
                    &roots.shadow(&journal, target, "old"),
                    operation,
                )?;
            }

            if replacement {
                let source = staging.join(target.name());

                let candidate = roots.shadow(&journal, target, "new");

                if target == Target::User {
                    let source = if source.exists() {
                        source
                    } else {
                        destination.clone()
                    };

                    let mut settings: serde_json::Value =
                        serde_json::from_reader(File::open(source)?)?;

                    let object = settings
                        .as_object_mut()
                        .ok_or_else(|| invalid("Invalid restored user settings"))?;

                    // Restored ratchets are discarded in staging. Republish
                    // prekeys before peers start new sessions against them.
                    object.insert(
                        "signalLastSignedPreKeyUpdated".into(),
                        serde_json::Value::Null,
                    );

                    object.insert(
                        "signalLastPqcPreKeysUploaded".into(),
                        serde_json::Value::Null,
                    );

                    let mut file = OpenOptions::new()
                        .write(true)
                        .create_new(true)
                        .open(candidate)?;

                    file.write_all(&serde_json::to_vec(&settings)?)?;

                    file.sync_all()?;
                } else {
                    copy(&source, &candidate, operation)?;
                }
            }

            sync_parent(&destination)?;

            hook("target prepared")?;
        }

        if let Some(operation) = operation {
            operation.check()?;
        }

        write_journal(&roots, &journal, hook)?;

        for entry in &journal.entries {
            let target = roots.target(entry.target);

            if entry.replacement {
                fs::rename(roots.shadow(&journal, entry.target, "new"), &target)?;
            } else {
                remove(&target)?;
            }

            hook("target installed")?;

            sync_parent(&target)?;

            hook("target directory synced")?;
        }

        journal.phase = Phase::Committed;

        write_journal(&roots, &journal, hook)?;

        committed = true;

        apply_identity(storage, &journal, hook)?;

        cleanup(&roots, &journal, hook)
    })();

    match prepared {
        Ok(()) => Ok(()),
        Err(error) if roots.journal().exists() => {
            // Resolve a single failure while exclusive access is still held.
            // If recovery also fails, leave the journal blocking all opens.
            let resolved = recover_locked(&roots, storage, &mut |_| Ok(()))?;

            if resolved == Some(Phase::Committed) {
                Ok(())
            } else {
                Err(error)
            }
        }
        Err(error) => {
            // A pre-publication failure changed no live files. If cleanup
            // already unlinked a committed journal, finish syncing that cleanup.
            cleanup(&roots, &journal, &mut |_| Ok(()))?;

            if committed {
                Ok(())
            } else {
                Err(error)
            }
        }
    }
}

#[cfg(test)]
mod tests;
