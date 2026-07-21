// This is a generated file - do not edit.
//
// Generated from backup.proto.

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

@$core.Deprecated('Use twonlySafeBackupContentDescriptor instead')
const TwonlySafeBackupContent$json = {
  '1': 'TwonlySafeBackupContent',
  '2': [
    {
      '1': 'secure_storage_json',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'secureStorageJson'
    },
    {'1': 'twonly_database', '3': 2, '4': 1, '5': 12, '10': 'twonlyDatabase'},
  ],
};

/// Descriptor for `TwonlySafeBackupContent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List twonlySafeBackupContentDescriptor = $convert.base64Decode(
    'ChdUd29ubHlTYWZlQmFja3VwQ29udGVudBIuChNzZWN1cmVfc3RvcmFnZV9qc29uGAEgASgJUh'
    'FzZWN1cmVTdG9yYWdlSnNvbhInCg90d29ubHlfZGF0YWJhc2UYAiABKAxSDnR3b25seURhdGFi'
    'YXNl');

@$core.Deprecated('Use twonlySafeBackupEncryptedDescriptor instead')
const TwonlySafeBackupEncrypted$json = {
  '1': 'TwonlySafeBackupEncrypted',
  '2': [
    {'1': 'mac', '3': 1, '4': 1, '5': 12, '10': 'mac'},
    {'1': 'nonce', '3': 2, '4': 1, '5': 12, '10': 'nonce'},
    {'1': 'cipher_text', '3': 3, '4': 1, '5': 12, '10': 'cipherText'},
  ],
};

/// Descriptor for `TwonlySafeBackupEncrypted`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List twonlySafeBackupEncryptedDescriptor =
    $convert.base64Decode(
        'ChlUd29ubHlTYWZlQmFja3VwRW5jcnlwdGVkEhAKA21hYxgBIAEoDFIDbWFjEhQKBW5vbmNlGA'
        'IgASgMUgVub25jZRIfCgtjaXBoZXJfdGV4dBgDIAEoDFIKY2lwaGVyVGV4dA==');

@$core.Deprecated('Use cloudMediaBackupEncryptedDescriptor instead')
const CloudMediaBackupEncrypted$json = {
  '1': 'CloudMediaBackupEncrypted',
  '2': [
    {'1': 'addition', '3': 1, '4': 1, '5': 9, '10': 'addition'},
    {
      '1': 'encrypted_media_key',
      '3': 2,
      '4': 1,
      '5': 12,
      '10': 'encryptedMediaKey'
    },
    {'1': 'media_nonce', '3': 3, '4': 1, '5': 12, '10': 'mediaNonce'},
    {'1': 'media_ciphertext', '3': 4, '4': 1, '5': 12, '10': 'mediaCiphertext'},
  ],
};

/// Descriptor for `CloudMediaBackupEncrypted`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List cloudMediaBackupEncryptedDescriptor = $convert.base64Decode(
    'ChlDbG91ZE1lZGlhQmFja3VwRW5jcnlwdGVkEhoKCGFkZGl0aW9uGAEgASgJUghhZGRpdGlvbh'
    'IuChNlbmNyeXB0ZWRfbWVkaWFfa2V5GAIgASgMUhFlbmNyeXB0ZWRNZWRpYUtleRIfCgttZWRp'
    'YV9ub25jZRgDIAEoDFIKbWVkaWFOb25jZRIpChBtZWRpYV9jaXBoZXJ0ZXh0GAQgASgMUg9tZW'
    'RpYUNpcGhlcnRleHQ=');
