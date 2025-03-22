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
    {'1': 'downloaddata', '3': 5, '4': 1, '5': 11, '6': '.server_to_client.DownloadData', '9': 0, '10': 'downloaddata'},
    {'1': 'error', '3': 6, '4': 1, '5': 14, '6': '.error.ErrorCode', '9': 0, '10': 'error'},
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
    'QgASgISABSEVJlcXVlc3ROZXdQcmVLZXlzEkQKDGRvd25sb2FkZGF0YRgFIAEoCzIeLnNlcnZl'
    'cl90b19jbGllbnQuRG93bmxvYWREYXRhSABSDGRvd25sb2FkZGF0YRIoCgVlcnJvchgGIAEoDj'
    'IQLmVycm9yLkVycm9yQ29kZUgAUgVlcnJvckIGCgRLaW5k');

@$core.Deprecated('Use newMessageDescriptor instead')
const NewMessage$json = {
  '1': 'NewMessage',
  '2': [
    {'1': 'from_user_id', '3': 2, '4': 1, '5': 3, '10': 'fromUserId'},
    {'1': 'body', '3': 1, '4': 1, '5': 12, '10': 'body'},
  ],
};

/// Descriptor for `NewMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List newMessageDescriptor = $convert.base64Decode(
    'CgpOZXdNZXNzYWdlEiAKDGZyb21fdXNlcl9pZBgCIAEoA1IKZnJvbVVzZXJJZBISCgRib2R5GA'
    'EgASgMUgRib2R5');

@$core.Deprecated('Use downloadDataDescriptor instead')
const DownloadData$json = {
  '1': 'DownloadData',
  '2': [
    {'1': 'download_token', '3': 1, '4': 1, '5': 12, '10': 'downloadToken'},
    {'1': 'offset', '3': 2, '4': 1, '5': 13, '10': 'offset'},
    {'1': 'data', '3': 3, '4': 1, '5': 12, '10': 'data'},
    {'1': 'fin', '3': 4, '4': 1, '5': 8, '10': 'fin'},
  ],
};

/// Descriptor for `DownloadData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List downloadDataDescriptor = $convert.base64Decode(
    'CgxEb3dubG9hZERhdGESJQoOZG93bmxvYWRfdG9rZW4YASABKAxSDWRvd25sb2FkVG9rZW4SFg'
    'oGb2Zmc2V0GAIgASgNUgZvZmZzZXQSEgoEZGF0YRgDIAEoDFIEZGF0YRIQCgNmaW4YBCABKAhS'
    'A2Zpbg==');

@$core.Deprecated('Use responseDescriptor instead')
const Response$json = {
  '1': 'Response',
  '2': [
    {'1': 'ok', '3': 1, '4': 1, '5': 11, '6': '.server_to_client.Response.Ok', '9': 0, '10': 'ok'},
    {'1': 'error', '3': 2, '4': 1, '5': 14, '6': '.error.ErrorCode', '9': 0, '10': 'error'},
  ],
  '3': [Response_Location$json, Response_PreKey$json, Response_UserData$json, Response_UploadToken$json, Response_Ok$json],
  '8': [
    {'1': 'Response'},
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_Location$json = {
  '1': 'Location',
  '2': [
    {'1': 'county', '3': 1, '4': 1, '5': 9, '10': 'county'},
    {'1': 'region', '3': 2, '4': 1, '5': 9, '10': 'region'},
    {'1': 'city', '3': 3, '4': 1, '5': 9, '10': 'city'},
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
const Response_UserData$json = {
  '1': 'UserData',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 3, '10': 'userId'},
    {'1': 'prekeys', '3': 2, '4': 3, '5': 11, '6': '.server_to_client.Response.PreKey', '10': 'prekeys'},
    {'1': 'username', '3': 7, '4': 1, '5': 12, '9': 0, '10': 'username', '17': true},
    {'1': 'public_identity_key', '3': 3, '4': 1, '5': 12, '9': 1, '10': 'publicIdentityKey', '17': true},
    {'1': 'signed_prekey', '3': 4, '4': 1, '5': 12, '9': 2, '10': 'signedPrekey', '17': true},
    {'1': 'signed_prekey_signature', '3': 5, '4': 1, '5': 12, '9': 3, '10': 'signedPrekeySignature', '17': true},
    {'1': 'signed_prekey_id', '3': 6, '4': 1, '5': 3, '9': 4, '10': 'signedPrekeyId', '17': true},
  ],
  '8': [
    {'1': '_username'},
    {'1': '_public_identity_key'},
    {'1': '_signed_prekey'},
    {'1': '_signed_prekey_signature'},
    {'1': '_signed_prekey_id'},
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_UploadToken$json = {
  '1': 'UploadToken',
  '2': [
    {'1': 'upload_token', '3': 1, '4': 1, '5': 12, '10': 'uploadToken'},
    {'1': 'download_tokens', '3': 2, '4': 3, '5': 12, '10': 'downloadTokens'},
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_Ok$json = {
  '1': 'Ok',
  '2': [
    {'1': 'None', '3': 1, '4': 1, '5': 8, '9': 0, '10': 'None'},
    {'1': 'userid', '3': 2, '4': 1, '5': 3, '9': 0, '10': 'userid'},
    {'1': 'authchallenge', '3': 3, '4': 1, '5': 12, '9': 0, '10': 'authchallenge'},
    {'1': 'uploadtoken', '3': 4, '4': 1, '5': 11, '6': '.server_to_client.Response.UploadToken', '9': 0, '10': 'uploadtoken'},
    {'1': 'userdata', '3': 5, '4': 1, '5': 11, '6': '.server_to_client.Response.UserData', '9': 0, '10': 'userdata'},
    {'1': 'authtoken', '3': 6, '4': 1, '5': 12, '9': 0, '10': 'authtoken'},
    {'1': 'location', '3': 7, '4': 1, '5': 11, '6': '.server_to_client.Response.Location', '9': 0, '10': 'location'},
  ],
  '8': [
    {'1': 'Ok'},
  ],
};

/// Descriptor for `Response`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseDescriptor = $convert.base64Decode(
    'CghSZXNwb25zZRIvCgJvaxgBIAEoCzIdLnNlcnZlcl90b19jbGllbnQuUmVzcG9uc2UuT2tIAF'
    'ICb2sSKAoFZXJyb3IYAiABKA4yEC5lcnJvci5FcnJvckNvZGVIAFIFZXJyb3IaTgoITG9jYXRp'
    'b24SFgoGY291bnR5GAEgASgJUgZjb3VudHkSFgoGcmVnaW9uGAIgASgJUgZyZWdpb24SEgoEY2'
    'l0eRgDIAEoCVIEY2l0eRowCgZQcmVLZXkSDgoCaWQYASABKANSAmlkEhYKBnByZWtleRgCIAEo'
    'DFIGcHJla2V5GrQDCghVc2VyRGF0YRIXCgd1c2VyX2lkGAEgASgDUgZ1c2VySWQSOwoHcHJla2'
    'V5cxgCIAMoCzIhLnNlcnZlcl90b19jbGllbnQuUmVzcG9uc2UuUHJlS2V5UgdwcmVrZXlzEh8K'
    'CHVzZXJuYW1lGAcgASgMSABSCHVzZXJuYW1liAEBEjMKE3B1YmxpY19pZGVudGl0eV9rZXkYAy'
    'ABKAxIAVIRcHVibGljSWRlbnRpdHlLZXmIAQESKAoNc2lnbmVkX3ByZWtleRgEIAEoDEgCUgxz'
    'aWduZWRQcmVrZXmIAQESOwoXc2lnbmVkX3ByZWtleV9zaWduYXR1cmUYBSABKAxIA1IVc2lnbm'
    'VkUHJla2V5U2lnbmF0dXJliAEBEi0KEHNpZ25lZF9wcmVrZXlfaWQYBiABKANIBFIOc2lnbmVk'
    'UHJla2V5SWSIAQFCCwoJX3VzZXJuYW1lQhYKFF9wdWJsaWNfaWRlbnRpdHlfa2V5QhAKDl9zaW'
    'duZWRfcHJla2V5QhoKGF9zaWduZWRfcHJla2V5X3NpZ25hdHVyZUITChFfc2lnbmVkX3ByZWtl'
    'eV9pZBpZCgtVcGxvYWRUb2tlbhIhCgx1cGxvYWRfdG9rZW4YASABKAxSC3VwbG9hZFRva2VuEi'
    'cKD2Rvd25sb2FkX3Rva2VucxgCIAMoDFIOZG93bmxvYWRUb2tlbnMa1AIKAk9rEhQKBE5vbmUY'
    'ASABKAhIAFIETm9uZRIYCgZ1c2VyaWQYAiABKANIAFIGdXNlcmlkEiYKDWF1dGhjaGFsbGVuZ2'
    'UYAyABKAxIAFINYXV0aGNoYWxsZW5nZRJKCgt1cGxvYWR0b2tlbhgEIAEoCzImLnNlcnZlcl90'
    'b19jbGllbnQuUmVzcG9uc2UuVXBsb2FkVG9rZW5IAFILdXBsb2FkdG9rZW4SQQoIdXNlcmRhdG'
    'EYBSABKAsyIy5zZXJ2ZXJfdG9fY2xpZW50LlJlc3BvbnNlLlVzZXJEYXRhSABSCHVzZXJkYXRh'
    'Eh4KCWF1dGh0b2tlbhgGIAEoDEgAUglhdXRodG9rZW4SQQoIbG9jYXRpb24YByABKAsyIy5zZX'
    'J2ZXJfdG9fY2xpZW50LlJlc3BvbnNlLkxvY2F0aW9uSABSCGxvY2F0aW9uQgQKAk9rQgoKCFJl'
    'c3BvbnNl');

