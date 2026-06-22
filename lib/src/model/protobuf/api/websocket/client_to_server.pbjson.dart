// This is a generated file - do not edit.
//
// Generated from api/websocket/client_to_server.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use clientToServerDescriptor instead')
const ClientToServer$json = {
  '1': 'ClientToServer',
  '2': [
    {
      '1': 'V0',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.V0',
      '9': 0,
      '10': 'V0'
    },
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
    {
      '1': 'handshake',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.Handshake',
      '9': 0,
      '10': 'handshake'
    },
    {
      '1': 'applicationdata',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData',
      '9': 0,
      '10': 'applicationdata'
    },
    {
      '1': 'response',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.Response',
      '9': 0,
      '10': 'response'
    },
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
    {
      '1': 'register',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.Handshake.Register',
      '9': 0,
      '10': 'register'
    },
    {
      '1': 'getAuthChallenge',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.Handshake.GetAuthChallenge',
      '9': 0,
      '10': 'getAuthChallenge'
    },
    {
      '1': 'getAuthToken',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.Handshake.GetAuthToken',
      '9': 0,
      '10': 'getAuthToken'
    },
    {
      '1': 'authenticate',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.Handshake.Authenticate',
      '9': 0,
      '10': 'authenticate'
    },
    {
      '1': 'requestPOW',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.Handshake.RequestPOW',
      '9': 0,
      '10': 'requestPOW'
    },
    {
      '1': 'authenticate_with_login_token',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.Handshake.AuthenticateWithLoginToken',
      '9': 0,
      '10': 'authenticateWithLoginToken'
    },
    {
      '1': 'get_userid_by_username',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.Handshake.GetUserIdByUsername',
      '9': 0,
      '10': 'getUseridByUsername'
    },
    {
      '1': 'get_server_key_for_passwordless_recovery',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.Handshake.GetServerKeyForPasswordLessRecovery',
      '9': 0,
      '10': 'getServerKeyForPasswordlessRecovery'
    },
    {
      '1': 'register_passwordless_notification',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.Handshake.RegisterPasswordlessNotification',
      '9': 0,
      '10': 'registerPasswordlessNotification'
    },
    {
      '1': 'check_for_passwordless_notification',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.Handshake.CheckForPasswordlessNotification',
      '9': 0,
      '10': 'checkForPasswordlessNotification'
    },
  ],
  '3': [
    Handshake_RequestPOW$json,
    Handshake_Register$json,
    Handshake_GetAuthChallenge$json,
    Handshake_GetUserIdByUsername$json,
    Handshake_GetAuthToken$json,
    Handshake_Authenticate$json,
    Handshake_AuthenticateWithLoginToken$json,
    Handshake_GetServerKeyForPasswordLessRecovery$json,
    Handshake_RegisterPasswordlessNotification$json,
    Handshake_CheckForPasswordlessNotification$json
  ],
  '8': [
    {'1': 'Handshake'},
  ],
};

@$core.Deprecated('Use handshakeDescriptor instead')
const Handshake_RequestPOW$json = {
  '1': 'RequestPOW',
};

@$core.Deprecated('Use handshakeDescriptor instead')
const Handshake_Register$json = {
  '1': 'Register',
  '2': [
    {'1': 'username', '3': 1, '4': 1, '5': 9, '10': 'username'},
    {
      '1': 'invite_code',
      '3': 2,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'inviteCode',
      '17': true
    },
    {
      '1': 'public_identity_key',
      '3': 3,
      '4': 1,
      '5': 12,
      '10': 'publicIdentityKey'
    },
    {'1': 'signed_prekey', '3': 4, '4': 1, '5': 12, '10': 'signedPrekey'},
    {
      '1': 'signed_prekey_signature',
      '3': 5,
      '4': 1,
      '5': 12,
      '10': 'signedPrekeySignature'
    },
    {'1': 'signed_prekey_id', '3': 6, '4': 1, '5': 3, '10': 'signedPrekeyId'},
    {'1': 'registration_id', '3': 7, '4': 1, '5': 3, '10': 'registrationId'},
    {'1': 'is_ios', '3': 8, '4': 1, '5': 8, '10': 'isIos'},
    {'1': 'lang_code', '3': 9, '4': 1, '5': 9, '10': 'langCode'},
    {'1': 'proof_of_work', '3': 10, '4': 1, '5': 3, '10': 'proofOfWork'},
    {
      '1': 'login_token',
      '3': 11,
      '4': 1,
      '5': 12,
      '9': 1,
      '10': 'loginToken',
      '17': true
    },
  ],
  '8': [
    {'1': '_invite_code'},
    {'1': '_login_token'},
  ],
};

@$core.Deprecated('Use handshakeDescriptor instead')
const Handshake_GetAuthChallenge$json = {
  '1': 'GetAuthChallenge',
};

@$core.Deprecated('Use handshakeDescriptor instead')
const Handshake_GetUserIdByUsername$json = {
  '1': 'GetUserIdByUsername',
  '2': [
    {'1': 'username', '3': 1, '4': 1, '5': 9, '10': 'username'},
  ],
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
    {
      '1': 'app_version',
      '3': 3,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'appVersion',
      '17': true
    },
    {
      '1': 'device_id',
      '3': 4,
      '4': 1,
      '5': 3,
      '9': 1,
      '10': 'deviceId',
      '17': true
    },
    {
      '1': 'in_background',
      '3': 5,
      '4': 1,
      '5': 8,
      '9': 2,
      '10': 'inBackground',
      '17': true
    },
  ],
  '8': [
    {'1': '_app_version'},
    {'1': '_device_id'},
    {'1': '_in_background'},
  ],
};

@$core.Deprecated('Use handshakeDescriptor instead')
const Handshake_AuthenticateWithLoginToken$json = {
  '1': 'AuthenticateWithLoginToken',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 3, '10': 'userId'},
    {
      '1': 'secret_login_token',
      '3': 2,
      '4': 1,
      '5': 12,
      '10': 'secretLoginToken'
    },
    {'1': 'app_version', '3': 3, '4': 1, '5': 9, '10': 'appVersion'},
    {'1': 'device_id', '3': 4, '4': 1, '5': 3, '10': 'deviceId'},
    {'1': 'in_background', '3': 5, '4': 1, '5': 8, '10': 'inBackground'},
  ],
};

@$core.Deprecated('Use handshakeDescriptor instead')
const Handshake_GetServerKeyForPasswordLessRecovery$json = {
  '1': 'GetServerKeyForPasswordLessRecovery',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 3, '10': 'userId'},
    {
      '1': 'encrypted_server_key_none',
      '3': 2,
      '4': 1,
      '5': 12,
      '10': 'encryptedServerKeyNone'
    },
    {
      '1': 'pin_unlock_token',
      '3': 3,
      '4': 1,
      '5': 12,
      '9': 0,
      '10': 'pinUnlockToken',
      '17': true
    },
    {
      '1': 'pin_protection_key',
      '3': 4,
      '4': 1,
      '5': 12,
      '9': 1,
      '10': 'pinProtectionKey',
      '17': true
    },
    {'1': 'email', '3': 5, '4': 1, '5': 9, '9': 2, '10': 'email', '17': true},
  ],
  '8': [
    {'1': '_pin_unlock_token'},
    {'1': '_pin_protection_key'},
    {'1': '_email'},
  ],
};

@$core.Deprecated('Use handshakeDescriptor instead')
const Handshake_RegisterPasswordlessNotification$json = {
  '1': 'RegisterPasswordlessNotification',
  '2': [
    {'1': 'notification_id', '3': 1, '4': 1, '5': 9, '10': 'notificationId'},
    {
      '1': 'download_auth_token',
      '3': 2,
      '4': 1,
      '5': 12,
      '10': 'downloadAuthToken'
    },
    {'1': 'lang_code', '3': 3, '4': 1, '5': 9, '10': 'langCode'},
    {
      '1': 'google_fcm',
      '3': 4,
      '4': 1,
      '5': 9,
      '9': 0,
      '10': 'googleFcm',
      '17': true
    },
  ],
  '8': [
    {'1': '_google_fcm'},
  ],
};

@$core.Deprecated('Use handshakeDescriptor instead')
const Handshake_CheckForPasswordlessNotification$json = {
  '1': 'CheckForPasswordlessNotification',
  '2': [
    {'1': 'notification_id', '3': 1, '4': 1, '5': 9, '10': 'notificationId'},
    {
      '1': 'download_auth_token',
      '3': 2,
      '4': 1,
      '5': 12,
      '10': 'downloadAuthToken'
    },
    {
      '1': 'already_received_message_ids',
      '3': 3,
      '4': 3,
      '5': 3,
      '10': 'alreadyReceivedMessageIds'
    },
  ],
};

/// Descriptor for `Handshake`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List handshakeDescriptor = $convert.base64Decode(
    'CglIYW5kc2hha2USQgoIcmVnaXN0ZXIYASABKAsyJC5jbGllbnRfdG9fc2VydmVyLkhhbmRzaG'
    'FrZS5SZWdpc3RlckgAUghyZWdpc3RlchJaChBnZXRBdXRoQ2hhbGxlbmdlGAIgASgLMiwuY2xp'
    'ZW50X3RvX3NlcnZlci5IYW5kc2hha2UuR2V0QXV0aENoYWxsZW5nZUgAUhBnZXRBdXRoQ2hhbG'
    'xlbmdlEk4KDGdldEF1dGhUb2tlbhgDIAEoCzIoLmNsaWVudF90b19zZXJ2ZXIuSGFuZHNoYWtl'
    'LkdldEF1dGhUb2tlbkgAUgxnZXRBdXRoVG9rZW4STgoMYXV0aGVudGljYXRlGAQgASgLMiguY2'
    'xpZW50X3RvX3NlcnZlci5IYW5kc2hha2UuQXV0aGVudGljYXRlSABSDGF1dGhlbnRpY2F0ZRJI'
    'CgpyZXF1ZXN0UE9XGAUgASgLMiYuY2xpZW50X3RvX3NlcnZlci5IYW5kc2hha2UuUmVxdWVzdF'
    'BPV0gAUgpyZXF1ZXN0UE9XEnsKHWF1dGhlbnRpY2F0ZV93aXRoX2xvZ2luX3Rva2VuGAYgASgL'
    'MjYuY2xpZW50X3RvX3NlcnZlci5IYW5kc2hha2UuQXV0aGVudGljYXRlV2l0aExvZ2luVG9rZW'
    '5IAFIaYXV0aGVudGljYXRlV2l0aExvZ2luVG9rZW4SZgoWZ2V0X3VzZXJpZF9ieV91c2VybmFt'
    'ZRgHIAEoCzIvLmNsaWVudF90b19zZXJ2ZXIuSGFuZHNoYWtlLkdldFVzZXJJZEJ5VXNlcm5hbW'
    'VIAFITZ2V0VXNlcmlkQnlVc2VybmFtZRKYAQooZ2V0X3NlcnZlcl9rZXlfZm9yX3Bhc3N3b3Jk'
    'bGVzc19yZWNvdmVyeRgIIAEoCzI/LmNsaWVudF90b19zZXJ2ZXIuSGFuZHNoYWtlLkdldFNlcn'
    'ZlcktleUZvclBhc3N3b3JkTGVzc1JlY292ZXJ5SABSI2dldFNlcnZlcktleUZvclBhc3N3b3Jk'
    'bGVzc1JlY292ZXJ5EowBCiJyZWdpc3Rlcl9wYXNzd29yZGxlc3Nfbm90aWZpY2F0aW9uGAkgAS'
    'gLMjwuY2xpZW50X3RvX3NlcnZlci5IYW5kc2hha2UuUmVnaXN0ZXJQYXNzd29yZGxlc3NOb3Rp'
    'ZmljYXRpb25IAFIgcmVnaXN0ZXJQYXNzd29yZGxlc3NOb3RpZmljYXRpb24SjQEKI2NoZWNrX2'
    'Zvcl9wYXNzd29yZGxlc3Nfbm90aWZpY2F0aW9uGAogASgLMjwuY2xpZW50X3RvX3NlcnZlci5I'
    'YW5kc2hha2UuQ2hlY2tGb3JQYXNzd29yZGxlc3NOb3RpZmljYXRpb25IAFIgY2hlY2tGb3JQYX'
    'Nzd29yZGxlc3NOb3RpZmljYXRpb24aDAoKUmVxdWVzdFBPVxrKAwoIUmVnaXN0ZXISGgoIdXNl'
    'cm5hbWUYASABKAlSCHVzZXJuYW1lEiQKC2ludml0ZV9jb2RlGAIgASgJSABSCmludml0ZUNvZG'
    'WIAQESLgoTcHVibGljX2lkZW50aXR5X2tleRgDIAEoDFIRcHVibGljSWRlbnRpdHlLZXkSIwoN'
    'c2lnbmVkX3ByZWtleRgEIAEoDFIMc2lnbmVkUHJla2V5EjYKF3NpZ25lZF9wcmVrZXlfc2lnbm'
    'F0dXJlGAUgASgMUhVzaWduZWRQcmVrZXlTaWduYXR1cmUSKAoQc2lnbmVkX3ByZWtleV9pZBgG'
    'IAEoA1IOc2lnbmVkUHJla2V5SWQSJwoPcmVnaXN0cmF0aW9uX2lkGAcgASgDUg5yZWdpc3RyYX'
    'Rpb25JZBIVCgZpc19pb3MYCCABKAhSBWlzSW9zEhsKCWxhbmdfY29kZRgJIAEoCVIIbGFuZ0Nv'
    'ZGUSIgoNcHJvb2Zfb2Zfd29yaxgKIAEoA1ILcHJvb2ZPZldvcmsSJAoLbG9naW5fdG9rZW4YCy'
    'ABKAxIAVIKbG9naW5Ub2tlbogBAUIOCgxfaW52aXRlX2NvZGVCDgoMX2xvZ2luX3Rva2VuGhIK'
    'EEdldEF1dGhDaGFsbGVuZ2UaMQoTR2V0VXNlcklkQnlVc2VybmFtZRIaCgh1c2VybmFtZRgBIA'
    'EoCVIIdXNlcm5hbWUaQwoMR2V0QXV0aFRva2VuEhcKB3VzZXJfaWQYASABKANSBnVzZXJJZBIa'
    'CghyZXNwb25zZRgCIAEoDFIIcmVzcG9uc2Ua6AEKDEF1dGhlbnRpY2F0ZRIXCgd1c2VyX2lkGA'
    'EgASgDUgZ1c2VySWQSHQoKYXV0aF90b2tlbhgCIAEoDFIJYXV0aFRva2VuEiQKC2FwcF92ZXJz'
    'aW9uGAMgASgJSABSCmFwcFZlcnNpb26IAQESIAoJZGV2aWNlX2lkGAQgASgDSAFSCGRldmljZU'
    'lkiAEBEigKDWluX2JhY2tncm91bmQYBSABKAhIAlIMaW5CYWNrZ3JvdW5kiAEBQg4KDF9hcHBf'
    'dmVyc2lvbkIMCgpfZGV2aWNlX2lkQhAKDl9pbl9iYWNrZ3JvdW5kGsYBChpBdXRoZW50aWNhdG'
    'VXaXRoTG9naW5Ub2tlbhIXCgd1c2VyX2lkGAEgASgDUgZ1c2VySWQSLAoSc2VjcmV0X2xvZ2lu'
    'X3Rva2VuGAIgASgMUhBzZWNyZXRMb2dpblRva2VuEh8KC2FwcF92ZXJzaW9uGAMgASgJUgphcH'
    'BWZXJzaW9uEhsKCWRldmljZV9pZBgEIAEoA1IIZGV2aWNlSWQSIwoNaW5fYmFja2dyb3VuZBgF'
    'IAEoCFIMaW5CYWNrZ3JvdW5kGqwCCiNHZXRTZXJ2ZXJLZXlGb3JQYXNzd29yZExlc3NSZWNvdm'
    'VyeRIXCgd1c2VyX2lkGAEgASgDUgZ1c2VySWQSOQoZZW5jcnlwdGVkX3NlcnZlcl9rZXlfbm9u'
    'ZRgCIAEoDFIWZW5jcnlwdGVkU2VydmVyS2V5Tm9uZRItChBwaW5fdW5sb2NrX3Rva2VuGAMgAS'
    'gMSABSDnBpblVubG9ja1Rva2VuiAEBEjEKEnBpbl9wcm90ZWN0aW9uX2tleRgEIAEoDEgBUhBw'
    'aW5Qcm90ZWN0aW9uS2V5iAEBEhkKBWVtYWlsGAUgASgJSAJSBWVtYWlsiAEBQhMKEV9waW5fdW'
    '5sb2NrX3Rva2VuQhUKE19waW5fcHJvdGVjdGlvbl9rZXlCCAoGX2VtYWlsGssBCiBSZWdpc3Rl'
    'clBhc3N3b3JkbGVzc05vdGlmaWNhdGlvbhInCg9ub3RpZmljYXRpb25faWQYASABKAlSDm5vdG'
    'lmaWNhdGlvbklkEi4KE2Rvd25sb2FkX2F1dGhfdG9rZW4YAiABKAxSEWRvd25sb2FkQXV0aFRv'
    'a2VuEhsKCWxhbmdfY29kZRgDIAEoCVIIbGFuZ0NvZGUSIgoKZ29vZ2xlX2ZjbRgEIAEoCUgAUg'
    'lnb29nbGVGY22IAQFCDQoLX2dvb2dsZV9mY20avAEKIENoZWNrRm9yUGFzc3dvcmRsZXNzTm90'
    'aWZpY2F0aW9uEicKD25vdGlmaWNhdGlvbl9pZBgBIAEoCVIObm90aWZpY2F0aW9uSWQSLgoTZG'
    '93bmxvYWRfYXV0aF90b2tlbhgCIAEoDFIRZG93bmxvYWRBdXRoVG9rZW4SPwocYWxyZWFkeV9y'
    'ZWNlaXZlZF9tZXNzYWdlX2lkcxgDIAMoA1IZYWxyZWFkeVJlY2VpdmVkTWVzc2FnZUlkc0ILCg'
    'lIYW5kc2hha2U=');

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData$json = {
  '1': 'ApplicationData',
  '2': [
    {
      '1': 'textMessage',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.TextMessage',
      '9': 0,
      '10': 'textMessage'
    },
    {
      '1': 'getUserByUsername',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.GetUserByUsername',
      '9': 0,
      '10': 'getUserByUsername'
    },
    {
      '1': 'getPrekeysByUserId',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.GetPrekeysByUserId',
      '9': 0,
      '10': 'getPrekeysByUserId'
    },
    {
      '1': 'getUserById',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.GetUserById',
      '9': 0,
      '10': 'getUserById'
    },
    {
      '1': 'updateGoogleFcmToken',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.UpdateGoogleFcmToken',
      '9': 0,
      '10': 'updateGoogleFcmToken'
    },
    {
      '1': 'deprecated_9',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.Deprecated',
      '9': 0,
      '10': 'deprecated9'
    },
    {
      '1': 'getCurrentPlanInfos',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.GetCurrentPlanInfos',
      '9': 0,
      '10': 'getCurrentPlanInfos'
    },
    {
      '1': 'deprecated_11',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.Deprecated',
      '9': 0,
      '10': 'deprecated11'
    },
    {
      '1': 'getAvailablePlans',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.GetAvailablePlans',
      '9': 0,
      '10': 'getAvailablePlans'
    },
    {
      '1': 'deprecated_13',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.Deprecated',
      '9': 0,
      '10': 'deprecated13'
    },
    {
      '1': 'deprecated_14',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.Deprecated',
      '9': 0,
      '10': 'deprecated14'
    },
    {
      '1': 'deprecated_15',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.Deprecated',
      '9': 0,
      '10': 'deprecated15'
    },
    {
      '1': 'deprecated_16',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.Deprecated',
      '9': 0,
      '10': 'deprecated16'
    },
    {
      '1': 'deprecated_17',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.Deprecated',
      '9': 0,
      '10': 'deprecated17'
    },
    {
      '1': 'deprecated_19',
      '3': 19,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.Deprecated',
      '9': 0,
      '10': 'deprecated19'
    },
    {
      '1': 'downloadDone',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.DownloadDone',
      '9': 0,
      '10': 'downloadDone'
    },
    {
      '1': 'getSignedPrekeyByUserid',
      '3': 22,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.GetSignedPreKeyByUserId',
      '9': 0,
      '10': 'getSignedPrekeyByUserid'
    },
    {
      '1': 'updateSignedPrekey',
      '3': 23,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.UpdateSignedPreKey',
      '9': 0,
      '10': 'updateSignedPrekey'
    },
    {
      '1': 'deleteAccount',
      '3': 24,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.DeleteAccount',
      '9': 0,
      '10': 'deleteAccount'
    },
    {
      '1': 'reportUser',
      '3': 25,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.ReportUser',
      '9': 0,
      '10': 'reportUser'
    },
    {
      '1': 'changeUsername',
      '3': 26,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.ChangeUsername',
      '9': 0,
      '10': 'changeUsername'
    },
    {
      '1': 'ipaPurchase',
      '3': 27,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.IPAPurchase',
      '9': 0,
      '10': 'ipaPurchase'
    },
    {
      '1': 'ipaForceCheck',
      '3': 28,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.IPAForceCheck',
      '9': 0,
      '10': 'ipaForceCheck'
    },
    {
      '1': 'removeAdditionalUser',
      '3': 18,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.RemoveAdditionalUser',
      '9': 0,
      '10': 'removeAdditionalUser'
    },
    {
      '1': 'addAdditionalUser',
      '3': 29,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.AddAdditionalUser',
      '9': 0,
      '10': 'addAdditionalUser'
    },
    {
      '1': 'set_login_token',
      '3': 30,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.SetLoginToken',
      '9': 0,
      '10': 'setLoginToken'
    },
    {
      '1': 'register_passwordless_recovery',
      '3': 31,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.RegisterPasswordLessRecovery',
      '9': 0,
      '10': 'registerPasswordlessRecovery'
    },
    {
      '1': 'passwordless_notification',
      '3': 32,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.PasswordlessNotification',
      '9': 0,
      '10': 'passwordlessNotification'
    },
  ],
  '3': [
    ApplicationData_TextMessage$json,
    ApplicationData_GetUserByUsername$json,
    ApplicationData_ChangeUsername$json,
    ApplicationData_UpdateGoogleFcmToken$json,
    ApplicationData_GetUserById$json,
    ApplicationData_GetAvailablePlans$json,
    ApplicationData_GetAddAccountsInvites$json,
    ApplicationData_GetCurrentPlanInfos$json,
    ApplicationData_RemoveAdditionalUser$json,
    ApplicationData_GetPrekeysByUserId$json,
    ApplicationData_GetSignedPreKeyByUserId$json,
    ApplicationData_UpdateSignedPreKey$json,
    ApplicationData_DownloadDone$json,
    ApplicationData_ReportUser$json,
    ApplicationData_IPAPurchase$json,
    ApplicationData_IPAForceCheck$json,
    ApplicationData_DeleteAccount$json,
    ApplicationData_AddAdditionalUser$json,
    ApplicationData_SetLoginToken$json,
    ApplicationData_Deprecated$json,
    ApplicationData_RegisterPasswordLessRecovery$json,
    ApplicationData_PasswordlessNotification$json
  ],
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
    {
      '1': 'push_data',
      '3': 4,
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

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_GetUserByUsername$json = {
  '1': 'GetUserByUsername',
  '2': [
    {'1': 'username', '3': 1, '4': 1, '5': 9, '10': 'username'},
  ],
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_ChangeUsername$json = {
  '1': 'ChangeUsername',
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
const ApplicationData_GetAvailablePlans$json = {
  '1': 'GetAvailablePlans',
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_GetAddAccountsInvites$json = {
  '1': 'GetAddAccountsInvites',
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_GetCurrentPlanInfos$json = {
  '1': 'GetCurrentPlanInfos',
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_RemoveAdditionalUser$json = {
  '1': 'RemoveAdditionalUser',
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
const ApplicationData_GetSignedPreKeyByUserId$json = {
  '1': 'GetSignedPreKeyByUserId',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 3, '10': 'userId'},
  ],
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_UpdateSignedPreKey$json = {
  '1': 'UpdateSignedPreKey',
  '2': [
    {'1': 'signed_prekey_id', '3': 1, '4': 1, '5': 3, '10': 'signedPrekeyId'},
    {'1': 'signed_prekey', '3': 2, '4': 1, '5': 12, '10': 'signedPrekey'},
    {
      '1': 'signed_prekey_signature',
      '3': 3,
      '4': 1,
      '5': 12,
      '10': 'signedPrekeySignature'
    },
  ],
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_DownloadDone$json = {
  '1': 'DownloadDone',
  '2': [
    {'1': 'download_token', '3': 1, '4': 1, '5': 12, '10': 'downloadToken'},
  ],
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_ReportUser$json = {
  '1': 'ReportUser',
  '2': [
    {'1': 'reported_user_id', '3': 1, '4': 1, '5': 3, '10': 'reportedUserId'},
    {'1': 'reason', '3': 2, '4': 1, '5': 9, '10': 'reason'},
  ],
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_IPAPurchase$json = {
  '1': 'IPAPurchase',
  '2': [
    {'1': 'product_id', '3': 1, '4': 1, '5': 9, '10': 'productId'},
    {'1': 'source', '3': 2, '4': 1, '5': 9, '10': 'source'},
    {
      '1': 'verification_data',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'verificationData'
    },
  ],
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_IPAForceCheck$json = {
  '1': 'IPAForceCheck',
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_DeleteAccount$json = {
  '1': 'DeleteAccount',
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_AddAdditionalUser$json = {
  '1': 'AddAdditionalUser',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 3, '10': 'userId'},
  ],
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_SetLoginToken$json = {
  '1': 'SetLoginToken',
  '2': [
    {'1': 'login_token', '3': 1, '4': 1, '5': 12, '10': 'loginToken'},
  ],
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_Deprecated$json = {
  '1': 'Deprecated',
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_RegisterPasswordLessRecovery$json = {
  '1': 'RegisterPasswordLessRecovery',
  '2': [
    {
      '1': 'encryptedServerKey',
      '3': 1,
      '4': 1,
      '5': 12,
      '10': 'encryptedServerKey'
    },
    {
      '1': 'pinUnlockToken',
      '3': 2,
      '4': 1,
      '5': 12,
      '9': 0,
      '10': 'pinUnlockToken',
      '17': true
    },
  ],
  '8': [
    {'1': '_pinUnlockToken'},
  ],
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_PasswordlessNotification$json = {
  '1': 'PasswordlessNotification',
  '2': [
    {'1': 'notification_id', '3': 1, '4': 1, '5': 9, '10': 'notificationId'},
    {
      '1': 'encrypted_message',
      '3': 2,
      '4': 1,
      '5': 12,
      '10': 'encryptedMessage'
    },
  ],
};

/// Descriptor for `ApplicationData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List applicationDataDescriptor = $convert.base64Decode(
    'Cg9BcHBsaWNhdGlvbkRhdGESUQoLdGV4dE1lc3NhZ2UYASABKAsyLS5jbGllbnRfdG9fc2Vydm'
    'VyLkFwcGxpY2F0aW9uRGF0YS5UZXh0TWVzc2FnZUgAUgt0ZXh0TWVzc2FnZRJjChFnZXRVc2Vy'
    'QnlVc2VybmFtZRgCIAEoCzIzLmNsaWVudF90b19zZXJ2ZXIuQXBwbGljYXRpb25EYXRhLkdldF'
    'VzZXJCeVVzZXJuYW1lSABSEWdldFVzZXJCeVVzZXJuYW1lEmYKEmdldFByZWtleXNCeVVzZXJJ'
    'ZBgDIAEoCzI0LmNsaWVudF90b19zZXJ2ZXIuQXBwbGljYXRpb25EYXRhLkdldFByZWtleXNCeV'
    'VzZXJJZEgAUhJnZXRQcmVrZXlzQnlVc2VySWQSUQoLZ2V0VXNlckJ5SWQYBiABKAsyLS5jbGll'
    'bnRfdG9fc2VydmVyLkFwcGxpY2F0aW9uRGF0YS5HZXRVc2VyQnlJZEgAUgtnZXRVc2VyQnlJZB'
    'JsChR1cGRhdGVHb29nbGVGY21Ub2tlbhgIIAEoCzI2LmNsaWVudF90b19zZXJ2ZXIuQXBwbGlj'
    'YXRpb25EYXRhLlVwZGF0ZUdvb2dsZUZjbVRva2VuSABSFHVwZGF0ZUdvb2dsZUZjbVRva2VuEl'
    'EKDGRlcHJlY2F0ZWRfORgJIAEoCzIsLmNsaWVudF90b19zZXJ2ZXIuQXBwbGljYXRpb25EYXRh'
    'LkRlcHJlY2F0ZWRIAFILZGVwcmVjYXRlZDkSaQoTZ2V0Q3VycmVudFBsYW5JbmZvcxgKIAEoCz'
    'I1LmNsaWVudF90b19zZXJ2ZXIuQXBwbGljYXRpb25EYXRhLkdldEN1cnJlbnRQbGFuSW5mb3NI'
    'AFITZ2V0Q3VycmVudFBsYW5JbmZvcxJTCg1kZXByZWNhdGVkXzExGAsgASgLMiwuY2xpZW50X3'
    'RvX3NlcnZlci5BcHBsaWNhdGlvbkRhdGEuRGVwcmVjYXRlZEgAUgxkZXByZWNhdGVkMTESYwoR'
    'Z2V0QXZhaWxhYmxlUGxhbnMYDCABKAsyMy5jbGllbnRfdG9fc2VydmVyLkFwcGxpY2F0aW9uRG'
    'F0YS5HZXRBdmFpbGFibGVQbGFuc0gAUhFnZXRBdmFpbGFibGVQbGFucxJTCg1kZXByZWNhdGVk'
    'XzEzGA0gASgLMiwuY2xpZW50X3RvX3NlcnZlci5BcHBsaWNhdGlvbkRhdGEuRGVwcmVjYXRlZE'
    'gAUgxkZXByZWNhdGVkMTMSUwoNZGVwcmVjYXRlZF8xNBgOIAEoCzIsLmNsaWVudF90b19zZXJ2'
    'ZXIuQXBwbGljYXRpb25EYXRhLkRlcHJlY2F0ZWRIAFIMZGVwcmVjYXRlZDE0ElMKDWRlcHJlY2'
    'F0ZWRfMTUYDyABKAsyLC5jbGllbnRfdG9fc2VydmVyLkFwcGxpY2F0aW9uRGF0YS5EZXByZWNh'
    'dGVkSABSDGRlcHJlY2F0ZWQxNRJTCg1kZXByZWNhdGVkXzE2GBAgASgLMiwuY2xpZW50X3RvX3'
    'NlcnZlci5BcHBsaWNhdGlvbkRhdGEuRGVwcmVjYXRlZEgAUgxkZXByZWNhdGVkMTYSUwoNZGVw'
    'cmVjYXRlZF8xNxgRIAEoCzIsLmNsaWVudF90b19zZXJ2ZXIuQXBwbGljYXRpb25EYXRhLkRlcH'
    'JlY2F0ZWRIAFIMZGVwcmVjYXRlZDE3ElMKDWRlcHJlY2F0ZWRfMTkYEyABKAsyLC5jbGllbnRf'
    'dG9fc2VydmVyLkFwcGxpY2F0aW9uRGF0YS5EZXByZWNhdGVkSABSDGRlcHJlY2F0ZWQxORJUCg'
    'xkb3dubG9hZERvbmUYFCABKAsyLi5jbGllbnRfdG9fc2VydmVyLkFwcGxpY2F0aW9uRGF0YS5E'
    'b3dubG9hZERvbmVIAFIMZG93bmxvYWREb25lEnUKF2dldFNpZ25lZFByZWtleUJ5VXNlcmlkGB'
    'YgASgLMjkuY2xpZW50X3RvX3NlcnZlci5BcHBsaWNhdGlvbkRhdGEuR2V0U2lnbmVkUHJlS2V5'
    'QnlVc2VySWRIAFIXZ2V0U2lnbmVkUHJla2V5QnlVc2VyaWQSZgoSdXBkYXRlU2lnbmVkUHJla2'
    'V5GBcgASgLMjQuY2xpZW50X3RvX3NlcnZlci5BcHBsaWNhdGlvbkRhdGEuVXBkYXRlU2lnbmVk'
    'UHJlS2V5SABSEnVwZGF0ZVNpZ25lZFByZWtleRJXCg1kZWxldGVBY2NvdW50GBggASgLMi8uY2'
    'xpZW50X3RvX3NlcnZlci5BcHBsaWNhdGlvbkRhdGEuRGVsZXRlQWNjb3VudEgAUg1kZWxldGVB'
    'Y2NvdW50Ek4KCnJlcG9ydFVzZXIYGSABKAsyLC5jbGllbnRfdG9fc2VydmVyLkFwcGxpY2F0aW'
    '9uRGF0YS5SZXBvcnRVc2VySABSCnJlcG9ydFVzZXISWgoOY2hhbmdlVXNlcm5hbWUYGiABKAsy'
    'MC5jbGllbnRfdG9fc2VydmVyLkFwcGxpY2F0aW9uRGF0YS5DaGFuZ2VVc2VybmFtZUgAUg5jaG'
    'FuZ2VVc2VybmFtZRJRCgtpcGFQdXJjaGFzZRgbIAEoCzItLmNsaWVudF90b19zZXJ2ZXIuQXBw'
    'bGljYXRpb25EYXRhLklQQVB1cmNoYXNlSABSC2lwYVB1cmNoYXNlElcKDWlwYUZvcmNlQ2hlY2'
    'sYHCABKAsyLy5jbGllbnRfdG9fc2VydmVyLkFwcGxpY2F0aW9uRGF0YS5JUEFGb3JjZUNoZWNr'
    'SABSDWlwYUZvcmNlQ2hlY2sSbAoUcmVtb3ZlQWRkaXRpb25hbFVzZXIYEiABKAsyNi5jbGllbn'
    'RfdG9fc2VydmVyLkFwcGxpY2F0aW9uRGF0YS5SZW1vdmVBZGRpdGlvbmFsVXNlckgAUhRyZW1v'
    'dmVBZGRpdGlvbmFsVXNlchJjChFhZGRBZGRpdGlvbmFsVXNlchgdIAEoCzIzLmNsaWVudF90b1'
    '9zZXJ2ZXIuQXBwbGljYXRpb25EYXRhLkFkZEFkZGl0aW9uYWxVc2VySABSEWFkZEFkZGl0aW9u'
    'YWxVc2VyElkKD3NldF9sb2dpbl90b2tlbhgeIAEoCzIvLmNsaWVudF90b19zZXJ2ZXIuQXBwbG'
    'ljYXRpb25EYXRhLlNldExvZ2luVG9rZW5IAFINc2V0TG9naW5Ub2tlbhKGAQoecmVnaXN0ZXJf'
    'cGFzc3dvcmRsZXNzX3JlY292ZXJ5GB8gASgLMj4uY2xpZW50X3RvX3NlcnZlci5BcHBsaWNhdG'
    'lvbkRhdGEuUmVnaXN0ZXJQYXNzd29yZExlc3NSZWNvdmVyeUgAUhxyZWdpc3RlclBhc3N3b3Jk'
    'bGVzc1JlY292ZXJ5EnkKGXBhc3N3b3JkbGVzc19ub3RpZmljYXRpb24YICABKAsyOi5jbGllbn'
    'RfdG9fc2VydmVyLkFwcGxpY2F0aW9uRGF0YS5QYXNzd29yZGxlc3NOb3RpZmljYXRpb25IAFIY'
    'cGFzc3dvcmRsZXNzTm90aWZpY2F0aW9uGmoKC1RleHRNZXNzYWdlEhcKB3VzZXJfaWQYASABKA'
    'NSBnVzZXJJZBISCgRib2R5GAMgASgMUgRib2R5EiAKCXB1c2hfZGF0YRgEIAEoDEgAUghwdXNo'
    'RGF0YYgBAUIMCgpfcHVzaF9kYXRhGi8KEUdldFVzZXJCeVVzZXJuYW1lEhoKCHVzZXJuYW1lGA'
    'EgASgJUgh1c2VybmFtZRosCg5DaGFuZ2VVc2VybmFtZRIaCgh1c2VybmFtZRgBIAEoCVIIdXNl'
    'cm5hbWUaNQoUVXBkYXRlR29vZ2xlRmNtVG9rZW4SHQoKZ29vZ2xlX2ZjbRgBIAEoCVIJZ29vZ2'
    'xlRmNtGiYKC0dldFVzZXJCeUlkEhcKB3VzZXJfaWQYASABKANSBnVzZXJJZBoTChFHZXRBdmFp'
    'bGFibGVQbGFucxoXChVHZXRBZGRBY2NvdW50c0ludml0ZXMaFQoTR2V0Q3VycmVudFBsYW5Jbm'
    'ZvcxovChRSZW1vdmVBZGRpdGlvbmFsVXNlchIXCgd1c2VyX2lkGAEgASgDUgZ1c2VySWQaLQoS'
    'R2V0UHJla2V5c0J5VXNlcklkEhcKB3VzZXJfaWQYASABKANSBnVzZXJJZBoyChdHZXRTaWduZW'
    'RQcmVLZXlCeVVzZXJJZBIXCgd1c2VyX2lkGAEgASgDUgZ1c2VySWQamwEKElVwZGF0ZVNpZ25l'
    'ZFByZUtleRIoChBzaWduZWRfcHJla2V5X2lkGAEgASgDUg5zaWduZWRQcmVrZXlJZBIjCg1zaW'
    'duZWRfcHJla2V5GAIgASgMUgxzaWduZWRQcmVrZXkSNgoXc2lnbmVkX3ByZWtleV9zaWduYXR1'
    'cmUYAyABKAxSFXNpZ25lZFByZWtleVNpZ25hdHVyZRo1CgxEb3dubG9hZERvbmUSJQoOZG93bm'
    'xvYWRfdG9rZW4YASABKAxSDWRvd25sb2FkVG9rZW4aTgoKUmVwb3J0VXNlchIoChByZXBvcnRl'
    'ZF91c2VyX2lkGAEgASgDUg5yZXBvcnRlZFVzZXJJZBIWCgZyZWFzb24YAiABKAlSBnJlYXNvbh'
    'pxCgtJUEFQdXJjaGFzZRIdCgpwcm9kdWN0X2lkGAEgASgJUglwcm9kdWN0SWQSFgoGc291cmNl'
    'GAIgASgJUgZzb3VyY2USKwoRdmVyaWZpY2F0aW9uX2RhdGEYAyABKAlSEHZlcmlmaWNhdGlvbk'
    'RhdGEaDwoNSVBBRm9yY2VDaGVjaxoPCg1EZWxldGVBY2NvdW50GiwKEUFkZEFkZGl0aW9uYWxV'
    'c2VyEhcKB3VzZXJfaWQYASABKANSBnVzZXJJZBowCg1TZXRMb2dpblRva2VuEh8KC2xvZ2luX3'
    'Rva2VuGAEgASgMUgpsb2dpblRva2VuGgwKCkRlcHJlY2F0ZWQajgEKHFJlZ2lzdGVyUGFzc3dv'
    'cmRMZXNzUmVjb3ZlcnkSLgoSZW5jcnlwdGVkU2VydmVyS2V5GAEgASgMUhJlbmNyeXB0ZWRTZX'
    'J2ZXJLZXkSKwoOcGluVW5sb2NrVG9rZW4YAiABKAxIAFIOcGluVW5sb2NrVG9rZW6IAQFCEQoP'
    'X3BpblVubG9ja1Rva2VuGnAKGFBhc3N3b3JkbGVzc05vdGlmaWNhdGlvbhInCg9ub3RpZmljYX'
    'Rpb25faWQYASABKAlSDm5vdGlmaWNhdGlvbklkEisKEWVuY3J5cHRlZF9tZXNzYWdlGAIgASgM'
    'UhBlbmNyeXB0ZWRNZXNzYWdlQhEKD0FwcGxpY2F0aW9uRGF0YQ==');

@$core.Deprecated('Use responseDescriptor instead')
const Response$json = {
  '1': 'Response',
  '2': [
    {
      '1': 'ok',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.Response.Ok',
      '9': 0,
      '10': 'ok'
    },
    {
      '1': 'error',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.error.ErrorCode',
      '9': 0,
      '10': 'error'
    },
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
    {
      '1': 'prekeys',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.client_to_server.Response.PreKey',
      '10': 'prekeys'
    },
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_Ok$json = {
  '1': 'Ok',
  '2': [
    {'1': 'None', '3': 1, '4': 1, '5': 8, '9': 0, '10': 'None'},
    {
      '1': 'prekeys',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.Response.Prekeys',
      '9': 0,
      '10': 'prekeys'
    },
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
