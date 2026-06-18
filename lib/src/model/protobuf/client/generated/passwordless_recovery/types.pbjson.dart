// This is a generated file - do not edit.
//
// Generated from types.proto.

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
    {'1': 'temp_id', '3': 1, '4': 1, '5': 3, '10': 'tempId'},
    {'1': 'public_key', '3': 2, '4': 1, '5': 12, '10': 'publicKey'},
  ],
};

/// Descriptor for `RecoveryRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List recoveryRequestDescriptor = $convert.base64Decode(
    'Cg9SZWNvdmVyeVJlcXVlc3QSFwoHdGVtcF9pZBgBIAEoA1IGdGVtcElkEh0KCnB1YmxpY19rZX'
    'kYAiABKAxSCXB1YmxpY0tleQ==');

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

@$core.Deprecated('Use sharedSecretDataDescriptor instead')
const SharedSecretData$json = {
  '1': 'SharedSecretData',
  '2': [
    {
      '1': 'recovery_data',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.passwordless_recovery.RecoveryData',
      '9': 0,
      '10': 'recoveryData',
      '17': true
    },
    {
      '1': 'second_factor_mail',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.passwordless_recovery.SharedSecretData.SecondFactorMail',
      '9': 1,
      '10': 'secondFactorMail',
      '17': true
    },
    {
      '1': 'second_factor_pin',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.passwordless_recovery.SharedSecretData.SecondFactorPin',
      '9': 2,
      '10': 'secondFactorPin',
      '17': true
    },
    {
      '1': 'recovery_data_encrypted',
      '3': 4,
      '4': 1,
      '5': 12,
      '9': 3,
      '10': 'recoveryDataEncrypted',
      '17': true
    },
  ],
  '3': [
    SharedSecretData_SecondFactorPin$json,
    SharedSecretData_SecondFactorMail$json
  ],
  '8': [
    {'1': '_recovery_data'},
    {'1': '_second_factor_mail'},
    {'1': '_second_factor_pin'},
    {'1': '_recovery_data_encrypted'},
  ],
};

@$core.Deprecated('Use sharedSecretDataDescriptor instead')
const SharedSecretData_SecondFactorPin$json = {
  '1': 'SecondFactorPin',
  '2': [
    {'1': 'unlock_token', '3': 1, '4': 1, '5': 12, '10': 'unlockToken'},
    {'1': 'pin_seed', '3': 2, '4': 1, '5': 12, '10': 'pinSeed'},
  ],
};

@$core.Deprecated('Use sharedSecretDataDescriptor instead')
const SharedSecretData_SecondFactorMail$json = {
  '1': 'SecondFactorMail',
};

/// Descriptor for `SharedSecretData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sharedSecretDataDescriptor = $convert.base64Decode(
    'ChBTaGFyZWRTZWNyZXREYXRhEk0KDXJlY292ZXJ5X2RhdGEYASABKAsyIy5wYXNzd29yZGxlc3'
    'NfcmVjb3ZlcnkuUmVjb3ZlcnlEYXRhSABSDHJlY292ZXJ5RGF0YYgBARJrChJzZWNvbmRfZmFj'
    'dG9yX21haWwYAiABKAsyOC5wYXNzd29yZGxlc3NfcmVjb3ZlcnkuU2hhcmVkU2VjcmV0RGF0YS'
    '5TZWNvbmRGYWN0b3JNYWlsSAFSEHNlY29uZEZhY3Rvck1haWyIAQESaAoRc2Vjb25kX2ZhY3Rv'
    'cl9waW4YAyABKAsyNy5wYXNzd29yZGxlc3NfcmVjb3ZlcnkuU2hhcmVkU2VjcmV0RGF0YS5TZW'
    'NvbmRGYWN0b3JQaW5IAlIPc2Vjb25kRmFjdG9yUGluiAEBEjsKF3JlY292ZXJ5X2RhdGFfZW5j'
    'cnlwdGVkGAQgASgMSANSFXJlY292ZXJ5RGF0YUVuY3J5cHRlZIgBARpPCg9TZWNvbmRGYWN0b3'
    'JQaW4SIQoMdW5sb2NrX3Rva2VuGAEgASgMUgt1bmxvY2tUb2tlbhIZCghwaW5fc2VlZBgCIAEo'
    'DFIHcGluU2VlZBoSChBTZWNvbmRGYWN0b3JNYWlsQhAKDl9yZWNvdmVyeV9kYXRhQhUKE19zZW'
    'NvbmRfZmFjdG9yX21haWxCFAoSX3NlY29uZF9mYWN0b3JfcGluQhoKGF9yZWNvdmVyeV9kYXRh'
    'X2VuY3J5cHRlZA==');

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
