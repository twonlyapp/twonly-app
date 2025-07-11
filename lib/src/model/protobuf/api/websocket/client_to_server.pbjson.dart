//
//  Generated code. Do not modify.
//  source: api/websocket/client_to_server.proto
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
    {'1': 'is_ios', '3': 8, '4': 1, '5': 8, '9': 1, '10': 'isIos', '17': true},
  ],
  '8': [
    {'1': '_invite_code'},
    {'1': '_is_ios'},
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
    {'1': 'app_version', '3': 3, '4': 1, '5': 9, '9': 0, '10': 'appVersion', '17': true},
  ],
  '8': [
    {'1': '_app_version'},
  ],
};

/// Descriptor for `Handshake`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List handshakeDescriptor = $convert.base64Decode(
    'CglIYW5kc2hha2USQgoIcmVnaXN0ZXIYASABKAsyJC5jbGllbnRfdG9fc2VydmVyLkhhbmRzaG'
    'FrZS5SZWdpc3RlckgAUghyZWdpc3RlchJaChBnZXRhdXRoY2hhbGxlbmdlGAIgASgLMiwuY2xp'
    'ZW50X3RvX3NlcnZlci5IYW5kc2hha2UuR2V0QXV0aENoYWxsZW5nZUgAUhBnZXRhdXRoY2hhbG'
    'xlbmdlEk4KDGdldGF1dGh0b2tlbhgDIAEoCzIoLmNsaWVudF90b19zZXJ2ZXIuSGFuZHNoYWtl'
    'LkdldEF1dGhUb2tlbkgAUgxnZXRhdXRodG9rZW4STgoMYXV0aGVudGljYXRlGAQgASgLMiguY2'
    'xpZW50X3RvX3NlcnZlci5IYW5kc2hha2UuQXV0aGVudGljYXRlSABSDGF1dGhlbnRpY2F0ZRrj'
    'AgoIUmVnaXN0ZXISGgoIdXNlcm5hbWUYASABKAlSCHVzZXJuYW1lEiQKC2ludml0ZV9jb2RlGA'
    'IgASgJSABSCmludml0ZUNvZGWIAQESLgoTcHVibGljX2lkZW50aXR5X2tleRgDIAEoDFIRcHVi'
    'bGljSWRlbnRpdHlLZXkSIwoNc2lnbmVkX3ByZWtleRgEIAEoDFIMc2lnbmVkUHJla2V5EjYKF3'
    'NpZ25lZF9wcmVrZXlfc2lnbmF0dXJlGAUgASgMUhVzaWduZWRQcmVrZXlTaWduYXR1cmUSKAoQ'
    'c2lnbmVkX3ByZWtleV9pZBgGIAEoA1IOc2lnbmVkUHJla2V5SWQSJwoPcmVnaXN0cmF0aW9uX2'
    'lkGAcgASgDUg5yZWdpc3RyYXRpb25JZBIaCgZpc19pb3MYCCABKAhIAVIFaXNJb3OIAQFCDgoM'
    'X2ludml0ZV9jb2RlQgkKB19pc19pb3MaEgoQR2V0QXV0aENoYWxsZW5nZRpDCgxHZXRBdXRoVG'
    '9rZW4SFwoHdXNlcl9pZBgBIAEoA1IGdXNlcklkEhoKCHJlc3BvbnNlGAIgASgMUghyZXNwb25z'
    'ZRp8CgxBdXRoZW50aWNhdGUSFwoHdXNlcl9pZBgBIAEoA1IGdXNlcklkEh0KCmF1dGhfdG9rZW'
    '4YAiABKAxSCWF1dGhUb2tlbhIkCgthcHBfdmVyc2lvbhgDIAEoCUgAUgphcHBWZXJzaW9uiAEB'
    'Qg4KDF9hcHBfdmVyc2lvbkILCglIYW5kc2hha2U=');

@$core.Deprecated('Use applicationDataDescriptor instead')
const ApplicationData$json = {
  '1': 'ApplicationData',
  '2': [
    {'1': 'textmessage', '3': 1, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.TextMessage', '9': 0, '10': 'textmessage'},
    {'1': 'getuserbyusername', '3': 2, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.GetUserByUsername', '9': 0, '10': 'getuserbyusername'},
    {'1': 'getprekeysbyuserid', '3': 3, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.GetPrekeysByUserId', '9': 0, '10': 'getprekeysbyuserid'},
    {'1': 'getuserbyid', '3': 6, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.GetUserById', '9': 0, '10': 'getuserbyid'},
    {'1': 'updategooglefcmtoken', '3': 8, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.UpdateGoogleFcmToken', '9': 0, '10': 'updategooglefcmtoken'},
    {'1': 'getlocation', '3': 9, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.GetLocation', '9': 0, '10': 'getlocation'},
    {'1': 'getcurrentplaninfos', '3': 10, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.GetCurrentPlanInfos', '9': 0, '10': 'getcurrentplaninfos'},
    {'1': 'redeemvoucher', '3': 11, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.RedeemVoucher', '9': 0, '10': 'redeemvoucher'},
    {'1': 'getavailableplans', '3': 12, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.GetAvailablePlans', '9': 0, '10': 'getavailableplans'},
    {'1': 'createvoucher', '3': 13, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.CreateVoucher', '9': 0, '10': 'createvoucher'},
    {'1': 'getvouchers', '3': 14, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.GetVouchers', '9': 0, '10': 'getvouchers'},
    {'1': 'Switchtopayedplan', '3': 15, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.SwitchToPayedPlan', '9': 0, '10': 'Switchtopayedplan'},
    {'1': 'getaddaccountsinvites', '3': 16, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.GetAddAccountsInvites', '9': 0, '10': 'getaddaccountsinvites'},
    {'1': 'redeemadditionalcode', '3': 17, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.RedeemAdditionalCode', '9': 0, '10': 'redeemadditionalcode'},
    {'1': 'removeadditionaluser', '3': 18, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.RemoveAdditionalUser', '9': 0, '10': 'removeadditionaluser'},
    {'1': 'updateplanoptions', '3': 19, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.UpdatePlanOptions', '9': 0, '10': 'updateplanoptions'},
    {'1': 'downloaddone', '3': 20, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.DownloadDone', '9': 0, '10': 'downloaddone'},
    {'1': 'getsignedprekeybyuserid', '3': 22, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.GetSignedPreKeyByUserId', '9': 0, '10': 'getsignedprekeybyuserid'},
    {'1': 'updatesignedprekey', '3': 23, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.UpdateSignedPreKey', '9': 0, '10': 'updatesignedprekey'},
    {'1': 'deleteaccount', '3': 24, '4': 1, '5': 11, '6': '.client_to_server.ApplicationData.DeleteAccount', '9': 0, '10': 'deleteaccount'},
  ],
  '3': [ApplicationData_TextMessage$json, ApplicationData_GetUserByUsername$json, ApplicationData_UpdateGoogleFcmToken$json, ApplicationData_GetUserById$json, ApplicationData_RedeemVoucher$json, ApplicationData_SwitchToPayedPlan$json, ApplicationData_UpdatePlanOptions$json, ApplicationData_CreateVoucher$json, ApplicationData_GetLocation$json, ApplicationData_GetVouchers$json, ApplicationData_GetAvailablePlans$json, ApplicationData_GetAddAccountsInvites$json, ApplicationData_GetCurrentPlanInfos$json, ApplicationData_RedeemAdditionalCode$json, ApplicationData_RemoveAdditionalUser$json, ApplicationData_GetPrekeysByUserId$json, ApplicationData_GetSignedPreKeyByUserId$json, ApplicationData_UpdateSignedPreKey$json, ApplicationData_DownloadDone$json, ApplicationData_DeleteAccount$json],
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
    {'1': 'push_data', '3': 4, '4': 1, '5': 12, '9': 0, '10': 'pushData', '17': true},
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
    {'1': 'signed_prekey_signature', '3': 3, '4': 1, '5': 12, '10': 'signedPrekeySignature'},
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
const ApplicationData_DeleteAccount$json = {
  '1': 'DeleteAccount',
};

/// Descriptor for `ApplicationData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List applicationDataDescriptor = $convert.base64Decode(
    'Cg9BcHBsaWNhdGlvbkRhdGESUQoLdGV4dG1lc3NhZ2UYASABKAsyLS5jbGllbnRfdG9fc2Vydm'
    'VyLkFwcGxpY2F0aW9uRGF0YS5UZXh0TWVzc2FnZUgAUgt0ZXh0bWVzc2FnZRJjChFnZXR1c2Vy'
    'Ynl1c2VybmFtZRgCIAEoCzIzLmNsaWVudF90b19zZXJ2ZXIuQXBwbGljYXRpb25EYXRhLkdldF'
    'VzZXJCeVVzZXJuYW1lSABSEWdldHVzZXJieXVzZXJuYW1lEmYKEmdldHByZWtleXNieXVzZXJp'
    'ZBgDIAEoCzI0LmNsaWVudF90b19zZXJ2ZXIuQXBwbGljYXRpb25EYXRhLkdldFByZWtleXNCeV'
    'VzZXJJZEgAUhJnZXRwcmVrZXlzYnl1c2VyaWQSUQoLZ2V0dXNlcmJ5aWQYBiABKAsyLS5jbGll'
    'bnRfdG9fc2VydmVyLkFwcGxpY2F0aW9uRGF0YS5HZXRVc2VyQnlJZEgAUgtnZXR1c2VyYnlpZB'
    'JsChR1cGRhdGVnb29nbGVmY210b2tlbhgIIAEoCzI2LmNsaWVudF90b19zZXJ2ZXIuQXBwbGlj'
    'YXRpb25EYXRhLlVwZGF0ZUdvb2dsZUZjbVRva2VuSABSFHVwZGF0ZWdvb2dsZWZjbXRva2VuEl'
    'EKC2dldGxvY2F0aW9uGAkgASgLMi0uY2xpZW50X3RvX3NlcnZlci5BcHBsaWNhdGlvbkRhdGEu'
    'R2V0TG9jYXRpb25IAFILZ2V0bG9jYXRpb24SaQoTZ2V0Y3VycmVudHBsYW5pbmZvcxgKIAEoCz'
    'I1LmNsaWVudF90b19zZXJ2ZXIuQXBwbGljYXRpb25EYXRhLkdldEN1cnJlbnRQbGFuSW5mb3NI'
    'AFITZ2V0Y3VycmVudHBsYW5pbmZvcxJXCg1yZWRlZW12b3VjaGVyGAsgASgLMi8uY2xpZW50X3'
    'RvX3NlcnZlci5BcHBsaWNhdGlvbkRhdGEuUmVkZWVtVm91Y2hlckgAUg1yZWRlZW12b3VjaGVy'
    'EmMKEWdldGF2YWlsYWJsZXBsYW5zGAwgASgLMjMuY2xpZW50X3RvX3NlcnZlci5BcHBsaWNhdG'
    'lvbkRhdGEuR2V0QXZhaWxhYmxlUGxhbnNIAFIRZ2V0YXZhaWxhYmxlcGxhbnMSVwoNY3JlYXRl'
    'dm91Y2hlchgNIAEoCzIvLmNsaWVudF90b19zZXJ2ZXIuQXBwbGljYXRpb25EYXRhLkNyZWF0ZV'
    'ZvdWNoZXJIAFINY3JlYXRldm91Y2hlchJRCgtnZXR2b3VjaGVycxgOIAEoCzItLmNsaWVudF90'
    'b19zZXJ2ZXIuQXBwbGljYXRpb25EYXRhLkdldFZvdWNoZXJzSABSC2dldHZvdWNoZXJzEmMKEV'
    'N3aXRjaHRvcGF5ZWRwbGFuGA8gASgLMjMuY2xpZW50X3RvX3NlcnZlci5BcHBsaWNhdGlvbkRh'
    'dGEuU3dpdGNoVG9QYXllZFBsYW5IAFIRU3dpdGNodG9wYXllZHBsYW4SbwoVZ2V0YWRkYWNjb3'
    'VudHNpbnZpdGVzGBAgASgLMjcuY2xpZW50X3RvX3NlcnZlci5BcHBsaWNhdGlvbkRhdGEuR2V0'
    'QWRkQWNjb3VudHNJbnZpdGVzSABSFWdldGFkZGFjY291bnRzaW52aXRlcxJsChRyZWRlZW1hZG'
    'RpdGlvbmFsY29kZRgRIAEoCzI2LmNsaWVudF90b19zZXJ2ZXIuQXBwbGljYXRpb25EYXRhLlJl'
    'ZGVlbUFkZGl0aW9uYWxDb2RlSABSFHJlZGVlbWFkZGl0aW9uYWxjb2RlEmwKFHJlbW92ZWFkZG'
    'l0aW9uYWx1c2VyGBIgASgLMjYuY2xpZW50X3RvX3NlcnZlci5BcHBsaWNhdGlvbkRhdGEuUmVt'
    'b3ZlQWRkaXRpb25hbFVzZXJIAFIUcmVtb3ZlYWRkaXRpb25hbHVzZXISYwoRdXBkYXRlcGxhbm'
    '9wdGlvbnMYEyABKAsyMy5jbGllbnRfdG9fc2VydmVyLkFwcGxpY2F0aW9uRGF0YS5VcGRhdGVQ'
    'bGFuT3B0aW9uc0gAUhF1cGRhdGVwbGFub3B0aW9ucxJUCgxkb3dubG9hZGRvbmUYFCABKAsyLi'
    '5jbGllbnRfdG9fc2VydmVyLkFwcGxpY2F0aW9uRGF0YS5Eb3dubG9hZERvbmVIAFIMZG93bmxv'
    'YWRkb25lEnUKF2dldHNpZ25lZHByZWtleWJ5dXNlcmlkGBYgASgLMjkuY2xpZW50X3RvX3Nlcn'
    'Zlci5BcHBsaWNhdGlvbkRhdGEuR2V0U2lnbmVkUHJlS2V5QnlVc2VySWRIAFIXZ2V0c2lnbmVk'
    'cHJla2V5Ynl1c2VyaWQSZgoSdXBkYXRlc2lnbmVkcHJla2V5GBcgASgLMjQuY2xpZW50X3RvX3'
    'NlcnZlci5BcHBsaWNhdGlvbkRhdGEuVXBkYXRlU2lnbmVkUHJlS2V5SABSEnVwZGF0ZXNpZ25l'
    'ZHByZWtleRJXCg1kZWxldGVhY2NvdW50GBggASgLMi8uY2xpZW50X3RvX3NlcnZlci5BcHBsaW'
    'NhdGlvbkRhdGEuRGVsZXRlQWNjb3VudEgAUg1kZWxldGVhY2NvdW50GmoKC1RleHRNZXNzYWdl'
    'EhcKB3VzZXJfaWQYASABKANSBnVzZXJJZBISCgRib2R5GAMgASgMUgRib2R5EiAKCXB1c2hfZG'
    'F0YRgEIAEoDEgAUghwdXNoRGF0YYgBAUIMCgpfcHVzaF9kYXRhGi8KEUdldFVzZXJCeVVzZXJu'
    'YW1lEhoKCHVzZXJuYW1lGAEgASgJUgh1c2VybmFtZRo1ChRVcGRhdGVHb29nbGVGY21Ub2tlbh'
    'IdCgpnb29nbGVfZmNtGAEgASgJUglnb29nbGVGY20aJgoLR2V0VXNlckJ5SWQSFwoHdXNlcl9p'
    'ZBgBIAEoA1IGdXNlcklkGikKDVJlZGVlbVZvdWNoZXISGAoHdm91Y2hlchgBIAEoCVIHdm91Y2'
    'hlchpwChFTd2l0Y2hUb1BheWVkUGxhbhIXCgdwbGFuX2lkGAEgASgJUgZwbGFuSWQSHwoLcGF5'
    'X21vbnRobHkYAiABKAhSCnBheU1vbnRobHkSIQoMYXV0b19yZW5ld2FsGAMgASgIUgthdXRvUm'
    'VuZXdhbBo2ChFVcGRhdGVQbGFuT3B0aW9ucxIhCgxhdXRvX3JlbmV3YWwYASABKAhSC2F1dG9S'
    'ZW5ld2FsGjAKDUNyZWF0ZVZvdWNoZXISHwoLdmFsdWVfY2VudHMYASABKA1SCnZhbHVlQ2VudH'
    'MaDQoLR2V0TG9jYXRpb24aDQoLR2V0Vm91Y2hlcnMaEwoRR2V0QXZhaWxhYmxlUGxhbnMaFwoV'
    'R2V0QWRkQWNjb3VudHNJbnZpdGVzGhUKE0dldEN1cnJlbnRQbGFuSW5mb3MaNwoUUmVkZWVtQW'
    'RkaXRpb25hbENvZGUSHwoLaW52aXRlX2NvZGUYAiABKAlSCmludml0ZUNvZGUaLwoUUmVtb3Zl'
    'QWRkaXRpb25hbFVzZXISFwoHdXNlcl9pZBgBIAEoA1IGdXNlcklkGi0KEkdldFByZWtleXNCeV'
    'VzZXJJZBIXCgd1c2VyX2lkGAEgASgDUgZ1c2VySWQaMgoXR2V0U2lnbmVkUHJlS2V5QnlVc2Vy'
    'SWQSFwoHdXNlcl9pZBgBIAEoA1IGdXNlcklkGpsBChJVcGRhdGVTaWduZWRQcmVLZXkSKAoQc2'
    'lnbmVkX3ByZWtleV9pZBgBIAEoA1IOc2lnbmVkUHJla2V5SWQSIwoNc2lnbmVkX3ByZWtleRgC'
    'IAEoDFIMc2lnbmVkUHJla2V5EjYKF3NpZ25lZF9wcmVrZXlfc2lnbmF0dXJlGAMgASgMUhVzaW'
    'duZWRQcmVrZXlTaWduYXR1cmUaNQoMRG93bmxvYWREb25lEiUKDmRvd25sb2FkX3Rva2VuGAEg'
    'ASgMUg1kb3dubG9hZFRva2VuGg8KDURlbGV0ZUFjY291bnRCEQoPQXBwbGljYXRpb25EYXRh');

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

