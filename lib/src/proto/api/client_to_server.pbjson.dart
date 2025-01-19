//
//  Generated code. Do not modify.
//  source: api/client_to_server.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use clientToServerDescriptor instead')
const ClientToServer$json = {
  '1': 'ClientToServer',
  '2': [
    {'1': 'V0', '3': 1, '4': 1, '5': 11, '6': '.client_to_server.V0', '9': 0, '10': 'V0'},
  ],
  '8': [
    {'1': 'v'},
  ],
};

/// Descriptor for `ClientToServer`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List clientToServerDescriptor = $convert.base64Decode(
    'Cg5DbGllbnRUb1NlcnZlchImCgJWMBgBIAEoCzIULmNsaWVudF90b19zZXJ2ZXIuVjBIAFICVj'
    'BCAwoBdg==');

@$core.Deprecated('Use v0Descriptor instead')
const V0$json = {
  '1': 'V0',
  '2': [
    {'1': 'seq', '3': 1, '4': 1, '5': 4, '10': 'seq'},
    {'1': 'handshake', '3': 2, '4': 1, '5': 11, '6': '.client_to_server.Handshake', '9': 0, '10': 'handshake'},
    {'1': 'applicationdata', '3': 3, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData', '9': 0, '10': 'applicationdata'},
    {'1': 'response', '3': 4, '4': 1, '5': 11, '6': '.client_to_server.Response', '9': 0, '10': 'response'},
  ],
  '8': [
    {'1': 'Kind'},
  ],
};

/// Descriptor for `V0`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List v0Descriptor = $convert.base64Decode(
    'CgJWMBIQCgNzZXEYASABKARSA3NlcRI7CgloYW5kc2hha2UYAiABKAsyGy5jbGllbnRfdG9fc2'
    'VydmVyLkhhbmRzaGFrZUgAUgloYW5kc2hha2USTQoPYXBwbGljYXRpb25kYXRhGAMgASgLMiEu'
    'Y2xpZW50X3RvX3NlcnZlci5BcHBsaWNhdGlvbkRhdGFIAFIPYXBwbGljYXRpb25kYXRhEjgKCH'
    'Jlc3BvbnNlGAQgASgLMhouY2xpZW50X3RvX3NlcnZlci5SZXNwb25zZUgAUghyZXNwb25zZUIG'
    'CgRLaW5k');

@$core.Deprecated('Use handshakeDescriptor instead')
const Handshake$json = {
  '1': 'Handshake',
  '2': [
    {'1': 'register', '3': 1, '4': 1, '5': 11, '6': '.client_to_server.Handshake.Register', '9': 0, '10': 'register'},
    {'1': 'getchallenge', '3': 2, '4': 1, '5': 11, '6': '.client_to_server.Handshake.GetChallenge', '9': 0, '10': 'getchallenge'},
    {'1': 'opensession', '3': 3, '4': 1, '5': 11, '6': '.client_to_server.Handshake.OpenSession', '9': 0, '10': 'opensession'},
  ],
  '3': [Handshake_Register$json, Handshake_GetChallenge$json, Handshake_OpenSession$json],
  '8': [
    {'1': 'Handshake'},
  ],
};

@$core.Deprecated('Use handshakeDescriptor instead')
const Handshake_Register$json = {
  '1': 'Register',
  '2': [
    {'1': 'username', '3': 1, '4': 1, '5': 9, '10': 'username'},
    {'1': 'invite_code', '3': 2, '4': 1, '5': 9, '9': 0, '10': 'inviteCode', '17': true},
    {'1': 'public_identity_key', '3': 3, '4': 1, '5': 12, '10': 'publicIdentityKey'},
    {'1': 'signed_prekey', '3': 4, '4': 1, '5': 12, '10': 'signedPrekey'},
    {'1': 'signed_prekey_signature', '3': 5, '4': 1, '5': 12, '10': 'signedPrekeySignature'},
    {'1': 'signed_prekey_id', '3': 6, '4': 1, '5': 3, '10': 'signedPrekeyId'},
  ],
  '8': [
    {'1': '_invite_code'},
  ],
};

@$core.Deprecated('Use handshakeDescriptor instead')
const Handshake_GetChallenge$json = {
  '1': 'GetChallenge',
};

@$core.Deprecated('Use handshakeDescriptor instead')
const Handshake_OpenSession$json = {
  '1': 'OpenSession',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 12, '10': 'userId'},
    {'1': 'response', '3': 2, '4': 1, '5': 12, '10': 'response'},
  ],
};

/// Descriptor for `Handshake`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List handshakeDescriptor = $convert.base64Decode(
    'CglIYW5kc2hha2USQgoIcmVnaXN0ZXIYASABKAsyJC5jbGllbnRfdG9fc2VydmVyLkhhbmRzaG'
    'FrZS5SZWdpc3RlckgAUghyZWdpc3RlchJOCgxnZXRjaGFsbGVuZ2UYAiABKAsyKC5jbGllbnRf'
    'dG9fc2VydmVyLkhhbmRzaGFrZS5HZXRDaGFsbGVuZ2VIAFIMZ2V0Y2hhbGxlbmdlEksKC29wZW'
    '5zZXNzaW9uGAMgASgLMicuY2xpZW50X3RvX3NlcnZlci5IYW5kc2hha2UuT3BlblNlc3Npb25I'
    'AFILb3BlbnNlc3Npb24akwIKCFJlZ2lzdGVyEhoKCHVzZXJuYW1lGAEgASgJUgh1c2VybmFtZR'
    'IkCgtpbnZpdGVfY29kZRgCIAEoCUgAUgppbnZpdGVDb2RliAEBEi4KE3B1YmxpY19pZGVudGl0'
    'eV9rZXkYAyABKAxSEXB1YmxpY0lkZW50aXR5S2V5EiMKDXNpZ25lZF9wcmVrZXkYBCABKAxSDH'
    'NpZ25lZFByZWtleRI2ChdzaWduZWRfcHJla2V5X3NpZ25hdHVyZRgFIAEoDFIVc2lnbmVkUHJl'
    'a2V5U2lnbmF0dXJlEigKEHNpZ25lZF9wcmVrZXlfaWQYBiABKANSDnNpZ25lZFByZWtleUlkQg'
    '4KDF9pbnZpdGVfY29kZRoOCgxHZXRDaGFsbGVuZ2UaQgoLT3BlblNlc3Npb24SFwoHdXNlcl9p'
    'ZBgBIAEoDFIGdXNlcklkEhoKCHJlc3BvbnNlGAIgASgMUghyZXNwb25zZUILCglIYW5kc2hha2'
    'U=');

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData$json = {
  '1': 'ApplicationData',
  '2': [
    {'1': 'textmessage', '3': 1, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.TextMessage', '9': 0, '10': 'textmessage'},
    {'1': 'getuserbyusername', '3': 2, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.GetUserByUsername', '9': 0, '10': 'getuserbyusername'},
    {'1': 'getprekeysbyuserid', '3': 3, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.GetPrekeysByUserId', '9': 0, '10': 'getprekeysbyuserid'},
  ],
  '3': [ApplicationData_TextMessage$json, ApplicationData_GetUserByUsername$json, ApplicationData_GetPrekeysByUserId$json],
  '8': [
    {'1': 'ApplicationData'},
  ],
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_TextMessage$json = {
  '1': 'TextMessage',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 12, '10': 'userId'},
    {'1': 'body', '3': 3, '4': 1, '5': 12, '10': 'body'},
  ],
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_GetUserByUsername$json = {
  '1': 'GetUserByUsername',
  '2': [
    {'1': 'username', '3': 1, '4': 1, '5': 9, '10': 'username'},
  ],
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_GetPrekeysByUserId$json = {
  '1': 'GetPrekeysByUserId',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 12, '10': 'userId'},
  ],
};

/// Descriptor for `ApplicationData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List applicationDataDescriptor = $convert.base64Decode(
    'Cg9BcHBsaWNhdGlvbkRhdGESUQoLdGV4dG1lc3NhZ2UYASABKAsyLS5jbGllbnRfdG9fc2Vydm'
    'VyLkFwcGxpY2F0aW9uRGF0YS5UZXh0TWVzc2FnZUgAUgt0ZXh0bWVzc2FnZRJjChFnZXR1c2Vy'
    'Ynl1c2VybmFtZRgCIAEoCzIzLmNsaWVudF90b19zZXJ2ZXIuQXBwbGljYXRpb25EYXRhLkdldF'
    'VzZXJCeVVzZXJuYW1lSABSEWdldHVzZXJieXVzZXJuYW1lEmYKEmdldHByZWtleXNieXVzZXJp'
    'ZBgDIAEoCzI0LmNsaWVudF90b19zZXJ2ZXIuQXBwbGljYXRpb25EYXRhLkdldFByZWtleXNCeV'
    'VzZXJJZEgAUhJnZXRwcmVrZXlzYnl1c2VyaWQaOgoLVGV4dE1lc3NhZ2USFwoHdXNlcl9pZBgB'
    'IAEoDFIGdXNlcklkEhIKBGJvZHkYAyABKAxSBGJvZHkaLwoRR2V0VXNlckJ5VXNlcm5hbWUSGg'
    'oIdXNlcm5hbWUYASABKAlSCHVzZXJuYW1lGi0KEkdldFByZWtleXNCeVVzZXJJZBIXCgd1c2Vy'
    'X2lkGAEgASgMUgZ1c2VySWRCEQoPQXBwbGljYXRpb25EYXRh');

@$core.Deprecated('Use responseDescriptor instead')
const Response$json = {
  '1': 'Response',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 11, '6': '.client_to_server.Response.Ok', '9': 0, '10': 'ok'},
    {'1': 'error', '3': 2, '4': 1, '5': 14, '6': '.error.ErrorCode', '9': 0, '10': 'error'},
  ],
  '3': [Response_Prekeys$json, Response_Ok$json],
  '8': [
    {'1': 'Response'},
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_Prekeys$json = {
  '1': 'Prekeys',
  '2': [
    {'1': 'prekeys', '3': 1, '4': 3, '5': 12, '10': 'prekeys'},
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_Ok$json = {
  '1': 'Ok',
  '2': [
    {'1': 'None', '3': 1, '4': 1, '5': 8, '9': 0, '10': 'None'},
    {'1': 'prekeys', '3': 2, '4': 1, '5': 11, '6': '.client_to_server.Response.Prekeys', '9': 0, '10': 'prekeys'},
  ],
  '8': [
    {'1': 'Ok'},
  ],
};

/// Descriptor for `Response`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseDescriptor = $convert.base64Decode(
    'CghSZXNwb25zZRIvCgJvaxgBIAEoCzIdLmNsaWVudF90b19zZXJ2ZXIuUmVzcG9uc2UuT2tIAF'
    'ICb2sSKAoFZXJyb3IYAiABKA4yEC5lcnJvci5FcnJvckNvZGVIAFIFZXJyb3IaIwoHUHJla2V5'
    'cxIYCgdwcmVrZXlzGAEgAygMUgdwcmVrZXlzGmAKAk9rEhQKBE5vbmUYASABKAhIAFIETm9uZR'
    'I+CgdwcmVrZXlzGAIgASgLMiIuY2xpZW50X3RvX3NlcnZlci5SZXNwb25zZS5QcmVrZXlzSABS'
    'B3ByZWtleXNCBAoCT2tCCgoIUmVzcG9uc2U=');

