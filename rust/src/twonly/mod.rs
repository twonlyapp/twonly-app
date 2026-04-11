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
