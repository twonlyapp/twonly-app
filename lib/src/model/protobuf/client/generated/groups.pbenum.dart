//
//  Generated code. Do not modify.
//  source: groups.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class EncryptedAppendedGroupState_Type extends $pb.ProtobufEnum {
  static const EncryptedAppendedGroupState_Type LEFT_GROUP = EncryptedAppendedGroupState_Type._(0, _omitEnumNames ? '' : 'LEFT_GROUP');

  static const $core.List<EncryptedAppendedGroupState_Type> values = <EncryptedAppendedGroupState_Type> [
    LEFT_GROUP,
  ];

  static final $core.Map<$core.int, EncryptedAppendedGroupState_Type> _byValue = $pb.ProtobufEnum.initByValue(values);
  static EncryptedAppendedGroupState_Type? valueOf($core.int value) => _byValue[value];

  const EncryptedAppendedGroupState_Type._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
