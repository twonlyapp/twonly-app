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
  ],
  '3': [
    Handshake_RequestPOW$json,
    Handshake_Register$json,
    Handshake_GetAuthChallenge$json,
    Handshake_GetAuthToken$json,
    Handshake_Authenticate$json,
    Handshake_AuthenticateWithLoginToken$json
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
    '5IAFIaYXV0aGVudGljYXRlV2l0aExvZ2luVG9rZW4aDAoKUmVxdWVzdFBPVxrKAwoIUmVnaXN0'
    'ZXISGgoIdXNlcm5hbWUYASABKAlSCHVzZXJuYW1lEiQKC2ludml0ZV9jb2RlGAIgASgJSABSCm'
    'ludml0ZUNvZGWIAQESLgoTcHVibGljX2lkZW50aXR5X2tleRgDIAEoDFIRcHVibGljSWRlbnRp'
    'dHlLZXkSIwoNc2lnbmVkX3ByZWtleRgEIAEoDFIMc2lnbmVkUHJla2V5EjYKF3NpZ25lZF9wcm'
    'VrZXlfc2lnbmF0dXJlGAUgASgMUhVzaWduZWRQcmVrZXlTaWduYXR1cmUSKAoQc2lnbmVkX3By'
    'ZWtleV9pZBgGIAEoA1IOc2lnbmVkUHJla2V5SWQSJwoPcmVnaXN0cmF0aW9uX2lkGAcgASgDUg'
    '5yZWdpc3RyYXRpb25JZBIVCgZpc19pb3MYCCABKAhSBWlzSW9zEhsKCWxhbmdfY29kZRgJIAEo'
    'CVIIbGFuZ0NvZGUSIgoNcHJvb2Zfb2Zfd29yaxgKIAEoA1ILcHJvb2ZPZldvcmsSJAoLbG9naW'
    '5fdG9rZW4YCyABKAxIAVIKbG9naW5Ub2tlbogBAUIOCgxfaW52aXRlX2NvZGVCDgoMX2xvZ2lu'
    'X3Rva2VuGhIKEEdldEF1dGhDaGFsbGVuZ2UaQwoMR2V0QXV0aFRva2VuEhcKB3VzZXJfaWQYAS'
    'ABKANSBnVzZXJJZBIaCghyZXNwb25zZRgCIAEoDFIIcmVzcG9uc2Ua6AEKDEF1dGhlbnRpY2F0'
    'ZRIXCgd1c2VyX2lkGAEgASgDUgZ1c2VySWQSHQoKYXV0aF90b2tlbhgCIAEoDFIJYXV0aFRva2'
    'VuEiQKC2FwcF92ZXJzaW9uGAMgASgJSABSCmFwcFZlcnNpb26IAQESIAoJZGV2aWNlX2lkGAQg'
    'ASgDSAFSCGRldmljZUlkiAEBEigKDWluX2JhY2tncm91bmQYBSABKAhIAlIMaW5CYWNrZ3JvdW'
    '5kiAEBQg4KDF9hcHBfdmVyc2lvbkIMCgpfZGV2aWNlX2lkQhAKDl9pbl9iYWNrZ3JvdW5kGsYB'
    'ChpBdXRoZW50aWNhdGVXaXRoTG9naW5Ub2tlbhIXCgd1c2VyX2lkGAEgASgDUgZ1c2VySWQSLA'
    'oSc2VjcmV0X2xvZ2luX3Rva2VuGAIgASgMUhBzZWNyZXRMb2dpblRva2VuEh8KC2FwcF92ZXJz'
    'aW9uGAMgASgJUgphcHBWZXJzaW9uEhsKCWRldmljZV9pZBgEIAEoA1IIZGV2aWNlSWQSIwoNaW'
    '5fYmFja2dyb3VuZBgFIAEoCFIMaW5CYWNrZ3JvdW5kQgsKCUhhbmRzaGFrZQ==');

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
    ApplicationData_Deprecated$json
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
    'ljYXRpb25EYXRhLlNldExvZ2luVG9rZW5IAFINc2V0TG9naW5Ub2tlbhpqCgtUZXh0TWVzc2Fn'
    'ZRIXCgd1c2VyX2lkGAEgASgDUgZ1c2VySWQSEgoEYm9keRgDIAEoDFIEYm9keRIgCglwdXNoX2'
    'RhdGEYBCABKAxIAFIIcHVzaERhdGGIAQFCDAoKX3B1c2hfZGF0YRovChFHZXRVc2VyQnlVc2Vy'
    'bmFtZRIaCgh1c2VybmFtZRgBIAEoCVIIdXNlcm5hbWUaLAoOQ2hhbmdlVXNlcm5hbWUSGgoIdX'
    'Nlcm5hbWUYASABKAlSCHVzZXJuYW1lGjUKFFVwZGF0ZUdvb2dsZUZjbVRva2VuEh0KCmdvb2ds'
    'ZV9mY20YASABKAlSCWdvb2dsZUZjbRomCgtHZXRVc2VyQnlJZBIXCgd1c2VyX2lkGAEgASgDUg'
    'Z1c2VySWQaEwoRR2V0QXZhaWxhYmxlUGxhbnMaFwoVR2V0QWRkQWNjb3VudHNJbnZpdGVzGhUK'
    'E0dldEN1cnJlbnRQbGFuSW5mb3MaLwoUUmVtb3ZlQWRkaXRpb25hbFVzZXISFwoHdXNlcl9pZB'
    'gBIAEoA1IGdXNlcklkGi0KEkdldFByZWtleXNCeVVzZXJJZBIXCgd1c2VyX2lkGAEgASgDUgZ1'
    'c2VySWQaMgoXR2V0U2lnbmVkUHJlS2V5QnlVc2VySWQSFwoHdXNlcl9pZBgBIAEoA1IGdXNlck'
    'lkGpsBChJVcGRhdGVTaWduZWRQcmVLZXkSKAoQc2lnbmVkX3ByZWtleV9pZBgBIAEoA1IOc2ln'
    'bmVkUHJla2V5SWQSIwoNc2lnbmVkX3ByZWtleRgCIAEoDFIMc2lnbmVkUHJla2V5EjYKF3NpZ2'
    '5lZF9wcmVrZXlfc2lnbmF0dXJlGAMgASgMUhVzaWduZWRQcmVrZXlTaWduYXR1cmUaNQoMRG93'
    'bmxvYWREb25lEiUKDmRvd25sb2FkX3Rva2VuGAEgASgMUg1kb3dubG9hZFRva2VuGk4KClJlcG'
    '9ydFVzZXISKAoQcmVwb3J0ZWRfdXNlcl9pZBgBIAEoA1IOcmVwb3J0ZWRVc2VySWQSFgoGcmVh'
    'c29uGAIgASgJUgZyZWFzb24acQoLSVBBUHVyY2hhc2USHQoKcHJvZHVjdF9pZBgBIAEoCVIJcH'
    'JvZHVjdElkEhYKBnNvdXJjZRgCIAEoCVIGc291cmNlEisKEXZlcmlmaWNhdGlvbl9kYXRhGAMg'
    'ASgJUhB2ZXJpZmljYXRpb25EYXRhGg8KDUlQQUZvcmNlQ2hlY2saDwoNRGVsZXRlQWNjb3VudB'
    'osChFBZGRBZGRpdGlvbmFsVXNlchIXCgd1c2VyX2lkGAEgASgDUgZ1c2VySWQaMAoNU2V0TG9n'
    'aW5Ub2tlbhIfCgtsb2dpbl90b2tlbhgBIAEoDFIKbG9naW5Ub2tlbhoMCgpEZXByZWNhdGVkQh'
    'EKD0FwcGxpY2F0aW9uRGF0YQ==');

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
