//
//  Generated code. Do not modify.
//  source: api/http/http_requests.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use textMessageDescriptor instead')
const TextMessage$json = {
  '1': 'TextMessage',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 3, '10': 'userId'},
    {'1': 'body', '3': 2, '4': 1, '5': 12, '10': 'body'},
    {
      '1': 'push_data',
      '3': 3,
      '4': 1,
      '5': 12,
      '9': 0,
      '10': 'pushData',
      '17': true
    },
  ],
  '8': [
    {'1': '_push_data'},
  ],
};

/// Descriptor for `TextMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List textMessageDescriptor = $convert.base64Decode(
    'CgtUZXh0TWVzc2FnZRIXCgd1c2VyX2lkGAEgASgDUgZ1c2VySWQSEgoEYm9keRgCIAEoDFIEYm'
    '9keRIgCglwdXNoX2RhdGEYAyABKAxIAFIIcHVzaERhdGGIAQFCDAoKX3B1c2hfZGF0YQ==');

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
