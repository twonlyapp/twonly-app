//
//  Generated code. Do not modify.
//  source: api/http/http_requests.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

class TextMessage extends $pb.GeneratedMessage {
  factory TextMessage({
    $fixnum.Int64? userId,
    $core.List<$core.int>? body,
    $core.List<$core.int>? pushData,
  }) {
    final $result = create();
    if (userId != null) {
      $result.userId = userId;
    }
    if (body != null) {
      $result.body = body;
    }
    if (pushData != null) {
      $result.pushData = pushData;
    }
    return $result;
  }
  TextMessage._() : super();
  factory TextMessage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TextMessage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TextMessage', package: const $pb.PackageName(_omitMessageNames ? '' : 'http_requests'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'userId')
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'body', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(3, _omitFieldNames ? '' : 'pushData', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TextMessage clone() => TextMessage()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TextMessage copyWith(void Function(TextMessage) updates) => super.copyWith((message) => updates(message as TextMessage)) as TextMessage;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TextMessage create() => TextMessage._();
  TextMessage createEmptyInstance() => create();
  static $pb.PbList<TextMessage> createRepeated() => $pb.PbList<TextMessage>();
  @$core.pragma('dart2js:noInline')
  static TextMessage getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TextMessage>(create);
  static TextMessage? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get userId => $_getI64(0);
  @$pb.TagNumber(1)
  set userId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get body => $_getN(1);
  @$pb.TagNumber(2)
  set body($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasBody() => $_has(1);
  @$pb.TagNumber(2)
  void clearBody() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get pushData => $_getN(2);
  @$pb.TagNumber(3)
  set pushData($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasPushData() => $_has(2);
  @$pb.TagNumber(3)
  void clearPushData() => clearField(3);
}

class UploadRequest extends $pb.GeneratedMessage {
  factory UploadRequest({
    $core.List<$core.int>? encryptedData,
    $core.Iterable<$core.List<$core.int>>? downloadTokens,
    $core.Iterable<TextMessage>? messagesOnSuccess,
  }) {
    final $result = create();
    if (encryptedData != null) {
      $result.encryptedData = encryptedData;
    }
    if (downloadTokens != null) {
      $result.downloadTokens.addAll(downloadTokens);
    }
    if (messagesOnSuccess != null) {
      $result.messagesOnSuccess.addAll(messagesOnSuccess);
    }
    return $result;
  }
  UploadRequest._() : super();
  factory UploadRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UploadRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'UploadRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'http_requests'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'encryptedData', $pb.PbFieldType.OY)
    ..p<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'downloadTokens', $pb.PbFieldType.PY)
    ..pc<TextMessage>(3, _omitFieldNames ? '' : 'messagesOnSuccess', $pb.PbFieldType.PM, subBuilder: TextMessage.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UploadRequest clone() => UploadRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UploadRequest copyWith(void Function(UploadRequest) updates) => super.copyWith((message) => updates(message as UploadRequest)) as UploadRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UploadRequest create() => UploadRequest._();
  UploadRequest createEmptyInstance() => create();
  static $pb.PbList<UploadRequest> createRepeated() => $pb.PbList<UploadRequest>();
  @$core.pragma('dart2js:noInline')
  static UploadRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UploadRequest>(create);
  static UploadRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get encryptedData => $_getN(0);
  @$pb.TagNumber(1)
  set encryptedData($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasEncryptedData() => $_has(0);
  @$pb.TagNumber(1)
  void clearEncryptedData() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.List<$core.int>> get downloadTokens => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<TextMessage> get messagesOnSuccess => $_getList(2);
}

class UpdateGroupState_UpdateTBS extends $pb.GeneratedMessage {
  factory UpdateGroupState_UpdateTBS({
    $fixnum.Int64? versionId,
    $core.List<$core.int>? encryptedGroupState,
    $core.List<$core.int>? publicKey,
    $core.List<$core.int>? removeAdmin,
    $core.List<$core.int>? addAdmin,
    $core.List<$core.int>? nonce,
  }) {
    final $result = create();
    if (versionId != null) {
      $result.versionId = versionId;
    }
    if (encryptedGroupState != null) {
      $result.encryptedGroupState = encryptedGroupState;
    }
    if (publicKey != null) {
      $result.publicKey = publicKey;
    }
    if (removeAdmin != null) {
      $result.removeAdmin = removeAdmin;
    }
    if (addAdmin != null) {
      $result.addAdmin = addAdmin;
    }
    if (nonce != null) {
      $result.nonce = nonce;
    }
    return $result;
  }
  UpdateGroupState_UpdateTBS._() : super();
  factory UpdateGroupState_UpdateTBS.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateGroupState_UpdateTBS.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'UpdateGroupState.UpdateTBS', package: const $pb.PackageName(_omitMessageNames ? '' : 'http_requests'), createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'versionId', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.List<$core.int>>(3, _omitFieldNames ? '' : 'encryptedGroupState', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(4, _omitFieldNames ? '' : 'publicKey', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(5, _omitFieldNames ? '' : 'removeAdmin', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(6, _omitFieldNames ? '' : 'addAdmin', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(7, _omitFieldNames ? '' : 'nonce', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdateGroupState_UpdateTBS clone() => UpdateGroupState_UpdateTBS()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdateGroupState_UpdateTBS copyWith(void Function(UpdateGroupState_UpdateTBS) updates) => super.copyWith((message) => updates(message as UpdateGroupState_UpdateTBS)) as UpdateGroupState_UpdateTBS;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateGroupState_UpdateTBS create() => UpdateGroupState_UpdateTBS._();
  UpdateGroupState_UpdateTBS createEmptyInstance() => create();
  static $pb.PbList<UpdateGroupState_UpdateTBS> createRepeated() => $pb.PbList<UpdateGroupState_UpdateTBS>();
  @$core.pragma('dart2js:noInline')
  static UpdateGroupState_UpdateTBS getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateGroupState_UpdateTBS>(create);
  static UpdateGroupState_UpdateTBS? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get versionId => $_getI64(0);
  @$pb.TagNumber(1)
  set versionId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasVersionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersionId() => clearField(1);

  @$pb.TagNumber(3)
  $core.List<$core.int> get encryptedGroupState => $_getN(1);
  @$pb.TagNumber(3)
  set encryptedGroupState($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(3)
  $core.bool hasEncryptedGroupState() => $_has(1);
  @$pb.TagNumber(3)
  void clearEncryptedGroupState() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get publicKey => $_getN(2);
  @$pb.TagNumber(4)
  set publicKey($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(4)
  $core.bool hasPublicKey() => $_has(2);
  @$pb.TagNumber(4)
  void clearPublicKey() => clearField(4);

  /// public group key
  @$pb.TagNumber(5)
  $core.List<$core.int> get removeAdmin => $_getN(3);
  @$pb.TagNumber(5)
  set removeAdmin($core.List<$core.int> v) { $_setBytes(3, v); }
  @$pb.TagNumber(5)
  $core.bool hasRemoveAdmin() => $_has(3);
  @$pb.TagNumber(5)
  void clearRemoveAdmin() => clearField(5);

  @$pb.TagNumber(6)
  $core.List<$core.int> get addAdmin => $_getN(4);
  @$pb.TagNumber(6)
  set addAdmin($core.List<$core.int> v) { $_setBytes(4, v); }
  @$pb.TagNumber(6)
  $core.bool hasAddAdmin() => $_has(4);
  @$pb.TagNumber(6)
  void clearAddAdmin() => clearField(6);

  @$pb.TagNumber(7)
  $core.List<$core.int> get nonce => $_getN(5);
  @$pb.TagNumber(7)
  set nonce($core.List<$core.int> v) { $_setBytes(5, v); }
  @$pb.TagNumber(7)
  $core.bool hasNonce() => $_has(5);
  @$pb.TagNumber(7)
  void clearNonce() => clearField(7);
}

/// plaintext message send to the server
class UpdateGroupState extends $pb.GeneratedMessage {
  factory UpdateGroupState({
    UpdateGroupState_UpdateTBS? update,
    $core.List<$core.int>? signature,
  }) {
    final $result = create();
    if (update != null) {
      $result.update = update;
    }
    if (signature != null) {
      $result.signature = signature;
    }
    return $result;
  }
  UpdateGroupState._() : super();
  factory UpdateGroupState.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UpdateGroupState.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'UpdateGroupState', package: const $pb.PackageName(_omitMessageNames ? '' : 'http_requests'), createEmptyInstance: create)
    ..aOM<UpdateGroupState_UpdateTBS>(1, _omitFieldNames ? '' : 'update', subBuilder: UpdateGroupState_UpdateTBS.create)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'signature', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UpdateGroupState clone() => UpdateGroupState()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UpdateGroupState copyWith(void Function(UpdateGroupState) updates) => super.copyWith((message) => updates(message as UpdateGroupState)) as UpdateGroupState;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateGroupState create() => UpdateGroupState._();
  UpdateGroupState createEmptyInstance() => create();
  static $pb.PbList<UpdateGroupState> createRepeated() => $pb.PbList<UpdateGroupState>();
  @$core.pragma('dart2js:noInline')
  static UpdateGroupState getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UpdateGroupState>(create);
  static UpdateGroupState? _defaultInstance;

  @$pb.TagNumber(1)
  UpdateGroupState_UpdateTBS get update => $_getN(0);
  @$pb.TagNumber(1)
  set update(UpdateGroupState_UpdateTBS v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasUpdate() => $_has(0);
  @$pb.TagNumber(1)
  void clearUpdate() => clearField(1);
  @$pb.TagNumber(1)
  UpdateGroupState_UpdateTBS ensureUpdate() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get signature => $_getN(1);
  @$pb.TagNumber(2)
  set signature($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSignature() => $_has(1);
  @$pb.TagNumber(2)
  void clearSignature() => clearField(2);
}

class NewGroupState extends $pb.GeneratedMessage {
  factory NewGroupState({
    $core.String? groupId,
    $fixnum.Int64? versionId,
    $core.List<$core.int>? encryptedGroupState,
    $core.List<$core.int>? publicKey,
  }) {
    final $result = create();
    if (groupId != null) {
      $result.groupId = groupId;
    }
    if (versionId != null) {
      $result.versionId = versionId;
    }
    if (encryptedGroupState != null) {
      $result.encryptedGroupState = encryptedGroupState;
    }
    if (publicKey != null) {
      $result.publicKey = publicKey;
    }
    return $result;
  }
  NewGroupState._() : super();
  factory NewGroupState.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory NewGroupState.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'NewGroupState', package: const $pb.PackageName(_omitMessageNames ? '' : 'http_requests'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'groupId', protoName: 'groupId')
    ..a<$fixnum.Int64>(2, _omitFieldNames ? '' : 'versionId', $pb.PbFieldType.OU6, protoName: 'versionId', defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.List<$core.int>>(4, _omitFieldNames ? '' : 'encryptedGroupState', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(5, _omitFieldNames ? '' : 'publicKey', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  NewGroupState clone() => NewGroupState()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  NewGroupState copyWith(void Function(NewGroupState) updates) => super.copyWith((message) => updates(message as NewGroupState)) as NewGroupState;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NewGroupState create() => NewGroupState._();
  NewGroupState createEmptyInstance() => create();
  static $pb.PbList<NewGroupState> createRepeated() => $pb.PbList<NewGroupState>();
  @$core.pragma('dart2js:noInline')
  static NewGroupState getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NewGroupState>(create);
  static NewGroupState? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get groupId => $_getSZ(0);
  @$pb.TagNumber(1)
  set groupId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGroupId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGroupId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get versionId => $_getI64(1);
  @$pb.TagNumber(2)
  set versionId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasVersionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersionId() => clearField(2);

  @$pb.TagNumber(4)
  $core.List<$core.int> get encryptedGroupState => $_getN(2);
  @$pb.TagNumber(4)
  set encryptedGroupState($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(4)
  $core.bool hasEncryptedGroupState() => $_has(2);
  @$pb.TagNumber(4)
  void clearEncryptedGroupState() => clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.int> get publicKey => $_getN(3);
  @$pb.TagNumber(5)
  set publicKey($core.List<$core.int> v) { $_setBytes(3, v); }
  @$pb.TagNumber(5)
  $core.bool hasPublicKey() => $_has(3);
  @$pb.TagNumber(5)
  void clearPublicKey() => clearField(5);
}

class GroupState extends $pb.GeneratedMessage {
  factory GroupState({
    $fixnum.Int64? versionId,
    $core.List<$core.int>? encryptedGroupState,
  }) {
    final $result = create();
    if (versionId != null) {
      $result.versionId = versionId;
    }
    if (encryptedGroupState != null) {
      $result.encryptedGroupState = encryptedGroupState;
    }
    return $result;
  }
  GroupState._() : super();
  factory GroupState.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory GroupState.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'GroupState', package: const $pb.PackageName(_omitMessageNames ? '' : 'http_requests'), createEmptyInstance: create)
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'versionId', $pb.PbFieldType.OU6, protoName: 'versionId', defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.List<$core.int>>(3, _omitFieldNames ? '' : 'encryptedGroupState', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  GroupState clone() => GroupState()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  GroupState copyWith(void Function(GroupState) updates) => super.copyWith((message) => updates(message as GroupState)) as GroupState;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GroupState create() => GroupState._();
  GroupState createEmptyInstance() => create();
  static $pb.PbList<GroupState> createRepeated() => $pb.PbList<GroupState>();
  @$core.pragma('dart2js:noInline')
  static GroupState getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<GroupState>(create);
  static GroupState? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get versionId => $_getI64(0);
  @$pb.TagNumber(1)
  set versionId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasVersionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersionId() => clearField(1);

  @$pb.TagNumber(3)
  $core.List<$core.int> get encryptedGroupState => $_getN(1);
  @$pb.TagNumber(3)
  set encryptedGroupState($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(3)
  $core.bool hasEncryptedGroupState() => $_has(1);
  @$pb.TagNumber(3)
  void clearEncryptedGroupState() => clearField(3);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
