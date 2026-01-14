// This is a generated file - do not edit.
//
// Generated from api/websocket/client_to_server.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

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
  ],
  '3': [
    Handshake_RequestPOW$json,
    Handshake_Register$json,
    Handshake_GetAuthChallenge$json,
    Handshake_GetAuthToken$json,
    Handshake_Authenticate$json
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
  ],
  '8': [
    {'1': '_app_version'},
    {'1': '_device_id'},
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
    'BPV0gAUgpyZXF1ZXN0UE9XGgwKClJlcXVlc3RQT1calAMKCFJlZ2lzdGVyEhoKCHVzZXJuYW1l'
    'GAEgASgJUgh1c2VybmFtZRIkCgtpbnZpdGVfY29kZRgCIAEoCUgAUgppbnZpdGVDb2RliAEBEi'
    '4KE3B1YmxpY19pZGVudGl0eV9rZXkYAyABKAxSEXB1YmxpY0lkZW50aXR5S2V5EiMKDXNpZ25l'
    'ZF9wcmVrZXkYBCABKAxSDHNpZ25lZFByZWtleRI2ChdzaWduZWRfcHJla2V5X3NpZ25hdHVyZR'
    'gFIAEoDFIVc2lnbmVkUHJla2V5U2lnbmF0dXJlEigKEHNpZ25lZF9wcmVrZXlfaWQYBiABKANS'
    'DnNpZ25lZFByZWtleUlkEicKD3JlZ2lzdHJhdGlvbl9pZBgHIAEoA1IOcmVnaXN0cmF0aW9uSW'
    'QSFQoGaXNfaW9zGAggASgIUgVpc0lvcxIbCglsYW5nX2NvZGUYCSABKAlSCGxhbmdDb2RlEiIK'
    'DXByb29mX29mX3dvcmsYCiABKANSC3Byb29mT2ZXb3JrQg4KDF9pbnZpdGVfY29kZRoSChBHZX'
    'RBdXRoQ2hhbGxlbmdlGkMKDEdldEF1dGhUb2tlbhIXCgd1c2VyX2lkGAEgASgDUgZ1c2VySWQS'
    'GgoIcmVzcG9uc2UYAiABKAxSCHJlc3BvbnNlGqwBCgxBdXRoZW50aWNhdGUSFwoHdXNlcl9pZB'
    'gBIAEoA1IGdXNlcklkEh0KCmF1dGhfdG9rZW4YAiABKAxSCWF1dGhUb2tlbhIkCgthcHBfdmVy'
    'c2lvbhgDIAEoCUgAUgphcHBWZXJzaW9uiAEBEiAKCWRldmljZV9pZBgEIAEoA0gBUghkZXZpY2'
    'VJZIgBAUIOCgxfYXBwX3ZlcnNpb25CDAoKX2RldmljZV9pZEILCglIYW5kc2hha2U=');

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
      '1': 'getLocation',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.GetLocation',
      '9': 0,
      '10': 'getLocation'
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
      '1': 'redeemVoucher',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.RedeemVoucher',
      '9': 0,
      '10': 'redeemVoucher'
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
      '1': 'createVoucher',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.CreateVoucher',
      '9': 0,
      '10': 'createVoucher'
    },
    {
      '1': 'getVouchers',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.GetVouchers',
      '9': 0,
      '10': 'getVouchers'
    },
    {
      '1': 'switchtoPayedPlan',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.SwitchToPayedPlan',
      '9': 0,
      '10': 'switchtoPayedPlan'
    },
    {
      '1': 'getAddaccountsInvites',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.GetAddAccountsInvites',
      '9': 0,
      '10': 'getAddaccountsInvites'
    },
    {
      '1': 'redeemAdditionalCode',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.RedeemAdditionalCode',
      '9': 0,
      '10': 'redeemAdditionalCode'
    },
    {
      '1': 'updatePlanOptions',
      '3': 19,
      '4': 1,
      '5': 11,
      '6': '.client_to_server.ApplicationData.UpdatePlanOptions',
      '9': 0,
      '10': 'updatePlanOptions'
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
  ],
  '3': [
    ApplicationData_TextMessage$json,
    ApplicationData_GetUserByUsername$json,
    ApplicationData_ChangeUsername$json,
    ApplicationData_UpdateGoogleFcmToken$json,
    ApplicationData_GetUserById$json,
    ApplicationData_RedeemVoucher$json,
    ApplicationData_SwitchToPayedPlan$json,
    ApplicationData_UpdatePlanOptions$json,
    ApplicationData_CreateVoucher$json,
    ApplicationData_GetLocation$json,
    ApplicationData_GetVouchers$json,
    ApplicationData_GetAvailablePlans$json,
    ApplicationData_GetAddAccountsInvites$json,
    ApplicationData_GetCurrentPlanInfos$json,
    ApplicationData_RedeemAdditionalCode$json,
    ApplicationData_RemoveAdditionalUser$json,
    ApplicationData_GetPrekeysByUserId$json,
    ApplicationData_GetSignedPreKeyByUserId$json,
    ApplicationData_UpdateSignedPreKey$json,
    ApplicationData_DownloadDone$json,
    ApplicationData_ReportUser$json,
    ApplicationData_IPAPurchase$json,
    ApplicationData_IPAForceCheck$json,
    ApplicationData_DeleteAccount$json,
    ApplicationData_AddAdditionalUser$json
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
const ApplicationData_RedeemVoucher$json = {
  '1': 'RedeemVoucher',
  '2': [
    {'1': 'voucher', '3': 1, '4': 1, '5': 9, '10': 'voucher'},
  ],
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_SwitchToPayedPlan$json = {
  '1': 'SwitchToPayedPlan',
  '2': [
    {'1': 'plan_id', '3': 1, '4': 1, '5': 9, '10': 'planId'},
    {'1': 'pay_monthly', '3': 2, '4': 1, '5': 8, '10': 'payMonthly'},
    {'1': 'auto_renewal', '3': 3, '4': 1, '5': 8, '10': 'autoRenewal'},
  ],
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_UpdatePlanOptions$json = {
  '1': 'UpdatePlanOptions',
  '2': [
    {'1': 'auto_renewal', '3': 1, '4': 1, '5': 8, '10': 'autoRenewal'},
  ],
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_CreateVoucher$json = {
  '1': 'CreateVoucher',
  '2': [
    {'1': 'value_cents', '3': 1, '4': 1, '5': 13, '10': 'valueCents'},
  ],
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_GetLocation$json = {
  '1': 'GetLocation',
};

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData_GetVouchers$json = {
  '1': 'GetVouchers',
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
const ApplicationData_RedeemAdditionalCode$json = {
  '1': 'RedeemAdditionalCode',
  '2': [
    {'1': 'invite_code', '3': 2, '4': 1, '5': 9, '10': 'inviteCode'},
  ],
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
    'EKC2dldExvY2F0aW9uGAkgASgLMi0uY2xpZW50X3RvX3NlcnZlci5BcHBsaWNhdGlvbkRhdGEu'
    'R2V0TG9jYXRpb25IAFILZ2V0TG9jYXRpb24SaQoTZ2V0Q3VycmVudFBsYW5JbmZvcxgKIAEoCz'
    'I1LmNsaWVudF90b19zZXJ2ZXIuQXBwbGljYXRpb25EYXRhLkdldEN1cnJlbnRQbGFuSW5mb3NI'
    'AFITZ2V0Q3VycmVudFBsYW5JbmZvcxJXCg1yZWRlZW1Wb3VjaGVyGAsgASgLMi8uY2xpZW50X3'
    'RvX3NlcnZlci5BcHBsaWNhdGlvbkRhdGEuUmVkZWVtVm91Y2hlckgAUg1yZWRlZW1Wb3VjaGVy'
    'EmMKEWdldEF2YWlsYWJsZVBsYW5zGAwgASgLMjMuY2xpZW50X3RvX3NlcnZlci5BcHBsaWNhdG'
    'lvbkRhdGEuR2V0QXZhaWxhYmxlUGxhbnNIAFIRZ2V0QXZhaWxhYmxlUGxhbnMSVwoNY3JlYXRl'
    'Vm91Y2hlchgNIAEoCzIvLmNsaWVudF90b19zZXJ2ZXIuQXBwbGljYXRpb25EYXRhLkNyZWF0ZV'
    'ZvdWNoZXJIAFINY3JlYXRlVm91Y2hlchJRCgtnZXRWb3VjaGVycxgOIAEoCzItLmNsaWVudF90'
    'b19zZXJ2ZXIuQXBwbGljYXRpb25EYXRhLkdldFZvdWNoZXJzSABSC2dldFZvdWNoZXJzEmMKEX'
    'N3aXRjaHRvUGF5ZWRQbGFuGA8gASgLMjMuY2xpZW50X3RvX3NlcnZlci5BcHBsaWNhdGlvbkRh'
    'dGEuU3dpdGNoVG9QYXllZFBsYW5IAFIRc3dpdGNodG9QYXllZFBsYW4SbwoVZ2V0QWRkYWNjb3'
    'VudHNJbnZpdGVzGBAgASgLMjcuY2xpZW50X3RvX3NlcnZlci5BcHBsaWNhdGlvbkRhdGEuR2V0'
    'QWRkQWNjb3VudHNJbnZpdGVzSABSFWdldEFkZGFjY291bnRzSW52aXRlcxJsChRyZWRlZW1BZG'
    'RpdGlvbmFsQ29kZRgRIAEoCzI2LmNsaWVudF90b19zZXJ2ZXIuQXBwbGljYXRpb25EYXRhLlJl'
    'ZGVlbUFkZGl0aW9uYWxDb2RlSABSFHJlZGVlbUFkZGl0aW9uYWxDb2RlEmMKEXVwZGF0ZVBsYW'
    '5PcHRpb25zGBMgASgLMjMuY2xpZW50X3RvX3NlcnZlci5BcHBsaWNhdGlvbkRhdGEuVXBkYXRl'
    'UGxhbk9wdGlvbnNIAFIRdXBkYXRlUGxhbk9wdGlvbnMSVAoMZG93bmxvYWREb25lGBQgASgLMi'
    '4uY2xpZW50X3RvX3NlcnZlci5BcHBsaWNhdGlvbkRhdGEuRG93bmxvYWREb25lSABSDGRvd25s'
    'b2FkRG9uZRJ1ChdnZXRTaWduZWRQcmVrZXlCeVVzZXJpZBgWIAEoCzI5LmNsaWVudF90b19zZX'
    'J2ZXIuQXBwbGljYXRpb25EYXRhLkdldFNpZ25lZFByZUtleUJ5VXNlcklkSABSF2dldFNpZ25l'
    'ZFByZWtleUJ5VXNlcmlkEmYKEnVwZGF0ZVNpZ25lZFByZWtleRgXIAEoCzI0LmNsaWVudF90b1'
    '9zZXJ2ZXIuQXBwbGljYXRpb25EYXRhLlVwZGF0ZVNpZ25lZFByZUtleUgAUhJ1cGRhdGVTaWdu'
    'ZWRQcmVrZXkSVwoNZGVsZXRlQWNjb3VudBgYIAEoCzIvLmNsaWVudF90b19zZXJ2ZXIuQXBwbG'
    'ljYXRpb25EYXRhLkRlbGV0ZUFjY291bnRIAFINZGVsZXRlQWNjb3VudBJOCgpyZXBvcnRVc2Vy'
    'GBkgASgLMiwuY2xpZW50X3RvX3NlcnZlci5BcHBsaWNhdGlvbkRhdGEuUmVwb3J0VXNlckgAUg'
    'pyZXBvcnRVc2VyEloKDmNoYW5nZVVzZXJuYW1lGBogASgLMjAuY2xpZW50X3RvX3NlcnZlci5B'
    'cHBsaWNhdGlvbkRhdGEuQ2hhbmdlVXNlcm5hbWVIAFIOY2hhbmdlVXNlcm5hbWUSUQoLaXBhUH'
    'VyY2hhc2UYGyABKAsyLS5jbGllbnRfdG9fc2VydmVyLkFwcGxpY2F0aW9uRGF0YS5JUEFQdXJj'
    'aGFzZUgAUgtpcGFQdXJjaGFzZRJXCg1pcGFGb3JjZUNoZWNrGBwgASgLMi8uY2xpZW50X3RvX3'
    'NlcnZlci5BcHBsaWNhdGlvbkRhdGEuSVBBRm9yY2VDaGVja0gAUg1pcGFGb3JjZUNoZWNrEmwK'
    'FHJlbW92ZUFkZGl0aW9uYWxVc2VyGBIgASgLMjYuY2xpZW50X3RvX3NlcnZlci5BcHBsaWNhdG'
    'lvbkRhdGEuUmVtb3ZlQWRkaXRpb25hbFVzZXJIAFIUcmVtb3ZlQWRkaXRpb25hbFVzZXISYwoR'
    'YWRkQWRkaXRpb25hbFVzZXIYHSABKAsyMy5jbGllbnRfdG9fc2VydmVyLkFwcGxpY2F0aW9uRG'
    'F0YS5BZGRBZGRpdGlvbmFsVXNlckgAUhFhZGRBZGRpdGlvbmFsVXNlchpqCgtUZXh0TWVzc2Fn'
    'ZRIXCgd1c2VyX2lkGAEgASgDUgZ1c2VySWQSEgoEYm9keRgDIAEoDFIEYm9keRIgCglwdXNoX2'
    'RhdGEYBCABKAxIAFIIcHVzaERhdGGIAQFCDAoKX3B1c2hfZGF0YRovChFHZXRVc2VyQnlVc2Vy'
    'bmFtZRIaCgh1c2VybmFtZRgBIAEoCVIIdXNlcm5hbWUaLAoOQ2hhbmdlVXNlcm5hbWUSGgoIdX'
    'Nlcm5hbWUYASABKAlSCHVzZXJuYW1lGjUKFFVwZGF0ZUdvb2dsZUZjbVRva2VuEh0KCmdvb2ds'
    'ZV9mY20YASABKAlSCWdvb2dsZUZjbRomCgtHZXRVc2VyQnlJZBIXCgd1c2VyX2lkGAEgASgDUg'
    'Z1c2VySWQaKQoNUmVkZWVtVm91Y2hlchIYCgd2b3VjaGVyGAEgASgJUgd2b3VjaGVyGnAKEVN3'
    'aXRjaFRvUGF5ZWRQbGFuEhcKB3BsYW5faWQYASABKAlSBnBsYW5JZBIfCgtwYXlfbW9udGhseR'
    'gCIAEoCFIKcGF5TW9udGhseRIhCgxhdXRvX3JlbmV3YWwYAyABKAhSC2F1dG9SZW5ld2FsGjYK'
    'EVVwZGF0ZVBsYW5PcHRpb25zEiEKDGF1dG9fcmVuZXdhbBgBIAEoCFILYXV0b1JlbmV3YWwaMA'
    'oNQ3JlYXRlVm91Y2hlchIfCgt2YWx1ZV9jZW50cxgBIAEoDVIKdmFsdWVDZW50cxoNCgtHZXRM'
    'b2NhdGlvbhoNCgtHZXRWb3VjaGVycxoTChFHZXRBdmFpbGFibGVQbGFucxoXChVHZXRBZGRBY2'
    'NvdW50c0ludml0ZXMaFQoTR2V0Q3VycmVudFBsYW5JbmZvcxo3ChRSZWRlZW1BZGRpdGlvbmFs'
    'Q29kZRIfCgtpbnZpdGVfY29kZRgCIAEoCVIKaW52aXRlQ29kZRovChRSZW1vdmVBZGRpdGlvbm'
    'FsVXNlchIXCgd1c2VyX2lkGAEgASgDUgZ1c2VySWQaLQoSR2V0UHJla2V5c0J5VXNlcklkEhcK'
    'B3VzZXJfaWQYASABKANSBnVzZXJJZBoyChdHZXRTaWduZWRQcmVLZXlCeVVzZXJJZBIXCgd1c2'
    'VyX2lkGAEgASgDUgZ1c2VySWQamwEKElVwZGF0ZVNpZ25lZFByZUtleRIoChBzaWduZWRfcHJl'
    'a2V5X2lkGAEgASgDUg5zaWduZWRQcmVrZXlJZBIjCg1zaWduZWRfcHJla2V5GAIgASgMUgxzaW'
    'duZWRQcmVrZXkSNgoXc2lnbmVkX3ByZWtleV9zaWduYXR1cmUYAyABKAxSFXNpZ25lZFByZWtl'
    'eVNpZ25hdHVyZRo1CgxEb3dubG9hZERvbmUSJQoOZG93bmxvYWRfdG9rZW4YASABKAxSDWRvd2'
    '5sb2FkVG9rZW4aTgoKUmVwb3J0VXNlchIoChByZXBvcnRlZF91c2VyX2lkGAEgASgDUg5yZXBv'
    'cnRlZFVzZXJJZBIWCgZyZWFzb24YAiABKAlSBnJlYXNvbhpxCgtJUEFQdXJjaGFzZRIdCgpwcm'
    '9kdWN0X2lkGAEgASgJUglwcm9kdWN0SWQSFgoGc291cmNlGAIgASgJUgZzb3VyY2USKwoRdmVy'
    'aWZpY2F0aW9uX2RhdGEYAyABKAlSEHZlcmlmaWNhdGlvbkRhdGEaDwoNSVBBRm9yY2VDaGVjax'
    'oPCg1EZWxldGVBY2NvdW50GiwKEUFkZEFkZGl0aW9uYWxVc2VyEhcKB3VzZXJfaWQYASABKANS'
    'BnVzZXJJZEIRCg9BcHBsaWNhdGlvbkRhdGE=');

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
