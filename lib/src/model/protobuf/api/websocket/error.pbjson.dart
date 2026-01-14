// This is a generated file - do not edit.
//
// Generated from api/websocket/error.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use errorCodeDescriptor instead')
const ErrorCode$json = {
  '1': 'ErrorCode',
  '2': [
    {'1': 'Unknown', '2': 0},
    {'1': 'BadRequest', '2': 400},
    {'1': 'TooManyRequests', '2': 429},
    {'1': 'InternalError', '2': 500},
    {'1': 'InvalidInvitationCode', '2': 1002},
    {'1': 'UsernameAlreadyTaken', '2': 1003},
    {'1': 'SignatureNotValid', '2': 1004},
    {'1': 'UsernameNotFound', '2': 1005},
    {'1': 'UsernameNotValid', '2': 1006},
    {'1': 'InvalidPublicKey', '2': 1007},
    {'1': 'SessionAlreadyAuthenticated', '2': 1008},
    {'1': 'SessionNotAuthenticated', '2': 1009},
    {'1': 'OnlyOneSessionAllowed', '2': 1010},
    {'1': 'UploadLimitReached', '2': 1011},
    {'1': 'InvalidUpdateToken', '2': 1012},
    {'1': 'InvalidOffset', '2': 1013},
    {'1': 'InvalidGoogleFcmToken', '2': 1014},
    {'1': 'UploadTokenIsBlocked', '2': 1015},
    {'1': 'UploadChecksumInvalid', '2': 1016},
    {'1': 'InvalidDownloadToken', '2': 1017},
    {'1': 'ApiEndpointNotFound', '2': 1018},
    {'1': 'AuthTokenNotValid', '2': 1019},
    {'1': 'InvalidPreKeys', '2': 1020},
    {'1': 'VoucherInValid', '2': 1021},
    {'1': 'PlanNotAllowed', '2': 1022},
    {'1': 'PlanLimitReached', '2': 1023},
    {'1': 'NotEnoughCredit', '2': 1024},
    {'1': 'PlanDowngrade', '2': 1025},
    {'1': 'PlanUpgradeNotYearly', '2': 1026},
    {'1': 'InvalidSignedPreKey', '2': 1027},
    {'1': 'UserIdNotFound', '2': 1028},
    {'1': 'UserIdAlreadyTaken', '2': 1029},
    {'1': 'AppVersionOutdated', '2': 1030},
    {'1': 'NewDeviceRegistered', '2': 1031},
    {'1': 'InvalidProofOfWork', '2': 1032},
    {'1': 'RegistrationDisabled', '2': 1033},
    {'1': 'IPAPaymentExpired', '2': 1034},
    {'1': 'UserIsNotInFreePlan', '2': 1035},
  ],
};

/// Descriptor for `ErrorCode`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List errorCodeDescriptor = $convert.base64Decode(
    'CglFcnJvckNvZGUSCwoHVW5rbm93bhAAEg8KCkJhZFJlcXVlc3QQkAMSFAoPVG9vTWFueVJlcX'
    'Vlc3RzEK0DEhIKDUludGVybmFsRXJyb3IQ9AMSGgoVSW52YWxpZEludml0YXRpb25Db2RlEOoH'
    'EhkKFFVzZXJuYW1lQWxyZWFkeVRha2VuEOsHEhYKEVNpZ25hdHVyZU5vdFZhbGlkEOwHEhUKEF'
    'VzZXJuYW1lTm90Rm91bmQQ7QcSFQoQVXNlcm5hbWVOb3RWYWxpZBDuBxIVChBJbnZhbGlkUHVi'
    'bGljS2V5EO8HEiAKG1Nlc3Npb25BbHJlYWR5QXV0aGVudGljYXRlZBDwBxIcChdTZXNzaW9uTm'
    '90QXV0aGVudGljYXRlZBDxBxIaChVPbmx5T25lU2Vzc2lvbkFsbG93ZWQQ8gcSFwoSVXBsb2Fk'
    'TGltaXRSZWFjaGVkEPMHEhcKEkludmFsaWRVcGRhdGVUb2tlbhD0BxISCg1JbnZhbGlkT2Zmc2'
    'V0EPUHEhoKFUludmFsaWRHb29nbGVGY21Ub2tlbhD2BxIZChRVcGxvYWRUb2tlbklzQmxvY2tl'
    'ZBD3BxIaChVVcGxvYWRDaGVja3N1bUludmFsaWQQ+AcSGQoUSW52YWxpZERvd25sb2FkVG9rZW'
    '4Q+QcSGAoTQXBpRW5kcG9pbnROb3RGb3VuZBD6BxIWChFBdXRoVG9rZW5Ob3RWYWxpZBD7BxIT'
    'Cg5JbnZhbGlkUHJlS2V5cxD8BxITCg5Wb3VjaGVySW5WYWxpZBD9BxITCg5QbGFuTm90QWxsb3'
    'dlZBD+BxIVChBQbGFuTGltaXRSZWFjaGVkEP8HEhQKD05vdEVub3VnaENyZWRpdBCACBISCg1Q'
    'bGFuRG93bmdyYWRlEIEIEhkKFFBsYW5VcGdyYWRlTm90WWVhcmx5EIIIEhgKE0ludmFsaWRTaW'
    'duZWRQcmVLZXkQgwgSEwoOVXNlcklkTm90Rm91bmQQhAgSFwoSVXNlcklkQWxyZWFkeVRha2Vu'
    'EIUIEhcKEkFwcFZlcnNpb25PdXRkYXRlZBCGCBIYChNOZXdEZXZpY2VSZWdpc3RlcmVkEIcIEh'
    'cKEkludmFsaWRQcm9vZk9mV29yaxCICBIZChRSZWdpc3RyYXRpb25EaXNhYmxlZBCJCBIWChFJ'
    'UEFQYXltZW50RXhwaXJlZBCKCBIYChNVc2VySXNOb3RJbkZyZWVQbGFuEIsI');
