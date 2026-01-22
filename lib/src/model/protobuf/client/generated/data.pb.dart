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

import 'data.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'data.pbenum.dart';

class AdditionalMessageData extends $pb.GeneratedMessage {
  factory AdditionalMessageData({
    AdditionalMessageData_Type? type,
    $core.String? link,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (link != null) result.link = link;
    return result;
  }

  AdditionalMessageData._();

  factory AdditionalMessageData.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AdditionalMessageData.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AdditionalMessageData',
      createEmptyInstance: create)
    ..e<AdditionalMessageData_Type>(
        1, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE,
        defaultOrMaker: AdditionalMessageData_Type.LINK,
        valueOf: AdditionalMessageData_Type.valueOf,
        enumValues: AdditionalMessageData_Type.values)
    ..aOS(2, _omitFieldNames ? '' : 'link')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdditionalMessageData clone() =>
      AdditionalMessageData()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdditionalMessageData copyWith(
          void Function(AdditionalMessageData) updates) =>
      super.copyWith((message) => updates(message as AdditionalMessageData))
          as AdditionalMessageData;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AdditionalMessageData create() => AdditionalMessageData._();
  @$core.override
  AdditionalMessageData createEmptyInstance() => create();
  static $pb.PbList<AdditionalMessageData> createRepeated() =>
      $pb.PbList<AdditionalMessageData>();
  @$core.pragma('dart2js:noInline')
  static AdditionalMessageData getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AdditionalMessageData>(create);
  static AdditionalMessageData? _defaultInstance;

  @$pb.TagNumber(1)
  AdditionalMessageData_Type get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(AdditionalMessageData_Type value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get link => $_getSZ(1);
  @$pb.TagNumber(2)
  set link($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasLink() => $_has(1);
  @$pb.TagNumber(2)
  void clearLink() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
