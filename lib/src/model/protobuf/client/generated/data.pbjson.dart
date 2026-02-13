// This is a generated file - do not edit.
//
// Generated from data.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use sharedContactDescriptor instead')
const SharedContact$json = {
  '1': 'SharedContact',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 3, '10': 'userId'},
    {
      '1': 'public_identity_key',
      '3': 2,
      '4': 1,
      '5': 12,
      '10': 'publicIdentityKey'
    },
    {'1': 'display_name', '3': 3, '4': 1, '5': 9, '10': 'displayName'},
  ],
};

/// Descriptor for `SharedContact`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sharedContactDescriptor = $convert.base64Decode(
    'Cg1TaGFyZWRDb250YWN0EhcKB3VzZXJfaWQYASABKANSBnVzZXJJZBIuChNwdWJsaWNfaWRlbn'
    'RpdHlfa2V5GAIgASgMUhFwdWJsaWNJZGVudGl0eUtleRIhCgxkaXNwbGF5X25hbWUYAyABKAlS'
    'C2Rpc3BsYXlOYW1l');

@$core.Deprecated('Use additionalMessageDataDescriptor instead')
const AdditionalMessageData$json = {
  '1': 'AdditionalMessageData',
  '2': [
    {
      '1': 'type',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.AdditionalMessageData.Type',
      '10': 'type'
    },
    {'1': 'link', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'link', '17': true},
    {
      '1': 'contacts',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.SharedContact',
      '10': 'contacts'
    },
  ],
  '4': [AdditionalMessageData_Type$json],
  '8': [
    {'1': '_link'},
  ],
};

@$core.Deprecated('Use additionalMessageDataDescriptor instead')
const AdditionalMessageData_Type$json = {
  '1': 'Type',
  '2': [
    {'1': 'LINK', '2': 0},
    {'1': 'CONTACTS', '2': 1},
  ],
};

/// Descriptor for `AdditionalMessageData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List additionalMessageDataDescriptor = $convert.base64Decode(
    'ChVBZGRpdGlvbmFsTWVzc2FnZURhdGESLwoEdHlwZRgBIAEoDjIbLkFkZGl0aW9uYWxNZXNzYW'
    'dlRGF0YS5UeXBlUgR0eXBlEhcKBGxpbmsYAiABKAlIAFIEbGlua4gBARIqCghjb250YWN0cxgD'
    'IAMoCzIOLlNoYXJlZENvbnRhY3RSCGNvbnRhY3RzIh4KBFR5cGUSCAoETElOSxAAEgwKCENPTl'
    'RBQ1RTEAFCBwoFX2xpbms=');
