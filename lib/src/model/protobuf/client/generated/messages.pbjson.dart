//
//  Generated code. Do not modify.
//  source: messages.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use messageDescriptor instead')
const Message$json = {
  '1': 'Message',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 14, '6': '.Message.Type', '10': 'type'},
    {'1': 'receiptId', '3': 2, '4': 1, '5': 9, '10': 'receiptId'},
    {'1': 'encryptedContent', '3': 3, '4': 1, '5': 12, '9': 0, '10': 'encryptedContent', '17': true},
    {'1': 'plaintextContent', '3': 4, '4': 1, '5': 11, '6': '.PlaintextContent', '9': 1, '10': 'plaintextContent', '17': true},
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
    {'1': 'decryptionErrorMessage', '3': 1, '4': 1, '5': 11, '6': '.PlaintextContent.DecryptionErrorMessage', '9': 0, '10': 'decryptionErrorMessage', '17': true},
    {'1': 'retryControlError', '3': 2, '4': 1, '5': 11, '6': '.PlaintextContent.RetryErrorMessage', '9': 1, '10': 'retryControlError', '17': true},
  ],
  '3': [PlaintextContent_RetryErrorMessage$json, PlaintextContent_DecryptionErrorMessage$json],
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
    {'1': 'type', '3': 1, '4': 1, '5': 14, '6': '.PlaintextContent.DecryptionErrorMessage.Type', '10': 'type'},
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
    {'1': 'groupId', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'groupId', '17': true},
    {'1': 'isDirectChat', '3': 3, '4': 1, '5': 8, '9': 1, '10': 'isDirectChat', '17': true},
    {'1': 'senderProfileCounter', '3': 4, '4': 1, '5': 3, '9': 2, '10': 'senderProfileCounter', '17': true},
    {'1': 'messageUpdate', '3': 5, '4': 1, '5': 11, '6': '.EncryptedContent.MessageUpdate', '9': 3, '10': 'messageUpdate', '17': true},
    {'1': 'media', '3': 6, '4': 1, '5': 11, '6': '.EncryptedContent.Media', '9': 4, '10': 'media', '17': true},
    {'1': 'mediaUpdate', '3': 7, '4': 1, '5': 11, '6': '.EncryptedContent.MediaUpdate', '9': 5, '10': 'mediaUpdate', '17': true},
    {'1': 'contactUpdate', '3': 8, '4': 1, '5': 11, '6': '.EncryptedContent.ContactUpdate', '9': 6, '10': 'contactUpdate', '17': true},
    {'1': 'contactRequest', '3': 9, '4': 1, '5': 11, '6': '.EncryptedContent.ContactRequest', '9': 7, '10': 'contactRequest', '17': true},
    {'1': 'flameSync', '3': 10, '4': 1, '5': 11, '6': '.EncryptedContent.FlameSync', '9': 8, '10': 'flameSync', '17': true},
    {'1': 'pushKeys', '3': 11, '4': 1, '5': 11, '6': '.EncryptedContent.PushKeys', '9': 9, '10': 'pushKeys', '17': true},
    {'1': 'reaction', '3': 12, '4': 1, '5': 11, '6': '.EncryptedContent.Reaction', '9': 10, '10': 'reaction', '17': true},
    {'1': 'textMessage', '3': 13, '4': 1, '5': 11, '6': '.EncryptedContent.TextMessage', '9': 11, '10': 'textMessage', '17': true},
    {'1': 'groupCreate', '3': 14, '4': 1, '5': 11, '6': '.EncryptedContent.GroupCreate', '9': 12, '10': 'groupCreate', '17': true},
    {'1': 'groupJoin', '3': 15, '4': 1, '5': 11, '6': '.EncryptedContent.GroupJoin', '9': 13, '10': 'groupJoin', '17': true},
    {'1': 'groupUpdate', '3': 16, '4': 1, '5': 11, '6': '.EncryptedContent.GroupUpdate', '9': 14, '10': 'groupUpdate', '17': true},
    {'1': 'resendGroupPublicKey', '3': 17, '4': 1, '5': 11, '6': '.EncryptedContent.ResendGroupPublicKey', '9': 15, '10': 'resendGroupPublicKey', '17': true},
  ],
  '3': [EncryptedContent_GroupCreate$json, EncryptedContent_GroupJoin$json, EncryptedContent_ResendGroupPublicKey$json, EncryptedContent_GroupUpdate$json, EncryptedContent_TextMessage$json, EncryptedContent_Reaction$json, EncryptedContent_MessageUpdate$json, EncryptedContent_Media$json, EncryptedContent_MediaUpdate$json, EncryptedContent_ContactRequest$json, EncryptedContent_ContactUpdate$json, EncryptedContent_PushKeys$json, EncryptedContent_FlameSync$json],
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
    {'1': 'affectedContactId', '3': 2, '4': 1, '5': 3, '9': 0, '10': 'affectedContactId', '17': true},
    {'1': 'newGroupName', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'newGroupName', '17': true},
  ],
  '8': [
    {'1': '_affectedContactId'},
    {'1': '_newGroupName'},
  ],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_TextMessage$json = {
  '1': 'TextMessage',
  '2': [
    {'1': 'senderMessageId', '3': 1, '4': 1, '5': 9, '10': 'senderMessageId'},
    {'1': 'text', '3': 2, '4': 1, '5': 9, '10': 'text'},
    {'1': 'timestamp', '3': 3, '4': 1, '5': 3, '10': 'timestamp'},
    {'1': 'quoteMessageId', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'quoteMessageId', '17': true},
  ],
  '8': [
    {'1': '_quoteMessageId'},
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
    {'1': 'type', '3': 1, '4': 1, '5': 14, '6': '.EncryptedContent.MessageUpdate.Type', '10': 'type'},
    {'1': 'senderMessageId', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'senderMessageId', '17': true},
    {'1': 'multipleTargetMessageIds', '3': 3, '4': 3, '5': 9, '10': 'multipleTargetMessageIds'},
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
    {'1': 'type', '3': 2, '4': 1, '5': 14, '6': '.EncryptedContent.Media.Type', '10': 'type'},
    {'1': 'displayLimitInMilliseconds', '3': 3, '4': 1, '5': 3, '9': 0, '10': 'displayLimitInMilliseconds', '17': true},
    {'1': 'requiresAuthentication', '3': 4, '4': 1, '5': 8, '10': 'requiresAuthentication'},
    {'1': 'timestamp', '3': 5, '4': 1, '5': 3, '10': 'timestamp'},
    {'1': 'quoteMessageId', '3': 6, '4': 1, '5': 9, '9': 1, '10': 'quoteMessageId', '17': true},
    {'1': 'downloadToken', '3': 7, '4': 1, '5': 12, '9': 2, '10': 'downloadToken', '17': true},
    {'1': 'encryptionKey', '3': 8, '4': 1, '5': 12, '9': 3, '10': 'encryptionKey', '17': true},
    {'1': 'encryptionMac', '3': 9, '4': 1, '5': 12, '9': 4, '10': 'encryptionMac', '17': true},
    {'1': 'encryptionNonce', '3': 10, '4': 1, '5': 12, '9': 5, '10': 'encryptionNonce', '17': true},
  ],
  '4': [EncryptedContent_Media_Type$json],
  '8': [
    {'1': '_displayLimitInMilliseconds'},
    {'1': '_quoteMessageId'},
    {'1': '_downloadToken'},
    {'1': '_encryptionKey'},
    {'1': '_encryptionMac'},
    {'1': '_encryptionNonce'},
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
  ],
};

@$core.Deprecated('Use encryptedContentDescriptor instead')
const EncryptedContent_MediaUpdate$json = {
  '1': 'MediaUpdate',
  '2': [
    {'1': 'type', '3': 1, '4': 1, '5': 14, '6': '.EncryptedContent.MediaUpdate.Type', '10': 'type'},
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
    {'1': 'type', '3': 1, '4': 1, '5': 14, '6': '.EncryptedContent.ContactRequest.Type', '10': 'type'},
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
    {'1': 'type', '3': 1, '4': 1, '5': 14, '6': '.EncryptedContent.ContactUpdate.Type', '10': 'type'},
    {'1': 'avatarSvgCompressed', '3': 2, '4': 1, '5': 12, '9': 0, '10': 'avatarSvgCompressed', '17': true},
    {'1': 'username', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'username', '17': true},
    {'1': 'displayName', '3': 4, '4': 1, '5': 9, '9': 2, '10': 'displayName', '17': true},
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
    {'1': 'type', '3': 1, '4': 1, '5': 14, '6': '.EncryptedContent.PushKeys.Type', '10': 'type'},
    {'1': 'keyId', '3': 2, '4': 1, '5': 3, '9': 0, '10': 'keyId', '17': true},
    {'1': 'key', '3': 3, '4': 1, '5': 12, '9': 1, '10': 'key', '17': true},
    {'1': 'createdAt', '3': 4, '4': 1, '5': 3, '9': 2, '10': 'createdAt', '17': true},
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
    {'1': 'lastFlameCounterChange', '3': 2, '4': 1, '5': 3, '10': 'lastFlameCounterChange'},
    {'1': 'bestFriend', '3': 3, '4': 1, '5': 8, '10': 'bestFriend'},
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
    'gBARpRCgtHcm91cENyZWF0ZRIaCghzdGF0ZUtleRgDIAEoDFIIc3RhdGVLZXkSJgoOZ3JvdXBQ'
    'dWJsaWNLZXkYBCABKAxSDmdyb3VwUHVibGljS2V5GjMKCUdyb3VwSm9pbhImCg5ncm91cFB1Ym'
    'xpY0tleRgBIAEoDFIOZ3JvdXBQdWJsaWNLZXkaFgoUUmVzZW5kR3JvdXBQdWJsaWNLZXkaugEK'
    'C0dyb3VwVXBkYXRlEigKD2dyb3VwQWN0aW9uVHlwZRgBIAEoCVIPZ3JvdXBBY3Rpb25UeXBlEj'
    'EKEWFmZmVjdGVkQ29udGFjdElkGAIgASgDSABSEWFmZmVjdGVkQ29udGFjdElkiAEBEicKDG5l'
    'd0dyb3VwTmFtZRgDIAEoCUgBUgxuZXdHcm91cE5hbWWIAQFCFAoSX2FmZmVjdGVkQ29udGFjdE'
    'lkQg8KDV9uZXdHcm91cE5hbWUaqQEKC1RleHRNZXNzYWdlEigKD3NlbmRlck1lc3NhZ2VJZBgB'
    'IAEoCVIPc2VuZGVyTWVzc2FnZUlkEhIKBHRleHQYAiABKAlSBHRleHQSHAoJdGltZXN0YW1wGA'
    'MgASgDUgl0aW1lc3RhbXASKwoOcXVvdGVNZXNzYWdlSWQYBCABKAlIAFIOcXVvdGVNZXNzYWdl'
    'SWSIAQFCEQoPX3F1b3RlTWVzc2FnZUlkGmIKCFJlYWN0aW9uEigKD3RhcmdldE1lc3NhZ2VJZB'
    'gBIAEoCVIPdGFyZ2V0TWVzc2FnZUlkEhQKBWVtb2ppGAIgASgJUgVlbW9qaRIWCgZyZW1vdmUY'
    'AyABKAhSBnJlbW92ZRq3AgoNTWVzc2FnZVVwZGF0ZRI4CgR0eXBlGAEgASgOMiQuRW5jcnlwdG'
    'VkQ29udGVudC5NZXNzYWdlVXBkYXRlLlR5cGVSBHR5cGUSLQoPc2VuZGVyTWVzc2FnZUlkGAIg'
    'ASgJSABSD3NlbmRlck1lc3NhZ2VJZIgBARI6ChhtdWx0aXBsZVRhcmdldE1lc3NhZ2VJZHMYAy'
    'ADKAlSGG11bHRpcGxlVGFyZ2V0TWVzc2FnZUlkcxIXCgR0ZXh0GAQgASgJSAFSBHRleHSIAQES'
    'HAoJdGltZXN0YW1wGAUgASgDUgl0aW1lc3RhbXAiLQoEVHlwZRIKCgZERUxFVEUQABINCglFRE'
    'lUX1RFWFQQARIKCgZPUEVORUQQAkISChBfc2VuZGVyTWVzc2FnZUlkQgcKBV90ZXh0GowFCgVN'
    'ZWRpYRIoCg9zZW5kZXJNZXNzYWdlSWQYASABKAlSD3NlbmRlck1lc3NhZ2VJZBIwCgR0eXBlGA'
    'IgASgOMhwuRW5jcnlwdGVkQ29udGVudC5NZWRpYS5UeXBlUgR0eXBlEkMKGmRpc3BsYXlMaW1p'
    'dEluTWlsbGlzZWNvbmRzGAMgASgDSABSGmRpc3BsYXlMaW1pdEluTWlsbGlzZWNvbmRziAEBEj'
    'YKFnJlcXVpcmVzQXV0aGVudGljYXRpb24YBCABKAhSFnJlcXVpcmVzQXV0aGVudGljYXRpb24S'
    'HAoJdGltZXN0YW1wGAUgASgDUgl0aW1lc3RhbXASKwoOcXVvdGVNZXNzYWdlSWQYBiABKAlIAV'
    'IOcXVvdGVNZXNzYWdlSWSIAQESKQoNZG93bmxvYWRUb2tlbhgHIAEoDEgCUg1kb3dubG9hZFRv'
    'a2VuiAEBEikKDWVuY3J5cHRpb25LZXkYCCABKAxIA1INZW5jcnlwdGlvbktleYgBARIpCg1lbm'
    'NyeXB0aW9uTWFjGAkgASgMSARSDWVuY3J5cHRpb25NYWOIAQESLQoPZW5jcnlwdGlvbk5vbmNl'
    'GAogASgMSAVSD2VuY3J5cHRpb25Ob25jZYgBASIzCgRUeXBlEgwKCFJFVVBMT0FEEAASCQoFSU'
    '1BR0UQARIJCgVWSURFTxACEgcKA0dJRhADQh0KG19kaXNwbGF5TGltaXRJbk1pbGxpc2Vjb25k'
    'c0IRCg9fcXVvdGVNZXNzYWdlSWRCEAoOX2Rvd25sb2FkVG9rZW5CEAoOX2VuY3J5cHRpb25LZX'
    'lCEAoOX2VuY3J5cHRpb25NYWNCEgoQX2VuY3J5cHRpb25Ob25jZRqnAQoLTWVkaWFVcGRhdGUS'
    'NgoEdHlwZRgBIAEoDjIiLkVuY3J5cHRlZENvbnRlbnQuTWVkaWFVcGRhdGUuVHlwZVIEdHlwZR'
    'IoCg90YXJnZXRNZXNzYWdlSWQYAiABKAlSD3RhcmdldE1lc3NhZ2VJZCI2CgRUeXBlEgwKCFJF'
    'T1BFTkVEEAASCgoGU1RPUkVEEAESFAoQREVDUllQVElPTl9FUlJPUhACGngKDkNvbnRhY3RSZX'
    'F1ZXN0EjkKBHR5cGUYASABKA4yJS5FbmNyeXB0ZWRDb250ZW50LkNvbnRhY3RSZXF1ZXN0LlR5'
    'cGVSBHR5cGUiKwoEVHlwZRILCgdSRVFVRVNUEAASCgoGUkVKRUNUEAESCgoGQUNDRVBUEAIang'
    'IKDUNvbnRhY3RVcGRhdGUSOAoEdHlwZRgBIAEoDjIkLkVuY3J5cHRlZENvbnRlbnQuQ29udGFj'
    'dFVwZGF0ZS5UeXBlUgR0eXBlEjUKE2F2YXRhclN2Z0NvbXByZXNzZWQYAiABKAxIAFITYXZhdG'
    'FyU3ZnQ29tcHJlc3NlZIgBARIfCgh1c2VybmFtZRgDIAEoCUgBUgh1c2VybmFtZYgBARIlCgtk'
    'aXNwbGF5TmFtZRgEIAEoCUgCUgtkaXNwbGF5TmFtZYgBASIfCgRUeXBlEgsKB1JFUVVFU1QQAB'
    'IKCgZVUERBVEUQAUIWChRfYXZhdGFyU3ZnQ29tcHJlc3NlZEILCglfdXNlcm5hbWVCDgoMX2Rp'
    'c3BsYXlOYW1lGtUBCghQdXNoS2V5cxIzCgR0eXBlGAEgASgOMh8uRW5jcnlwdGVkQ29udGVudC'
    '5QdXNoS2V5cy5UeXBlUgR0eXBlEhkKBWtleUlkGAIgASgDSABSBWtleUlkiAEBEhUKA2tleRgD'
    'IAEoDEgBUgNrZXmIAQESIQoJY3JlYXRlZEF0GAQgASgDSAJSCWNyZWF0ZWRBdIgBASIfCgRUeX'
    'BlEgsKB1JFUVVFU1QQABIKCgZVUERBVEUQAUIICgZfa2V5SWRCBgoEX2tleUIMCgpfY3JlYXRl'
    'ZEF0GocBCglGbGFtZVN5bmMSIgoMZmxhbWVDb3VudGVyGAEgASgDUgxmbGFtZUNvdW50ZXISNg'
    'oWbGFzdEZsYW1lQ291bnRlckNoYW5nZRgCIAEoA1IWbGFzdEZsYW1lQ291bnRlckNoYW5nZRIe'
    'CgpiZXN0RnJpZW5kGAMgASgIUgpiZXN0RnJpZW5kQgoKCF9ncm91cElkQg8KDV9pc0RpcmVjdE'
    'NoYXRCFwoVX3NlbmRlclByb2ZpbGVDb3VudGVyQhAKDl9tZXNzYWdlVXBkYXRlQggKBl9tZWRp'
    'YUIOCgxfbWVkaWFVcGRhdGVCEAoOX2NvbnRhY3RVcGRhdGVCEQoPX2NvbnRhY3RSZXF1ZXN0Qg'
    'wKCl9mbGFtZVN5bmNCCwoJX3B1c2hLZXlzQgsKCV9yZWFjdGlvbkIOCgxfdGV4dE1lc3NhZ2VC'
    'DgoMX2dyb3VwQ3JlYXRlQgwKCl9ncm91cEpvaW5CDgoMX2dyb3VwVXBkYXRlQhcKFV9yZXNlbm'
    'RHcm91cFB1YmxpY0tleQ==');

