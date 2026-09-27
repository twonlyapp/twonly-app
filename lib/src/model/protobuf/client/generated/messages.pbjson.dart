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
      '1': 'widget_sharing_allowed',
      '3': 29,
      '4': 1,
      '5': 8,
      '9': 5,
      '10': 'widgetSharingAllowed',
      '17': true
    },
    {
      '1': 'message_update',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.MessageUpdate',
      '9': 6,
      '10': 'messageUpdate',
      '17': true
    },
    {
      '1': 'media',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.Media',
      '9': 7,
      '10': 'media',
      '17': true
    },
    {
      '1': 'media_update',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.MediaUpdate',
      '9': 8,
      '10': 'mediaUpdate',
      '17': true
    },
    {
      '1': 'contact_update',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.ContactUpdate',
      '9': 9,
      '10': 'contactUpdate',
      '17': true
    },
    {
      '1': 'contact_request',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.ContactRequest',
      '9': 10,
      '10': 'contactRequest',
      '17': true
    },
    {
      '1': 'flame_sync',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.FlameSync',
      '9': 11,
      '10': 'flameSync',
      '17': true
    },
    {
      '1': 'reaction',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.Reaction',
      '9': 12,
      '10': 'reaction',
      '17': true
    },
    {
      '1': 'text_message',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.TextMessage',
      '9': 13,
      '10': 'textMessage',
      '17': true
    },
    {
      '1': 'group_create',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.GroupCreate',
      '9': 14,
      '10': 'groupCreate',
      '17': true
    },
    {
      '1': 'group_join',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.GroupJoin',
      '9': 15,
      '10': 'groupJoin',
      '17': true
    },
    {
      '1': 'group_update',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.GroupUpdate',
      '9': 16,
      '10': 'groupUpdate',
      '17': true
    },
    {
      '1': 'resend_group_public_key',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.ResendGroupPublicKey',
      '9': 17,
      '10': 'resendGroupPublicKey',
      '17': true
    },
    {
      '1': 'error_messages',
      '3': 18,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.ErrorMessages',
      '9': 18,
      '10': 'errorMessages',
      '17': true
    },
    {
      '1': 'additional_data_message',
      '3': 19,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.AdditionalDataMessage',
      '9': 19,
      '10': 'additionalDataMessage',
      '17': true
    },
    {
      '1': 'typing_indicator',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.TypingIndicator',
      '9': 20,
      '10': 'typingIndicator',
      '17': true
    },
    {
      '1': 'user_discovery_request',
      '3': 22,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.UserDiscoveryRequest',
      '9': 21,
      '10': 'userDiscoveryRequest',
      '17': true
    },
    {
      '1': 'user_discovery_update',
      '3': 23,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.UserDiscoveryUpdate',
      '9': 22,
      '10': 'userDiscoveryUpdate',
      '17': true
    },
    {
      '1': 'key_verification_proof',
      '3': 24,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.KeyVerificationProof',
      '9': 23,
      '10': 'keyVerificationProof',
      '17': true
    },
    {
      '1': 'passwordless_recovery',
      '3': 26,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.PasswordLessRecovery',
      '9': 24,
      '10': 'passwordlessRecovery',
      '17': true
    },
    {
      '1': 'passwordless_recovery_heartbeat',
      '3': 27,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.PasswordLessRecoveryHeartbeat',
      '9': 25,
      '10': 'passwordlessRecoveryHeartbeat',
      '17': true
    },
    {
      '1': 'story',
      '3': 30,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.Story',
      '9': 26,
      '10': 'story',
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
    EncryptedContent_Story$json,
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
    {'1': '_widget_sharing_allowed'},
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
    {'1': '_story'},
  ],
  '9': [
    {'1': 28, '2': 29},
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
    {
      '1': 'additional_message_data',
      '3': 5,
      '4': 1,
      '5': 12,
      '9': 1,
      '10': 'additionalMessageData',
      '17': true
    },
  ],
  '8': [
    {'1': '_quote_message_id'},
    {'1': '_additional_message_data'},
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
    {'1': 'hidden', '3': 5, '4': 1, '5': 8, '10': 'hidden'},
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
    {
      '1': 'widget_only',
      '3': 12,
      '4': 1,
      '5': 8,
      '9': 7,
      '10': 'widgetOnly',
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
    {'1': '_widget_only'},
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
const EncryptedContent_Story$json = {
  '1': 'Story',
  '2': [
    {
      '1': 'media',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.Media',
      '10': 'media'
    },
    {'1': 'notify', '3': 2, '4': 1, '5': 8, '10': 'notify'},
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
    '9tb3Rpb25ziAEBEjkKFndpZGdldF9zaGFyaW5nX2FsbG93ZWQYHSABKAhIBVIUd2lkZ2V0U2hh'
    'cmluZ0FsbG93ZWSIAQESSwoObWVzc2FnZV91cGRhdGUYBSABKAsyHy5FbmNyeXB0ZWRDb250ZW'
    '50Lk1lc3NhZ2VVcGRhdGVIBlINbWVzc2FnZVVwZGF0ZYgBARIyCgVtZWRpYRgGIAEoCzIXLkVu'
    'Y3J5cHRlZENvbnRlbnQuTWVkaWFIB1IFbWVkaWGIAQESRQoMbWVkaWFfdXBkYXRlGAcgASgLMh'
    '0uRW5jcnlwdGVkQ29udGVudC5NZWRpYVVwZGF0ZUgIUgttZWRpYVVwZGF0ZYgBARJLCg5jb250'
    'YWN0X3VwZGF0ZRgIIAEoCzIfLkVuY3J5cHRlZENvbnRlbnQuQ29udGFjdFVwZGF0ZUgJUg1jb2'
    '50YWN0VXBkYXRliAEBEk4KD2NvbnRhY3RfcmVxdWVzdBgJIAEoCzIgLkVuY3J5cHRlZENvbnRl'
    'bnQuQ29udGFjdFJlcXVlc3RIClIOY29udGFjdFJlcXVlc3SIAQESPwoKZmxhbWVfc3luYxgKIA'
    'EoCzIbLkVuY3J5cHRlZENvbnRlbnQuRmxhbWVTeW5jSAtSCWZsYW1lU3luY4gBARI7CghyZWFj'
    'dGlvbhgMIAEoCzIaLkVuY3J5cHRlZENvbnRlbnQuUmVhY3Rpb25IDFIIcmVhY3Rpb26IAQESRQ'
    'oMdGV4dF9tZXNzYWdlGA0gASgLMh0uRW5jcnlwdGVkQ29udGVudC5UZXh0TWVzc2FnZUgNUgt0'
    'ZXh0TWVzc2FnZYgBARJFCgxncm91cF9jcmVhdGUYDiABKAsyHS5FbmNyeXB0ZWRDb250ZW50Lk'
    'dyb3VwQ3JlYXRlSA5SC2dyb3VwQ3JlYXRliAEBEj8KCmdyb3VwX2pvaW4YDyABKAsyGy5FbmNy'
    'eXB0ZWRDb250ZW50Lkdyb3VwSm9pbkgPUglncm91cEpvaW6IAQESRQoMZ3JvdXBfdXBkYXRlGB'
    'AgASgLMh0uRW5jcnlwdGVkQ29udGVudC5Hcm91cFVwZGF0ZUgQUgtncm91cFVwZGF0ZYgBARJi'
    'ChdyZXNlbmRfZ3JvdXBfcHVibGljX2tleRgRIAEoCzImLkVuY3J5cHRlZENvbnRlbnQuUmVzZW'
    '5kR3JvdXBQdWJsaWNLZXlIEVIUcmVzZW5kR3JvdXBQdWJsaWNLZXmIAQESSwoOZXJyb3JfbWVz'
    'c2FnZXMYEiABKAsyHy5FbmNyeXB0ZWRDb250ZW50LkVycm9yTWVzc2FnZXNIElINZXJyb3JNZX'
    'NzYWdlc4gBARJkChdhZGRpdGlvbmFsX2RhdGFfbWVzc2FnZRgTIAEoCzInLkVuY3J5cHRlZENv'
    'bnRlbnQuQWRkaXRpb25hbERhdGFNZXNzYWdlSBNSFWFkZGl0aW9uYWxEYXRhTWVzc2FnZYgBAR'
    'JRChB0eXBpbmdfaW5kaWNhdG9yGBQgASgLMiEuRW5jcnlwdGVkQ29udGVudC5UeXBpbmdJbmRp'
    'Y2F0b3JIFFIPdHlwaW5nSW5kaWNhdG9yiAEBEmEKFnVzZXJfZGlzY292ZXJ5X3JlcXVlc3QYFi'
    'ABKAsyJi5FbmNyeXB0ZWRDb250ZW50LlVzZXJEaXNjb3ZlcnlSZXF1ZXN0SBVSFHVzZXJEaXNj'
    'b3ZlcnlSZXF1ZXN0iAEBEl4KFXVzZXJfZGlzY292ZXJ5X3VwZGF0ZRgXIAEoCzIlLkVuY3J5cH'
    'RlZENvbnRlbnQuVXNlckRpc2NvdmVyeVVwZGF0ZUgWUhN1c2VyRGlzY292ZXJ5VXBkYXRliAEB'
    'EmEKFmtleV92ZXJpZmljYXRpb25fcHJvb2YYGCABKAsyJi5FbmNyeXB0ZWRDb250ZW50LktleV'
    'ZlcmlmaWNhdGlvblByb29mSBdSFGtleVZlcmlmaWNhdGlvblByb29miAEBEmAKFXBhc3N3b3Jk'
    'bGVzc19yZWNvdmVyeRgaIAEoCzImLkVuY3J5cHRlZENvbnRlbnQuUGFzc3dvcmRMZXNzUmVjb3'
    'ZlcnlIGFIUcGFzc3dvcmRsZXNzUmVjb3ZlcnmIAQESfAofcGFzc3dvcmRsZXNzX3JlY292ZXJ5'
    'X2hlYXJ0YmVhdBgbIAEoCzIvLkVuY3J5cHRlZENvbnRlbnQuUGFzc3dvcmRMZXNzUmVjb3Zlcn'
    'lIZWFydGJlYXRIGVIdcGFzc3dvcmRsZXNzUmVjb3ZlcnlIZWFydGJlYXSIAQESMgoFc3RvcnkY'
    'HiABKAsyFy5FbmNyeXB0ZWRDb250ZW50LlN0b3J5SBpSBXN0b3J5iAEBGpYCCg1FcnJvck1lc3'
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
    '9uZXdfZGVsZXRlX21lc3NhZ2VzX2FmdGVyX21pbGxpc2Vjb25kcxqIAgoLVGV4dE1lc3NhZ2US'
    'KgoRc2VuZGVyX21lc3NhZ2VfaWQYASABKAlSD3NlbmRlck1lc3NhZ2VJZBISCgR0ZXh0GAIgAS'
    'gJUgR0ZXh0EhwKCXRpbWVzdGFtcBgDIAEoA1IJdGltZXN0YW1wEi0KEHF1b3RlX21lc3NhZ2Vf'
    'aWQYBCABKAlIAFIOcXVvdGVNZXNzYWdlSWSIAQESOwoXYWRkaXRpb25hbF9tZXNzYWdlX2RhdG'
    'EYBSABKAxIAVIVYWRkaXRpb25hbE1lc3NhZ2VEYXRhiAEBQhMKEV9xdW90ZV9tZXNzYWdlX2lk'
    'QhoKGF9hZGRpdGlvbmFsX21lc3NhZ2VfZGF0YRrmAQoVQWRkaXRpb25hbERhdGFNZXNzYWdlEi'
    'oKEXNlbmRlcl9tZXNzYWdlX2lkGAEgASgJUg9zZW5kZXJNZXNzYWdlSWQSHAoJdGltZXN0YW1w'
    'GAIgASgDUgl0aW1lc3RhbXASEgoEdHlwZRgDIAEoCVIEdHlwZRI7ChdhZGRpdGlvbmFsX21lc3'
    'NhZ2VfZGF0YRgEIAEoDEgAUhVhZGRpdGlvbmFsTWVzc2FnZURhdGGIAQESFgoGaGlkZGVuGAUg'
    'ASgIUgZoaWRkZW5CGgoYX2FkZGl0aW9uYWxfbWVzc2FnZV9kYXRhGmQKCFJlYWN0aW9uEioKEX'
    'RhcmdldF9tZXNzYWdlX2lkGAEgASgJUg90YXJnZXRNZXNzYWdlSWQSFAoFZW1vamkYAiABKAlS'
    'BWVtb2ppEhYKBnJlbW92ZRgDIAEoCFIGcmVtb3ZlGr4CCg1NZXNzYWdlVXBkYXRlEjgKBHR5cG'
    'UYASABKA4yJC5FbmNyeXB0ZWRDb250ZW50Lk1lc3NhZ2VVcGRhdGUuVHlwZVIEdHlwZRIvChFz'
    'ZW5kZXJfbWVzc2FnZV9pZBgCIAEoCUgAUg9zZW5kZXJNZXNzYWdlSWSIAQESPQobbXVsdGlwbG'
    'VfdGFyZ2V0X21lc3NhZ2VfaWRzGAMgAygJUhhtdWx0aXBsZVRhcmdldE1lc3NhZ2VJZHMSFwoE'
    'dGV4dBgEIAEoCUgBUgR0ZXh0iAEBEhwKCXRpbWVzdGFtcBgFIAEoA1IJdGltZXN0YW1wIi0KBF'
    'R5cGUSCgoGREVMRVRFEAASDQoJRURJVF9URVhUEAESCgoGT1BFTkVEEAJCFAoSX3NlbmRlcl9t'
    'ZXNzYWdlX2lkQgcKBV90ZXh0GrsGCgVNZWRpYRIqChFzZW5kZXJfbWVzc2FnZV9pZBgBIAEoCV'
    'IPc2VuZGVyTWVzc2FnZUlkEjAKBHR5cGUYAiABKA4yHC5FbmNyeXB0ZWRDb250ZW50Lk1lZGlh'
    'LlR5cGVSBHR5cGUSRgodZGlzcGxheV9saW1pdF9pbl9taWxsaXNlY29uZHMYAyABKANIAFIaZG'
    'lzcGxheUxpbWl0SW5NaWxsaXNlY29uZHOIAQESNwoXcmVxdWlyZXNfYXV0aGVudGljYXRpb24Y'
    'BCABKAhSFnJlcXVpcmVzQXV0aGVudGljYXRpb24SHAoJdGltZXN0YW1wGAUgASgDUgl0aW1lc3'
    'RhbXASLQoQcXVvdGVfbWVzc2FnZV9pZBgGIAEoCUgBUg5xdW90ZU1lc3NhZ2VJZIgBARIqCg5k'
    'b3dubG9hZF90b2tlbhgHIAEoDEgCUg1kb3dubG9hZFRva2VuiAEBEioKDmVuY3J5cHRpb25fa2'
    'V5GAggASgMSANSDWVuY3J5cHRpb25LZXmIAQESKgoOZW5jcnlwdGlvbl9tYWMYCSABKAxIBFIN'
    'ZW5jcnlwdGlvbk1hY4gBARIuChBlbmNyeXB0aW9uX25vbmNlGAogASgMSAVSD2VuY3J5cHRpb2'
    '5Ob25jZYgBARI7ChdhZGRpdGlvbmFsX21lc3NhZ2VfZGF0YRgLIAEoDEgGUhVhZGRpdGlvbmFs'
    'TWVzc2FnZURhdGGIAQESJAoLd2lkZ2V0X29ubHkYDCABKAhIB1IKd2lkZ2V0T25seYgBASI+Cg'
    'RUeXBlEgwKCFJFVVBMT0FEEAASCQoFSU1BR0UQARIJCgVWSURFTxACEgcKA0dJRhADEgkKBUFV'
    'RElPEARCIAoeX2Rpc3BsYXlfbGltaXRfaW5fbWlsbGlzZWNvbmRzQhMKEV9xdW90ZV9tZXNzYW'
    'dlX2lkQhEKD19kb3dubG9hZF90b2tlbkIRCg9fZW5jcnlwdGlvbl9rZXlCEQoPX2VuY3J5cHRp'
    'b25fbWFjQhMKEV9lbmNyeXB0aW9uX25vbmNlQhoKGF9hZGRpdGlvbmFsX21lc3NhZ2VfZGF0YU'
    'IOCgxfd2lkZ2V0X29ubHkaTgoFU3RvcnkSLQoFbWVkaWEYASABKAsyFy5FbmNyeXB0ZWRDb250'
    'ZW50Lk1lZGlhUgVtZWRpYRIWCgZub3RpZnkYAiABKAhSBm5vdGlmeRqpAQoLTWVkaWFVcGRhdG'
    'USNgoEdHlwZRgBIAEoDjIiLkVuY3J5cHRlZENvbnRlbnQuTWVkaWFVcGRhdGUuVHlwZVIEdHlw'
    'ZRIqChF0YXJnZXRfbWVzc2FnZV9pZBgCIAEoCVIPdGFyZ2V0TWVzc2FnZUlkIjYKBFR5cGUSDA'
    'oIUkVPUEVORUQQABIKCgZTVE9SRUQQARIUChBERUNSWVBUSU9OX0VSUk9SEAIaeAoOQ29udGFj'
    'dFJlcXVlc3QSOQoEdHlwZRgBIAEoDjIlLkVuY3J5cHRlZENvbnRlbnQuQ29udGFjdFJlcXVlc3'
    'QuVHlwZVIEdHlwZSIrCgRUeXBlEgsKB1JFUVVFU1QQABIKCgZSRUpFQ1QQARIKCgZBQ0NFUFQQ'
    'AhqkAgoNQ29udGFjdFVwZGF0ZRI4CgR0eXBlGAEgASgOMiQuRW5jcnlwdGVkQ29udGVudC5Db2'
    '50YWN0VXBkYXRlLlR5cGVSBHR5cGUSNwoVYXZhdGFyX3N2Z19jb21wcmVzc2VkGAIgASgMSABS'
    'E2F2YXRhclN2Z0NvbXByZXNzZWSIAQESHwoIdXNlcm5hbWUYAyABKAlIAVIIdXNlcm5hbWWIAQ'
    'ESJgoMZGlzcGxheV9uYW1lGAQgASgJSAJSC2Rpc3BsYXlOYW1liAEBIh8KBFR5cGUSCwoHUkVR'
    'VUVTVBAAEgoKBlVQREFURRABQhgKFl9hdmF0YXJfc3ZnX2NvbXByZXNzZWRCCwoJX3VzZXJuYW'
    '1lQg8KDV9kaXNwbGF5X25hbWUarwEKCUZsYW1lU3luYxIjCg1mbGFtZV9jb3VudGVyGAEgASgD'
    'UgxmbGFtZUNvdW50ZXISOQoZbGFzdF9mbGFtZV9jb3VudGVyX2NoYW5nZRgCIAEoA1IWbGFzdE'
    'ZsYW1lQ291bnRlckNoYW5nZRIfCgtiZXN0X2ZyaWVuZBgDIAEoCFIKYmVzdEZyaWVuZBIhCgxm'
    'b3JjZV91cGRhdGUYBCABKAhSC2ZvcmNlVXBkYXRlGk0KD1R5cGluZ0luZGljYXRvchIbCglpc1'
    '90eXBpbmcYASABKAhSCGlzVHlwaW5nEh0KCmNyZWF0ZWRfYXQYAiABKANSCWNyZWF0ZWRBdBo/'
    'ChRVc2VyRGlzY292ZXJ5UmVxdWVzdBInCg9jdXJyZW50X3ZlcnNpb24YASABKAxSDmN1cnJlbn'
    'RWZXJzaW9uGjEKE1VzZXJEaXNjb3ZlcnlVcGRhdGUSGgoIbWVzc2FnZXMYASADKAxSCG1lc3Nh'
    'Z2VzGj0KFEtleVZlcmlmaWNhdGlvblByb29mEiUKDmNhbGN1bGF0ZWRfbWFjGAEgASgMUg1jYW'
    'xjdWxhdGVkTWFjGpsBChRQYXNzd29yZExlc3NSZWNvdmVyeRI1ChNyZWNvdmVyeVNlY3JldFNo'
    'YXJlGAEgASgMSABSE3JlY292ZXJ5U2VjcmV0U2hhcmWIAQESFgoGZGVsZXRlGAIgASgIUgZkZW'
    'xldGUSHAoJdGhyZXNob2xkGAMgASgDUgl0aHJlc2hvbGRCFgoUX3JlY292ZXJ5U2VjcmV0U2hh'
    'cmUaMwodUGFzc3dvcmRMZXNzUmVjb3ZlcnlIZWFydGJlYXQSEgoEaGFzaBgBIAEoDFIEaGFzaE'
    'ILCglfZ3JvdXBfaWRCEQoPX2lzX2RpcmVjdF9jaGF0QhkKF19zZW5kZXJfcHJvZmlsZV9jb3Vu'
    'dGVyQiAKHl9zZW5kZXJfdXNlcl9kaXNjb3ZlcnlfdmVyc2lvbkIcChpfYXNrX2Zvcl9mcmllbm'
    'RfcHJvbW90aW9uc0IZChdfd2lkZ2V0X3NoYXJpbmdfYWxsb3dlZEIRCg9fbWVzc2FnZV91cGRh'
    'dGVCCAoGX21lZGlhQg8KDV9tZWRpYV91cGRhdGVCEQoPX2NvbnRhY3RfdXBkYXRlQhIKEF9jb2'
    '50YWN0X3JlcXVlc3RCDQoLX2ZsYW1lX3N5bmNCCwoJX3JlYWN0aW9uQg8KDV90ZXh0X21lc3Nh'
    'Z2VCDwoNX2dyb3VwX2NyZWF0ZUINCgtfZ3JvdXBfam9pbkIPCg1fZ3JvdXBfdXBkYXRlQhoKGF'
    '9yZXNlbmRfZ3JvdXBfcHVibGljX2tleUIRCg9fZXJyb3JfbWVzc2FnZXNCGgoYX2FkZGl0aW9u'
    'YWxfZGF0YV9tZXNzYWdlQhMKEV90eXBpbmdfaW5kaWNhdG9yQhkKF191c2VyX2Rpc2NvdmVyeV'
    '9yZXF1ZXN0QhgKFl91c2VyX2Rpc2NvdmVyeV91cGRhdGVCGQoXX2tleV92ZXJpZmljYXRpb25f'
    'cHJvb2ZCGAoWX3Bhc3N3b3JkbGVzc19yZWNvdmVyeUIiCiBfcGFzc3dvcmRsZXNzX3JlY292ZX'
    'J5X2hlYXJ0YmVhdEIICgZfc3RvcnlKBAgcEB0=');
