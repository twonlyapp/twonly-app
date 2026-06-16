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

@$core.Deprecated('Use messageDescriptor instead')
const Message$json = {
  '1': 'Message',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 14, '6': '.Message.Type', '10': 'type'},
    {'1': 'receipt_id', '3': 2, '4': 1, '5': 9, '10': 'receiptId'},
    {
      '1': 'encrypted_content',
      '3': 3,
      '4': 1,
      '5': 12,
      '9': 0,
      '10': 'encryptedContent',
      '17': true
    },
    {
      '1': 'plaintext_content',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.PlaintextContent',
      '9': 1,
      '10': 'plaintextContent',
      '17': true
    },
  ],
  '4': [Message_Type$json],
  '8': [
    {'1': '_encrypted_content'},
    {'1': '_plaintext_content'},
  ],
};

@$core.Deprecated('Use messageDescriptor instead')
const Message_Type$json = {
  '1': 'Type',
  '2': [
    {'1': 'SENDER_DELIVERY_RECEIPT', '2': 0},
    {'1': 'PLAINTEXT_CONTENT', '2': 1},
    {'1': 'CIPHERTEXT', '2': 2},
    {'1': 'PREKEY_BUNDLE', '2': 3},
    {'1': 'TEST_NOTIFICATION', '2': 4},
  ],
};

/// Descriptor for `Message`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List messageDescriptor = $convert.base64Decode(
    'CgdNZXNzYWdlEiEKBHR5cGUYASABKA4yDS5NZXNzYWdlLlR5cGVSBHR5cGUSHQoKcmVjZWlwdF'
    '9pZBgCIAEoCVIJcmVjZWlwdElkEjAKEWVuY3J5cHRlZF9jb250ZW50GAMgASgMSABSEGVuY3J5'
    'cHRlZENvbnRlbnSIAQESQwoRcGxhaW50ZXh0X2NvbnRlbnQYBCABKAsyES5QbGFpbnRleHRDb2'
    '50ZW50SAFSEHBsYWludGV4dENvbnRlbnSIAQEidAoEVHlwZRIbChdTRU5ERVJfREVMSVZFUllf'
    'UkVDRUlQVBAAEhUKEVBMQUlOVEVYVF9DT05URU5UEAESDgoKQ0lQSEVSVEVYVBACEhEKDVBSRU'
    'tFWV9CVU5ETEUQAxIVChFURVNUX05PVElGSUNBVElPThAEQhQKEl9lbmNyeXB0ZWRfY29udGVu'
    'dEIUChJfcGxhaW50ZXh0X2NvbnRlbnQ=');

@$core.Deprecated('Use plaintextContentDescriptor instead')
const PlaintextContent$json = {
  '1': 'PlaintextContent',
  '2': [
    {
      '1': 'decryption_error_message',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.PlaintextContent.DecryptionErrorMessage',
      '9': 0,
      '10': 'decryptionErrorMessage',
      '17': true
    },
    {
      '1': 'retry_control_error',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.PlaintextContent.RetryErrorMessage',
      '9': 1,
      '10': 'retryControlError',
      '17': true
    },
  ],
  '3': [
    PlaintextContent_RetryErrorMessage$json,
    PlaintextContent_DecryptionErrorMessage$json
  ],
  '8': [
    {'1': '_decryption_error_message'},
    {'1': '_retry_control_error'},
  ],
};

@$core.Deprecated('Use plaintextContentDescriptor instead')
const PlaintextContent_RetryErrorMessage$json = {
  '1': 'RetryErrorMessage',
};

@$core.Deprecated('Use plaintextContentDescriptor instead')
const PlaintextContent_DecryptionErrorMessage$json = {
  '1': 'DecryptionErrorMessage',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.PlaintextContent.DecryptionErrorMessage.Type',
      '10': 'type'
    },
  ],
  '4': [PlaintextContent_DecryptionErrorMessage_Type$json],
};

@$core.Deprecated('Use plaintextContentDescriptor instead')
const PlaintextContent_DecryptionErrorMessage_Type$json = {
  '1': 'Type',
  '2': [
    {'1': 'UNKNOWN', '2': 0},
    {'1': 'PREKEY_UNKNOWN', '2': 1},
  ],
};

/// Descriptor for `PlaintextContent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List plaintextContentDescriptor = $convert.base64Decode(
    'ChBQbGFpbnRleHRDb250ZW50EmcKGGRlY3J5cHRpb25fZXJyb3JfbWVzc2FnZRgBIAEoCzIoLl'
    'BsYWludGV4dENvbnRlbnQuRGVjcnlwdGlvbkVycm9yTWVzc2FnZUgAUhZkZWNyeXB0aW9uRXJy'
    'b3JNZXNzYWdliAEBElgKE3JldHJ5X2NvbnRyb2xfZXJyb3IYAiABKAsyIy5QbGFpbnRleHRDb2'
    '50ZW50LlJldHJ5RXJyb3JNZXNzYWdlSAFSEXJldHJ5Q29udHJvbEVycm9yiAEBGhMKEVJldHJ5'
    'RXJyb3JNZXNzYWdlGoQBChZEZWNyeXB0aW9uRXJyb3JNZXNzYWdlEkEKBHR5cGUYASABKA4yLS'
    '5QbGFpbnRleHRDb250ZW50LkRlY3J5cHRpb25FcnJvck1lc3NhZ2UuVHlwZVIEdHlwZSInCgRU'
    'eXBlEgsKB1VOS05PV04QABISCg5QUkVLRVlfVU5LTk9XThABQhsKGV9kZWNyeXB0aW9uX2Vycm'
    '9yX21lc3NhZ2VCFgoUX3JldHJ5X2NvbnRyb2xfZXJyb3I=');

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
      '1': 'push_keys',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.PushKeys',
      '9': 11,
      '10': 'pushKeys',
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
    EncryptedContent_PushKeys$json,
    EncryptedContent_FlameSync$json,
    EncryptedContent_TypingIndicator$json,
    EncryptedContent_UserDiscoveryRequest$json,
    EncryptedContent_UserDiscoveryUpdate$json,
    EncryptedContent_KeyVerificationProof$json
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
    {'1': '_push_keys'},
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
const EncryptedContent_PushKeys$json = {
  '1': 'PushKeys',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.EncryptedContent.PushKeys.Type',
      '10': 'type'
    },
    {'1': 'key_id', '3': 2, '4': 1, '5': 3, '9': 0, '10': 'keyId', '17': true},
    {'1': 'key', '3': 3, '4': 1, '5': 12, '9': 1, '10': 'key', '17': true},
    {
      '1': 'created_at',
      '3': 4,
      '4': 1,
      '5': 3,
      '9': 2,
      '10': 'createdAt',
      '17': true
    },
  ],
  '4': [EncryptedContent_PushKeys_Type$json],
  '8': [
    {'1': '_key_id'},
    {'1': '_key'},
    {'1': '_created_at'},
  ],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_PushKeys_Type$json = {
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
    'Gy5FbmNyeXB0ZWRDb250ZW50LkZsYW1lU3luY0gKUglmbGFtZVN5bmOIAQESPAoJcHVzaF9rZX'
    'lzGAsgASgLMhouRW5jcnlwdGVkQ29udGVudC5QdXNoS2V5c0gLUghwdXNoS2V5c4gBARI7Cghy'
    'ZWFjdGlvbhgMIAEoCzIaLkVuY3J5cHRlZENvbnRlbnQuUmVhY3Rpb25IDFIIcmVhY3Rpb26IAQ'
    'ESRQoMdGV4dF9tZXNzYWdlGA0gASgLMh0uRW5jcnlwdGVkQ29udGVudC5UZXh0TWVzc2FnZUgN'
    'Ugt0ZXh0TWVzc2FnZYgBARJFCgxncm91cF9jcmVhdGUYDiABKAsyHS5FbmNyeXB0ZWRDb250ZW'
    '50Lkdyb3VwQ3JlYXRlSA5SC2dyb3VwQ3JlYXRliAEBEj8KCmdyb3VwX2pvaW4YDyABKAsyGy5F'
    'bmNyeXB0ZWRDb250ZW50Lkdyb3VwSm9pbkgPUglncm91cEpvaW6IAQESRQoMZ3JvdXBfdXBkYX'
    'RlGBAgASgLMh0uRW5jcnlwdGVkQ29udGVudC5Hcm91cFVwZGF0ZUgQUgtncm91cFVwZGF0ZYgB'
    'ARJiChdyZXNlbmRfZ3JvdXBfcHVibGljX2tleRgRIAEoCzImLkVuY3J5cHRlZENvbnRlbnQuUm'
    'VzZW5kR3JvdXBQdWJsaWNLZXlIEVIUcmVzZW5kR3JvdXBQdWJsaWNLZXmIAQESSwoOZXJyb3Jf'
    'bWVzc2FnZXMYEiABKAsyHy5FbmNyeXB0ZWRDb250ZW50LkVycm9yTWVzc2FnZXNIElINZXJyb3'
    'JNZXNzYWdlc4gBARJkChdhZGRpdGlvbmFsX2RhdGFfbWVzc2FnZRgTIAEoCzInLkVuY3J5cHRl'
    'ZENvbnRlbnQuQWRkaXRpb25hbERhdGFNZXNzYWdlSBNSFWFkZGl0aW9uYWxEYXRhTWVzc2FnZY'
    'gBARJRChB0eXBpbmdfaW5kaWNhdG9yGBQgASgLMiEuRW5jcnlwdGVkQ29udGVudC5UeXBpbmdJ'
    'bmRpY2F0b3JIFFIPdHlwaW5nSW5kaWNhdG9yiAEBEmEKFnVzZXJfZGlzY292ZXJ5X3JlcXVlc3'
    'QYFiABKAsyJi5FbmNyeXB0ZWRDb250ZW50LlVzZXJEaXNjb3ZlcnlSZXF1ZXN0SBVSFHVzZXJE'
    'aXNjb3ZlcnlSZXF1ZXN0iAEBEl4KFXVzZXJfZGlzY292ZXJ5X3VwZGF0ZRgXIAEoCzIlLkVuY3'
    'J5cHRlZENvbnRlbnQuVXNlckRpc2NvdmVyeVVwZGF0ZUgWUhN1c2VyRGlzY292ZXJ5VXBkYXRl'
    'iAEBEmEKFmtleV92ZXJpZmljYXRpb25fcHJvb2YYGCABKAsyJi5FbmNyeXB0ZWRDb250ZW50Lk'
    'tleVZlcmlmaWNhdGlvblByb29mSBdSFGtleVZlcmlmaWNhdGlvblByb29miAEBGpYCCg1FcnJv'
    'ck1lc3NhZ2VzEjgKBHR5cGUYASABKA4yJC5FbmNyeXB0ZWRDb250ZW50LkVycm9yTWVzc2FnZX'
    'MuVHlwZVIEdHlwZRIsChJyZWxhdGVkX3JlY2VpcHRfaWQYAiABKAlSEHJlbGF0ZWRSZWNlaXB0'
    'SWQinAEKBFR5cGUSPAo4RVJST1JfUFJPQ0VTU0lOR19NRVNTQUdFX0NSRUFURURfQUNDT1VOVF'
    '9SRVFVRVNUX0lOU1RFQUQQABIYChRVTktOT1dOX01FU1NBR0VfVFlQRRACEhcKE1NFU1NJT05f'
    'T1VUX09GX1NZTkMQAxIjCh9HUk9VUF9OT1RfRk9VTkRfT1JfTk9UX0FfTUVNQkVSEAQahwEKC0'
    'dyb3VwQ3JlYXRlEhsKCXN0YXRlX2tleRgDIAEoDFIIc3RhdGVLZXkSKAoQZ3JvdXBfcHVibGlj'
    'X2tleRgEIAEoDFIOZ3JvdXBQdWJsaWNLZXkSIgoKZ3JvdXBfbmFtZRgFIAEoCUgAUglncm91cE'
    '5hbWWIAQFCDQoLX2dyb3VwX25hbWUaNQoJR3JvdXBKb2luEigKEGdyb3VwX3B1YmxpY19rZXkY'
    'ASABKAxSDmdyb3VwUHVibGljS2V5GhYKFFJlc2VuZEdyb3VwUHVibGljS2V5GsgCCgtHcm91cF'
    'VwZGF0ZRIqChFncm91cF9hY3Rpb25fdHlwZRgBIAEoCVIPZ3JvdXBBY3Rpb25UeXBlEjMKE2Fm'
    'ZmVjdGVkX2NvbnRhY3RfaWQYAiABKANIAFIRYWZmZWN0ZWRDb250YWN0SWSIAQESKQoObmV3X2'
    'dyb3VwX25hbWUYAyABKAlIAVIMbmV3R3JvdXBOYW1liAEBElcKJm5ld19kZWxldGVfbWVzc2Fn'
    'ZXNfYWZ0ZXJfbWlsbGlzZWNvbmRzGAQgASgDSAJSIm5ld0RlbGV0ZU1lc3NhZ2VzQWZ0ZXJNaW'
    'xsaXNlY29uZHOIAQFCFgoUX2FmZmVjdGVkX2NvbnRhY3RfaWRCEQoPX25ld19ncm91cF9uYW1l'
    'QikKJ19uZXdfZGVsZXRlX21lc3NhZ2VzX2FmdGVyX21pbGxpc2Vjb25kcxqvAQoLVGV4dE1lc3'
    'NhZ2USKgoRc2VuZGVyX21lc3NhZ2VfaWQYASABKAlSD3NlbmRlck1lc3NhZ2VJZBISCgR0ZXh0'
    'GAIgASgJUgR0ZXh0EhwKCXRpbWVzdGFtcBgDIAEoA1IJdGltZXN0YW1wEi0KEHF1b3RlX21lc3'
    'NhZ2VfaWQYBCABKAlIAFIOcXVvdGVNZXNzYWdlSWSIAQFCEwoRX3F1b3RlX21lc3NhZ2VfaWQa'
    'zgEKFUFkZGl0aW9uYWxEYXRhTWVzc2FnZRIqChFzZW5kZXJfbWVzc2FnZV9pZBgBIAEoCVIPc2'
    'VuZGVyTWVzc2FnZUlkEhwKCXRpbWVzdGFtcBgCIAEoA1IJdGltZXN0YW1wEhIKBHR5cGUYAyAB'
    'KAlSBHR5cGUSOwoXYWRkaXRpb25hbF9tZXNzYWdlX2RhdGEYBCABKAxIAFIVYWRkaXRpb25hbE'
    '1lc3NhZ2VEYXRhiAEBQhoKGF9hZGRpdGlvbmFsX21lc3NhZ2VfZGF0YRpkCghSZWFjdGlvbhIq'
    'ChF0YXJnZXRfbWVzc2FnZV9pZBgBIAEoCVIPdGFyZ2V0TWVzc2FnZUlkEhQKBWVtb2ppGAIgAS'
    'gJUgVlbW9qaRIWCgZyZW1vdmUYAyABKAhSBnJlbW92ZRq+AgoNTWVzc2FnZVVwZGF0ZRI4CgR0'
    'eXBlGAEgASgOMiQuRW5jcnlwdGVkQ29udGVudC5NZXNzYWdlVXBkYXRlLlR5cGVSBHR5cGUSLw'
    'oRc2VuZGVyX21lc3NhZ2VfaWQYAiABKAlIAFIPc2VuZGVyTWVzc2FnZUlkiAEBEj0KG211bHRp'
    'cGxlX3RhcmdldF9tZXNzYWdlX2lkcxgDIAMoCVIYbXVsdGlwbGVUYXJnZXRNZXNzYWdlSWRzEh'
    'cKBHRleHQYBCABKAlIAVIEdGV4dIgBARIcCgl0aW1lc3RhbXAYBSABKANSCXRpbWVzdGFtcCIt'
    'CgRUeXBlEgoKBkRFTEVURRAAEg0KCUVESVRfVEVYVBABEgoKBk9QRU5FRBACQhQKEl9zZW5kZX'
    'JfbWVzc2FnZV9pZEIHCgVfdGV4dBqFBgoFTWVkaWESKgoRc2VuZGVyX21lc3NhZ2VfaWQYASAB'
    'KAlSD3NlbmRlck1lc3NhZ2VJZBIwCgR0eXBlGAIgASgOMhwuRW5jcnlwdGVkQ29udGVudC5NZW'
    'RpYS5UeXBlUgR0eXBlEkYKHWRpc3BsYXlfbGltaXRfaW5fbWlsbGlzZWNvbmRzGAMgASgDSABS'
    'GmRpc3BsYXlMaW1pdEluTWlsbGlzZWNvbmRziAEBEjcKF3JlcXVpcmVzX2F1dGhlbnRpY2F0aW'
    '9uGAQgASgIUhZyZXF1aXJlc0F1dGhlbnRpY2F0aW9uEhwKCXRpbWVzdGFtcBgFIAEoA1IJdGlt'
    'ZXN0YW1wEi0KEHF1b3RlX21lc3NhZ2VfaWQYBiABKAlIAVIOcXVvdGVNZXNzYWdlSWSIAQESKg'
    'oOZG93bmxvYWRfdG9rZW4YByABKAxIAlINZG93bmxvYWRUb2tlbogBARIqCg5lbmNyeXB0aW9u'
    'X2tleRgIIAEoDEgDUg1lbmNyeXB0aW9uS2V5iAEBEioKDmVuY3J5cHRpb25fbWFjGAkgASgMSA'
    'RSDWVuY3J5cHRpb25NYWOIAQESLgoQZW5jcnlwdGlvbl9ub25jZRgKIAEoDEgFUg9lbmNyeXB0'
    'aW9uTm9uY2WIAQESOwoXYWRkaXRpb25hbF9tZXNzYWdlX2RhdGEYCyABKAxIBlIVYWRkaXRpb2'
    '5hbE1lc3NhZ2VEYXRhiAEBIj4KBFR5cGUSDAoIUkVVUExPQUQQABIJCgVJTUFHRRABEgkKBVZJ'
    'REVPEAISBwoDR0lGEAMSCQoFQVVESU8QBEIgCh5fZGlzcGxheV9saW1pdF9pbl9taWxsaXNlY2'
    '9uZHNCEwoRX3F1b3RlX21lc3NhZ2VfaWRCEQoPX2Rvd25sb2FkX3Rva2VuQhEKD19lbmNyeXB0'
    'aW9uX2tleUIRCg9fZW5jcnlwdGlvbl9tYWNCEwoRX2VuY3J5cHRpb25fbm9uY2VCGgoYX2FkZG'
    'l0aW9uYWxfbWVzc2FnZV9kYXRhGqkBCgtNZWRpYVVwZGF0ZRI2CgR0eXBlGAEgASgOMiIuRW5j'
    'cnlwdGVkQ29udGVudC5NZWRpYVVwZGF0ZS5UeXBlUgR0eXBlEioKEXRhcmdldF9tZXNzYWdlX2'
    'lkGAIgASgJUg90YXJnZXRNZXNzYWdlSWQiNgoEVHlwZRIMCghSRU9QRU5FRBAAEgoKBlNUT1JF'
    'RBABEhQKEERFQ1JZUFRJT05fRVJST1IQAhp4Cg5Db250YWN0UmVxdWVzdBI5CgR0eXBlGAEgAS'
    'gOMiUuRW5jcnlwdGVkQ29udGVudC5Db250YWN0UmVxdWVzdC5UeXBlUgR0eXBlIisKBFR5cGUS'
    'CwoHUkVRVUVTVBAAEgoKBlJFSkVDVBABEgoKBkFDQ0VQVBACGqQCCg1Db250YWN0VXBkYXRlEj'
    'gKBHR5cGUYASABKA4yJC5FbmNyeXB0ZWRDb250ZW50LkNvbnRhY3RVcGRhdGUuVHlwZVIEdHlw'
    'ZRI3ChVhdmF0YXJfc3ZnX2NvbXByZXNzZWQYAiABKAxIAFITYXZhdGFyU3ZnQ29tcHJlc3NlZI'
    'gBARIfCgh1c2VybmFtZRgDIAEoCUgBUgh1c2VybmFtZYgBARImCgxkaXNwbGF5X25hbWUYBCAB'
    'KAlIAlILZGlzcGxheU5hbWWIAQEiHwoEVHlwZRILCgdSRVFVRVNUEAASCgoGVVBEQVRFEAFCGA'
    'oWX2F2YXRhcl9zdmdfY29tcHJlc3NlZEILCglfdXNlcm5hbWVCDwoNX2Rpc3BsYXlfbmFtZRrZ'
    'AQoIUHVzaEtleXMSMwoEdHlwZRgBIAEoDjIfLkVuY3J5cHRlZENvbnRlbnQuUHVzaEtleXMuVH'
    'lwZVIEdHlwZRIaCgZrZXlfaWQYAiABKANIAFIFa2V5SWSIAQESFQoDa2V5GAMgASgMSAFSA2tl'
    'eYgBARIiCgpjcmVhdGVkX2F0GAQgASgDSAJSCWNyZWF0ZWRBdIgBASIfCgRUeXBlEgsKB1JFUV'
    'VFU1QQABIKCgZVUERBVEUQAUIJCgdfa2V5X2lkQgYKBF9rZXlCDQoLX2NyZWF0ZWRfYXQarwEK'
    'CUZsYW1lU3luYxIjCg1mbGFtZV9jb3VudGVyGAEgASgDUgxmbGFtZUNvdW50ZXISOQoZbGFzdF'
    '9mbGFtZV9jb3VudGVyX2NoYW5nZRgCIAEoA1IWbGFzdEZsYW1lQ291bnRlckNoYW5nZRIfCgti'
    'ZXN0X2ZyaWVuZBgDIAEoCFIKYmVzdEZyaWVuZBIhCgxmb3JjZV91cGRhdGUYBCABKAhSC2Zvcm'
    'NlVXBkYXRlGk0KD1R5cGluZ0luZGljYXRvchIbCglpc190eXBpbmcYASABKAhSCGlzVHlwaW5n'
    'Eh0KCmNyZWF0ZWRfYXQYAiABKANSCWNyZWF0ZWRBdBo/ChRVc2VyRGlzY292ZXJ5UmVxdWVzdB'
    'InCg9jdXJyZW50X3ZlcnNpb24YASABKAxSDmN1cnJlbnRWZXJzaW9uGjEKE1VzZXJEaXNjb3Zl'
    'cnlVcGRhdGUSGgoIbWVzc2FnZXMYASADKAxSCG1lc3NhZ2VzGj0KFEtleVZlcmlmaWNhdGlvbl'
    'Byb29mEiUKDmNhbGN1bGF0ZWRfbWFjGAEgASgMUg1jYWxjdWxhdGVkTWFjQgsKCV9ncm91cF9p'
    'ZEIRCg9faXNfZGlyZWN0X2NoYXRCGQoXX3NlbmRlcl9wcm9maWxlX2NvdW50ZXJCIAoeX3Nlbm'
    'Rlcl91c2VyX2Rpc2NvdmVyeV92ZXJzaW9uQhwKGl9hc2tfZm9yX2ZyaWVuZF9wcm9tb3Rpb25z'
    'QhEKD19tZXNzYWdlX3VwZGF0ZUIICgZfbWVkaWFCDwoNX21lZGlhX3VwZGF0ZUIRCg9fY29udG'
    'FjdF91cGRhdGVCEgoQX2NvbnRhY3RfcmVxdWVzdEINCgtfZmxhbWVfc3luY0IMCgpfcHVzaF9r'
    'ZXlzQgsKCV9yZWFjdGlvbkIPCg1fdGV4dF9tZXNzYWdlQg8KDV9ncm91cF9jcmVhdGVCDQoLX2'
    'dyb3VwX2pvaW5CDwoNX2dyb3VwX3VwZGF0ZUIaChhfcmVzZW5kX2dyb3VwX3B1YmxpY19rZXlC'
    'EQoPX2Vycm9yX21lc3NhZ2VzQhoKGF9hZGRpdGlvbmFsX2RhdGFfbWVzc2FnZUITChFfdHlwaW'
    '5nX2luZGljYXRvckIZChdfdXNlcl9kaXNjb3ZlcnlfcmVxdWVzdEIYChZfdXNlcl9kaXNjb3Zl'
    'cnlfdXBkYXRlQhkKF19rZXlfdmVyaWZpY2F0aW9uX3Byb29m');
