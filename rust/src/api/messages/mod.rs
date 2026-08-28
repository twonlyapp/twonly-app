/*
 * Copyright (c) 2026, Tobias Müller git@tsmr.eu
 *
 */

pub mod incoming;
#[doc(hidden)]
pub mod outgoing;

pub(crate) fn content_type_kind(
    content: &crate::api::proto::client::EncryptedContent,
) -> &'static str {
    if content.message_update.is_some() {
        "MessageUpdate"
    } else if content.media.is_some() {
        "Media"
    } else if content.media_update.is_some() {
        "MediaUpdate"
    } else if content.contact_update.is_some() {
        "ContactUpdate"
    } else if content.contact_request.is_some() {
        "ContactRequest"
    } else if content.flame_sync.is_some() {
        "FlameSync"
    } else if content.push_keys.is_some() {
        "PushKeys"
    } else if content.reaction.is_some() {
        "Reaction"
    } else if content.text_message.is_some() {
        "TextMessage"
    } else if content.group_create.is_some() {
        "GroupCreate"
    } else if content.group_join.is_some() {
        "GroupJoin"
    } else if content.group_update.is_some() {
        "GroupUpdate"
    } else if content.resend_group_public_key.is_some() {
        "ResendGroupPublicKey"
    } else if content.error_messages.is_some() {
        "ErrorMessages"
    } else if content.additional_data_message.is_some() {
        "AdditionalDataMessage"
    } else if content.typing_indicator.is_some() {
        "TypingIndicator"
    } else if content.user_discovery_request.is_some() {
        "UserDiscoveryRequest"
    } else if content.user_discovery_update.is_some() {
        "UserDiscoveryUpdate"
    } else if content.key_verification_proof.is_some() {
        "KeyVerificationProof"
    } else if content.passwordless_recovery.is_some() {
        "PasswordLessRecovery"
    } else if content.passwordless_recovery_heartbeat.is_some() {
        "PasswordLessRecoveryHeartbeat"
    } else {
        "Unknown"
    }
}
