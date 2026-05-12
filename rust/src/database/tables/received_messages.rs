#![allow(dead_code)]
use chrono::{DateTime, Utc};
use sqlx::FromRow;

#[derive(Debug, FromRow, PartialEq, Clone)]
pub struct ReceivedMessage {
    pub id: i64,
    pub sender_id: i64,
    pub content: Vec<u8>,
    pub timestamp: DateTime<Utc>,
}

impl ReceivedMessage {
    crate::generate_insert!(
        "received_messages",
        insert,
        sender_id: i64,
        content: &[u8]
    );
    crate::generate_select!("received_messages", get_all);
    crate::generate_select!("received_messages", get_by_sender, sender_id: i64);
}

crate::generate_table_tests!(ReceivedMessage, insert(1, b"hello world"), get_all);

crate::generate_test_select!(ReceivedMessage, insert(1, b"hello world"), get_by_sender(1));
