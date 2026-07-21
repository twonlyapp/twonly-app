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
    Response_PasswordlessNotificationMessage$json,
    Response_PasswordlessNotificationMessages$json,
    Response_PresignedPost$json,
    Response_MemoriesUploadUrls$json,
    Response_MediaItem$json,
    Response_MemoriesList$json,
    Response_MemoriesUrl$json,
    Response_MemoriesUsage$json,
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
  ],
  '8': [
    {'1': 'Ok'},
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
    'EgASgDUgZ1c2VySWQSFwoHcGxhbl9pZBgDIAEoCVIGcGxhbklkGgwKCkRlcHJlY2F0ZWQaDQoL'
    'VHJhbnNhY3Rpb24alwUKDFBsYW5CYWxsYW5jZRJACh11c2VkX2RhaWx5X21lZGlhX3VwbG9hZF'
    '9saW1pdBgBIAEoA1IZdXNlZERhaWx5TWVkaWFVcGxvYWRMaW1pdBI+Chx1c2VkX3VwbG9hZF9t'
    'ZWRpYV9zaXplX2xpbWl0GAIgASgDUhh1c2VkVXBsb2FkTWVkaWFTaXplTGltaXQSMwoTcGF5bW'
    'VudF9wZXJpb2RfZGF5cxgDIAEoA0gAUhFwYXltZW50UGVyaW9kRGF5c4gBARJLCiBsYXN0X3Bh'
    'eW1lbnRfZG9uZV91bml4X3RpbWVzdGFtcBgEIAEoA0gBUhxsYXN0UGF5bWVudERvbmVVbml4VG'
    'ltZXN0YW1wiAEBEkoKDHRyYW5zYWN0aW9ucxgFIAMoCzImLnNlcnZlcl90b19jbGllbnQuUmVz'
    'cG9uc2UuVHJhbnNhY3Rpb25SDHRyYW5zYWN0aW9ucxJdChNhZGRpdGlvbmFsX2FjY291bnRzGA'
    'YgAygLMiwuc2VydmVyX3RvX2NsaWVudC5SZXNwb25zZS5BZGRpdGlvbmFsQWNjb3VudFISYWRk'
    'aXRpb25hbEFjY291bnRzEiYKDGF1dG9fcmVuZXdhbBgHIAEoCEgCUgthdXRvUmVuZXdhbIgBAR'
    'JCChthZGRpdGlvbmFsX2FjY291bnRfb3duZXJfaWQYCCABKANIA1IYYWRkaXRpb25hbEFjY291'
    'bnRPd25lcklkiAEBQhYKFF9wYXltZW50X3BlcmlvZF9kYXlzQiMKIV9sYXN0X3BheW1lbnRfZG'
    '9uZV91bml4X3RpbWVzdGFtcEIPCg1fYXV0b19yZW5ld2FsQh4KHF9hZGRpdGlvbmFsX2FjY291'
    'bnRfb3duZXJfaWQaMAoGUHJlS2V5Eg4KAmlkGAEgASgDUgJpZBIWCgZwcmVrZXkYAiABKAxSBn'
    'ByZWtleRqVAQoMU2lnbmVkUHJlS2V5EigKEHNpZ25lZF9wcmVrZXlfaWQYASABKANSDnNpZ25l'
    'ZFByZWtleUlkEiMKDXNpZ25lZF9wcmVrZXkYAiABKAxSDHNpZ25lZFByZWtleRI2ChdzaWduZW'
    'RfcHJla2V5X3NpZ25hdHVyZRgDIAEoDFIVc2lnbmVkUHJla2V5U2lnbmF0dXJlGvYDCghVc2Vy'
    'RGF0YRIXCgd1c2VyX2lkGAEgASgDUgZ1c2VySWQSOwoHcHJla2V5cxgCIAMoCzIhLnNlcnZlcl'
    '90b19jbGllbnQuUmVzcG9uc2UuUHJlS2V5UgdwcmVrZXlzEh8KCHVzZXJuYW1lGAcgASgMSABS'
    'CHVzZXJuYW1liAEBEjMKE3B1YmxpY19pZGVudGl0eV9rZXkYAyABKAxIAVIRcHVibGljSWRlbn'
    'RpdHlLZXmIAQESKAoNc2lnbmVkX3ByZWtleRgEIAEoDEgCUgxzaWduZWRQcmVrZXmIAQESOwoX'
    'c2lnbmVkX3ByZWtleV9zaWduYXR1cmUYBSABKAxIA1IVc2lnbmVkUHJla2V5U2lnbmF0dXJliA'
    'EBEi0KEHNpZ25lZF9wcmVrZXlfaWQYBiABKANIBFIOc2lnbmVkUHJla2V5SWSIAQESLAoPcmVn'
    'aXN0cmF0aW9uX2lkGAggASgDSAVSDnJlZ2lzdHJhdGlvbklkiAEBQgsKCV91c2VybmFtZUIWCh'
    'RfcHVibGljX2lkZW50aXR5X2tleUIQCg5fc2lnbmVkX3ByZWtleUIaChhfc2lnbmVkX3ByZWtl'
    'eV9zaWduYXR1cmVCEwoRX3NpZ25lZF9wcmVrZXlfaWRCEgoQX3JlZ2lzdHJhdGlvbl9pZBpZCg'
    'tVcGxvYWRUb2tlbhIhCgx1cGxvYWRfdG9rZW4YASABKAxSC3VwbG9hZFRva2VuEicKD2Rvd25s'
    'b2FkX3Rva2VucxgCIAMoDFIOZG93bmxvYWRUb2tlbnMaOQoORG93bmxvYWRUb2tlbnMSJwoPZG'
    '93bmxvYWRfdG9rZW5zGAEgAygMUg5kb3dubG9hZFRva2VucxpFCgtQcm9vZk9mV29yaxIWCgZw'
    'cmVmaXgYASABKAlSBnByZWZpeBIeCgpkaWZmaWN1bHR5GAIgASgDUgpkaWZmaWN1bHR5Gl4KH1'
    'Bhc3N3b3JkbGVzc05vdGlmaWNhdGlvbk1lc3NhZ2USDgoCaWQYASABKANSAmlkEisKEWVuY3J5'
    'cHRlZF9tZXNzYWdlGAIgASgMUhBlbmNyeXB0ZWRNZXNzYWdlGnoKIFBhc3N3b3JkbGVzc05vdG'
    'lmaWNhdGlvbk1lc3NhZ2VzElYKCG1lc3NhZ2VzGAEgAygLMjouc2VydmVyX3RvX2NsaWVudC5S'
    'ZXNwb25zZS5QYXNzd29yZGxlc3NOb3RpZmljYXRpb25NZXNzYWdlUghtZXNzYWdlcxqqAQoNUH'
    'Jlc2lnbmVkUG9zdBIQCgN1cmwYASABKAlSA3VybBJMCgZmaWVsZHMYAiADKAsyNC5zZXJ2ZXJf'
    'dG9fY2xpZW50LlJlc3BvbnNlLlByZXNpZ25lZFBvc3QuRmllbGRzRW50cnlSBmZpZWxkcxo5Cg'
    'tGaWVsZHNFbnRyeRIQCgNrZXkYASABKAlSA2tleRIUCgV2YWx1ZRgCIAEoCVIFdmFsdWU6AjgB'
    'Gs8BChJNZW1vcmllc1VwbG9hZFVybHMSGQoIbWVkaWFfaWQYASABKAlSB21lZGlhSWQSUwoQdG'
    'h1bWJuYWlsX3VwbG9hZBgCIAEoCzIoLnNlcnZlcl90b19jbGllbnQuUmVzcG9uc2UuUHJlc2ln'
    'bmVkUG9zdFIPdGh1bWJuYWlsVXBsb2FkEkkKC2Z1bGxfdXBsb2FkGAMgASgLMiguc2VydmVyX3'
    'RvX2NsaWVudC5SZXNwb25zZS5QcmVzaWduZWRQb3N0UgpmdWxsVXBsb2FkGoEBCglNZWRpYUl0'
    'ZW0SGQoIbWVkaWFfaWQYASABKAlSB21lZGlhSWQSIwoNb3JpZ2luYWxfZGF0ZRgCIAEoA1IMb3'
    'JpZ2luYWxEYXRlEjQKFnRodW1ibmFpbF9kb3dubG9hZF91cmwYAyABKAlSFHRodW1ibmFpbERv'
    'd25sb2FkVXJsGkoKDE1lbW9yaWVzTGlzdBI6CgVpdGVtcxgBIAMoCzIkLnNlcnZlcl90b19jbG'
    'llbnQuUmVzcG9uc2UuTWVkaWFJdGVtUgVpdGVtcxo5CgtNZW1vcmllc1VybBIqChFmdWxsX2Rv'
    'd25sb2FkX3VybBgBIAEoCVIPZnVsbERvd25sb2FkVXJsGmcKDU1lbW9yaWVzVXNhZ2USGwoJbW'
    'F4X2J5dGVzGAEgASgDUghtYXhCeXRlcxIjCg1jdXJyZW50X2J5dGVzGAIgASgDUgxjdXJyZW50'
    'Qnl0ZXMSFAoFY291bnQYAyABKANSBWNvdW50GoMMCgJPaxIUCgROb25lGAEgASgISABSBE5vbm'
    'USGAoGdXNlcmlkGAIgASgDSABSBnVzZXJpZBImCg1hdXRoY2hhbGxlbmdlGAMgASgMSABSDWF1'
    'dGhjaGFsbGVuZ2USSgoLdXBsb2FkdG9rZW4YBCABKAsyJi5zZXJ2ZXJfdG9fY2xpZW50LlJlc3'
    'BvbnNlLlVwbG9hZFRva2VuSABSC3VwbG9hZHRva2VuEkEKCHVzZXJkYXRhGAUgASgLMiMuc2Vy'
    'dmVyX3RvX2NsaWVudC5SZXNwb25zZS5Vc2VyRGF0YUgAUgh1c2VyZGF0YRIeCglhdXRodG9rZW'
    '4YBiABKAxIAFIJYXV0aHRva2VuEkoKDGRlcHJlY2F0ZWRfNxgHIAEoCzIlLnNlcnZlcl90b19j'
    'bGllbnQuUmVzcG9uc2UuRGVwcmVjYXRlZEgAUgtkZXByZWNhdGVkNxJQCg1hdXRoZW50aWNhdG'
    'VkGAggASgLMiguc2VydmVyX3RvX2NsaWVudC5SZXNwb25zZS5BdXRoZW50aWNhdGVkSABSDWF1'
    'dGhlbnRpY2F0ZWQSOAoFcGxhbnMYCSABKAsyIC5zZXJ2ZXJfdG9fY2xpZW50LlJlc3BvbnNlLl'
    'BsYW5zSABSBXBsYW5zEk0KDHBsYW5iYWxsYW5jZRgKIAEoCzInLnNlcnZlcl90b19jbGllbnQu'
    'UmVzcG9uc2UuUGxhbkJhbGxhbmNlSABSDHBsYW5iYWxsYW5jZRJMCg1kZXByZWNhdGVkXzExGA'
    'sgASgLMiUuc2VydmVyX3RvX2NsaWVudC5SZXNwb25zZS5EZXByZWNhdGVkSABSDGRlcHJlY2F0'
    'ZWQxMRJfChJhZGRhY2NvdW50c2ludml0ZXMYDCABKAsyLS5zZXJ2ZXJfdG9fY2xpZW50LlJlc3'
    'BvbnNlLkFkZEFjY291bnRzSW52aXRlc0gAUhJhZGRhY2NvdW50c2ludml0ZXMSUwoOZG93bmxv'
    'YWR0b2tlbnMYDSABKAsyKS5zZXJ2ZXJfdG9fY2xpZW50LlJlc3BvbnNlLkRvd25sb2FkVG9rZW'
    '5zSABSDmRvd25sb2FkdG9rZW5zEk0KDHNpZ25lZHByZWtleRgOIAEoCzInLnNlcnZlcl90b19j'
    'bGllbnQuUmVzcG9uc2UuU2lnbmVkUHJlS2V5SABSDHNpZ25lZHByZWtleRJKCgtwcm9vZk9mV2'
    '9yaxgPIAEoCzImLnNlcnZlcl90b19jbGllbnQuUmVzcG9uc2UuUHJvb2ZPZldvcmtIAFILcHJv'
    'b2ZPZldvcmsSSQogcGFzc3dvcmRsZXNzX3JlY292ZXJ5X3NlcnZlcl9rZXkYECABKAxIAFIdcG'
    'Fzc3dvcmRsZXNzUmVjb3ZlcnlTZXJ2ZXJLZXkSiwEKInBhc3N3b3JkbGVzc19ub3RpZmljYXRp'
    'b25fbWVzc2FnZXMYESABKAsyOy5zZXJ2ZXJfdG9fY2xpZW50LlJlc3BvbnNlLlBhc3N3b3JkbG'
    'Vzc05vdGlmaWNhdGlvbk1lc3NhZ2VzSABSIHBhc3N3b3JkbGVzc05vdGlmaWNhdGlvbk1lc3Nh'
    'Z2VzEmEKFG1lbW9yaWVzX3VwbG9hZF91cmxzGBIgASgLMi0uc2VydmVyX3RvX2NsaWVudC5SZX'
    'Nwb25zZS5NZW1vcmllc1VwbG9hZFVybHNIAFISbWVtb3JpZXNVcGxvYWRVcmxzEk4KDW1lbW9y'
    'aWVzX2xpc3QYEyABKAsyJy5zZXJ2ZXJfdG9fY2xpZW50LlJlc3BvbnNlLk1lbW9yaWVzTGlzdE'
    'gAUgxtZW1vcmllc0xpc3QSSwoMbWVtb3JpZXNfdXJsGBQgASgLMiYuc2VydmVyX3RvX2NsaWVu'
    'dC5SZXNwb25zZS5NZW1vcmllc1VybEgAUgttZW1vcmllc1VybBJRCg5tZW1vcmllc191c2FnZR'
    'gVIAEoCzIoLnNlcnZlcl90b19jbGllbnQuUmVzcG9uc2UuTWVtb3JpZXNVc2FnZUgAUg1tZW1v'
    'cmllc1VzYWdlQgQKAk9rQgoKCFJlc3BvbnNl');
