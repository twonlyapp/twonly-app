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
  static const PushKind REACTION =
      PushKind._(0, _omitEnumNames ? '' : 'REACTION');
  static const PushKind RESPONSE =
      PushKind._(1, _omitEnumNames ? '' : 'RESPONSE');
  static const PushKind TEXT = PushKind._(2, _omitEnumNames ? '' : 'TEXT');
  static const PushKind VIDEO = PushKind._(3, _omitEnumNames ? '' : 'VIDEO');
  static const PushKind TWONLY = PushKind._(4, _omitEnumNames ? '' : 'TWONLY');
  static const PushKind IMAGE = PushKind._(5, _omitEnumNames ? '' : 'IMAGE');
  static const PushKind CONTACT_REQUEST =
      PushKind._(6, _omitEnumNames ? '' : 'CONTACT_REQUEST');
  static const PushKind ACCEPT_REQUEST =
      PushKind._(7, _omitEnumNames ? '' : 'ACCEPT_REQUEST');
  static const PushKind STORED_MEDIA_FILE =
      PushKind._(8, _omitEnumNames ? '' : 'STORED_MEDIA_FILE');
  static const PushKind TEST_NOTIFICATION =
      PushKind._(9, _omitEnumNames ? '' : 'TEST_NOTIFICATION');
  static const PushKind REOPENED_MEDIA =
      PushKind._(10, _omitEnumNames ? '' : 'REOPENED_MEDIA');
  static const PushKind REACTION_TO_VIDEO =
      PushKind._(11, _omitEnumNames ? '' : 'REACTION_TO_VIDEO');
  static const PushKind REACTION_TO_TEXT =
      PushKind._(12, _omitEnumNames ? '' : 'REACTION_TO_TEXT');
  static const PushKind REACTION_TO_IMAGE =
      PushKind._(13, _omitEnumNames ? '' : 'REACTION_TO_IMAGE');
  static const PushKind REACTION_TO_AUDIO =
      PushKind._(14, _omitEnumNames ? '' : 'REACTION_TO_AUDIO');
  static const PushKind ADDED_TO_GROUP =
      PushKind._(15, _omitEnumNames ? '' : 'ADDED_TO_GROUP');
  static const PushKind AUDIO = PushKind._(16, _omitEnumNames ? '' : 'AUDIO');

  static const $core.List<PushKind> values = <PushKind>[
    REACTION,
    RESPONSE,
    TEXT,
    VIDEO,
    TWONLY,
    IMAGE,
    CONTACT_REQUEST,
    ACCEPT_REQUEST,
    STORED_MEDIA_FILE,
    TEST_NOTIFICATION,
    REOPENED_MEDIA,
    REACTION_TO_VIDEO,
    REACTION_TO_TEXT,
    REACTION_TO_IMAGE,
    REACTION_TO_AUDIO,
    ADDED_TO_GROUP,
    AUDIO,
  ];

  static final $core.List<PushKind?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 16);
  static PushKind? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const PushKind._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
