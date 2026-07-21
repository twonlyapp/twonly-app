// This is a generated file - do not edit.
//
// Generated from passwordless_recovery.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

/// Used as envelope for TrustedFriendShare and RecoveryData.
/// Encrypted using XChaCha20-Poly1305.
class EncryptedEnvelope extends $pb.GeneratedMessage {
  factory EncryptedEnvelope({
    $core.List<$core.int>? encryptedData,
    $core.List<$core.int>? iv,
    $core.List<$core.int>? mac,
  }) {
    final result = create();
    if (encryptedData != null) result.encryptedData = encryptedData;
    if (iv != null) result.iv = iv;
    if (mac != null) result.mac = mac;
    return result;
  }

  EncryptedEnvelope._();

  factory EncryptedEnvelope.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory EncryptedEnvelope.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'EncryptedEnvelope',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'passwordless_recovery'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'encryptedData', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'iv', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'mac', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EncryptedEnvelope clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  EncryptedEnvelope copyWith(void Function(EncryptedEnvelope) updates) =>
      super.copyWith((message) => updates(message as EncryptedEnvelope))
          as EncryptedEnvelope;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EncryptedEnvelope create() => EncryptedEnvelope._();
  @$core.override
  EncryptedEnvelope createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static EncryptedEnvelope getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<EncryptedEnvelope>(create);
  static EncryptedEnvelope? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get encryptedData => $_getN(0);
  @$pb.TagNumber(1)
  set encryptedData($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEncryptedData() => $_has(0);
  @$pb.TagNumber(1)
  void clearEncryptedData() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get iv => $_getN(1);
  @$pb.TagNumber(2)
  set iv($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasIv() => $_has(1);
  @$pb.TagNumber(2)
  void clearIv() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get mac => $_getN(2);
  @$pb.TagNumber(3)
  set mac($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasMac() => $_has(2);
  @$pb.TagNumber(3)
  void clearMac() => $_clearField(3);
}

class TrustedFriendShare_User extends $pb.GeneratedMessage {
  factory TrustedFriendShare_User({
    $fixnum.Int64? userId,
    $core.String? displayName,
    $core.List<$core.int>? avatar,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    if (displayName != null) result.displayName = displayName;
    if (avatar != null) result.avatar = avatar;
    return result;
  }

  TrustedFriendShare_User._();

  factory TrustedFriendShare_User.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TrustedFriendShare_User.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TrustedFriendShare.User',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'passwordless_recovery'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'displayName')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'avatar', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TrustedFriendShare_User clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TrustedFriendShare_User copyWith(
          void Function(TrustedFriendShare_User) updates) =>
      super.copyWith((message) => updates(message as TrustedFriendShare_User))
          as TrustedFriendShare_User;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TrustedFriendShare_User create() => TrustedFriendShare_User._();
  @$core.override
  TrustedFriendShare_User createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TrustedFriendShare_User getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TrustedFriendShare_User>(create);
  static TrustedFriendShare_User? _defaultInstance;

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
  $core.List<$core.int> get avatar => $_getN(2);
  @$pb.TagNumber(3)
  set avatar($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAvatar() => $_has(2);
  @$pb.TagNumber(3)
  void clearAvatar() => $_clearField(3);
}

/// Sent from the trusted friend to the recovering user via the server.
/// This is symmetrically encrypted using the encryption key received from the recovery link.
class TrustedFriendShare extends $pb.GeneratedMessage {
  factory TrustedFriendShare({
    TrustedFriendShare_User? trustedFriend,
    TrustedFriendShare_User? shareUser,
    $core.int? threshold,
    $core.List<$core.int>? sharedSecretData,
  }) {
    final result = create();
    if (trustedFriend != null) result.trustedFriend = trustedFriend;
    if (shareUser != null) result.shareUser = shareUser;
    if (threshold != null) result.threshold = threshold;
    if (sharedSecretData != null) result.sharedSecretData = sharedSecretData;
    return result;
  }

  TrustedFriendShare._();

  factory TrustedFriendShare.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TrustedFriendShare.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TrustedFriendShare',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'passwordless_recovery'),
      createEmptyInstance: create)
    ..aOM<TrustedFriendShare_User>(1, _omitFieldNames ? '' : 'trustedFriend',
        subBuilder: TrustedFriendShare_User.create)
    ..aOM<TrustedFriendShare_User>(2, _omitFieldNames ? '' : 'shareUser',
        subBuilder: TrustedFriendShare_User.create)
    ..aI(3, _omitFieldNames ? '' : 'threshold')
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'sharedSecretData', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TrustedFriendShare clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TrustedFriendShare copyWith(void Function(TrustedFriendShare) updates) =>
      super.copyWith((message) => updates(message as TrustedFriendShare))
          as TrustedFriendShare;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TrustedFriendShare create() => TrustedFriendShare._();
  @$core.override
  TrustedFriendShare createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TrustedFriendShare getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TrustedFriendShare>(create);
  static TrustedFriendShare? _defaultInstance;

  /// This allows to display to the recovering user which trusted friend has sent their recovery data.
  @$pb.TagNumber(1)
  TrustedFriendShare_User get trustedFriend => $_getN(0);
  @$pb.TagNumber(1)
  set trustedFriend(TrustedFriendShare_User value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasTrustedFriend() => $_has(0);
  @$pb.TagNumber(1)
  void clearTrustedFriend() => $_clearField(1);
  @$pb.TagNumber(1)
  TrustedFriendShare_User ensureTrustedFriend() => $_ensure(0);

  /// This allows to display the userdata, showing that the trusted friend is recovering the correct person.
  @$pb.TagNumber(2)
  TrustedFriendShare_User get shareUser => $_getN(1);
  @$pb.TagNumber(2)
  set shareUser(TrustedFriendShare_User value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasShareUser() => $_has(1);
  @$pb.TagNumber(2)
  void clearShareUser() => $_clearField(2);
  @$pb.TagNumber(2)
  TrustedFriendShare_User ensureShareUser() => $_ensure(1);

  /// The minimum threshold required to reconstruct the shares.
  @$pb.TagNumber(3)
  $core.int get threshold => $_getIZ(2);
  @$pb.TagNumber(3)
  set threshold($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasThreshold() => $_has(2);
  @$pb.TagNumber(3)
  void clearThreshold() => $_clearField(3);

  /// The actual share which will be used to reconstruct SharedSecretData.
  @$pb.TagNumber(4)
  $core.List<$core.int> get sharedSecretData => $_getN(3);
  @$pb.TagNumber(4)
  set sharedSecretData($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSharedSecretData() => $_has(3);
  @$pb.TagNumber(4)
  void clearSharedSecretData() => $_clearField(4);
}

/// The user identity keys. Can be used to restore the data backup.
class RecoveryData extends $pb.GeneratedMessage {
  factory RecoveryData({
    $fixnum.Int64? userId,
    $core.List<$core.int>? keyManager,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    if (keyManager != null) result.keyManager = keyManager;
    return result;
  }

  RecoveryData._();

  factory RecoveryData.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory RecoveryData.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'RecoveryData',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'passwordless_recovery'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'userId')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'keyManager', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecoveryData clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  RecoveryData copyWith(void Function(RecoveryData) updates) =>
      super.copyWith((message) => updates(message as RecoveryData))
          as RecoveryData;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static RecoveryData create() => RecoveryData._();
  @$core.override
  RecoveryData createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static RecoveryData getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<RecoveryData>(create);
  static RecoveryData? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get userId => $_getI64(0);
  @$pb.TagNumber(1)
  set userId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(3)
  $core.List<$core.int> get keyManager => $_getN(1);
  @$pb.TagNumber(3)
  set keyManager($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(3)
  $core.bool hasKeyManager() => $_has(1);
  @$pb.TagNumber(3)
  void clearKeyManager() => $_clearField(3);
}

/// After receiving threshold shares, this is reconstructed by the recovering user.
class SharedSecretData extends $pb.GeneratedMessage {
  factory SharedSecretData({
    $core.List<$core.int>? recoveryData,
    $core.List<$core.int>? serverKeyProtection,
    $core.List<$core.int>? pinUnlockToken,
    $core.String? emailHint,
  }) {
    final result = create();
    if (recoveryData != null) result.recoveryData = recoveryData;
    if (serverKeyProtection != null)
      result.serverKeyProtection = serverKeyProtection;
    if (pinUnlockToken != null) result.pinUnlockToken = pinUnlockToken;
    if (emailHint != null) result.emailHint = emailHint;
    return result;
  }

  SharedSecretData._();

  factory SharedSecretData.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory SharedSecretData.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'SharedSecretData',
      package: const $pb.PackageName(
          _omitMessageNames ? '' : 'passwordless_recovery'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'recoveryData', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'serverKeyProtection', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'pinUnlockToken', $pb.PbFieldType.OY)
    ..aOS(6, _omitFieldNames ? '' : 'emailHint')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SharedSecretData clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  SharedSecretData copyWith(void Function(SharedSecretData) updates) =>
      super.copyWith((message) => updates(message as SharedSecretData))
          as SharedSecretData;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static SharedSecretData create() => SharedSecretData._();
  @$core.override
  SharedSecretData createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static SharedSecretData getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<SharedSecretData>(create);
  static SharedSecretData? _defaultInstance;

  /// The recovery data (RecoveryData). It is encrypted with the server_key in case a second factor was chosen.
  @$pb.TagNumber(1)
  $core.List<$core.int> get recoveryData => $_getN(0);
  @$pb.TagNumber(1)
  set recoveryData($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasRecoveryData() => $_has(0);
  @$pb.TagNumber(1)
  void clearRecoveryData() => $_clearField(1);

  /// Combined with the user's PIN/Email via HKDF to derive the key to decrypt the encrypted server_key.
  /// The server NEVER sees this value.
  @$pb.TagNumber(3)
  $core.List<$core.int> get serverKeyProtection => $_getN(1);
  @$pb.TagNumber(3)
  set serverKeyProtection($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(3)
  $core.bool hasServerKeyProtection() => $_has(1);
  @$pb.TagNumber(3)
  void clearServerKeyProtection() => $_clearField(3);

  /// Used to authenticate with the server to fetch the encrypted server_key.
  @$pb.TagNumber(5)
  $core.List<$core.int> get pinUnlockToken => $_getN(2);
  @$pb.TagNumber(5)
  set pinUnlockToken($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(5)
  $core.bool hasPinUnlockToken() => $_has(2);
  @$pb.TagNumber(5)
  void clearPinUnlockToken() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.String get emailHint => $_getSZ(3);
  @$pb.TagNumber(6)
  set emailHint($core.String value) => $_setString(3, value);
  @$pb.TagNumber(6)
  $core.bool hasEmailHint() => $_has(3);
  @$pb.TagNumber(6)
  void clearEmailHint() => $_clearField(6);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
