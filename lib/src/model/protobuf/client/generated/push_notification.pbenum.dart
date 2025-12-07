// This is a generated file - do not edit.
//
// Generated from push_notification.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class PushKind extends $pb.ProtobufEnum {
  static const PushKind reaction =
      PushKind._(0, _omitEnumNames ? '' : 'reaction');
  static const PushKind response =
      PushKind._(1, _omitEnumNames ? '' : 'response');
  static const PushKind text = PushKind._(2, _omitEnumNames ? '' : 'text');
  static const PushKind video = PushKind._(3, _omitEnumNames ? '' : 'video');
  static const PushKind twonly = PushKind._(4, _omitEnumNames ? '' : 'twonly');
  static const PushKind image = PushKind._(5, _omitEnumNames ? '' : 'image');
  static const PushKind contactRequest =
      PushKind._(6, _omitEnumNames ? '' : 'contactRequest');
  static const PushKind acceptRequest =
      PushKind._(7, _omitEnumNames ? '' : 'acceptRequest');
  static const PushKind storedMediaFile =
      PushKind._(8, _omitEnumNames ? '' : 'storedMediaFile');
  static const PushKind testNotification =
      PushKind._(9, _omitEnumNames ? '' : 'testNotification');
  static const PushKind reopenedMedia =
      PushKind._(10, _omitEnumNames ? '' : 'reopenedMedia');
  static const PushKind reactionToVideo =
      PushKind._(11, _omitEnumNames ? '' : 'reactionToVideo');
  static const PushKind reactionToText =
      PushKind._(12, _omitEnumNames ? '' : 'reactionToText');
  static const PushKind reactionToImage =
      PushKind._(13, _omitEnumNames ? '' : 'reactionToImage');
  static const PushKind reactionToAudio =
      PushKind._(14, _omitEnumNames ? '' : 'reactionToAudio');
  static const PushKind addedToGroup =
      PushKind._(15, _omitEnumNames ? '' : 'addedToGroup');
  static const PushKind audio = PushKind._(16, _omitEnumNames ? '' : 'audio');

  static const $core.List<PushKind> values = <PushKind>[
    reaction,
    response,
    text,
    video,
    twonly,
    image,
    contactRequest,
    acceptRequest,
    storedMediaFile,
    testNotification,
    reopenedMedia,
    reactionToVideo,
    reactionToText,
    reactionToImage,
    reactionToAudio,
    addedToGroup,
    audio,
  ];

  static final $core.List<PushKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 16);
  static PushKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PushKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
