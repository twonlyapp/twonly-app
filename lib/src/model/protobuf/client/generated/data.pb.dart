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
  }) {
    final result = create();
    if (instanceId != null) result.instanceId = instanceId;
    if (payload != null) result.payload = payload;
    if (info != null) result.info = info;
    if (href != null) result.href = href;
    if (summary != null) result.summary = summary;
    if (document != null) result.document = document;
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
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
