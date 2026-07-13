// This is a generated file - do not edit.
//
// Generated from passwordless_recovery.proto.

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

@$core.Deprecated('Use recoveryRequestDescriptor instead')
const RecoveryRequest$json = {
  '1': 'RecoveryRequest',
  '2': [
    {'1': 'notification_id', '3': 1, '4': 1, '5': 9, '10': 'notificationId'},
    {'1': 'public_key', '3': 2, '4': 1, '5': 12, '10': 'publicKey'},
  ],
};

/// Descriptor for `RecoveryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recoveryRequestDescriptor = $convert.base64Decode(
    'Cg9SZWNvdmVyeVJlcXVlc3QSJwoPbm90aWZpY2F0aW9uX2lkGAEgASgJUg5ub3RpZmljYXRpb2'
    '5JZBIdCgpwdWJsaWNfa2V5GAIgASgMUglwdWJsaWNLZXk=');

@$core.Deprecated('Use encryptedEnvelopeDescriptor instead')
const EncryptedEnvelope$json = {
  '1': 'EncryptedEnvelope',
  '2': [
    {'1': 'encrypted_data', '3': 1, '4': 1, '5': 12, '10': 'encryptedData'},
    {'1': 'iv', '3': 2, '4': 1, '5': 12, '10': 'iv'},
    {'1': 'mac', '3': 3, '4': 1, '5': 12, '10': 'mac'},
  ],
};

/// Descriptor for `EncryptedEnvelope`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List encryptedEnvelopeDescriptor = $convert.base64Decode(
    'ChFFbmNyeXB0ZWRFbnZlbG9wZRIlCg5lbmNyeXB0ZWRfZGF0YRgBIAEoDFINZW5jcnlwdGVkRG'
    'F0YRIOCgJpdhgCIAEoDFICaXYSEAoDbWFjGAMgASgMUgNtYWM=');

@$core.Deprecated('Use trustedFriendShareDescriptor instead')
const TrustedFriendShare$json = {
  '1': 'TrustedFriendShare',
  '2': [
    {
      '1': 'trusted_friend',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.passwordless_recovery.TrustedFriendShare.User',
      '10': 'trustedFriend'
    },
    {
      '1': 'share_user',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.passwordless_recovery.TrustedFriendShare.User',
      '10': 'shareUser'
    },
    {'1': 'threshold', '3': 3, '4': 1, '5': 5, '10': 'threshold'},
    {
      '1': 'shared_secret_data',
      '3': 4,
      '4': 1,
      '5': 12,
      '10': 'sharedSecretData'
    },
  ],
  '3': [TrustedFriendShare_User$json],
};

@$core.Deprecated('Use trustedFriendShareDescriptor instead')
const TrustedFriendShare_User$json = {
  '1': 'User',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 3, '10': 'userId'},
    {'1': 'display_name', '3': 2, '4': 1, '5': 9, '10': 'displayName'},
    {'1': 'avatar', '3': 3, '4': 1, '5': 12, '10': 'avatar'},
  ],
};

/// Descriptor for `TrustedFriendShare`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List trustedFriendShareDescriptor = $convert.base64Decode(
    'ChJUcnVzdGVkRnJpZW5kU2hhcmUSVQoOdHJ1c3RlZF9mcmllbmQYASABKAsyLi5wYXNzd29yZG'
    'xlc3NfcmVjb3ZlcnkuVHJ1c3RlZEZyaWVuZFNoYXJlLlVzZXJSDXRydXN0ZWRGcmllbmQSTQoK'
    'c2hhcmVfdXNlchgCIAEoCzIuLnBhc3N3b3JkbGVzc19yZWNvdmVyeS5UcnVzdGVkRnJpZW5kU2'
    'hhcmUuVXNlclIJc2hhcmVVc2VyEhwKCXRocmVzaG9sZBgDIAEoBVIJdGhyZXNob2xkEiwKEnNo'
    'YXJlZF9zZWNyZXRfZGF0YRgEIAEoDFIQc2hhcmVkU2VjcmV0RGF0YRpaCgRVc2VyEhcKB3VzZX'
    'JfaWQYASABKANSBnVzZXJJZBIhCgxkaXNwbGF5X25hbWUYAiABKAlSC2Rpc3BsYXlOYW1lEhYK'
    'BmF2YXRhchgDIAEoDFIGYXZhdGFy');

@$core.Deprecated('Use recoveryDataDescriptor instead')
const RecoveryData$json = {
  '1': 'RecoveryData',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 3, '10': 'userId'},
    {'1': 'key_manager', '3': 3, '4': 1, '5': 12, '10': 'keyManager'},
  ],
};

/// Descriptor for `RecoveryData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recoveryDataDescriptor = $convert.base64Decode(
    'CgxSZWNvdmVyeURhdGESFwoHdXNlcl9pZBgBIAEoA1IGdXNlcklkEh8KC2tleV9tYW5hZ2VyGA'
    'MgASgMUgprZXlNYW5hZ2Vy');

@$core.Deprecated('Use sharedSecretDataDescriptor instead')
const SharedSecretData$json = {
  '1': 'SharedSecretData',
  '2': [
    {'1': 'recovery_data', '3': 1, '4': 1, '5': 12, '10': 'recoveryData'},
    {
      '1': 'encrypted_server_key_nonce',
      '3': 3,
      '4': 1,
      '5': 12,
      '9': 0,
      '10': 'encryptedServerKeyNonce',
      '17': true
    },
    {
      '1': 'pin_seed',
      '3': 4,
      '4': 1,
      '5': 12,
      '9': 1,
      '10': 'pinSeed',
      '17': true
    },
    {
      '1': 'pin_unlock_token',
      '3': 5,
      '4': 1,
      '5': 12,
      '9': 2,
      '10': 'pinUnlockToken',
      '17': true
    },
    {
      '1': 'email_hint',
      '3': 6,
      '4': 1,
      '5': 9,
      '9': 3,
      '10': 'emailHint',
      '17': true
    },
  ],
  '8': [
    {'1': '_encrypted_server_key_nonce'},
    {'1': '_pin_seed'},
    {'1': '_pin_unlock_token'},
    {'1': '_email_hint'},
  ],
};

/// Descriptor for `SharedSecretData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sharedSecretDataDescriptor = $convert.base64Decode(
    'ChBTaGFyZWRTZWNyZXREYXRhEiMKDXJlY292ZXJ5X2RhdGEYASABKAxSDHJlY292ZXJ5RGF0YR'
    'JAChplbmNyeXB0ZWRfc2VydmVyX2tleV9ub25jZRgDIAEoDEgAUhdlbmNyeXB0ZWRTZXJ2ZXJL'
    'ZXlOb25jZYgBARIeCghwaW5fc2VlZBgEIAEoDEgBUgdwaW5TZWVkiAEBEi0KEHBpbl91bmxvY2'
    'tfdG9rZW4YBSABKAxIAlIOcGluVW5sb2NrVG9rZW6IAQESIgoKZW1haWxfaGludBgGIAEoCUgD'
    'UgllbWFpbEhpbnSIAQFCHQobX2VuY3J5cHRlZF9zZXJ2ZXJfa2V5X25vbmNlQgsKCV9waW5fc2'
    'VlZEITChFfcGluX3VubG9ja190b2tlbkINCgtfZW1haWxfaGludA==');
