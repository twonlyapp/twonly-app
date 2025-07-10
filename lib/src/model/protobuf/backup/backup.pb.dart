//
//  Generated code. Do not modify.
//  source: backup.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class TwonlySafeBackupContent extends $pb.GeneratedMessage {
  factory TwonlySafeBackupContent({
    $core.String? secureStorageJson,
    $core.List<$core.int>? twonlyDatabase,
  }) {
    final $result = create();
    if (secureStorageJson != null) {
      $result.secureStorageJson = secureStorageJson;
    }
    if (twonlyDatabase != null) {
      $result.twonlyDatabase = twonlyDatabase;
    }
    return $result;
  }
  TwonlySafeBackupContent._() : super();
  factory TwonlySafeBackupContent.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory TwonlySafeBackupContent.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TwonlySafeBackupContent',
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'secureStorageJson',
        protoName: 'secureStorageJson')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'twonlyDatabase', $pb.PbFieldType.OY,
        protoName: 'twonlyDatabase')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  TwonlySafeBackupContent clone() =>
      TwonlySafeBackupContent()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  TwonlySafeBackupContent copyWith(
          void Function(TwonlySafeBackupContent) updates) =>
      super.copyWith((message) => updates(message as TwonlySafeBackupContent))
          as TwonlySafeBackupContent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TwonlySafeBackupContent create() => TwonlySafeBackupContent._();
  TwonlySafeBackupContent createEmptyInstance() => create();
  static $pb.PbList<TwonlySafeBackupContent> createRepeated() =>
      $pb.PbList<TwonlySafeBackupContent>();
  @$core.pragma('dart2js:noInline')
  static TwonlySafeBackupContent getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TwonlySafeBackupContent>(create);
  static TwonlySafeBackupContent? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get secureStorageJson => $_getSZ(0);
  @$pb.TagNumber(1)
  set secureStorageJson($core.String v) {
    $_setString(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasSecureStorageJson() => $_has(0);
  @$pb.TagNumber(1)
  void clearSecureStorageJson() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get twonlyDatabase => $_getN(1);
  @$pb.TagNumber(2)
  set twonlyDatabase($core.List<$core.int> v) {
    $_setBytes(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasTwonlyDatabase() => $_has(1);
  @$pb.TagNumber(2)
  void clearTwonlyDatabase() => clearField(2);
}

class TwonlySafeBackupEncrypted extends $pb.GeneratedMessage {
  factory TwonlySafeBackupEncrypted({
    $core.List<$core.int>? mac,
    $core.List<$core.int>? nonce,
    $core.List<$core.int>? cipherText,
  }) {
    final $result = create();
    if (mac != null) {
      $result.mac = mac;
    }
    if (nonce != null) {
      $result.nonce = nonce;
    }
    if (cipherText != null) {
      $result.cipherText = cipherText;
    }
    return $result;
  }
  TwonlySafeBackupEncrypted._() : super();
  factory TwonlySafeBackupEncrypted.fromBuffer($core.List<$core.int> i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(i, r);
  factory TwonlySafeBackupEncrypted.fromJson($core.String i,
          [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TwonlySafeBackupEncrypted',
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'mac', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'nonce', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'cipherText', $pb.PbFieldType.OY,
        protoName: 'cipherText')
    ..hasRequiredFields = false;

  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
      'Will be removed in next major version')
  TwonlySafeBackupEncrypted clone() =>
      TwonlySafeBackupEncrypted()..mergeFromMessage(this);
  @$core.Deprecated('Using this can add significant overhead to your binary. '
      'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
      'Will be removed in next major version')
  TwonlySafeBackupEncrypted copyWith(
          void Function(TwonlySafeBackupEncrypted) updates) =>
      super.copyWith((message) => updates(message as TwonlySafeBackupEncrypted))
          as TwonlySafeBackupEncrypted;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TwonlySafeBackupEncrypted create() => TwonlySafeBackupEncrypted._();
  TwonlySafeBackupEncrypted createEmptyInstance() => create();
  static $pb.PbList<TwonlySafeBackupEncrypted> createRepeated() =>
      $pb.PbList<TwonlySafeBackupEncrypted>();
  @$core.pragma('dart2js:noInline')
  static TwonlySafeBackupEncrypted getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TwonlySafeBackupEncrypted>(create);
  static TwonlySafeBackupEncrypted? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get mac => $_getN(0);
  @$pb.TagNumber(1)
  set mac($core.List<$core.int> v) {
    $_setBytes(0, v);
  }

  @$pb.TagNumber(1)
  $core.bool hasMac() => $_has(0);
  @$pb.TagNumber(1)
  void clearMac() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get nonce => $_getN(1);
  @$pb.TagNumber(2)
  set nonce($core.List<$core.int> v) {
    $_setBytes(1, v);
  }

  @$pb.TagNumber(2)
  $core.bool hasNonce() => $_has(1);
  @$pb.TagNumber(2)
  void clearNonce() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get cipherText => $_getN(2);
  @$pb.TagNumber(3)
  set cipherText($core.List<$core.int> v) {
    $_setBytes(2, v);
  }

  @$pb.TagNumber(3)
  $core.bool hasCipherText() => $_has(2);
  @$pb.TagNumber(3)
  void clearCipherText() => clearField(3);
}

const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
