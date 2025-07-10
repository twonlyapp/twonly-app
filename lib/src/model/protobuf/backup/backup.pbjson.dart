//
//  Generated code. Do not modify.
//  source: backup.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use twonlySafeBackupContentDescriptor instead')
const TwonlySafeBackupContent$json = {
  '1': 'TwonlySafeBackupContent',
  '2': [
    {
      '1': 'secureStorageJson',
      '3': 1,
      '4': 1,
      '5': 9,
      '10': 'secureStorageJson'
    },
    {'1': 'twonlyDatabase', '3': 2, '4': 1, '5': 12, '10': 'twonlyDatabase'},
  ],
};

/// Descriptor for `TwonlySafeBackupContent`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List twonlySafeBackupContentDescriptor = $convert.base64Decode(
    'ChdUd29ubHlTYWZlQmFja3VwQ29udGVudBIsChFzZWN1cmVTdG9yYWdlSnNvbhgBIAEoCVIRc2'
    'VjdXJlU3RvcmFnZUpzb24SJgoOdHdvbmx5RGF0YWJhc2UYAiABKAxSDnR3b25seURhdGFiYXNl');

@$core.Deprecated('Use twonlySafeBackupEncryptedDescriptor instead')
const TwonlySafeBackupEncrypted$json = {
  '1': 'TwonlySafeBackupEncrypted',
  '2': [
    {'1': 'mac', '3': 1, '4': 1, '5': 12, '10': 'mac'},
    {'1': 'nonce', '3': 2, '4': 1, '5': 12, '10': 'nonce'},
    {'1': 'cipherText', '3': 3, '4': 1, '5': 12, '10': 'cipherText'},
  ],
};

/// Descriptor for `TwonlySafeBackupEncrypted`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List twonlySafeBackupEncryptedDescriptor =
    $convert.base64Decode(
        'ChlUd29ubHlTYWZlQmFja3VwRW5jcnlwdGVkEhAKA21hYxgBIAEoDFIDbWFjEhQKBW5vbmNlGA'
        'IgASgMUgVub25jZRIeCgpjaXBoZXJUZXh0GAMgASgMUgpjaXBoZXJUZXh0');
