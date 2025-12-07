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
    {'1': 'memberIds', '3': 1, '4': 3, '5': 3, '10': 'memberIds'},
    {'1': 'adminIds', '3': 2, '4': 3, '5': 3, '10': 'adminIds'},
    {'1': 'groupName', '3': 3, '4': 1, '5': 9, '10': 'groupName'},
    {
      '1': 'deleteMessagesAfterMilliseconds',
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
    {'1': '_deleteMessagesAfterMilliseconds'},
  ],
};

/// Descriptor for `EncryptedGroupState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List encryptedGroupStateDescriptor = $convert.base64Decode(
    'ChNFbmNyeXB0ZWRHcm91cFN0YXRlEhwKCW1lbWJlcklkcxgBIAMoA1IJbWVtYmVySWRzEhoKCG'
    'FkbWluSWRzGAIgAygDUghhZG1pbklkcxIcCglncm91cE5hbWUYAyABKAlSCWdyb3VwTmFtZRJN'
    'Ch9kZWxldGVNZXNzYWdlc0FmdGVyTWlsbGlzZWNvbmRzGAQgASgDSABSH2RlbGV0ZU1lc3NhZ2'
    'VzQWZ0ZXJNaWxsaXNlY29uZHOIAQESGAoHcGFkZGluZxgFIAEoDFIHcGFkZGluZ0IiCiBfZGVs'
    'ZXRlTWVzc2FnZXNBZnRlck1pbGxpc2Vjb25kcw==');

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
      '1': 'encryptedGroupState',
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
        'ChpFbmNyeXB0ZWRHcm91cFN0YXRlRW52ZWxvcBIUCgVub25jZRgBIAEoDFIFbm9uY2USMAoTZW'
        '5jcnlwdGVkR3JvdXBTdGF0ZRgCIAEoDFITZW5jcnlwdGVkR3JvdXBTdGF0ZRIQCgNtYWMYAyAB'
        'KAxSA21hYw==');
