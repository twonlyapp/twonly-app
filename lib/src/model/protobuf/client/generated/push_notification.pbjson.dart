// This is a generated file - do not edit.
//
// Generated from push_notification.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use pushKindDescriptor instead')
const PushKind$json = {
  '1': 'PushKind',
  '2': [
    {'1': 'REACTION', '2': 0},
    {'1': 'RESPONSE', '2': 1},
    {'1': 'TEXT', '2': 2},
    {'1': 'VIDEO', '2': 3},
    {'1': 'TWONLY', '2': 4},
    {'1': 'IMAGE', '2': 5},
    {'1': 'CONTACT_REQUEST', '2': 6},
    {'1': 'ACCEPT_REQUEST', '2': 7},
    {'1': 'STORED_MEDIA_FILE', '2': 8},
    {'1': 'TEST_NOTIFICATION', '2': 9},
    {'1': 'REOPENED_MEDIA', '2': 10},
    {'1': 'REACTION_TO_VIDEO', '2': 11},
    {'1': 'REACTION_TO_TEXT', '2': 12},
    {'1': 'REACTION_TO_IMAGE', '2': 13},
    {'1': 'REACTION_TO_AUDIO', '2': 14},
    {'1': 'ADDED_TO_GROUP', '2': 15},
    {'1': 'AUDIO', '2': 16},
  ],
};

/// Descriptor for `PushKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List pushKindDescriptor = $convert.base64Decode(
    'CghQdXNoS2luZBIMCghSRUFDVElPThAAEgwKCFJFU1BPTlNFEAESCAoEVEVYVBACEgkKBVZJRE'
    'VPEAMSCgoGVFdPTkxZEAQSCQoFSU1BR0UQBRITCg9DT05UQUNUX1JFUVVFU1QQBhISCg5BQ0NF'
    'UFRfUkVRVUVTVBAHEhUKEVNUT1JFRF9NRURJQV9GSUxFEAgSFQoRVEVTVF9OT1RJRklDQVRJT0'
    '4QCRISCg5SRU9QRU5FRF9NRURJQRAKEhUKEVJFQUNUSU9OX1RPX1ZJREVPEAsSFAoQUkVBQ1RJ'
    'T05fVE9fVEVYVBAMEhUKEVJFQUNUSU9OX1RPX0lNQUdFEA0SFQoRUkVBQ1RJT05fVE9fQVVESU'
    '8QDhISCg5BRERFRF9UT19HUk9VUBAPEgkKBUFVRElPEBA=');

@$core.Deprecated('Use encryptedPushNotificationDescriptor instead')
const EncryptedPushNotification$json = {
  '1': 'EncryptedPushNotification',
  '2': [
    {'1': 'key_id', '3': 1, '4': 1, '5': 3, '10': 'keyId'},
    {'1': 'nonce', '3': 2, '4': 1, '5': 12, '10': 'nonce'},
    {'1': 'ciphertext', '3': 3, '4': 1, '5': 12, '10': 'ciphertext'},
    {'1': 'mac', '3': 4, '4': 1, '5': 12, '10': 'mac'},
  ],
};

/// Descriptor for `EncryptedPushNotification`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List encryptedPushNotificationDescriptor = $convert.base64Decode(
    'ChlFbmNyeXB0ZWRQdXNoTm90aWZpY2F0aW9uEhUKBmtleV9pZBgBIAEoA1IFa2V5SWQSFAoFbm'
    '9uY2UYAiABKAxSBW5vbmNlEh4KCmNpcGhlcnRleHQYAyABKAxSCmNpcGhlcnRleHQSEAoDbWFj'
    'GAQgASgMUgNtYWM=');

@$core.Deprecated('Use pushNotificationDescriptor instead')
const PushNotification$json = {
  '1': 'PushNotification',
  '2': [
    {'1': 'kind', '3': 1, '4': 1, '5': 14, '6': '.PushKind', '10': 'kind'},
    {
      '1': 'message_id',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'messageId',
      '17': true
    },
    {
      '1': 'additional_content',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 1,
      '10': 'additionalContent',
      '17': true
    },
  ],
  '8': [
    {'1': '_message_id'},
    {'1': '_additional_content'},
  ],
};

/// Descriptor for `PushNotification`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pushNotificationDescriptor = $convert.base64Decode(
    'ChBQdXNoTm90aWZpY2F0aW9uEh0KBGtpbmQYASABKA4yCS5QdXNoS2luZFIEa2luZBIiCgptZX'
    'NzYWdlX2lkGAIgASgJSABSCW1lc3NhZ2VJZIgBARIyChJhZGRpdGlvbmFsX2NvbnRlbnQYAyAB'
    'KAlIAVIRYWRkaXRpb25hbENvbnRlbnSIAQFCDQoLX21lc3NhZ2VfaWRCFQoTX2FkZGl0aW9uYW'
    'xfY29udGVudA==');

@$core.Deprecated('Use pushUsersDescriptor instead')
const PushUsers$json = {
  '1': 'PushUsers',
  '2': [
    {'1': 'users', '3': 1, '4': 3, '5': 11, '6': '.PushUser', '10': 'users'},
  ],
};

/// Descriptor for `PushUsers`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pushUsersDescriptor = $convert.base64Decode(
    'CglQdXNoVXNlcnMSHwoFdXNlcnMYASADKAsyCS5QdXNoVXNlclIFdXNlcnM=');

@$core.Deprecated('Use pushUserDescriptor instead')
const PushUser$json = {
  '1': 'PushUser',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 3, '10': 'userId'},
    {'1': 'display_name', '3': 2, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'blocked', '3': 3, '4': 1, '5': 8, '10': 'blocked'},
    {
      '1': 'last_message_id',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'lastMessageId',
      '17': true
    },
    {
      '1': 'push_keys',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.PushKey',
      '10': 'pushKeys'
    },
  ],
  '8': [
    {'1': '_last_message_id'},
  ],
};

/// Descriptor for `PushUser`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pushUserDescriptor = $convert.base64Decode(
    'CghQdXNoVXNlchIXCgd1c2VyX2lkGAEgASgDUgZ1c2VySWQSIQoMZGlzcGxheV9uYW1lGAIgAS'
    'gJUgtkaXNwbGF5TmFtZRIYCgdibG9ja2VkGAMgASgIUgdibG9ja2VkEisKD2xhc3RfbWVzc2Fn'
    'ZV9pZBgEIAEoCUgAUg1sYXN0TWVzc2FnZUlkiAEBEiUKCXB1c2hfa2V5cxgFIAMoCzIILlB1c2'
    'hLZXlSCHB1c2hLZXlzQhIKEF9sYXN0X21lc3NhZ2VfaWQ=');

@$core.Deprecated('Use pushKeyDescriptor instead')
const PushKey$json = {
  '1': 'PushKey',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'key', '3': 2, '4': 1, '5': 12, '10': 'key'},
    {
      '1': 'created_at_unix_timestamp',
      '3': 3,
      '4': 1,
      '5': 3,
      '10': 'createdAtUnixTimestamp'
    },
  ],
};

/// Descriptor for `PushKey`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pushKeyDescriptor = $convert.base64Decode(
    'CgdQdXNoS2V5Eg4KAmlkGAEgASgDUgJpZBIQCgNrZXkYAiABKAxSA2tleRI5ChljcmVhdGVkX2'
    'F0X3VuaXhfdGltZXN0YW1wGAMgASgDUhZjcmVhdGVkQXRVbml4VGltZXN0YW1w');
