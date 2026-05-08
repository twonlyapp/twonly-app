use serde::{Deserialize, Serialize};
use zeroize::{Zeroize, ZeroizeOnDrop};

#[derive(Zeroize, ZeroizeOnDrop, Serialize, Deserialize)]
pub(crate) enum IdentityKey {
    Nost(),
    Signal(),
}
