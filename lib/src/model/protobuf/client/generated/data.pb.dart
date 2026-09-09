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
  SharedContact clone() => deepCopy();
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
    $fixnum.Int64? restoredFlameCounter,
    $fixnum.Int64? askAboutUserId,
    WebxdcApp? webxdcApp,
    WebxdcUpdate? webxdcUpdate,
    WebxdcOrigin? webxdcOrigin,
    WebxdcSyncChunk? webxdcSync,
    WebxdcSyncRequest? webxdcSyncRequest,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (link != null) result.link = link;
    if (contacts != null) result.contacts.addAll(contacts);
    if (restoredFlameCounter != null)
      result.restoredFlameCounter = restoredFlameCounter;
    if (askAboutUserId != null) result.askAboutUserId = askAboutUserId;
    if (webxdcApp != null) result.webxdcApp = webxdcApp;
    if (webxdcUpdate != null) result.webxdcUpdate = webxdcUpdate;
    if (webxdcOrigin != null) result.webxdcOrigin = webxdcOrigin;
    if (webxdcSync != null) result.webxdcSync = webxdcSync;
    if (webxdcSyncRequest != null) result.webxdcSyncRequest = webxdcSyncRequest;
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
    ..aE<AdditionalMessageData_Type>(1, _omitFieldNames ? '' : 'type',
        enumValues: AdditionalMessageData_Type.values)
    ..aOS(2, _omitFieldNames ? '' : 'link')
    ..pPM<SharedContact>(3, _omitFieldNames ? '' : 'contacts',
        subBuilder: SharedContact.create)
    ..aInt64(4, _omitFieldNames ? '' : 'restoredFlameCounter')
    ..aInt64(5, _omitFieldNames ? '' : 'askAboutUserId')
    ..aOM<WebxdcApp>(6, _omitFieldNames ? '' : 'webxdcApp',
        subBuilder: WebxdcApp.create)
    ..aOM<WebxdcUpdate>(7, _omitFieldNames ? '' : 'webxdcUpdate',
        subBuilder: WebxdcUpdate.create)
    ..aOM<WebxdcOrigin>(8, _omitFieldNames ? '' : 'webxdcOrigin',
        subBuilder: WebxdcOrigin.create)
    ..aOM<WebxdcSyncChunk>(9, _omitFieldNames ? '' : 'webxdcSync',
        subBuilder: WebxdcSyncChunk.create)
    ..aOM<WebxdcSyncRequest>(10, _omitFieldNames ? '' : 'webxdcSyncRequest',
        subBuilder: WebxdcSyncRequest.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  AdditionalMessageData clone() => deepCopy();
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

  @$pb.TagNumber(4)
  $fixnum.Int64 get restoredFlameCounter => $_getI64(3);
  @$pb.TagNumber(4)
  set restoredFlameCounter($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRestoredFlameCounter() => $_has(3);
  @$pb.TagNumber(4)
  void clearRestoredFlameCounter() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get askAboutUserId => $_getI64(4);
  @$pb.TagNumber(5)
  set askAboutUserId($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAskAboutUserId() => $_has(4);
  @$pb.TagNumber(5)
  void clearAskAboutUserId() => $_clearField(5);

  @$pb.TagNumber(6)
  WebxdcApp get webxdcApp => $_getN(5);
  @$pb.TagNumber(6)
  set webxdcApp(WebxdcApp value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasWebxdcApp() => $_has(5);
  @$pb.TagNumber(6)
  void clearWebxdcApp() => $_clearField(6);
  @$pb.TagNumber(6)
  WebxdcApp ensureWebxdcApp() => $_ensure(5);

  @$pb.TagNumber(7)
  WebxdcUpdate get webxdcUpdate => $_getN(6);
  @$pb.TagNumber(7)
  set webxdcUpdate(WebxdcUpdate value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasWebxdcUpdate() => $_has(6);
  @$pb.TagNumber(7)
  void clearWebxdcUpdate() => $_clearField(7);
  @$pb.TagNumber(7)
  WebxdcUpdate ensureWebxdcUpdate() => $_ensure(6);

  @$pb.TagNumber(8)
  WebxdcOrigin get webxdcOrigin => $_getN(7);
  @$pb.TagNumber(8)
  set webxdcOrigin(WebxdcOrigin value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasWebxdcOrigin() => $_has(7);
  @$pb.TagNumber(8)
  void clearWebxdcOrigin() => $_clearField(8);
  @$pb.TagNumber(8)
  WebxdcOrigin ensureWebxdcOrigin() => $_ensure(7);

  @$pb.TagNumber(9)
  WebxdcSyncChunk get webxdcSync => $_getN(8);
  @$pb.TagNumber(9)
  set webxdcSync(WebxdcSyncChunk value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasWebxdcSync() => $_has(8);
  @$pb.TagNumber(9)
  void clearWebxdcSync() => $_clearField(9);
  @$pb.TagNumber(9)
  WebxdcSyncChunk ensureWebxdcSync() => $_ensure(8);

  @$pb.TagNumber(10)
  WebxdcSyncRequest get webxdcSyncRequest => $_getN(9);
  @$pb.TagNumber(10)
  set webxdcSyncRequest(WebxdcSyncRequest value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasWebxdcSyncRequest() => $_has(9);
  @$pb.TagNumber(10)
  void clearWebxdcSyncRequest() => $_clearField(10);
  @$pb.TagNumber(10)
  WebxdcSyncRequest ensureWebxdcSyncRequest() => $_ensure(9);
}

/// A peer-to-peer transfer of existing one-time app state. The encoded payload
/// is split into bounded hidden messages and installed only after every chunk
/// arrived and the digest matches.
class WebxdcSyncChunk extends $pb.GeneratedMessage {
  factory WebxdcSyncChunk({
    $core.String? transferId,
    $core.int? chunkIndex,
    $core.int? chunkCount,
    $core.List<$core.int>? payloadSha256,
    $core.List<$core.int>? payload,
  }) {
    final result = create();
    if (transferId != null) result.transferId = transferId;
    if (chunkIndex != null) result.chunkIndex = chunkIndex;
    if (chunkCount != null) result.chunkCount = chunkCount;
    if (payloadSha256 != null) result.payloadSha256 = payloadSha256;
    if (payload != null) result.payload = payload;
    return result;
  }

  WebxdcSyncChunk._();

  factory WebxdcSyncChunk.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WebxdcSyncChunk.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WebxdcSyncChunk',
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'transferId')
    ..aI(2, _omitFieldNames ? '' : 'chunkIndex', fieldType: $pb.PbFieldType.OU3)
    ..aI(3, _omitFieldNames ? '' : 'chunkCount', fieldType: $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'payloadSha256', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'payload', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebxdcSyncChunk clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebxdcSyncChunk copyWith(void Function(WebxdcSyncChunk) updates) =>
      super.copyWith((message) => updates(message as WebxdcSyncChunk))
          as WebxdcSyncChunk;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WebxdcSyncChunk create() => WebxdcSyncChunk._();
  @$core.override
  WebxdcSyncChunk createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WebxdcSyncChunk getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WebxdcSyncChunk>(create);
  static WebxdcSyncChunk? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get transferId => $_getSZ(0);
  @$pb.TagNumber(1)
  set transferId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasTransferId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTransferId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get chunkIndex => $_getIZ(1);
  @$pb.TagNumber(2)
  set chunkIndex($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasChunkIndex() => $_has(1);
  @$pb.TagNumber(2)
  void clearChunkIndex() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get chunkCount => $_getIZ(2);
  @$pb.TagNumber(3)
  set chunkCount($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasChunkCount() => $_has(2);
  @$pb.TagNumber(3)
  void clearChunkCount() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get payloadSha256 => $_getN(3);
  @$pb.TagNumber(4)
  set payloadSha256($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasPayloadSha256() => $_has(3);
  @$pb.TagNumber(4)
  void clearPayloadSha256() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.int> get payload => $_getN(4);
  @$pb.TagNumber(5)
  set payload($core.List<$core.int> value) => $_setBytes(4, value);
  @$pb.TagNumber(5)
  $core.bool hasPayload() => $_has(4);
  @$pb.TagNumber(5)
  void clearPayload() => $_clearField(5);
}

class WebxdcSyncRequest extends $pb.GeneratedMessage {
  factory WebxdcSyncRequest() => create();

  WebxdcSyncRequest._();

  factory WebxdcSyncRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WebxdcSyncRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WebxdcSyncRequest',
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebxdcSyncRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebxdcSyncRequest copyWith(void Function(WebxdcSyncRequest) updates) =>
      super.copyWith((message) => updates(message as WebxdcSyncRequest))
          as WebxdcSyncRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WebxdcSyncRequest create() => WebxdcSyncRequest._();
  @$core.override
  WebxdcSyncRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WebxdcSyncRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WebxdcSyncRequest>(create);
  static WebxdcSyncRequest? _defaultInstance;
}

class WebxdcSyncPayload extends $pb.GeneratedMessage {
  factory WebxdcSyncPayload({
    $core.Iterable<WebxdcSyncInstance>? instances,
  }) {
    final result = create();
    if (instances != null) result.instances.addAll(instances);
    return result;
  }

  WebxdcSyncPayload._();

  factory WebxdcSyncPayload.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WebxdcSyncPayload.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WebxdcSyncPayload',
      createEmptyInstance: create)
    ..pPM<WebxdcSyncInstance>(1, _omitFieldNames ? '' : 'instances',
        subBuilder: WebxdcSyncInstance.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebxdcSyncPayload clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebxdcSyncPayload copyWith(void Function(WebxdcSyncPayload) updates) =>
      super.copyWith((message) => updates(message as WebxdcSyncPayload))
          as WebxdcSyncPayload;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WebxdcSyncPayload create() => WebxdcSyncPayload._();
  @$core.override
  WebxdcSyncPayload createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WebxdcSyncPayload getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WebxdcSyncPayload>(create);
  static WebxdcSyncPayload? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<WebxdcSyncInstance> get instances => $_getList(0);
}

class WebxdcSyncInstance extends $pb.GeneratedMessage {
  factory WebxdcSyncInstance({
    $core.String? instanceId,
    $core.String? appId,
    $fixnum.Int64? version,
    $core.String? summary,
    $core.String? document,
    $fixnum.Int64? createdAt,
    $fixnum.Int64? lastUpdateAt,
    $core.Iterable<WebxdcSyncUpdate>? updates,
  }) {
    final result = create();
    if (instanceId != null) result.instanceId = instanceId;
    if (appId != null) result.appId = appId;
    if (version != null) result.version = version;
    if (summary != null) result.summary = summary;
    if (document != null) result.document = document;
    if (createdAt != null) result.createdAt = createdAt;
    if (lastUpdateAt != null) result.lastUpdateAt = lastUpdateAt;
    if (updates != null) result.updates.addAll(updates);
    return result;
  }

  WebxdcSyncInstance._();

  factory WebxdcSyncInstance.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WebxdcSyncInstance.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WebxdcSyncInstance',
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'instanceId')
    ..aOS(2, _omitFieldNames ? '' : 'appId')
    ..aInt64(3, _omitFieldNames ? '' : 'version')
    ..aOS(4, _omitFieldNames ? '' : 'summary')
    ..aOS(5, _omitFieldNames ? '' : 'document')
    ..aInt64(6, _omitFieldNames ? '' : 'createdAt')
    ..aInt64(7, _omitFieldNames ? '' : 'lastUpdateAt')
    ..pPM<WebxdcSyncUpdate>(8, _omitFieldNames ? '' : 'updates',
        subBuilder: WebxdcSyncUpdate.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebxdcSyncInstance clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebxdcSyncInstance copyWith(void Function(WebxdcSyncInstance) updates) =>
      super.copyWith((message) => updates(message as WebxdcSyncInstance))
          as WebxdcSyncInstance;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WebxdcSyncInstance create() => WebxdcSyncInstance._();
  @$core.override
  WebxdcSyncInstance createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WebxdcSyncInstance getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WebxdcSyncInstance>(create);
  static WebxdcSyncInstance? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get instanceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set instanceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInstanceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearInstanceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get appId => $_getSZ(1);
  @$pb.TagNumber(2)
  set appId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAppId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAppId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get version => $_getI64(2);
  @$pb.TagNumber(3)
  set version($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearVersion() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get summary => $_getSZ(3);
  @$pb.TagNumber(4)
  set summary($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSummary() => $_has(3);
  @$pb.TagNumber(4)
  void clearSummary() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get document => $_getSZ(4);
  @$pb.TagNumber(5)
  set document($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasDocument() => $_has(4);
  @$pb.TagNumber(5)
  void clearDocument() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get createdAt => $_getI64(5);
  @$pb.TagNumber(6)
  set createdAt($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasCreatedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearCreatedAt() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get lastUpdateAt => $_getI64(6);
  @$pb.TagNumber(7)
  set lastUpdateAt($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasLastUpdateAt() => $_has(6);
  @$pb.TagNumber(7)
  void clearLastUpdateAt() => $_clearField(7);

  @$pb.TagNumber(8)
  $pb.PbList<WebxdcSyncUpdate> get updates => $_getList(7);
}

class WebxdcSyncUpdate extends $pb.GeneratedMessage {
  factory WebxdcSyncUpdate({
    $core.String? messageId,
    $fixnum.Int64? senderId,
    $core.String? payload,
    $core.String? info,
    $core.String? href,
    $fixnum.Int64? receivedAt,
  }) {
    final result = create();
    if (messageId != null) result.messageId = messageId;
    if (senderId != null) result.senderId = senderId;
    if (payload != null) result.payload = payload;
    if (info != null) result.info = info;
    if (href != null) result.href = href;
    if (receivedAt != null) result.receivedAt = receivedAt;
    return result;
  }

  WebxdcSyncUpdate._();

  factory WebxdcSyncUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WebxdcSyncUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WebxdcSyncUpdate',
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'messageId')
    ..aInt64(2, _omitFieldNames ? '' : 'senderId')
    ..aOS(3, _omitFieldNames ? '' : 'payload')
    ..aOS(4, _omitFieldNames ? '' : 'info')
    ..aOS(5, _omitFieldNames ? '' : 'href')
    ..aInt64(6, _omitFieldNames ? '' : 'receivedAt')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebxdcSyncUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebxdcSyncUpdate copyWith(void Function(WebxdcSyncUpdate) updates) =>
      super.copyWith((message) => updates(message as WebxdcSyncUpdate))
          as WebxdcSyncUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WebxdcSyncUpdate create() => WebxdcSyncUpdate._();
  @$core.override
  WebxdcSyncUpdate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WebxdcSyncUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WebxdcSyncUpdate>(create);
  static WebxdcSyncUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get messageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set messageId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessageId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get senderId => $_getI64(1);
  @$pb.TagNumber(2)
  set senderId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSenderId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSenderId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get payload => $_getSZ(2);
  @$pb.TagNumber(3)
  set payload($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPayload() => $_has(2);
  @$pb.TagNumber(3)
  void clearPayload() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get info => $_getSZ(3);
  @$pb.TagNumber(4)
  set info($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasInfo() => $_has(3);
  @$pb.TagNumber(4)
  void clearInfo() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get href => $_getSZ(4);
  @$pb.TagNumber(5)
  set href($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasHref() => $_has(4);
  @$pb.TagNumber(5)
  void clearHref() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get receivedAt => $_getI64(5);
  @$pb.TagNumber(6)
  set receivedAt($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasReceivedAt() => $_has(5);
  @$pb.TagNumber(6)
  void clearReceivedAt() => $_clearField(6);
}

/// Attached to a message a webxdc app asked the user to send, so the chat can
/// say which app it came from.
///
/// `instance_id` is the app card in the chat the app runs in, which is not
/// necessarily the chat this message was sent to: the user picks the recipient.
/// `app_id` and `version` are carried as well so the receiver can name and
/// picture the app even when it has no instance of its own.
class WebxdcOrigin extends $pb.GeneratedMessage {
  factory WebxdcOrigin({
    $core.String? instanceId,
    $core.String? appId,
    $fixnum.Int64? version,
  }) {
    final result = create();
    if (instanceId != null) result.instanceId = instanceId;
    if (appId != null) result.appId = appId;
    if (version != null) result.version = version;
    return result;
  }

  WebxdcOrigin._();

  factory WebxdcOrigin.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WebxdcOrigin.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WebxdcOrigin',
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'instanceId')
    ..aOS(2, _omitFieldNames ? '' : 'appId')
    ..aInt64(3, _omitFieldNames ? '' : 'version')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebxdcOrigin clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebxdcOrigin copyWith(void Function(WebxdcOrigin) updates) =>
      super.copyWith((message) => updates(message as WebxdcOrigin))
          as WebxdcOrigin;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WebxdcOrigin create() => WebxdcOrigin._();
  @$core.override
  WebxdcOrigin createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WebxdcOrigin getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WebxdcOrigin>(create);
  static WebxdcOrigin? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get instanceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set instanceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInstanceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearInstanceId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get appId => $_getSZ(1);
  @$pb.TagNumber(2)
  set appId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasAppId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAppId() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get version => $_getI64(2);
  @$pb.TagNumber(3)
  set version($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearVersion() => $_clearField(3);
}

/// The app itself is never sent. Peers resolve the id and version against the
/// twonly store and download the bundle from the API server, so a sender can
/// only point at code that has already been published.
class WebxdcApp extends $pb.GeneratedMessage {
  factory WebxdcApp({
    $core.String? appId,
    $fixnum.Int64? version,
  }) {
    final result = create();
    if (appId != null) result.appId = appId;
    if (version != null) result.version = version;
    return result;
  }

  WebxdcApp._();

  factory WebxdcApp.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WebxdcApp.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WebxdcApp',
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'appId')
    ..aInt64(2, _omitFieldNames ? '' : 'version')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebxdcApp clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebxdcApp copyWith(void Function(WebxdcApp) updates) =>
      super.copyWith((message) => updates(message as WebxdcApp)) as WebxdcApp;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WebxdcApp create() => WebxdcApp._();
  @$core.override
  WebxdcApp createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WebxdcApp getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<WebxdcApp>(create);
  static WebxdcApp? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get appId => $_getSZ(0);
  @$pb.TagNumber(1)
  set appId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAppId() => $_has(0);
  @$pb.TagNumber(1)
  void clearAppId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get version => $_getI64(1);
  @$pb.TagNumber(2)
  set version($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => $_clearField(2);
}

class WebxdcUpdate extends $pb.GeneratedMessage {
  factory WebxdcUpdate({
    $core.String? instanceId,
    $core.String? payload,
    $core.String? info,
    $core.String? href,
    $core.String? summary,
    $core.String? document,
    $core.String? notify,
  }) {
    final result = create();
    if (instanceId != null) result.instanceId = instanceId;
    if (payload != null) result.payload = payload;
    if (info != null) result.info = info;
    if (href != null) result.href = href;
    if (summary != null) result.summary = summary;
    if (document != null) result.document = document;
    if (notify != null) result.notify = notify;
    return result;
  }

  WebxdcUpdate._();

  factory WebxdcUpdate.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory WebxdcUpdate.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'WebxdcUpdate',
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'instanceId')
    ..aOS(2, _omitFieldNames ? '' : 'payload')
    ..aOS(3, _omitFieldNames ? '' : 'info')
    ..aOS(4, _omitFieldNames ? '' : 'href')
    ..aOS(5, _omitFieldNames ? '' : 'summary')
    ..aOS(6, _omitFieldNames ? '' : 'document')
    ..aOS(7, _omitFieldNames ? '' : 'notify')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebxdcUpdate clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  WebxdcUpdate copyWith(void Function(WebxdcUpdate) updates) =>
      super.copyWith((message) => updates(message as WebxdcUpdate))
          as WebxdcUpdate;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static WebxdcUpdate create() => WebxdcUpdate._();
  @$core.override
  WebxdcUpdate createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static WebxdcUpdate getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<WebxdcUpdate>(create);
  static WebxdcUpdate? _defaultInstance;

  /// The message id of the app card this update belongs to.
  @$pb.TagNumber(1)
  $core.String get instanceId => $_getSZ(0);
  @$pb.TagNumber(1)
  set instanceId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasInstanceId() => $_has(0);
  @$pb.TagNumber(1)
  void clearInstanceId() => $_clearField(1);

  /// JSON, as the app produced it. Never parsed by twonly.
  @$pb.TagNumber(2)
  $core.String get payload => $_getSZ(1);
  @$pb.TagNumber(2)
  set payload($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPayload() => $_has(1);
  @$pb.TagNumber(2)
  void clearPayload() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get info => $_getSZ(2);
  @$pb.TagNumber(3)
  set info($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasInfo() => $_has(2);
  @$pb.TagNumber(3)
  void clearInfo() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get href => $_getSZ(3);
  @$pb.TagNumber(4)
  set href($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasHref() => $_has(3);
  @$pb.TagNumber(4)
  void clearHref() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.String get summary => $_getSZ(4);
  @$pb.TagNumber(5)
  set summary($core.String value) => $_setString(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSummary() => $_has(4);
  @$pb.TagNumber(5)
  void clearSummary() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get document => $_getSZ(5);
  @$pb.TagNumber(6)
  set document($core.String value) => $_setString(5, value);
  @$pb.TagNumber(6)
  $core.bool hasDocument() => $_has(5);
  @$pb.TagNumber(6)
  void clearDocument() => $_clearField(6);

  /// JSON map of app-scoped member addresses to notification text.
  /// Absent preserves legacy broadcast; an empty map notifies nobody.
  @$pb.TagNumber(7)
  $core.String get notify => $_getSZ(6);
  @$pb.TagNumber(7)
  set notify($core.String value) => $_setString(6, value);
  @$pb.TagNumber(7)
  $core.bool hasNotify() => $_has(6);
  @$pb.TagNumber(7)
  void clearNotify() => $_clearField(7);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
