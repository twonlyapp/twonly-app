// This is a generated file - do not edit.
//
// Generated from http_requests.proto.

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

@$core.Deprecated('Use textMessageDescriptor instead')
const TextMessage$json = {
  '1': 'TextMessage',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 3, '10': 'userId'},
    {'1': 'body', '3': 2, '4': 1, '5': 12, '10': 'body'},
    {'1': 'wake_receiver', '3': 4, '4': 1, '5': 8, '10': 'wakeReceiver'},
  ],
  '9': [
    {'1': 3, '2': 4},
  ],
};

/// Descriptor for `TextMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List textMessageDescriptor = $convert.base64Decode(
    'CgtUZXh0TWVzc2FnZRIXCgd1c2VyX2lkGAEgASgDUgZ1c2VySWQSEgoEYm9keRgCIAEoDFIEYm'
    '9keRIjCg13YWtlX3JlY2VpdmVyGAQgASgIUgx3YWtlUmVjZWl2ZXJKBAgDEAQ=');

@$core.Deprecated('Use uploadRequestDescriptor instead')
const UploadRequest$json = {
  '1': 'UploadRequest',
  '2': [
    {'1': 'encrypted_data', '3': 1, '4': 1, '5': 12, '10': 'encryptedData'},
    {'1': 'download_tokens', '3': 2, '4': 3, '5': 12, '10': 'downloadTokens'},
    {
      '1': 'messages_on_success',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.http_requests.TextMessage',
      '10': 'messagesOnSuccess'
    },
  ],
};

/// Descriptor for `UploadRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uploadRequestDescriptor = $convert.base64Decode(
    'Cg1VcGxvYWRSZXF1ZXN0EiUKDmVuY3J5cHRlZF9kYXRhGAEgASgMUg1lbmNyeXB0ZWREYXRhEi'
    'cKD2Rvd25sb2FkX3Rva2VucxgCIAMoDFIOZG93bmxvYWRUb2tlbnMSSgoTbWVzc2FnZXNfb25f'
    'c3VjY2VzcxgDIAMoCzIaLmh0dHBfcmVxdWVzdHMuVGV4dE1lc3NhZ2VSEW1lc3NhZ2VzT25TdW'
    'NjZXNz');
