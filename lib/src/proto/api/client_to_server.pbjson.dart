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
    {'1': 'getauthchallenge', '3': 2, '4': 1, '5': 11, '6': '.client_to_server.Handshake.GetAuthChallenge', '9': 0, '10': 'getauthchallenge'},
    {'1': 'getauthtoken', '3': 3, '4': 1, '5': 11, '6': '.client_to_server.Handshake.GetAuthToken', '9': 0, '10': 'getauthtoken'},
    {'1': 'authenticate', '3': 4, '4': 1, '5': 11, '6': '.client_to_server.Handshake.Authenticate', '9': 0, '10': 'authenticate'},
  ],
  '3': [Handshake_Register$json, Handshake_GetAuthChallenge$json, Handshake_GetAuthToken$json, Handshake_Authenticate$json],
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
    {'1': 'registration_id', '3': 7, '4': 1, '5': 3, '10': 'registrationId'},
  ],
  '8': [
    {'1': '_invite_code'},
  ],
};

@$core.Deprecated('Use handshakeDescriptor instead')
const Handshake_GetAuthChallenge$json = {
  '1': 'GetAuthChallenge',
};

@$core.Deprecated('Use handshakeDescriptor instead')
const Handshake_GetAuthToken$json = {
  '1': 'GetAuthToken',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 3, '10': 'userId'},
    {'1': 'response', '3': 2, '4': 1, '5': 12, '10': 'response'},
  ],
};

@$core.Deprecated('Use handshakeDescriptor instead')
const Handshake_Authenticate$json = {
  '1': 'Authenticate',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 3, '10': 'userId'},
    {'1': 'auth_token', '3': 2, '4': 1, '5': 12, '10': 'authToken'},
  ],
};

/// Descriptor for `Handshake`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List handshakeDescriptor = $convert.base64Decode(
    'CglIYW5kc2hha2USQgoIcmVnaXN0ZXIYASABKAsyJC5jbGllbnRfdG9fc2VydmVyLkhhbmRzaG'
    'FrZS5SZWdpc3RlckgAUghyZWdpc3RlchJaChBnZXRhdXRoY2hhbGxlbmdlGAIgASgLMiwuY2xp'
    'ZW50X3RvX3NlcnZlci5IYW5kc2hha2UuR2V0QXV0aENoYWxsZW5nZUgAUhBnZXRhdXRoY2hhbG'
    'xlbmdlEk4KDGdldGF1dGh0b2tlbhgDIAEoCzIoLmNsaWVudF90b19zZXJ2ZXIuSGFuZHNoYWtl'
    'LkdldEF1dGhUb2tlbkgAUgxnZXRhdXRodG9rZW4STgoMYXV0aGVudGljYXRlGAQgASgLMiguY2'
    'xpZW50X3RvX3NlcnZlci5IYW5kc2hha2UuQXV0aGVudGljYXRlSABSDGF1dGhlbnRpY2F0ZRq8'
    'AgoIUmVnaXN0ZXISGgoIdXNlcm5hbWUYASABKAlSCHVzZXJuYW1lEiQKC2ludml0ZV9jb2RlGA'
    'IgASgJSABSCmludml0ZUNvZGWIAQESLgoTcHVibGljX2lkZW50aXR5X2tleRgDIAEoDFIRcHVi'
    'bGljSWRlbnRpdHlLZXkSIwoNc2lnbmVkX3ByZWtleRgEIAEoDFIMc2lnbmVkUHJla2V5EjYKF3'
    'NpZ25lZF9wcmVrZXlfc2lnbmF0dXJlGAUgASgMUhVzaWduZWRQcmVrZXlTaWduYXR1cmUSKAoQ'
    'c2lnbmVkX3ByZWtleV9pZBgGIAEoA1IOc2lnbmVkUHJla2V5SWQSJwoPcmVnaXN0cmF0aW9uX2'
    'lkGAcgASgDUg5yZWdpc3RyYXRpb25JZEIOCgxfaW52aXRlX2NvZGUaEgoQR2V0QXV0aENoYWxs'
    'ZW5nZRpDCgxHZXRBdXRoVG9rZW4SFwoHdXNlcl9pZBgBIAEoA1IGdXNlcklkEhoKCHJlc3Bvbn'
    'NlGAIgASgMUghyZXNwb25zZRpGCgxBdXRoZW50aWNhdGUSFwoHdXNlcl9pZBgBIAEoA1IGdXNl'
    'cklkEh0KCmF1dGhfdG9rZW4YAiABKAxSCWF1dGhUb2tlbkILCglIYW5kc2hha2U=');

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData$json = {
  '1': 'ApplicationData',
  '2': [
    {'1': 'textmessage', '3': 1, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.TextMessage', '9': 0, '10': 'textmessage'},
    {'1': 'getuserbyusername', '3': 2, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.GetUserByUsername', '9': 0, '10': 'getuserbyusername'},
    {'1': 'getprekeysbyuserid', '3': 3, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.GetPrekeysByUserId', '9': 0, '10': 'getprekeysbyuserid'},
    {'1': 'getuploadtoken', '3': 4, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.GetUploadToken', '9': 0, '10': 'getuploadtoken'},
    {'1': 'uploaddata', '3': 5, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.UploadData', '9': 0, '10': 'uploaddata'},
    {'1': 'getuserbyid', '3': 6, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.GetUserById', '9': 0, '10': 'getuserbyid'},
    {'1': 'downloaddata', '3': 7, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.DownloadData', '9': 0, '10': 'downloaddata'},
    {'1': 'updategooglefcmtoken', '3': 8, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.UpdateGoogleFcmToken', '9': 0, '10': 'updategooglefcmtoken'},
  ],
  '3': [ApplicationData_TextMessage$json, ApplicationData_GetUserByUsername$json, ApplicationData_UpdateGoogleFcmToken$json, ApplicationData_GetUserById$json, ApplicationData_GetPrekeysByUserId$json, ApplicationData_GetUploadToken$json, ApplicationData_UploadData$json, ApplicationData_DownloadData$json],
  '8': [
    {'1': 'ApplicationData'},
  ],
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_TextMessage$json = {
  '1': 'TextMessage',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 3, '10': 'userId'},
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
const ApplicationData_UpdateGoogleFcmToken$json = {
  '1': 'UpdateGoogleFcmToken',
  '2': [
    {'1': 'google_fcm', '3': 1, '4': 1, '5': 9, '10': 'googleFcm'},
  ],
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_GetUserById$json = {
  '1': 'GetUserById',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 3, '10': 'userId'},
  ],
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_GetPrekeysByUserId$json = {
  '1': 'GetPrekeysByUserId',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 3, '10': 'userId'},
  ],
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_GetUploadToken$json = {
  '1': 'GetUploadToken',
  '2': [
    {'1': 'recipients_count', '3': 1, '4': 1, '5': 13, '10': 'recipientsCount'},
  ],
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_UploadData$json = {
  '1': 'UploadData',
  '2': [
    {'1': 'upload_token', '3': 1, '4': 1, '5': 12, '10': 'uploadToken'},
    {'1': 'offset', '3': 2, '4': 1, '5': 13, '10': 'offset'},
    {'1': 'data', '3': 3, '4': 1, '5': 12, '10': 'data'},
    {'1': 'checksum', '3': 4, '4': 1, '5': 12, '9': 0, '10': 'checksum', '17': true},
  ],
  '8': [
    {'1': '_checksum'},
  ],
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_DownloadData$json = {
  '1': 'DownloadData',
  '2': [
    {'1': 'download_token', '3': 1, '4': 1, '5': 12, '10': 'downloadToken'},
    {'1': 'offset', '3': 2, '4': 1, '5': 13, '10': 'offset'},
  ],
};

/// Descriptor for `ApplicationData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List applicationDataDescriptor = $convert.base64Decode(
    'Cg9BcHBsaWNhdGlvbkRhdGESUQoLdGV4dG1lc3NhZ2UYASABKAsyLS5jbGllbnRfdG9fc2Vydm'
    'VyLkFwcGxpY2F0aW9uRGF0YS5UZXh0TWVzc2FnZUgAUgt0ZXh0bWVzc2FnZRJjChFnZXR1c2Vy'
    'Ynl1c2VybmFtZRgCIAEoCzIzLmNsaWVudF90b19zZXJ2ZXIuQXBwbGljYXRpb25EYXRhLkdldF'
    'VzZXJCeVVzZXJuYW1lSABSEWdldHVzZXJieXVzZXJuYW1lEmYKEmdldHByZWtleXNieXVzZXJp'
    'ZBgDIAEoCzI0LmNsaWVudF90b19zZXJ2ZXIuQXBwbGljYXRpb25EYXRhLkdldFByZWtleXNCeV'
    'VzZXJJZEgAUhJnZXRwcmVrZXlzYnl1c2VyaWQSWgoOZ2V0dXBsb2FkdG9rZW4YBCABKAsyMC5j'
    'bGllbnRfdG9fc2VydmVyLkFwcGxpY2F0aW9uRGF0YS5HZXRVcGxvYWRUb2tlbkgAUg5nZXR1cG'
    'xvYWR0b2tlbhJOCgp1cGxvYWRkYXRhGAUgASgLMiwuY2xpZW50X3RvX3NlcnZlci5BcHBsaWNh'
    'dGlvbkRhdGEuVXBsb2FkRGF0YUgAUgp1cGxvYWRkYXRhElEKC2dldHVzZXJieWlkGAYgASgLMi'
    '0uY2xpZW50X3RvX3NlcnZlci5BcHBsaWNhdGlvbkRhdGEuR2V0VXNlckJ5SWRIAFILZ2V0dXNl'
    'cmJ5aWQSVAoMZG93bmxvYWRkYXRhGAcgASgLMi4uY2xpZW50X3RvX3NlcnZlci5BcHBsaWNhdG'
    'lvbkRhdGEuRG93bmxvYWREYXRhSABSDGRvd25sb2FkZGF0YRJsChR1cGRhdGVnb29nbGVmY210'
    'b2tlbhgIIAEoCzI2LmNsaWVudF90b19zZXJ2ZXIuQXBwbGljYXRpb25EYXRhLlVwZGF0ZUdvb2'
    'dsZUZjbVRva2VuSABSFHVwZGF0ZWdvb2dsZWZjbXRva2VuGjoKC1RleHRNZXNzYWdlEhcKB3Vz'
    'ZXJfaWQYASABKANSBnVzZXJJZBISCgRib2R5GAMgASgMUgRib2R5Gi8KEUdldFVzZXJCeVVzZX'
    'JuYW1lEhoKCHVzZXJuYW1lGAEgASgJUgh1c2VybmFtZRo1ChRVcGRhdGVHb29nbGVGY21Ub2tl'
    'bhIdCgpnb29nbGVfZmNtGAEgASgJUglnb29nbGVGY20aJgoLR2V0VXNlckJ5SWQSFwoHdXNlcl'
    '9pZBgBIAEoA1IGdXNlcklkGi0KEkdldFByZWtleXNCeVVzZXJJZBIXCgd1c2VyX2lkGAEgASgD'
    'UgZ1c2VySWQaOwoOR2V0VXBsb2FkVG9rZW4SKQoQcmVjaXBpZW50c19jb3VudBgBIAEoDVIPcm'
    'VjaXBpZW50c0NvdW50GokBCgpVcGxvYWREYXRhEiEKDHVwbG9hZF90b2tlbhgBIAEoDFILdXBs'
    'b2FkVG9rZW4SFgoGb2Zmc2V0GAIgASgNUgZvZmZzZXQSEgoEZGF0YRgDIAEoDFIEZGF0YRIfCg'
    'hjaGVja3N1bRgEIAEoDEgAUghjaGVja3N1bYgBAUILCglfY2hlY2tzdW0aTQoMRG93bmxvYWRE'
    'YXRhEiUKDmRvd25sb2FkX3Rva2VuGAEgASgMUg1kb3dubG9hZFRva2VuEhYKBm9mZnNldBgCIA'
    'EoDVIGb2Zmc2V0QhEKD0FwcGxpY2F0aW9uRGF0YQ==');

@$core.Deprecated('Use responseDescriptor instead')
const Response$json = {
  '1': 'Response',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 11, '6': '.client_to_server.Response.Ok', '9': 0, '10': 'ok'},
    {'1': 'error', '3': 2, '4': 1, '5': 14, '6': '.error.ErrorCode', '9': 0, '10': 'error'},
  ],
  '3': [Response_PreKey$json, Response_Prekeys$json, Response_Ok$json],
  '8': [
    {'1': 'Response'},
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_PreKey$json = {
  '1': 'PreKey',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'prekey', '3': 2, '4': 1, '5': 12, '10': 'prekey'},
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_Prekeys$json = {
  '1': 'Prekeys',
  '2': [
    {'1': 'prekeys', '3': 1, '4': 3, '5': 11, '6': '.client_to_server.Response.PreKey', '10': 'prekeys'},
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
    'ICb2sSKAoFZXJyb3IYAiABKA4yEC5lcnJvci5FcnJvckNvZGVIAFIFZXJyb3IaMAoGUHJlS2V5'
    'Eg4KAmlkGAEgASgDUgJpZBIWCgZwcmVrZXkYAiABKAxSBnByZWtleRpGCgdQcmVrZXlzEjsKB3'
    'ByZWtleXMYASADKAsyIS5jbGllbnRfdG9fc2VydmVyLlJlc3BvbnNlLlByZUtleVIHcHJla2V5'
    'cxpgCgJPaxIUCgROb25lGAEgASgISABSBE5vbmUSPgoHcHJla2V5cxgCIAEoCzIiLmNsaWVudF'
    '90b19zZXJ2ZXIuUmVzcG9uc2UuUHJla2V5c0gAUgdwcmVrZXlzQgQKAk9rQgoKCFJlc3BvbnNl');

