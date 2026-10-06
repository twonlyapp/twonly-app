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
      '1': 'sender_twonly_score',
      '3': 31,
      '4': 1,
      '5': 3,
      '9': 6,
      '10': 'senderTwonlyScore',
      '17': true
    },
    {
      '1': 'sender_custom_avatar_counter',
      '3': 32,
      '4': 1,
      '5': 3,
      '9': 7,
      '10': 'senderCustomAvatarCounter',
      '17': true
    },
    {
      '1': 'custom_avatar_protocol_version',
      '3': 33,
      '4': 1,
      '5': 13,
      '9': 8,
      '10': 'customAvatarProtocolVersion',
      '17': true
    },
    {
      '1': 'message_update',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.MessageUpdate',
      '9': 9,
      '10': 'messageUpdate',
      '17': true
    },
    {
      '1': 'media',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.Media',
      '9': 10,
      '10': 'media',
      '17': true
    },
    {
      '1': 'media_update',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.MediaUpdate',
      '9': 11,
      '10': 'mediaUpdate',
      '17': true
    },
    {
      '1': 'contact_update',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.ContactUpdate',
      '9': 12,
      '10': 'contactUpdate',
      '17': true
    },
    {
      '1': 'contact_request',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.ContactRequest',
      '9': 13,
      '10': 'contactRequest',
      '17': true
    },
    {
      '1': 'flame_sync',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.FlameSync',
      '9': 14,
      '10': 'flameSync',
      '17': true
    },
    {
      '1': 'reaction',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.Reaction',
      '9': 15,
      '10': 'reaction',
      '17': true
    },
    {
      '1': 'text_message',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.TextMessage',
      '9': 16,
      '10': 'textMessage',
      '17': true
    },
    {
      '1': 'group_create',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.GroupCreate',
      '9': 17,
      '10': 'groupCreate',
      '17': true
    },
    {
      '1': 'group_join',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.GroupJoin',
      '9': 18,
      '10': 'groupJoin',
      '17': true
    },
    {
      '1': 'group_update',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.GroupUpdate',
      '9': 19,
      '10': 'groupUpdate',
      '17': true
    },
    {
      '1': 'resend_group_public_key',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.ResendGroupPublicKey',
      '9': 20,
      '10': 'resendGroupPublicKey',
      '17': true
    },
    {
      '1': 'error_messages',
      '3': 18,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.ErrorMessages',
      '9': 21,
      '10': 'errorMessages',
      '17': true
    },
    {
      '1': 'additional_data_message',
      '3': 19,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.AdditionalDataMessage',
      '9': 22,
      '10': 'additionalDataMessage',
      '17': true
    },
    {
      '1': 'typing_indicator',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.TypingIndicator',
      '9': 23,
      '10': 'typingIndicator',
      '17': true
    },
    {
      '1': 'user_discovery_request',
      '3': 22,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.UserDiscoveryRequest',
      '9': 24,
      '10': 'userDiscoveryRequest',
      '17': true
    },
    {
      '1': 'user_discovery_update',
      '3': 23,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.UserDiscoveryUpdate',
      '9': 25,
      '10': 'userDiscoveryUpdate',
      '17': true
    },
    {
      '1': 'key_verification_proof',
      '3': 24,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.KeyVerificationProof',
      '9': 26,
      '10': 'keyVerificationProof',
      '17': true
    },
    {
      '1': 'passwordless_recovery',
      '3': 26,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.PasswordLessRecovery',
      '9': 27,
      '10': 'passwordlessRecovery',
      '17': true
    },
    {
      '1': 'passwordless_recovery_heartbeat',
      '3': 27,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.PasswordLessRecoveryHeartbeat',
      '9': 28,
      '10': 'passwordlessRecoveryHeartbeat',
      '17': true
    },
    {
      '1': 'story',
      '3': 30,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.Story',
      '9': 29,
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
    EncryptedContent_CustomAvatar$json,
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
    {'1': '_sender_twonly_score'},
    {'1': '_sender_custom_avatar_counter'},
    {'1': '_custom_avatar_protocol_version'},
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
    {
      '1': 'custom_avatar_requested',
      '3': 5,
      '4': 1,
      '5': 8,
      '9': 3,
      '10': 'customAvatarRequested',
      '17': true
    },
    {
      '1': 'custom_avatar',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.CustomAvatar',
      '9': 4,
      '10': 'customAvatar',
      '17': true
    },
  ],
  '4': [EncryptedContent_ContactUpdate_Type$json],
  '8': [
    {'1': '_avatar_svg_compressed'},
    {'1': '_username'},
    {'1': '_display_name'},
    {'1': '_custom_avatar_requested'},
    {'1': '_custom_avatar'},
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
const EncryptedContent_CustomAvatar$json = {
  '1': 'CustomAvatar',
  '2': [
    {'1': 'version', '3': 1, '4': 1, '5': 13, '10': 'version'},
    {
      '1': 'publication_counter',
      '3': 2,
      '4': 1,
      '5': 3,
      '10': 'publicationCounter'
    },
    {
      '1': 'state',
      '3': 3,
      '4': 1,
      '5': 14,
      '6': '.EncryptedContent.CustomAvatar.State',
      '10': 'state'
    },
    {'1': 'webp', '3': 4, '4': 1, '5': 12, '9': 0, '10': 'webp', '17': true},
    {
      '1': 'sha256',
      '3': 5,
      '4': 1,
      '5': 12,
      '9': 1,
      '10': 'sha256',
      '17': true
    },
    {'1': 'width', '3': 6, '4': 1, '5': 13, '9': 2, '10': 'width', '17': true},
    {
      '1': 'height',
      '3': 7,
      '4': 1,
      '5': 13,
      '9': 3,
      '10': 'height',
      '17': true
    },
  ],
  '4': [EncryptedContent_CustomAvatar_State$json],
  '8': [
    {'1': '_webp'},
    {'1': '_sha256'},
    {'1': '_width'},
    {'1': '_height'},
  ],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_CustomAvatar_State$json = {
  '1': 'State',
  '2': [
    {'1': 'SVG_ONLY', '2': 0},
    {'1': 'PHOTO', '2': 1},
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
    'cmluZ0FsbG93ZWSIAQESMwoTc2VuZGVyX3R3b25seV9zY29yZRgfIAEoA0gGUhFzZW5kZXJUd2'
    '9ubHlTY29yZYgBARJEChxzZW5kZXJfY3VzdG9tX2F2YXRhcl9jb3VudGVyGCAgASgDSAdSGXNl'
    'bmRlckN1c3RvbUF2YXRhckNvdW50ZXKIAQESSAoeY3VzdG9tX2F2YXRhcl9wcm90b2NvbF92ZX'
    'JzaW9uGCEgASgNSAhSG2N1c3RvbUF2YXRhclByb3RvY29sVmVyc2lvbogBARJLCg5tZXNzYWdl'
    'X3VwZGF0ZRgFIAEoCzIfLkVuY3J5cHRlZENvbnRlbnQuTWVzc2FnZVVwZGF0ZUgJUg1tZXNzYW'
    'dlVXBkYXRliAEBEjIKBW1lZGlhGAYgASgLMhcuRW5jcnlwdGVkQ29udGVudC5NZWRpYUgKUgVt'
    'ZWRpYYgBARJFCgxtZWRpYV91cGRhdGUYByABKAsyHS5FbmNyeXB0ZWRDb250ZW50Lk1lZGlhVX'
    'BkYXRlSAtSC21lZGlhVXBkYXRliAEBEksKDmNvbnRhY3RfdXBkYXRlGAggASgLMh8uRW5jcnlw'
    'dGVkQ29udGVudC5Db250YWN0VXBkYXRlSAxSDWNvbnRhY3RVcGRhdGWIAQESTgoPY29udGFjdF'
    '9yZXF1ZXN0GAkgASgLMiAuRW5jcnlwdGVkQ29udGVudC5Db250YWN0UmVxdWVzdEgNUg5jb250'
    'YWN0UmVxdWVzdIgBARI/CgpmbGFtZV9zeW5jGAogASgLMhsuRW5jcnlwdGVkQ29udGVudC5GbG'
    'FtZVN5bmNIDlIJZmxhbWVTeW5jiAEBEjsKCHJlYWN0aW9uGAwgASgLMhouRW5jcnlwdGVkQ29u'
    'dGVudC5SZWFjdGlvbkgPUghyZWFjdGlvbogBARJFCgx0ZXh0X21lc3NhZ2UYDSABKAsyHS5Fbm'
    'NyeXB0ZWRDb250ZW50LlRleHRNZXNzYWdlSBBSC3RleHRNZXNzYWdliAEBEkUKDGdyb3VwX2Ny'
    'ZWF0ZRgOIAEoCzIdLkVuY3J5cHRlZENvbnRlbnQuR3JvdXBDcmVhdGVIEVILZ3JvdXBDcmVhdG'
    'WIAQESPwoKZ3JvdXBfam9pbhgPIAEoCzIbLkVuY3J5cHRlZENvbnRlbnQuR3JvdXBKb2luSBJS'
    'CWdyb3VwSm9pbogBARJFCgxncm91cF91cGRhdGUYECABKAsyHS5FbmNyeXB0ZWRDb250ZW50Lk'
    'dyb3VwVXBkYXRlSBNSC2dyb3VwVXBkYXRliAEBEmIKF3Jlc2VuZF9ncm91cF9wdWJsaWNfa2V5'
    'GBEgASgLMiYuRW5jcnlwdGVkQ29udGVudC5SZXNlbmRHcm91cFB1YmxpY0tleUgUUhRyZXNlbm'
    'RHcm91cFB1YmxpY0tleYgBARJLCg5lcnJvcl9tZXNzYWdlcxgSIAEoCzIfLkVuY3J5cHRlZENv'
    'bnRlbnQuRXJyb3JNZXNzYWdlc0gVUg1lcnJvck1lc3NhZ2VziAEBEmQKF2FkZGl0aW9uYWxfZG'
    'F0YV9tZXNzYWdlGBMgASgLMicuRW5jcnlwdGVkQ29udGVudC5BZGRpdGlvbmFsRGF0YU1lc3Nh'
    'Z2VIFlIVYWRkaXRpb25hbERhdGFNZXNzYWdliAEBElEKEHR5cGluZ19pbmRpY2F0b3IYFCABKA'
    'syIS5FbmNyeXB0ZWRDb250ZW50LlR5cGluZ0luZGljYXRvckgXUg90eXBpbmdJbmRpY2F0b3KI'
    'AQESYQoWdXNlcl9kaXNjb3ZlcnlfcmVxdWVzdBgWIAEoCzImLkVuY3J5cHRlZENvbnRlbnQuVX'
    'NlckRpc2NvdmVyeVJlcXVlc3RIGFIUdXNlckRpc2NvdmVyeVJlcXVlc3SIAQESXgoVdXNlcl9k'
    'aXNjb3ZlcnlfdXBkYXRlGBcgASgLMiUuRW5jcnlwdGVkQ29udGVudC5Vc2VyRGlzY292ZXJ5VX'
    'BkYXRlSBlSE3VzZXJEaXNjb3ZlcnlVcGRhdGWIAQESYQoWa2V5X3ZlcmlmaWNhdGlvbl9wcm9v'
    'ZhgYIAEoCzImLkVuY3J5cHRlZENvbnRlbnQuS2V5VmVyaWZpY2F0aW9uUHJvb2ZIGlIUa2V5Vm'
    'VyaWZpY2F0aW9uUHJvb2aIAQESYAoVcGFzc3dvcmRsZXNzX3JlY292ZXJ5GBogASgLMiYuRW5j'
    'cnlwdGVkQ29udGVudC5QYXNzd29yZExlc3NSZWNvdmVyeUgbUhRwYXNzd29yZGxlc3NSZWNvdm'
    'VyeYgBARJ8Ch9wYXNzd29yZGxlc3NfcmVjb3ZlcnlfaGVhcnRiZWF0GBsgASgLMi8uRW5jcnlw'
    'dGVkQ29udGVudC5QYXNzd29yZExlc3NSZWNvdmVyeUhlYXJ0YmVhdEgcUh1wYXNzd29yZGxlc3'
    'NSZWNvdmVyeUhlYXJ0YmVhdIgBARIyCgVzdG9yeRgeIAEoCzIXLkVuY3J5cHRlZENvbnRlbnQu'
    'U3RvcnlIHVIFc3RvcnmIAQEalgIKDUVycm9yTWVzc2FnZXMSOAoEdHlwZRgBIAEoDjIkLkVuY3'
    'J5cHRlZENvbnRlbnQuRXJyb3JNZXNzYWdlcy5UeXBlUgR0eXBlEiwKEnJlbGF0ZWRfcmVjZWlw'
    'dF9pZBgCIAEoCVIQcmVsYXRlZFJlY2VpcHRJZCKcAQoEVHlwZRI8CjhFUlJPUl9QUk9DRVNTSU'
    '5HX01FU1NBR0VfQ1JFQVRFRF9BQ0NPVU5UX1JFUVVFU1RfSU5TVEVBRBAAEhgKFFVOS05PV05f'
    'TUVTU0FHRV9UWVBFEAISFwoTU0VTU0lPTl9PVVRfT0ZfU1lOQxADEiMKH0dST1VQX05PVF9GT1'
    'VORF9PUl9OT1RfQV9NRU1CRVIQBBqHAQoLR3JvdXBDcmVhdGUSGwoJc3RhdGVfa2V5GAMgASgM'
    'UghzdGF0ZUtleRIoChBncm91cF9wdWJsaWNfa2V5GAQgASgMUg5ncm91cFB1YmxpY0tleRIiCg'
    'pncm91cF9uYW1lGAUgASgJSABSCWdyb3VwTmFtZYgBAUINCgtfZ3JvdXBfbmFtZRo1CglHcm91'
    'cEpvaW4SKAoQZ3JvdXBfcHVibGljX2tleRgBIAEoDFIOZ3JvdXBQdWJsaWNLZXkaFgoUUmVzZW'
    '5kR3JvdXBQdWJsaWNLZXkayAIKC0dyb3VwVXBkYXRlEioKEWdyb3VwX2FjdGlvbl90eXBlGAEg'
    'ASgJUg9ncm91cEFjdGlvblR5cGUSMwoTYWZmZWN0ZWRfY29udGFjdF9pZBgCIAEoA0gAUhFhZm'
    'ZlY3RlZENvbnRhY3RJZIgBARIpCg5uZXdfZ3JvdXBfbmFtZRgDIAEoCUgBUgxuZXdHcm91cE5h'
    'bWWIAQESVwombmV3X2RlbGV0ZV9tZXNzYWdlc19hZnRlcl9taWxsaXNlY29uZHMYBCABKANIAl'
    'IibmV3RGVsZXRlTWVzc2FnZXNBZnRlck1pbGxpc2Vjb25kc4gBAUIWChRfYWZmZWN0ZWRfY29u'
    'dGFjdF9pZEIRCg9fbmV3X2dyb3VwX25hbWVCKQonX25ld19kZWxldGVfbWVzc2FnZXNfYWZ0ZX'
    'JfbWlsbGlzZWNvbmRzGogCCgtUZXh0TWVzc2FnZRIqChFzZW5kZXJfbWVzc2FnZV9pZBgBIAEo'
    'CVIPc2VuZGVyTWVzc2FnZUlkEhIKBHRleHQYAiABKAlSBHRleHQSHAoJdGltZXN0YW1wGAMgAS'
    'gDUgl0aW1lc3RhbXASLQoQcXVvdGVfbWVzc2FnZV9pZBgEIAEoCUgAUg5xdW90ZU1lc3NhZ2VJ'
    'ZIgBARI7ChdhZGRpdGlvbmFsX21lc3NhZ2VfZGF0YRgFIAEoDEgBUhVhZGRpdGlvbmFsTWVzc2'
    'FnZURhdGGIAQFCEwoRX3F1b3RlX21lc3NhZ2VfaWRCGgoYX2FkZGl0aW9uYWxfbWVzc2FnZV9k'
    'YXRhGuYBChVBZGRpdGlvbmFsRGF0YU1lc3NhZ2USKgoRc2VuZGVyX21lc3NhZ2VfaWQYASABKA'
    'lSD3NlbmRlck1lc3NhZ2VJZBIcCgl0aW1lc3RhbXAYAiABKANSCXRpbWVzdGFtcBISCgR0eXBl'
    'GAMgASgJUgR0eXBlEjsKF2FkZGl0aW9uYWxfbWVzc2FnZV9kYXRhGAQgASgMSABSFWFkZGl0aW'
    '9uYWxNZXNzYWdlRGF0YYgBARIWCgZoaWRkZW4YBSABKAhSBmhpZGRlbkIaChhfYWRkaXRpb25h'
    'bF9tZXNzYWdlX2RhdGEaZAoIUmVhY3Rpb24SKgoRdGFyZ2V0X21lc3NhZ2VfaWQYASABKAlSD3'
    'RhcmdldE1lc3NhZ2VJZBIUCgVlbW9qaRgCIAEoCVIFZW1vamkSFgoGcmVtb3ZlGAMgASgIUgZy'
    'ZW1vdmUavgIKDU1lc3NhZ2VVcGRhdGUSOAoEdHlwZRgBIAEoDjIkLkVuY3J5cHRlZENvbnRlbn'
    'QuTWVzc2FnZVVwZGF0ZS5UeXBlUgR0eXBlEi8KEXNlbmRlcl9tZXNzYWdlX2lkGAIgASgJSABS'
    'D3NlbmRlck1lc3NhZ2VJZIgBARI9ChttdWx0aXBsZV90YXJnZXRfbWVzc2FnZV9pZHMYAyADKA'
    'lSGG11bHRpcGxlVGFyZ2V0TWVzc2FnZUlkcxIXCgR0ZXh0GAQgASgJSAFSBHRleHSIAQESHAoJ'
    'dGltZXN0YW1wGAUgASgDUgl0aW1lc3RhbXAiLQoEVHlwZRIKCgZERUxFVEUQABINCglFRElUX1'
    'RFWFQQARIKCgZPUEVORUQQAkIUChJfc2VuZGVyX21lc3NhZ2VfaWRCBwoFX3RleHQauwYKBU1l'
    'ZGlhEioKEXNlbmRlcl9tZXNzYWdlX2lkGAEgASgJUg9zZW5kZXJNZXNzYWdlSWQSMAoEdHlwZR'
    'gCIAEoDjIcLkVuY3J5cHRlZENvbnRlbnQuTWVkaWEuVHlwZVIEdHlwZRJGCh1kaXNwbGF5X2xp'
    'bWl0X2luX21pbGxpc2Vjb25kcxgDIAEoA0gAUhpkaXNwbGF5TGltaXRJbk1pbGxpc2Vjb25kc4'
    'gBARI3ChdyZXF1aXJlc19hdXRoZW50aWNhdGlvbhgEIAEoCFIWcmVxdWlyZXNBdXRoZW50aWNh'
    'dGlvbhIcCgl0aW1lc3RhbXAYBSABKANSCXRpbWVzdGFtcBItChBxdW90ZV9tZXNzYWdlX2lkGA'
    'YgASgJSAFSDnF1b3RlTWVzc2FnZUlkiAEBEioKDmRvd25sb2FkX3Rva2VuGAcgASgMSAJSDWRv'
    'd25sb2FkVG9rZW6IAQESKgoOZW5jcnlwdGlvbl9rZXkYCCABKAxIA1INZW5jcnlwdGlvbktleY'
    'gBARIqCg5lbmNyeXB0aW9uX21hYxgJIAEoDEgEUg1lbmNyeXB0aW9uTWFjiAEBEi4KEGVuY3J5'
    'cHRpb25fbm9uY2UYCiABKAxIBVIPZW5jcnlwdGlvbk5vbmNliAEBEjsKF2FkZGl0aW9uYWxfbW'
    'Vzc2FnZV9kYXRhGAsgASgMSAZSFWFkZGl0aW9uYWxNZXNzYWdlRGF0YYgBARIkCgt3aWRnZXRf'
    'b25seRgMIAEoCEgHUgp3aWRnZXRPbmx5iAEBIj4KBFR5cGUSDAoIUkVVUExPQUQQABIJCgVJTU'
    'FHRRABEgkKBVZJREVPEAISBwoDR0lGEAMSCQoFQVVESU8QBEIgCh5fZGlzcGxheV9saW1pdF9p'
    'bl9taWxsaXNlY29uZHNCEwoRX3F1b3RlX21lc3NhZ2VfaWRCEQoPX2Rvd25sb2FkX3Rva2VuQh'
    'EKD19lbmNyeXB0aW9uX2tleUIRCg9fZW5jcnlwdGlvbl9tYWNCEwoRX2VuY3J5cHRpb25fbm9u'
    'Y2VCGgoYX2FkZGl0aW9uYWxfbWVzc2FnZV9kYXRhQg4KDF93aWRnZXRfb25seRpOCgVTdG9yeR'
    'ItCgVtZWRpYRgBIAEoCzIXLkVuY3J5cHRlZENvbnRlbnQuTWVkaWFSBW1lZGlhEhYKBm5vdGlm'
    'eRgCIAEoCFIGbm90aWZ5GqkBCgtNZWRpYVVwZGF0ZRI2CgR0eXBlGAEgASgOMiIuRW5jcnlwdG'
    'VkQ29udGVudC5NZWRpYVVwZGF0ZS5UeXBlUgR0eXBlEioKEXRhcmdldF9tZXNzYWdlX2lkGAIg'
    'ASgJUg90YXJnZXRNZXNzYWdlSWQiNgoEVHlwZRIMCghSRU9QRU5FRBAAEgoKBlNUT1JFRBABEh'
    'QKEERFQ1JZUFRJT05fRVJST1IQAhp4Cg5Db250YWN0UmVxdWVzdBI5CgR0eXBlGAEgASgOMiUu'
    'RW5jcnlwdGVkQ29udGVudC5Db250YWN0UmVxdWVzdC5UeXBlUgR0eXBlIisKBFR5cGUSCwoHUk'
    'VRVUVTVBAAEgoKBlJFSkVDVBABEgoKBkFDQ0VQVBACGtkDCg1Db250YWN0VXBkYXRlEjgKBHR5'
    'cGUYASABKA4yJC5FbmNyeXB0ZWRDb250ZW50LkNvbnRhY3RVcGRhdGUuVHlwZVIEdHlwZRI3Ch'
    'VhdmF0YXJfc3ZnX2NvbXByZXNzZWQYAiABKAxIAFITYXZhdGFyU3ZnQ29tcHJlc3NlZIgBARIf'
    'Cgh1c2VybmFtZRgDIAEoCUgBUgh1c2VybmFtZYgBARImCgxkaXNwbGF5X25hbWUYBCABKAlIAl'
    'ILZGlzcGxheU5hbWWIAQESOwoXY3VzdG9tX2F2YXRhcl9yZXF1ZXN0ZWQYBSABKAhIA1IVY3Vz'
    'dG9tQXZhdGFyUmVxdWVzdGVkiAEBEkgKDWN1c3RvbV9hdmF0YXIYBiABKAsyHi5FbmNyeXB0ZW'
    'RDb250ZW50LkN1c3RvbUF2YXRhckgEUgxjdXN0b21BdmF0YXKIAQEiHwoEVHlwZRILCgdSRVFV'
    'RVNUEAASCgoGVVBEQVRFEAFCGAoWX2F2YXRhcl9zdmdfY29tcHJlc3NlZEILCglfdXNlcm5hbW'
    'VCDwoNX2Rpc3BsYXlfbmFtZUIaChhfY3VzdG9tX2F2YXRhcl9yZXF1ZXN0ZWRCEAoOX2N1c3Rv'
    'bV9hdmF0YXIazgIKDEN1c3RvbUF2YXRhchIYCgd2ZXJzaW9uGAEgASgNUgd2ZXJzaW9uEi8KE3'
    'B1YmxpY2F0aW9uX2NvdW50ZXIYAiABKANSEnB1YmxpY2F0aW9uQ291bnRlchI6CgVzdGF0ZRgD'
    'IAEoDjIkLkVuY3J5cHRlZENvbnRlbnQuQ3VzdG9tQXZhdGFyLlN0YXRlUgVzdGF0ZRIXCgR3ZW'
    'JwGAQgASgMSABSBHdlYnCIAQESGwoGc2hhMjU2GAUgASgMSAFSBnNoYTI1NogBARIZCgV3aWR0'
    'aBgGIAEoDUgCUgV3aWR0aIgBARIbCgZoZWlnaHQYByABKA1IA1IGaGVpZ2h0iAEBIiAKBVN0YX'
    'RlEgwKCFNWR19PTkxZEAASCQoFUEhPVE8QAUIHCgVfd2VicEIJCgdfc2hhMjU2QggKBl93aWR0'
    'aEIJCgdfaGVpZ2h0Gq8BCglGbGFtZVN5bmMSIwoNZmxhbWVfY291bnRlchgBIAEoA1IMZmxhbW'
    'VDb3VudGVyEjkKGWxhc3RfZmxhbWVfY291bnRlcl9jaGFuZ2UYAiABKANSFmxhc3RGbGFtZUNv'
    'dW50ZXJDaGFuZ2USHwoLYmVzdF9mcmllbmQYAyABKAhSCmJlc3RGcmllbmQSIQoMZm9yY2VfdX'
    'BkYXRlGAQgASgIUgtmb3JjZVVwZGF0ZRpNCg9UeXBpbmdJbmRpY2F0b3ISGwoJaXNfdHlwaW5n'
    'GAEgASgIUghpc1R5cGluZxIdCgpjcmVhdGVkX2F0GAIgASgDUgljcmVhdGVkQXQaPwoUVXNlck'
    'Rpc2NvdmVyeVJlcXVlc3QSJwoPY3VycmVudF92ZXJzaW9uGAEgASgMUg5jdXJyZW50VmVyc2lv'
    'bhoxChNVc2VyRGlzY292ZXJ5VXBkYXRlEhoKCG1lc3NhZ2VzGAEgAygMUghtZXNzYWdlcxo9Ch'
    'RLZXlWZXJpZmljYXRpb25Qcm9vZhIlCg5jYWxjdWxhdGVkX21hYxgBIAEoDFINY2FsY3VsYXRl'
    'ZE1hYxqbAQoUUGFzc3dvcmRMZXNzUmVjb3ZlcnkSNQoTcmVjb3ZlcnlTZWNyZXRTaGFyZRgBIA'
    'EoDEgAUhNyZWNvdmVyeVNlY3JldFNoYXJliAEBEhYKBmRlbGV0ZRgCIAEoCFIGZGVsZXRlEhwK'
    'CXRocmVzaG9sZBgDIAEoA1IJdGhyZXNob2xkQhYKFF9yZWNvdmVyeVNlY3JldFNoYXJlGjMKHV'
    'Bhc3N3b3JkTGVzc1JlY292ZXJ5SGVhcnRiZWF0EhIKBGhhc2gYASABKAxSBGhhc2hCCwoJX2dy'
    'b3VwX2lkQhEKD19pc19kaXJlY3RfY2hhdEIZChdfc2VuZGVyX3Byb2ZpbGVfY291bnRlckIgCh'
    '5fc2VuZGVyX3VzZXJfZGlzY292ZXJ5X3ZlcnNpb25CHAoaX2Fza19mb3JfZnJpZW5kX3Byb21v'
    'dGlvbnNCGQoXX3dpZGdldF9zaGFyaW5nX2FsbG93ZWRCFgoUX3NlbmRlcl90d29ubHlfc2Nvcm'
    'VCHwodX3NlbmRlcl9jdXN0b21fYXZhdGFyX2NvdW50ZXJCIQofX2N1c3RvbV9hdmF0YXJfcHJv'
    'dG9jb2xfdmVyc2lvbkIRCg9fbWVzc2FnZV91cGRhdGVCCAoGX21lZGlhQg8KDV9tZWRpYV91cG'
    'RhdGVCEQoPX2NvbnRhY3RfdXBkYXRlQhIKEF9jb250YWN0X3JlcXVlc3RCDQoLX2ZsYW1lX3N5'
    'bmNCCwoJX3JlYWN0aW9uQg8KDV90ZXh0X21lc3NhZ2VCDwoNX2dyb3VwX2NyZWF0ZUINCgtfZ3'
    'JvdXBfam9pbkIPCg1fZ3JvdXBfdXBkYXRlQhoKGF9yZXNlbmRfZ3JvdXBfcHVibGljX2tleUIR'
    'Cg9fZXJyb3JfbWVzc2FnZXNCGgoYX2FkZGl0aW9uYWxfZGF0YV9tZXNzYWdlQhMKEV90eXBpbm'
    'dfaW5kaWNhdG9yQhkKF191c2VyX2Rpc2NvdmVyeV9yZXF1ZXN0QhgKFl91c2VyX2Rpc2NvdmVy'
    'eV91cGRhdGVCGQoXX2tleV92ZXJpZmljYXRpb25fcHJvb2ZCGAoWX3Bhc3N3b3JkbGVzc19yZW'
    'NvdmVyeUIiCiBfcGFzc3dvcmRsZXNzX3JlY292ZXJ5X2hlYXJ0YmVhdEIICgZfc3RvcnlKBAgc'
    'EB0=');
