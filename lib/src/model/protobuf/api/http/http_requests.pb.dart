// This is a generated file - do not edit.
//
// Generated from api/http/http_requests.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class TextMessage extends $pb.GeneratedMessage {
  factory TextMessage({
    $fixnum.Int64? userId,
    $core.List<$core.int>? body,
    $core.List<$core.int>? pushData,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    if (body != null) result.body = body;
    if (pushData != null) result.pushData = pushData;
    return result;
  }

  TextMessage._();

  factory TextMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TextMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TextMessage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'http_requests'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'userId')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'body', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'pushData', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TextMessage clone() => TextMessage()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TextMessage copyWith(void Function(TextMessage) updates) =>
      super.copyWith((message) => updates(message as TextMessage))
          as TextMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TextMessage create() => TextMessage._();
  @$core.override
  TextMessage createEmptyInstance() => create();
  static $pb.PbList<TextMessage> createRepeated() => $pb.PbList<TextMessage>();
  @$core.pragma('dart2js:noInline')
  static TextMessage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TextMessage>(create);
  static TextMessage? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get userId => $_getI64(0);
  @$pb.TagNumber(1)
  set userId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get body => $_getN(1);
  @$pb.TagNumber(2)
  set body($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBody() => $_has(1);
  @$pb.TagNumber(2)
  void clearBody() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get pushData => $_getN(2);
  @$pb.TagNumber(3)
  set pushData($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPushData() => $_has(2);
  @$pb.TagNumber(3)
  void clearPushData() => $_clearField(3);
}

class UploadRequest extends $pb.GeneratedMessage {
  factory UploadRequest({
    $core.List<$core.int>? encryptedData,
    $core.Iterable<$core.List<$core.int>>? downloadTokens,
    $core.Iterable<TextMessage>? messagesOnSuccess,
  }) {
    final result = create();
    if (encryptedData != null) result.encryptedData = encryptedData;
    if (downloadTokens != null) result.downloadTokens.addAll(downloadTokens);
    if (messagesOnSuccess != null)
      result.messagesOnSuccess.addAll(messagesOnSuccess);
    return result;
  }

  UploadRequest._();

  factory UploadRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UploadRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UploadRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'http_requests'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'encryptedData', $pb.PbFieldType.OY)
    ..p<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'downloadTokens', $pb.PbFieldType.PY)
    ..pc<TextMessage>(
        3, _omitFieldNames ? '' : 'messagesOnSuccess', $pb.PbFieldType.PM,
        subBuilder: TextMessage.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadRequest clone() => UploadRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadRequest copyWith(void Function(UploadRequest) updates) =>
      super.copyWith((message) => updates(message as UploadRequest))
          as UploadRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UploadRequest create() => UploadRequest._();
  @$core.override
  UploadRequest createEmptyInstance() => create();
  static $pb.PbList<UploadRequest> createRepeated() =>
      $pb.PbList<UploadRequest>();
  @$core.pragma('dart2js:noInline')
  static UploadRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UploadRequest>(create);
  static UploadRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get encryptedData => $_getN(0);
  @$pb.TagNumber(1)
  set encryptedData($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEncryptedData() => $_has(0);
  @$pb.TagNumber(1)
  void clearEncryptedData() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.List<$core.int>> get downloadTokens => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<TextMessage> get messagesOnSuccess => $_getList(2);
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
    final result = create();
    if (versionId != null) result.versionId = versionId;
    if (encryptedGroupState != null)
      result.encryptedGroupState = encryptedGroupState;
    if (publicKey != null) result.publicKey = publicKey;
    if (removeAdmin != null) result.removeAdmin = removeAdmin;
    if (addAdmin != null) result.addAdmin = addAdmin;
    if (nonce != null) result.nonce = nonce;
    return result;
  }

  UpdateGroupState_UpdateTBS._();

  factory UpdateGroupState_UpdateTBS.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateGroupState_UpdateTBS.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateGroupState.UpdateTBS',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'http_requests'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'versionId', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'encryptedGroupState', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'publicKey', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'removeAdmin', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        6, _omitFieldNames ? '' : 'addAdmin', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        7, _omitFieldNames ? '' : 'nonce', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateGroupState_UpdateTBS clone() =>
      UpdateGroupState_UpdateTBS()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateGroupState_UpdateTBS copyWith(
          void Function(UpdateGroupState_UpdateTBS) updates) =>
      super.copyWith(
              (message) => updates(message as UpdateGroupState_UpdateTBS))
          as UpdateGroupState_UpdateTBS;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateGroupState_UpdateTBS create() => UpdateGroupState_UpdateTBS._();
  @$core.override
  UpdateGroupState_UpdateTBS createEmptyInstance() => create();
  static $pb.PbList<UpdateGroupState_UpdateTBS> createRepeated() =>
      $pb.PbList<UpdateGroupState_UpdateTBS>();
  @$core.pragma('dart2js:noInline')
  static UpdateGroupState_UpdateTBS getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateGroupState_UpdateTBS>(create);
  static UpdateGroupState_UpdateTBS? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get versionId => $_getI64(0);
  @$pb.TagNumber(1)
  set versionId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersionId() => $_clearField(1);

  @$pb.TagNumber(3)
  $core.List<$core.int> get encryptedGroupState => $_getN(1);
  @$pb.TagNumber(3)
  set encryptedGroupState($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(3)
  $core.bool hasEncryptedGroupState() => $_has(1);
  @$pb.TagNumber(3)
  void clearEncryptedGroupState() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get publicKey => $_getN(2);
  @$pb.TagNumber(4)
  set publicKey($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(4)
  $core.bool hasPublicKey() => $_has(2);
  @$pb.TagNumber(4)
  void clearPublicKey() => $_clearField(4);

  /// public group key
  @$pb.TagNumber(5)
  $core.List<$core.int> get removeAdmin => $_getN(3);
  @$pb.TagNumber(5)
  set removeAdmin($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(5)
  $core.bool hasRemoveAdmin() => $_has(3);
  @$pb.TagNumber(5)
  void clearRemoveAdmin() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.List<$core.int> get addAdmin => $_getN(4);
  @$pb.TagNumber(6)
  set addAdmin($core.List<$core.int> value) => $_setBytes(4, value);
  @$pb.TagNumber(6)
  $core.bool hasAddAdmin() => $_has(4);
  @$pb.TagNumber(6)
  void clearAddAdmin() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.List<$core.int> get nonce => $_getN(5);
  @$pb.TagNumber(7)
  set nonce($core.List<$core.int> value) => $_setBytes(5, value);
  @$pb.TagNumber(7)
  $core.bool hasNonce() => $_has(5);
  @$pb.TagNumber(7)
  void clearNonce() => $_clearField(7);
}

/// plaintext message send to the server
class UpdateGroupState extends $pb.GeneratedMessage {
  factory UpdateGroupState({
    UpdateGroupState_UpdateTBS? update,
    $core.List<$core.int>? signature,
  }) {
    final result = create();
    if (update != null) result.update = update;
    if (signature != null) result.signature = signature;
    return result;
  }

  UpdateGroupState._();

  factory UpdateGroupState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UpdateGroupState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UpdateGroupState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'http_requests'),
      createEmptyInstance: create)
    ..aOM<UpdateGroupState_UpdateTBS>(1, _omitFieldNames ? '' : 'update',
        subBuilder: UpdateGroupState_UpdateTBS.create)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'signature', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateGroupState clone() => UpdateGroupState()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UpdateGroupState copyWith(void Function(UpdateGroupState) updates) =>
      super.copyWith((message) => updates(message as UpdateGroupState))
          as UpdateGroupState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UpdateGroupState create() => UpdateGroupState._();
  @$core.override
  UpdateGroupState createEmptyInstance() => create();
  static $pb.PbList<UpdateGroupState> createRepeated() =>
      $pb.PbList<UpdateGroupState>();
  @$core.pragma('dart2js:noInline')
  static UpdateGroupState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UpdateGroupState>(create);
  static UpdateGroupState? _defaultInstance;

  @$pb.TagNumber(1)
  UpdateGroupState_UpdateTBS get update => $_getN(0);
  @$pb.TagNumber(1)
  set update(UpdateGroupState_UpdateTBS value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasUpdate() => $_has(0);
  @$pb.TagNumber(1)
  void clearUpdate() => $_clearField(1);
  @$pb.TagNumber(1)
  UpdateGroupState_UpdateTBS ensureUpdate() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get signature => $_getN(1);
  @$pb.TagNumber(2)
  set signature($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSignature() => $_has(1);
  @$pb.TagNumber(2)
  void clearSignature() => $_clearField(2);
}

class NewGroupState extends $pb.GeneratedMessage {
  factory NewGroupState({
    $core.String? groupId,
    $fixnum.Int64? versionId,
    $core.List<$core.int>? encryptedGroupState,
    $core.List<$core.int>? publicKey,
  }) {
    final result = create();
    if (groupId != null) result.groupId = groupId;
    if (versionId != null) result.versionId = versionId;
    if (encryptedGroupState != null)
      result.encryptedGroupState = encryptedGroupState;
    if (publicKey != null) result.publicKey = publicKey;
    return result;
  }

  NewGroupState._();

  factory NewGroupState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NewGroupState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NewGroupState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'http_requests'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'groupId')
    ..a<$fixnum.Int64>(
        2, _omitFieldNames ? '' : 'versionId', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'encryptedGroupState', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'publicKey', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NewGroupState clone() => NewGroupState()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NewGroupState copyWith(void Function(NewGroupState) updates) =>
      super.copyWith((message) => updates(message as NewGroupState))
          as NewGroupState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NewGroupState create() => NewGroupState._();
  @$core.override
  NewGroupState createEmptyInstance() => create();
  static $pb.PbList<NewGroupState> createRepeated() =>
      $pb.PbList<NewGroupState>();
  @$core.pragma('dart2js:noInline')
  static NewGroupState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NewGroupState>(create);
  static NewGroupState? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get groupId => $_getSZ(0);
  @$pb.TagNumber(1)
  set groupId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasGroupId() => $_has(0);
  @$pb.TagNumber(1)
  void clearGroupId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get versionId => $_getI64(1);
  @$pb.TagNumber(2)
  set versionId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVersionId() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersionId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get encryptedGroupState => $_getN(2);
  @$pb.TagNumber(3)
  set encryptedGroupState($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEncryptedGroupState() => $_has(2);
  @$pb.TagNumber(3)
  void clearEncryptedGroupState() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get publicKey => $_getN(3);
  @$pb.TagNumber(4)
  set publicKey($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPublicKey() => $_has(3);
  @$pb.TagNumber(4)
  void clearPublicKey() => $_clearField(4);
}

class AppendGroupState_AppendTBS extends $pb.GeneratedMessage {
  factory AppendGroupState_AppendTBS({
    $core.List<$core.int>? encryptedGroupStateAppend,
    $core.List<$core.int>? publicKey,
    $core.String? groupId,
    $core.List<$core.int>? nonce,
  }) {
    final result = create();
    if (encryptedGroupStateAppend != null)
      result.encryptedGroupStateAppend = encryptedGroupStateAppend;
    if (publicKey != null) result.publicKey = publicKey;
    if (groupId != null) result.groupId = groupId;
    if (nonce != null) result.nonce = nonce;
    return result;
  }

  AppendGroupState_AppendTBS._();

  factory AppendGroupState_AppendTBS.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AppendGroupState_AppendTBS.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AppendGroupState.AppendTBS',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'http_requests'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1,
        _omitFieldNames ? '' : 'encryptedGroupStateAppend', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'publicKey', $pb.PbFieldType.OY)
    ..aOS(3, _omitFieldNames ? '' : 'groupId')
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'nonce', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AppendGroupState_AppendTBS clone() =>
      AppendGroupState_AppendTBS()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AppendGroupState_AppendTBS copyWith(
          void Function(AppendGroupState_AppendTBS) updates) =>
      super.copyWith(
              (message) => updates(message as AppendGroupState_AppendTBS))
          as AppendGroupState_AppendTBS;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AppendGroupState_AppendTBS create() => AppendGroupState_AppendTBS._();
  @$core.override
  AppendGroupState_AppendTBS createEmptyInstance() => create();
  static $pb.PbList<AppendGroupState_AppendTBS> createRepeated() =>
      $pb.PbList<AppendGroupState_AppendTBS>();
  @$core.pragma('dart2js:noInline')
  static AppendGroupState_AppendTBS getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AppendGroupState_AppendTBS>(create);
  static AppendGroupState_AppendTBS? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get encryptedGroupStateAppend => $_getN(0);
  @$pb.TagNumber(1)
  set encryptedGroupStateAppend($core.List<$core.int> value) =>
      $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEncryptedGroupStateAppend() => $_has(0);
  @$pb.TagNumber(1)
  void clearEncryptedGroupStateAppend() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get publicKey => $_getN(1);
  @$pb.TagNumber(2)
  set publicKey($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPublicKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearPublicKey() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get groupId => $_getSZ(2);
  @$pb.TagNumber(3)
  set groupId($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasGroupId() => $_has(2);
  @$pb.TagNumber(3)
  void clearGroupId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get nonce => $_getN(3);
  @$pb.TagNumber(4)
  set nonce($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasNonce() => $_has(3);
  @$pb.TagNumber(4)
  void clearNonce() => $_clearField(4);
}

class AppendGroupState extends $pb.GeneratedMessage {
  factory AppendGroupState({
    $core.List<$core.int>? signature,
    AppendGroupState_AppendTBS? appendTBS,
    $fixnum.Int64? versionId,
  }) {
    final result = create();
    if (signature != null) result.signature = signature;
    if (appendTBS != null) result.appendTBS = appendTBS;
    if (versionId != null) result.versionId = versionId;
    return result;
  }

  AppendGroupState._();

  factory AppendGroupState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AppendGroupState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AppendGroupState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'http_requests'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'signature', $pb.PbFieldType.OY)
    ..aOM<AppendGroupState_AppendTBS>(2, _omitFieldNames ? '' : 'appendTBS',
        protoName: 'appendTBS', subBuilder: AppendGroupState_AppendTBS.create)
    ..a<$fixnum.Int64>(
        3, _omitFieldNames ? '' : 'versionId', $pb.PbFieldType.OU6,
        protoName: 'versionId', defaultOrMaker: $fixnum.Int64.ZERO)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AppendGroupState clone() => AppendGroupState()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AppendGroupState copyWith(void Function(AppendGroupState) updates) =>
      super.copyWith((message) => updates(message as AppendGroupState))
          as AppendGroupState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AppendGroupState create() => AppendGroupState._();
  @$core.override
  AppendGroupState createEmptyInstance() => create();
  static $pb.PbList<AppendGroupState> createRepeated() =>
      $pb.PbList<AppendGroupState>();
  @$core.pragma('dart2js:noInline')
  static AppendGroupState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AppendGroupState>(create);
  static AppendGroupState? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get signature => $_getN(0);
  @$pb.TagNumber(1)
  set signature($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSignature() => $_has(0);
  @$pb.TagNumber(1)
  void clearSignature() => $_clearField(1);

  @$pb.TagNumber(2)
  AppendGroupState_AppendTBS get appendTBS => $_getN(1);
  @$pb.TagNumber(2)
  set appendTBS(AppendGroupState_AppendTBS value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasAppendTBS() => $_has(1);
  @$pb.TagNumber(2)
  void clearAppendTBS() => $_clearField(2);
  @$pb.TagNumber(2)
  AppendGroupState_AppendTBS ensureAppendTBS() => $_ensure(1);

  @$pb.TagNumber(3)
  $fixnum.Int64 get versionId => $_getI64(2);
  @$pb.TagNumber(3)
  set versionId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasVersionId() => $_has(2);
  @$pb.TagNumber(3)
  void clearVersionId() => $_clearField(3);
}

class GroupState extends $pb.GeneratedMessage {
  factory GroupState({
    $fixnum.Int64? versionId,
    $core.List<$core.int>? encryptedGroupState,
    $core.Iterable<AppendGroupState>? appendedGroupStates,
  }) {
    final result = create();
    if (versionId != null) result.versionId = versionId;
    if (encryptedGroupState != null)
      result.encryptedGroupState = encryptedGroupState;
    if (appendedGroupStates != null)
      result.appendedGroupStates.addAll(appendedGroupStates);
    return result;
  }

  GroupState._();

  factory GroupState.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory GroupState.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'GroupState',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'http_requests'),
      createEmptyInstance: create)
    ..a<$fixnum.Int64>(
        1, _omitFieldNames ? '' : 'versionId', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'encryptedGroupState', $pb.PbFieldType.OY)
    ..pc<AppendGroupState>(
        3, _omitFieldNames ? '' : 'appendedGroupStates', $pb.PbFieldType.PM,
        subBuilder: AppendGroupState.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupState clone() => GroupState()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  GroupState copyWith(void Function(GroupState) updates) =>
      super.copyWith((message) => updates(message as GroupState)) as GroupState;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static GroupState create() => GroupState._();
  @$core.override
  GroupState createEmptyInstance() => create();
  static $pb.PbList<GroupState> createRepeated() => $pb.PbList<GroupState>();
  @$core.pragma('dart2js:noInline')
  static GroupState getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<GroupState>(create);
  static GroupState? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get versionId => $_getI64(0);
  @$pb.TagNumber(1)
  set versionId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVersionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get encryptedGroupState => $_getN(1);
  @$pb.TagNumber(2)
  set encryptedGroupState($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEncryptedGroupState() => $_has(1);
  @$pb.TagNumber(2)
  void clearEncryptedGroupState() => $_clearField(2);

  @$pb.TagNumber(3)
  $pb.PbList<AppendGroupState> get appendedGroupStates => $_getList(2);
}

/// this is just a database helper to store multiple appends
class AppendGroupStateHelper extends $pb.GeneratedMessage {
  factory AppendGroupStateHelper({
    $core.Iterable<AppendGroupState>? appendedGroupStates,
  }) {
    final result = create();
    if (appendedGroupStates != null)
      result.appendedGroupStates.addAll(appendedGroupStates);
    return result;
  }

  AppendGroupStateHelper._();

  factory AppendGroupStateHelper.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory AppendGroupStateHelper.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'AppendGroupStateHelper',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'http_requests'),
      createEmptyInstance: create)
    ..pc<AppendGroupState>(
        1, _omitFieldNames ? '' : 'appendedGroupStates', $pb.PbFieldType.PM,
        subBuilder: AppendGroupState.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AppendGroupStateHelper clone() =>
      AppendGroupStateHelper()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AppendGroupStateHelper copyWith(
          void Function(AppendGroupStateHelper) updates) =>
      super.copyWith((message) => updates(message as AppendGroupStateHelper))
          as AppendGroupStateHelper;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static AppendGroupStateHelper create() => AppendGroupStateHelper._();
  @$core.override
  AppendGroupStateHelper createEmptyInstance() => create();
  static $pb.PbList<AppendGroupStateHelper> createRepeated() =>
      $pb.PbList<AppendGroupStateHelper>();
  @$core.pragma('dart2js:noInline')
  static AppendGroupStateHelper getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<AppendGroupStateHelper>(create);
  static AppendGroupStateHelper? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<AppendGroupState> get appendedGroupStates => $_getList(0);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
