pub mod database;
pub mod error;
use crate::twonly::{database::contact::Contact, error::TwonlyError};
use database::Database;
use error::Result;
use std::sync::Arc;
use tokio::sync::OnceCell;

pub struct TwonlyConfig {
    pub database_path: String,
}

struct Twonly {
    #[allow(dead_code)]
    pub(crate) config: TwonlyConfig,
    database: Arc<Database>,
}

static GLOBAL_TWONLY: OnceCell<Twonly> = OnceCell::const_new();

fn get_instance() -> Result<&'static Twonly> {
    GLOBAL_TWONLY.get().ok_or(TwonlyError::Initialization)
}

pub async fn initialize_twonly(config: TwonlyConfig) -> Result<()> {
    println!("initialized twonly");
    let twonly_res: Result<&'static Twonly> = GLOBAL_TWONLY
        .get_or_try_init(|| async {
            let database = Arc::new(Database::new(&config.database_path).await?);
            Ok(Twonly { config, database })
        })
        .await;

    twonly_res?;

    Ok(())
}

pub async fn get_all_contacts() -> Result<Vec<Contact>> {
    let twonly = get_instance()?;
    Contact::get_all_contacts(twonly.database.as_ref()).await
}

#[cfg(test)]
pub(crate) mod tests {
    use super::error::Result;
    use super::Twonly;
    use std::path::PathBuf;

    use crate::twonly::{get_instance, initialize_twonly, TwonlyConfig};

    pub(super) async fn initialize_twonly_for_testing() -> Result<&'static Twonly> {
        let default_twonly_database = PathBuf::from("tests/testing.db");

        if !default_twonly_database.is_file() {
            panic!("{} not found!", default_twonly_database.display())
        }

        let copied_twonly_database = default_twonly_database
            .parent()
            .unwrap()
            .join("tmp_testing.db");
        if copied_twonly_database.exists() {
            std::fs::remove_file(&copied_twonly_database).unwrap();
        }

        std::fs::copy(default_twonly_database, &copied_twonly_database).unwrap();

        initialize_twonly(TwonlyConfig {
            database_path: copied_twonly_database.display().to_string(),
        })
        .await
        .unwrap();

        get_instance()
    }
}
