// This is a generated file - do not edit.
//
// Generated from qr.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use qREnvelopeDescriptor instead')
const QREnvelope$json = {
  '1': 'QREnvelope',
  '2': [
    {
      '1': 'type',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.QREnvelope.Type',
      '10': 'type'
    },
    {'1': 'data', '3': 3, '4': 1, '5': 12, '10': 'data'},
  ],
  '4': [QREnvelope_Type$json],
};

@$core.Deprecated('Use qREnvelopeDescriptor instead')
const QREnvelope_Type$json = {
  '1': 'Type',
  '2': [
    {'1': 'PublicProfile', '2': 0},
  ],
};

/// Descriptor for `QREnvelope`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List qREnvelopeDescriptor = $convert.base64Decode(
    'CgpRUkVudmVsb3BlEiQKBHR5cGUYAiABKA4yEC5RUkVudmVsb3BlLlR5cGVSBHR5cGUSEgoEZG'
    'F0YRgDIAEoDFIEZGF0YSIZCgRUeXBlEhEKDVB1YmxpY1Byb2ZpbGUQAA==');

@$core.Deprecated('Use publicProfileDescriptor instead')
const PublicProfile$json = {
  '1': 'PublicProfile',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 3, '10': 'userId'},
    {'1': 'username', '3': 2, '4': 1, '5': 9, '10': 'username'},
    {
      '1': 'public_identity_key',
      '3': 3,
      '4': 1,
      '5': 12,
      '10': 'publicIdentityKey'
    },
    {'1': 'signed_prekey', '3': 4, '4': 1, '5': 12, '10': 'signedPrekey'},
    {'1': 'registration_id', '3': 5, '4': 1, '5': 3, '10': 'registrationId'},
    {
      '1': 'signed_prekey_signature',
      '3': 6,
      '4': 1,
      '5': 12,
      '10': 'signedPrekeySignature'
    },
    {'1': 'signed_prekey_id', '3': 7, '4': 1, '5': 3, '10': 'signedPrekeyId'},
  ],
};

/// Descriptor for `PublicProfile`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List publicProfileDescriptor = $convert.base64Decode(
    'Cg1QdWJsaWNQcm9maWxlEhcKB3VzZXJfaWQYASABKANSBnVzZXJJZBIaCgh1c2VybmFtZRgCIA'
    'EoCVIIdXNlcm5hbWUSLgoTcHVibGljX2lkZW50aXR5X2tleRgDIAEoDFIRcHVibGljSWRlbnRp'
    'dHlLZXkSIwoNc2lnbmVkX3ByZWtleRgEIAEoDFIMc2lnbmVkUHJla2V5EicKD3JlZ2lzdHJhdG'
    'lvbl9pZBgFIAEoA1IOcmVnaXN0cmF0aW9uSWQSNgoXc2lnbmVkX3ByZWtleV9zaWduYXR1cmUY'
    'BiABKAxSFXNpZ25lZFByZWtleVNpZ25hdHVyZRIoChBzaWduZWRfcHJla2V5X2lkGAcgASgDUg'
    '5zaWduZWRQcmVrZXlJZA==');
