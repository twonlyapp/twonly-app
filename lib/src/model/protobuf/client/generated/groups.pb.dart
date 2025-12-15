// This is a generated file - do not edit.
//
// Generated from groups.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'groups.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'groups.pbenum.dart';

/// Stored encrypted on the server in the members columns.
class EncryptedGroupState extends $pb.GeneratedMessage {
  factory EncryptedGroupState({
    $core.Iterable<$fixnum.Int64>? memberIds,
    $core.Iterable<$fixnum.Int64>? adminIds,
    $core.String? groupName,
    $fixnum.Int64? deleteMessagesAfterMilliseconds,
    $core.List<$core.int>? padding,
  }) {
    final result = create();
    if (memberIds != null) result.memberIds.addAll(memberIds);
    if (adminIds != null) result.adminIds.addAll(adminIds);
    if (groupName != null) result.groupName = groupName;
    if (deleteMessagesAfterMilliseconds != null)
      result.deleteMessagesAfterMilliseconds = deleteMessagesAfterMilliseconds;
    if (padding != null) result.padding = padding;
    return result;
  }

  EncryptedGroupState._();

  factory EncryptedGroupState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EncryptedGroupState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EncryptedGroupState',
      createEmptyInstance: create)
    ..p<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'memberIds', $pb.PbFieldType.K6,
        protoName: 'memberIds')
    ..p<$fixnum.Int64>(2, _omitFieldNames ? '' : 'adminIds', $pb.PbFieldType.K6,
        protoName: 'adminIds')
    ..aOS(3, _omitFieldNames ? '' : 'groupName', protoName: 'groupName')
    ..aInt64(4, _omitFieldNames ? '' : 'deleteMessagesAfterMilliseconds',
        protoName: 'deleteMessagesAfterMilliseconds')
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'padding', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EncryptedGroupState clone() => EncryptedGroupState()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EncryptedGroupState copyWith(void Function(EncryptedGroupState) updates) =>
      super.copyWith((message) => updates(message as EncryptedGroupState))
          as EncryptedGroupState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EncryptedGroupState create() => EncryptedGroupState._();
  @$core.override
  EncryptedGroupState createEmptyInstance() => create();
  static $pb.PbList<EncryptedGroupState> createRepeated() =>
      $pb.PbList<EncryptedGroupState>();
  @$core.pragma('dart2js:noInline')
  static EncryptedGroupState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EncryptedGroupState>(create);
  static EncryptedGroupState? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$fixnum.Int64> get memberIds => $_getList(0);

  @$pb.TagNumber(2)
  $pb.PbList<$fixnum.Int64> get adminIds => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get groupName => $_getSZ(2);
  @$pb.TagNumber(3)
  set groupName($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGroupName() => $_has(2);
  @$pb.TagNumber(3)
  void clearGroupName() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get deleteMessagesAfterMilliseconds => $_getI64(3);
  @$pb.TagNumber(4)
  set deleteMessagesAfterMilliseconds($fixnum.Int64 value) =>
      $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasDeleteMessagesAfterMilliseconds() => $_has(3);
  @$pb.TagNumber(4)
  void clearDeleteMessagesAfterMilliseconds() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.int> get padding => $_getN(4);
  @$pb.TagNumber(5)
  set padding($core.List<$core.int> value) => $_setBytes(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPadding() => $_has(4);
  @$pb.TagNumber(5)
  void clearPadding() => $_clearField(5);
}

class EncryptedAppendedGroupState extends $pb.GeneratedMessage {
  factory EncryptedAppendedGroupState({
    EncryptedAppendedGroupState_Type? type,
  }) {
    final result = create();
    if (type != null) result.type = type;
    return result;
  }

  EncryptedAppendedGroupState._();

  factory EncryptedAppendedGroupState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EncryptedAppendedGroupState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EncryptedAppendedGroupState',
      createEmptyInstance: create)
    ..e<EncryptedAppendedGroupState_Type>(
        1, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE,
        defaultOrMaker: EncryptedAppendedGroupState_Type.LEFT_GROUP,
        valueOf: EncryptedAppendedGroupState_Type.valueOf,
        enumValues: EncryptedAppendedGroupState_Type.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EncryptedAppendedGroupState clone() =>
      EncryptedAppendedGroupState()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EncryptedAppendedGroupState copyWith(
          void Function(EncryptedAppendedGroupState) updates) =>
      super.copyWith(
              (message) => updates(message as EncryptedAppendedGroupState))
          as EncryptedAppendedGroupState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EncryptedAppendedGroupState create() =>
      EncryptedAppendedGroupState._();
  @$core.override
  EncryptedAppendedGroupState createEmptyInstance() => create();
  static $pb.PbList<EncryptedAppendedGroupState> createRepeated() =>
      $pb.PbList<EncryptedAppendedGroupState>();
  @$core.pragma('dart2js:noInline')
  static EncryptedAppendedGroupState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EncryptedAppendedGroupState>(create);
  static EncryptedAppendedGroupState? _defaultInstance;

  @$pb.TagNumber(1)
  EncryptedAppendedGroupState_Type get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(EncryptedAppendedGroupState_Type value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => $_clearField(1);
}

class EncryptedGroupStateEnvelop extends $pb.GeneratedMessage {
  factory EncryptedGroupStateEnvelop({
    $core.List<$core.int>? nonce,
    $core.List<$core.int>? encryptedGroupState,
    $core.List<$core.int>? mac,
  }) {
    final result = create();
    if (nonce != null) result.nonce = nonce;
    if (encryptedGroupState != null)
      result.encryptedGroupState = encryptedGroupState;
    if (mac != null) result.mac = mac;
    return result;
  }

  EncryptedGroupStateEnvelop._();

  factory EncryptedGroupStateEnvelop.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EncryptedGroupStateEnvelop.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EncryptedGroupStateEnvelop',
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'nonce', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'encryptedGroupState', $pb.PbFieldType.OY,
        protoName: 'encryptedGroupState')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'mac', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EncryptedGroupStateEnvelop clone() =>
      EncryptedGroupStateEnvelop()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EncryptedGroupStateEnvelop copyWith(
          void Function(EncryptedGroupStateEnvelop) updates) =>
      super.copyWith(
              (message) => updates(message as EncryptedGroupStateEnvelop))
          as EncryptedGroupStateEnvelop;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EncryptedGroupStateEnvelop create() => EncryptedGroupStateEnvelop._();
  @$core.override
  EncryptedGroupStateEnvelop createEmptyInstance() => create();
  static $pb.PbList<EncryptedGroupStateEnvelop> createRepeated() =>
      $pb.PbList<EncryptedGroupStateEnvelop>();
  @$core.pragma('dart2js:noInline')
  static EncryptedGroupStateEnvelop getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EncryptedGroupStateEnvelop>(create);
  static EncryptedGroupStateEnvelop? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get nonce => $_getN(0);
  @$pb.TagNumber(1)
  set nonce($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNonce() => $_has(0);
  @$pb.TagNumber(1)
  void clearNonce() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get encryptedGroupState => $_getN(1);
  @$pb.TagNumber(2)
  set encryptedGroupState($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEncryptedGroupState() => $_has(1);
  @$pb.TagNumber(2)
  void clearEncryptedGroupState() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get mac => $_getN(2);
  @$pb.TagNumber(3)
  set mac($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMac() => $_has(2);
  @$pb.TagNumber(3)
  void clearMac() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
