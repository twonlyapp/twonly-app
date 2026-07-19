// This is a generated file - do not edit.
//
// Generated from backup.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class TwonlySafeBackupContent extends $pb.GeneratedMessage {
  factory TwonlySafeBackupContent({
    $core.String? secureStorageJson,
    $core.List<$core.int>? twonlyDatabase,
  }) {
    final result = create();
    if (secureStorageJson != null) result.secureStorageJson = secureStorageJson;
    if (twonlyDatabase != null) result.twonlyDatabase = twonlyDatabase;
    return result;
  }

  TwonlySafeBackupContent._();

  factory TwonlySafeBackupContent.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TwonlySafeBackupContent.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TwonlySafeBackupContent',
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'secureStorageJson')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'twonlyDatabase', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TwonlySafeBackupContent clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TwonlySafeBackupContent copyWith(
          void Function(TwonlySafeBackupContent) updates) =>
      super.copyWith((message) => updates(message as TwonlySafeBackupContent))
          as TwonlySafeBackupContent;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TwonlySafeBackupContent create() => TwonlySafeBackupContent._();
  @$core.override
  TwonlySafeBackupContent createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TwonlySafeBackupContent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TwonlySafeBackupContent>(create);
  static TwonlySafeBackupContent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get secureStorageJson => $_getSZ(0);
  @$pb.TagNumber(1)
  set secureStorageJson($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSecureStorageJson() => $_has(0);
  @$pb.TagNumber(1)
  void clearSecureStorageJson() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get twonlyDatabase => $_getN(1);
  @$pb.TagNumber(2)
  set twonlyDatabase($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasTwonlyDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearTwonlyDatabase() => $_clearField(2);
}

class TwonlySafeBackupEncrypted extends $pb.GeneratedMessage {
  factory TwonlySafeBackupEncrypted({
    $core.List<$core.int>? mac,
    $core.List<$core.int>? nonce,
    $core.List<$core.int>? cipherText,
  }) {
    final result = create();
    if (mac != null) result.mac = mac;
    if (nonce != null) result.nonce = nonce;
    if (cipherText != null) result.cipherText = cipherText;
    return result;
  }

  TwonlySafeBackupEncrypted._();

  factory TwonlySafeBackupEncrypted.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TwonlySafeBackupEncrypted.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TwonlySafeBackupEncrypted',
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'mac', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'nonce', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'cipherText', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TwonlySafeBackupEncrypted clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TwonlySafeBackupEncrypted copyWith(
          void Function(TwonlySafeBackupEncrypted) updates) =>
      super.copyWith((message) => updates(message as TwonlySafeBackupEncrypted))
          as TwonlySafeBackupEncrypted;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TwonlySafeBackupEncrypted create() => TwonlySafeBackupEncrypted._();
  @$core.override
  TwonlySafeBackupEncrypted createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TwonlySafeBackupEncrypted getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TwonlySafeBackupEncrypted>(create);
  static TwonlySafeBackupEncrypted? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get mac => $_getN(0);
  @$pb.TagNumber(1)
  set mac($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMac() => $_has(0);
  @$pb.TagNumber(1)
  void clearMac() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get nonce => $_getN(1);
  @$pb.TagNumber(2)
  set nonce($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasNonce() => $_has(1);
  @$pb.TagNumber(2)
  void clearNonce() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get cipherText => $_getN(2);
  @$pb.TagNumber(3)
  set cipherText($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCipherText() => $_has(2);
  @$pb.TagNumber(3)
  void clearCipherText() => $_clearField(3);
}

class CloudMediaBackupEncrypted extends $pb.GeneratedMessage {
  factory CloudMediaBackupEncrypted({
    $core.String? addition,
    $core.List<$core.int>? encryptedMediaKey,
    $core.List<$core.int>? mediaNonce,
    $core.List<$core.int>? mediaCiphertext,
  }) {
    final result = create();
    if (addition != null) result.addition = addition;
    if (encryptedMediaKey != null) result.encryptedMediaKey = encryptedMediaKey;
    if (mediaNonce != null) result.mediaNonce = mediaNonce;
    if (mediaCiphertext != null) result.mediaCiphertext = mediaCiphertext;
    return result;
  }

  CloudMediaBackupEncrypted._();

  factory CloudMediaBackupEncrypted.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory CloudMediaBackupEncrypted.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'CloudMediaBackupEncrypted',
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'addition')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'encryptedMediaKey', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'mediaNonce', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'mediaCiphertext', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CloudMediaBackupEncrypted clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  CloudMediaBackupEncrypted copyWith(
          void Function(CloudMediaBackupEncrypted) updates) =>
      super.copyWith((message) => updates(message as CloudMediaBackupEncrypted))
          as CloudMediaBackupEncrypted;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static CloudMediaBackupEncrypted create() => CloudMediaBackupEncrypted._();
  @$core.override
  CloudMediaBackupEncrypted createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static CloudMediaBackupEncrypted getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<CloudMediaBackupEncrypted>(create);
  static CloudMediaBackupEncrypted? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get addition => $_getSZ(0);
  @$pb.TagNumber(1)
  set addition($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAddition() => $_has(0);
  @$pb.TagNumber(1)
  void clearAddition() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get encryptedMediaKey => $_getN(1);
  @$pb.TagNumber(2)
  set encryptedMediaKey($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEncryptedMediaKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearEncryptedMediaKey() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get mediaNonce => $_getN(2);
  @$pb.TagNumber(3)
  set mediaNonce($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMediaNonce() => $_has(2);
  @$pb.TagNumber(3)
  void clearMediaNonce() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get mediaCiphertext => $_getN(3);
  @$pb.TagNumber(4)
  set mediaCiphertext($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMediaCiphertext() => $_has(3);
  @$pb.TagNumber(4)
  void clearMediaCiphertext() => $_clearField(4);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
