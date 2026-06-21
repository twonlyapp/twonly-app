// This is a generated file - do not edit.
//
// Generated from api/websocket/server_to_client.proto.

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

@$core.Deprecated('Use serverToClientDescriptor instead')
const ServerToClient$json = {
  '1': 'ServerToClient',
  '2': [
    {
      '1': 'V0',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.V0',
      '9': 0,
      '10': 'V0'
    },
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
    {
      '1': 'response',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.Response',
      '9': 0,
      '10': 'response'
    },
    {
      '1': 'newMessage',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.NewMessage',
      '9': 0,
      '10': 'newMessage'
    },
    {
      '1': 'newMessages',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.NewMessages',
      '9': 0,
      '10': 'newMessages'
    },
    {
      '1': 'RequestNewPreKeys',
      '3': 4,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'RequestNewPreKeys'
    },
    {
      '1': 'error',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.error.ErrorCode',
      '9': 0,
      '10': 'error'
    },
  ],
  '8': [
    {'1': 'Kind'},
  ],
};

/// Descriptor for `V0`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List v0Descriptor = $convert.base64Decode(
    'CgJWMBIQCgNzZXEYASABKARSA3NlcRI4CghyZXNwb25zZRgCIAEoCzIaLnNlcnZlcl90b19jbG'
    'llbnQuUmVzcG9uc2VIAFIIcmVzcG9uc2USPgoKbmV3TWVzc2FnZRgDIAEoCzIcLnNlcnZlcl90'
    'b19jbGllbnQuTmV3TWVzc2FnZUgAUgpuZXdNZXNzYWdlEkEKC25ld01lc3NhZ2VzGAcgASgLMh'
    '0uc2VydmVyX3RvX2NsaWVudC5OZXdNZXNzYWdlc0gAUgtuZXdNZXNzYWdlcxIuChFSZXF1ZXN0'
    'TmV3UHJlS2V5cxgEIAEoCEgAUhFSZXF1ZXN0TmV3UHJlS2V5cxIoCgVlcnJvchgGIAEoDjIQLm'
    'Vycm9yLkVycm9yQ29kZUgAUgVlcnJvckIGCgRLaW5k');

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

@$core.Deprecated('Use newMessagesDescriptor instead')
const NewMessages$json = {
  '1': 'NewMessages',
  '2': [
    {
      '1': 'newMessages',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.server_to_client.NewMessage',
      '10': 'newMessages'
    },
  ],
};

/// Descriptor for `NewMessages`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List newMessagesDescriptor = $convert.base64Decode(
    'CgtOZXdNZXNzYWdlcxI+CgtuZXdNZXNzYWdlcxgBIAMoCzIcLnNlcnZlcl90b19jbGllbnQuTm'
    'V3TWVzc2FnZVILbmV3TWVzc2FnZXM=');

@$core.Deprecated('Use responseDescriptor instead')
const Response$json = {
  '1': 'Response',
  '2': [
    {
      '1': 'ok',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.Response.Ok',
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
    Response_Authenticated$json,
    Response_Plan$json,
    Response_Plans$json,
    Response_AddAccountsInvite$json,
    Response_AddAccountsInvites$json,
    Response_AdditionalAccount$json,
    Response_Deprecated$json,
    Response_Transaction$json,
    Response_PlanBallance$json,
    Response_PreKey$json,
    Response_SignedPreKey$json,
    Response_UserData$json,
    Response_UploadToken$json,
    Response_DownloadTokens$json,
    Response_ProofOfWork$json,
    Response_Ok$json
  ],
  '8': [
    {'1': 'Response'},
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_Authenticated$json = {
  '1': 'Authenticated',
  '2': [
    {'1': 'plan', '3': 1, '4': 1, '5': 9, '10': 'plan'},
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_Plan$json = {
  '1': 'Plan',
  '2': [
    {'1': 'plan_id', '3': 1, '4': 1, '5': 9, '10': 'planId'},
    {'1': 'upload_size_limit', '3': 2, '4': 1, '5': 3, '10': 'uploadSizeLimit'},
    {
      '1': 'daily_media_upload_limit',
      '3': 3,
      '4': 1,
      '5': 3,
      '10': 'dailyMediaUploadLimit'
    },
    {
      '1': 'maximal_upload_size_of_single_media_size',
      '3': 4,
      '4': 1,
      '5': 3,
      '10': 'maximalUploadSizeOfSingleMediaSize'
    },
    {
      '1': 'additional_plus_accounts',
      '3': 5,
      '4': 1,
      '5': 3,
      '10': 'additionalPlusAccounts'
    },
    {
      '1': 'monthly_costs_cent',
      '3': 7,
      '4': 1,
      '5': 3,
      '10': 'monthlyCostsCent'
    },
    {'1': 'yearly_costs_cent', '3': 8, '4': 1, '5': 3, '10': 'yearlyCostsCent'},
    {
      '1': 'allowed_to_send_text_messages',
      '3': 9,
      '4': 1,
      '5': 8,
      '10': 'allowedToSendTextMessages'
    },
    {
      '1': 'is_additional_account',
      '3': 10,
      '4': 1,
      '5': 8,
      '10': 'isAdditionalAccount'
    },
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_Plans$json = {
  '1': 'Plans',
  '2': [
    {
      '1': 'plans',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.server_to_client.Response.Plan',
      '10': 'plans'
    },
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_AddAccountsInvite$json = {
  '1': 'AddAccountsInvite',
  '2': [
    {'1': 'plan_id', '3': 1, '4': 1, '5': 9, '10': 'planId'},
    {'1': 'invite_code', '3': 2, '4': 1, '5': 9, '10': 'inviteCode'},
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_AddAccountsInvites$json = {
  '1': 'AddAccountsInvites',
  '2': [
    {
      '1': 'invites',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.server_to_client.Response.AddAccountsInvite',
      '10': 'invites'
    },
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_AdditionalAccount$json = {
  '1': 'AdditionalAccount',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 3, '10': 'userId'},
    {'1': 'plan_id', '3': 3, '4': 1, '5': 9, '10': 'planId'},
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_Deprecated$json = {
  '1': 'Deprecated',
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_Transaction$json = {
  '1': 'Transaction',
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_PlanBallance$json = {
  '1': 'PlanBallance',
  '2': [
    {
      '1': 'used_daily_media_upload_limit',
      '3': 1,
      '4': 1,
      '5': 3,
      '10': 'usedDailyMediaUploadLimit'
    },
    {
      '1': 'used_upload_media_size_limit',
      '3': 2,
      '4': 1,
      '5': 3,
      '10': 'usedUploadMediaSizeLimit'
    },
    {
      '1': 'payment_period_days',
      '3': 3,
      '4': 1,
      '5': 3,
      '9': 0,
      '10': 'paymentPeriodDays',
      '17': true
    },
    {
      '1': 'last_payment_done_unix_timestamp',
      '3': 4,
      '4': 1,
      '5': 3,
      '9': 1,
      '10': 'lastPaymentDoneUnixTimestamp',
      '17': true
    },
    {
      '1': 'transactions',
      '3': 5,
      '4': 3,
      '5': 11,
      '6': '.server_to_client.Response.Transaction',
      '10': 'transactions'
    },
    {
      '1': 'additional_accounts',
      '3': 6,
      '4': 3,
      '5': 11,
      '6': '.server_to_client.Response.AdditionalAccount',
      '10': 'additionalAccounts'
    },
    {
      '1': 'auto_renewal',
      '3': 7,
      '4': 1,
      '5': 8,
      '9': 2,
      '10': 'autoRenewal',
      '17': true
    },
    {
      '1': 'additional_account_owner_id',
      '3': 8,
      '4': 1,
      '5': 3,
      '9': 3,
      '10': 'additionalAccountOwnerId',
      '17': true
    },
  ],
  '8': [
    {'1': '_payment_period_days'},
    {'1': '_last_payment_done_unix_timestamp'},
    {'1': '_auto_renewal'},
    {'1': '_additional_account_owner_id'},
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
const Response_SignedPreKey$json = {
  '1': 'SignedPreKey',
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

@$core.Deprecated('Use responseDescriptor instead')
const Response_UserData$json = {
  '1': 'UserData',
  '2': [
    {'1': 'user_id', '3': 1, '4': 1, '5': 3, '10': 'userId'},
    {
      '1': 'prekeys',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.server_to_client.Response.PreKey',
      '10': 'prekeys'
    },
    {
      '1': 'username',
      '3': 7,
      '4': 1,
      '5': 12,
      '9': 0,
      '10': 'username',
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
      '3': 8,
      '4': 1,
      '5': 3,
      '9': 5,
      '10': 'registrationId',
      '17': true
    },
  ],
  '8': [
    {'1': '_username'},
    {'1': '_public_identity_key'},
    {'1': '_signed_prekey'},
    {'1': '_signed_prekey_signature'},
    {'1': '_signed_prekey_id'},
    {'1': '_registration_id'},
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
const Response_DownloadTokens$json = {
  '1': 'DownloadTokens',
  '2': [
    {'1': 'download_tokens', '3': 1, '4': 3, '5': 12, '10': 'downloadTokens'},
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_ProofOfWork$json = {
  '1': 'ProofOfWork',
  '2': [
    {'1': 'prefix', '3': 1, '4': 1, '5': 9, '10': 'prefix'},
    {'1': 'difficulty', '3': 2, '4': 1, '5': 3, '10': 'difficulty'},
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_Ok$json = {
  '1': 'Ok',
  '2': [
    {'1': 'None', '3': 1, '4': 1, '5': 8, '9': 0, '10': 'None'},
    {'1': 'userid', '3': 2, '4': 1, '5': 3, '9': 0, '10': 'userid'},
    {
      '1': 'authchallenge',
      '3': 3,
      '4': 1,
      '5': 12,
      '9': 0,
      '10': 'authchallenge'
    },
    {
      '1': 'uploadtoken',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.Response.UploadToken',
      '9': 0,
      '10': 'uploadtoken'
    },
    {
      '1': 'userdata',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.Response.UserData',
      '9': 0,
      '10': 'userdata'
    },
    {'1': 'authtoken', '3': 6, '4': 1, '5': 12, '9': 0, '10': 'authtoken'},
    {
      '1': 'deprecated_7',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.Response.Deprecated',
      '9': 0,
      '10': 'deprecated7'
    },
    {
      '1': 'authenticated',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.Response.Authenticated',
      '9': 0,
      '10': 'authenticated'
    },
    {
      '1': 'plans',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.Response.Plans',
      '9': 0,
      '10': 'plans'
    },
    {
      '1': 'planballance',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.Response.PlanBallance',
      '9': 0,
      '10': 'planballance'
    },
    {
      '1': 'deprecated_11',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.Response.Deprecated',
      '9': 0,
      '10': 'deprecated11'
    },
    {
      '1': 'addaccountsinvites',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.Response.AddAccountsInvites',
      '9': 0,
      '10': 'addaccountsinvites'
    },
    {
      '1': 'downloadtokens',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.Response.DownloadTokens',
      '9': 0,
      '10': 'downloadtokens'
    },
    {
      '1': 'signedprekey',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.Response.SignedPreKey',
      '9': 0,
      '10': 'signedprekey'
    },
    {
      '1': 'proofOfWork',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.Response.ProofOfWork',
      '9': 0,
      '10': 'proofOfWork'
    },
    {
      '1': 'passwordless_recovery_server_key',
      '3': 16,
      '4': 1,
      '5': 12,
      '9': 0,
      '10': 'passwordlessRecoveryServerKey'
    },
  ],
  '8': [
    {'1': 'Ok'},
  ],
};

/// Descriptor for `Response`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseDescriptor = $convert.base64Decode(
    'CghSZXNwb25zZRIvCgJvaxgBIAEoCzIdLnNlcnZlcl90b19jbGllbnQuUmVzcG9uc2UuT2tIAF'
    'ICb2sSKAoFZXJyb3IYAiABKA4yEC5lcnJvci5FcnJvckNvZGVIAFIFZXJyb3IaIwoNQXV0aGVu'
    'dGljYXRlZBISCgRwbGFuGAEgASgJUgRwbGFuGuQDCgRQbGFuEhcKB3BsYW5faWQYASABKAlSBn'
    'BsYW5JZBIqChF1cGxvYWRfc2l6ZV9saW1pdBgCIAEoA1IPdXBsb2FkU2l6ZUxpbWl0EjcKGGRh'
    'aWx5X21lZGlhX3VwbG9hZF9saW1pdBgDIAEoA1IVZGFpbHlNZWRpYVVwbG9hZExpbWl0ElQKKG'
    '1heGltYWxfdXBsb2FkX3NpemVfb2Zfc2luZ2xlX21lZGlhX3NpemUYBCABKANSIm1heGltYWxV'
    'cGxvYWRTaXplT2ZTaW5nbGVNZWRpYVNpemUSOAoYYWRkaXRpb25hbF9wbHVzX2FjY291bnRzGA'
    'UgASgDUhZhZGRpdGlvbmFsUGx1c0FjY291bnRzEiwKEm1vbnRobHlfY29zdHNfY2VudBgHIAEo'
    'A1IQbW9udGhseUNvc3RzQ2VudBIqChF5ZWFybHlfY29zdHNfY2VudBgIIAEoA1IPeWVhcmx5Q2'
    '9zdHNDZW50EkAKHWFsbG93ZWRfdG9fc2VuZF90ZXh0X21lc3NhZ2VzGAkgASgIUhlhbGxvd2Vk'
    'VG9TZW5kVGV4dE1lc3NhZ2VzEjIKFWlzX2FkZGl0aW9uYWxfYWNjb3VudBgKIAEoCFITaXNBZG'
    'RpdGlvbmFsQWNjb3VudBo+CgVQbGFucxI1CgVwbGFucxgBIAMoCzIfLnNlcnZlcl90b19jbGll'
    'bnQuUmVzcG9uc2UuUGxhblIFcGxhbnMaTQoRQWRkQWNjb3VudHNJbnZpdGUSFwoHcGxhbl9pZB'
    'gBIAEoCVIGcGxhbklkEh8KC2ludml0ZV9jb2RlGAIgASgJUgppbnZpdGVDb2RlGlwKEkFkZEFj'
    'Y291bnRzSW52aXRlcxJGCgdpbnZpdGVzGAEgAygLMiwuc2VydmVyX3RvX2NsaWVudC5SZXNwb2'
    '5zZS5BZGRBY2NvdW50c0ludml0ZVIHaW52aXRlcxpFChFBZGRpdGlvbmFsQWNjb3VudBIXCgd1'
    'c2VyX2lkGAEgASgDUgZ1c2VySWQSFwoHcGxhbl9pZBgDIAEoCVIGcGxhbklkGgwKCkRlcHJlY2'
    'F0ZWQaDQoLVHJhbnNhY3Rpb24alwUKDFBsYW5CYWxsYW5jZRJACh11c2VkX2RhaWx5X21lZGlh'
    'X3VwbG9hZF9saW1pdBgBIAEoA1IZdXNlZERhaWx5TWVkaWFVcGxvYWRMaW1pdBI+Chx1c2VkX3'
    'VwbG9hZF9tZWRpYV9zaXplX2xpbWl0GAIgASgDUhh1c2VkVXBsb2FkTWVkaWFTaXplTGltaXQS'
    'MwoTcGF5bWVudF9wZXJpb2RfZGF5cxgDIAEoA0gAUhFwYXltZW50UGVyaW9kRGF5c4gBARJLCi'
    'BsYXN0X3BheW1lbnRfZG9uZV91bml4X3RpbWVzdGFtcBgEIAEoA0gBUhxsYXN0UGF5bWVudERv'
    'bmVVbml4VGltZXN0YW1wiAEBEkoKDHRyYW5zYWN0aW9ucxgFIAMoCzImLnNlcnZlcl90b19jbG'
    'llbnQuUmVzcG9uc2UuVHJhbnNhY3Rpb25SDHRyYW5zYWN0aW9ucxJdChNhZGRpdGlvbmFsX2Fj'
    'Y291bnRzGAYgAygLMiwuc2VydmVyX3RvX2NsaWVudC5SZXNwb25zZS5BZGRpdGlvbmFsQWNjb3'
    'VudFISYWRkaXRpb25hbEFjY291bnRzEiYKDGF1dG9fcmVuZXdhbBgHIAEoCEgCUgthdXRvUmVu'
    'ZXdhbIgBARJCChthZGRpdGlvbmFsX2FjY291bnRfb3duZXJfaWQYCCABKANIA1IYYWRkaXRpb2'
    '5hbEFjY291bnRPd25lcklkiAEBQhYKFF9wYXltZW50X3BlcmlvZF9kYXlzQiMKIV9sYXN0X3Bh'
    'eW1lbnRfZG9uZV91bml4X3RpbWVzdGFtcEIPCg1fYXV0b19yZW5ld2FsQh4KHF9hZGRpdGlvbm'
    'FsX2FjY291bnRfb3duZXJfaWQaMAoGUHJlS2V5Eg4KAmlkGAEgASgDUgJpZBIWCgZwcmVrZXkY'
    'AiABKAxSBnByZWtleRqVAQoMU2lnbmVkUHJlS2V5EigKEHNpZ25lZF9wcmVrZXlfaWQYASABKA'
    'NSDnNpZ25lZFByZWtleUlkEiMKDXNpZ25lZF9wcmVrZXkYAiABKAxSDHNpZ25lZFByZWtleRI2'
    'ChdzaWduZWRfcHJla2V5X3NpZ25hdHVyZRgDIAEoDFIVc2lnbmVkUHJla2V5U2lnbmF0dXJlGv'
    'YDCghVc2VyRGF0YRIXCgd1c2VyX2lkGAEgASgDUgZ1c2VySWQSOwoHcHJla2V5cxgCIAMoCzIh'
    'LnNlcnZlcl90b19jbGllbnQuUmVzcG9uc2UuUHJlS2V5UgdwcmVrZXlzEh8KCHVzZXJuYW1lGA'
    'cgASgMSABSCHVzZXJuYW1liAEBEjMKE3B1YmxpY19pZGVudGl0eV9rZXkYAyABKAxIAVIRcHVi'
    'bGljSWRlbnRpdHlLZXmIAQESKAoNc2lnbmVkX3ByZWtleRgEIAEoDEgCUgxzaWduZWRQcmVrZX'
    'mIAQESOwoXc2lnbmVkX3ByZWtleV9zaWduYXR1cmUYBSABKAxIA1IVc2lnbmVkUHJla2V5U2ln'
    'bmF0dXJliAEBEi0KEHNpZ25lZF9wcmVrZXlfaWQYBiABKANIBFIOc2lnbmVkUHJla2V5SWSIAQ'
    'ESLAoPcmVnaXN0cmF0aW9uX2lkGAggASgDSAVSDnJlZ2lzdHJhdGlvbklkiAEBQgsKCV91c2Vy'
    'bmFtZUIWChRfcHVibGljX2lkZW50aXR5X2tleUIQCg5fc2lnbmVkX3ByZWtleUIaChhfc2lnbm'
    'VkX3ByZWtleV9zaWduYXR1cmVCEwoRX3NpZ25lZF9wcmVrZXlfaWRCEgoQX3JlZ2lzdHJhdGlv'
    'bl9pZBpZCgtVcGxvYWRUb2tlbhIhCgx1cGxvYWRfdG9rZW4YASABKAxSC3VwbG9hZFRva2VuEi'
    'cKD2Rvd25sb2FkX3Rva2VucxgCIAMoDFIOZG93bmxvYWRUb2tlbnMaOQoORG93bmxvYWRUb2tl'
    'bnMSJwoPZG93bmxvYWRfdG9rZW5zGAEgAygMUg5kb3dubG9hZFRva2VucxpFCgtQcm9vZk9mV2'
    '9yaxIWCgZwcmVmaXgYASABKAlSBnByZWZpeBIeCgpkaWZmaWN1bHR5GAIgASgDUgpkaWZmaWN1'
    'bHR5GqIICgJPaxIUCgROb25lGAEgASgISABSBE5vbmUSGAoGdXNlcmlkGAIgASgDSABSBnVzZX'
    'JpZBImCg1hdXRoY2hhbGxlbmdlGAMgASgMSABSDWF1dGhjaGFsbGVuZ2USSgoLdXBsb2FkdG9r'
    'ZW4YBCABKAsyJi5zZXJ2ZXJfdG9fY2xpZW50LlJlc3BvbnNlLlVwbG9hZFRva2VuSABSC3VwbG'
    '9hZHRva2VuEkEKCHVzZXJkYXRhGAUgASgLMiMuc2VydmVyX3RvX2NsaWVudC5SZXNwb25zZS5V'
    'c2VyRGF0YUgAUgh1c2VyZGF0YRIeCglhdXRodG9rZW4YBiABKAxIAFIJYXV0aHRva2VuEkoKDG'
    'RlcHJlY2F0ZWRfNxgHIAEoCzIlLnNlcnZlcl90b19jbGllbnQuUmVzcG9uc2UuRGVwcmVjYXRl'
    'ZEgAUgtkZXByZWNhdGVkNxJQCg1hdXRoZW50aWNhdGVkGAggASgLMiguc2VydmVyX3RvX2NsaW'
    'VudC5SZXNwb25zZS5BdXRoZW50aWNhdGVkSABSDWF1dGhlbnRpY2F0ZWQSOAoFcGxhbnMYCSAB'
    'KAsyIC5zZXJ2ZXJfdG9fY2xpZW50LlJlc3BvbnNlLlBsYW5zSABSBXBsYW5zEk0KDHBsYW5iYW'
    'xsYW5jZRgKIAEoCzInLnNlcnZlcl90b19jbGllbnQuUmVzcG9uc2UuUGxhbkJhbGxhbmNlSABS'
    'DHBsYW5iYWxsYW5jZRJMCg1kZXByZWNhdGVkXzExGAsgASgLMiUuc2VydmVyX3RvX2NsaWVudC'
    '5SZXNwb25zZS5EZXByZWNhdGVkSABSDGRlcHJlY2F0ZWQxMRJfChJhZGRhY2NvdW50c2ludml0'
    'ZXMYDCABKAsyLS5zZXJ2ZXJfdG9fY2xpZW50LlJlc3BvbnNlLkFkZEFjY291bnRzSW52aXRlc0'
    'gAUhJhZGRhY2NvdW50c2ludml0ZXMSUwoOZG93bmxvYWR0b2tlbnMYDSABKAsyKS5zZXJ2ZXJf'
    'dG9fY2xpZW50LlJlc3BvbnNlLkRvd25sb2FkVG9rZW5zSABSDmRvd25sb2FkdG9rZW5zEk0KDH'
    'NpZ25lZHByZWtleRgOIAEoCzInLnNlcnZlcl90b19jbGllbnQuUmVzcG9uc2UuU2lnbmVkUHJl'
    'S2V5SABSDHNpZ25lZHByZWtleRJKCgtwcm9vZk9mV29yaxgPIAEoCzImLnNlcnZlcl90b19jbG'
    'llbnQuUmVzcG9uc2UuUHJvb2ZPZldvcmtIAFILcHJvb2ZPZldvcmsSSQogcGFzc3dvcmRsZXNz'
    'X3JlY292ZXJ5X3NlcnZlcl9rZXkYECABKAxIAFIdcGFzc3dvcmRsZXNzUmVjb3ZlcnlTZXJ2ZX'
    'JLZXlCBAoCT2tCCgoIUmVzcG9uc2U=');
