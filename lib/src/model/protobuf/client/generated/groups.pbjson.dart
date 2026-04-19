// This is a generated file - do not edit.
//
// Generated from groups.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use encryptedGroupStateDescriptor instead')
const EncryptedGroupState$json = {
  '1': 'EncryptedGroupState',
  '2': [
    {'1': 'member_ids', '3': 1, '4': 3, '5': 3, '10': 'memberIds'},
    {'1': 'admin_ids', '3': 2, '4': 3, '5': 3, '10': 'adminIds'},
    {'1': 'group_name', '3': 3, '4': 1, '5': 9, '10': 'groupName'},
    {
      '1': 'delete_messages_after_milliseconds',
      '3': 4,
      '4': 1,
      '5': 3,
      '9': 0,
      '10': 'deleteMessagesAfterMilliseconds',
      '17': true
    },
    {'1': 'padding', '3': 5, '4': 1, '5': 12, '10': 'padding'},
  ],
  '8': [
    {'1': '_delete_messages_after_milliseconds'},
  ],
};

/// Descriptor for `EncryptedGroupState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List encryptedGroupStateDescriptor = $convert.base64Decode(
    'ChNFbmNyeXB0ZWRHcm91cFN0YXRlEh0KCm1lbWJlcl9pZHMYASADKANSCW1lbWJlcklkcxIbCg'
    'lhZG1pbl9pZHMYAiADKANSCGFkbWluSWRzEh0KCmdyb3VwX25hbWUYAyABKAlSCWdyb3VwTmFt'
    'ZRJQCiJkZWxldGVfbWVzc2FnZXNfYWZ0ZXJfbWlsbGlzZWNvbmRzGAQgASgDSABSH2RlbGV0ZU'
    '1lc3NhZ2VzQWZ0ZXJNaWxsaXNlY29uZHOIAQESGAoHcGFkZGluZxgFIAEoDFIHcGFkZGluZ0Il'
    'CiNfZGVsZXRlX21lc3NhZ2VzX2FmdGVyX21pbGxpc2Vjb25kcw==');

@$core.Deprecated('Use encryptedAppendedGroupStateDescriptor instead')
const EncryptedAppendedGroupState$json = {
  '1': 'EncryptedAppendedGroupState',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.EncryptedAppendedGroupState.Type',
      '10': 'type'
    },
  ],
  '4': [EncryptedAppendedGroupState_Type$json],
};

@$core.Deprecated('Use encryptedAppendedGroupStateDescriptor instead')
const EncryptedAppendedGroupState_Type$json = {
  '1': 'Type',
  '2': [
    {'1': 'LEFT_GROUP', '2': 0},
  ],
};

/// Descriptor for `EncryptedAppendedGroupState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List encryptedAppendedGroupStateDescriptor =
    $convert.base64Decode(
        'ChtFbmNyeXB0ZWRBcHBlbmRlZEdyb3VwU3RhdGUSNQoEdHlwZRgBIAEoDjIhLkVuY3J5cHRlZE'
        'FwcGVuZGVkR3JvdXBTdGF0ZS5UeXBlUgR0eXBlIhYKBFR5cGUSDgoKTEVGVF9HUk9VUBAA');

@$core.Deprecated('Use encryptedGroupStateEnvelopDescriptor instead')
const EncryptedGroupStateEnvelop$json = {
  '1': 'EncryptedGroupStateEnvelop',
  '2': [
    {'1': 'nonce', '3': 1, '4': 1, '5': 12, '10': 'nonce'},
    {
      '1': 'encrypted_group_state',
      '3': 2,
      '4': 1,
      '5': 12,
      '10': 'encryptedGroupState'
    },
    {'1': 'mac', '3': 3, '4': 1, '5': 12, '10': 'mac'},
  ],
};

/// Descriptor for `EncryptedGroupStateEnvelop`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List encryptedGroupStateEnvelopDescriptor =
    $convert.base64Decode(
        'ChpFbmNyeXB0ZWRHcm91cFN0YXRlRW52ZWxvcBIUCgVub25jZRgBIAEoDFIFbm9uY2USMgoVZW'
        '5jcnlwdGVkX2dyb3VwX3N0YXRlGAIgASgMUhNlbmNyeXB0ZWRHcm91cFN0YXRlEhAKA21hYxgD'
        'IAEoDFIDbWFj');
