// This is a generated file - do not edit.
//
// Generated from messages.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use messageDescriptor instead')
const Message$json = {
  '1': 'Message',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 14, '6': '.Message.Type', '10': 'type'},
    {'1': 'receiptId', '3': 2, '4': 1, '5': 9, '10': 'receiptId'},
    {
      '1': 'encryptedContent',
      '3': 3,
      '4': 1,
      '5': 12,
      '9': 0,
      '10': 'encryptedContent',
      '17': true
    },
    {
      '1': 'plaintextContent',
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
    {'1': '_encryptedContent'},
    {'1': '_plaintextContent'},
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
    'CgdNZXNzYWdlEiEKBHR5cGUYASABKA4yDS5NZXNzYWdlLlR5cGVSBHR5cGUSHAoJcmVjZWlwdE'
    'lkGAIgASgJUglyZWNlaXB0SWQSLwoQZW5jcnlwdGVkQ29udGVudBgDIAEoDEgAUhBlbmNyeXB0'
    'ZWRDb250ZW50iAEBEkIKEHBsYWludGV4dENvbnRlbnQYBCABKAsyES5QbGFpbnRleHRDb250ZW'
    '50SAFSEHBsYWludGV4dENvbnRlbnSIAQEidAoEVHlwZRIbChdTRU5ERVJfREVMSVZFUllfUkVD'
    'RUlQVBAAEhUKEVBMQUlOVEVYVF9DT05URU5UEAESDgoKQ0lQSEVSVEVYVBACEhEKDVBSRUtFWV'
    '9CVU5ETEUQAxIVChFURVNUX05PVElGSUNBVElPThAEQhMKEV9lbmNyeXB0ZWRDb250ZW50QhMK'
    'EV9wbGFpbnRleHRDb250ZW50');

@$core.Deprecated('Use plaintextContentDescriptor instead')
const PlaintextContent$json = {
  '1': 'PlaintextContent',
  '2': [
    {
      '1': 'decryptionErrorMessage',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.PlaintextContent.DecryptionErrorMessage',
      '9': 0,
      '10': 'decryptionErrorMessage',
      '17': true
    },
    {
      '1': 'retryControlError',
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
    {'1': '_decryptionErrorMessage'},
    {'1': '_retryControlError'},
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
    'ChBQbGFpbnRleHRDb250ZW50EmUKFmRlY3J5cHRpb25FcnJvck1lc3NhZ2UYASABKAsyKC5QbG'
    'FpbnRleHRDb250ZW50LkRlY3J5cHRpb25FcnJvck1lc3NhZ2VIAFIWZGVjcnlwdGlvbkVycm9y'
    'TWVzc2FnZYgBARJWChFyZXRyeUNvbnRyb2xFcnJvchgCIAEoCzIjLlBsYWludGV4dENvbnRlbn'
    'QuUmV0cnlFcnJvck1lc3NhZ2VIAVIRcmV0cnlDb250cm9sRXJyb3KIAQEaEwoRUmV0cnlFcnJv'
    'ck1lc3NhZ2UahAEKFkRlY3J5cHRpb25FcnJvck1lc3NhZ2USQQoEdHlwZRgBIAEoDjItLlBsYW'
    'ludGV4dENvbnRlbnQuRGVjcnlwdGlvbkVycm9yTWVzc2FnZS5UeXBlUgR0eXBlIicKBFR5cGUS'
    'CwoHVU5LTk9XThAAEhIKDlBSRUtFWV9VTktOT1dOEAFCGQoXX2RlY3J5cHRpb25FcnJvck1lc3'
    'NhZ2VCFAoSX3JldHJ5Q29udHJvbEVycm9y');

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent$json = {
  '1': 'EncryptedContent',
  '2': [
    {
      '1': 'groupId',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'groupId',
      '17': true
    },
    {
      '1': 'isDirectChat',
      '3': 3,
      '4': 1,
      '5': 8,
      '9': 1,
      '10': 'isDirectChat',
      '17': true
    },
    {
      '1': 'senderProfileCounter',
      '3': 4,
      '4': 1,
      '5': 3,
      '9': 2,
      '10': 'senderProfileCounter',
      '17': true
    },
    {
      '1': 'messageUpdate',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.MessageUpdate',
      '9': 3,
      '10': 'messageUpdate',
      '17': true
    },
    {
      '1': 'media',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.Media',
      '9': 4,
      '10': 'media',
      '17': true
    },
    {
      '1': 'mediaUpdate',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.MediaUpdate',
      '9': 5,
      '10': 'mediaUpdate',
      '17': true
    },
    {
      '1': 'contactUpdate',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.ContactUpdate',
      '9': 6,
      '10': 'contactUpdate',
      '17': true
    },
    {
      '1': 'contactRequest',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.ContactRequest',
      '9': 7,
      '10': 'contactRequest',
      '17': true
    },
    {
      '1': 'flameSync',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.FlameSync',
      '9': 8,
      '10': 'flameSync',
      '17': true
    },
    {
      '1': 'pushKeys',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.PushKeys',
      '9': 9,
      '10': 'pushKeys',
      '17': true
    },
    {
      '1': 'reaction',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.Reaction',
      '9': 10,
      '10': 'reaction',
      '17': true
    },
    {
      '1': 'textMessage',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.TextMessage',
      '9': 11,
      '10': 'textMessage',
      '17': true
    },
    {
      '1': 'groupCreate',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.GroupCreate',
      '9': 12,
      '10': 'groupCreate',
      '17': true
    },
    {
      '1': 'groupJoin',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.GroupJoin',
      '9': 13,
      '10': 'groupJoin',
      '17': true
    },
    {
      '1': 'groupUpdate',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.GroupUpdate',
      '9': 14,
      '10': 'groupUpdate',
      '17': true
    },
    {
      '1': 'resendGroupPublicKey',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.ResendGroupPublicKey',
      '9': 15,
      '10': 'resendGroupPublicKey',
      '17': true
    },
    {
      '1': 'error_messages',
      '3': 18,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.ErrorMessages',
      '9': 16,
      '10': 'errorMessages',
      '17': true
    },
    {
      '1': 'additional_data_message',
      '3': 19,
      '4': 1,
      '5': 11,
      '6': '.EncryptedContent.AdditionalDataMessage',
      '9': 17,
      '10': 'additionalDataMessage',
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
    EncryptedContent_FlameSync$json
  ],
  '8': [
    {'1': '_groupId'},
    {'1': '_isDirectChat'},
    {'1': '_senderProfileCounter'},
    {'1': '_messageUpdate'},
    {'1': '_media'},
    {'1': '_mediaUpdate'},
    {'1': '_contactUpdate'},
    {'1': '_contactRequest'},
    {'1': '_flameSync'},
    {'1': '_pushKeys'},
    {'1': '_reaction'},
    {'1': '_textMessage'},
    {'1': '_groupCreate'},
    {'1': '_groupJoin'},
    {'1': '_groupUpdate'},
    {'1': '_resendGroupPublicKey'},
    {'1': '_error_messages'},
    {'1': '_additional_data_message'},
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
  ],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_GroupCreate$json = {
  '1': 'GroupCreate',
  '2': [
    {'1': 'stateKey', '3': 3, '4': 1, '5': 12, '10': 'stateKey'},
    {'1': 'groupPublicKey', '3': 4, '4': 1, '5': 12, '10': 'groupPublicKey'},
  ],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_GroupJoin$json = {
  '1': 'GroupJoin',
  '2': [
    {'1': 'groupPublicKey', '3': 1, '4': 1, '5': 12, '10': 'groupPublicKey'},
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
    {'1': 'groupActionType', '3': 1, '4': 1, '5': 9, '10': 'groupActionType'},
    {
      '1': 'affectedContactId',
      '3': 2,
      '4': 1,
      '5': 3,
      '9': 0,
      '10': 'affectedContactId',
      '17': true
    },
    {
      '1': 'newGroupName',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'newGroupName',
      '17': true
    },
    {
      '1': 'newDeleteMessagesAfterMilliseconds',
      '3': 4,
      '4': 1,
      '5': 3,
      '9': 2,
      '10': 'newDeleteMessagesAfterMilliseconds',
      '17': true
    },
  ],
  '8': [
    {'1': '_affectedContactId'},
    {'1': '_newGroupName'},
    {'1': '_newDeleteMessagesAfterMilliseconds'},
  ],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_TextMessage$json = {
  '1': 'TextMessage',
  '2': [
    {'1': 'senderMessageId', '3': 1, '4': 1, '5': 9, '10': 'senderMessageId'},
    {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
    {'1': 'timestamp', '3': 3, '4': 1, '5': 3, '10': 'timestamp'},
    {
      '1': 'quoteMessageId',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'quoteMessageId',
      '17': true
    },
  ],
  '8': [
    {'1': '_quoteMessageId'},
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
    {'1': 'targetMessageId', '3': 1, '4': 1, '5': 9, '10': 'targetMessageId'},
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
      '1': 'senderMessageId',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'senderMessageId',
      '17': true
    },
    {
      '1': 'multipleTargetMessageIds',
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
    {'1': '_senderMessageId'},
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
    {'1': 'senderMessageId', '3': 1, '4': 1, '5': 9, '10': 'senderMessageId'},
    {
      '1': 'type',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.EncryptedContent.Media.Type',
      '10': 'type'
    },
    {
      '1': 'displayLimitInMilliseconds',
      '3': 3,
      '4': 1,
      '5': 3,
      '9': 0,
      '10': 'displayLimitInMilliseconds',
      '17': true
    },
    {
      '1': 'requiresAuthentication',
      '3': 4,
      '4': 1,
      '5': 8,
      '10': 'requiresAuthentication'
    },
    {'1': 'timestamp', '3': 5, '4': 1, '5': 3, '10': 'timestamp'},
    {
      '1': 'quoteMessageId',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'quoteMessageId',
      '17': true
    },
    {
      '1': 'downloadToken',
      '3': 7,
      '4': 1,
      '5': 12,
      '9': 2,
      '10': 'downloadToken',
      '17': true
    },
    {
      '1': 'encryptionKey',
      '3': 8,
      '4': 1,
      '5': 12,
      '9': 3,
      '10': 'encryptionKey',
      '17': true
    },
    {
      '1': 'encryptionMac',
      '3': 9,
      '4': 1,
      '5': 12,
      '9': 4,
      '10': 'encryptionMac',
      '17': true
    },
    {
      '1': 'encryptionNonce',
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
    {'1': '_displayLimitInMilliseconds'},
    {'1': '_quoteMessageId'},
    {'1': '_downloadToken'},
    {'1': '_encryptionKey'},
    {'1': '_encryptionMac'},
    {'1': '_encryptionNonce'},
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
    {'1': 'targetMessageId', '3': 2, '4': 1, '5': 9, '10': 'targetMessageId'},
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
      '1': 'avatarSvgCompressed',
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
      '1': 'displayName',
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
    {'1': '_avatarSvgCompressed'},
    {'1': '_username'},
    {'1': '_displayName'},
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
    {'1': 'keyId', '3': 2, '4': 1, '5': 3, '9': 0, '10': 'keyId', '17': true},
    {'1': 'key', '3': 3, '4': 1, '5': 12, '9': 1, '10': 'key', '17': true},
    {
      '1': 'createdAt',
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
    {'1': '_keyId'},
    {'1': '_key'},
    {'1': '_createdAt'},
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
    {'1': 'flameCounter', '3': 1, '4': 1, '5': 3, '10': 'flameCounter'},
    {
      '1': 'lastFlameCounterChange',
      '3': 2,
      '4': 1,
      '5': 3,
      '10': 'lastFlameCounterChange'
    },
    {'1': 'bestFriend', '3': 3, '4': 1, '5': 8, '10': 'bestFriend'},
    {'1': 'forceUpdate', '3': 4, '4': 1, '5': 8, '10': 'forceUpdate'},
  ],
};

/// Descriptor for `EncryptedContent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List encryptedContentDescriptor = $convert.base64Decode(
    'ChBFbmNyeXB0ZWRDb250ZW50Eh0KB2dyb3VwSWQYAiABKAlIAFIHZ3JvdXBJZIgBARInCgxpc0'
    'RpcmVjdENoYXQYAyABKAhIAVIMaXNEaXJlY3RDaGF0iAEBEjcKFHNlbmRlclByb2ZpbGVDb3Vu'
    'dGVyGAQgASgDSAJSFHNlbmRlclByb2ZpbGVDb3VudGVyiAEBEkoKDW1lc3NhZ2VVcGRhdGUYBS'
    'ABKAsyHy5FbmNyeXB0ZWRDb250ZW50Lk1lc3NhZ2VVcGRhdGVIA1INbWVzc2FnZVVwZGF0ZYgB'
    'ARIyCgVtZWRpYRgGIAEoCzIXLkVuY3J5cHRlZENvbnRlbnQuTWVkaWFIBFIFbWVkaWGIAQESRA'
    'oLbWVkaWFVcGRhdGUYByABKAsyHS5FbmNyeXB0ZWRDb250ZW50Lk1lZGlhVXBkYXRlSAVSC21l'
    'ZGlhVXBkYXRliAEBEkoKDWNvbnRhY3RVcGRhdGUYCCABKAsyHy5FbmNyeXB0ZWRDb250ZW50Lk'
    'NvbnRhY3RVcGRhdGVIBlINY29udGFjdFVwZGF0ZYgBARJNCg5jb250YWN0UmVxdWVzdBgJIAEo'
    'CzIgLkVuY3J5cHRlZENvbnRlbnQuQ29udGFjdFJlcXVlc3RIB1IOY29udGFjdFJlcXVlc3SIAQ'
    'ESPgoJZmxhbWVTeW5jGAogASgLMhsuRW5jcnlwdGVkQ29udGVudC5GbGFtZVN5bmNICFIJZmxh'
    'bWVTeW5jiAEBEjsKCHB1c2hLZXlzGAsgASgLMhouRW5jcnlwdGVkQ29udGVudC5QdXNoS2V5c0'
    'gJUghwdXNoS2V5c4gBARI7CghyZWFjdGlvbhgMIAEoCzIaLkVuY3J5cHRlZENvbnRlbnQuUmVh'
    'Y3Rpb25IClIIcmVhY3Rpb26IAQESRAoLdGV4dE1lc3NhZ2UYDSABKAsyHS5FbmNyeXB0ZWRDb2'
    '50ZW50LlRleHRNZXNzYWdlSAtSC3RleHRNZXNzYWdliAEBEkQKC2dyb3VwQ3JlYXRlGA4gASgL'
    'Mh0uRW5jcnlwdGVkQ29udGVudC5Hcm91cENyZWF0ZUgMUgtncm91cENyZWF0ZYgBARI+Cglncm'
    '91cEpvaW4YDyABKAsyGy5FbmNyeXB0ZWRDb250ZW50Lkdyb3VwSm9pbkgNUglncm91cEpvaW6I'
    'AQESRAoLZ3JvdXBVcGRhdGUYECABKAsyHS5FbmNyeXB0ZWRDb250ZW50Lkdyb3VwVXBkYXRlSA'
    '5SC2dyb3VwVXBkYXRliAEBEl8KFHJlc2VuZEdyb3VwUHVibGljS2V5GBEgASgLMiYuRW5jcnlw'
    'dGVkQ29udGVudC5SZXNlbmRHcm91cFB1YmxpY0tleUgPUhRyZXNlbmRHcm91cFB1YmxpY0tleY'
    'gBARJLCg5lcnJvcl9tZXNzYWdlcxgSIAEoCzIfLkVuY3J5cHRlZENvbnRlbnQuRXJyb3JNZXNz'
    'YWdlc0gQUg1lcnJvck1lc3NhZ2VziAEBEmQKF2FkZGl0aW9uYWxfZGF0YV9tZXNzYWdlGBMgAS'
    'gLMicuRW5jcnlwdGVkQ29udGVudC5BZGRpdGlvbmFsRGF0YU1lc3NhZ2VIEVIVYWRkaXRpb25h'
    'bERhdGFNZXNzYWdliAEBGtcBCg1FcnJvck1lc3NhZ2VzEjgKBHR5cGUYASABKA4yJC5FbmNyeX'
    'B0ZWRDb250ZW50LkVycm9yTWVzc2FnZXMuVHlwZVIEdHlwZRIsChJyZWxhdGVkX3JlY2VpcHRf'
    'aWQYAiABKAlSEHJlbGF0ZWRSZWNlaXB0SWQiXgoEVHlwZRI8CjhFUlJPUl9QUk9DRVNTSU5HX0'
    '1FU1NBR0VfQ1JFQVRFRF9BQ0NPVU5UX1JFUVVFU1RfSU5TVEVBRBAAEhgKFFVOS05PV05fTUVT'
    'U0FHRV9UWVBFEAIaUQoLR3JvdXBDcmVhdGUSGgoIc3RhdGVLZXkYAyABKAxSCHN0YXRlS2V5Ei'
    'YKDmdyb3VwUHVibGljS2V5GAQgASgMUg5ncm91cFB1YmxpY0tleRozCglHcm91cEpvaW4SJgoO'
    'Z3JvdXBQdWJsaWNLZXkYASABKAxSDmdyb3VwUHVibGljS2V5GhYKFFJlc2VuZEdyb3VwUHVibG'
    'ljS2V5GrYCCgtHcm91cFVwZGF0ZRIoCg9ncm91cEFjdGlvblR5cGUYASABKAlSD2dyb3VwQWN0'
    'aW9uVHlwZRIxChFhZmZlY3RlZENvbnRhY3RJZBgCIAEoA0gAUhFhZmZlY3RlZENvbnRhY3RJZI'
    'gBARInCgxuZXdHcm91cE5hbWUYAyABKAlIAVIMbmV3R3JvdXBOYW1liAEBElMKIm5ld0RlbGV0'
    'ZU1lc3NhZ2VzQWZ0ZXJNaWxsaXNlY29uZHMYBCABKANIAlIibmV3RGVsZXRlTWVzc2FnZXNBZn'
    'Rlck1pbGxpc2Vjb25kc4gBAUIUChJfYWZmZWN0ZWRDb250YWN0SWRCDwoNX25ld0dyb3VwTmFt'
    'ZUIlCiNfbmV3RGVsZXRlTWVzc2FnZXNBZnRlck1pbGxpc2Vjb25kcxqpAQoLVGV4dE1lc3NhZ2'
    'USKAoPc2VuZGVyTWVzc2FnZUlkGAEgASgJUg9zZW5kZXJNZXNzYWdlSWQSEgoEdGV4dBgCIAEo'
    'CVIEdGV4dBIcCgl0aW1lc3RhbXAYAyABKANSCXRpbWVzdGFtcBIrCg5xdW90ZU1lc3NhZ2VJZB'
    'gEIAEoCUgAUg5xdW90ZU1lc3NhZ2VJZIgBAUIRCg9fcXVvdGVNZXNzYWdlSWQazgEKFUFkZGl0'
    'aW9uYWxEYXRhTWVzc2FnZRIqChFzZW5kZXJfbWVzc2FnZV9pZBgBIAEoCVIPc2VuZGVyTWVzc2'
    'FnZUlkEhwKCXRpbWVzdGFtcBgCIAEoA1IJdGltZXN0YW1wEhIKBHR5cGUYAyABKAlSBHR5cGUS'
    'OwoXYWRkaXRpb25hbF9tZXNzYWdlX2RhdGEYBCABKAxIAFIVYWRkaXRpb25hbE1lc3NhZ2VEYX'
    'RhiAEBQhoKGF9hZGRpdGlvbmFsX21lc3NhZ2VfZGF0YRpiCghSZWFjdGlvbhIoCg90YXJnZXRN'
    'ZXNzYWdlSWQYASABKAlSD3RhcmdldE1lc3NhZ2VJZBIUCgVlbW9qaRgCIAEoCVIFZW1vamkSFg'
    'oGcmVtb3ZlGAMgASgIUgZyZW1vdmUatwIKDU1lc3NhZ2VVcGRhdGUSOAoEdHlwZRgBIAEoDjIk'
    'LkVuY3J5cHRlZENvbnRlbnQuTWVzc2FnZVVwZGF0ZS5UeXBlUgR0eXBlEi0KD3NlbmRlck1lc3'
    'NhZ2VJZBgCIAEoCUgAUg9zZW5kZXJNZXNzYWdlSWSIAQESOgoYbXVsdGlwbGVUYXJnZXRNZXNz'
    'YWdlSWRzGAMgAygJUhhtdWx0aXBsZVRhcmdldE1lc3NhZ2VJZHMSFwoEdGV4dBgEIAEoCUgBUg'
    'R0ZXh0iAEBEhwKCXRpbWVzdGFtcBgFIAEoA1IJdGltZXN0YW1wIi0KBFR5cGUSCgoGREVMRVRF'
    'EAASDQoJRURJVF9URVhUEAESCgoGT1BFTkVEEAJCEgoQX3NlbmRlck1lc3NhZ2VJZEIHCgVfdG'
    'V4dBrwBQoFTWVkaWESKAoPc2VuZGVyTWVzc2FnZUlkGAEgASgJUg9zZW5kZXJNZXNzYWdlSWQS'
    'MAoEdHlwZRgCIAEoDjIcLkVuY3J5cHRlZENvbnRlbnQuTWVkaWEuVHlwZVIEdHlwZRJDChpkaX'
    'NwbGF5TGltaXRJbk1pbGxpc2Vjb25kcxgDIAEoA0gAUhpkaXNwbGF5TGltaXRJbk1pbGxpc2Vj'
    'b25kc4gBARI2ChZyZXF1aXJlc0F1dGhlbnRpY2F0aW9uGAQgASgIUhZyZXF1aXJlc0F1dGhlbn'
    'RpY2F0aW9uEhwKCXRpbWVzdGFtcBgFIAEoA1IJdGltZXN0YW1wEisKDnF1b3RlTWVzc2FnZUlk'
    'GAYgASgJSAFSDnF1b3RlTWVzc2FnZUlkiAEBEikKDWRvd25sb2FkVG9rZW4YByABKAxIAlINZG'
    '93bmxvYWRUb2tlbogBARIpCg1lbmNyeXB0aW9uS2V5GAggASgMSANSDWVuY3J5cHRpb25LZXmI'
    'AQESKQoNZW5jcnlwdGlvbk1hYxgJIAEoDEgEUg1lbmNyeXB0aW9uTWFjiAEBEi0KD2VuY3J5cH'
    'Rpb25Ob25jZRgKIAEoDEgFUg9lbmNyeXB0aW9uTm9uY2WIAQESOwoXYWRkaXRpb25hbF9tZXNz'
    'YWdlX2RhdGEYCyABKAxIBlIVYWRkaXRpb25hbE1lc3NhZ2VEYXRhiAEBIj4KBFR5cGUSDAoIUk'
    'VVUExPQUQQABIJCgVJTUFHRRABEgkKBVZJREVPEAISBwoDR0lGEAMSCQoFQVVESU8QBEIdChtf'
    'ZGlzcGxheUxpbWl0SW5NaWxsaXNlY29uZHNCEQoPX3F1b3RlTWVzc2FnZUlkQhAKDl9kb3dubG'
    '9hZFRva2VuQhAKDl9lbmNyeXB0aW9uS2V5QhAKDl9lbmNyeXB0aW9uTWFjQhIKEF9lbmNyeXB0'
    'aW9uTm9uY2VCGgoYX2FkZGl0aW9uYWxfbWVzc2FnZV9kYXRhGqcBCgtNZWRpYVVwZGF0ZRI2Cg'
    'R0eXBlGAEgASgOMiIuRW5jcnlwdGVkQ29udGVudC5NZWRpYVVwZGF0ZS5UeXBlUgR0eXBlEigK'
    'D3RhcmdldE1lc3NhZ2VJZBgCIAEoCVIPdGFyZ2V0TWVzc2FnZUlkIjYKBFR5cGUSDAoIUkVPUE'
    'VORUQQABIKCgZTVE9SRUQQARIUChBERUNSWVBUSU9OX0VSUk9SEAIaeAoOQ29udGFjdFJlcXVl'
    'c3QSOQoEdHlwZRgBIAEoDjIlLkVuY3J5cHRlZENvbnRlbnQuQ29udGFjdFJlcXVlc3QuVHlwZV'
    'IEdHlwZSIrCgRUeXBlEgsKB1JFUVVFU1QQABIKCgZSRUpFQ1QQARIKCgZBQ0NFUFQQAhqeAgoN'
    'Q29udGFjdFVwZGF0ZRI4CgR0eXBlGAEgASgOMiQuRW5jcnlwdGVkQ29udGVudC5Db250YWN0VX'
    'BkYXRlLlR5cGVSBHR5cGUSNQoTYXZhdGFyU3ZnQ29tcHJlc3NlZBgCIAEoDEgAUhNhdmF0YXJT'
    'dmdDb21wcmVzc2VkiAEBEh8KCHVzZXJuYW1lGAMgASgJSAFSCHVzZXJuYW1liAEBEiUKC2Rpc3'
    'BsYXlOYW1lGAQgASgJSAJSC2Rpc3BsYXlOYW1liAEBIh8KBFR5cGUSCwoHUkVRVUVTVBAAEgoK'
    'BlVQREFURRABQhYKFF9hdmF0YXJTdmdDb21wcmVzc2VkQgsKCV91c2VybmFtZUIOCgxfZGlzcG'
    'xheU5hbWUa1QEKCFB1c2hLZXlzEjMKBHR5cGUYASABKA4yHy5FbmNyeXB0ZWRDb250ZW50LlB1'
    'c2hLZXlzLlR5cGVSBHR5cGUSGQoFa2V5SWQYAiABKANIAFIFa2V5SWSIAQESFQoDa2V5GAMgAS'
    'gMSAFSA2tleYgBARIhCgljcmVhdGVkQXQYBCABKANIAlIJY3JlYXRlZEF0iAEBIh8KBFR5cGUS'
    'CwoHUkVRVUVTVBAAEgoKBlVQREFURRABQggKBl9rZXlJZEIGCgRfa2V5QgwKCl9jcmVhdGVkQX'
    'QaqQEKCUZsYW1lU3luYxIiCgxmbGFtZUNvdW50ZXIYASABKANSDGZsYW1lQ291bnRlchI2ChZs'
    'YXN0RmxhbWVDb3VudGVyQ2hhbmdlGAIgASgDUhZsYXN0RmxhbWVDb3VudGVyQ2hhbmdlEh4KCm'
    'Jlc3RGcmllbmQYAyABKAhSCmJlc3RGcmllbmQSIAoLZm9yY2VVcGRhdGUYBCABKAhSC2ZvcmNl'
    'VXBkYXRlQgoKCF9ncm91cElkQg8KDV9pc0RpcmVjdENoYXRCFwoVX3NlbmRlclByb2ZpbGVDb3'
    'VudGVyQhAKDl9tZXNzYWdlVXBkYXRlQggKBl9tZWRpYUIOCgxfbWVkaWFVcGRhdGVCEAoOX2Nv'
    'bnRhY3RVcGRhdGVCEQoPX2NvbnRhY3RSZXF1ZXN0QgwKCl9mbGFtZVN5bmNCCwoJX3B1c2hLZX'
    'lzQgsKCV9yZWFjdGlvbkIOCgxfdGV4dE1lc3NhZ2VCDgoMX2dyb3VwQ3JlYXRlQgwKCl9ncm91'
    'cEpvaW5CDgoMX2dyb3VwVXBkYXRlQhcKFV9yZXNlbmRHcm91cFB1YmxpY0tleUIRCg9fZXJyb3'
    'JfbWVzc2FnZXNCGgoYX2FkZGl0aW9uYWxfZGF0YV9tZXNzYWdl');
