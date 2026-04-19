// This is a generated file - do not edit.
//
// Generated from types.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use userDiscoveryVersionDescriptor instead')
const UserDiscoveryVersion$json = {
  '1': 'UserDiscoveryVersion',
  '2': [
    {'1': 'announcement', '3': 1, '4': 1, '5': 13, '10': 'announcement'},
    {'1': 'promotion', '3': 2, '4': 1, '5': 13, '10': 'promotion'},
  ],
};

/// Descriptor for `UserDiscoveryVersion`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userDiscoveryVersionDescriptor = $convert.base64Decode(
    'ChRVc2VyRGlzY292ZXJ5VmVyc2lvbhIiCgxhbm5vdW5jZW1lbnQYASABKA1SDGFubm91bmNlbW'
    'VudBIcCglwcm9tb3Rpb24YAiABKA1SCXByb21vdGlvbg==');

@$core.Deprecated('Use userDiscoveryMessageDescriptor instead')
const UserDiscoveryMessage$json = {
  '1': 'UserDiscoveryMessage',
  '2': [
    {
      '1': 'version',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.user_discovery.UserDiscoveryVersion',
      '10': 'version'
    },
    {
      '1': 'user_discovery_announcement',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.user_discovery.UserDiscoveryMessage.UserDiscoveryAnnouncement',
      '9': 0,
      '10': 'userDiscoveryAnnouncement',
      '17': true
    },
    {
      '1': 'user_discovery_promotion',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.user_discovery.UserDiscoveryMessage.UserDiscoveryPromotion',
      '9': 1,
      '10': 'userDiscoveryPromotion',
      '17': true
    },
    {
      '1': 'user_discovery_recall',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.user_discovery.UserDiscoveryMessage.UserDiscoveryRecall',
      '9': 2,
      '10': 'userDiscoveryRecall',
      '17': true
    },
  ],
  '3': [
    UserDiscoveryMessage_UserDiscoveryAnnouncement$json,
    UserDiscoveryMessage_UserDiscoveryPromotion$json,
    UserDiscoveryMessage_UserDiscoveryRecall$json
  ],
  '8': [
    {'1': '_user_discovery_announcement'},
    {'1': '_user_discovery_promotion'},
    {'1': '_user_discovery_recall'},
  ],
};

@$core.Deprecated('Use userDiscoveryMessageDescriptor instead')
const UserDiscoveryMessage_UserDiscoveryAnnouncement$json = {
  '1': 'UserDiscoveryAnnouncement',
  '2': [
    {'1': 'public_id', '3': 1, '4': 1, '5': 3, '10': 'publicId'},
    {'1': 'threshold', '3': 2, '4': 1, '5': 13, '10': 'threshold'},
    {
      '1': 'announcement_share',
      '3': 4,
      '4': 1,
      '5': 12,
      '10': 'announcementShare'
    },
    {
      '1': 'verification_shares',
      '3': 6,
      '4': 3,
      '5': 12,
      '10': 'verificationShares'
    },
  ],
};

@$core.Deprecated('Use userDiscoveryMessageDescriptor instead')
const UserDiscoveryMessage_UserDiscoveryPromotion$json = {
  '1': 'UserDiscoveryPromotion',
  '2': [
    {'1': 'promotion_id', '3': 1, '4': 1, '5': 13, '10': 'promotionId'},
    {'1': 'public_id', '3': 2, '4': 1, '5': 3, '10': 'publicId'},
    {'1': 'threshold', '3': 3, '4': 1, '5': 13, '10': 'threshold'},
    {
      '1': 'announcement_share',
      '3': 5,
      '4': 1,
      '5': 12,
      '10': 'announcementShare'
    },
    {
      '1': 'public_key_verified_timestamp',
      '3': 6,
      '4': 1,
      '5': 3,
      '9': 0,
      '10': 'publicKeyVerifiedTimestamp',
      '17': true
    },
  ],
  '3': [
    UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted$json
  ],
  '8': [
    {'1': '_public_key_verified_timestamp'},
  ],
};

@$core.Deprecated('Use userDiscoveryMessageDescriptor instead')
const UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted$json =
    {
  '1': 'AnnouncementShareDecrypted',
  '2': [
    {
      '1': 'signed_data',
      '3': 1,
      '4': 1,
      '5': 11,
      '6':
          '.user_discovery.UserDiscoveryMessage.UserDiscoveryPromotion.AnnouncementShareDecrypted.SignedData',
      '10': 'signedData'
    },
    {'1': 'signature', '3': 2, '4': 1, '5': 12, '10': 'signature'},
  ],
  '3': [
    UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted_SignedData$json
  ],
};

@$core.Deprecated('Use userDiscoveryMessageDescriptor instead')
const UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted_SignedData$json =
    {
  '1': 'SignedData',
  '2': [
    {'1': 'public_id', '3': 1, '4': 1, '5': 3, '10': 'publicId'},
    {'1': 'user_id', '3': 2, '4': 1, '5': 3, '10': 'userId'},
    {'1': 'public_key', '3': 3, '4': 1, '5': 12, '10': 'publicKey'},
  ],
};

@$core.Deprecated('Use userDiscoveryMessageDescriptor instead')
const UserDiscoveryMessage_UserDiscoveryRecall$json = {
  '1': 'UserDiscoveryRecall',
  '2': [
    {'1': 'promotion_id', '3': 1, '4': 1, '5': 3, '10': 'promotionId'},
  ],
};

/// Descriptor for `UserDiscoveryMessage`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List userDiscoveryMessageDescriptor = $convert.base64Decode(
    'ChRVc2VyRGlzY292ZXJ5TWVzc2FnZRI+Cgd2ZXJzaW9uGAEgASgLMiQudXNlcl9kaXNjb3Zlcn'
    'kuVXNlckRpc2NvdmVyeVZlcnNpb25SB3ZlcnNpb24SgwEKG3VzZXJfZGlzY292ZXJ5X2Fubm91'
    'bmNlbWVudBgCIAEoCzI+LnVzZXJfZGlzY292ZXJ5LlVzZXJEaXNjb3ZlcnlNZXNzYWdlLlVzZX'
    'JEaXNjb3ZlcnlBbm5vdW5jZW1lbnRIAFIZdXNlckRpc2NvdmVyeUFubm91bmNlbWVudIgBARJ6'
    'Chh1c2VyX2Rpc2NvdmVyeV9wcm9tb3Rpb24YAyABKAsyOy51c2VyX2Rpc2NvdmVyeS5Vc2VyRG'
    'lzY292ZXJ5TWVzc2FnZS5Vc2VyRGlzY292ZXJ5UHJvbW90aW9uSAFSFnVzZXJEaXNjb3ZlcnlQ'
    'cm9tb3Rpb26IAQEScQoVdXNlcl9kaXNjb3ZlcnlfcmVjYWxsGAQgASgLMjgudXNlcl9kaXNjb3'
    'ZlcnkuVXNlckRpc2NvdmVyeU1lc3NhZ2UuVXNlckRpc2NvdmVyeVJlY2FsbEgCUhN1c2VyRGlz'
    'Y292ZXJ5UmVjYWxsiAEBGrYBChlVc2VyRGlzY292ZXJ5QW5ub3VuY2VtZW50EhsKCXB1YmxpY1'
    '9pZBgBIAEoA1IIcHVibGljSWQSHAoJdGhyZXNob2xkGAIgASgNUgl0aHJlc2hvbGQSLQoSYW5u'
    'b3VuY2VtZW50X3NoYXJlGAQgASgMUhFhbm5vdW5jZW1lbnRTaGFyZRIvChN2ZXJpZmljYXRpb2'
    '5fc2hhcmVzGAYgAygMUhJ2ZXJpZmljYXRpb25TaGFyZXMatAQKFlVzZXJEaXNjb3ZlcnlQcm9t'
    'b3Rpb24SIQoMcHJvbW90aW9uX2lkGAEgASgNUgtwcm9tb3Rpb25JZBIbCglwdWJsaWNfaWQYAi'
    'ABKANSCHB1YmxpY0lkEhwKCXRocmVzaG9sZBgDIAEoDVIJdGhyZXNob2xkEi0KEmFubm91bmNl'
    'bWVudF9zaGFyZRgFIAEoDFIRYW5ub3VuY2VtZW50U2hhcmUSRgodcHVibGljX2tleV92ZXJpZm'
    'llZF90aW1lc3RhbXAYBiABKANIAFIacHVibGljS2V5VmVyaWZpZWRUaW1lc3RhbXCIAQEaogIK'
    'GkFubm91bmNlbWVudFNoYXJlRGVjcnlwdGVkEoIBCgtzaWduZWRfZGF0YRgBIAEoCzJhLnVzZX'
    'JfZGlzY292ZXJ5LlVzZXJEaXNjb3ZlcnlNZXNzYWdlLlVzZXJEaXNjb3ZlcnlQcm9tb3Rpb24u'
    'QW5ub3VuY2VtZW50U2hhcmVEZWNyeXB0ZWQuU2lnbmVkRGF0YVIKc2lnbmVkRGF0YRIcCglzaW'
    'duYXR1cmUYAiABKAxSCXNpZ25hdHVyZRphCgpTaWduZWREYXRhEhsKCXB1YmxpY19pZBgBIAEo'
    'A1IIcHVibGljSWQSFwoHdXNlcl9pZBgCIAEoA1IGdXNlcklkEh0KCnB1YmxpY19rZXkYAyABKA'
    'xSCXB1YmxpY0tleUIgCh5fcHVibGljX2tleV92ZXJpZmllZF90aW1lc3RhbXAaOAoTVXNlckRp'
    'c2NvdmVyeVJlY2FsbBIhCgxwcm9tb3Rpb25faWQYASABKANSC3Byb21vdGlvbklkQh4KHF91c2'
    'VyX2Rpc2NvdmVyeV9hbm5vdW5jZW1lbnRCGwoZX3VzZXJfZGlzY292ZXJ5X3Byb21vdGlvbkIY'
    'ChZfdXNlcl9kaXNjb3ZlcnlfcmVjYWxs');
