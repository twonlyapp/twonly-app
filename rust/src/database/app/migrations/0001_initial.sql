CREATE TABLE contacts (
    user_id INTEGER NOT NULL PRIMARY KEY,
    username TEXT NOT NULL,
    display_name TEXT,
    nick_name TEXT,
    avatar_svg_compressed BLOB,
    sender_profile_counter INTEGER NOT NULL DEFAULT 0,
    accepted INTEGER NOT NULL DEFAULT 0 CHECK (accepted IN (0, 1)),
    deleted_by_user INTEGER NOT NULL DEFAULT 0 CHECK (deleted_by_user IN (0, 1)),
    requested INTEGER NOT NULL DEFAULT 0 CHECK (requested IN (0, 1)),
    blocked INTEGER NOT NULL DEFAULT 0 CHECK (blocked IN (0, 1)),
    verified INTEGER NOT NULL DEFAULT 0 CHECK (verified IN (0, 1)),
    account_deleted INTEGER NOT NULL DEFAULT 0 CHECK (account_deleted IN (0, 1)),
    created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
    signal_version TEXT NOT NULL DEFAULT 'v1',
    user_discovery_version BLOB,
    user_discovery_excluded INTEGER NOT NULL DEFAULT 0 CHECK (user_discovery_excluded IN (0, 1)),
    user_discovery_manual_approved INTEGER DEFAULT 0 CHECK (user_discovery_manual_approved IN (0, 1)),
    recovery_is_trusted_friend INTEGER NOT NULL DEFAULT 0 CHECK (recovery_is_trusted_friend IN (0, 1)),
    recovery_last_heartbeat INTEGER,
    recovery_secret_share BLOB,
    recovery_contacts_secret_share BLOB,
    recovery_contacts_last_heartbeat INTEGER,
    recovery_contacts_threshold INTEGER,
    ask_for_friend_promotions INTEGER CHECK (ask_for_friend_promotions IN (0, 1)),
    media_send_counter INTEGER NOT NULL DEFAULT 0,
    media_received_counter INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE groups (
    group_id TEXT NOT NULL PRIMARY KEY,
    is_group_admin INTEGER NOT NULL DEFAULT 0 CHECK (is_group_admin IN (0, 1)),
    is_direct_chat INTEGER NOT NULL DEFAULT 0 CHECK (is_direct_chat IN (0, 1)),
    pinned INTEGER NOT NULL DEFAULT 0 CHECK (pinned IN (0, 1)),
    archived INTEGER NOT NULL DEFAULT 0 CHECK (archived IN (0, 1)),
    joined_group INTEGER NOT NULL DEFAULT 0 CHECK (joined_group IN (0, 1)),
    left_group INTEGER NOT NULL DEFAULT 0 CHECK (left_group IN (0, 1)),
    deleted_content INTEGER NOT NULL DEFAULT 0 CHECK (deleted_content IN (0, 1)),
    state_version_id INTEGER NOT NULL DEFAULT 0,
    state_encryption_key BLOB,
    my_group_private_key BLOB,
    group_name TEXT NOT NULL,
    draft_message TEXT,
    total_media_counter INTEGER NOT NULL DEFAULT 0,
    also_best_friend INTEGER NOT NULL DEFAULT 0 CHECK (also_best_friend IN (0, 1)),
    delete_messages_after_milliseconds INTEGER NOT NULL DEFAULT 86400000,
    created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
    last_message_send INTEGER,
    last_message_received INTEGER,
    last_flame_counter_change INTEGER,
    last_flame_sync INTEGER,
    flame_counter INTEGER NOT NULL DEFAULT 0,
    max_flame_counter INTEGER NOT NULL DEFAULT 0,
    max_flame_counter_from INTEGER,
    last_message_exchange INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
);

CREATE TABLE media_files (
    media_id TEXT NOT NULL PRIMARY KEY,
    type TEXT NOT NULL,
    upload_state TEXT,
    cloud_state TEXT NOT NULL DEFAULT 'none',
    blurhash TEXT,
    download_state TEXT,
    requires_authentication INTEGER NOT NULL DEFAULT 0 CHECK (requires_authentication IN (0, 1)),
    stored INTEGER NOT NULL DEFAULT 0 CHECK (stored IN (0, 1)),
    is_draft_media INTEGER NOT NULL DEFAULT 0 CHECK (is_draft_media IN (0, 1)),
    is_favorite INTEGER NOT NULL DEFAULT 0 CHECK (is_favorite IN (0, 1)),
    has_crop_analyzed INTEGER NOT NULL DEFAULT 0 CHECK (has_crop_analyzed IN (0, 1)),
    pre_progressing_process INTEGER,
    reupload_requested_by TEXT,
    display_limit_in_milliseconds INTEGER,
    remove_audio INTEGER CHECK (remove_audio IN (0, 1)),
    download_token BLOB,
    encryption_key BLOB,
    encryption_mac BLOB,
    encryption_nonce BLOB,
    stored_file_hash BLOB,
    has_thumbnail INTEGER NOT NULL DEFAULT 0 CHECK (has_thumbnail IN (0, 1)),
    size_in_bytes INTEGER,
    created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
    created_at_month TEXT
);

CREATE TABLE messages (
    group_id TEXT NOT NULL REFERENCES groups(group_id) ON DELETE CASCADE,
    message_id TEXT NOT NULL PRIMARY KEY,
    sender_id INTEGER REFERENCES contacts(user_id),
    type TEXT NOT NULL,
    content TEXT,
    media_id TEXT REFERENCES media_files(media_id) ON DELETE SET NULL,
    additional_message_data BLOB,
    media_stored INTEGER NOT NULL DEFAULT 0 CHECK (media_stored IN (0, 1)),
    media_reopened INTEGER NOT NULL DEFAULT 0 CHECK (media_reopened IN (0, 1)),
    download_token BLOB,
    quotes_message_id TEXT,
    is_deleted_from_sender INTEGER NOT NULL DEFAULT 0 CHECK (is_deleted_from_sender IN (0, 1)),
    opened_at INTEGER,
    opened_by_all INTEGER,
    created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
    modified_at INTEGER,
    ack_by_user INTEGER,
    ack_by_server INTEGER
);
CREATE INDEX idx_messages_group_id_created_at ON messages(group_id, created_at);

CREATE TABLE message_histories (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    message_id TEXT NOT NULL REFERENCES messages(message_id) ON DELETE CASCADE,
    contact_id INTEGER REFERENCES contacts(user_id) ON DELETE CASCADE,
    content TEXT,
    created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
);

CREATE TABLE reactions (
    message_id TEXT NOT NULL REFERENCES messages(message_id) ON DELETE CASCADE,
    emoji TEXT NOT NULL,
    sender_id INTEGER REFERENCES contacts(user_id) ON DELETE CASCADE,
    created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
    PRIMARY KEY (message_id, sender_id, emoji)
);

CREATE TABLE group_members (
    group_id TEXT NOT NULL REFERENCES groups(group_id) ON DELETE CASCADE,
    contact_id INTEGER NOT NULL REFERENCES contacts(user_id),
    member_state TEXT,
    group_public_key BLOB,
    last_chat_opened INTEGER,
    last_type_indicator INTEGER,
    last_message INTEGER,
    created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
    PRIMARY KEY (group_id, contact_id)
);

CREATE TABLE receipts (
    receipt_id TEXT NOT NULL PRIMARY KEY,
    contact_id INTEGER NOT NULL REFERENCES contacts(user_id) ON DELETE CASCADE,
    message_id TEXT REFERENCES messages(message_id) ON DELETE CASCADE,
    message BLOB NOT NULL,
    contact_will_sends_receipt INTEGER NOT NULL DEFAULT 1 CHECK (contact_will_sends_receipt IN (0, 1)),
    will_be_retried_by_media_upload INTEGER NOT NULL DEFAULT 0 CHECK (will_be_retried_by_media_upload IN (0, 1)),
    mark_for_retry INTEGER,
    mark_for_retry_after_accepted INTEGER,
    ack_by_server_at INTEGER,
    retry_count INTEGER NOT NULL DEFAULT 0,
    last_retry INTEGER,
    created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
);
CREATE INDEX idx_receipts_message_id ON receipts(message_id);

CREATE TABLE received_receipts (
    receipt_id TEXT NOT NULL PRIMARY KEY,
    created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
);

CREATE TABLE message_actions (
    message_id TEXT NOT NULL REFERENCES messages(message_id) ON DELETE CASCADE,
    contact_id INTEGER NOT NULL REFERENCES contacts(user_id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    action_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
    PRIMARY KEY (message_id, contact_id, type)
);

CREATE TABLE group_histories (
    group_history_id TEXT NOT NULL PRIMARY KEY,
    group_id TEXT NOT NULL REFERENCES groups(group_id) ON DELETE CASCADE,
    contact_id INTEGER REFERENCES contacts(user_id),
    affected_contact_id INTEGER,
    old_group_name TEXT,
    new_group_name TEXT,
    new_delete_messages_after_milliseconds INTEGER,
    type TEXT NOT NULL,
    action_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
);

CREATE TABLE key_verifications (
    verification_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    contact_id INTEGER NOT NULL REFERENCES contacts(user_id) ON DELETE CASCADE,
    type TEXT NOT NULL,
    verified_by INTEGER REFERENCES contacts(user_id) ON DELETE CASCADE,
    created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
);

CREATE TABLE verification_tokens (
    token_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    token BLOB NOT NULL,
    created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
);

CREATE TABLE user_discovery_announced_users (
    announced_user_id INTEGER NOT NULL PRIMARY KEY,
    announced_public_key BLOB NOT NULL,
    public_id INTEGER NOT NULL UNIQUE,
    username TEXT,
    was_shown_to_the_user INTEGER NOT NULL DEFAULT 0 CHECK (was_shown_to_the_user IN (0, 1)),
    is_hidden INTEGER NOT NULL DEFAULT 0 CHECK (is_hidden IN (0, 1)),
    was_asked_friends INTEGER NOT NULL DEFAULT 0 CHECK (was_asked_friends IN (0, 1))
);

CREATE TABLE user_discovery_user_relations (
    announced_user_id INTEGER NOT NULL REFERENCES user_discovery_announced_users(announced_user_id) ON DELETE CASCADE,
    from_contact_id INTEGER NOT NULL REFERENCES contacts(user_id) ON DELETE CASCADE,
    public_key_verified_timestamp INTEGER,
    PRIMARY KEY (announced_user_id, from_contact_id)
);

CREATE TABLE user_discovery_other_promotions (
    from_contact_id INTEGER NOT NULL REFERENCES contacts(user_id) ON DELETE CASCADE,
    promotion_id INTEGER NOT NULL,
    public_id INTEGER NOT NULL,
    threshold INTEGER NOT NULL,
    announcement_share BLOB NOT NULL,
    public_key_verified_timestamp INTEGER,
    PRIMARY KEY (from_contact_id, public_id)
);

CREATE TABLE user_discovery_own_promotions (
    version_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    contact_id INTEGER NOT NULL REFERENCES contacts(user_id) ON DELETE CASCADE,
    promotion BLOB NOT NULL
);

CREATE TABLE user_discovery_shares (
    share_id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    share BLOB NOT NULL,
    contact_id INTEGER REFERENCES contacts(user_id) ON DELETE CASCADE
);

CREATE TABLE shortcuts (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    emoji TEXT NOT NULL UNIQUE,
    usage_counter INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE shortcut_members (
    shortcut_id INTEGER NOT NULL REFERENCES shortcuts(id) ON DELETE CASCADE,
    group_id TEXT NOT NULL REFERENCES groups(group_id) ON DELETE CASCADE,
    PRIMARY KEY (shortcut_id, group_id)
);

CREATE TABLE labels (
    id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    text_color INTEGER NOT NULL,
    background_color INTEGER NOT NULL,
    created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER))
);

CREATE TABLE contact_labels (
    contact_id INTEGER NOT NULL REFERENCES contacts(user_id) ON DELETE CASCADE,
    label_id INTEGER NOT NULL REFERENCES labels(id) ON DELETE CASCADE,
    PRIMARY KEY (contact_id, label_id)
);

CREATE TABLE app_metadata (
    key TEXT NOT NULL PRIMARY KEY,
    value TEXT NOT NULL
);
