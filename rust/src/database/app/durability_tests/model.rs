use super::super::contact_groups::table::ContactGroupInput;
use super::super::contact_groups::{self};
use super::super::messages::table::MessagePatch;
use super::super::messages::{self};
use super::super::patch::{NullableBytes, NullableInt, NullableText};
use super::super::receipts::table::{NewReceipt, ReceiptPatch};
use super::super::receipts::writes::ReceiptTarget;
use super::super::receipts::{self};
use rand::rngs::StdRng;
use rand::Rng;
use serde::Serialize;
use sha2::{Digest, Sha256};
use sqlx::{Sqlite, SqliteConnection, Transaction};
use std::collections::{BTreeMap, BTreeSet};

#[derive(Clone, Debug, PartialEq, Eq, Serialize)]

pub(super) struct Group {
    pub id: i64,
    name: String,
    emoji: Option<String>,
    color: i64,
    background: i64,
    shortcut: bool,
    label: bool,
    stories: bool,
    usage: i64,
    created: i64,
}

#[derive(Clone, Debug, PartialEq, Eq, Serialize)]

pub(super) struct Message {
    pub id: String,
    pub content: Option<String>,
    pub payload: Option<Vec<u8>>,
    pub ack: Option<i64>,
}

#[derive(Clone, Debug, PartialEq, Eq, Serialize)]

struct Receipt {
    id: String,
    message_id: Option<String>,
    payload: Vec<u8>,
    retry: i64,
}

#[derive(Clone, Debug, PartialEq, Eq, PartialOrd, Ord, Serialize)]

struct Member {
    label: i64,
    user: i64,
}

#[derive(Clone, Debug, Default, PartialEq, Eq, Serialize)]

pub(super) struct State {
    pub groups: Vec<Group>,
    pub messages: Vec<Message>,
    receipts: Vec<Receipt>,
    members: Vec<Member>,
}

impl State {
    pub(super) fn groups(groups: Vec<contact_groups::table::ContactGroup>) -> Vec<Group> {
        let mut projected: Vec<_> = groups
            .into_iter()
            .map(|group| Group {
                id: group.id,
                name: group.name,
                emoji: group.emoji,
                color: group.text_color,
                background: group.background_color,
                shortcut: group.show_as_shortcut,
                label: group.show_as_label,
                stories: group.share_stories,
                usage: group.usage_counter,
                created: group.created_at,
            })
            .collect();

        projected.sort_by_key(|group| group.id);

        projected
    }

    pub(super) fn digest(&self) -> String {
        hex::encode(Sha256::digest(serde_json::to_vec(self).unwrap()))
    }

    pub(super) async fn read(connection: &mut SqliteConnection) -> Self {
        Self {
            groups: sqlx::query_as!(Group,
                r#"
                    SELECT id, name, emoji, text_color AS color, background_color AS background,
                        show_as_shortcut AS "shortcut!: bool", show_as_label AS "label!: bool",
                        share_stories AS "stories!: bool", usage_counter AS usage, created_at AS created
                    FROM contact_groups ORDER BY id
                "#
            ).fetch_all(&mut *connection).await.unwrap(),
            messages: sqlx::query_as!(Message,
                r#"
                    SELECT message_id AS id, content, additional_message_data AS payload, ack_by_server AS ack
                    FROM messages ORDER BY message_id
                "#
            ).fetch_all(&mut *connection).await.unwrap(),
            receipts: sqlx::query_as!(Receipt,
                r#"
                    SELECT receipt_id AS id, message_id, message AS payload, retry_count AS retry
                    FROM receipts ORDER BY receipt_id
                "#
            ).fetch_all(&mut *connection).await.unwrap(),
            members: sqlx::query_as!(Member,
                r#"
                    SELECT contact_group_id AS label, user_id AS "user!"
                    FROM contact_group_members WHERE user_id IS NOT NULL
                    ORDER BY contact_group_id, user_id
                "#
            ).fetch_all(connection).await.unwrap(),
        }
    }
}

#[derive(Clone)]

struct Record {
    group: Group,
    message: Message,
    receipt: Receipt,
    users: BTreeSet<i64>,
}

#[derive(Clone, Default)]

pub(super) struct Model(BTreeMap<usize, Record>);

impl Model {
    pub(super) fn state(&self) -> State {
        let mut state = State::default();

        for value in self.0.values() {
            state.groups.push(value.group.clone());

            state.messages.push(value.message.clone());

            state.receipts.push(value.receipt.clone());

            state.members.extend(value.users.iter().map(|user| Member {
                label: value.group.id,
                user: *user,
            }));
        }

        state.groups.sort_by_key(|group| group.id);

        state.messages.sort_by(|a, b| a.id.cmp(&b.id));

        state.receipts.sort_by(|a, b| a.id.cmp(&b.id));

        state.members.sort();

        state
    }

    pub(super) async fn change(
        &mut self, tx: &mut Transaction<'_, Sqlite>, slot: usize, kind: u8, ordinal: i64,
        rng: &mut StdRng,
    ) {
        let id = format!("soak-{slot:02}");

        if let std::collections::btree_map::Entry::Vacant(e) = self.0.entry(slot) {
            let input = ContactGroupInput {
                name: format!("slot-{slot}-{ordinal}"),
                emoji: Some("⭐".into()),
                text_color: 0xff001122,
                background_color: 0,
                show_as_shortcut: true,
                show_as_label: true,
                share_stories: false,
            };

            let group_id = contact_groups::writes::create(tx, &input).await.unwrap();

            let created = 1_700_000_000 + ordinal;

            sqlx::query!(
                "UPDATE contact_groups SET created_at = ? WHERE id = ?",
                created,
                group_id
            )
            .execute(&mut **tx)
            .await
            .unwrap();

            let content = Some(format!("content-{slot}-{ordinal}"));

            let payload = Some(vec![0, 255, slot as u8, ordinal as u8]);

            messages::writes::upsert(
                tx,
                MessagePatch {
                    message_id: Some(id.clone()),
                    group_id: Some("soak-chat".into()),
                    sender_id: Some(NullableInt { value: Some(7) }),
                    r#type: Some("text".into()),
                    content: Some(NullableText {
                        value: content.clone(),
                    }),
                    additional_message_data: Some(NullableBytes {
                        value: payload.clone(),
                    }),
                    created_at: Some(created),
                    ..Default::default()
                },
            )
            .await
            .unwrap();

            NewReceipt::new(&id, 7, &[0, 255, slot as u8])
                .insert(tx)
                .await
                .unwrap();

            receipts::writes::update(
                tx,
                ReceiptTarget::Id(&id),
                ReceiptPatch {
                    message_id: Some(NullableText {
                        value: Some(id.clone()),
                    }),
                    ..Default::default()
                },
            )
            .await
            .unwrap();

            e.insert(Record {
                group: Group {
                    id: group_id,
                    name: input.name,
                    emoji: input.emoji,
                    color: input.text_color,
                    background: input.background_color,
                    shortcut: true,
                    label: true,
                    stories: false,
                    usage: 0,
                    created,
                },
                message: Message {
                    id: id.clone(),
                    content,
                    payload,
                    ack: None,
                },
                receipt: Receipt {
                    id: id.clone(),
                    message_id: Some(id),
                    payload: vec![0, 255, slot as u8],
                    retry: 0,
                },
                users: BTreeSet::new(),
            });

            return;
        }

        let value = self.0.get_mut(&slot).unwrap();

        match kind {
            0 | 6 | 7 => {
                let input = ContactGroupInput {
                    name: format!("slot-{slot}-{ordinal}"),
                    emoji: rng.random_bool(0.5).then(|| "🦀".into()),
                    text_color: rng.random_range(0..=u32::MAX) as i64,
                    background_color: rng.random_range(0..=u32::MAX) as i64,
                    show_as_shortcut: rng.random(),
                    show_as_label: rng.random(),
                    share_stories: rng.random(),
                };

                assert!(contact_groups::writes::update(tx, value.group.id, &input)
                    .await
                    .unwrap());

                value.group.name = input.name;

                value.group.emoji = input.emoji;

                value.group.color = input.text_color;

                value.group.background = input.background_color;

                value.group.shortcut = input.show_as_shortcut;

                value.group.label = input.show_as_label;

                value.group.stories = input.share_stories;
            }
            1 => {
                contact_groups::writes::increment_usage(tx, value.group.id)
                    .await
                    .unwrap();

                value.group.usage += 1;
            }
            2 => {
                let user = if rng.random() { 7 } else { 8 };

                let selected = rng.random();

                contact_groups::writes::set_user_membership(tx, value.group.id, user, selected)
                    .await
                    .unwrap();

                if selected {
                    value.users.insert(user);
                } else {
                    value.users.remove(&user);
                }
            }
            3 => {
                let content = rng
                    .random_bool(0.5)
                    .then(|| format!("edited-{slot}-{ordinal}"));

                let bytes: Vec<u8> = (0..rng.random_range(1..256))
                    .map(|_| rng.random())
                    .collect();

                let payload = rng.random_bool(0.75).then(|| bytes.clone());

                messages::writes::update(
                    tx,
                    &id,
                    MessagePatch {
                        content: Some(NullableText {
                            value: content.clone(),
                        }),
                        additional_message_data: Some(NullableBytes {
                            value: payload.clone(),
                        }),
                        ..Default::default()
                    },
                )
                .await
                .unwrap();

                receipts::writes::update(
                    tx,
                    ReceiptTarget::Id(&id),
                    ReceiptPatch {
                        message: Some(bytes.clone()),
                        ..Default::default()
                    },
                )
                .await
                .unwrap();

                value.message.content = content;

                value.message.payload = payload;

                value.receipt.payload = bytes;
            }
            4 => {
                contact_groups::writes::delete(tx, value.group.id)
                    .await
                    .unwrap();

                messages::writes::delete(tx, &id).await.unwrap();

                self.0.remove(&slot);
            }
            5 => {
                let ack = rng.random_bool(0.75).then_some(1_700_000_000 + ordinal);

                messages::writes::update(
                    tx,
                    &id,
                    MessagePatch {
                        ack_by_server: Some(NullableInt { value: ack }),
                        ..Default::default()
                    },
                )
                .await
                .unwrap();

                value.message.ack = ack;

                value.receipt.retry += 1;

                receipts::writes::update(
                    tx,
                    ReceiptTarget::Id(&id),
                    ReceiptPatch {
                        retry_count: Some(value.receipt.retry),
                        ..Default::default()
                    },
                )
                .await
                .unwrap();
            }
            _ => unreachable!(),
        }
    }
}
