//
//  Generated code. Do not modify.
//  source: api/server_to_client.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use serverToClientDescriptor instead')
const ServerToClient$json = {
  '1': 'ServerToClient',
  '2': [
    {'1': 'V0', '3': 1, '4': 1, '5': 11, '6': '.server_to_client.V0', '9': 0, '10': 'V0'},
  ],
  '8': [
    {'1': 'v'},
  ],
};

/// Descriptor for `ServerToClient`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List serverToClientDescriptor = $convert.base64Decode(
    'Cg5TZXJ2ZXJUb0NsaWVudBImCgJWMBgBIAEoCzIULnNlcnZlcl90b19jbGllbnQuVjBIAFICVj'
    'BCAwoBdg==');

@$core.Deprecated('Use v0Descriptor instead')
const V0$json = {
  '1': 'V0',
  '2': [
    {'1': 'seq', '3': 1, '4': 1, '5': 4, '10': 'seq'},
    {'1': 'response', '3': 2, '4': 1, '5': 11, '6': '.server_to_client.Response', '9': 0, '10': 'response'},
    {'1': 'newMessage', '3': 3, '4': 1, '5': 11, '6': '.server_to_client.NewMessage', '9': 0, '10': 'newMessage'},
    {'1': 'RequestNewPreKeys', '3': 4, '4': 1, '5': 8, '9': 0, '10': 'RequestNewPreKeys'},
  ],
  '8': [
    {'1': 'Kind'},
  ],
};

/// Descriptor for `V0`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List v0Descriptor = $convert.base64Decode(
    'CgJWMBIQCgNzZXEYASABKARSA3NlcRI4CghyZXNwb25zZRgCIAEoCzIaLnNlcnZlcl90b19jbG'
    'llbnQuUmVzcG9uc2VIAFIIcmVzcG9uc2USPgoKbmV3TWVzc2FnZRgDIAEoCzIcLnNlcnZlcl90'
    'b19jbGllbnQuTmV3TWVzc2FnZUgAUgpuZXdNZXNzYWdlEi4KEVJlcXVlc3ROZXdQcmVLZXlzGA'
    'QgASgISABSEVJlcXVlc3ROZXdQcmVLZXlzQgYKBEtpbmQ=');

@$core.Deprecated('Use newMessageDescriptor instead')
const NewMessage$json = {
  '1': 'NewMessage',
  '2': [
    {'1': 'body', '3': 1, '4': 1, '5': 12, '10': 'body'},
  ],
};

/// Descriptor for `NewMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List newMessageDescriptor = $convert.base64Decode(
    'CgpOZXdNZXNzYWdlEhIKBGJvZHkYASABKAxSBGJvZHk=');

@$core.Deprecated('Use responseDescriptor instead')
const Response$json = {
  '1': 'Response',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 11, '6': '.server_to_client.Response.Ok', '9': 0, '10': 'ok'},
    {'1': 'error', '3': 2, '4': 1, '5': 14, '6': '.error.ErrorCode', '9': 0, '10': 'error'},
  ],
  '3': [Response_UserData$json, Response_Ok$json],
  '8': [
    {'1': 'Response'},
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_UserData$json = {
  '1': 'UserData',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 12, '10': 'userId'},
    {'1': 'prekeys', '3': 2, '4': 3, '5': 12, '10': 'prekeys'},
    {'1': 'public_identity_key', '3': 3, '4': 1, '5': 12, '9': 0, '10': 'publicIdentityKey', '17': true},
    {'1': 'signed_prekey', '3': 4, '4': 1, '5': 12, '9': 1, '10': 'signedPrekey', '17': true},
    {'1': 'signed_prekey_signature', '3': 5, '4': 1, '5': 12, '9': 2, '10': 'signedPrekeySignature', '17': true},
    {'1': 'signed_prekey_id', '3': 6, '4': 1, '5': 3, '9': 3, '10': 'signedPrekeyId', '17': true},
  ],
  '8': [
    {'1': '_public_identity_key'},
    {'1': '_signed_prekey'},
    {'1': '_signed_prekey_signature'},
    {'1': '_signed_prekey_id'},
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_Ok$json = {
  '1': 'Ok',
  '2': [
    {'1': 'None', '3': 1, '4': 1, '5': 8, '9': 0, '10': 'None'},
    {'1': 'userid', '3': 2, '4': 1, '5': 12, '9': 0, '10': 'userid'},
    {'1': 'challenge', '3': 3, '4': 1, '5': 12, '9': 0, '10': 'challenge'},
    {'1': 'userdata', '3': 4, '4': 1, '5': 11, '6': '.server_to_client.Response.UserData', '9': 0, '10': 'userdata'},
  ],
  '8': [
    {'1': 'Ok'},
  ],
};

/// Descriptor for `Response`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseDescriptor = $convert.base64Decode(
    'CghSZXNwb25zZRIvCgJvaxgBIAEoCzIdLnNlcnZlcl90b19jbGllbnQuUmVzcG9uc2UuT2tIAF'
    'ICb2sSKAoFZXJyb3IYAiABKA4yEC5lcnJvci5FcnJvckNvZGVIAFIFZXJyb3Ia4wIKCFVzZXJE'
    'YXRhEhcKB3VzZXJfaWQYASABKAxSBnVzZXJJZBIYCgdwcmVrZXlzGAIgAygMUgdwcmVrZXlzEj'
    'MKE3B1YmxpY19pZGVudGl0eV9rZXkYAyABKAxIAFIRcHVibGljSWRlbnRpdHlLZXmIAQESKAoN'
    'c2lnbmVkX3ByZWtleRgEIAEoDEgBUgxzaWduZWRQcmVrZXmIAQESOwoXc2lnbmVkX3ByZWtleV'
    '9zaWduYXR1cmUYBSABKAxIAlIVc2lnbmVkUHJla2V5U2lnbmF0dXJliAEBEi0KEHNpZ25lZF9w'
    'cmVrZXlfaWQYBiABKANIA1IOc2lnbmVkUHJla2V5SWSIAQFCFgoUX3B1YmxpY19pZGVudGl0eV'
    '9rZXlCEAoOX3NpZ25lZF9wcmVrZXlCGgoYX3NpZ25lZF9wcmVrZXlfc2lnbmF0dXJlQhMKEV9z'
    'aWduZWRfcHJla2V5X2lkGp0BCgJPaxIUCgROb25lGAEgASgISABSBE5vbmUSGAoGdXNlcmlkGA'
    'IgASgMSABSBnVzZXJpZBIeCgljaGFsbGVuZ2UYAyABKAxIAFIJY2hhbGxlbmdlEkEKCHVzZXJk'
    'YXRhGAQgASgLMiMuc2VydmVyX3RvX2NsaWVudC5SZXNwb25zZS5Vc2VyRGF0YUgAUgh1c2VyZG'
    'F0YUIECgJPa0IKCghSZXNwb25zZQ==');

