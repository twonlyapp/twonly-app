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
  '3': [Response_Authenticated$json, Response_Plan$json, Response_Plans$json, Response_AddAccountsInvite$json, Response_AddAccountsInvites$json, Response_Transaction$json, Response_AdditionalAccount$json, Response_Voucher$json, Response_Vouchers$json, Response_PlanBallance$json, Response_Location$json, Response_PreKey$json, Response_SignedPreKey$json, Response_UserData$json, Response_UploadToken$json, Response_DownloadTokens$json, Response_Ok$json],
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
    {'1': 'daily_media_upload_limit', '3': 3, '4': 1, '5': 3, '10': 'dailyMediaUploadLimit'},
    {'1': 'maximal_upload_size_of_single_media_size', '3': 4, '4': 1, '5': 3, '10': 'maximalUploadSizeOfSingleMediaSize'},
    {'1': 'additional_plus_accounts', '3': 5, '4': 1, '5': 3, '10': 'additionalPlusAccounts'},
    {'1': 'additional_free_accounts', '3': 6, '4': 1, '5': 3, '10': 'additionalFreeAccounts'},
    {'1': 'monthly_costs_cent', '3': 7, '4': 1, '5': 3, '10': 'monthlyCostsCent'},
    {'1': 'yearly_costs_cent', '3': 8, '4': 1, '5': 3, '10': 'yearlyCostsCent'},
    {'1': 'allowed_to_send_text_messages', '3': 9, '4': 1, '5': 8, '10': 'allowedToSendTextMessages'},
    {'1': 'is_additional_account', '3': 10, '4': 1, '5': 8, '10': 'isAdditionalAccount'},
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_Plans$json = {
  '1': 'Plans',
  '2': [
    {'1': 'plans', '3': 1, '4': 3, '5': 11, '6': '.server_to_client.Response.Plan', '10': 'plans'},
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
    {'1': 'invites', '3': 1, '4': 3, '5': 11, '6': '.server_to_client.Response.AddAccountsInvite', '10': 'invites'},
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_Transaction$json = {
  '1': 'Transaction',
  '2': [
    {'1': 'deposit_cents', '3': 1, '4': 1, '5': 3, '10': 'depositCents'},
    {'1': 'transaction_type', '3': 2, '4': 1, '5': 14, '6': '.server_to_client.Response.TransactionTypes', '10': 'transactionType'},
    {'1': 'created_at_unix_timestamp', '3': 3, '4': 1, '5': 3, '10': 'createdAtUnixTimestamp'},
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
    {'1': 'created_at_unix_timestamp', '3': 5, '4': 1, '5': 3, '10': 'createdAtUnixTimestamp'},
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_Vouchers$json = {
  '1': 'Vouchers',
  '2': [
    {'1': 'vouchers', '3': 1, '4': 3, '5': 11, '6': '.server_to_client.Response.Voucher', '10': 'vouchers'},
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_PlanBallance$json = {
  '1': 'PlanBallance',
  '2': [
    {'1': 'used_daily_media_upload_limit', '3': 1, '4': 1, '5': 3, '10': 'usedDailyMediaUploadLimit'},
    {'1': 'used_upload_media_size_limit', '3': 2, '4': 1, '5': 3, '10': 'usedUploadMediaSizeLimit'},
    {'1': 'payment_period_days', '3': 3, '4': 1, '5': 3, '9': 0, '10': 'paymentPeriodDays', '17': true},
    {'1': 'last_payment_done_unix_timestamp', '3': 4, '4': 1, '5': 3, '9': 1, '10': 'lastPaymentDoneUnixTimestamp', '17': true},
    {'1': 'transactions', '3': 5, '4': 3, '5': 11, '6': '.server_to_client.Response.Transaction', '10': 'transactions'},
    {'1': 'additional_accounts', '3': 6, '4': 3, '5': 11, '6': '.server_to_client.Response.AdditionalAccount', '10': 'additionalAccounts'},
    {'1': 'auto_renewal', '3': 7, '4': 1, '5': 8, '9': 2, '10': 'autoRenewal', '17': true},
    {'1': 'additional_account_owner_id', '3': 8, '4': 1, '5': 3, '9': 3, '10': 'additionalAccountOwnerId', '17': true},
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
    {'1': 'signed_prekey_signature', '3': 3, '4': 1, '5': 12, '10': 'signedPrekeySignature'},
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
const Response_DownloadTokens$json = {
  '1': 'DownloadTokens',
  '2': [
    {'1': 'download_tokens', '3': 1, '4': 3, '5': 12, '10': 'downloadTokens'},
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
    {'1': 'authenticated', '3': 8, '4': 1, '5': 11, '6': '.server_to_client.Response.Authenticated', '9': 0, '10': 'authenticated'},
    {'1': 'plans', '3': 9, '4': 1, '5': 11, '6': '.server_to_client.Response.Plans', '9': 0, '10': 'plans'},
    {'1': 'planballance', '3': 10, '4': 1, '5': 11, '6': '.server_to_client.Response.PlanBallance', '9': 0, '10': 'planballance'},
    {'1': 'vouchers', '3': 11, '4': 1, '5': 11, '6': '.server_to_client.Response.Vouchers', '9': 0, '10': 'vouchers'},
    {'1': 'addaccountsinvites', '3': 12, '4': 1, '5': 11, '6': '.server_to_client.Response.AddAccountsInvites', '9': 0, '10': 'addaccountsinvites'},
    {'1': 'downloadtokens', '3': 13, '4': 1, '5': 11, '6': '.server_to_client.Response.DownloadTokens', '9': 0, '10': 'downloadtokens'},
    {'1': 'signedprekey', '3': 14, '4': 1, '5': 11, '6': '.server_to_client.Response.SignedPreKey', '9': 0, '10': 'signedprekey'},
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
    'dGljYXRlZBISCgRwbGFuGAEgASgJUgRwbGFuGp4ECgRQbGFuEhcKB3BsYW5faWQYASABKAlSBn'
    'BsYW5JZBIqChF1cGxvYWRfc2l6ZV9saW1pdBgCIAEoA1IPdXBsb2FkU2l6ZUxpbWl0EjcKGGRh'
    'aWx5X21lZGlhX3VwbG9hZF9saW1pdBgDIAEoA1IVZGFpbHlNZWRpYVVwbG9hZExpbWl0ElQKKG'
    '1heGltYWxfdXBsb2FkX3NpemVfb2Zfc2luZ2xlX21lZGlhX3NpemUYBCABKANSIm1heGltYWxV'
    'cGxvYWRTaXplT2ZTaW5nbGVNZWRpYVNpemUSOAoYYWRkaXRpb25hbF9wbHVzX2FjY291bnRzGA'
    'UgASgDUhZhZGRpdGlvbmFsUGx1c0FjY291bnRzEjgKGGFkZGl0aW9uYWxfZnJlZV9hY2NvdW50'
    'cxgGIAEoA1IWYWRkaXRpb25hbEZyZWVBY2NvdW50cxIsChJtb250aGx5X2Nvc3RzX2NlbnQYBy'
    'ABKANSEG1vbnRobHlDb3N0c0NlbnQSKgoReWVhcmx5X2Nvc3RzX2NlbnQYCCABKANSD3llYXJs'
    'eUNvc3RzQ2VudBJACh1hbGxvd2VkX3RvX3NlbmRfdGV4dF9tZXNzYWdlcxgJIAEoCFIZYWxsb3'
    'dlZFRvU2VuZFRleHRNZXNzYWdlcxIyChVpc19hZGRpdGlvbmFsX2FjY291bnQYCiABKAhSE2lz'
    'QWRkaXRpb25hbEFjY291bnQaPgoFUGxhbnMSNQoFcGxhbnMYASADKAsyHy5zZXJ2ZXJfdG9fY2'
    'xpZW50LlJlc3BvbnNlLlBsYW5SBXBsYW5zGk0KEUFkZEFjY291bnRzSW52aXRlEhcKB3BsYW5f'
    'aWQYASABKAlSBnBsYW5JZBIfCgtpbnZpdGVfY29kZRgCIAEoCVIKaW52aXRlQ29kZRpcChJBZG'
    'RBY2NvdW50c0ludml0ZXMSRgoHaW52aXRlcxgBIAMoCzIsLnNlcnZlcl90b19jbGllbnQuUmVz'
    'cG9uc2UuQWRkQWNjb3VudHNJbnZpdGVSB2ludml0ZXMaxQEKC1RyYW5zYWN0aW9uEiMKDWRlcG'
    '9zaXRfY2VudHMYASABKANSDGRlcG9zaXRDZW50cxJWChB0cmFuc2FjdGlvbl90eXBlGAIgASgO'
    'Misuc2VydmVyX3RvX2NsaWVudC5SZXNwb25zZS5UcmFuc2FjdGlvblR5cGVzUg90cmFuc2FjdG'
    'lvblR5cGUSOQoZY3JlYXRlZF9hdF91bml4X3RpbWVzdGFtcBgDIAEoA1IWY3JlYXRlZEF0VW5p'
    'eFRpbWVzdGFtcBpFChFBZGRpdGlvbmFsQWNjb3VudBIXCgd1c2VyX2lkGAEgASgDUgZ1c2VySW'
    'QSFwoHcGxhbl9pZBgDIAEoCVIGcGxhbklkGr4BCgdWb3VjaGVyEh0KCnZvdWNoZXJfaWQYASAB'
    'KAlSCXZvdWNoZXJJZBIfCgt2YWx1ZV9jZW50cxgCIAEoA1IKdmFsdWVDZW50cxIaCghyZWRlZW'
    '1lZBgDIAEoCFIIcmVkZWVtZWQSHAoJcmVxdWVzdGVkGAQgASgIUglyZXF1ZXN0ZWQSOQoZY3Jl'
    'YXRlZF9hdF91bml4X3RpbWVzdGFtcBgFIAEoA1IWY3JlYXRlZEF0VW5peFRpbWVzdGFtcBpKCg'
    'hWb3VjaGVycxI+Cgh2b3VjaGVycxgBIAMoCzIiLnNlcnZlcl90b19jbGllbnQuUmVzcG9uc2Uu'
    'Vm91Y2hlclIIdm91Y2hlcnMalwUKDFBsYW5CYWxsYW5jZRJACh11c2VkX2RhaWx5X21lZGlhX3'
    'VwbG9hZF9saW1pdBgBIAEoA1IZdXNlZERhaWx5TWVkaWFVcGxvYWRMaW1pdBI+Chx1c2VkX3Vw'
    'bG9hZF9tZWRpYV9zaXplX2xpbWl0GAIgASgDUhh1c2VkVXBsb2FkTWVkaWFTaXplTGltaXQSMw'
    'oTcGF5bWVudF9wZXJpb2RfZGF5cxgDIAEoA0gAUhFwYXltZW50UGVyaW9kRGF5c4gBARJLCiBs'
    'YXN0X3BheW1lbnRfZG9uZV91bml4X3RpbWVzdGFtcBgEIAEoA0gBUhxsYXN0UGF5bWVudERvbm'
    'VVbml4VGltZXN0YW1wiAEBEkoKDHRyYW5zYWN0aW9ucxgFIAMoCzImLnNlcnZlcl90b19jbGll'
    'bnQuUmVzcG9uc2UuVHJhbnNhY3Rpb25SDHRyYW5zYWN0aW9ucxJdChNhZGRpdGlvbmFsX2FjY2'
    '91bnRzGAYgAygLMiwuc2VydmVyX3RvX2NsaWVudC5SZXNwb25zZS5BZGRpdGlvbmFsQWNjb3Vu'
    'dFISYWRkaXRpb25hbEFjY291bnRzEiYKDGF1dG9fcmVuZXdhbBgHIAEoCEgCUgthdXRvUmVuZX'
    'dhbIgBARJCChthZGRpdGlvbmFsX2FjY291bnRfb3duZXJfaWQYCCABKANIA1IYYWRkaXRpb25h'
    'bEFjY291bnRPd25lcklkiAEBQhYKFF9wYXltZW50X3BlcmlvZF9kYXlzQiMKIV9sYXN0X3BheW'
    '1lbnRfZG9uZV91bml4X3RpbWVzdGFtcEIPCg1fYXV0b19yZW5ld2FsQh4KHF9hZGRpdGlvbmFs'
    'X2FjY291bnRfb3duZXJfaWQaTgoITG9jYXRpb24SFgoGY291bnR5GAEgASgJUgZjb3VudHkSFg'
    'oGcmVnaW9uGAIgASgJUgZyZWdpb24SEgoEY2l0eRgDIAEoCVIEY2l0eRowCgZQcmVLZXkSDgoC'
    'aWQYASABKANSAmlkEhYKBnByZWtleRgCIAEoDFIGcHJla2V5GpUBCgxTaWduZWRQcmVLZXkSKA'
    'oQc2lnbmVkX3ByZWtleV9pZBgBIAEoA1IOc2lnbmVkUHJla2V5SWQSIwoNc2lnbmVkX3ByZWtl'
    'eRgCIAEoDFIMc2lnbmVkUHJla2V5EjYKF3NpZ25lZF9wcmVrZXlfc2lnbmF0dXJlGAMgASgMUh'
    'VzaWduZWRQcmVrZXlTaWduYXR1cmUatAMKCFVzZXJEYXRhEhcKB3VzZXJfaWQYASABKANSBnVz'
    'ZXJJZBI7CgdwcmVrZXlzGAIgAygLMiEuc2VydmVyX3RvX2NsaWVudC5SZXNwb25zZS5QcmVLZX'
    'lSB3ByZWtleXMSHwoIdXNlcm5hbWUYByABKAxIAFIIdXNlcm5hbWWIAQESMwoTcHVibGljX2lk'
    'ZW50aXR5X2tleRgDIAEoDEgBUhFwdWJsaWNJZGVudGl0eUtleYgBARIoCg1zaWduZWRfcHJla2'
    'V5GAQgASgMSAJSDHNpZ25lZFByZWtleYgBARI7ChdzaWduZWRfcHJla2V5X3NpZ25hdHVyZRgF'
    'IAEoDEgDUhVzaWduZWRQcmVrZXlTaWduYXR1cmWIAQESLQoQc2lnbmVkX3ByZWtleV9pZBgGIA'
    'EoA0gEUg5zaWduZWRQcmVrZXlJZIgBAUILCglfdXNlcm5hbWVCFgoUX3B1YmxpY19pZGVudGl0'
    'eV9rZXlCEAoOX3NpZ25lZF9wcmVrZXlCGgoYX3NpZ25lZF9wcmVrZXlfc2lnbmF0dXJlQhMKEV'
    '9zaWduZWRfcHJla2V5X2lkGlkKC1VwbG9hZFRva2VuEiEKDHVwbG9hZF90b2tlbhgBIAEoDFIL'
    'dXBsb2FkVG9rZW4SJwoPZG93bmxvYWRfdG9rZW5zGAIgAygMUg5kb3dubG9hZFRva2Vucxo5Cg'
    '5Eb3dubG9hZFRva2VucxInCg9kb3dubG9hZF90b2tlbnMYASADKAxSDmRvd25sb2FkVG9rZW5z'
    'GvcGCgJPaxIUCgROb25lGAEgASgISABSBE5vbmUSGAoGdXNlcmlkGAIgASgDSABSBnVzZXJpZB'
    'ImCg1hdXRoY2hhbGxlbmdlGAMgASgMSABSDWF1dGhjaGFsbGVuZ2USSgoLdXBsb2FkdG9rZW4Y'
    'BCABKAsyJi5zZXJ2ZXJfdG9fY2xpZW50LlJlc3BvbnNlLlVwbG9hZFRva2VuSABSC3VwbG9hZH'
    'Rva2VuEkEKCHVzZXJkYXRhGAUgASgLMiMuc2VydmVyX3RvX2NsaWVudC5SZXNwb25zZS5Vc2Vy'
    'RGF0YUgAUgh1c2VyZGF0YRIeCglhdXRodG9rZW4YBiABKAxIAFIJYXV0aHRva2VuEkEKCGxvY2'
    'F0aW9uGAcgASgLMiMuc2VydmVyX3RvX2NsaWVudC5SZXNwb25zZS5Mb2NhdGlvbkgAUghsb2Nh'
    'dGlvbhJQCg1hdXRoZW50aWNhdGVkGAggASgLMiguc2VydmVyX3RvX2NsaWVudC5SZXNwb25zZS'
    '5BdXRoZW50aWNhdGVkSABSDWF1dGhlbnRpY2F0ZWQSOAoFcGxhbnMYCSABKAsyIC5zZXJ2ZXJf'
    'dG9fY2xpZW50LlJlc3BvbnNlLlBsYW5zSABSBXBsYW5zEk0KDHBsYW5iYWxsYW5jZRgKIAEoCz'
    'InLnNlcnZlcl90b19jbGllbnQuUmVzcG9uc2UuUGxhbkJhbGxhbmNlSABSDHBsYW5iYWxsYW5j'
    'ZRJBCgh2b3VjaGVycxgLIAEoCzIjLnNlcnZlcl90b19jbGllbnQuUmVzcG9uc2UuVm91Y2hlcn'
    'NIAFIIdm91Y2hlcnMSXwoSYWRkYWNjb3VudHNpbnZpdGVzGAwgASgLMi0uc2VydmVyX3RvX2Ns'
    'aWVudC5SZXNwb25zZS5BZGRBY2NvdW50c0ludml0ZXNIAFISYWRkYWNjb3VudHNpbnZpdGVzEl'
    'MKDmRvd25sb2FkdG9rZW5zGA0gASgLMikuc2VydmVyX3RvX2NsaWVudC5SZXNwb25zZS5Eb3du'
    'bG9hZFRva2Vuc0gAUg5kb3dubG9hZHRva2VucxJNCgxzaWduZWRwcmVrZXkYDiABKAsyJy5zZX'
    'J2ZXJfdG9fY2xpZW50LlJlc3BvbnNlLlNpZ25lZFByZUtleUgAUgxzaWduZWRwcmVrZXlCBAoC'
    'T2silgEKEFRyYW5zYWN0aW9uVHlwZXMSCgoGUmVmdW5kEAASEwoPVm91Y2hlclJlZGVlbWVkEA'
    'ESEgoOVm91Y2hlckNyZWF0ZWQQAhIICgRDYXNoEAMSDwoLUGxhblVwZ3JhZGUQBBILCgdVbmtu'
    'b3duEAUSFAoQVGhhbmtzRm9yVGVzdGluZxAGEg8KC0F1dG9SZW5ld2FsEAdCCgoIUmVzcG9uc2'
    'U=');

