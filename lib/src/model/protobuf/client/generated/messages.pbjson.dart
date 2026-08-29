// This is a generated file - do not edit.
//
// Generated from messages.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent$json = {
  '1': 'EncryptedContent',
  '2': [
    {
      '1': 'group_id',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'groupId',
      '17': true
    },
    {
      '1': 'is_direct_chat',
      '3': 3,
      '4': 1,
      '5': 8,
      '9': 1,
      '10': 'isDirectChat',
      '17': true
    },
    {
      '1': 'sender_profile_counter',
      '3': 4,
      '4': 1,
      '5': 3,
      '9': 2,
      '10': 'senderProfileCounter',
      '17': true
    },
    {
      '1': 'sender_user_discovery_version',
      '3': 21,
      '4': 1,
      '5': 12,
      '9': 3,
      '10': 'senderUserDiscoveryVersion',
      '17': true
    },
    {
      '1': 'ask_for_friend_promotions',
      '3': 25,
      '4': 1,
      '5': 8,
      '9': 4,
      '10': 'askForFriendPromotions',
      '17': true
    },
    {
      '1': 'message_update',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.MessageUpdate',
      '9': 5,
      '10': 'messageUpdate',
      '17': true
    },
    {
      '1': 'media',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.Media',
      '9': 6,
      '10': 'media',
      '17': true
    },
    {
      '1': 'media_update',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.MediaUpdate',
      '9': 7,
      '10': 'mediaUpdate',
      '17': true
    },
    {
      '1': 'contact_update',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.ContactUpdate',
      '9': 8,
      '10': 'contactUpdate',
      '17': true
    },
    {
      '1': 'contact_request',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.ContactRequest',
      '9': 9,
      '10': 'contactRequest',
      '17': true
    },
    {
      '1': 'flame_sync',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.FlameSync',
      '9': 10,
      '10': 'flameSync',
      '17': true
    },
    {
      '1': 'reaction',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.Reaction',
      '9': 11,
      '10': 'reaction',
      '17': true
    },
    {
      '1': 'text_message',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.TextMessage',
      '9': 12,
      '10': 'textMessage',
      '17': true
    },
    {
      '1': 'group_create',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.GroupCreate',
      '9': 13,
      '10': 'groupCreate',
      '17': true
    },
    {
      '1': 'group_join',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.GroupJoin',
      '9': 14,
      '10': 'groupJoin',
      '17': true
    },
    {
      '1': 'group_update',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.GroupUpdate',
      '9': 15,
      '10': 'groupUpdate',
      '17': true
    },
    {
      '1': 'resend_group_public_key',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.ResendGroupPublicKey',
      '9': 16,
      '10': 'resendGroupPublicKey',
      '17': true
    },
    {
      '1': 'error_messages',
      '3': 18,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.ErrorMessages',
      '9': 17,
      '10': 'errorMessages',
      '17': true
    },
    {
      '1': 'additional_data_message',
      '3': 19,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.AdditionalDataMessage',
      '9': 18,
      '10': 'additionalDataMessage',
      '17': true
    },
    {
      '1': 'typing_indicator',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.TypingIndicator',
      '9': 19,
      '10': 'typingIndicator',
      '17': true
    },
    {
      '1': 'user_discovery_request',
      '3': 22,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.UserDiscoveryRequest',
      '9': 20,
      '10': 'userDiscoveryRequest',
      '17': true
    },
    {
      '1': 'user_discovery_update',
      '3': 23,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.UserDiscoveryUpdate',
      '9': 21,
      '10': 'userDiscoveryUpdate',
      '17': true
    },
    {
      '1': 'key_verification_proof',
      '3': 24,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.KeyVerificationProof',
      '9': 22,
      '10': 'keyVerificationProof',
      '17': true
    },
    {
      '1': 'passwordless_recovery',
      '3': 26,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.PasswordLessRecovery',
      '9': 23,
      '10': 'passwordlessRecovery',
      '17': true
    },
    {
      '1': 'passwordless_recovery_heartbeat',
      '3': 27,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.PasswordLessRecoveryHeartbeat',
      '9': 24,
      '10': 'passwordlessRecoveryHeartbeat',
      '17': true
    },
  ],
  '3': [
    EncryptedContent_ErrorMessages$json,
    EncryptedContent_GroupCreate$json,
    EncryptedContent_GroupJoin$json,
    EncryptedContent_ResendGroupPublicKey$json,
    EncryptedContent_GroupUpdate$json,
    EncryptedContent_TextMessage$json,
    EncryptedContent_AdditionalDataMessage$json,
    EncryptedContent_Reaction$json,
    EncryptedContent_MessageUpdate$json,
    EncryptedContent_Media$json,
    EncryptedContent_MediaUpdate$json,
    EncryptedContent_ContactRequest$json,
    EncryptedContent_ContactUpdate$json,
    EncryptedContent_FlameSync$json,
    EncryptedContent_TypingIndicator$json,
    EncryptedContent_UserDiscoveryRequest$json,
    EncryptedContent_UserDiscoveryUpdate$json,
    EncryptedContent_KeyVerificationProof$json,
    EncryptedContent_PasswordLessRecovery$json,
    EncryptedContent_PasswordLessRecoveryHeartbeat$json
  ],
  '8': [
    {'1': '_group_id'},
    {'1': '_is_direct_chat'},
    {'1': '_sender_profile_counter'},
    {'1': '_sender_user_discovery_version'},
    {'1': '_ask_for_friend_promotions'},
    {'1': '_message_update'},
    {'1': '_media'},
    {'1': '_media_update'},
    {'1': '_contact_update'},
    {'1': '_contact_request'},
    {'1': '_flame_sync'},
    {'1': '_reaction'},
    {'1': '_text_message'},
    {'1': '_group_create'},
    {'1': '_group_join'},
    {'1': '_group_update'},
    {'1': '_resend_group_public_key'},
    {'1': '_error_messages'},
    {'1': '_additional_data_message'},
    {'1': '_typing_indicator'},
    {'1': '_user_discovery_request'},
    {'1': '_user_discovery_update'},
    {'1': '_key_verification_proof'},
    {'1': '_passwordless_recovery'},
    {'1': '_passwordless_recovery_heartbeat'},
  ],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_ErrorMessages$json = {
  '1': 'ErrorMessages',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.EncryptedContent.ErrorMessages.Type',
      '10': 'type'
    },
    {
      '1': 'related_receipt_id',
      '3': 2,
      '4': 1,
      '5': 9,
      '10': 'relatedReceiptId'
    },
  ],
  '4': [EncryptedContent_ErrorMessages_Type$json],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_ErrorMessages_Type$json = {
  '1': 'Type',
  '2': [
    {'1': 'ERROR_PROCESSING_MESSAGE_CREATED_ACCOUNT_REQUEST_INSTEAD', '2': 0},
    {'1': 'UNKNOWN_MESSAGE_TYPE', '2': 2},
    {'1': 'SESSION_OUT_OF_SYNC', '2': 3},
    {'1': 'GROUP_NOT_FOUND_OR_NOT_A_MEMBER', '2': 4},
  ],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_GroupCreate$json = {
  '1': 'GroupCreate',
  '2': [
    {'1': 'state_key', '3': 3, '4': 1, '5': 12, '10': 'stateKey'},
    {'1': 'group_public_key', '3': 4, '4': 1, '5': 12, '10': 'groupPublicKey'},
    {
      '1': 'group_name',
      '3': 5,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'groupName',
      '17': true
    },
  ],
  '8': [
    {'1': '_group_name'},
  ],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_GroupJoin$json = {
  '1': 'GroupJoin',
  '2': [
    {'1': 'group_public_key', '3': 1, '4': 1, '5': 12, '10': 'groupPublicKey'},
  ],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_ResendGroupPublicKey$json = {
  '1': 'ResendGroupPublicKey',
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_GroupUpdate$json = {
  '1': 'GroupUpdate',
  '2': [
    {'1': 'group_action_type', '3': 1, '4': 1, '5': 9, '10': 'groupActionType'},
    {
      '1': 'affected_contact_id',
      '3': 2,
      '4': 1,
      '5': 3,
      '9': 0,
      '10': 'affectedContactId',
      '17': true
    },
    {
      '1': 'new_group_name',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'newGroupName',
      '17': true
    },
    {
      '1': 'new_delete_messages_after_milliseconds',
      '3': 4,
      '4': 1,
      '5': 3,
      '9': 2,
      '10': 'newDeleteMessagesAfterMilliseconds',
      '17': true
    },
  ],
  '8': [
    {'1': '_affected_contact_id'},
    {'1': '_new_group_name'},
    {'1': '_new_delete_messages_after_milliseconds'},
  ],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_TextMessage$json = {
  '1': 'TextMessage',
  '2': [
    {'1': 'sender_message_id', '3': 1, '4': 1, '5': 9, '10': 'senderMessageId'},
    {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
    {'1': 'timestamp', '3': 3, '4': 1, '5': 3, '10': 'timestamp'},
    {
      '1': 'quote_message_id',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'quoteMessageId',
      '17': true
    },
  ],
  '8': [
    {'1': '_quote_message_id'},
  ],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_AdditionalDataMessage$json = {
  '1': 'AdditionalDataMessage',
  '2': [
    {'1': 'sender_message_id', '3': 1, '4': 1, '5': 9, '10': 'senderMessageId'},
    {'1': 'timestamp', '3': 2, '4': 1, '5': 3, '10': 'timestamp'},
    {'1': 'type', '3': 3, '4': 1, '5': 9, '10': 'type'},
    {
      '1': 'additional_message_data',
      '3': 4,
      '4': 1,
      '5': 12,
      '9': 0,
      '10': 'additionalMessageData',
      '17': true
    },
  ],
  '8': [
    {'1': '_additional_message_data'},
  ],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_Reaction$json = {
  '1': 'Reaction',
  '2': [
    {'1': 'target_message_id', '3': 1, '4': 1, '5': 9, '10': 'targetMessageId'},
    {'1': 'emoji', '3': 2, '4': 1, '5': 9, '10': 'emoji'},
    {'1': 'remove', '3': 3, '4': 1, '5': 8, '10': 'remove'},
  ],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_MessageUpdate$json = {
  '1': 'MessageUpdate',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.EncryptedContent.MessageUpdate.Type',
      '10': 'type'
    },
    {
      '1': 'sender_message_id',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'senderMessageId',
      '17': true
    },
    {
      '1': 'multiple_target_message_ids',
      '3': 3,
      '4': 3,
      '5': 9,
      '10': 'multipleTargetMessageIds'
    },
    {'1': 'text', '3': 4, '4': 1, '5': 9, '9': 1, '10': 'text', '17': true},
    {'1': 'timestamp', '3': 5, '4': 1, '5': 3, '10': 'timestamp'},
  ],
  '4': [EncryptedContent_MessageUpdate_Type$json],
  '8': [
    {'1': '_sender_message_id'},
    {'1': '_text'},
  ],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_MessageUpdate_Type$json = {
  '1': 'Type',
  '2': [
    {'1': 'DELETE', '2': 0},
    {'1': 'EDIT_TEXT', '2': 1},
    {'1': 'OPENED', '2': 2},
  ],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_Media$json = {
  '1': 'Media',
  '2': [
    {'1': 'sender_message_id', '3': 1, '4': 1, '5': 9, '10': 'senderMessageId'},
    {
      '1': 'type',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.EncryptedContent.Media.Type',
      '10': 'type'
    },
    {
      '1': 'display_limit_in_milliseconds',
      '3': 3,
      '4': 1,
      '5': 3,
      '9': 0,
      '10': 'displayLimitInMilliseconds',
      '17': true
    },
    {
      '1': 'requires_authentication',
      '3': 4,
      '4': 1,
      '5': 8,
      '10': 'requiresAuthentication'
    },
    {'1': 'timestamp', '3': 5, '4': 1, '5': 3, '10': 'timestamp'},
    {
      '1': 'quote_message_id',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'quoteMessageId',
      '17': true
    },
    {
      '1': 'download_token',
      '3': 7,
      '4': 1,
      '5': 12,
      '9': 2,
      '10': 'downloadToken',
      '17': true
    },
    {
      '1': 'encryption_key',
      '3': 8,
      '4': 1,
      '5': 12,
      '9': 3,
      '10': 'encryptionKey',
      '17': true
    },
    {
      '1': 'encryption_mac',
      '3': 9,
      '4': 1,
      '5': 12,
      '9': 4,
      '10': 'encryptionMac',
      '17': true
    },
    {
      '1': 'encryption_nonce',
      '3': 10,
      '4': 1,
      '5': 12,
      '9': 5,
      '10': 'encryptionNonce',
      '17': true
    },
    {
      '1': 'additional_message_data',
      '3': 11,
      '4': 1,
      '5': 12,
      '9': 6,
      '10': 'additionalMessageData',
      '17': true
    },
  ],
  '4': [EncryptedContent_Media_Type$json],
  '8': [
    {'1': '_display_limit_in_milliseconds'},
    {'1': '_quote_message_id'},
    {'1': '_download_token'},
    {'1': '_encryption_key'},
    {'1': '_encryption_mac'},
    {'1': '_encryption_nonce'},
    {'1': '_additional_message_data'},
  ],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_Media_Type$json = {
  '1': 'Type',
  '2': [
    {'1': 'REUPLOAD', '2': 0},
    {'1': 'IMAGE', '2': 1},
    {'1': 'VIDEO', '2': 2},
    {'1': 'GIF', '2': 3},
    {'1': 'AUDIO', '2': 4},
  ],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_MediaUpdate$json = {
  '1': 'MediaUpdate',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.EncryptedContent.MediaUpdate.Type',
      '10': 'type'
    },
    {'1': 'target_message_id', '3': 2, '4': 1, '5': 9, '10': 'targetMessageId'},
  ],
  '4': [EncryptedContent_MediaUpdate_Type$json],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_MediaUpdate_Type$json = {
  '1': 'Type',
  '2': [
    {'1': 'REOPENED', '2': 0},
    {'1': 'STORED', '2': 1},
    {'1': 'DECRYPTION_ERROR', '2': 2},
  ],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_ContactRequest$json = {
  '1': 'ContactRequest',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.EncryptedContent.ContactRequest.Type',
      '10': 'type'
    },
  ],
  '4': [EncryptedContent_ContactRequest_Type$json],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_ContactRequest_Type$json = {
  '1': 'Type',
  '2': [
    {'1': 'REQUEST', '2': 0},
    {'1': 'REJECT', '2': 1},
    {'1': 'ACCEPT', '2': 2},
  ],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_ContactUpdate$json = {
  '1': 'ContactUpdate',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.EncryptedContent.ContactUpdate.Type',
      '10': 'type'
    },
    {
      '1': 'avatar_svg_compressed',
      '3': 2,
      '4': 1,
      '5': 12,
      '9': 0,
      '10': 'avatarSvgCompressed',
      '17': true
    },
    {
      '1': 'username',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'username',
      '17': true
    },
    {
      '1': 'display_name',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 2,
      '10': 'displayName',
      '17': true
    },
  ],
  '4': [EncryptedContent_ContactUpdate_Type$json],
  '8': [
    {'1': '_avatar_svg_compressed'},
    {'1': '_username'},
    {'1': '_display_name'},
  ],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_ContactUpdate_Type$json = {
  '1': 'Type',
  '2': [
    {'1': 'REQUEST', '2': 0},
    {'1': 'UPDATE', '2': 1},
  ],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_FlameSync$json = {
  '1': 'FlameSync',
  '2': [
    {'1': 'flame_counter', '3': 1, '4': 1, '5': 3, '10': 'flameCounter'},
    {
      '1': 'last_flame_counter_change',
      '3': 2,
      '4': 1,
      '5': 3,
      '10': 'lastFlameCounterChange'
    },
    {'1': 'best_friend', '3': 3, '4': 1, '5': 8, '10': 'bestFriend'},
    {'1': 'force_update', '3': 4, '4': 1, '5': 8, '10': 'forceUpdate'},
  ],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_TypingIndicator$json = {
  '1': 'TypingIndicator',
  '2': [
    {'1': 'is_typing', '3': 1, '4': 1, '5': 8, '10': 'isTyping'},
    {'1': 'created_at', '3': 2, '4': 1, '5': 3, '10': 'createdAt'},
  ],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_UserDiscoveryRequest$json = {
  '1': 'UserDiscoveryRequest',
  '2': [
    {'1': 'current_version', '3': 1, '4': 1, '5': 12, '10': 'currentVersion'},
  ],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_UserDiscoveryUpdate$json = {
  '1': 'UserDiscoveryUpdate',
  '2': [
    {'1': 'messages', '3': 1, '4': 3, '5': 12, '10': 'messages'},
  ],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_KeyVerificationProof$json = {
  '1': 'KeyVerificationProof',
  '2': [
    {'1': 'calculated_mac', '3': 1, '4': 1, '5': 12, '10': 'calculatedMac'},
  ],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_PasswordLessRecovery$json = {
  '1': 'PasswordLessRecovery',
  '2': [
    {
      '1': 'recoverySecretShare',
      '3': 1,
      '4': 1,
      '5': 12,
      '9': 0,
      '10': 'recoverySecretShare',
      '17': true
    },
    {'1': 'delete', '3': 2, '4': 1, '5': 8, '10': 'delete'},
    {'1': 'threshold', '3': 3, '4': 1, '5': 3, '10': 'threshold'},
  ],
  '8': [
    {'1': '_recoverySecretShare'},
  ],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_PasswordLessRecoveryHeartbeat$json = {
  '1': 'PasswordLessRecoveryHeartbeat',
  '2': [
    {'1': 'hash', '3': 1, '4': 1, '5': 12, '10': 'hash'},
  ],
};

/// Descriptor for `EncryptedContent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List encryptedContentDescriptor = $convert.base64Decode(
    'ChBFbmNyeXB0ZWRDb250ZW50Eh4KCGdyb3VwX2lkGAIgASgJSABSB2dyb3VwSWSIAQESKQoOaX'
    'NfZGlyZWN0X2NoYXQYAyABKAhIAVIMaXNEaXJlY3RDaGF0iAEBEjkKFnNlbmRlcl9wcm9maWxl'
    'X2NvdW50ZXIYBCABKANIAlIUc2VuZGVyUHJvZmlsZUNvdW50ZXKIAQESRgodc2VuZGVyX3VzZX'
    'JfZGlzY292ZXJ5X3ZlcnNpb24YFSABKAxIA1Iac2VuZGVyVXNlckRpc2NvdmVyeVZlcnNpb26I'
    'AQESPgoZYXNrX2Zvcl9mcmllbmRfcHJvbW90aW9ucxgZIAEoCEgEUhZhc2tGb3JGcmllbmRQcm'
    '9tb3Rpb25ziAEBEksKDm1lc3NhZ2VfdXBkYXRlGAUgASgLMh8uRW5jcnlwdGVkQ29udGVudC5N'
    'ZXNzYWdlVXBkYXRlSAVSDW1lc3NhZ2VVcGRhdGWIAQESMgoFbWVkaWEYBiABKAsyFy5FbmNyeX'
    'B0ZWRDb250ZW50Lk1lZGlhSAZSBW1lZGlhiAEBEkUKDG1lZGlhX3VwZGF0ZRgHIAEoCzIdLkVu'
    'Y3J5cHRlZENvbnRlbnQuTWVkaWFVcGRhdGVIB1ILbWVkaWFVcGRhdGWIAQESSwoOY29udGFjdF'
    '91cGRhdGUYCCABKAsyHy5FbmNyeXB0ZWRDb250ZW50LkNvbnRhY3RVcGRhdGVICFINY29udGFj'
    'dFVwZGF0ZYgBARJOCg9jb250YWN0X3JlcXVlc3QYCSABKAsyIC5FbmNyeXB0ZWRDb250ZW50Lk'
    'NvbnRhY3RSZXF1ZXN0SAlSDmNvbnRhY3RSZXF1ZXN0iAEBEj8KCmZsYW1lX3N5bmMYCiABKAsy'
    'Gy5FbmNyeXB0ZWRDb250ZW50LkZsYW1lU3luY0gKUglmbGFtZVN5bmOIAQESOwoIcmVhY3Rpb2'
    '4YDCABKAsyGi5FbmNyeXB0ZWRDb250ZW50LlJlYWN0aW9uSAtSCHJlYWN0aW9uiAEBEkUKDHRl'
    'eHRfbWVzc2FnZRgNIAEoCzIdLkVuY3J5cHRlZENvbnRlbnQuVGV4dE1lc3NhZ2VIDFILdGV4dE'
    '1lc3NhZ2WIAQESRQoMZ3JvdXBfY3JlYXRlGA4gASgLMh0uRW5jcnlwdGVkQ29udGVudC5Hcm91'
    'cENyZWF0ZUgNUgtncm91cENyZWF0ZYgBARI/Cgpncm91cF9qb2luGA8gASgLMhsuRW5jcnlwdG'
    'VkQ29udGVudC5Hcm91cEpvaW5IDlIJZ3JvdXBKb2luiAEBEkUKDGdyb3VwX3VwZGF0ZRgQIAEo'
    'CzIdLkVuY3J5cHRlZENvbnRlbnQuR3JvdXBVcGRhdGVID1ILZ3JvdXBVcGRhdGWIAQESYgoXcm'
    'VzZW5kX2dyb3VwX3B1YmxpY19rZXkYESABKAsyJi5FbmNyeXB0ZWRDb250ZW50LlJlc2VuZEdy'
    'b3VwUHVibGljS2V5SBBSFHJlc2VuZEdyb3VwUHVibGljS2V5iAEBEksKDmVycm9yX21lc3NhZ2'
    'VzGBIgASgLMh8uRW5jcnlwdGVkQ29udGVudC5FcnJvck1lc3NhZ2VzSBFSDWVycm9yTWVzc2Fn'
    'ZXOIAQESZAoXYWRkaXRpb25hbF9kYXRhX21lc3NhZ2UYEyABKAsyJy5FbmNyeXB0ZWRDb250ZW'
    '50LkFkZGl0aW9uYWxEYXRhTWVzc2FnZUgSUhVhZGRpdGlvbmFsRGF0YU1lc3NhZ2WIAQESUQoQ'
    'dHlwaW5nX2luZGljYXRvchgUIAEoCzIhLkVuY3J5cHRlZENvbnRlbnQuVHlwaW5nSW5kaWNhdG'
    '9ySBNSD3R5cGluZ0luZGljYXRvcogBARJhChZ1c2VyX2Rpc2NvdmVyeV9yZXF1ZXN0GBYgASgL'
    'MiYuRW5jcnlwdGVkQ29udGVudC5Vc2VyRGlzY292ZXJ5UmVxdWVzdEgUUhR1c2VyRGlzY292ZX'
    'J5UmVxdWVzdIgBARJeChV1c2VyX2Rpc2NvdmVyeV91cGRhdGUYFyABKAsyJS5FbmNyeXB0ZWRD'
    'b250ZW50LlVzZXJEaXNjb3ZlcnlVcGRhdGVIFVITdXNlckRpc2NvdmVyeVVwZGF0ZYgBARJhCh'
    'ZrZXlfdmVyaWZpY2F0aW9uX3Byb29mGBggASgLMiYuRW5jcnlwdGVkQ29udGVudC5LZXlWZXJp'
    'ZmljYXRpb25Qcm9vZkgWUhRrZXlWZXJpZmljYXRpb25Qcm9vZogBARJgChVwYXNzd29yZGxlc3'
    'NfcmVjb3ZlcnkYGiABKAsyJi5FbmNyeXB0ZWRDb250ZW50LlBhc3N3b3JkTGVzc1JlY292ZXJ5'
    'SBdSFHBhc3N3b3JkbGVzc1JlY292ZXJ5iAEBEnwKH3Bhc3N3b3JkbGVzc19yZWNvdmVyeV9oZW'
    'FydGJlYXQYGyABKAsyLy5FbmNyeXB0ZWRDb250ZW50LlBhc3N3b3JkTGVzc1JlY292ZXJ5SGVh'
    'cnRiZWF0SBhSHXBhc3N3b3JkbGVzc1JlY292ZXJ5SGVhcnRiZWF0iAEBGpYCCg1FcnJvck1lc3'
    'NhZ2VzEjgKBHR5cGUYASABKA4yJC5FbmNyeXB0ZWRDb250ZW50LkVycm9yTWVzc2FnZXMuVHlw'
    'ZVIEdHlwZRIsChJyZWxhdGVkX3JlY2VpcHRfaWQYAiABKAlSEHJlbGF0ZWRSZWNlaXB0SWQinA'
    'EKBFR5cGUSPAo4RVJST1JfUFJPQ0VTU0lOR19NRVNTQUdFX0NSRUFURURfQUNDT1VOVF9SRVFV'
    'RVNUX0lOU1RFQUQQABIYChRVTktOT1dOX01FU1NBR0VfVFlQRRACEhcKE1NFU1NJT05fT1VUX0'
    '9GX1NZTkMQAxIjCh9HUk9VUF9OT1RfRk9VTkRfT1JfTk9UX0FfTUVNQkVSEAQahwEKC0dyb3Vw'
    'Q3JlYXRlEhsKCXN0YXRlX2tleRgDIAEoDFIIc3RhdGVLZXkSKAoQZ3JvdXBfcHVibGljX2tleR'
    'gEIAEoDFIOZ3JvdXBQdWJsaWNLZXkSIgoKZ3JvdXBfbmFtZRgFIAEoCUgAUglncm91cE5hbWWI'
    'AQFCDQoLX2dyb3VwX25hbWUaNQoJR3JvdXBKb2luEigKEGdyb3VwX3B1YmxpY19rZXkYASABKA'
    'xSDmdyb3VwUHVibGljS2V5GhYKFFJlc2VuZEdyb3VwUHVibGljS2V5GsgCCgtHcm91cFVwZGF0'
    'ZRIqChFncm91cF9hY3Rpb25fdHlwZRgBIAEoCVIPZ3JvdXBBY3Rpb25UeXBlEjMKE2FmZmVjdG'
    'VkX2NvbnRhY3RfaWQYAiABKANIAFIRYWZmZWN0ZWRDb250YWN0SWSIAQESKQoObmV3X2dyb3Vw'
    'X25hbWUYAyABKAlIAVIMbmV3R3JvdXBOYW1liAEBElcKJm5ld19kZWxldGVfbWVzc2FnZXNfYW'
    'Z0ZXJfbWlsbGlzZWNvbmRzGAQgASgDSAJSIm5ld0RlbGV0ZU1lc3NhZ2VzQWZ0ZXJNaWxsaXNl'
    'Y29uZHOIAQFCFgoUX2FmZmVjdGVkX2NvbnRhY3RfaWRCEQoPX25ld19ncm91cF9uYW1lQikKJ1'
    '9uZXdfZGVsZXRlX21lc3NhZ2VzX2FmdGVyX21pbGxpc2Vjb25kcxqvAQoLVGV4dE1lc3NhZ2US'
    'KgoRc2VuZGVyX21lc3NhZ2VfaWQYASABKAlSD3NlbmRlck1lc3NhZ2VJZBISCgR0ZXh0GAIgAS'
    'gJUgR0ZXh0EhwKCXRpbWVzdGFtcBgDIAEoA1IJdGltZXN0YW1wEi0KEHF1b3RlX21lc3NhZ2Vf'
    'aWQYBCABKAlIAFIOcXVvdGVNZXNzYWdlSWSIAQFCEwoRX3F1b3RlX21lc3NhZ2VfaWQazgEKFU'
    'FkZGl0aW9uYWxEYXRhTWVzc2FnZRIqChFzZW5kZXJfbWVzc2FnZV9pZBgBIAEoCVIPc2VuZGVy'
    'TWVzc2FnZUlkEhwKCXRpbWVzdGFtcBgCIAEoA1IJdGltZXN0YW1wEhIKBHR5cGUYAyABKAlSBH'
    'R5cGUSOwoXYWRkaXRpb25hbF9tZXNzYWdlX2RhdGEYBCABKAxIAFIVYWRkaXRpb25hbE1lc3Nh'
    'Z2VEYXRhiAEBQhoKGF9hZGRpdGlvbmFsX21lc3NhZ2VfZGF0YRpkCghSZWFjdGlvbhIqChF0YX'
    'JnZXRfbWVzc2FnZV9pZBgBIAEoCVIPdGFyZ2V0TWVzc2FnZUlkEhQKBWVtb2ppGAIgASgJUgVl'
    'bW9qaRIWCgZyZW1vdmUYAyABKAhSBnJlbW92ZRq+AgoNTWVzc2FnZVVwZGF0ZRI4CgR0eXBlGA'
    'EgASgOMiQuRW5jcnlwdGVkQ29udGVudC5NZXNzYWdlVXBkYXRlLlR5cGVSBHR5cGUSLwoRc2Vu'
    'ZGVyX21lc3NhZ2VfaWQYAiABKAlIAFIPc2VuZGVyTWVzc2FnZUlkiAEBEj0KG211bHRpcGxlX3'
    'RhcmdldF9tZXNzYWdlX2lkcxgDIAMoCVIYbXVsdGlwbGVUYXJnZXRNZXNzYWdlSWRzEhcKBHRl'
    'eHQYBCABKAlIAVIEdGV4dIgBARIcCgl0aW1lc3RhbXAYBSABKANSCXRpbWVzdGFtcCItCgRUeX'
    'BlEgoKBkRFTEVURRAAEg0KCUVESVRfVEVYVBABEgoKBk9QRU5FRBACQhQKEl9zZW5kZXJfbWVz'
    'c2FnZV9pZEIHCgVfdGV4dBqFBgoFTWVkaWESKgoRc2VuZGVyX21lc3NhZ2VfaWQYASABKAlSD3'
    'NlbmRlck1lc3NhZ2VJZBIwCgR0eXBlGAIgASgOMhwuRW5jcnlwdGVkQ29udGVudC5NZWRpYS5U'
    'eXBlUgR0eXBlEkYKHWRpc3BsYXlfbGltaXRfaW5fbWlsbGlzZWNvbmRzGAMgASgDSABSGmRpc3'
    'BsYXlMaW1pdEluTWlsbGlzZWNvbmRziAEBEjcKF3JlcXVpcmVzX2F1dGhlbnRpY2F0aW9uGAQg'
    'ASgIUhZyZXF1aXJlc0F1dGhlbnRpY2F0aW9uEhwKCXRpbWVzdGFtcBgFIAEoA1IJdGltZXN0YW'
    '1wEi0KEHF1b3RlX21lc3NhZ2VfaWQYBiABKAlIAVIOcXVvdGVNZXNzYWdlSWSIAQESKgoOZG93'
    'bmxvYWRfdG9rZW4YByABKAxIAlINZG93bmxvYWRUb2tlbogBARIqCg5lbmNyeXB0aW9uX2tleR'
    'gIIAEoDEgDUg1lbmNyeXB0aW9uS2V5iAEBEioKDmVuY3J5cHRpb25fbWFjGAkgASgMSARSDWVu'
    'Y3J5cHRpb25NYWOIAQESLgoQZW5jcnlwdGlvbl9ub25jZRgKIAEoDEgFUg9lbmNyeXB0aW9uTm'
    '9uY2WIAQESOwoXYWRkaXRpb25hbF9tZXNzYWdlX2RhdGEYCyABKAxIBlIVYWRkaXRpb25hbE1l'
    'c3NhZ2VEYXRhiAEBIj4KBFR5cGUSDAoIUkVVUExPQUQQABIJCgVJTUFHRRABEgkKBVZJREVPEA'
    'ISBwoDR0lGEAMSCQoFQVVESU8QBEIgCh5fZGlzcGxheV9saW1pdF9pbl9taWxsaXNlY29uZHNC'
    'EwoRX3F1b3RlX21lc3NhZ2VfaWRCEQoPX2Rvd25sb2FkX3Rva2VuQhEKD19lbmNyeXB0aW9uX2'
    'tleUIRCg9fZW5jcnlwdGlvbl9tYWNCEwoRX2VuY3J5cHRpb25fbm9uY2VCGgoYX2FkZGl0aW9u'
    'YWxfbWVzc2FnZV9kYXRhGqkBCgtNZWRpYVVwZGF0ZRI2CgR0eXBlGAEgASgOMiIuRW5jcnlwdG'
    'VkQ29udGVudC5NZWRpYVVwZGF0ZS5UeXBlUgR0eXBlEioKEXRhcmdldF9tZXNzYWdlX2lkGAIg'
    'ASgJUg90YXJnZXRNZXNzYWdlSWQiNgoEVHlwZRIMCghSRU9QRU5FRBAAEgoKBlNUT1JFRBABEh'
    'QKEERFQ1JZUFRJT05fRVJST1IQAhp4Cg5Db250YWN0UmVxdWVzdBI5CgR0eXBlGAEgASgOMiUu'
    'RW5jcnlwdGVkQ29udGVudC5Db250YWN0UmVxdWVzdC5UeXBlUgR0eXBlIisKBFR5cGUSCwoHUk'
    'VRVUVTVBAAEgoKBlJFSkVDVBABEgoKBkFDQ0VQVBACGqQCCg1Db250YWN0VXBkYXRlEjgKBHR5'
    'cGUYASABKA4yJC5FbmNyeXB0ZWRDb250ZW50LkNvbnRhY3RVcGRhdGUuVHlwZVIEdHlwZRI3Ch'
    'VhdmF0YXJfc3ZnX2NvbXByZXNzZWQYAiABKAxIAFITYXZhdGFyU3ZnQ29tcHJlc3NlZIgBARIf'
    'Cgh1c2VybmFtZRgDIAEoCUgBUgh1c2VybmFtZYgBARImCgxkaXNwbGF5X25hbWUYBCABKAlIAl'
    'ILZGlzcGxheU5hbWWIAQEiHwoEVHlwZRILCgdSRVFVRVNUEAASCgoGVVBEQVRFEAFCGAoWX2F2'
    'YXRhcl9zdmdfY29tcHJlc3NlZEILCglfdXNlcm5hbWVCDwoNX2Rpc3BsYXlfbmFtZRqvAQoJRm'
    'xhbWVTeW5jEiMKDWZsYW1lX2NvdW50ZXIYASABKANSDGZsYW1lQ291bnRlchI5ChlsYXN0X2Zs'
    'YW1lX2NvdW50ZXJfY2hhbmdlGAIgASgDUhZsYXN0RmxhbWVDb3VudGVyQ2hhbmdlEh8KC2Jlc3'
    'RfZnJpZW5kGAMgASgIUgpiZXN0RnJpZW5kEiEKDGZvcmNlX3VwZGF0ZRgEIAEoCFILZm9yY2VV'
    'cGRhdGUaTQoPVHlwaW5nSW5kaWNhdG9yEhsKCWlzX3R5cGluZxgBIAEoCFIIaXNUeXBpbmcSHQ'
    'oKY3JlYXRlZF9hdBgCIAEoA1IJY3JlYXRlZEF0Gj8KFFVzZXJEaXNjb3ZlcnlSZXF1ZXN0EicK'
    'D2N1cnJlbnRfdmVyc2lvbhgBIAEoDFIOY3VycmVudFZlcnNpb24aMQoTVXNlckRpc2NvdmVyeV'
    'VwZGF0ZRIaCghtZXNzYWdlcxgBIAMoDFIIbWVzc2FnZXMaPQoUS2V5VmVyaWZpY2F0aW9uUHJv'
    'b2YSJQoOY2FsY3VsYXRlZF9tYWMYASABKAxSDWNhbGN1bGF0ZWRNYWMamwEKFFBhc3N3b3JkTG'
    'Vzc1JlY292ZXJ5EjUKE3JlY292ZXJ5U2VjcmV0U2hhcmUYASABKAxIAFITcmVjb3ZlcnlTZWNy'
    'ZXRTaGFyZYgBARIWCgZkZWxldGUYAiABKAhSBmRlbGV0ZRIcCgl0aHJlc2hvbGQYAyABKANSCX'
    'RocmVzaG9sZEIWChRfcmVjb3ZlcnlTZWNyZXRTaGFyZRozCh1QYXNzd29yZExlc3NSZWNvdmVy'
    'eUhlYXJ0YmVhdBISCgRoYXNoGAEgASgMUgRoYXNoQgsKCV9ncm91cF9pZEIRCg9faXNfZGlyZW'
    'N0X2NoYXRCGQoXX3NlbmRlcl9wcm9maWxlX2NvdW50ZXJCIAoeX3NlbmRlcl91c2VyX2Rpc2Nv'
    'dmVyeV92ZXJzaW9uQhwKGl9hc2tfZm9yX2ZyaWVuZF9wcm9tb3Rpb25zQhEKD19tZXNzYWdlX3'
    'VwZGF0ZUIICgZfbWVkaWFCDwoNX21lZGlhX3VwZGF0ZUIRCg9fY29udGFjdF91cGRhdGVCEgoQ'
    'X2NvbnRhY3RfcmVxdWVzdEINCgtfZmxhbWVfc3luY0ILCglfcmVhY3Rpb25CDwoNX3RleHRfbW'
    'Vzc2FnZUIPCg1fZ3JvdXBfY3JlYXRlQg0KC19ncm91cF9qb2luQg8KDV9ncm91cF91cGRhdGVC'
    'GgoYX3Jlc2VuZF9ncm91cF9wdWJsaWNfa2V5QhEKD19lcnJvcl9tZXNzYWdlc0IaChhfYWRkaX'
    'Rpb25hbF9kYXRhX21lc3NhZ2VCEwoRX3R5cGluZ19pbmRpY2F0b3JCGQoXX3VzZXJfZGlzY292'
    'ZXJ5X3JlcXVlc3RCGAoWX3VzZXJfZGlzY292ZXJ5X3VwZGF0ZUIZChdfa2V5X3ZlcmlmaWNhdG'
    'lvbl9wcm9vZkIYChZfcGFzc3dvcmRsZXNzX3JlY292ZXJ5QiIKIF9wYXNzd29yZGxlc3NfcmVj'
    'b3ZlcnlfaGVhcnRiZWF0');
