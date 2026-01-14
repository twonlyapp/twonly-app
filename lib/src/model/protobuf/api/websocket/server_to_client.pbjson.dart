// This is a generated file - do not edit.
//
// Generated from api/websocket/server_to_client.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

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
    Response_Transaction$json,
    Response_AdditionalAccount$json,
    Response_Voucher$json,
    Response_Vouchers$json,
    Response_PlanBallance$json,
    Response_Location$json,
    Response_PreKey$json,
    Response_SignedPreKey$json,
    Response_UserData$json,
    Response_UploadToken$json,
    Response_DownloadTokens$json,
    Response_ProofOfWork$json,
    Response_Ok$json
  ],
  '4': [Response_TransactionTypes$json],
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
const Response_Transaction$json = {
  '1': 'Transaction',
  '2': [
    {'1': 'deposit_cents', '3': 1, '4': 1, '5': 3, '10': 'depositCents'},
    {
      '1': 'transaction_type',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.server_to_client.Response.TransactionTypes',
      '10': 'transactionType'
    },
    {
      '1': 'created_at_unix_timestamp',
      '3': 3,
      '4': 1,
      '5': 3,
      '10': 'createdAtUnixTimestamp'
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
const Response_Voucher$json = {
  '1': 'Voucher',
  '2': [
    {'1': 'voucher_id', '3': 1, '4': 1, '5': 9, '10': 'voucherId'},
    {'1': 'value_cents', '3': 2, '4': 1, '5': 3, '10': 'valueCents'},
    {'1': 'redeemed', '3': 3, '4': 1, '5': 8, '10': 'redeemed'},
    {'1': 'requested', '3': 4, '4': 1, '5': 8, '10': 'requested'},
    {
      '1': 'created_at_unix_timestamp',
      '3': 5,
      '4': 1,
      '5': 3,
      '10': 'createdAtUnixTimestamp'
    },
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_Vouchers$json = {
  '1': 'Vouchers',
  '2': [
    {
      '1': 'vouchers',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.server_to_client.Response.Voucher',
      '10': 'vouchers'
    },
  ],
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
      '1': 'location',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.Response.Location',
      '9': 0,
      '10': 'location'
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
      '1': 'vouchers',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.Response.Vouchers',
      '9': 0,
      '10': 'vouchers'
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
  ],
  '8': [
    {'1': 'Ok'},
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_TransactionTypes$json = {
  '1': 'TransactionTypes',
  '2': [
    {'1': 'Refund', '2': 0},
    {'1': 'VoucherRedeemed', '2': 1},
    {'1': 'VoucherCreated', '2': 2},
    {'1': 'Cash', '2': 3},
    {'1': 'PlanUpgrade', '2': 4},
    {'1': 'Unknown', '2': 5},
    {'1': 'ThanksForTesting', '2': 6},
    {'1': 'AutoRenewal', '2': 7},
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
    '5zZS5BZGRBY2NvdW50c0ludml0ZVIHaW52aXRlcxrFAQoLVHJhbnNhY3Rpb24SIwoNZGVwb3Np'
    'dF9jZW50cxgBIAEoA1IMZGVwb3NpdENlbnRzElYKEHRyYW5zYWN0aW9uX3R5cGUYAiABKA4yKy'
    '5zZXJ2ZXJfdG9fY2xpZW50LlJlc3BvbnNlLlRyYW5zYWN0aW9uVHlwZXNSD3RyYW5zYWN0aW9u'
    'VHlwZRI5ChljcmVhdGVkX2F0X3VuaXhfdGltZXN0YW1wGAMgASgDUhZjcmVhdGVkQXRVbml4VG'
    'ltZXN0YW1wGkUKEUFkZGl0aW9uYWxBY2NvdW50EhcKB3VzZXJfaWQYASABKANSBnVzZXJJZBIX'
    'CgdwbGFuX2lkGAMgASgJUgZwbGFuSWQavgEKB1ZvdWNoZXISHQoKdm91Y2hlcl9pZBgBIAEoCV'
    'IJdm91Y2hlcklkEh8KC3ZhbHVlX2NlbnRzGAIgASgDUgp2YWx1ZUNlbnRzEhoKCHJlZGVlbWVk'
    'GAMgASgIUghyZWRlZW1lZBIcCglyZXF1ZXN0ZWQYBCABKAhSCXJlcXVlc3RlZBI5ChljcmVhdG'
    'VkX2F0X3VuaXhfdGltZXN0YW1wGAUgASgDUhZjcmVhdGVkQXRVbml4VGltZXN0YW1wGkoKCFZv'
    'dWNoZXJzEj4KCHZvdWNoZXJzGAEgAygLMiIuc2VydmVyX3RvX2NsaWVudC5SZXNwb25zZS5Wb3'
    'VjaGVyUgh2b3VjaGVycxqXBQoMUGxhbkJhbGxhbmNlEkAKHXVzZWRfZGFpbHlfbWVkaWFfdXBs'
    'b2FkX2xpbWl0GAEgASgDUhl1c2VkRGFpbHlNZWRpYVVwbG9hZExpbWl0Ej4KHHVzZWRfdXBsb2'
    'FkX21lZGlhX3NpemVfbGltaXQYAiABKANSGHVzZWRVcGxvYWRNZWRpYVNpemVMaW1pdBIzChNw'
    'YXltZW50X3BlcmlvZF9kYXlzGAMgASgDSABSEXBheW1lbnRQZXJpb2REYXlziAEBEksKIGxhc3'
    'RfcGF5bWVudF9kb25lX3VuaXhfdGltZXN0YW1wGAQgASgDSAFSHGxhc3RQYXltZW50RG9uZVVu'
    'aXhUaW1lc3RhbXCIAQESSgoMdHJhbnNhY3Rpb25zGAUgAygLMiYuc2VydmVyX3RvX2NsaWVudC'
    '5SZXNwb25zZS5UcmFuc2FjdGlvblIMdHJhbnNhY3Rpb25zEl0KE2FkZGl0aW9uYWxfYWNjb3Vu'
    'dHMYBiADKAsyLC5zZXJ2ZXJfdG9fY2xpZW50LlJlc3BvbnNlLkFkZGl0aW9uYWxBY2NvdW50Uh'
    'JhZGRpdGlvbmFsQWNjb3VudHMSJgoMYXV0b19yZW5ld2FsGAcgASgISAJSC2F1dG9SZW5ld2Fs'
    'iAEBEkIKG2FkZGl0aW9uYWxfYWNjb3VudF9vd25lcl9pZBgIIAEoA0gDUhhhZGRpdGlvbmFsQW'
    'Njb3VudE93bmVySWSIAQFCFgoUX3BheW1lbnRfcGVyaW9kX2RheXNCIwohX2xhc3RfcGF5bWVu'
    'dF9kb25lX3VuaXhfdGltZXN0YW1wQg8KDV9hdXRvX3JlbmV3YWxCHgocX2FkZGl0aW9uYWxfYW'
    'Njb3VudF9vd25lcl9pZBpOCghMb2NhdGlvbhIWCgZjb3VudHkYASABKAlSBmNvdW50eRIWCgZy'
    'ZWdpb24YAiABKAlSBnJlZ2lvbhISCgRjaXR5GAMgASgJUgRjaXR5GjAKBlByZUtleRIOCgJpZB'
    'gBIAEoA1ICaWQSFgoGcHJla2V5GAIgASgMUgZwcmVrZXkalQEKDFNpZ25lZFByZUtleRIoChBz'
    'aWduZWRfcHJla2V5X2lkGAEgASgDUg5zaWduZWRQcmVrZXlJZBIjCg1zaWduZWRfcHJla2V5GA'
    'IgASgMUgxzaWduZWRQcmVrZXkSNgoXc2lnbmVkX3ByZWtleV9zaWduYXR1cmUYAyABKAxSFXNp'
    'Z25lZFByZWtleVNpZ25hdHVyZRr2AwoIVXNlckRhdGESFwoHdXNlcl9pZBgBIAEoA1IGdXNlck'
    'lkEjsKB3ByZWtleXMYAiADKAsyIS5zZXJ2ZXJfdG9fY2xpZW50LlJlc3BvbnNlLlByZUtleVIH'
    'cHJla2V5cxIfCgh1c2VybmFtZRgHIAEoDEgAUgh1c2VybmFtZYgBARIzChNwdWJsaWNfaWRlbn'
    'RpdHlfa2V5GAMgASgMSAFSEXB1YmxpY0lkZW50aXR5S2V5iAEBEigKDXNpZ25lZF9wcmVrZXkY'
    'BCABKAxIAlIMc2lnbmVkUHJla2V5iAEBEjsKF3NpZ25lZF9wcmVrZXlfc2lnbmF0dXJlGAUgAS'
    'gMSANSFXNpZ25lZFByZWtleVNpZ25hdHVyZYgBARItChBzaWduZWRfcHJla2V5X2lkGAYgASgD'
    'SARSDnNpZ25lZFByZWtleUlkiAEBEiwKD3JlZ2lzdHJhdGlvbl9pZBgIIAEoA0gFUg5yZWdpc3'
    'RyYXRpb25JZIgBAUILCglfdXNlcm5hbWVCFgoUX3B1YmxpY19pZGVudGl0eV9rZXlCEAoOX3Np'
    'Z25lZF9wcmVrZXlCGgoYX3NpZ25lZF9wcmVrZXlfc2lnbmF0dXJlQhMKEV9zaWduZWRfcHJla2'
    'V5X2lkQhIKEF9yZWdpc3RyYXRpb25faWQaWQoLVXBsb2FkVG9rZW4SIQoMdXBsb2FkX3Rva2Vu'
    'GAEgASgMUgt1cGxvYWRUb2tlbhInCg9kb3dubG9hZF90b2tlbnMYAiADKAxSDmRvd25sb2FkVG'
    '9rZW5zGjkKDkRvd25sb2FkVG9rZW5zEicKD2Rvd25sb2FkX3Rva2VucxgBIAMoDFIOZG93bmxv'
    'YWRUb2tlbnMaRQoLUHJvb2ZPZldvcmsSFgoGcHJlZml4GAEgASgJUgZwcmVmaXgSHgoKZGlmZm'
    'ljdWx0eRgCIAEoA1IKZGlmZmljdWx0eRrDBwoCT2sSFAoETm9uZRgBIAEoCEgAUgROb25lEhgK'
    'BnVzZXJpZBgCIAEoA0gAUgZ1c2VyaWQSJgoNYXV0aGNoYWxsZW5nZRgDIAEoDEgAUg1hdXRoY2'
    'hhbGxlbmdlEkoKC3VwbG9hZHRva2VuGAQgASgLMiYuc2VydmVyX3RvX2NsaWVudC5SZXNwb25z'
    'ZS5VcGxvYWRUb2tlbkgAUgt1cGxvYWR0b2tlbhJBCgh1c2VyZGF0YRgFIAEoCzIjLnNlcnZlcl'
    '90b19jbGllbnQuUmVzcG9uc2UuVXNlckRhdGFIAFIIdXNlcmRhdGESHgoJYXV0aHRva2VuGAYg'
    'ASgMSABSCWF1dGh0b2tlbhJBCghsb2NhdGlvbhgHIAEoCzIjLnNlcnZlcl90b19jbGllbnQuUm'
    'VzcG9uc2UuTG9jYXRpb25IAFIIbG9jYXRpb24SUAoNYXV0aGVudGljYXRlZBgIIAEoCzIoLnNl'
    'cnZlcl90b19jbGllbnQuUmVzcG9uc2UuQXV0aGVudGljYXRlZEgAUg1hdXRoZW50aWNhdGVkEj'
    'gKBXBsYW5zGAkgASgLMiAuc2VydmVyX3RvX2NsaWVudC5SZXNwb25zZS5QbGFuc0gAUgVwbGFu'
    'cxJNCgxwbGFuYmFsbGFuY2UYCiABKAsyJy5zZXJ2ZXJfdG9fY2xpZW50LlJlc3BvbnNlLlBsYW'
    '5CYWxsYW5jZUgAUgxwbGFuYmFsbGFuY2USQQoIdm91Y2hlcnMYCyABKAsyIy5zZXJ2ZXJfdG9f'
    'Y2xpZW50LlJlc3BvbnNlLlZvdWNoZXJzSABSCHZvdWNoZXJzEl8KEmFkZGFjY291bnRzaW52aX'
    'RlcxgMIAEoCzItLnNlcnZlcl90b19jbGllbnQuUmVzcG9uc2UuQWRkQWNjb3VudHNJbnZpdGVz'
    'SABSEmFkZGFjY291bnRzaW52aXRlcxJTCg5kb3dubG9hZHRva2VucxgNIAEoCzIpLnNlcnZlcl'
    '90b19jbGllbnQuUmVzcG9uc2UuRG93bmxvYWRUb2tlbnNIAFIOZG93bmxvYWR0b2tlbnMSTQoM'
    'c2lnbmVkcHJla2V5GA4gASgLMicuc2VydmVyX3RvX2NsaWVudC5SZXNwb25zZS5TaWduZWRQcm'
    'VLZXlIAFIMc2lnbmVkcHJla2V5EkoKC3Byb29mT2ZXb3JrGA8gASgLMiYuc2VydmVyX3RvX2Ns'
    'aWVudC5SZXNwb25zZS5Qcm9vZk9mV29ya0gAUgtwcm9vZk9mV29ya0IECgJPayKWAQoQVHJhbn'
    'NhY3Rpb25UeXBlcxIKCgZSZWZ1bmQQABITCg9Wb3VjaGVyUmVkZWVtZWQQARISCg5Wb3VjaGVy'
    'Q3JlYXRlZBACEggKBENhc2gQAxIPCgtQbGFuVXBncmFkZRAEEgsKB1Vua25vd24QBRIUChBUaG'
    'Fua3NGb3JUZXN0aW5nEAYSDwoLQXV0b1JlbmV3YWwQB0IKCghSZXNwb25zZQ==');
