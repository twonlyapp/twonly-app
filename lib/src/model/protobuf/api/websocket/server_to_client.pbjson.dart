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
      '1': 'RequestNewPqcPreKeys',
      '3': 8,
      '4': 1,
      '5': 8,
      '9': 0,
      '10': 'RequestNewPqcPreKeys'
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
    {
      '1': 'sealedSenderMessage',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.SealedSenderMessage',
      '9': 0,
      '10': 'sealedSenderMessage'
    },
    {
      '1': 'sealedSenderMessages',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.SealedSenderMessages',
      '9': 0,
      '10': 'sealedSenderMessages'
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
    'TmV3UHJlS2V5cxgEIAEoCEgAUhFSZXF1ZXN0TmV3UHJlS2V5cxI0ChRSZXF1ZXN0TmV3UHFjUH'
    'JlS2V5cxgIIAEoCEgAUhRSZXF1ZXN0TmV3UHFjUHJlS2V5cxIoCgVlcnJvchgGIAEoDjIQLmVy'
    'cm9yLkVycm9yQ29kZUgAUgVlcnJvchJZChNzZWFsZWRTZW5kZXJNZXNzYWdlGAkgASgLMiUuc2'
    'VydmVyX3RvX2NsaWVudC5TZWFsZWRTZW5kZXJNZXNzYWdlSABSE3NlYWxlZFNlbmRlck1lc3Nh'
    'Z2USXAoUc2VhbGVkU2VuZGVyTWVzc2FnZXMYCiABKAsyJi5zZXJ2ZXJfdG9fY2xpZW50LlNlYW'
    'xlZFNlbmRlck1lc3NhZ2VzSABSFHNlYWxlZFNlbmRlck1lc3NhZ2VzQgYKBEtpbmQ=');

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

@$core.Deprecated('Use sealedSenderMessageDescriptor instead')
const SealedSenderMessage$json = {
  '1': 'SealedSenderMessage',
  '2': [
    {'1': 'message_id', '3': 1, '4': 1, '5': 9, '10': 'messageId'},
    {'1': 'body', '3': 2, '4': 1, '5': 12, '10': 'body'},
  ],
};

/// Descriptor for `SealedSenderMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sealedSenderMessageDescriptor = $convert.base64Decode(
    'ChNTZWFsZWRTZW5kZXJNZXNzYWdlEh0KCm1lc3NhZ2VfaWQYASABKAlSCW1lc3NhZ2VJZBISCg'
    'Rib2R5GAIgASgMUgRib2R5');

@$core.Deprecated('Use sealedSenderMessagesDescriptor instead')
const SealedSenderMessages$json = {
  '1': 'SealedSenderMessages',
  '2': [
    {
      '1': 'messages',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.server_to_client.SealedSenderMessage',
      '10': 'messages'
    },
  ],
};

/// Descriptor for `SealedSenderMessages`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List sealedSenderMessagesDescriptor = $convert.base64Decode(
    'ChRTZWFsZWRTZW5kZXJNZXNzYWdlcxJBCghtZXNzYWdlcxgBIAMoCzIlLnNlcnZlcl90b19jbG'
    'llbnQuU2VhbGVkU2VuZGVyTWVzc2FnZVIIbWVzc2FnZXM=');

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
    Response_Transaction$json,
    Response_PlanBallance$json,
    Response_PreKey$json,
    Response_SignedPreKey$json,
    Response_PqcPreKey$json,
    Response_PqcBundle$json,
    Response_UserData$json,
    Response_UploadToken$json,
    Response_DownloadTokens$json,
    Response_ProofOfWork$json,
    Response_PasswordlessNotificationMessage$json,
    Response_PasswordlessNotificationMessages$json,
    Response_PresignedPost$json,
    Response_MemoriesUploadUrls$json,
    Response_MediaItem$json,
    Response_MemoriesList$json,
    Response_MemoriesUrl$json,
    Response_MemoriesUsage$json,
    Response_PrivacyPassParameters$json,
    Response_PrivacyPassTokenResponses$json,
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
    {
      '1': 'memories_size_limit',
      '3': 11,
      '4': 1,
      '5': 3,
      '10': 'memoriesSizeLimit'
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
const Response_PqcPreKey$json = {
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

@$core.Deprecated('Use responseDescriptor instead')
const Response_PqcBundle$json = {
  '1': 'PqcBundle',
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
      '1': 'prekey',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.Response.PqcPreKey',
      '9': 0,
      '10': 'prekey',
      '17': true
    },
  ],
  '8': [
    {'1': '_prekey'},
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
    {
      '1': 'pqc_bundle',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.Response.PqcBundle',
      '9': 6,
      '10': 'pqcBundle',
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
    {'1': '_pqc_bundle'},
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
const Response_PasswordlessNotificationMessage$json = {
  '1': 'PasswordlessNotificationMessage',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {
      '1': 'encrypted_message',
      '3': 2,
      '4': 1,
      '5': 12,
      '10': 'encryptedMessage'
    },
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_PasswordlessNotificationMessages$json = {
  '1': 'PasswordlessNotificationMessages',
  '2': [
    {
      '1': 'messages',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.server_to_client.Response.PasswordlessNotificationMessage',
      '10': 'messages'
    },
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_PresignedPost$json = {
  '1': 'PresignedPost',
  '2': [
    {'1': 'url', '3': 1, '4': 1, '5': 9, '10': 'url'},
    {
      '1': 'fields',
      '3': 2,
      '4': 3,
      '5': 11,
      '6': '.server_to_client.Response.PresignedPost.FieldsEntry',
      '10': 'fields'
    },
  ],
  '3': [Response_PresignedPost_FieldsEntry$json],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_PresignedPost_FieldsEntry$json = {
  '1': 'FieldsEntry',
  '2': [
    {'1': 'key', '3': 1, '4': 1, '5': 9, '10': 'key'},
    {'1': 'value', '3': 2, '4': 1, '5': 9, '10': 'value'},
  ],
  '7': {'7': true},
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_MemoriesUploadUrls$json = {
  '1': 'MemoriesUploadUrls',
  '2': [
    {'1': 'media_id', '3': 1, '4': 1, '5': 9, '10': 'mediaId'},
    {
      '1': 'thumbnail_upload',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.Response.PresignedPost',
      '10': 'thumbnailUpload'
    },
    {
      '1': 'full_upload',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.Response.PresignedPost',
      '10': 'fullUpload'
    },
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_MediaItem$json = {
  '1': 'MediaItem',
  '2': [
    {'1': 'media_id', '3': 1, '4': 1, '5': 9, '10': 'mediaId'},
    {'1': 'original_date', '3': 2, '4': 1, '5': 3, '10': 'originalDate'},
    {
      '1': 'thumbnail_download_url',
      '3': 3,
      '4': 1,
      '5': 9,
      '10': 'thumbnailDownloadUrl'
    },
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_MemoriesList$json = {
  '1': 'MemoriesList',
  '2': [
    {
      '1': 'items',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.server_to_client.Response.MediaItem',
      '10': 'items'
    },
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_MemoriesUrl$json = {
  '1': 'MemoriesUrl',
  '2': [
    {'1': 'full_download_url', '3': 1, '4': 1, '5': 9, '10': 'fullDownloadUrl'},
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_MemoriesUsage$json = {
  '1': 'MemoriesUsage',
  '2': [
    {'1': 'max_bytes', '3': 1, '4': 1, '5': 3, '10': 'maxBytes'},
    {'1': 'current_bytes', '3': 2, '4': 1, '5': 3, '10': 'currentBytes'},
    {'1': 'count', '3': 3, '4': 1, '5': 3, '10': 'count'},
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_PrivacyPassParameters$json = {
  '1': 'PrivacyPassParameters',
  '2': [
    {'1': 'token_challenge', '3': 1, '4': 1, '5': 12, '10': 'tokenChallenge'},
    {'1': 'public_key', '3': 2, '4': 1, '5': 12, '10': 'publicKey'},
    {'1': 'max_batch_size', '3': 3, '4': 1, '5': 13, '10': 'maxBatchSize'},
    {'1': 'max_age_seconds', '3': 4, '4': 1, '5': 13, '10': 'maxAgeSeconds'},
    {
      '1': 'daily_token_limit',
      '3': 5,
      '4': 1,
      '5': 13,
      '10': 'dailyTokenLimit'
    },
    {
      '1': 'issuance_cooldown_seconds',
      '3': 6,
      '4': 1,
      '5': 13,
      '10': 'issuanceCooldownSeconds'
    },
  ],
};

@$core.Deprecated('Use responseDescriptor instead')
const Response_PrivacyPassTokenResponses$json = {
  '1': 'PrivacyPassTokenResponses',
  '2': [
    {'1': 'token_responses', '3': 1, '4': 3, '5': 12, '10': 'tokenResponses'},
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
    {
      '1': 'passwordless_notification_messages',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.Response.PasswordlessNotificationMessages',
      '9': 0,
      '10': 'passwordlessNotificationMessages'
    },
    {
      '1': 'memories_upload_urls',
      '3': 18,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.Response.MemoriesUploadUrls',
      '9': 0,
      '10': 'memoriesUploadUrls'
    },
    {
      '1': 'memories_list',
      '3': 19,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.Response.MemoriesList',
      '9': 0,
      '10': 'memoriesList'
    },
    {
      '1': 'memories_url',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.Response.MemoriesUrl',
      '9': 0,
      '10': 'memoriesUrl'
    },
    {
      '1': 'memories_usage',
      '3': 21,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.Response.MemoriesUsage',
      '9': 0,
      '10': 'memoriesUsage'
    },
    {
      '1': 'privacy_pass_parameters',
      '3': 22,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.Response.PrivacyPassParameters',
      '9': 0,
      '10': 'privacyPassParameters'
    },
    {
      '1': 'privacy_pass_token_responses',
      '3': 23,
      '4': 1,
      '5': 11,
      '6': '.server_to_client.Response.PrivacyPassTokenResponses',
      '9': 0,
      '10': 'privacyPassTokenResponses'
    },
  ],
  '8': [
    {'1': 'Ok'},
  ],
  '9': [
    {'1': 7, '2': 8},
    {'1': 11, '2': 12},
  ],
};

/// Descriptor for `Response`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseDescriptor = $convert.base64Decode(
    'CghSZXNwb25zZRIvCgJvaxgBIAEoCzIdLnNlcnZlcl90b19jbGllbnQuUmVzcG9uc2UuT2tIAF'
    'ICb2sSKAoFZXJyb3IYAiABKA4yEC5lcnJvci5FcnJvckNvZGVIAFIFZXJyb3IaIwoNQXV0aGVu'
    'dGljYXRlZBISCgRwbGFuGAEgASgJUgRwbGFuGpQECgRQbGFuEhcKB3BsYW5faWQYASABKAlSBn'
    'BsYW5JZBIqChF1cGxvYWRfc2l6ZV9saW1pdBgCIAEoA1IPdXBsb2FkU2l6ZUxpbWl0EjcKGGRh'
    'aWx5X21lZGlhX3VwbG9hZF9saW1pdBgDIAEoA1IVZGFpbHlNZWRpYVVwbG9hZExpbWl0ElQKKG'
    '1heGltYWxfdXBsb2FkX3NpemVfb2Zfc2luZ2xlX21lZGlhX3NpemUYBCABKANSIm1heGltYWxV'
    'cGxvYWRTaXplT2ZTaW5nbGVNZWRpYVNpemUSOAoYYWRkaXRpb25hbF9wbHVzX2FjY291bnRzGA'
    'UgASgDUhZhZGRpdGlvbmFsUGx1c0FjY291bnRzEiwKEm1vbnRobHlfY29zdHNfY2VudBgHIAEo'
    'A1IQbW9udGhseUNvc3RzQ2VudBIqChF5ZWFybHlfY29zdHNfY2VudBgIIAEoA1IPeWVhcmx5Q2'
    '9zdHNDZW50EkAKHWFsbG93ZWRfdG9fc2VuZF90ZXh0X21lc3NhZ2VzGAkgASgIUhlhbGxvd2Vk'
    'VG9TZW5kVGV4dE1lc3NhZ2VzEjIKFWlzX2FkZGl0aW9uYWxfYWNjb3VudBgKIAEoCFITaXNBZG'
    'RpdGlvbmFsQWNjb3VudBIuChNtZW1vcmllc19zaXplX2xpbWl0GAsgASgDUhFtZW1vcmllc1Np'
    'emVMaW1pdBo+CgVQbGFucxI1CgVwbGFucxgBIAMoCzIfLnNlcnZlcl90b19jbGllbnQuUmVzcG'
    '9uc2UuUGxhblIFcGxhbnMaTQoRQWRkQWNjb3VudHNJbnZpdGUSFwoHcGxhbl9pZBgBIAEoCVIG'
    'cGxhbklkEh8KC2ludml0ZV9jb2RlGAIgASgJUgppbnZpdGVDb2RlGlwKEkFkZEFjY291bnRzSW'
    '52aXRlcxJGCgdpbnZpdGVzGAEgAygLMiwuc2VydmVyX3RvX2NsaWVudC5SZXNwb25zZS5BZGRB'
    'Y2NvdW50c0ludml0ZVIHaW52aXRlcxpFChFBZGRpdGlvbmFsQWNjb3VudBIXCgd1c2VyX2lkGA'
    'EgASgDUgZ1c2VySWQSFwoHcGxhbl9pZBgDIAEoCVIGcGxhbklkGg0KC1RyYW5zYWN0aW9uGpcF'
    'CgxQbGFuQmFsbGFuY2USQAoddXNlZF9kYWlseV9tZWRpYV91cGxvYWRfbGltaXQYASABKANSGX'
    'VzZWREYWlseU1lZGlhVXBsb2FkTGltaXQSPgocdXNlZF91cGxvYWRfbWVkaWFfc2l6ZV9saW1p'
    'dBgCIAEoA1IYdXNlZFVwbG9hZE1lZGlhU2l6ZUxpbWl0EjMKE3BheW1lbnRfcGVyaW9kX2RheX'
    'MYAyABKANIAFIRcGF5bWVudFBlcmlvZERheXOIAQESSwogbGFzdF9wYXltZW50X2RvbmVfdW5p'
    'eF90aW1lc3RhbXAYBCABKANIAVIcbGFzdFBheW1lbnREb25lVW5peFRpbWVzdGFtcIgBARJKCg'
    'x0cmFuc2FjdGlvbnMYBSADKAsyJi5zZXJ2ZXJfdG9fY2xpZW50LlJlc3BvbnNlLlRyYW5zYWN0'
    'aW9uUgx0cmFuc2FjdGlvbnMSXQoTYWRkaXRpb25hbF9hY2NvdW50cxgGIAMoCzIsLnNlcnZlcl'
    '90b19jbGllbnQuUmVzcG9uc2UuQWRkaXRpb25hbEFjY291bnRSEmFkZGl0aW9uYWxBY2NvdW50'
    'cxImCgxhdXRvX3JlbmV3YWwYByABKAhIAlILYXV0b1JlbmV3YWyIAQESQgobYWRkaXRpb25hbF'
    '9hY2NvdW50X293bmVyX2lkGAggASgDSANSGGFkZGl0aW9uYWxBY2NvdW50T3duZXJJZIgBAUIW'
    'ChRfcGF5bWVudF9wZXJpb2RfZGF5c0IjCiFfbGFzdF9wYXltZW50X2RvbmVfdW5peF90aW1lc3'
    'RhbXBCDwoNX2F1dG9fcmVuZXdhbEIeChxfYWRkaXRpb25hbF9hY2NvdW50X293bmVyX2lkGjAK'
    'BlByZUtleRIOCgJpZBgBIAEoA1ICaWQSFgoGcHJla2V5GAIgASgMUgZwcmVrZXkalQEKDFNpZ2'
    '5lZFByZUtleRIoChBzaWduZWRfcHJla2V5X2lkGAEgASgDUg5zaWduZWRQcmVrZXlJZBIjCg1z'
    'aWduZWRfcHJla2V5GAIgASgMUgxzaWduZWRQcmVrZXkSNgoXc2lnbmVkX3ByZWtleV9zaWduYX'
    'R1cmUYAyABKAxSFXNpZ25lZFByZWtleVNpZ25hdHVyZRrUAQoJUHFjUHJlS2V5EiMKDmVjY19w'
    'cmVfa2V5X2lkGAEgASgDUgtlY2NQcmVLZXlJZBIeCgtlY2NfcHJlX2tleRgCIAEoDFIJZWNjUH'
    'JlS2V5EicKEGt5YmVyX3ByZV9rZXlfaWQYAyABKANSDWt5YmVyUHJlS2V5SWQSIgoNa3liZXJf'
    'cHJlX2tleRgEIAEoDFILa3liZXJQcmVLZXkSNQoXa3liZXJfcHJlX2tleV9zaWduYXR1cmUYBS'
    'ABKAxSFGt5YmVyUHJlS2V5U2lnbmF0dXJlGp0DCglQcWNCdW5kbGUSLwoUZWNjX3NpZ25lZF9w'
    'cmVrZXlfaWQYASABKANSEWVjY1NpZ25lZFByZWtleUlkEioKEWVjY19zaWduZWRfcHJla2V5GA'
    'IgASgMUg9lY2NTaWduZWRQcmVrZXkSPQobZWNjX3NpZ25lZF9wcmVrZXlfc2lnbmF0dXJlGAMg'
    'ASgMUhhlY2NTaWduZWRQcmVrZXlTaWduYXR1cmUSMwoWa3liZXJfc2lnbmVkX3ByZWtleV9pZB'
    'gEIAEoA1ITa3liZXJTaWduZWRQcmVrZXlJZBIuChNreWJlcl9zaWduZWRfcHJla2V5GAUgASgM'
    'UhFreWJlclNpZ25lZFByZWtleRJBCh1reWJlcl9zaWduZWRfcHJla2V5X3NpZ25hdHVyZRgGIA'
    'EoDFIaa3liZXJTaWduZWRQcmVrZXlTaWduYXR1cmUSQQoGcHJla2V5GAcgASgLMiQuc2VydmVy'
    'X3RvX2NsaWVudC5SZXNwb25zZS5QcWNQcmVLZXlIAFIGcHJla2V5iAEBQgkKB19wcmVrZXkazw'
    'QKCFVzZXJEYXRhEhcKB3VzZXJfaWQYASABKANSBnVzZXJJZBI7CgdwcmVrZXlzGAIgAygLMiEu'
    'c2VydmVyX3RvX2NsaWVudC5SZXNwb25zZS5QcmVLZXlSB3ByZWtleXMSHwoIdXNlcm5hbWUYBy'
    'ABKAxIAFIIdXNlcm5hbWWIAQESMwoTcHVibGljX2lkZW50aXR5X2tleRgDIAEoDEgBUhFwdWJs'
    'aWNJZGVudGl0eUtleYgBARIoCg1zaWduZWRfcHJla2V5GAQgASgMSAJSDHNpZ25lZFByZWtleY'
    'gBARI7ChdzaWduZWRfcHJla2V5X3NpZ25hdHVyZRgFIAEoDEgDUhVzaWduZWRQcmVrZXlTaWdu'
    'YXR1cmWIAQESLQoQc2lnbmVkX3ByZWtleV9pZBgGIAEoA0gEUg5zaWduZWRQcmVrZXlJZIgBAR'
    'IsCg9yZWdpc3RyYXRpb25faWQYCCABKANIBVIOcmVnaXN0cmF0aW9uSWSIAQESSAoKcHFjX2J1'
    'bmRsZRgJIAEoCzIkLnNlcnZlcl90b19jbGllbnQuUmVzcG9uc2UuUHFjQnVuZGxlSAZSCXBxY0'
    'J1bmRsZYgBAUILCglfdXNlcm5hbWVCFgoUX3B1YmxpY19pZGVudGl0eV9rZXlCEAoOX3NpZ25l'
    'ZF9wcmVrZXlCGgoYX3NpZ25lZF9wcmVrZXlfc2lnbmF0dXJlQhMKEV9zaWduZWRfcHJla2V5X2'
    'lkQhIKEF9yZWdpc3RyYXRpb25faWRCDQoLX3BxY19idW5kbGUaWQoLVXBsb2FkVG9rZW4SIQoM'
    'dXBsb2FkX3Rva2VuGAEgASgMUgt1cGxvYWRUb2tlbhInCg9kb3dubG9hZF90b2tlbnMYAiADKA'
    'xSDmRvd25sb2FkVG9rZW5zGjkKDkRvd25sb2FkVG9rZW5zEicKD2Rvd25sb2FkX3Rva2VucxgB'
    'IAMoDFIOZG93bmxvYWRUb2tlbnMaRQoLUHJvb2ZPZldvcmsSFgoGcHJlZml4GAEgASgJUgZwcm'
    'VmaXgSHgoKZGlmZmljdWx0eRgCIAEoA1IKZGlmZmljdWx0eRpeCh9QYXNzd29yZGxlc3NOb3Rp'
    'ZmljYXRpb25NZXNzYWdlEg4KAmlkGAEgASgDUgJpZBIrChFlbmNyeXB0ZWRfbWVzc2FnZRgCIA'
    'EoDFIQZW5jcnlwdGVkTWVzc2FnZRp6CiBQYXNzd29yZGxlc3NOb3RpZmljYXRpb25NZXNzYWdl'
    'cxJWCghtZXNzYWdlcxgBIAMoCzI6LnNlcnZlcl90b19jbGllbnQuUmVzcG9uc2UuUGFzc3dvcm'
    'RsZXNzTm90aWZpY2F0aW9uTWVzc2FnZVIIbWVzc2FnZXMaqgEKDVByZXNpZ25lZFBvc3QSEAoD'
    'dXJsGAEgASgJUgN1cmwSTAoGZmllbGRzGAIgAygLMjQuc2VydmVyX3RvX2NsaWVudC5SZXNwb2'
    '5zZS5QcmVzaWduZWRQb3N0LkZpZWxkc0VudHJ5UgZmaWVsZHMaOQoLRmllbGRzRW50cnkSEAoD'
    'a2V5GAEgASgJUgNrZXkSFAoFdmFsdWUYAiABKAlSBXZhbHVlOgI4ARrPAQoSTWVtb3JpZXNVcG'
    'xvYWRVcmxzEhkKCG1lZGlhX2lkGAEgASgJUgdtZWRpYUlkElMKEHRodW1ibmFpbF91cGxvYWQY'
    'AiABKAsyKC5zZXJ2ZXJfdG9fY2xpZW50LlJlc3BvbnNlLlByZXNpZ25lZFBvc3RSD3RodW1ibm'
    'FpbFVwbG9hZBJJCgtmdWxsX3VwbG9hZBgDIAEoCzIoLnNlcnZlcl90b19jbGllbnQuUmVzcG9u'
    'c2UuUHJlc2lnbmVkUG9zdFIKZnVsbFVwbG9hZBqBAQoJTWVkaWFJdGVtEhkKCG1lZGlhX2lkGA'
    'EgASgJUgdtZWRpYUlkEiMKDW9yaWdpbmFsX2RhdGUYAiABKANSDG9yaWdpbmFsRGF0ZRI0ChZ0'
    'aHVtYm5haWxfZG93bmxvYWRfdXJsGAMgASgJUhR0aHVtYm5haWxEb3dubG9hZFVybBpKCgxNZW'
    '1vcmllc0xpc3QSOgoFaXRlbXMYASADKAsyJC5zZXJ2ZXJfdG9fY2xpZW50LlJlc3BvbnNlLk1l'
    'ZGlhSXRlbVIFaXRlbXMaOQoLTWVtb3JpZXNVcmwSKgoRZnVsbF9kb3dubG9hZF91cmwYASABKA'
    'lSD2Z1bGxEb3dubG9hZFVybBpnCg1NZW1vcmllc1VzYWdlEhsKCW1heF9ieXRlcxgBIAEoA1II'
    'bWF4Qnl0ZXMSIwoNY3VycmVudF9ieXRlcxgCIAEoA1IMY3VycmVudEJ5dGVzEhQKBWNvdW50GA'
    'MgASgDUgVjb3VudBqVAgoVUHJpdmFjeVBhc3NQYXJhbWV0ZXJzEicKD3Rva2VuX2NoYWxsZW5n'
    'ZRgBIAEoDFIOdG9rZW5DaGFsbGVuZ2USHQoKcHVibGljX2tleRgCIAEoDFIJcHVibGljS2V5Ei'
    'QKDm1heF9iYXRjaF9zaXplGAMgASgNUgxtYXhCYXRjaFNpemUSJgoPbWF4X2FnZV9zZWNvbmRz'
    'GAQgASgNUg1tYXhBZ2VTZWNvbmRzEioKEWRhaWx5X3Rva2VuX2xpbWl0GAUgASgNUg9kYWlseV'
    'Rva2VuTGltaXQSOgoZaXNzdWFuY2VfY29vbGRvd25fc2Vjb25kcxgGIAEoDVIXaXNzdWFuY2VD'
    'b29sZG93blNlY29uZHMaRAoZUHJpdmFjeVBhc3NUb2tlblJlc3BvbnNlcxInCg90b2tlbl9yZX'
    'Nwb25zZXMYASADKAxSDnRva2VuUmVzcG9uc2VzGtoMCgJPaxIUCgROb25lGAEgASgISABSBE5v'
    'bmUSGAoGdXNlcmlkGAIgASgDSABSBnVzZXJpZBImCg1hdXRoY2hhbGxlbmdlGAMgASgMSABSDW'
    'F1dGhjaGFsbGVuZ2USSgoLdXBsb2FkdG9rZW4YBCABKAsyJi5zZXJ2ZXJfdG9fY2xpZW50LlJl'
    'c3BvbnNlLlVwbG9hZFRva2VuSABSC3VwbG9hZHRva2VuEkEKCHVzZXJkYXRhGAUgASgLMiMuc2'
    'VydmVyX3RvX2NsaWVudC5SZXNwb25zZS5Vc2VyRGF0YUgAUgh1c2VyZGF0YRIeCglhdXRodG9r'
    'ZW4YBiABKAxIAFIJYXV0aHRva2VuElAKDWF1dGhlbnRpY2F0ZWQYCCABKAsyKC5zZXJ2ZXJfdG'
    '9fY2xpZW50LlJlc3BvbnNlLkF1dGhlbnRpY2F0ZWRIAFINYXV0aGVudGljYXRlZBI4CgVwbGFu'
    'cxgJIAEoCzIgLnNlcnZlcl90b19jbGllbnQuUmVzcG9uc2UuUGxhbnNIAFIFcGxhbnMSTQoMcG'
    'xhbmJhbGxhbmNlGAogASgLMicuc2VydmVyX3RvX2NsaWVudC5SZXNwb25zZS5QbGFuQmFsbGFu'
    'Y2VIAFIMcGxhbmJhbGxhbmNlEl8KEmFkZGFjY291bnRzaW52aXRlcxgMIAEoCzItLnNlcnZlcl'
    '90b19jbGllbnQuUmVzcG9uc2UuQWRkQWNjb3VudHNJbnZpdGVzSABSEmFkZGFjY291bnRzaW52'
    'aXRlcxJTCg5kb3dubG9hZHRva2VucxgNIAEoCzIpLnNlcnZlcl90b19jbGllbnQuUmVzcG9uc2'
    'UuRG93bmxvYWRUb2tlbnNIAFIOZG93bmxvYWR0b2tlbnMSTQoMc2lnbmVkcHJla2V5GA4gASgL'
    'Micuc2VydmVyX3RvX2NsaWVudC5SZXNwb25zZS5TaWduZWRQcmVLZXlIAFIMc2lnbmVkcHJla2'
    'V5EkoKC3Byb29mT2ZXb3JrGA8gASgLMiYuc2VydmVyX3RvX2NsaWVudC5SZXNwb25zZS5Qcm9v'
    'Zk9mV29ya0gAUgtwcm9vZk9mV29yaxJJCiBwYXNzd29yZGxlc3NfcmVjb3Zlcnlfc2VydmVyX2'
    'tleRgQIAEoDEgAUh1wYXNzd29yZGxlc3NSZWNvdmVyeVNlcnZlcktleRKLAQoicGFzc3dvcmRs'
    'ZXNzX25vdGlmaWNhdGlvbl9tZXNzYWdlcxgRIAEoCzI7LnNlcnZlcl90b19jbGllbnQuUmVzcG'
    '9uc2UuUGFzc3dvcmRsZXNzTm90aWZpY2F0aW9uTWVzc2FnZXNIAFIgcGFzc3dvcmRsZXNzTm90'
    'aWZpY2F0aW9uTWVzc2FnZXMSYQoUbWVtb3JpZXNfdXBsb2FkX3VybHMYEiABKAsyLS5zZXJ2ZX'
    'JfdG9fY2xpZW50LlJlc3BvbnNlLk1lbW9yaWVzVXBsb2FkVXJsc0gAUhJtZW1vcmllc1VwbG9h'
    'ZFVybHMSTgoNbWVtb3JpZXNfbGlzdBgTIAEoCzInLnNlcnZlcl90b19jbGllbnQuUmVzcG9uc2'
    'UuTWVtb3JpZXNMaXN0SABSDG1lbW9yaWVzTGlzdBJLCgxtZW1vcmllc191cmwYFCABKAsyJi5z'
    'ZXJ2ZXJfdG9fY2xpZW50LlJlc3BvbnNlLk1lbW9yaWVzVXJsSABSC21lbW9yaWVzVXJsElEKDm'
    '1lbW9yaWVzX3VzYWdlGBUgASgLMiguc2VydmVyX3RvX2NsaWVudC5SZXNwb25zZS5NZW1vcmll'
    'c1VzYWdlSABSDW1lbW9yaWVzVXNhZ2USagoXcHJpdmFjeV9wYXNzX3BhcmFtZXRlcnMYFiABKA'
    'syMC5zZXJ2ZXJfdG9fY2xpZW50LlJlc3BvbnNlLlByaXZhY3lQYXNzUGFyYW1ldGVyc0gAUhVw'
    'cml2YWN5UGFzc1BhcmFtZXRlcnMSdwoccHJpdmFjeV9wYXNzX3Rva2VuX3Jlc3BvbnNlcxgXIA'
    'EoCzI0LnNlcnZlcl90b19jbGllbnQuUmVzcG9uc2UuUHJpdmFjeVBhc3NUb2tlblJlc3BvbnNl'
    'c0gAUhlwcml2YWN5UGFzc1Rva2VuUmVzcG9uc2VzQgQKAk9rSgQIBxAISgQICxAMQgoKCFJlc3'
    'BvbnNl');
