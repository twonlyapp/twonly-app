// use crate::{bridge::TwonlyConfig, database::Database};
// use std::sync::Arc;

// pub(crate) struct TwonlyStandalone {
//     #[allow(dead_code)]
//     pub(crate) config: TwonlyConfig,
//     /// Because Rust is called from a different process it is safe to write to the twonly_db.
//     pub(crate) twonly_db: Arc<Database>,
// }
