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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'data.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'data.pbenum.dart';

class SharedContact extends $pb.GeneratedMessage {
  factory SharedContact({
    $fixnum.Int64? userId,
    $core.List<$core.int>? publicIdentityKey,
    $core.String? displayName,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    if (publicIdentityKey != null) result.publicIdentityKey = publicIdentityKey;
    if (displayName != null) result.displayName = displayName;
    return result;
  }

  SharedContact._();

  factory SharedContact.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SharedContact.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SharedContact',
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'userId')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'publicIdentityKey', $pb.PbFieldType.OY)
    ..aOS(3, _omitFieldNames ? '' : 'displayName')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SharedContact clone() => SharedContact()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SharedContact copyWith(void Function(SharedContact) updates) =>
      super.copyWith((message) => updates(message as SharedContact))
          as SharedContact;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SharedContact create() => SharedContact._();
  @$core.override
  SharedContact createEmptyInstance() => create();
  static $pb.PbList<SharedContact> createRepeated() =>
      $pb.PbList<SharedContact>();
  @$core.pragma('dart2js:noInline')
  static SharedContact getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SharedContact>(create);
  static SharedContact? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get userId => $_getI64(0);
  @$pb.TagNumber(1)
  set userId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get publicIdentityKey => $_getN(1);
  @$pb.TagNumber(2)
  set publicIdentityKey($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPublicIdentityKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearPublicIdentityKey() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get displayName => $_getSZ(2);
  @$pb.TagNumber(3)
  set displayName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDisplayName() => $_has(2);
  @$pb.TagNumber(3)
  void clearDisplayName() => $_clearField(3);
}

class AdditionalMessageData extends $pb.GeneratedMessage {
  factory AdditionalMessageData({
    AdditionalMessageData_Type? type,
    $core.String? link,
    $core.Iterable<SharedContact>? contacts,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (link != null) result.link = link;
    if (contacts != null) result.contacts.addAll(contacts);
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
    ..pc<SharedContact>(
        3, _omitFieldNames ? '' : 'contacts', $pb.PbFieldType.PM,
        subBuilder: SharedContact.create)
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

  @$pb.TagNumber(3)
  $pb.PbList<SharedContact> get contacts => $_getList(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
