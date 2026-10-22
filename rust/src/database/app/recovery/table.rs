#[derive(Debug, Clone, Copy)]

pub enum RecoveryContacts {
    Trusted,
    Eligible,
}

#[derive(Debug, Clone)]

pub struct RecoveryShare {
    pub contact_id: i64,
    pub secret: Vec<u8>,
}
