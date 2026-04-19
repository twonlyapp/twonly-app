// This is a generated file - do not edit.
//
// Generated from types.proto.

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

class UserDiscoveryVersion extends $pb.GeneratedMessage {
  factory UserDiscoveryVersion({
    $core.int? announcement,
    $core.int? promotion,
  }) {
    final result = create();
    if (announcement != null) result.announcement = announcement;
    if (promotion != null) result.promotion = promotion;
    return result;
  }

  UserDiscoveryVersion._();

  factory UserDiscoveryVersion.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UserDiscoveryVersion.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UserDiscoveryVersion',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'user_discovery'),
      createEmptyInstance: create)
    ..a<$core.int>(
        1, _omitFieldNames ? '' : 'announcement', $pb.PbFieldType.OU3)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'promotion', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserDiscoveryVersion clone() =>
      UserDiscoveryVersion()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserDiscoveryVersion copyWith(void Function(UserDiscoveryVersion) updates) =>
      super.copyWith((message) => updates(message as UserDiscoveryVersion))
          as UserDiscoveryVersion;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UserDiscoveryVersion create() => UserDiscoveryVersion._();
  @$core.override
  UserDiscoveryVersion createEmptyInstance() => create();
  static $pb.PbList<UserDiscoveryVersion> createRepeated() =>
      $pb.PbList<UserDiscoveryVersion>();
  @$core.pragma('dart2js:noInline')
  static UserDiscoveryVersion getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UserDiscoveryVersion>(create);
  static UserDiscoveryVersion? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get announcement => $_getIZ(0);
  @$pb.TagNumber(1)
  set announcement($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasAnnouncement() => $_has(0);
  @$pb.TagNumber(1)
  void clearAnnouncement() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get promotion => $_getIZ(1);
  @$pb.TagNumber(2)
  set promotion($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPromotion() => $_has(1);
  @$pb.TagNumber(2)
  void clearPromotion() => $_clearField(2);
}

class UserDiscoveryMessage_UserDiscoveryAnnouncement
    extends $pb.GeneratedMessage {
  factory UserDiscoveryMessage_UserDiscoveryAnnouncement({
    $fixnum.Int64? publicId,
    $core.int? threshold,
    $core.List<$core.int>? announcementShare,
    $core.Iterable<$core.List<$core.int>>? verificationShares,
  }) {
    final result = create();
    if (publicId != null) result.publicId = publicId;
    if (threshold != null) result.threshold = threshold;
    if (announcementShare != null) result.announcementShare = announcementShare;
    if (verificationShares != null)
      result.verificationShares.addAll(verificationShares);
    return result;
  }

  UserDiscoveryMessage_UserDiscoveryAnnouncement._();

  factory UserDiscoveryMessage_UserDiscoveryAnnouncement.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UserDiscoveryMessage_UserDiscoveryAnnouncement.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UserDiscoveryMessage.UserDiscoveryAnnouncement',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'user_discovery'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'publicId')
    ..a<$core.int>(2, _omitFieldNames ? '' : 'threshold', $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'announcementShare', $pb.PbFieldType.OY)
    ..p<$core.List<$core.int>>(
        6, _omitFieldNames ? '' : 'verificationShares', $pb.PbFieldType.PY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserDiscoveryMessage_UserDiscoveryAnnouncement clone() =>
      UserDiscoveryMessage_UserDiscoveryAnnouncement()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserDiscoveryMessage_UserDiscoveryAnnouncement copyWith(
          void Function(UserDiscoveryMessage_UserDiscoveryAnnouncement)
              updates) =>
      super.copyWith((message) => updates(
              message as UserDiscoveryMessage_UserDiscoveryAnnouncement))
          as UserDiscoveryMessage_UserDiscoveryAnnouncement;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UserDiscoveryMessage_UserDiscoveryAnnouncement create() =>
      UserDiscoveryMessage_UserDiscoveryAnnouncement._();
  @$core.override
  UserDiscoveryMessage_UserDiscoveryAnnouncement createEmptyInstance() =>
      create();
  static $pb.PbList<UserDiscoveryMessage_UserDiscoveryAnnouncement>
      createRepeated() =>
          $pb.PbList<UserDiscoveryMessage_UserDiscoveryAnnouncement>();
  @$core.pragma('dart2js:noInline')
  static UserDiscoveryMessage_UserDiscoveryAnnouncement getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          UserDiscoveryMessage_UserDiscoveryAnnouncement>(create);
  static UserDiscoveryMessage_UserDiscoveryAnnouncement? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get publicId => $_getI64(0);
  @$pb.TagNumber(1)
  set publicId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPublicId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPublicId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.int get threshold => $_getIZ(1);
  @$pb.TagNumber(2)
  set threshold($core.int value) => $_setUnsignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasThreshold() => $_has(1);
  @$pb.TagNumber(2)
  void clearThreshold() => $_clearField(2);

  @$pb.TagNumber(4)
  $core.List<$core.int> get announcementShare => $_getN(2);
  @$pb.TagNumber(4)
  set announcementShare($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(4)
  $core.bool hasAnnouncementShare() => $_has(2);
  @$pb.TagNumber(4)
  void clearAnnouncementShare() => $_clearField(4);

  @$pb.TagNumber(6)
  $pb.PbList<$core.List<$core.int>> get verificationShares => $_getList(3);
}

class UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted_SignedData
    extends $pb.GeneratedMessage {
  factory UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted_SignedData({
    $fixnum.Int64? publicId,
    $fixnum.Int64? userId,
    $core.List<$core.int>? publicKey,
  }) {
    final result = create();
    if (publicId != null) result.publicId = publicId;
    if (userId != null) result.userId = userId;
    if (publicKey != null) result.publicKey = publicKey;
    return result;
  }

  UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted_SignedData._();

  factory UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted_SignedData.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted_SignedData.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'UserDiscoveryMessage.UserDiscoveryPromotion.AnnouncementShareDecrypted.SignedData',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'user_discovery'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'publicId')
    ..aInt64(2, _omitFieldNames ? '' : 'userId')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'publicKey', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted_SignedData
      clone() =>
          UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted_SignedData()
            ..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted_SignedData copyWith(
          void Function(
                  UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted_SignedData)
              updates) =>
      super.copyWith((message) => updates(message
              as UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted_SignedData))
          as UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted_SignedData;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted_SignedData
      create() =>
          UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted_SignedData
              ._();
  @$core.override
  UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted_SignedData
      createEmptyInstance() => create();
  static $pb.PbList<
          UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted_SignedData>
      createRepeated() => $pb.PbList<
          UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted_SignedData>();
  @$core.pragma('dart2js:noInline')
  static UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted_SignedData
      getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
              UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted_SignedData>(
          create);
  static UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted_SignedData?
      _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get publicId => $_getI64(0);
  @$pb.TagNumber(1)
  set publicId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPublicId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPublicId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get userId => $_getI64(1);
  @$pb.TagNumber(2)
  set userId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get publicKey => $_getN(2);
  @$pb.TagNumber(3)
  set publicKey($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPublicKey() => $_has(2);
  @$pb.TagNumber(3)
  void clearPublicKey() => $_clearField(3);
}

class UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted
    extends $pb.GeneratedMessage {
  factory UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted({
    UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted_SignedData?
        signedData,
    $core.List<$core.int>? signature,
  }) {
    final result = create();
    if (signedData != null) result.signedData = signedData;
    if (signature != null) result.signature = signature;
    return result;
  }

  UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted._();

  factory UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames
          ? ''
          : 'UserDiscoveryMessage.UserDiscoveryPromotion.AnnouncementShareDecrypted',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'user_discovery'),
      createEmptyInstance: create)
    ..aOM<UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted_SignedData>(
        1, _omitFieldNames ? '' : 'signedData',
        subBuilder:
            UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted_SignedData
                .create)
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'signature', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted
      clone() =>
          UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted()
            ..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted copyWith(
          void Function(
                  UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted)
              updates) =>
      super.copyWith((message) => updates(message
              as UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted))
          as UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted
      create() =>
          UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted
              ._();
  @$core.override
  UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted
      createEmptyInstance() => create();
  static $pb.PbList<
          UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted>
      createRepeated() => $pb.PbList<
          UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted>();
  @$core.pragma('dart2js:noInline')
  static UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted
      getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
              UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted>(
          create);
  static UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted?
      _defaultInstance;

  @$pb.TagNumber(1)
  UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted_SignedData
      get signedData => $_getN(0);
  @$pb.TagNumber(1)
  set signedData(
          UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted_SignedData
              value) =>
      $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasSignedData() => $_has(0);
  @$pb.TagNumber(1)
  void clearSignedData() => $_clearField(1);
  @$pb.TagNumber(1)
  UserDiscoveryMessage_UserDiscoveryPromotion_AnnouncementShareDecrypted_SignedData
      ensureSignedData() => $_ensure(0);

  @$pb.TagNumber(2)
  $core.List<$core.int> get signature => $_getN(1);
  @$pb.TagNumber(2)
  set signature($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSignature() => $_has(1);
  @$pb.TagNumber(2)
  void clearSignature() => $_clearField(2);
}

class UserDiscoveryMessage_UserDiscoveryPromotion extends $pb.GeneratedMessage {
  factory UserDiscoveryMessage_UserDiscoveryPromotion({
    $core.int? promotionId,
    $fixnum.Int64? publicId,
    $core.int? threshold,
    $core.List<$core.int>? announcementShare,
    $fixnum.Int64? publicKeyVerifiedTimestamp,
  }) {
    final result = create();
    if (promotionId != null) result.promotionId = promotionId;
    if (publicId != null) result.publicId = publicId;
    if (threshold != null) result.threshold = threshold;
    if (announcementShare != null) result.announcementShare = announcementShare;
    if (publicKeyVerifiedTimestamp != null)
      result.publicKeyVerifiedTimestamp = publicKeyVerifiedTimestamp;
    return result;
  }

  UserDiscoveryMessage_UserDiscoveryPromotion._();

  factory UserDiscoveryMessage_UserDiscoveryPromotion.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UserDiscoveryMessage_UserDiscoveryPromotion.fromJson(
          $core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UserDiscoveryMessage.UserDiscoveryPromotion',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'user_discovery'),
      createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'promotionId', $pb.PbFieldType.OU3)
    ..aInt64(2, _omitFieldNames ? '' : 'publicId')
    ..a<$core.int>(3, _omitFieldNames ? '' : 'threshold', $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'announcementShare', $pb.PbFieldType.OY)
    ..aInt64(6, _omitFieldNames ? '' : 'publicKeyVerifiedTimestamp')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserDiscoveryMessage_UserDiscoveryPromotion clone() =>
      UserDiscoveryMessage_UserDiscoveryPromotion()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserDiscoveryMessage_UserDiscoveryPromotion copyWith(
          void Function(UserDiscoveryMessage_UserDiscoveryPromotion) updates) =>
      super.copyWith((message) =>
              updates(message as UserDiscoveryMessage_UserDiscoveryPromotion))
          as UserDiscoveryMessage_UserDiscoveryPromotion;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UserDiscoveryMessage_UserDiscoveryPromotion create() =>
      UserDiscoveryMessage_UserDiscoveryPromotion._();
  @$core.override
  UserDiscoveryMessage_UserDiscoveryPromotion createEmptyInstance() => create();
  static $pb.PbList<UserDiscoveryMessage_UserDiscoveryPromotion>
      createRepeated() =>
          $pb.PbList<UserDiscoveryMessage_UserDiscoveryPromotion>();
  @$core.pragma('dart2js:noInline')
  static UserDiscoveryMessage_UserDiscoveryPromotion getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          UserDiscoveryMessage_UserDiscoveryPromotion>(create);
  static UserDiscoveryMessage_UserDiscoveryPromotion? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get promotionId => $_getIZ(0);
  @$pb.TagNumber(1)
  set promotionId($core.int value) => $_setUnsignedInt32(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPromotionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPromotionId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get publicId => $_getI64(1);
  @$pb.TagNumber(2)
  set publicId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPublicId() => $_has(1);
  @$pb.TagNumber(2)
  void clearPublicId() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get threshold => $_getIZ(2);
  @$pb.TagNumber(3)
  set threshold($core.int value) => $_setUnsignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasThreshold() => $_has(2);
  @$pb.TagNumber(3)
  void clearThreshold() => $_clearField(3);

  @$pb.TagNumber(5)
  $core.List<$core.int> get announcementShare => $_getN(3);
  @$pb.TagNumber(5)
  set announcementShare($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(5)
  $core.bool hasAnnouncementShare() => $_has(3);
  @$pb.TagNumber(5)
  void clearAnnouncementShare() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get publicKeyVerifiedTimestamp => $_getI64(4);
  @$pb.TagNumber(6)
  set publicKeyVerifiedTimestamp($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(6)
  $core.bool hasPublicKeyVerifiedTimestamp() => $_has(4);
  @$pb.TagNumber(6)
  void clearPublicKeyVerifiedTimestamp() => $_clearField(6);
}

class UserDiscoveryMessage_UserDiscoveryRecall extends $pb.GeneratedMessage {
  factory UserDiscoveryMessage_UserDiscoveryRecall({
    $fixnum.Int64? promotionId,
  }) {
    final result = create();
    if (promotionId != null) result.promotionId = promotionId;
    return result;
  }

  UserDiscoveryMessage_UserDiscoveryRecall._();

  factory UserDiscoveryMessage_UserDiscoveryRecall.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UserDiscoveryMessage_UserDiscoveryRecall.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UserDiscoveryMessage.UserDiscoveryRecall',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'user_discovery'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'promotionId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserDiscoveryMessage_UserDiscoveryRecall clone() =>
      UserDiscoveryMessage_UserDiscoveryRecall()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserDiscoveryMessage_UserDiscoveryRecall copyWith(
          void Function(UserDiscoveryMessage_UserDiscoveryRecall) updates) =>
      super.copyWith((message) =>
              updates(message as UserDiscoveryMessage_UserDiscoveryRecall))
          as UserDiscoveryMessage_UserDiscoveryRecall;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UserDiscoveryMessage_UserDiscoveryRecall create() =>
      UserDiscoveryMessage_UserDiscoveryRecall._();
  @$core.override
  UserDiscoveryMessage_UserDiscoveryRecall createEmptyInstance() => create();
  static $pb.PbList<UserDiscoveryMessage_UserDiscoveryRecall>
      createRepeated() =>
          $pb.PbList<UserDiscoveryMessage_UserDiscoveryRecall>();
  @$core.pragma('dart2js:noInline')
  static UserDiscoveryMessage_UserDiscoveryRecall getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          UserDiscoveryMessage_UserDiscoveryRecall>(create);
  static UserDiscoveryMessage_UserDiscoveryRecall? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get promotionId => $_getI64(0);
  @$pb.TagNumber(1)
  set promotionId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPromotionId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPromotionId() => $_clearField(1);
}

class UserDiscoveryMessage extends $pb.GeneratedMessage {
  factory UserDiscoveryMessage({
    UserDiscoveryVersion? version,
    UserDiscoveryMessage_UserDiscoveryAnnouncement? userDiscoveryAnnouncement,
    UserDiscoveryMessage_UserDiscoveryPromotion? userDiscoveryPromotion,
    UserDiscoveryMessage_UserDiscoveryRecall? userDiscoveryRecall,
  }) {
    final result = create();
    if (version != null) result.version = version;
    if (userDiscoveryAnnouncement != null)
      result.userDiscoveryAnnouncement = userDiscoveryAnnouncement;
    if (userDiscoveryPromotion != null)
      result.userDiscoveryPromotion = userDiscoveryPromotion;
    if (userDiscoveryRecall != null)
      result.userDiscoveryRecall = userDiscoveryRecall;
    return result;
  }

  UserDiscoveryMessage._();

  factory UserDiscoveryMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UserDiscoveryMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UserDiscoveryMessage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'user_discovery'),
      createEmptyInstance: create)
    ..aOM<UserDiscoveryVersion>(1, _omitFieldNames ? '' : 'version',
        subBuilder: UserDiscoveryVersion.create)
    ..aOM<UserDiscoveryMessage_UserDiscoveryAnnouncement>(
        2, _omitFieldNames ? '' : 'userDiscoveryAnnouncement',
        subBuilder: UserDiscoveryMessage_UserDiscoveryAnnouncement.create)
    ..aOM<UserDiscoveryMessage_UserDiscoveryPromotion>(
        3, _omitFieldNames ? '' : 'userDiscoveryPromotion',
        subBuilder: UserDiscoveryMessage_UserDiscoveryPromotion.create)
    ..aOM<UserDiscoveryMessage_UserDiscoveryRecall>(
        4, _omitFieldNames ? '' : 'userDiscoveryRecall',
        subBuilder: UserDiscoveryMessage_UserDiscoveryRecall.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserDiscoveryMessage clone() =>
      UserDiscoveryMessage()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UserDiscoveryMessage copyWith(void Function(UserDiscoveryMessage) updates) =>
      super.copyWith((message) => updates(message as UserDiscoveryMessage))
          as UserDiscoveryMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UserDiscoveryMessage create() => UserDiscoveryMessage._();
  @$core.override
  UserDiscoveryMessage createEmptyInstance() => create();
  static $pb.PbList<UserDiscoveryMessage> createRepeated() =>
      $pb.PbList<UserDiscoveryMessage>();
  @$core.pragma('dart2js:noInline')
  static UserDiscoveryMessage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UserDiscoveryMessage>(create);
  static UserDiscoveryMessage? _defaultInstance;

  @$pb.TagNumber(1)
  UserDiscoveryVersion get version => $_getN(0);
  @$pb.TagNumber(1)
  set version(UserDiscoveryVersion value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasVersion() => $_has(0);
  @$pb.TagNumber(1)
  void clearVersion() => $_clearField(1);
  @$pb.TagNumber(1)
  UserDiscoveryVersion ensureVersion() => $_ensure(0);

  @$pb.TagNumber(2)
  UserDiscoveryMessage_UserDiscoveryAnnouncement
      get userDiscoveryAnnouncement => $_getN(1);
  @$pb.TagNumber(2)
  set userDiscoveryAnnouncement(
          UserDiscoveryMessage_UserDiscoveryAnnouncement value) =>
      $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasUserDiscoveryAnnouncement() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserDiscoveryAnnouncement() => $_clearField(2);
  @$pb.TagNumber(2)
  UserDiscoveryMessage_UserDiscoveryAnnouncement
      ensureUserDiscoveryAnnouncement() => $_ensure(1);

  @$pb.TagNumber(3)
  UserDiscoveryMessage_UserDiscoveryPromotion get userDiscoveryPromotion =>
      $_getN(2);
  @$pb.TagNumber(3)
  set userDiscoveryPromotion(
          UserDiscoveryMessage_UserDiscoveryPromotion value) =>
      $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasUserDiscoveryPromotion() => $_has(2);
  @$pb.TagNumber(3)
  void clearUserDiscoveryPromotion() => $_clearField(3);
  @$pb.TagNumber(3)
  UserDiscoveryMessage_UserDiscoveryPromotion ensureUserDiscoveryPromotion() =>
      $_ensure(2);

  @$pb.TagNumber(4)
  UserDiscoveryMessage_UserDiscoveryRecall get userDiscoveryRecall => $_getN(3);
  @$pb.TagNumber(4)
  set userDiscoveryRecall(UserDiscoveryMessage_UserDiscoveryRecall value) =>
      $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasUserDiscoveryRecall() => $_has(3);
  @$pb.TagNumber(4)
  void clearUserDiscoveryRecall() => $_clearField(4);
  @$pb.TagNumber(4)
  UserDiscoveryMessage_UserDiscoveryRecall ensureUserDiscoveryRecall() =>
      $_ensure(3);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
