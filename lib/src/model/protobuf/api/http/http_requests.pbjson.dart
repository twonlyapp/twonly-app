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
    {'1': 'push_data', '3': 3, '4': 1, '5': 12, '9': 0, '10': 'pushData', '17': true},
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
    {'1': 'messages_on_success', '3': 3, '4': 3, '5': 11, '6': '.http_requests.TextMessage', '10': 'messagesOnSuccess'},
  ],
};

/// Descriptor for `UploadRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List uploadRequestDescriptor = $convert.base64Decode(
    'Cg1VcGxvYWRSZXF1ZXN0EiUKDmVuY3J5cHRlZF9kYXRhGAEgASgMUg1lbmNyeXB0ZWREYXRhEi'
    'cKD2Rvd25sb2FkX3Rva2VucxgCIAMoDFIOZG93bmxvYWRUb2tlbnMSSgoTbWVzc2FnZXNfb25f'
    'c3VjY2VzcxgDIAMoCzIaLmh0dHBfcmVxdWVzdHMuVGV4dE1lc3NhZ2VSEW1lc3NhZ2VzT25TdW'
    'NjZXNz');

@$core.Deprecated('Use updateGroupStateDescriptor instead')
const UpdateGroupState$json = {
  '1': 'UpdateGroupState',
  '2': [
    {'1': 'update', '3': 1, '4': 1, '5': 11, '6': '.http_requests.UpdateGroupState.UpdateTBS', '10': 'update'},
    {'1': 'signature', '3': 2, '4': 1, '5': 12, '10': 'signature'},
  ],
  '3': [UpdateGroupState_UpdateTBS$json],
};

@$core.Deprecated('Use updateGroupStateDescriptor instead')
const UpdateGroupState_UpdateTBS$json = {
  '1': 'UpdateTBS',
  '2': [
    {'1': 'version_id', '3': 1, '4': 1, '5': 4, '10': 'versionId'},
    {'1': 'encrypted_group_state', '3': 3, '4': 1, '5': 12, '10': 'encryptedGroupState'},
    {'1': 'public_key', '3': 4, '4': 1, '5': 12, '10': 'publicKey'},
    {'1': 'remove_admin', '3': 5, '4': 1, '5': 12, '9': 0, '10': 'removeAdmin', '17': true},
    {'1': 'add_admin', '3': 6, '4': 1, '5': 12, '9': 1, '10': 'addAdmin', '17': true},
    {'1': 'nonce', '3': 7, '4': 1, '5': 12, '10': 'nonce'},
  ],
  '8': [
    {'1': '_remove_admin'},
    {'1': '_add_admin'},
  ],
};

/// Descriptor for `UpdateGroupState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List updateGroupStateDescriptor = $convert.base64Decode(
    'ChBVcGRhdGVHcm91cFN0YXRlEkEKBnVwZGF0ZRgBIAEoCzIpLmh0dHBfcmVxdWVzdHMuVXBkYX'
    'RlR3JvdXBTdGF0ZS5VcGRhdGVUQlNSBnVwZGF0ZRIcCglzaWduYXR1cmUYAiABKAxSCXNpZ25h'
    'dHVyZRr8AQoJVXBkYXRlVEJTEh0KCnZlcnNpb25faWQYASABKARSCXZlcnNpb25JZBIyChVlbm'
    'NyeXB0ZWRfZ3JvdXBfc3RhdGUYAyABKAxSE2VuY3J5cHRlZEdyb3VwU3RhdGUSHQoKcHVibGlj'
    'X2tleRgEIAEoDFIJcHVibGljS2V5EiYKDHJlbW92ZV9hZG1pbhgFIAEoDEgAUgtyZW1vdmVBZG'
    '1pbogBARIgCglhZGRfYWRtaW4YBiABKAxIAVIIYWRkQWRtaW6IAQESFAoFbm9uY2UYByABKAxS'
    'BW5vbmNlQg8KDV9yZW1vdmVfYWRtaW5CDAoKX2FkZF9hZG1pbg==');

@$core.Deprecated('Use newGroupStateDescriptor instead')
const NewGroupState$json = {
  '1': 'NewGroupState',
  '2': [
    {'1': 'group_id', '3': 1, '4': 1, '5': 9, '10': 'groupId'},
    {'1': 'version_id', '3': 2, '4': 1, '5': 4, '10': 'versionId'},
    {'1': 'encrypted_group_state', '3': 3, '4': 1, '5': 12, '10': 'encryptedGroupState'},
    {'1': 'public_key', '3': 4, '4': 1, '5': 12, '10': 'publicKey'},
  ],
};

/// Descriptor for `NewGroupState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List newGroupStateDescriptor = $convert.base64Decode(
    'Cg1OZXdHcm91cFN0YXRlEhkKCGdyb3VwX2lkGAEgASgJUgdncm91cElkEh0KCnZlcnNpb25faW'
    'QYAiABKARSCXZlcnNpb25JZBIyChVlbmNyeXB0ZWRfZ3JvdXBfc3RhdGUYAyABKAxSE2VuY3J5'
    'cHRlZEdyb3VwU3RhdGUSHQoKcHVibGljX2tleRgEIAEoDFIJcHVibGljS2V5');

@$core.Deprecated('Use appendGroupStateDescriptor instead')
const AppendGroupState$json = {
  '1': 'AppendGroupState',
  '2': [
    {'1': 'signature', '3': 1, '4': 1, '5': 12, '10': 'signature'},
    {'1': 'appendTBS', '3': 2, '4': 1, '5': 11, '6': '.http_requests.AppendGroupState.AppendTBS', '10': 'appendTBS'},
    {'1': 'versionId', '3': 3, '4': 1, '5': 4, '10': 'versionId'},
  ],
  '3': [AppendGroupState_AppendTBS$json],
};

@$core.Deprecated('Use appendGroupStateDescriptor instead')
const AppendGroupState_AppendTBS$json = {
  '1': 'AppendTBS',
  '2': [
    {'1': 'encrypted_group_state_append', '3': 1, '4': 1, '5': 12, '10': 'encryptedGroupStateAppend'},
    {'1': 'public_key', '3': 2, '4': 1, '5': 12, '10': 'publicKey'},
    {'1': 'group_id', '3': 3, '4': 1, '5': 9, '10': 'groupId'},
    {'1': 'nonce', '3': 4, '4': 1, '5': 12, '10': 'nonce'},
  ],
};

/// Descriptor for `AppendGroupState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List appendGroupStateDescriptor = $convert.base64Decode(
    'ChBBcHBlbmRHcm91cFN0YXRlEhwKCXNpZ25hdHVyZRgBIAEoDFIJc2lnbmF0dXJlEkcKCWFwcG'
    'VuZFRCUxgCIAEoCzIpLmh0dHBfcmVxdWVzdHMuQXBwZW5kR3JvdXBTdGF0ZS5BcHBlbmRUQlNS'
    'CWFwcGVuZFRCUxIcCgl2ZXJzaW9uSWQYAyABKARSCXZlcnNpb25JZBqcAQoJQXBwZW5kVEJTEj'
    '8KHGVuY3J5cHRlZF9ncm91cF9zdGF0ZV9hcHBlbmQYASABKAxSGWVuY3J5cHRlZEdyb3VwU3Rh'
    'dGVBcHBlbmQSHQoKcHVibGljX2tleRgCIAEoDFIJcHVibGljS2V5EhkKCGdyb3VwX2lkGAMgAS'
    'gJUgdncm91cElkEhQKBW5vbmNlGAQgASgMUgVub25jZQ==');

@$core.Deprecated('Use groupStateDescriptor instead')
const GroupState$json = {
  '1': 'GroupState',
  '2': [
    {'1': 'version_id', '3': 1, '4': 1, '5': 4, '10': 'versionId'},
    {'1': 'encrypted_group_state', '3': 2, '4': 1, '5': 12, '10': 'encryptedGroupState'},
    {'1': 'appended_group_states', '3': 3, '4': 3, '5': 11, '6': '.http_requests.AppendGroupState', '10': 'appendedGroupStates'},
  ],
};

/// Descriptor for `GroupState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List groupStateDescriptor = $convert.base64Decode(
    'CgpHcm91cFN0YXRlEh0KCnZlcnNpb25faWQYASABKARSCXZlcnNpb25JZBIyChVlbmNyeXB0ZW'
    'RfZ3JvdXBfc3RhdGUYAiABKAxSE2VuY3J5cHRlZEdyb3VwU3RhdGUSUwoVYXBwZW5kZWRfZ3Jv'
    'dXBfc3RhdGVzGAMgAygLMh8uaHR0cF9yZXF1ZXN0cy5BcHBlbmRHcm91cFN0YXRlUhNhcHBlbm'
    'RlZEdyb3VwU3RhdGVz');

@$core.Deprecated('Use appendGroupStateHelperDescriptor instead')
const AppendGroupStateHelper$json = {
  '1': 'AppendGroupStateHelper',
  '2': [
    {'1': 'appended_group_states', '3': 1, '4': 3, '5': 11, '6': '.http_requests.AppendGroupState', '10': 'appendedGroupStates'},
  ],
};

/// Descriptor for `AppendGroupStateHelper`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List appendGroupStateHelperDescriptor = $convert.base64Decode(
    'ChZBcHBlbmRHcm91cFN0YXRlSGVscGVyElMKFWFwcGVuZGVkX2dyb3VwX3N0YXRlcxgBIAMoCz'
    'IfLmh0dHBfcmVxdWVzdHMuQXBwZW5kR3JvdXBTdGF0ZVITYXBwZW5kZWRHcm91cFN0YXRlcw==');

