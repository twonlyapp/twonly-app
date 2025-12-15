// This is a generated file - do not edit.
//
// Generated from push_notification.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'push_notification.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'push_notification.pbenum.dart';

class EncryptedPushNotification extends $pb.GeneratedMessage {
  factory EncryptedPushNotification({
    $fixnum.Int64? keyId,
    $core.List<$core.int>? nonce,
    $core.List<$core.int>? ciphertext,
    $core.List<$core.int>? mac,
  }) {
    final result = create();
    if (keyId != null) result.keyId = keyId;
    if (nonce != null) result.nonce = nonce;
    if (ciphertext != null) result.ciphertext = ciphertext;
    if (mac != null) result.mac = mac;
    return result;
  }

  EncryptedPushNotification._();

  factory EncryptedPushNotification.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EncryptedPushNotification.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EncryptedPushNotification',
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'keyId', protoName: 'keyId')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'nonce', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'ciphertext', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'mac', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EncryptedPushNotification clone() =>
      EncryptedPushNotification()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EncryptedPushNotification copyWith(
          void Function(EncryptedPushNotification) updates) =>
      super.copyWith((message) => updates(message as EncryptedPushNotification))
          as EncryptedPushNotification;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EncryptedPushNotification create() => EncryptedPushNotification._();
  @$core.override
  EncryptedPushNotification createEmptyInstance() => create();
  static $pb.PbList<EncryptedPushNotification> createRepeated() =>
      $pb.PbList<EncryptedPushNotification>();
  @$core.pragma('dart2js:noInline')
  static EncryptedPushNotification getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EncryptedPushNotification>(create);
  static EncryptedPushNotification? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get keyId => $_getI64(0);
  @$pb.TagNumber(1)
  set keyId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasKeyId() => $_has(0);
  @$pb.TagNumber(1)
  void clearKeyId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get nonce => $_getN(1);
  @$pb.TagNumber(2)
  set nonce($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNonce() => $_has(1);
  @$pb.TagNumber(2)
  void clearNonce() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get ciphertext => $_getN(2);
  @$pb.TagNumber(3)
  set ciphertext($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCiphertext() => $_has(2);
  @$pb.TagNumber(3)
  void clearCiphertext() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get mac => $_getN(3);
  @$pb.TagNumber(4)
  set mac($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMac() => $_has(3);
  @$pb.TagNumber(4)
  void clearMac() => $_clearField(4);
}

class PushNotification extends $pb.GeneratedMessage {
  factory PushNotification({
    PushKind? kind,
    $core.String? messageId,
    $core.String? additionalContent,
  }) {
    final result = create();
    if (kind != null) result.kind = kind;
    if (messageId != null) result.messageId = messageId;
    if (additionalContent != null) result.additionalContent = additionalContent;
    return result;
  }

  PushNotification._();

  factory PushNotification.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PushNotification.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PushNotification',
      createEmptyInstance: create)
    ..e<PushKind>(1, _omitFieldNames ? '' : 'kind', $pb.PbFieldType.OE,
        defaultOrMaker: PushKind.reaction,
        valueOf: PushKind.valueOf,
        enumValues: PushKind.values)
    ..aOS(2, _omitFieldNames ? '' : 'messageId', protoName: 'messageId')
    ..aOS(3, _omitFieldNames ? '' : 'additionalContent',
        protoName: 'additionalContent')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PushNotification clone() => PushNotification()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PushNotification copyWith(void Function(PushNotification) updates) =>
      super.copyWith((message) => updates(message as PushNotification))
          as PushNotification;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PushNotification create() => PushNotification._();
  @$core.override
  PushNotification createEmptyInstance() => create();
  static $pb.PbList<PushNotification> createRepeated() =>
      $pb.PbList<PushNotification>();
  @$core.pragma('dart2js:noInline')
  static PushNotification getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PushNotification>(create);
  static PushNotification? _defaultInstance;

  @$pb.TagNumber(1)
  PushKind get kind => $_getN(0);
  @$pb.TagNumber(1)
  set kind(PushKind value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasKind() => $_has(0);
  @$pb.TagNumber(1)
  void clearKind() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get messageId => $_getSZ(1);
  @$pb.TagNumber(2)
  set messageId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasMessageId() => $_has(1);
  @$pb.TagNumber(2)
  void clearMessageId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get additionalContent => $_getSZ(2);
  @$pb.TagNumber(3)
  set additionalContent($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAdditionalContent() => $_has(2);
  @$pb.TagNumber(3)
  void clearAdditionalContent() => $_clearField(3);
}

class PushUsers extends $pb.GeneratedMessage {
  factory PushUsers({
    $core.Iterable<PushUser>? users,
  }) {
    final result = create();
    if (users != null) result.users.addAll(users);
    return result;
  }

  PushUsers._();

  factory PushUsers.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PushUsers.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PushUsers',
      createEmptyInstance: create)
    ..pc<PushUser>(1, _omitFieldNames ? '' : 'users', $pb.PbFieldType.PM,
        subBuilder: PushUser.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PushUsers clone() => PushUsers()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PushUsers copyWith(void Function(PushUsers) updates) =>
      super.copyWith((message) => updates(message as PushUsers)) as PushUsers;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PushUsers create() => PushUsers._();
  @$core.override
  PushUsers createEmptyInstance() => create();
  static $pb.PbList<PushUsers> createRepeated() => $pb.PbList<PushUsers>();
  @$core.pragma('dart2js:noInline')
  static PushUsers getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PushUsers>(create);
  static PushUsers? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<PushUser> get users => $_getList(0);
}

class PushUser extends $pb.GeneratedMessage {
  factory PushUser({
    $fixnum.Int64? userId,
    $core.String? displayName,
    $core.bool? blocked,
    $core.String? lastMessageId,
    $core.Iterable<PushKey>? pushKeys,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    if (displayName != null) result.displayName = displayName;
    if (blocked != null) result.blocked = blocked;
    if (lastMessageId != null) result.lastMessageId = lastMessageId;
    if (pushKeys != null) result.pushKeys.addAll(pushKeys);
    return result;
  }

  PushUser._();

  factory PushUser.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PushUser.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PushUser',
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'userId', protoName: 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'displayName', protoName: 'displayName')
    ..aOB(3, _omitFieldNames ? '' : 'blocked')
    ..aOS(4, _omitFieldNames ? '' : 'lastMessageId', protoName: 'lastMessageId')
    ..pc<PushKey>(5, _omitFieldNames ? '' : 'pushKeys', $pb.PbFieldType.PM,
        protoName: 'pushKeys', subBuilder: PushKey.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PushUser clone() => PushUser()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PushUser copyWith(void Function(PushUser) updates) =>
      super.copyWith((message) => updates(message as PushUser)) as PushUser;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PushUser create() => PushUser._();
  @$core.override
  PushUser createEmptyInstance() => create();
  static $pb.PbList<PushUser> createRepeated() => $pb.PbList<PushUser>();
  @$core.pragma('dart2js:noInline')
  static PushUser getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PushUser>(create);
  static PushUser? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get userId => $_getI64(0);
  @$pb.TagNumber(1)
  set userId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get displayName => $_getSZ(1);
  @$pb.TagNumber(2)
  set displayName($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDisplayName() => $_has(1);
  @$pb.TagNumber(2)
  void clearDisplayName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get blocked => $_getBF(2);
  @$pb.TagNumber(3)
  set blocked($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBlocked() => $_has(2);
  @$pb.TagNumber(3)
  void clearBlocked() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.String get lastMessageId => $_getSZ(3);
  @$pb.TagNumber(4)
  set lastMessageId($core.String value) => $_setString(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLastMessageId() => $_has(3);
  @$pb.TagNumber(4)
  void clearLastMessageId() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<PushKey> get pushKeys => $_getList(4);
}

class PushKey extends $pb.GeneratedMessage {
  factory PushKey({
    $fixnum.Int64? id,
    $core.List<$core.int>? key,
    $fixnum.Int64? createdAtUnixTimestamp,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (key != null) result.key = key;
    if (createdAtUnixTimestamp != null)
      result.createdAtUnixTimestamp = createdAtUnixTimestamp;
    return result;
  }

  PushKey._();

  factory PushKey.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PushKey.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PushKey',
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'key', $pb.PbFieldType.OY)
    ..aInt64(3, _omitFieldNames ? '' : 'createdAtUnixTimestamp',
        protoName: 'createdAtUnixTimestamp')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PushKey clone() => PushKey()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PushKey copyWith(void Function(PushKey) updates) =>
      super.copyWith((message) => updates(message as PushKey)) as PushKey;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PushKey create() => PushKey._();
  @$core.override
  PushKey createEmptyInstance() => create();
  static $pb.PbList<PushKey> createRepeated() => $pb.PbList<PushKey>();
  @$core.pragma('dart2js:noInline')
  static PushKey getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PushKey>(create);
  static PushKey? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get key => $_getN(1);
  @$pb.TagNumber(2)
  set key($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearKey() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get createdAtUnixTimestamp => $_getI64(2);
  @$pb.TagNumber(3)
  set createdAtUnixTimestamp($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCreatedAtUnixTimestamp() => $_has(2);
  @$pb.TagNumber(3)
  void clearCreatedAtUnixTimestamp() => $_clearField(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
