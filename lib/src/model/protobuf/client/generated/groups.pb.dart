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

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

/// Stored encrypted on the server in the members columns.
class EncryptedGroupState extends $pb.GeneratedMessage {
  factory EncryptedGroupState({
    $core.Iterable<$fixnum.Int64>? memberIds,
    $core.Iterable<$fixnum.Int64>? adminIds,
    $core.String? groupName,
    $fixnum.Int64? deleteMessagesAfterMilliseconds,
    $core.List<$core.int>? padding,
  }) {
    final $result = create();
    if (memberIds != null) {
      $result.memberIds.addAll(memberIds);
    }
    if (adminIds != null) {
      $result.adminIds.addAll(adminIds);
    }
    if (groupName != null) {
      $result.groupName = groupName;
    }
    if (deleteMessagesAfterMilliseconds != null) {
      $result.deleteMessagesAfterMilliseconds = deleteMessagesAfterMilliseconds;
    }
    if (padding != null) {
      $result.padding = padding;
    }
    return $result;
  }
  EncryptedGroupState._() : super();
  factory EncryptedGroupState.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EncryptedGroupState.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EncryptedGroupState', createEmptyInstance: create)
    ..p<$fixnum.Int64>(1, _omitFieldNames ? '' : 'memberIds', $pb.PbFieldType.K6, protoName: 'memberIds')
    ..p<$fixnum.Int64>(2, _omitFieldNames ? '' : 'adminIds', $pb.PbFieldType.K6, protoName: 'adminIds')
    ..aOS(3, _omitFieldNames ? '' : 'groupName', protoName: 'groupName')
    ..aInt64(4, _omitFieldNames ? '' : 'deleteMessagesAfterMilliseconds', protoName: 'deleteMessagesAfterMilliseconds')
    ..a<$core.List<$core.int>>(5, _omitFieldNames ? '' : 'padding', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EncryptedGroupState clone() => EncryptedGroupState()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EncryptedGroupState copyWith(void Function(EncryptedGroupState) updates) => super.copyWith((message) => updates(message as EncryptedGroupState)) as EncryptedGroupState;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EncryptedGroupState create() => EncryptedGroupState._();
  EncryptedGroupState createEmptyInstance() => create();
  static $pb.PbList<EncryptedGroupState> createRepeated() => $pb.PbList<EncryptedGroupState>();
  @$core.pragma('dart2js:noInline')
  static EncryptedGroupState getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EncryptedGroupState>(create);
  static EncryptedGroupState? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$fixnum.Int64> get memberIds => $_getList(0);

  @$pb.TagNumber(2)
  $core.List<$fixnum.Int64> get adminIds => $_getList(1);

  @$pb.TagNumber(3)
  $core.String get groupName => $_getSZ(2);
  @$pb.TagNumber(3)
  set groupName($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasGroupName() => $_has(2);
  @$pb.TagNumber(3)
  void clearGroupName() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get deleteMessagesAfterMilliseconds => $_getI64(3);
  @$pb.TagNumber(4)
  set deleteMessagesAfterMilliseconds($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasDeleteMessagesAfterMilliseconds() => $_has(3);
  @$pb.TagNumber(4)
  void clearDeleteMessagesAfterMilliseconds() => clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.int> get padding => $_getN(4);
  @$pb.TagNumber(5)
  set padding($core.List<$core.int> v) { $_setBytes(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasPadding() => $_has(4);
  @$pb.TagNumber(5)
  void clearPadding() => clearField(5);
}

class EncryptedGroupStateEnvelop extends $pb.GeneratedMessage {
  factory EncryptedGroupStateEnvelop({
    $core.List<$core.int>? nonce,
    $core.List<$core.int>? encryptedGroupState,
    $core.List<$core.int>? mac,
  }) {
    final $result = create();
    if (nonce != null) {
      $result.nonce = nonce;
    }
    if (encryptedGroupState != null) {
      $result.encryptedGroupState = encryptedGroupState;
    }
    if (mac != null) {
      $result.mac = mac;
    }
    return $result;
  }
  EncryptedGroupStateEnvelop._() : super();
  factory EncryptedGroupStateEnvelop.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EncryptedGroupStateEnvelop.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EncryptedGroupStateEnvelop', createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'nonce', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'encryptedGroupState', $pb.PbFieldType.OY, protoName: 'encryptedGroupState')
    ..a<$core.List<$core.int>>(3, _omitFieldNames ? '' : 'mac', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EncryptedGroupStateEnvelop clone() => EncryptedGroupStateEnvelop()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EncryptedGroupStateEnvelop copyWith(void Function(EncryptedGroupStateEnvelop) updates) => super.copyWith((message) => updates(message as EncryptedGroupStateEnvelop)) as EncryptedGroupStateEnvelop;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EncryptedGroupStateEnvelop create() => EncryptedGroupStateEnvelop._();
  EncryptedGroupStateEnvelop createEmptyInstance() => create();
  static $pb.PbList<EncryptedGroupStateEnvelop> createRepeated() => $pb.PbList<EncryptedGroupStateEnvelop>();
  @$core.pragma('dart2js:noInline')
  static EncryptedGroupStateEnvelop getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EncryptedGroupStateEnvelop>(create);
  static EncryptedGroupStateEnvelop? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get nonce => $_getN(0);
  @$pb.TagNumber(1)
  set nonce($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasNonce() => $_has(0);
  @$pb.TagNumber(1)
  void clearNonce() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get encryptedGroupState => $_getN(1);
  @$pb.TagNumber(2)
  set encryptedGroupState($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasEncryptedGroupState() => $_has(1);
  @$pb.TagNumber(2)
  void clearEncryptedGroupState() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get mac => $_getN(2);
  @$pb.TagNumber(3)
  set mac($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasMac() => $_has(2);
  @$pb.TagNumber(3)
  void clearMac() => clearField(3);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
