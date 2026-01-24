// This is a generated file - do not edit.
//
// Generated from data.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class AdditionalMessageData_Type extends $pb.ProtobufEnum {
  static const AdditionalMessageData_Type LINK =
      AdditionalMessageData_Type._(0, _omitEnumNames ? '' : 'LINK');

  static const $core.List<AdditionalMessageData_Type> values =
      <AdditionalMessageData_Type>[
    LINK,
  ];

  static final $core.List<AdditionalMessageData_Type?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 0);
  static AdditionalMessageData_Type? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AdditionalMessageData_Type._(super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
