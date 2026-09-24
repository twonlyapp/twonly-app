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
    Handshake_InitialPqcKeys$json,
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
      '9': 1,
      '10': 'publicIdentityKey',
      '17': true
    },
    {
      '1': 'signed_prekey',
      '3': 4,
      '4': 1,
      '5': 12,
      '9': 2,
      '10': 'signedPrekey',
      '17': true
    },
    {
      '1': 'signed_prekey_signature',
      '3': 5,
      '4': 1,
      '5': 12,
      '9': 3,
      '10': 'signedPrekeySignature',
      '17': true
    },
    {
      '1': 'signed_prekey_id',
      '3': 6,
      '4': 1,
      '5': 3,
      '9': 4,
      '10': 'signedPrekeyId',
      '17': true
    },
    {
      '1': 'registration_id',
      '3': 7,
      '4': 1,
      '5': 3,
      '9': 5,
      '10': 'registrationId',
      '17': true
    },
    {'1': 'is_ios', '3': 8, '4': 1, '5': 8, '10': 'isIos'},
    {'1': 'lang_code', '3': 9, '4': 1, '5': 9, '10': 'langCode'},
    {'1': 'proof_of_work', '3': 10, '4': 1, '5': 3, '10': 'proofOfWork'},
    {
      '1': 'login_token',
      '3': 11,
      '4': 1,
      '5': 12,
      '9': 6,
      '10': 'loginToken',
      '17': true
    },
    {
      '1': 'initial_pqc_keys',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.Handshake.InitialPqcKeys',
      '9': 7,
      '10': 'initialPqcKeys',
      '17': true
    },
  ],
  '8': [
    {'1': '_invite_code'},
    {'1': '_public_identity_key'},
    {'1': '_signed_prekey'},
    {'1': '_signed_prekey_signature'},
    {'1': '_signed_prekey_id'},
    {'1': '_registration_id'},
    {'1': '_login_token'},
    {'1': '_initial_pqc_keys'},
  ],
};

@$core.Deprecated('Use handshakeDescriptor instead')
const Handshake_InitialPqcKeys$json = {
  '1': 'InitialPqcKeys',
  '2': [
    {
      '1': 'public_identity_key',
      '3': 1,
      '4': 1,
      '5': 12,
      '10': 'publicIdentityKey'
    },
    {'1': 'registration_id', '3': 2, '4': 1, '5': 3, '10': 'registrationId'},
    {
      '1': 'ecc_signed_prekey_id',
      '3': 3,
      '4': 1,
      '5': 3,
      '10': 'eccSignedPrekeyId'
    },
    {
      '1': 'ecc_signed_prekey',
      '3': 4,
      '4': 1,
      '5': 12,
      '10': 'eccSignedPrekey'
    },
    {
      '1': 'ecc_signed_prekey_signature',
      '3': 5,
      '4': 1,
      '5': 12,
      '10': 'eccSignedPrekeySignature'
    },
    {
      '1': 'kyber_signed_prekey_id',
      '3': 6,
      '4': 1,
      '5': 3,
      '10': 'kyberSignedPrekeyId'
    },
    {
      '1': 'kyber_signed_prekey',
      '3': 7,
      '4': 1,
      '5': 12,
      '10': 'kyberSignedPrekey'
    },
    {
      '1': 'kyber_signed_prekey_signature',
      '3': 8,
      '4': 1,
      '5': 12,
      '10': 'kyberSignedPrekeySignature'
    },
    {
      '1': 'prekeys',
      '3': 9,
      '4': 3,
      '5': 11,
      '6': '.client_to_server.Handshake.InitialPqcKeys.PqcPreKey',
      '10': 'prekeys'
    },
  ],
  '3': [Handshake_InitialPqcKeys_PqcPreKey$json],
};

@$core.Deprecated('Use handshakeDescriptor instead')
const Handshake_InitialPqcKeys_PqcPreKey$json = {
  '1': 'PqcPreKey',
  '2': [
    {'1': 'ecc_pre_key_id', '3': 1, '4': 1, '5': 3, '10': 'eccPreKeyId'},
    {'1': 'ecc_pre_key', '3': 2, '4': 1, '5': 12, '10': 'eccPreKey'},
    {'1': 'kyber_pre_key_id', '3': 3, '4': 1, '5': 3, '10': 'kyberPreKeyId'},
    {'1': 'kyber_pre_key', '3': 4, '4': 1, '5': 12, '10': 'kyberPreKey'},
    {
      '1': 'kyber_pre_key_signature',
      '3': 5,
      '4': 1,
      '5': 12,
      '10': 'kyberPreKeySignature'
    },
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
    {
      '1': 'supports_mailbox_v2',
      '3': 6,
      '4': 1,
      '5': 8,
      '9': 3,
      '10': 'supportsMailboxV2',
      '17': true
    },
  ],
  '8': [
    {'1': '_app_version'},
    {'1': '_device_id'},
    {'1': '_in_background'},
    {'1': '_supports_mailbox_v2'},
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
    {
      '1': 'supports_mailbox_v2',
      '3': 6,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'supportsMailboxV2',
      '17': true
    },
  ],
  '8': [
    {'1': '_supports_mailbox_v2'},
  ],
};

@$core.Deprecated('Use handshakeDescriptor instead')
const Handshake_GetServerKeyForPasswordLessRecovery$json = {
  '1': 'GetServerKeyForPasswordLessRecovery',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 3, '10': 'userId'},
    {
      '1': 'server_key_protection',
      '3': 2,
      '4': 1,
      '5': 12,
      '10': 'serverKeyProtection'
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
    'Nzd29yZGxlc3NOb3RpZmljYXRpb24aDAoKUmVxdWVzdFBPVxrCBQoIUmVnaXN0ZXISGgoIdXNl'
    'cm5hbWUYASABKAlSCHVzZXJuYW1lEiQKC2ludml0ZV9jb2RlGAIgASgJSABSCmludml0ZUNvZG'
    'WIAQESMwoTcHVibGljX2lkZW50aXR5X2tleRgDIAEoDEgBUhFwdWJsaWNJZGVudGl0eUtleYgB'
    'ARIoCg1zaWduZWRfcHJla2V5GAQgASgMSAJSDHNpZ25lZFByZWtleYgBARI7ChdzaWduZWRfcH'
    'Jla2V5X3NpZ25hdHVyZRgFIAEoDEgDUhVzaWduZWRQcmVrZXlTaWduYXR1cmWIAQESLQoQc2ln'
    'bmVkX3ByZWtleV9pZBgGIAEoA0gEUg5zaWduZWRQcmVrZXlJZIgBARIsCg9yZWdpc3RyYXRpb2'
    '5faWQYByABKANIBVIOcmVnaXN0cmF0aW9uSWSIAQESFQoGaXNfaW9zGAggASgIUgVpc0lvcxIb'
    'CglsYW5nX2NvZGUYCSABKAlSCGxhbmdDb2RlEiIKDXByb29mX29mX3dvcmsYCiABKANSC3Byb2'
    '9mT2ZXb3JrEiQKC2xvZ2luX3Rva2VuGAsgASgMSAZSCmxvZ2luVG9rZW6IAQESWQoQaW5pdGlh'
    'bF9wcWNfa2V5cxgMIAEoCzIqLmNsaWVudF90b19zZXJ2ZXIuSGFuZHNoYWtlLkluaXRpYWxQcW'
    'NLZXlzSAdSDmluaXRpYWxQcWNLZXlziAEBQg4KDF9pbnZpdGVfY29kZUIWChRfcHVibGljX2lk'
    'ZW50aXR5X2tleUIQCg5fc2lnbmVkX3ByZWtleUIaChhfc2lnbmVkX3ByZWtleV9zaWduYXR1cm'
    'VCEwoRX3NpZ25lZF9wcmVrZXlfaWRCEgoQX3JlZ2lzdHJhdGlvbl9pZEIOCgxfbG9naW5fdG9r'
    'ZW5CEwoRX2luaXRpYWxfcHFjX2tleXMa1AUKDkluaXRpYWxQcWNLZXlzEi4KE3B1YmxpY19pZG'
    'VudGl0eV9rZXkYASABKAxSEXB1YmxpY0lkZW50aXR5S2V5EicKD3JlZ2lzdHJhdGlvbl9pZBgC'
    'IAEoA1IOcmVnaXN0cmF0aW9uSWQSLwoUZWNjX3NpZ25lZF9wcmVrZXlfaWQYAyABKANSEWVjY1'
    'NpZ25lZFByZWtleUlkEioKEWVjY19zaWduZWRfcHJla2V5GAQgASgMUg9lY2NTaWduZWRQcmVr'
    'ZXkSPQobZWNjX3NpZ25lZF9wcmVrZXlfc2lnbmF0dXJlGAUgASgMUhhlY2NTaWduZWRQcmVrZX'
    'lTaWduYXR1cmUSMwoWa3liZXJfc2lnbmVkX3ByZWtleV9pZBgGIAEoA1ITa3liZXJTaWduZWRQ'
    'cmVrZXlJZBIuChNreWJlcl9zaWduZWRfcHJla2V5GAcgASgMUhFreWJlclNpZ25lZFByZWtleR'
    'JBCh1reWJlcl9zaWduZWRfcHJla2V5X3NpZ25hdHVyZRgIIAEoDFIaa3liZXJTaWduZWRQcmVr'
    'ZXlTaWduYXR1cmUSTgoHcHJla2V5cxgJIAMoCzI0LmNsaWVudF90b19zZXJ2ZXIuSGFuZHNoYW'
    'tlLkluaXRpYWxQcWNLZXlzLlBxY1ByZUtleVIHcHJla2V5cxrUAQoJUHFjUHJlS2V5EiMKDmVj'
    'Y19wcmVfa2V5X2lkGAEgASgDUgtlY2NQcmVLZXlJZBIeCgtlY2NfcHJlX2tleRgCIAEoDFIJZW'
    'NjUHJlS2V5EicKEGt5YmVyX3ByZV9rZXlfaWQYAyABKANSDWt5YmVyUHJlS2V5SWQSIgoNa3li'
    'ZXJfcHJlX2tleRgEIAEoDFILa3liZXJQcmVLZXkSNQoXa3liZXJfcHJlX2tleV9zaWduYXR1cm'
    'UYBSABKAxSFGt5YmVyUHJlS2V5U2lnbmF0dXJlGhIKEEdldEF1dGhDaGFsbGVuZ2UaMQoTR2V0'
    'VXNlcklkQnlVc2VybmFtZRIaCgh1c2VybmFtZRgBIAEoCVIIdXNlcm5hbWUaQwoMR2V0QXV0aF'
    'Rva2VuEhcKB3VzZXJfaWQYASABKANSBnVzZXJJZBIaCghyZXNwb25zZRgCIAEoDFIIcmVzcG9u'
    'c2UatQIKDEF1dGhlbnRpY2F0ZRIXCgd1c2VyX2lkGAEgASgDUgZ1c2VySWQSHQoKYXV0aF90b2'
    'tlbhgCIAEoDFIJYXV0aFRva2VuEiQKC2FwcF92ZXJzaW9uGAMgASgJSABSCmFwcFZlcnNpb26I'
    'AQESIAoJZGV2aWNlX2lkGAQgASgDSAFSCGRldmljZUlkiAEBEigKDWluX2JhY2tncm91bmQYBS'
    'ABKAhIAlIMaW5CYWNrZ3JvdW5kiAEBEjMKE3N1cHBvcnRzX21haWxib3hfdjIYBiABKAhIA1IR'
    'c3VwcG9ydHNNYWlsYm94VjKIAQFCDgoMX2FwcF92ZXJzaW9uQgwKCl9kZXZpY2VfaWRCEAoOX2'
    'luX2JhY2tncm91bmRCFgoUX3N1cHBvcnRzX21haWxib3hfdjIakwIKGkF1dGhlbnRpY2F0ZVdp'
    'dGhMb2dpblRva2VuEhcKB3VzZXJfaWQYASABKANSBnVzZXJJZBIsChJzZWNyZXRfbG9naW5fdG'
    '9rZW4YAiABKAxSEHNlY3JldExvZ2luVG9rZW4SHwoLYXBwX3ZlcnNpb24YAyABKAlSCmFwcFZl'
    'cnNpb24SGwoJZGV2aWNlX2lkGAQgASgDUghkZXZpY2VJZBIjCg1pbl9iYWNrZ3JvdW5kGAUgAS'
    'gIUgxpbkJhY2tncm91bmQSMwoTc3VwcG9ydHNfbWFpbGJveF92MhgGIAEoCEgAUhFzdXBwb3J0'
    'c01haWxib3hWMogBAUIWChRfc3VwcG9ydHNfbWFpbGJveF92MhqlAgojR2V0U2VydmVyS2V5Rm'
    '9yUGFzc3dvcmRMZXNzUmVjb3ZlcnkSFwoHdXNlcl9pZBgBIAEoA1IGdXNlcklkEjIKFXNlcnZl'
    'cl9rZXlfcHJvdGVjdGlvbhgCIAEoDFITc2VydmVyS2V5UHJvdGVjdGlvbhItChBwaW5fdW5sb2'
    'NrX3Rva2VuGAMgASgMSABSDnBpblVubG9ja1Rva2VuiAEBEjEKEnBpbl9wcm90ZWN0aW9uX2tl'
    'eRgEIAEoDEgBUhBwaW5Qcm90ZWN0aW9uS2V5iAEBEhkKBWVtYWlsGAUgASgJSAJSBWVtYWlsiA'
    'EBQhMKEV9waW5fdW5sb2NrX3Rva2VuQhUKE19waW5fcHJvdGVjdGlvbl9rZXlCCAoGX2VtYWls'
    'GssBCiBSZWdpc3RlclBhc3N3b3JkbGVzc05vdGlmaWNhdGlvbhInCg9ub3RpZmljYXRpb25faW'
    'QYASABKAlSDm5vdGlmaWNhdGlvbklkEi4KE2Rvd25sb2FkX2F1dGhfdG9rZW4YAiABKAxSEWRv'
    'd25sb2FkQXV0aFRva2VuEhsKCWxhbmdfY29kZRgDIAEoCVIIbGFuZ0NvZGUSIgoKZ29vZ2xlX2'
    'ZjbRgEIAEoCUgAUglnb29nbGVGY22IAQFCDQoLX2dvb2dsZV9mY20avAEKIENoZWNrRm9yUGFz'
    'c3dvcmRsZXNzTm90aWZpY2F0aW9uEicKD25vdGlmaWNhdGlvbl9pZBgBIAEoCVIObm90aWZpY2'
    'F0aW9uSWQSLgoTZG93bmxvYWRfYXV0aF90b2tlbhgCIAEoDFIRZG93bmxvYWRBdXRoVG9rZW4S'
    'PwocYWxyZWFkeV9yZWNlaXZlZF9tZXNzYWdlX2lkcxgDIAMoA1IZYWxyZWFkeVJlY2VpdmVkTW'
    'Vzc2FnZUlkc0ILCglIYW5kc2hha2U=');

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
      '1': 'getCurrentPlanInfos',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.GetCurrentPlanInfos',
      '9': 0,
      '10': 'getCurrentPlanInfos'
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
    {
      '1': 'request_memories_upload',
      '3': 33,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.RequestMemoriesUpload',
      '9': 0,
      '10': 'requestMemoriesUpload'
    },
    {
      '1': 'confirm_memories_upload',
      '3': 34,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.ConfirmMemoriesUpload',
      '9': 0,
      '10': 'confirmMemoriesUpload'
    },
    {
      '1': 'get_memories_list',
      '3': 35,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.GetMemoriesList',
      '9': 0,
      '10': 'getMemoriesList'
    },
    {
      '1': 'get_memories_url',
      '3': 36,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.GetMemoriesUrl',
      '9': 0,
      '10': 'getMemoriesUrl'
    },
    {
      '1': 'get_memories_usage',
      '3': 37,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.GetMemoriesUsage',
      '9': 0,
      '10': 'getMemoriesUsage'
    },
    {
      '1': 'delete_memory',
      '3': 38,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.DeleteMemory',
      '9': 0,
      '10': 'deleteMemory'
    },
    {
      '1': 'disable_memories_backup',
      '3': 39,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.DisableMemoriesBackup',
      '9': 0,
      '10': 'disableMemoriesBackup'
    },
    {
      '1': 'upload_pqc_prekeys',
      '3': 40,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.UploadPqcPreKeys',
      '9': 0,
      '10': 'uploadPqcPrekeys'
    },
    {
      '1': 'request_pending_messages',
      '3': 43,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.RequestPendingMessages',
      '9': 0,
      '10': 'requestPendingMessages'
    },
  ],
  '3': [
    ApplicationData_TextMessage$json,
    ApplicationData_GetUserByUsername$json,
    ApplicationData_ChangeUsername$json,
    ApplicationData_UpdateGoogleFcmToken$json,
    ApplicationData_GetUserById$json,
    ApplicationData_GetAvailablePlans$json,
    ApplicationData_GetCurrentPlanInfos$json,
    ApplicationData_RemoveAdditionalUser$json,
    ApplicationData_GetPrekeysByUserId$json,
    ApplicationData_GetSignedPreKeyByUserId$json,
    ApplicationData_UpdateSignedPreKey$json,
    ApplicationData_PqcPreKey$json,
    ApplicationData_UploadPqcPreKeys$json,
    ApplicationData_DownloadDone$json,
    ApplicationData_ReportUser$json,
    ApplicationData_IPAPurchase$json,
    ApplicationData_IPAForceCheck$json,
    ApplicationData_DeleteAccount$json,
    ApplicationData_AddAdditionalUser$json,
    ApplicationData_SetLoginToken$json,
    ApplicationData_RegisterPasswordLessRecovery$json,
    ApplicationData_PasswordlessNotification$json,
    ApplicationData_RequestMemoriesUpload$json,
    ApplicationData_ConfirmMemoriesUpload$json,
    ApplicationData_GetMemoriesList$json,
    ApplicationData_GetMemoriesUrl$json,
    ApplicationData_GetMemoriesUsage$json,
    ApplicationData_DeleteMemory$json,
    ApplicationData_DisableMemoriesBackup$json,
    ApplicationData_RequestPendingMessages$json
  ],
  '8': [
    {'1': 'ApplicationData'},
  ],
  '9': [
    {'1': 9, '2': 10},
    {'1': 11, '2': 12},
    {'1': 13, '2': 18},
    {'1': 19, '2': 20},
    {'1': 41, '2': 42},
    {'1': 42, '2': 43},
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
    {'1': 'wake_receiver', '3': 5, '4': 1, '5': 8, '10': 'wakeReceiver'},
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
const ApplicationData_PqcPreKey$json = {
  '1': 'PqcPreKey',
  '2': [
    {'1': 'ecc_pre_key_id', '3': 1, '4': 1, '5': 3, '10': 'eccPreKeyId'},
    {'1': 'ecc_pre_key', '3': 2, '4': 1, '5': 12, '10': 'eccPreKey'},
    {'1': 'kyber_pre_key_id', '3': 3, '4': 1, '5': 3, '10': 'kyberPreKeyId'},
    {'1': 'kyber_pre_key', '3': 4, '4': 1, '5': 12, '10': 'kyberPreKey'},
    {
      '1': 'kyber_pre_key_signature',
      '3': 5,
      '4': 1,
      '5': 12,
      '10': 'kyberPreKeySignature'
    },
  ],
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_UploadPqcPreKeys$json = {
  '1': 'UploadPqcPreKeys',
  '2': [
    {
      '1': 'ecc_signed_prekey_id',
      '3': 1,
      '4': 1,
      '5': 3,
      '10': 'eccSignedPrekeyId'
    },
    {
      '1': 'ecc_signed_prekey',
      '3': 2,
      '4': 1,
      '5': 12,
      '10': 'eccSignedPrekey'
    },
    {
      '1': 'ecc_signed_prekey_signature',
      '3': 3,
      '4': 1,
      '5': 12,
      '10': 'eccSignedPrekeySignature'
    },
    {
      '1': 'kyber_signed_prekey_id',
      '3': 4,
      '4': 1,
      '5': 3,
      '10': 'kyberSignedPrekeyId'
    },
    {
      '1': 'kyber_signed_prekey',
      '3': 5,
      '4': 1,
      '5': 12,
      '10': 'kyberSignedPrekey'
    },
    {
      '1': 'kyber_signed_prekey_signature',
      '3': 6,
      '4': 1,
      '5': 12,
      '10': 'kyberSignedPrekeySignature'
    },
    {
      '1': 'prekeys',
      '3': 7,
      '4': 3,
      '5': 11,
      '6': '.client_to_server.ApplicationData.PqcPreKey',
      '10': 'prekeys'
    },
    {
      '1': 'public_identity_key',
      '3': 8,
      '4': 1,
      '5': 12,
      '9': 0,
      '10': 'publicIdentityKey',
      '17': true
    },
    {
      '1': 'registration_id',
      '3': 9,
      '4': 1,
      '5': 3,
      '9': 1,
      '10': 'registrationId',
      '17': true
    },
  ],
  '8': [
    {'1': '_public_identity_key'},
    {'1': '_registration_id'},
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

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_RequestMemoriesUpload$json = {
  '1': 'RequestMemoriesUpload',
  '2': [
    {'1': 'size', '3': 1, '4': 1, '5': 3, '10': 'size'},
    {'1': 'original_date', '3': 2, '4': 1, '5': 3, '10': 'originalDate'},
    {'1': 'media_id', '3': 3, '4': 1, '5': 9, '10': 'mediaId'},
  ],
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_ConfirmMemoriesUpload$json = {
  '1': 'ConfirmMemoriesUpload',
  '2': [
    {'1': 'media_id', '3': 1, '4': 1, '5': 9, '10': 'mediaId'},
  ],
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_GetMemoriesList$json = {
  '1': 'GetMemoriesList',
  '2': [
    {'1': 'offset_date', '3': 1, '4': 1, '5': 3, '10': 'offsetDate'},
    {'1': 'limit', '3': 2, '4': 1, '5': 3, '10': 'limit'},
  ],
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_GetMemoriesUrl$json = {
  '1': 'GetMemoriesUrl',
  '2': [
    {'1': 'media_id', '3': 1, '4': 1, '5': 9, '10': 'mediaId'},
    {'1': 'thumbnail', '3': 2, '4': 1, '5': 8, '10': 'thumbnail'},
  ],
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_GetMemoriesUsage$json = {
  '1': 'GetMemoriesUsage',
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_DeleteMemory$json = {
  '1': 'DeleteMemory',
  '2': [
    {'1': 'media_id', '3': 1, '4': 1, '5': 9, '10': 'mediaId'},
  ],
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_DisableMemoriesBackup$json = {
  '1': 'DisableMemoriesBackup',
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_RequestPendingMessages$json = {
  '1': 'RequestPendingMessages',
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
    'YXRpb25EYXRhLlVwZGF0ZUdvb2dsZUZjbVRva2VuSABSFHVwZGF0ZUdvb2dsZUZjbVRva2VuEm'
    'kKE2dldEN1cnJlbnRQbGFuSW5mb3MYCiABKAsyNS5jbGllbnRfdG9fc2VydmVyLkFwcGxpY2F0'
    'aW9uRGF0YS5HZXRDdXJyZW50UGxhbkluZm9zSABSE2dldEN1cnJlbnRQbGFuSW5mb3MSYwoRZ2'
    'V0QXZhaWxhYmxlUGxhbnMYDCABKAsyMy5jbGllbnRfdG9fc2VydmVyLkFwcGxpY2F0aW9uRGF0'
    'YS5HZXRBdmFpbGFibGVQbGFuc0gAUhFnZXRBdmFpbGFibGVQbGFucxJUCgxkb3dubG9hZERvbm'
    'UYFCABKAsyLi5jbGllbnRfdG9fc2VydmVyLkFwcGxpY2F0aW9uRGF0YS5Eb3dubG9hZERvbmVI'
    'AFIMZG93bmxvYWREb25lEnUKF2dldFNpZ25lZFByZWtleUJ5VXNlcmlkGBYgASgLMjkuY2xpZW'
    '50X3RvX3NlcnZlci5BcHBsaWNhdGlvbkRhdGEuR2V0U2lnbmVkUHJlS2V5QnlVc2VySWRIAFIX'
    'Z2V0U2lnbmVkUHJla2V5QnlVc2VyaWQSZgoSdXBkYXRlU2lnbmVkUHJla2V5GBcgASgLMjQuY2'
    'xpZW50X3RvX3NlcnZlci5BcHBsaWNhdGlvbkRhdGEuVXBkYXRlU2lnbmVkUHJlS2V5SABSEnVw'
    'ZGF0ZVNpZ25lZFByZWtleRJXCg1kZWxldGVBY2NvdW50GBggASgLMi8uY2xpZW50X3RvX3Nlcn'
    'Zlci5BcHBsaWNhdGlvbkRhdGEuRGVsZXRlQWNjb3VudEgAUg1kZWxldGVBY2NvdW50Ek4KCnJl'
    'cG9ydFVzZXIYGSABKAsyLC5jbGllbnRfdG9fc2VydmVyLkFwcGxpY2F0aW9uRGF0YS5SZXBvcn'
    'RVc2VySABSCnJlcG9ydFVzZXISWgoOY2hhbmdlVXNlcm5hbWUYGiABKAsyMC5jbGllbnRfdG9f'
    'c2VydmVyLkFwcGxpY2F0aW9uRGF0YS5DaGFuZ2VVc2VybmFtZUgAUg5jaGFuZ2VVc2VybmFtZR'
    'JRCgtpcGFQdXJjaGFzZRgbIAEoCzItLmNsaWVudF90b19zZXJ2ZXIuQXBwbGljYXRpb25EYXRh'
    'LklQQVB1cmNoYXNlSABSC2lwYVB1cmNoYXNlElcKDWlwYUZvcmNlQ2hlY2sYHCABKAsyLy5jbG'
    'llbnRfdG9fc2VydmVyLkFwcGxpY2F0aW9uRGF0YS5JUEFGb3JjZUNoZWNrSABSDWlwYUZvcmNl'
    'Q2hlY2sSbAoUcmVtb3ZlQWRkaXRpb25hbFVzZXIYEiABKAsyNi5jbGllbnRfdG9fc2VydmVyLk'
    'FwcGxpY2F0aW9uRGF0YS5SZW1vdmVBZGRpdGlvbmFsVXNlckgAUhRyZW1vdmVBZGRpdGlvbmFs'
    'VXNlchJjChFhZGRBZGRpdGlvbmFsVXNlchgdIAEoCzIzLmNsaWVudF90b19zZXJ2ZXIuQXBwbG'
    'ljYXRpb25EYXRhLkFkZEFkZGl0aW9uYWxVc2VySABSEWFkZEFkZGl0aW9uYWxVc2VyElkKD3Nl'
    'dF9sb2dpbl90b2tlbhgeIAEoCzIvLmNsaWVudF90b19zZXJ2ZXIuQXBwbGljYXRpb25EYXRhLl'
    'NldExvZ2luVG9rZW5IAFINc2V0TG9naW5Ub2tlbhKGAQoecmVnaXN0ZXJfcGFzc3dvcmRsZXNz'
    'X3JlY292ZXJ5GB8gASgLMj4uY2xpZW50X3RvX3NlcnZlci5BcHBsaWNhdGlvbkRhdGEuUmVnaX'
    'N0ZXJQYXNzd29yZExlc3NSZWNvdmVyeUgAUhxyZWdpc3RlclBhc3N3b3JkbGVzc1JlY292ZXJ5'
    'EnkKGXBhc3N3b3JkbGVzc19ub3RpZmljYXRpb24YICABKAsyOi5jbGllbnRfdG9fc2VydmVyLk'
    'FwcGxpY2F0aW9uRGF0YS5QYXNzd29yZGxlc3NOb3RpZmljYXRpb25IAFIYcGFzc3dvcmRsZXNz'
    'Tm90aWZpY2F0aW9uEnEKF3JlcXVlc3RfbWVtb3JpZXNfdXBsb2FkGCEgASgLMjcuY2xpZW50X3'
    'RvX3NlcnZlci5BcHBsaWNhdGlvbkRhdGEuUmVxdWVzdE1lbW9yaWVzVXBsb2FkSABSFXJlcXVl'
    'c3RNZW1vcmllc1VwbG9hZBJxChdjb25maXJtX21lbW9yaWVzX3VwbG9hZBgiIAEoCzI3LmNsaW'
    'VudF90b19zZXJ2ZXIuQXBwbGljYXRpb25EYXRhLkNvbmZpcm1NZW1vcmllc1VwbG9hZEgAUhVj'
    'b25maXJtTWVtb3JpZXNVcGxvYWQSXwoRZ2V0X21lbW9yaWVzX2xpc3QYIyABKAsyMS5jbGllbn'
    'RfdG9fc2VydmVyLkFwcGxpY2F0aW9uRGF0YS5HZXRNZW1vcmllc0xpc3RIAFIPZ2V0TWVtb3Jp'
    'ZXNMaXN0ElwKEGdldF9tZW1vcmllc191cmwYJCABKAsyMC5jbGllbnRfdG9fc2VydmVyLkFwcG'
    'xpY2F0aW9uRGF0YS5HZXRNZW1vcmllc1VybEgAUg5nZXRNZW1vcmllc1VybBJiChJnZXRfbWVt'
    'b3JpZXNfdXNhZ2UYJSABKAsyMi5jbGllbnRfdG9fc2VydmVyLkFwcGxpY2F0aW9uRGF0YS5HZX'
    'RNZW1vcmllc1VzYWdlSABSEGdldE1lbW9yaWVzVXNhZ2USVQoNZGVsZXRlX21lbW9yeRgmIAEo'
    'CzIuLmNsaWVudF90b19zZXJ2ZXIuQXBwbGljYXRpb25EYXRhLkRlbGV0ZU1lbW9yeUgAUgxkZW'
    'xldGVNZW1vcnkScQoXZGlzYWJsZV9tZW1vcmllc19iYWNrdXAYJyABKAsyNy5jbGllbnRfdG9f'
    'c2VydmVyLkFwcGxpY2F0aW9uRGF0YS5EaXNhYmxlTWVtb3JpZXNCYWNrdXBIAFIVZGlzYWJsZU'
    '1lbW9yaWVzQmFja3VwEmIKEnVwbG9hZF9wcWNfcHJla2V5cxgoIAEoCzIyLmNsaWVudF90b19z'
    'ZXJ2ZXIuQXBwbGljYXRpb25EYXRhLlVwbG9hZFBxY1ByZUtleXNIAFIQdXBsb2FkUHFjUHJla2'
    'V5cxJ0ChhyZXF1ZXN0X3BlbmRpbmdfbWVzc2FnZXMYKyABKAsyOC5jbGllbnRfdG9fc2VydmVy'
    'LkFwcGxpY2F0aW9uRGF0YS5SZXF1ZXN0UGVuZGluZ01lc3NhZ2VzSABSFnJlcXVlc3RQZW5kaW'
    '5nTWVzc2FnZXMajwEKC1RleHRNZXNzYWdlEhcKB3VzZXJfaWQYASABKANSBnVzZXJJZBISCgRi'
    'b2R5GAMgASgMUgRib2R5EiAKCXB1c2hfZGF0YRgEIAEoDEgAUghwdXNoRGF0YYgBARIjCg13YW'
    'tlX3JlY2VpdmVyGAUgASgIUgx3YWtlUmVjZWl2ZXJCDAoKX3B1c2hfZGF0YRovChFHZXRVc2Vy'
    'QnlVc2VybmFtZRIaCgh1c2VybmFtZRgBIAEoCVIIdXNlcm5hbWUaLAoOQ2hhbmdlVXNlcm5hbW'
    'USGgoIdXNlcm5hbWUYASABKAlSCHVzZXJuYW1lGjUKFFVwZGF0ZUdvb2dsZUZjbVRva2VuEh0K'
    'Cmdvb2dsZV9mY20YASABKAlSCWdvb2dsZUZjbRomCgtHZXRVc2VyQnlJZBIXCgd1c2VyX2lkGA'
    'EgASgDUgZ1c2VySWQaEwoRR2V0QXZhaWxhYmxlUGxhbnMaFQoTR2V0Q3VycmVudFBsYW5JbmZv'
    'cxovChRSZW1vdmVBZGRpdGlvbmFsVXNlchIXCgd1c2VyX2lkGAEgASgDUgZ1c2VySWQaLQoSR2'
    'V0UHJla2V5c0J5VXNlcklkEhcKB3VzZXJfaWQYASABKANSBnVzZXJJZBoyChdHZXRTaWduZWRQ'
    'cmVLZXlCeVVzZXJJZBIXCgd1c2VyX2lkGAEgASgDUgZ1c2VySWQamwEKElVwZGF0ZVNpZ25lZF'
    'ByZUtleRIoChBzaWduZWRfcHJla2V5X2lkGAEgASgDUg5zaWduZWRQcmVrZXlJZBIjCg1zaWdu'
    'ZWRfcHJla2V5GAIgASgMUgxzaWduZWRQcmVrZXkSNgoXc2lnbmVkX3ByZWtleV9zaWduYXR1cm'
    'UYAyABKAxSFXNpZ25lZFByZWtleVNpZ25hdHVyZRrUAQoJUHFjUHJlS2V5EiMKDmVjY19wcmVf'
    'a2V5X2lkGAEgASgDUgtlY2NQcmVLZXlJZBIeCgtlY2NfcHJlX2tleRgCIAEoDFIJZWNjUHJlS2'
    'V5EicKEGt5YmVyX3ByZV9rZXlfaWQYAyABKANSDWt5YmVyUHJlS2V5SWQSIgoNa3liZXJfcHJl'
    'X2tleRgEIAEoDFILa3liZXJQcmVLZXkSNQoXa3liZXJfcHJlX2tleV9zaWduYXR1cmUYBSABKA'
    'xSFGt5YmVyUHJlS2V5U2lnbmF0dXJlGqwEChBVcGxvYWRQcWNQcmVLZXlzEi8KFGVjY19zaWdu'
    'ZWRfcHJla2V5X2lkGAEgASgDUhFlY2NTaWduZWRQcmVrZXlJZBIqChFlY2Nfc2lnbmVkX3ByZW'
    'tleRgCIAEoDFIPZWNjU2lnbmVkUHJla2V5Ej0KG2VjY19zaWduZWRfcHJla2V5X3NpZ25hdHVy'
    'ZRgDIAEoDFIYZWNjU2lnbmVkUHJla2V5U2lnbmF0dXJlEjMKFmt5YmVyX3NpZ25lZF9wcmVrZX'
    'lfaWQYBCABKANSE2t5YmVyU2lnbmVkUHJla2V5SWQSLgoTa3liZXJfc2lnbmVkX3ByZWtleRgF'
    'IAEoDFIRa3liZXJTaWduZWRQcmVrZXkSQQoda3liZXJfc2lnbmVkX3ByZWtleV9zaWduYXR1cm'
    'UYBiABKAxSGmt5YmVyU2lnbmVkUHJla2V5U2lnbmF0dXJlEkUKB3ByZWtleXMYByADKAsyKy5j'
    'bGllbnRfdG9fc2VydmVyLkFwcGxpY2F0aW9uRGF0YS5QcWNQcmVLZXlSB3ByZWtleXMSMwoTcH'
    'VibGljX2lkZW50aXR5X2tleRgIIAEoDEgAUhFwdWJsaWNJZGVudGl0eUtleYgBARIsCg9yZWdp'
    'c3RyYXRpb25faWQYCSABKANIAVIOcmVnaXN0cmF0aW9uSWSIAQFCFgoUX3B1YmxpY19pZGVudG'
    'l0eV9rZXlCEgoQX3JlZ2lzdHJhdGlvbl9pZBo1CgxEb3dubG9hZERvbmUSJQoOZG93bmxvYWRf'
    'dG9rZW4YASABKAxSDWRvd25sb2FkVG9rZW4aTgoKUmVwb3J0VXNlchIoChByZXBvcnRlZF91c2'
    'VyX2lkGAEgASgDUg5yZXBvcnRlZFVzZXJJZBIWCgZyZWFzb24YAiABKAlSBnJlYXNvbhpxCgtJ'
    'UEFQdXJjaGFzZRIdCgpwcm9kdWN0X2lkGAEgASgJUglwcm9kdWN0SWQSFgoGc291cmNlGAIgAS'
    'gJUgZzb3VyY2USKwoRdmVyaWZpY2F0aW9uX2RhdGEYAyABKAlSEHZlcmlmaWNhdGlvbkRhdGEa'
    'DwoNSVBBRm9yY2VDaGVjaxoPCg1EZWxldGVBY2NvdW50GiwKEUFkZEFkZGl0aW9uYWxVc2VyEh'
    'cKB3VzZXJfaWQYASABKANSBnVzZXJJZBowCg1TZXRMb2dpblRva2VuEh8KC2xvZ2luX3Rva2Vu'
    'GAEgASgMUgpsb2dpblRva2VuGo4BChxSZWdpc3RlclBhc3N3b3JkTGVzc1JlY292ZXJ5Ei4KEm'
    'VuY3J5cHRlZFNlcnZlcktleRgBIAEoDFISZW5jcnlwdGVkU2VydmVyS2V5EisKDnBpblVubG9j'
    'a1Rva2VuGAIgASgMSABSDnBpblVubG9ja1Rva2VuiAEBQhEKD19waW5VbmxvY2tUb2tlbhpwCh'
    'hQYXNzd29yZGxlc3NOb3RpZmljYXRpb24SJwoPbm90aWZpY2F0aW9uX2lkGAEgASgJUg5ub3Rp'
    'ZmljYXRpb25JZBIrChFlbmNyeXB0ZWRfbWVzc2FnZRgCIAEoDFIQZW5jcnlwdGVkTWVzc2FnZR'
    'prChVSZXF1ZXN0TWVtb3JpZXNVcGxvYWQSEgoEc2l6ZRgBIAEoA1IEc2l6ZRIjCg1vcmlnaW5h'
    'bF9kYXRlGAIgASgDUgxvcmlnaW5hbERhdGUSGQoIbWVkaWFfaWQYAyABKAlSB21lZGlhSWQaMg'
    'oVQ29uZmlybU1lbW9yaWVzVXBsb2FkEhkKCG1lZGlhX2lkGAEgASgJUgdtZWRpYUlkGkgKD0dl'
    'dE1lbW9yaWVzTGlzdBIfCgtvZmZzZXRfZGF0ZRgBIAEoA1IKb2Zmc2V0RGF0ZRIUCgVsaW1pdB'
    'gCIAEoA1IFbGltaXQaSQoOR2V0TWVtb3JpZXNVcmwSGQoIbWVkaWFfaWQYASABKAlSB21lZGlh'
    'SWQSHAoJdGh1bWJuYWlsGAIgASgIUgl0aHVtYm5haWwaEgoQR2V0TWVtb3JpZXNVc2FnZRopCg'
    'xEZWxldGVNZW1vcnkSGQoIbWVkaWFfaWQYASABKAlSB21lZGlhSWQaFwoVRGlzYWJsZU1lbW9y'
    'aWVzQmFja3VwGhgKFlJlcXVlc3RQZW5kaW5nTWVzc2FnZXNCEQoPQXBwbGljYXRpb25EYXRhSg'
    'QICRAKSgQICxAMSgQIDRASSgQIExAUSgQIKRAqSgQIKhAr');

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
  '3': [
    Response_PreKey$json,
    Response_Prekeys$json,
    Response_PqcPrekeys$json,
    Response_AcknowledgedPendingMessages$json,
    Response_Ok$json
  ],
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
const Response_PqcPrekeys$json = {
  '1': 'PqcPrekeys',
  '2': [
    {
      '1': 'prekeys',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.client_to_server.ApplicationData.PqcPreKey',
      '10': 'prekeys'
    },
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_AcknowledgedPendingMessages$json = {
  '1': 'AcknowledgedPendingMessages',
  '2': [
    {'1': 'delivery_ids', '3': 1, '4': 3, '5': 3, '10': 'deliveryIds'},
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
    {
      '1': 'prekeys_pqc',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.Response.PqcPrekeys',
      '9': 0,
      '10': 'prekeysPqc'
    },
    {
      '1': 'acknowledged_pending_messages',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.Response.AcknowledgedPendingMessages',
      '9': 0,
      '10': 'acknowledgedPendingMessages'
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
    'cxpTCgpQcWNQcmVrZXlzEkUKB3ByZWtleXMYASADKAsyKy5jbGllbnRfdG9fc2VydmVyLkFwcG'
    'xpY2F0aW9uRGF0YS5QcWNQcmVLZXlSB3ByZWtleXMaQAobQWNrbm93bGVkZ2VkUGVuZGluZ01l'
    'c3NhZ2VzEiEKDGRlbGl2ZXJ5X2lkcxgBIAMoA1ILZGVsaXZlcnlJZHMaqAIKAk9rEhQKBE5vbm'
    'UYASABKAhIAFIETm9uZRI+CgdwcmVrZXlzGAIgASgLMiIuY2xpZW50X3RvX3NlcnZlci5SZXNw'
    'b25zZS5QcmVrZXlzSABSB3ByZWtleXMSSAoLcHJla2V5c19wcWMYAyABKAsyJS5jbGllbnRfdG'
    '9fc2VydmVyLlJlc3BvbnNlLlBxY1ByZWtleXNIAFIKcHJla2V5c1BxYxJ8Ch1hY2tub3dsZWRn'
    'ZWRfcGVuZGluZ19tZXNzYWdlcxgEIAEoCzI2LmNsaWVudF90b19zZXJ2ZXIuUmVzcG9uc2UuQW'
    'Nrbm93bGVkZ2VkUGVuZGluZ01lc3NhZ2VzSABSG2Fja25vd2xlZGdlZFBlbmRpbmdNZXNzYWdl'
    'c0IECgJPa0IKCghSZXNwb25zZQ==');
