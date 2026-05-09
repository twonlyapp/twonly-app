use serde::{Deserialize, Serialize};
use zeroize::{Zeroize, ZeroizeOnDrop};

#[derive(Debug, PartialEq, Zeroize, ZeroizeOnDrop, Serialize, Deserialize)]
pub(crate) enum IdentityKey {
    Nost(),
    Signal(),
}
