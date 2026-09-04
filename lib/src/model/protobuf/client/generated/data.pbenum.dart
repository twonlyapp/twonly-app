// This is a generated file - do not edit.
//
// Generated from data.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class AdditionalMessageData_Type extends $pb.ProtobufEnum {
  static const AdditionalMessageData_Type LINK =
      AdditionalMessageData_Type._(0, _omitEnumNames ? '' : 'LINK');
  static const AdditionalMessageData_Type CONTACTS =
      AdditionalMessageData_Type._(1, _omitEnumNames ? '' : 'CONTACTS');
  static const AdditionalMessageData_Type RESTORED_FLAME_COUNTER =
      AdditionalMessageData_Type._(
          2, _omitEnumNames ? '' : 'RESTORED_FLAME_COUNTER');
  static const AdditionalMessageData_Type ASK_ABOUT_USER =
      AdditionalMessageData_Type._(3, _omitEnumNames ? '' : 'ASK_ABOUT_USER');
  static const AdditionalMessageData_Type WEBXDC_APP =
      AdditionalMessageData_Type._(4, _omitEnumNames ? '' : 'WEBXDC_APP');
  static const AdditionalMessageData_Type WEBXDC_UPDATE =
      AdditionalMessageData_Type._(5, _omitEnumNames ? '' : 'WEBXDC_UPDATE');
  static const AdditionalMessageData_Type WEBXDC_SENT =
      AdditionalMessageData_Type._(6, _omitEnumNames ? '' : 'WEBXDC_SENT');

  static const $core.List<AdditionalMessageData_Type> values =
      <AdditionalMessageData_Type>[
    LINK,
    CONTACTS,
    RESTORED_FLAME_COUNTER,
    ASK_ABOUT_USER,
    WEBXDC_APP,
    WEBXDC_UPDATE,
    WEBXDC_SENT,
  ];

  static final $core.List<AdditionalMessageData_Type?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 6);
  static AdditionalMessageData_Type? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AdditionalMessageData_Type._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
