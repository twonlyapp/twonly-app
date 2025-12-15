// This is a generated file - do not edit.
//
// Generated from qr.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'qr.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'qr.pbenum.dart';

class QREnvelope extends $pb.GeneratedMessage {
  factory QREnvelope({
    QREnvelope_Type? type,
    $core.List<$core.int>? data,
  }) {
    final result = create();
    if (type != null) result.type = type;
    if (data != null) result.data = data;
    return result;
  }

  QREnvelope._();

  factory QREnvelope.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory QREnvelope.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'QREnvelope',
      createEmptyInstance: create)
    ..e<QREnvelope_Type>(2, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE,
        defaultOrMaker: QREnvelope_Type.PublicProfile,
        valueOf: QREnvelope_Type.valueOf,
        enumValues: QREnvelope_Type.values)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QREnvelope clone() => QREnvelope()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  QREnvelope copyWith(void Function(QREnvelope) updates) =>
      super.copyWith((message) => updates(message as QREnvelope)) as QREnvelope;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static QREnvelope create() => QREnvelope._();
  @$core.override
  QREnvelope createEmptyInstance() => create();
  static $pb.PbList<QREnvelope> createRepeated() => $pb.PbList<QREnvelope>();
  @$core.pragma('dart2js:noInline')
  static QREnvelope getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<QREnvelope>(create);
  static QREnvelope? _defaultInstance;

  @$pb.TagNumber(2)
  QREnvelope_Type get type => $_getN(0);
  @$pb.TagNumber(2)
  set type(QREnvelope_Type value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(2)
  void clearType() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get data => $_getN(1);
  @$pb.TagNumber(3)
  set data($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(3)
  $core.bool hasData() => $_has(1);
  @$pb.TagNumber(3)
  void clearData() => $_clearField(3);
}

class PublicProfile extends $pb.GeneratedMessage {
  factory PublicProfile({
    $fixnum.Int64? userId,
    $core.String? username,
    $core.List<$core.int>? publicIdentityKey,
    $core.List<$core.int>? signedPrekey,
    $fixnum.Int64? registrationId,
    $core.List<$core.int>? signedPrekeySignature,
    $fixnum.Int64? signedPrekeyId,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    if (username != null) result.username = username;
    if (publicIdentityKey != null) result.publicIdentityKey = publicIdentityKey;
    if (signedPrekey != null) result.signedPrekey = signedPrekey;
    if (registrationId != null) result.registrationId = registrationId;
    if (signedPrekeySignature != null)
      result.signedPrekeySignature = signedPrekeySignature;
    if (signedPrekeyId != null) result.signedPrekeyId = signedPrekeyId;
    return result;
  }

  PublicProfile._();

  factory PublicProfile.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory PublicProfile.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'PublicProfile',
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'userId')
    ..aOS(2, _omitFieldNames ? '' : 'username')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'publicIdentityKey', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'signedPrekey', $pb.PbFieldType.OY)
    ..aInt64(5, _omitFieldNames ? '' : 'registrationId')
    ..a<$core.List<$core.int>>(
        6, _omitFieldNames ? '' : 'signedPrekeySignature', $pb.PbFieldType.OY)
    ..aInt64(7, _omitFieldNames ? '' : 'signedPrekeyId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublicProfile clone() => PublicProfile()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PublicProfile copyWith(void Function(PublicProfile) updates) =>
      super.copyWith((message) => updates(message as PublicProfile))
          as PublicProfile;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PublicProfile create() => PublicProfile._();
  @$core.override
  PublicProfile createEmptyInstance() => create();
  static $pb.PbList<PublicProfile> createRepeated() =>
      $pb.PbList<PublicProfile>();
  @$core.pragma('dart2js:noInline')
  static PublicProfile getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<PublicProfile>(create);
  static PublicProfile? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get userId => $_getI64(0);
  @$pb.TagNumber(1)
  set userId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get username => $_getSZ(1);
  @$pb.TagNumber(2)
  set username($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsername() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get publicIdentityKey => $_getN(2);
  @$pb.TagNumber(3)
  set publicIdentityKey($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPublicIdentityKey() => $_has(2);
  @$pb.TagNumber(3)
  void clearPublicIdentityKey() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get signedPrekey => $_getN(3);
  @$pb.TagNumber(4)
  set signedPrekey($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasSignedPrekey() => $_has(3);
  @$pb.TagNumber(4)
  void clearSignedPrekey() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get registrationId => $_getI64(4);
  @$pb.TagNumber(5)
  set registrationId($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasRegistrationId() => $_has(4);
  @$pb.TagNumber(5)
  void clearRegistrationId() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.List<$core.int> get signedPrekeySignature => $_getN(5);
  @$pb.TagNumber(6)
  set signedPrekeySignature($core.List<$core.int> value) =>
      $_setBytes(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSignedPrekeySignature() => $_has(5);
  @$pb.TagNumber(6)
  void clearSignedPrekeySignature() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get signedPrekeyId => $_getI64(6);
  @$pb.TagNumber(7)
  set signedPrekeyId($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasSignedPrekeyId() => $_has(6);
  @$pb.TagNumber(7)
  void clearSignedPrekeyId() => $_clearField(7);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
