//
//  Generated code. Do not modify.
//  source: push_notification.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use pushKindDescriptor instead')
const PushKind$json = {
  '1': 'PushKind',
  '2': [
    {'1': 'reaction', '2': 0},
    {'1': 'response', '2': 1},
    {'1': 'text', '2': 2},
    {'1': 'video', '2': 3},
    {'1': 'twonly', '2': 4},
    {'1': 'image', '2': 5},
    {'1': 'contactRequest', '2': 6},
    {'1': 'acceptRequest', '2': 7},
    {'1': 'storedMediaFile', '2': 8},
    {'1': 'testNotification', '2': 9},
    {'1': 'reopenedMedia', '2': 10},
    {'1': 'reactionToVideo', '2': 11},
    {'1': 'reactionToText', '2': 12},
    {'1': 'reactionToImage', '2': 13},
    {'1': 'addedToGroup', '2': 14},
  ],
};

/// Descriptor for `PushKind`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List pushKindDescriptor = $convert.base64Decode(
    'CghQdXNoS2luZBIMCghyZWFjdGlvbhAAEgwKCHJlc3BvbnNlEAESCAoEdGV4dBACEgkKBXZpZG'
    'VvEAMSCgoGdHdvbmx5EAQSCQoFaW1hZ2UQBRISCg5jb250YWN0UmVxdWVzdBAGEhEKDWFjY2Vw'
    'dFJlcXVlc3QQBxITCg9zdG9yZWRNZWRpYUZpbGUQCBIUChB0ZXN0Tm90aWZpY2F0aW9uEAkSEQ'
    'oNcmVvcGVuZWRNZWRpYRAKEhMKD3JlYWN0aW9uVG9WaWRlbxALEhIKDnJlYWN0aW9uVG9UZXh0'
    'EAwSEwoPcmVhY3Rpb25Ub0ltYWdlEA0SEAoMYWRkZWRUb0dyb3VwEA4=');

@$core.Deprecated('Use encryptedPushNotificationDescriptor instead')
const EncryptedPushNotification$json = {
  '1': 'EncryptedPushNotification',
  '2': [
    {'1': 'keyId', '3': 1, '4': 1, '5': 3, '10': 'keyId'},
    {'1': 'nonce', '3': 2, '4': 1, '5': 12, '10': 'nonce'},
    {'1': 'ciphertext', '3': 3, '4': 1, '5': 12, '10': 'ciphertext'},
    {'1': 'mac', '3': 4, '4': 1, '5': 12, '10': 'mac'},
  ],
};

/// Descriptor for `EncryptedPushNotification`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List encryptedPushNotificationDescriptor = $convert.base64Decode(
    'ChlFbmNyeXB0ZWRQdXNoTm90aWZpY2F0aW9uEhQKBWtleUlkGAEgASgDUgVrZXlJZBIUCgVub2'
    '5jZRgCIAEoDFIFbm9uY2USHgoKY2lwaGVydGV4dBgDIAEoDFIKY2lwaGVydGV4dBIQCgNtYWMY'
    'BCABKAxSA21hYw==');

@$core.Deprecated('Use pushNotificationDescriptor instead')
const PushNotification$json = {
  '1': 'PushNotification',
  '2': [
    {'1': 'kind', '3': 1, '4': 1, '5': 14, '6': '.PushKind', '10': 'kind'},
    {'1': 'messageId', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'messageId', '17': true},
    {'1': 'additionalContent', '3': 3, '4': 1, '5': 9, '9': 1, '10': 'additionalContent', '17': true},
  ],
  '8': [
    {'1': '_messageId'},
    {'1': '_additionalContent'},
  ],
};

/// Descriptor for `PushNotification`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pushNotificationDescriptor = $convert.base64Decode(
    'ChBQdXNoTm90aWZpY2F0aW9uEh0KBGtpbmQYASABKA4yCS5QdXNoS2luZFIEa2luZBIhCgltZX'
    'NzYWdlSWQYAiABKAlIAFIJbWVzc2FnZUlkiAEBEjEKEWFkZGl0aW9uYWxDb250ZW50GAMgASgJ'
    'SAFSEWFkZGl0aW9uYWxDb250ZW50iAEBQgwKCl9tZXNzYWdlSWRCFAoSX2FkZGl0aW9uYWxDb2'
    '50ZW50');

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
    {'1': 'userId', '3': 1, '4': 1, '5': 3, '10': 'userId'},
    {'1': 'displayName', '3': 2, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'blocked', '3': 3, '4': 1, '5': 8, '10': 'blocked'},
    {'1': 'lastMessageId', '3': 4, '4': 1, '5': 9, '9': 0, '10': 'lastMessageId', '17': true},
    {'1': 'pushKeys', '3': 5, '4': 3, '5': 11, '6': '.PushKey', '10': 'pushKeys'},
  ],
  '8': [
    {'1': '_lastMessageId'},
  ],
};

/// Descriptor for `PushUser`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pushUserDescriptor = $convert.base64Decode(
    'CghQdXNoVXNlchIWCgZ1c2VySWQYASABKANSBnVzZXJJZBIgCgtkaXNwbGF5TmFtZRgCIAEoCV'
    'ILZGlzcGxheU5hbWUSGAoHYmxvY2tlZBgDIAEoCFIHYmxvY2tlZBIpCg1sYXN0TWVzc2FnZUlk'
    'GAQgASgJSABSDWxhc3RNZXNzYWdlSWSIAQESJAoIcHVzaEtleXMYBSADKAsyCC5QdXNoS2V5Ug'
    'hwdXNoS2V5c0IQCg5fbGFzdE1lc3NhZ2VJZA==');

@$core.Deprecated('Use pushKeyDescriptor instead')
const PushKey$json = {
  '1': 'PushKey',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'key', '3': 2, '4': 1, '5': 12, '10': 'key'},
    {'1': 'createdAtUnixTimestamp', '3': 3, '4': 1, '5': 3, '10': 'createdAtUnixTimestamp'},
  ],
};

/// Descriptor for `PushKey`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pushKeyDescriptor = $convert.base64Decode(
    'CgdQdXNoS2V5Eg4KAmlkGAEgASgDUgJpZBIQCgNrZXkYAiABKAxSA2tleRI2ChZjcmVhdGVkQX'
    'RVbml4VGltZXN0YW1wGAMgASgDUhZjcmVhdGVkQXRVbml4VGltZXN0YW1w');

