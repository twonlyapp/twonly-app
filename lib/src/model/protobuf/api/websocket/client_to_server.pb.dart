//
//  Generated code. Do not modify.
//  source: api/websocket/client_to_server.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'error.pbenum.dart' as $0;

enum ClientToServer_V {
  v0, 
  notSet
}

class ClientToServer extends $pb.GeneratedMessage {
  factory ClientToServer({
    V0? v0,
  }) {
    final $result = create();
    if (v0 != null) {
      $result.v0 = v0;
    }
    return $result;
  }
  ClientToServer._() : super();
  factory ClientToServer.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ClientToServer.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, ClientToServer_V> _ClientToServer_VByTag = {
    1 : ClientToServer_V.v0,
    0 : ClientToServer_V.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ClientToServer', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..oo(0, [1])
    ..aOM<V0>(1, _omitFieldNames ? '' : 'V0', protoName: 'V0', subBuilder: V0.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ClientToServer clone() => ClientToServer()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ClientToServer copyWith(void Function(ClientToServer) updates) => super.copyWith((message) => updates(message as ClientToServer)) as ClientToServer;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ClientToServer create() => ClientToServer._();
  ClientToServer createEmptyInstance() => create();
  static $pb.PbList<ClientToServer> createRepeated() => $pb.PbList<ClientToServer>();
  @$core.pragma('dart2js:noInline')
  static ClientToServer getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ClientToServer>(create);
  static ClientToServer? _defaultInstance;

  ClientToServer_V whichV() => _ClientToServer_VByTag[$_whichOneof(0)]!;
  void clearV() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  V0 get v0 => $_getN(0);
  @$pb.TagNumber(1)
  set v0(V0 v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasV0() => $_has(0);
  @$pb.TagNumber(1)
  void clearV0() => clearField(1);
  @$pb.TagNumber(1)
  V0 ensureV0() => $_ensure(0);
}

enum V0_Kind {
  handshake, 
  applicationdata, 
  response, 
  notSet
}

class V0 extends $pb.GeneratedMessage {
  factory V0({
    $fixnum.Int64? seq,
    Handshake? handshake,
    ApplicationData? applicationdata,
    Response? response,
  }) {
    final $result = create();
    if (seq != null) {
      $result.seq = seq;
    }
    if (handshake != null) {
      $result.handshake = handshake;
    }
    if (applicationdata != null) {
      $result.applicationdata = applicationdata;
    }
    if (response != null) {
      $result.response = response;
    }
    return $result;
  }
  V0._() : super();
  factory V0.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory V0.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, V0_Kind> _V0_KindByTag = {
    2 : V0_Kind.handshake,
    3 : V0_Kind.applicationdata,
    4 : V0_Kind.response,
    0 : V0_Kind.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'V0', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..oo(0, [2, 3, 4])
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'seq', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<Handshake>(2, _omitFieldNames ? '' : 'handshake', subBuilder: Handshake.create)
    ..aOM<ApplicationData>(3, _omitFieldNames ? '' : 'applicationdata', subBuilder: ApplicationData.create)
    ..aOM<Response>(4, _omitFieldNames ? '' : 'response', subBuilder: Response.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  V0 clone() => V0()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  V0 copyWith(void Function(V0) updates) => super.copyWith((message) => updates(message as V0)) as V0;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static V0 create() => V0._();
  V0 createEmptyInstance() => create();
  static $pb.PbList<V0> createRepeated() => $pb.PbList<V0>();
  @$core.pragma('dart2js:noInline')
  static V0 getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<V0>(create);
  static V0? _defaultInstance;

  V0_Kind whichKind() => _V0_KindByTag[$_whichOneof(0)]!;
  void clearKind() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $fixnum.Int64 get seq => $_getI64(0);
  @$pb.TagNumber(1)
  set seq($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSeq() => $_has(0);
  @$pb.TagNumber(1)
  void clearSeq() => clearField(1);

  @$pb.TagNumber(2)
  Handshake get handshake => $_getN(1);
  @$pb.TagNumber(2)
  set handshake(Handshake v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasHandshake() => $_has(1);
  @$pb.TagNumber(2)
  void clearHandshake() => clearField(2);
  @$pb.TagNumber(2)
  Handshake ensureHandshake() => $_ensure(1);

  @$pb.TagNumber(3)
  ApplicationData get applicationdata => $_getN(2);
  @$pb.TagNumber(3)
  set applicationdata(ApplicationData v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasApplicationdata() => $_has(2);
  @$pb.TagNumber(3)
  void clearApplicationdata() => clearField(3);
  @$pb.TagNumber(3)
  ApplicationData ensureApplicationdata() => $_ensure(2);

  @$pb.TagNumber(4)
  Response get response => $_getN(3);
  @$pb.TagNumber(4)
  set response(Response v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasResponse() => $_has(3);
  @$pb.TagNumber(4)
  void clearResponse() => clearField(4);
  @$pb.TagNumber(4)
  Response ensureResponse() => $_ensure(3);
}

class Handshake_Register extends $pb.GeneratedMessage {
  factory Handshake_Register({
    $core.String? username,
    $core.String? inviteCode,
    $core.List<$core.int>? publicIdentityKey,
    $core.List<$core.int>? signedPrekey,
    $core.List<$core.int>? signedPrekeySignature,
    $fixnum.Int64? signedPrekeyId,
    $fixnum.Int64? registrationId,
    $core.bool? isIos,
    $core.String? langCode,
  }) {
    final $result = create();
    if (username != null) {
      $result.username = username;
    }
    if (inviteCode != null) {
      $result.inviteCode = inviteCode;
    }
    if (publicIdentityKey != null) {
      $result.publicIdentityKey = publicIdentityKey;
    }
    if (signedPrekey != null) {
      $result.signedPrekey = signedPrekey;
    }
    if (signedPrekeySignature != null) {
      $result.signedPrekeySignature = signedPrekeySignature;
    }
    if (signedPrekeyId != null) {
      $result.signedPrekeyId = signedPrekeyId;
    }
    if (registrationId != null) {
      $result.registrationId = registrationId;
    }
    if (isIos != null) {
      $result.isIos = isIos;
    }
    if (langCode != null) {
      $result.langCode = langCode;
    }
    return $result;
  }
  Handshake_Register._() : super();
  factory Handshake_Register.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Handshake_Register.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Handshake.Register', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'username')
    ..aOS(2, _omitFieldNames ? '' : 'inviteCode')
    ..a<$core.List<$core.int>>(3, _omitFieldNames ? '' : 'publicIdentityKey', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(4, _omitFieldNames ? '' : 'signedPrekey', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(5, _omitFieldNames ? '' : 'signedPrekeySignature', $pb.PbFieldType.OY)
    ..aInt64(6, _omitFieldNames ? '' : 'signedPrekeyId')
    ..aInt64(7, _omitFieldNames ? '' : 'registrationId')
    ..aOB(8, _omitFieldNames ? '' : 'isIos')
    ..aOS(9, _omitFieldNames ? '' : 'langCode')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Handshake_Register clone() => Handshake_Register()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Handshake_Register copyWith(void Function(Handshake_Register) updates) => super.copyWith((message) => updates(message as Handshake_Register)) as Handshake_Register;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Handshake_Register create() => Handshake_Register._();
  Handshake_Register createEmptyInstance() => create();
  static $pb.PbList<Handshake_Register> createRepeated() => $pb.PbList<Handshake_Register>();
  @$core.pragma('dart2js:noInline')
  static Handshake_Register getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Handshake_Register>(create);
  static Handshake_Register? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get username => $_getSZ(0);
  @$pb.TagNumber(1)
  set username($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUsername() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsername() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get inviteCode => $_getSZ(1);
  @$pb.TagNumber(2)
  set inviteCode($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasInviteCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearInviteCode() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get publicIdentityKey => $_getN(2);
  @$pb.TagNumber(3)
  set publicIdentityKey($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasPublicIdentityKey() => $_has(2);
  @$pb.TagNumber(3)
  void clearPublicIdentityKey() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get signedPrekey => $_getN(3);
  @$pb.TagNumber(4)
  set signedPrekey($core.List<$core.int> v) { $_setBytes(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasSignedPrekey() => $_has(3);
  @$pb.TagNumber(4)
  void clearSignedPrekey() => clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.int> get signedPrekeySignature => $_getN(4);
  @$pb.TagNumber(5)
  set signedPrekeySignature($core.List<$core.int> v) { $_setBytes(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasSignedPrekeySignature() => $_has(4);
  @$pb.TagNumber(5)
  void clearSignedPrekeySignature() => clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get signedPrekeyId => $_getI64(5);
  @$pb.TagNumber(6)
  set signedPrekeyId($fixnum.Int64 v) { $_setInt64(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasSignedPrekeyId() => $_has(5);
  @$pb.TagNumber(6)
  void clearSignedPrekeyId() => clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get registrationId => $_getI64(6);
  @$pb.TagNumber(7)
  set registrationId($fixnum.Int64 v) { $_setInt64(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasRegistrationId() => $_has(6);
  @$pb.TagNumber(7)
  void clearRegistrationId() => clearField(7);

  @$pb.TagNumber(8)
  $core.bool get isIos => $_getBF(7);
  @$pb.TagNumber(8)
  set isIos($core.bool v) { $_setBool(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasIsIos() => $_has(7);
  @$pb.TagNumber(8)
  void clearIsIos() => clearField(8);

  @$pb.TagNumber(9)
  $core.String get langCode => $_getSZ(8);
  @$pb.TagNumber(9)
  set langCode($core.String v) { $_setString(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasLangCode() => $_has(8);
  @$pb.TagNumber(9)
  void clearLangCode() => clearField(9);
}

class Handshake_GetAuthChallenge extends $pb.GeneratedMessage {
  factory Handshake_GetAuthChallenge() => create();
  Handshake_GetAuthChallenge._() : super();
  factory Handshake_GetAuthChallenge.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Handshake_GetAuthChallenge.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Handshake.GetAuthChallenge', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Handshake_GetAuthChallenge clone() => Handshake_GetAuthChallenge()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Handshake_GetAuthChallenge copyWith(void Function(Handshake_GetAuthChallenge) updates) => super.copyWith((message) => updates(message as Handshake_GetAuthChallenge)) as Handshake_GetAuthChallenge;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Handshake_GetAuthChallenge create() => Handshake_GetAuthChallenge._();
  Handshake_GetAuthChallenge createEmptyInstance() => create();
  static $pb.PbList<Handshake_GetAuthChallenge> createRepeated() => $pb.PbList<Handshake_GetAuthChallenge>();
  @$core.pragma('dart2js:noInline')
  static Handshake_GetAuthChallenge getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Handshake_GetAuthChallenge>(create);
  static Handshake_GetAuthChallenge? _defaultInstance;
}

class Handshake_GetAuthToken extends $pb.GeneratedMessage {
  factory Handshake_GetAuthToken({
    $fixnum.Int64? userId,
    $core.List<$core.int>? response,
  }) {
    final $result = create();
    if (userId != null) {
      $result.userId = userId;
    }
    if (response != null) {
      $result.response = response;
    }
    return $result;
  }
  Handshake_GetAuthToken._() : super();
  factory Handshake_GetAuthToken.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Handshake_GetAuthToken.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Handshake.GetAuthToken', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'userId')
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'response', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Handshake_GetAuthToken clone() => Handshake_GetAuthToken()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Handshake_GetAuthToken copyWith(void Function(Handshake_GetAuthToken) updates) => super.copyWith((message) => updates(message as Handshake_GetAuthToken)) as Handshake_GetAuthToken;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Handshake_GetAuthToken create() => Handshake_GetAuthToken._();
  Handshake_GetAuthToken createEmptyInstance() => create();
  static $pb.PbList<Handshake_GetAuthToken> createRepeated() => $pb.PbList<Handshake_GetAuthToken>();
  @$core.pragma('dart2js:noInline')
  static Handshake_GetAuthToken getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Handshake_GetAuthToken>(create);
  static Handshake_GetAuthToken? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get userId => $_getI64(0);
  @$pb.TagNumber(1)
  set userId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get response => $_getN(1);
  @$pb.TagNumber(2)
  set response($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasResponse() => $_has(1);
  @$pb.TagNumber(2)
  void clearResponse() => clearField(2);
}

class Handshake_Authenticate extends $pb.GeneratedMessage {
  factory Handshake_Authenticate({
    $fixnum.Int64? userId,
    $core.List<$core.int>? authToken,
    $core.String? appVersion,
    $fixnum.Int64? deviceId,
  }) {
    final $result = create();
    if (userId != null) {
      $result.userId = userId;
    }
    if (authToken != null) {
      $result.authToken = authToken;
    }
    if (appVersion != null) {
      $result.appVersion = appVersion;
    }
    if (deviceId != null) {
      $result.deviceId = deviceId;
    }
    return $result;
  }
  Handshake_Authenticate._() : super();
  factory Handshake_Authenticate.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Handshake_Authenticate.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Handshake.Authenticate', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'userId')
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'authToken', $pb.PbFieldType.OY)
    ..aOS(3, _omitFieldNames ? '' : 'appVersion')
    ..aInt64(4, _omitFieldNames ? '' : 'deviceId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Handshake_Authenticate clone() => Handshake_Authenticate()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Handshake_Authenticate copyWith(void Function(Handshake_Authenticate) updates) => super.copyWith((message) => updates(message as Handshake_Authenticate)) as Handshake_Authenticate;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Handshake_Authenticate create() => Handshake_Authenticate._();
  Handshake_Authenticate createEmptyInstance() => create();
  static $pb.PbList<Handshake_Authenticate> createRepeated() => $pb.PbList<Handshake_Authenticate>();
  @$core.pragma('dart2js:noInline')
  static Handshake_Authenticate getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Handshake_Authenticate>(create);
  static Handshake_Authenticate? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get userId => $_getI64(0);
  @$pb.TagNumber(1)
  set userId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get authToken => $_getN(1);
  @$pb.TagNumber(2)
  set authToken($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAuthToken() => $_has(1);
  @$pb.TagNumber(2)
  void clearAuthToken() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get appVersion => $_getSZ(2);
  @$pb.TagNumber(3)
  set appVersion($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasAppVersion() => $_has(2);
  @$pb.TagNumber(3)
  void clearAppVersion() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get deviceId => $_getI64(3);
  @$pb.TagNumber(4)
  set deviceId($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasDeviceId() => $_has(3);
  @$pb.TagNumber(4)
  void clearDeviceId() => clearField(4);
}

enum Handshake_Handshake {
  register, 
  getauthchallenge, 
  getauthtoken, 
  authenticate, 
  notSet
}

class Handshake extends $pb.GeneratedMessage {
  factory Handshake({
    Handshake_Register? register,
    Handshake_GetAuthChallenge? getauthchallenge,
    Handshake_GetAuthToken? getauthtoken,
    Handshake_Authenticate? authenticate,
  }) {
    final $result = create();
    if (register != null) {
      $result.register = register;
    }
    if (getauthchallenge != null) {
      $result.getauthchallenge = getauthchallenge;
    }
    if (getauthtoken != null) {
      $result.getauthtoken = getauthtoken;
    }
    if (authenticate != null) {
      $result.authenticate = authenticate;
    }
    return $result;
  }
  Handshake._() : super();
  factory Handshake.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Handshake.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, Handshake_Handshake> _Handshake_HandshakeByTag = {
    1 : Handshake_Handshake.register,
    2 : Handshake_Handshake.getauthchallenge,
    3 : Handshake_Handshake.getauthtoken,
    4 : Handshake_Handshake.authenticate,
    0 : Handshake_Handshake.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Handshake', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4])
    ..aOM<Handshake_Register>(1, _omitFieldNames ? '' : 'register', subBuilder: Handshake_Register.create)
    ..aOM<Handshake_GetAuthChallenge>(2, _omitFieldNames ? '' : 'getauthchallenge', subBuilder: Handshake_GetAuthChallenge.create)
    ..aOM<Handshake_GetAuthToken>(3, _omitFieldNames ? '' : 'getauthtoken', subBuilder: Handshake_GetAuthToken.create)
    ..aOM<Handshake_Authenticate>(4, _omitFieldNames ? '' : 'authenticate', subBuilder: Handshake_Authenticate.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Handshake clone() => Handshake()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Handshake copyWith(void Function(Handshake) updates) => super.copyWith((message) => updates(message as Handshake)) as Handshake;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Handshake create() => Handshake._();
  Handshake createEmptyInstance() => create();
  static $pb.PbList<Handshake> createRepeated() => $pb.PbList<Handshake>();
  @$core.pragma('dart2js:noInline')
  static Handshake getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Handshake>(create);
  static Handshake? _defaultInstance;

  Handshake_Handshake whichHandshake() => _Handshake_HandshakeByTag[$_whichOneof(0)]!;
  void clearHandshake() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  Handshake_Register get register => $_getN(0);
  @$pb.TagNumber(1)
  set register(Handshake_Register v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasRegister() => $_has(0);
  @$pb.TagNumber(1)
  void clearRegister() => clearField(1);
  @$pb.TagNumber(1)
  Handshake_Register ensureRegister() => $_ensure(0);

  @$pb.TagNumber(2)
  Handshake_GetAuthChallenge get getauthchallenge => $_getN(1);
  @$pb.TagNumber(2)
  set getauthchallenge(Handshake_GetAuthChallenge v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasGetauthchallenge() => $_has(1);
  @$pb.TagNumber(2)
  void clearGetauthchallenge() => clearField(2);
  @$pb.TagNumber(2)
  Handshake_GetAuthChallenge ensureGetauthchallenge() => $_ensure(1);

  @$pb.TagNumber(3)
  Handshake_GetAuthToken get getauthtoken => $_getN(2);
  @$pb.TagNumber(3)
  set getauthtoken(Handshake_GetAuthToken v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasGetauthtoken() => $_has(2);
  @$pb.TagNumber(3)
  void clearGetauthtoken() => clearField(3);
  @$pb.TagNumber(3)
  Handshake_GetAuthToken ensureGetauthtoken() => $_ensure(2);

  @$pb.TagNumber(4)
  Handshake_Authenticate get authenticate => $_getN(3);
  @$pb.TagNumber(4)
  set authenticate(Handshake_Authenticate v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasAuthenticate() => $_has(3);
  @$pb.TagNumber(4)
  void clearAuthenticate() => clearField(4);
  @$pb.TagNumber(4)
  Handshake_Authenticate ensureAuthenticate() => $_ensure(3);
}

class ApplicationData_TextMessage extends $pb.GeneratedMessage {
  factory ApplicationData_TextMessage({
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
  ApplicationData_TextMessage._() : super();
  factory ApplicationData_TextMessage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ApplicationData_TextMessage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApplicationData.TextMessage', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'userId')
    ..a<$core.List<$core.int>>(3, _omitFieldNames ? '' : 'body', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(4, _omitFieldNames ? '' : 'pushData', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ApplicationData_TextMessage clone() => ApplicationData_TextMessage()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ApplicationData_TextMessage copyWith(void Function(ApplicationData_TextMessage) updates) => super.copyWith((message) => updates(message as ApplicationData_TextMessage)) as ApplicationData_TextMessage;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplicationData_TextMessage create() => ApplicationData_TextMessage._();
  ApplicationData_TextMessage createEmptyInstance() => create();
  static $pb.PbList<ApplicationData_TextMessage> createRepeated() => $pb.PbList<ApplicationData_TextMessage>();
  @$core.pragma('dart2js:noInline')
  static ApplicationData_TextMessage getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApplicationData_TextMessage>(create);
  static ApplicationData_TextMessage? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get userId => $_getI64(0);
  @$pb.TagNumber(1)
  set userId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => clearField(1);

  @$pb.TagNumber(3)
  $core.List<$core.int> get body => $_getN(1);
  @$pb.TagNumber(3)
  set body($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(3)
  $core.bool hasBody() => $_has(1);
  @$pb.TagNumber(3)
  void clearBody() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get pushData => $_getN(2);
  @$pb.TagNumber(4)
  set pushData($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(4)
  $core.bool hasPushData() => $_has(2);
  @$pb.TagNumber(4)
  void clearPushData() => clearField(4);
}

class ApplicationData_GetUserByUsername extends $pb.GeneratedMessage {
  factory ApplicationData_GetUserByUsername({
    $core.String? username,
  }) {
    final $result = create();
    if (username != null) {
      $result.username = username;
    }
    return $result;
  }
  ApplicationData_GetUserByUsername._() : super();
  factory ApplicationData_GetUserByUsername.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ApplicationData_GetUserByUsername.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApplicationData.GetUserByUsername', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'username')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ApplicationData_GetUserByUsername clone() => ApplicationData_GetUserByUsername()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ApplicationData_GetUserByUsername copyWith(void Function(ApplicationData_GetUserByUsername) updates) => super.copyWith((message) => updates(message as ApplicationData_GetUserByUsername)) as ApplicationData_GetUserByUsername;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplicationData_GetUserByUsername create() => ApplicationData_GetUserByUsername._();
  ApplicationData_GetUserByUsername createEmptyInstance() => create();
  static $pb.PbList<ApplicationData_GetUserByUsername> createRepeated() => $pb.PbList<ApplicationData_GetUserByUsername>();
  @$core.pragma('dart2js:noInline')
  static ApplicationData_GetUserByUsername getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApplicationData_GetUserByUsername>(create);
  static ApplicationData_GetUserByUsername? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get username => $_getSZ(0);
  @$pb.TagNumber(1)
  set username($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUsername() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsername() => clearField(1);
}

class ApplicationData_ChangeUsername extends $pb.GeneratedMessage {
  factory ApplicationData_ChangeUsername({
    $core.String? username,
  }) {
    final $result = create();
    if (username != null) {
      $result.username = username;
    }
    return $result;
  }
  ApplicationData_ChangeUsername._() : super();
  factory ApplicationData_ChangeUsername.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ApplicationData_ChangeUsername.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApplicationData.ChangeUsername', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'username')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ApplicationData_ChangeUsername clone() => ApplicationData_ChangeUsername()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ApplicationData_ChangeUsername copyWith(void Function(ApplicationData_ChangeUsername) updates) => super.copyWith((message) => updates(message as ApplicationData_ChangeUsername)) as ApplicationData_ChangeUsername;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplicationData_ChangeUsername create() => ApplicationData_ChangeUsername._();
  ApplicationData_ChangeUsername createEmptyInstance() => create();
  static $pb.PbList<ApplicationData_ChangeUsername> createRepeated() => $pb.PbList<ApplicationData_ChangeUsername>();
  @$core.pragma('dart2js:noInline')
  static ApplicationData_ChangeUsername getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApplicationData_ChangeUsername>(create);
  static ApplicationData_ChangeUsername? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get username => $_getSZ(0);
  @$pb.TagNumber(1)
  set username($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUsername() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsername() => clearField(1);
}

class ApplicationData_UpdateGoogleFcmToken extends $pb.GeneratedMessage {
  factory ApplicationData_UpdateGoogleFcmToken({
    $core.String? googleFcm,
  }) {
    final $result = create();
    if (googleFcm != null) {
      $result.googleFcm = googleFcm;
    }
    return $result;
  }
  ApplicationData_UpdateGoogleFcmToken._() : super();
  factory ApplicationData_UpdateGoogleFcmToken.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ApplicationData_UpdateGoogleFcmToken.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApplicationData.UpdateGoogleFcmToken', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'googleFcm')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ApplicationData_UpdateGoogleFcmToken clone() => ApplicationData_UpdateGoogleFcmToken()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ApplicationData_UpdateGoogleFcmToken copyWith(void Function(ApplicationData_UpdateGoogleFcmToken) updates) => super.copyWith((message) => updates(message as ApplicationData_UpdateGoogleFcmToken)) as ApplicationData_UpdateGoogleFcmToken;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplicationData_UpdateGoogleFcmToken create() => ApplicationData_UpdateGoogleFcmToken._();
  ApplicationData_UpdateGoogleFcmToken createEmptyInstance() => create();
  static $pb.PbList<ApplicationData_UpdateGoogleFcmToken> createRepeated() => $pb.PbList<ApplicationData_UpdateGoogleFcmToken>();
  @$core.pragma('dart2js:noInline')
  static ApplicationData_UpdateGoogleFcmToken getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApplicationData_UpdateGoogleFcmToken>(create);
  static ApplicationData_UpdateGoogleFcmToken? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get googleFcm => $_getSZ(0);
  @$pb.TagNumber(1)
  set googleFcm($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGoogleFcm() => $_has(0);
  @$pb.TagNumber(1)
  void clearGoogleFcm() => clearField(1);
}

class ApplicationData_GetUserById extends $pb.GeneratedMessage {
  factory ApplicationData_GetUserById({
    $fixnum.Int64? userId,
  }) {
    final $result = create();
    if (userId != null) {
      $result.userId = userId;
    }
    return $result;
  }
  ApplicationData_GetUserById._() : super();
  factory ApplicationData_GetUserById.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ApplicationData_GetUserById.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApplicationData.GetUserById', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'userId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ApplicationData_GetUserById clone() => ApplicationData_GetUserById()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ApplicationData_GetUserById copyWith(void Function(ApplicationData_GetUserById) updates) => super.copyWith((message) => updates(message as ApplicationData_GetUserById)) as ApplicationData_GetUserById;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplicationData_GetUserById create() => ApplicationData_GetUserById._();
  ApplicationData_GetUserById createEmptyInstance() => create();
  static $pb.PbList<ApplicationData_GetUserById> createRepeated() => $pb.PbList<ApplicationData_GetUserById>();
  @$core.pragma('dart2js:noInline')
  static ApplicationData_GetUserById getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApplicationData_GetUserById>(create);
  static ApplicationData_GetUserById? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get userId => $_getI64(0);
  @$pb.TagNumber(1)
  set userId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => clearField(1);
}

class ApplicationData_RedeemVoucher extends $pb.GeneratedMessage {
  factory ApplicationData_RedeemVoucher({
    $core.String? voucher,
  }) {
    final $result = create();
    if (voucher != null) {
      $result.voucher = voucher;
    }
    return $result;
  }
  ApplicationData_RedeemVoucher._() : super();
  factory ApplicationData_RedeemVoucher.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ApplicationData_RedeemVoucher.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApplicationData.RedeemVoucher', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'voucher')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ApplicationData_RedeemVoucher clone() => ApplicationData_RedeemVoucher()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ApplicationData_RedeemVoucher copyWith(void Function(ApplicationData_RedeemVoucher) updates) => super.copyWith((message) => updates(message as ApplicationData_RedeemVoucher)) as ApplicationData_RedeemVoucher;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplicationData_RedeemVoucher create() => ApplicationData_RedeemVoucher._();
  ApplicationData_RedeemVoucher createEmptyInstance() => create();
  static $pb.PbList<ApplicationData_RedeemVoucher> createRepeated() => $pb.PbList<ApplicationData_RedeemVoucher>();
  @$core.pragma('dart2js:noInline')
  static ApplicationData_RedeemVoucher getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApplicationData_RedeemVoucher>(create);
  static ApplicationData_RedeemVoucher? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get voucher => $_getSZ(0);
  @$pb.TagNumber(1)
  set voucher($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasVoucher() => $_has(0);
  @$pb.TagNumber(1)
  void clearVoucher() => clearField(1);
}

class ApplicationData_SwitchToPayedPlan extends $pb.GeneratedMessage {
  factory ApplicationData_SwitchToPayedPlan({
    $core.String? planId,
    $core.bool? payMonthly,
    $core.bool? autoRenewal,
  }) {
    final $result = create();
    if (planId != null) {
      $result.planId = planId;
    }
    if (payMonthly != null) {
      $result.payMonthly = payMonthly;
    }
    if (autoRenewal != null) {
      $result.autoRenewal = autoRenewal;
    }
    return $result;
  }
  ApplicationData_SwitchToPayedPlan._() : super();
  factory ApplicationData_SwitchToPayedPlan.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ApplicationData_SwitchToPayedPlan.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApplicationData.SwitchToPayedPlan', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'planId')
    ..aOB(2, _omitFieldNames ? '' : 'payMonthly')
    ..aOB(3, _omitFieldNames ? '' : 'autoRenewal')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ApplicationData_SwitchToPayedPlan clone() => ApplicationData_SwitchToPayedPlan()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ApplicationData_SwitchToPayedPlan copyWith(void Function(ApplicationData_SwitchToPayedPlan) updates) => super.copyWith((message) => updates(message as ApplicationData_SwitchToPayedPlan)) as ApplicationData_SwitchToPayedPlan;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplicationData_SwitchToPayedPlan create() => ApplicationData_SwitchToPayedPlan._();
  ApplicationData_SwitchToPayedPlan createEmptyInstance() => create();
  static $pb.PbList<ApplicationData_SwitchToPayedPlan> createRepeated() => $pb.PbList<ApplicationData_SwitchToPayedPlan>();
  @$core.pragma('dart2js:noInline')
  static ApplicationData_SwitchToPayedPlan getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApplicationData_SwitchToPayedPlan>(create);
  static ApplicationData_SwitchToPayedPlan? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get planId => $_getSZ(0);
  @$pb.TagNumber(1)
  set planId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPlanId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlanId() => clearField(1);

  @$pb.TagNumber(2)
  $core.bool get payMonthly => $_getBF(1);
  @$pb.TagNumber(2)
  set payMonthly($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPayMonthly() => $_has(1);
  @$pb.TagNumber(2)
  void clearPayMonthly() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get autoRenewal => $_getBF(2);
  @$pb.TagNumber(3)
  set autoRenewal($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasAutoRenewal() => $_has(2);
  @$pb.TagNumber(3)
  void clearAutoRenewal() => clearField(3);
}

class ApplicationData_UpdatePlanOptions extends $pb.GeneratedMessage {
  factory ApplicationData_UpdatePlanOptions({
    $core.bool? autoRenewal,
  }) {
    final $result = create();
    if (autoRenewal != null) {
      $result.autoRenewal = autoRenewal;
    }
    return $result;
  }
  ApplicationData_UpdatePlanOptions._() : super();
  factory ApplicationData_UpdatePlanOptions.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ApplicationData_UpdatePlanOptions.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApplicationData.UpdatePlanOptions', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'autoRenewal')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ApplicationData_UpdatePlanOptions clone() => ApplicationData_UpdatePlanOptions()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ApplicationData_UpdatePlanOptions copyWith(void Function(ApplicationData_UpdatePlanOptions) updates) => super.copyWith((message) => updates(message as ApplicationData_UpdatePlanOptions)) as ApplicationData_UpdatePlanOptions;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplicationData_UpdatePlanOptions create() => ApplicationData_UpdatePlanOptions._();
  ApplicationData_UpdatePlanOptions createEmptyInstance() => create();
  static $pb.PbList<ApplicationData_UpdatePlanOptions> createRepeated() => $pb.PbList<ApplicationData_UpdatePlanOptions>();
  @$core.pragma('dart2js:noInline')
  static ApplicationData_UpdatePlanOptions getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApplicationData_UpdatePlanOptions>(create);
  static ApplicationData_UpdatePlanOptions? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get autoRenewal => $_getBF(0);
  @$pb.TagNumber(1)
  set autoRenewal($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasAutoRenewal() => $_has(0);
  @$pb.TagNumber(1)
  void clearAutoRenewal() => clearField(1);
}

class ApplicationData_CreateVoucher extends $pb.GeneratedMessage {
  factory ApplicationData_CreateVoucher({
    $core.int? valueCents,
  }) {
    final $result = create();
    if (valueCents != null) {
      $result.valueCents = valueCents;
    }
    return $result;
  }
  ApplicationData_CreateVoucher._() : super();
  factory ApplicationData_CreateVoucher.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ApplicationData_CreateVoucher.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApplicationData.CreateVoucher', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'valueCents', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ApplicationData_CreateVoucher clone() => ApplicationData_CreateVoucher()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ApplicationData_CreateVoucher copyWith(void Function(ApplicationData_CreateVoucher) updates) => super.copyWith((message) => updates(message as ApplicationData_CreateVoucher)) as ApplicationData_CreateVoucher;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplicationData_CreateVoucher create() => ApplicationData_CreateVoucher._();
  ApplicationData_CreateVoucher createEmptyInstance() => create();
  static $pb.PbList<ApplicationData_CreateVoucher> createRepeated() => $pb.PbList<ApplicationData_CreateVoucher>();
  @$core.pragma('dart2js:noInline')
  static ApplicationData_CreateVoucher getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApplicationData_CreateVoucher>(create);
  static ApplicationData_CreateVoucher? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get valueCents => $_getIZ(0);
  @$pb.TagNumber(1)
  set valueCents($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasValueCents() => $_has(0);
  @$pb.TagNumber(1)
  void clearValueCents() => clearField(1);
}

class ApplicationData_GetLocation extends $pb.GeneratedMessage {
  factory ApplicationData_GetLocation() => create();
  ApplicationData_GetLocation._() : super();
  factory ApplicationData_GetLocation.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ApplicationData_GetLocation.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApplicationData.GetLocation', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ApplicationData_GetLocation clone() => ApplicationData_GetLocation()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ApplicationData_GetLocation copyWith(void Function(ApplicationData_GetLocation) updates) => super.copyWith((message) => updates(message as ApplicationData_GetLocation)) as ApplicationData_GetLocation;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplicationData_GetLocation create() => ApplicationData_GetLocation._();
  ApplicationData_GetLocation createEmptyInstance() => create();
  static $pb.PbList<ApplicationData_GetLocation> createRepeated() => $pb.PbList<ApplicationData_GetLocation>();
  @$core.pragma('dart2js:noInline')
  static ApplicationData_GetLocation getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApplicationData_GetLocation>(create);
  static ApplicationData_GetLocation? _defaultInstance;
}

class ApplicationData_GetVouchers extends $pb.GeneratedMessage {
  factory ApplicationData_GetVouchers() => create();
  ApplicationData_GetVouchers._() : super();
  factory ApplicationData_GetVouchers.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ApplicationData_GetVouchers.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApplicationData.GetVouchers', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ApplicationData_GetVouchers clone() => ApplicationData_GetVouchers()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ApplicationData_GetVouchers copyWith(void Function(ApplicationData_GetVouchers) updates) => super.copyWith((message) => updates(message as ApplicationData_GetVouchers)) as ApplicationData_GetVouchers;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplicationData_GetVouchers create() => ApplicationData_GetVouchers._();
  ApplicationData_GetVouchers createEmptyInstance() => create();
  static $pb.PbList<ApplicationData_GetVouchers> createRepeated() => $pb.PbList<ApplicationData_GetVouchers>();
  @$core.pragma('dart2js:noInline')
  static ApplicationData_GetVouchers getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApplicationData_GetVouchers>(create);
  static ApplicationData_GetVouchers? _defaultInstance;
}

class ApplicationData_GetAvailablePlans extends $pb.GeneratedMessage {
  factory ApplicationData_GetAvailablePlans() => create();
  ApplicationData_GetAvailablePlans._() : super();
  factory ApplicationData_GetAvailablePlans.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ApplicationData_GetAvailablePlans.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApplicationData.GetAvailablePlans', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ApplicationData_GetAvailablePlans clone() => ApplicationData_GetAvailablePlans()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ApplicationData_GetAvailablePlans copyWith(void Function(ApplicationData_GetAvailablePlans) updates) => super.copyWith((message) => updates(message as ApplicationData_GetAvailablePlans)) as ApplicationData_GetAvailablePlans;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplicationData_GetAvailablePlans create() => ApplicationData_GetAvailablePlans._();
  ApplicationData_GetAvailablePlans createEmptyInstance() => create();
  static $pb.PbList<ApplicationData_GetAvailablePlans> createRepeated() => $pb.PbList<ApplicationData_GetAvailablePlans>();
  @$core.pragma('dart2js:noInline')
  static ApplicationData_GetAvailablePlans getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApplicationData_GetAvailablePlans>(create);
  static ApplicationData_GetAvailablePlans? _defaultInstance;
}

class ApplicationData_GetAddAccountsInvites extends $pb.GeneratedMessage {
  factory ApplicationData_GetAddAccountsInvites() => create();
  ApplicationData_GetAddAccountsInvites._() : super();
  factory ApplicationData_GetAddAccountsInvites.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ApplicationData_GetAddAccountsInvites.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApplicationData.GetAddAccountsInvites', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ApplicationData_GetAddAccountsInvites clone() => ApplicationData_GetAddAccountsInvites()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ApplicationData_GetAddAccountsInvites copyWith(void Function(ApplicationData_GetAddAccountsInvites) updates) => super.copyWith((message) => updates(message as ApplicationData_GetAddAccountsInvites)) as ApplicationData_GetAddAccountsInvites;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplicationData_GetAddAccountsInvites create() => ApplicationData_GetAddAccountsInvites._();
  ApplicationData_GetAddAccountsInvites createEmptyInstance() => create();
  static $pb.PbList<ApplicationData_GetAddAccountsInvites> createRepeated() => $pb.PbList<ApplicationData_GetAddAccountsInvites>();
  @$core.pragma('dart2js:noInline')
  static ApplicationData_GetAddAccountsInvites getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApplicationData_GetAddAccountsInvites>(create);
  static ApplicationData_GetAddAccountsInvites? _defaultInstance;
}

class ApplicationData_GetCurrentPlanInfos extends $pb.GeneratedMessage {
  factory ApplicationData_GetCurrentPlanInfos() => create();
  ApplicationData_GetCurrentPlanInfos._() : super();
  factory ApplicationData_GetCurrentPlanInfos.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ApplicationData_GetCurrentPlanInfos.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApplicationData.GetCurrentPlanInfos', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ApplicationData_GetCurrentPlanInfos clone() => ApplicationData_GetCurrentPlanInfos()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ApplicationData_GetCurrentPlanInfos copyWith(void Function(ApplicationData_GetCurrentPlanInfos) updates) => super.copyWith((message) => updates(message as ApplicationData_GetCurrentPlanInfos)) as ApplicationData_GetCurrentPlanInfos;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplicationData_GetCurrentPlanInfos create() => ApplicationData_GetCurrentPlanInfos._();
  ApplicationData_GetCurrentPlanInfos createEmptyInstance() => create();
  static $pb.PbList<ApplicationData_GetCurrentPlanInfos> createRepeated() => $pb.PbList<ApplicationData_GetCurrentPlanInfos>();
  @$core.pragma('dart2js:noInline')
  static ApplicationData_GetCurrentPlanInfos getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApplicationData_GetCurrentPlanInfos>(create);
  static ApplicationData_GetCurrentPlanInfos? _defaultInstance;
}

class ApplicationData_RedeemAdditionalCode extends $pb.GeneratedMessage {
  factory ApplicationData_RedeemAdditionalCode({
    $core.String? inviteCode,
  }) {
    final $result = create();
    if (inviteCode != null) {
      $result.inviteCode = inviteCode;
    }
    return $result;
  }
  ApplicationData_RedeemAdditionalCode._() : super();
  factory ApplicationData_RedeemAdditionalCode.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ApplicationData_RedeemAdditionalCode.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApplicationData.RedeemAdditionalCode', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..aOS(2, _omitFieldNames ? '' : 'inviteCode')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ApplicationData_RedeemAdditionalCode clone() => ApplicationData_RedeemAdditionalCode()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ApplicationData_RedeemAdditionalCode copyWith(void Function(ApplicationData_RedeemAdditionalCode) updates) => super.copyWith((message) => updates(message as ApplicationData_RedeemAdditionalCode)) as ApplicationData_RedeemAdditionalCode;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplicationData_RedeemAdditionalCode create() => ApplicationData_RedeemAdditionalCode._();
  ApplicationData_RedeemAdditionalCode createEmptyInstance() => create();
  static $pb.PbList<ApplicationData_RedeemAdditionalCode> createRepeated() => $pb.PbList<ApplicationData_RedeemAdditionalCode>();
  @$core.pragma('dart2js:noInline')
  static ApplicationData_RedeemAdditionalCode getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApplicationData_RedeemAdditionalCode>(create);
  static ApplicationData_RedeemAdditionalCode? _defaultInstance;

  @$pb.TagNumber(2)
  $core.String get inviteCode => $_getSZ(0);
  @$pb.TagNumber(2)
  set inviteCode($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(2)
  $core.bool hasInviteCode() => $_has(0);
  @$pb.TagNumber(2)
  void clearInviteCode() => clearField(2);
}

class ApplicationData_RemoveAdditionalUser extends $pb.GeneratedMessage {
  factory ApplicationData_RemoveAdditionalUser({
    $fixnum.Int64? userId,
  }) {
    final $result = create();
    if (userId != null) {
      $result.userId = userId;
    }
    return $result;
  }
  ApplicationData_RemoveAdditionalUser._() : super();
  factory ApplicationData_RemoveAdditionalUser.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ApplicationData_RemoveAdditionalUser.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApplicationData.RemoveAdditionalUser', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'userId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ApplicationData_RemoveAdditionalUser clone() => ApplicationData_RemoveAdditionalUser()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ApplicationData_RemoveAdditionalUser copyWith(void Function(ApplicationData_RemoveAdditionalUser) updates) => super.copyWith((message) => updates(message as ApplicationData_RemoveAdditionalUser)) as ApplicationData_RemoveAdditionalUser;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplicationData_RemoveAdditionalUser create() => ApplicationData_RemoveAdditionalUser._();
  ApplicationData_RemoveAdditionalUser createEmptyInstance() => create();
  static $pb.PbList<ApplicationData_RemoveAdditionalUser> createRepeated() => $pb.PbList<ApplicationData_RemoveAdditionalUser>();
  @$core.pragma('dart2js:noInline')
  static ApplicationData_RemoveAdditionalUser getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApplicationData_RemoveAdditionalUser>(create);
  static ApplicationData_RemoveAdditionalUser? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get userId => $_getI64(0);
  @$pb.TagNumber(1)
  set userId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => clearField(1);
}

class ApplicationData_GetPrekeysByUserId extends $pb.GeneratedMessage {
  factory ApplicationData_GetPrekeysByUserId({
    $fixnum.Int64? userId,
  }) {
    final $result = create();
    if (userId != null) {
      $result.userId = userId;
    }
    return $result;
  }
  ApplicationData_GetPrekeysByUserId._() : super();
  factory ApplicationData_GetPrekeysByUserId.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ApplicationData_GetPrekeysByUserId.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApplicationData.GetPrekeysByUserId', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'userId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ApplicationData_GetPrekeysByUserId clone() => ApplicationData_GetPrekeysByUserId()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ApplicationData_GetPrekeysByUserId copyWith(void Function(ApplicationData_GetPrekeysByUserId) updates) => super.copyWith((message) => updates(message as ApplicationData_GetPrekeysByUserId)) as ApplicationData_GetPrekeysByUserId;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplicationData_GetPrekeysByUserId create() => ApplicationData_GetPrekeysByUserId._();
  ApplicationData_GetPrekeysByUserId createEmptyInstance() => create();
  static $pb.PbList<ApplicationData_GetPrekeysByUserId> createRepeated() => $pb.PbList<ApplicationData_GetPrekeysByUserId>();
  @$core.pragma('dart2js:noInline')
  static ApplicationData_GetPrekeysByUserId getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApplicationData_GetPrekeysByUserId>(create);
  static ApplicationData_GetPrekeysByUserId? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get userId => $_getI64(0);
  @$pb.TagNumber(1)
  set userId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => clearField(1);
}

class ApplicationData_GetSignedPreKeyByUserId extends $pb.GeneratedMessage {
  factory ApplicationData_GetSignedPreKeyByUserId({
    $fixnum.Int64? userId,
  }) {
    final $result = create();
    if (userId != null) {
      $result.userId = userId;
    }
    return $result;
  }
  ApplicationData_GetSignedPreKeyByUserId._() : super();
  factory ApplicationData_GetSignedPreKeyByUserId.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ApplicationData_GetSignedPreKeyByUserId.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApplicationData.GetSignedPreKeyByUserId', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'userId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ApplicationData_GetSignedPreKeyByUserId clone() => ApplicationData_GetSignedPreKeyByUserId()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ApplicationData_GetSignedPreKeyByUserId copyWith(void Function(ApplicationData_GetSignedPreKeyByUserId) updates) => super.copyWith((message) => updates(message as ApplicationData_GetSignedPreKeyByUserId)) as ApplicationData_GetSignedPreKeyByUserId;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplicationData_GetSignedPreKeyByUserId create() => ApplicationData_GetSignedPreKeyByUserId._();
  ApplicationData_GetSignedPreKeyByUserId createEmptyInstance() => create();
  static $pb.PbList<ApplicationData_GetSignedPreKeyByUserId> createRepeated() => $pb.PbList<ApplicationData_GetSignedPreKeyByUserId>();
  @$core.pragma('dart2js:noInline')
  static ApplicationData_GetSignedPreKeyByUserId getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApplicationData_GetSignedPreKeyByUserId>(create);
  static ApplicationData_GetSignedPreKeyByUserId? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get userId => $_getI64(0);
  @$pb.TagNumber(1)
  set userId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => clearField(1);
}

class ApplicationData_UpdateSignedPreKey extends $pb.GeneratedMessage {
  factory ApplicationData_UpdateSignedPreKey({
    $fixnum.Int64? signedPrekeyId,
    $core.List<$core.int>? signedPrekey,
    $core.List<$core.int>? signedPrekeySignature,
  }) {
    final $result = create();
    if (signedPrekeyId != null) {
      $result.signedPrekeyId = signedPrekeyId;
    }
    if (signedPrekey != null) {
      $result.signedPrekey = signedPrekey;
    }
    if (signedPrekeySignature != null) {
      $result.signedPrekeySignature = signedPrekeySignature;
    }
    return $result;
  }
  ApplicationData_UpdateSignedPreKey._() : super();
  factory ApplicationData_UpdateSignedPreKey.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ApplicationData_UpdateSignedPreKey.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApplicationData.UpdateSignedPreKey', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'signedPrekeyId')
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'signedPrekey', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(3, _omitFieldNames ? '' : 'signedPrekeySignature', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ApplicationData_UpdateSignedPreKey clone() => ApplicationData_UpdateSignedPreKey()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ApplicationData_UpdateSignedPreKey copyWith(void Function(ApplicationData_UpdateSignedPreKey) updates) => super.copyWith((message) => updates(message as ApplicationData_UpdateSignedPreKey)) as ApplicationData_UpdateSignedPreKey;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplicationData_UpdateSignedPreKey create() => ApplicationData_UpdateSignedPreKey._();
  ApplicationData_UpdateSignedPreKey createEmptyInstance() => create();
  static $pb.PbList<ApplicationData_UpdateSignedPreKey> createRepeated() => $pb.PbList<ApplicationData_UpdateSignedPreKey>();
  @$core.pragma('dart2js:noInline')
  static ApplicationData_UpdateSignedPreKey getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApplicationData_UpdateSignedPreKey>(create);
  static ApplicationData_UpdateSignedPreKey? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get signedPrekeyId => $_getI64(0);
  @$pb.TagNumber(1)
  set signedPrekeyId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSignedPrekeyId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSignedPrekeyId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get signedPrekey => $_getN(1);
  @$pb.TagNumber(2)
  set signedPrekey($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSignedPrekey() => $_has(1);
  @$pb.TagNumber(2)
  void clearSignedPrekey() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get signedPrekeySignature => $_getN(2);
  @$pb.TagNumber(3)
  set signedPrekeySignature($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasSignedPrekeySignature() => $_has(2);
  @$pb.TagNumber(3)
  void clearSignedPrekeySignature() => clearField(3);
}

class ApplicationData_DownloadDone extends $pb.GeneratedMessage {
  factory ApplicationData_DownloadDone({
    $core.List<$core.int>? downloadToken,
  }) {
    final $result = create();
    if (downloadToken != null) {
      $result.downloadToken = downloadToken;
    }
    return $result;
  }
  ApplicationData_DownloadDone._() : super();
  factory ApplicationData_DownloadDone.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ApplicationData_DownloadDone.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApplicationData.DownloadDone', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'downloadToken', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ApplicationData_DownloadDone clone() => ApplicationData_DownloadDone()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ApplicationData_DownloadDone copyWith(void Function(ApplicationData_DownloadDone) updates) => super.copyWith((message) => updates(message as ApplicationData_DownloadDone)) as ApplicationData_DownloadDone;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplicationData_DownloadDone create() => ApplicationData_DownloadDone._();
  ApplicationData_DownloadDone createEmptyInstance() => create();
  static $pb.PbList<ApplicationData_DownloadDone> createRepeated() => $pb.PbList<ApplicationData_DownloadDone>();
  @$core.pragma('dart2js:noInline')
  static ApplicationData_DownloadDone getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApplicationData_DownloadDone>(create);
  static ApplicationData_DownloadDone? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get downloadToken => $_getN(0);
  @$pb.TagNumber(1)
  set downloadToken($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDownloadToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearDownloadToken() => clearField(1);
}

class ApplicationData_ReportUser extends $pb.GeneratedMessage {
  factory ApplicationData_ReportUser({
    $fixnum.Int64? reportedUserId,
    $core.String? reason,
  }) {
    final $result = create();
    if (reportedUserId != null) {
      $result.reportedUserId = reportedUserId;
    }
    if (reason != null) {
      $result.reason = reason;
    }
    return $result;
  }
  ApplicationData_ReportUser._() : super();
  factory ApplicationData_ReportUser.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ApplicationData_ReportUser.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApplicationData.ReportUser', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'reportedUserId')
    ..aOS(2, _omitFieldNames ? '' : 'reason')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ApplicationData_ReportUser clone() => ApplicationData_ReportUser()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ApplicationData_ReportUser copyWith(void Function(ApplicationData_ReportUser) updates) => super.copyWith((message) => updates(message as ApplicationData_ReportUser)) as ApplicationData_ReportUser;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplicationData_ReportUser create() => ApplicationData_ReportUser._();
  ApplicationData_ReportUser createEmptyInstance() => create();
  static $pb.PbList<ApplicationData_ReportUser> createRepeated() => $pb.PbList<ApplicationData_ReportUser>();
  @$core.pragma('dart2js:noInline')
  static ApplicationData_ReportUser getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApplicationData_ReportUser>(create);
  static ApplicationData_ReportUser? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get reportedUserId => $_getI64(0);
  @$pb.TagNumber(1)
  set reportedUserId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasReportedUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearReportedUserId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get reason => $_getSZ(1);
  @$pb.TagNumber(2)
  set reason($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasReason() => $_has(1);
  @$pb.TagNumber(2)
  void clearReason() => clearField(2);
}

class ApplicationData_DeleteAccount extends $pb.GeneratedMessage {
  factory ApplicationData_DeleteAccount() => create();
  ApplicationData_DeleteAccount._() : super();
  factory ApplicationData_DeleteAccount.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ApplicationData_DeleteAccount.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApplicationData.DeleteAccount', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ApplicationData_DeleteAccount clone() => ApplicationData_DeleteAccount()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ApplicationData_DeleteAccount copyWith(void Function(ApplicationData_DeleteAccount) updates) => super.copyWith((message) => updates(message as ApplicationData_DeleteAccount)) as ApplicationData_DeleteAccount;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplicationData_DeleteAccount create() => ApplicationData_DeleteAccount._();
  ApplicationData_DeleteAccount createEmptyInstance() => create();
  static $pb.PbList<ApplicationData_DeleteAccount> createRepeated() => $pb.PbList<ApplicationData_DeleteAccount>();
  @$core.pragma('dart2js:noInline')
  static ApplicationData_DeleteAccount getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApplicationData_DeleteAccount>(create);
  static ApplicationData_DeleteAccount? _defaultInstance;
}

enum ApplicationData_ApplicationData {
  textMessage, 
  getUserByUsername, 
  getPrekeysByUserId, 
  getUserById, 
  updateGoogleFcmToken, 
  getLocation, 
  getCurrentPlanInfos, 
  redeemVoucher, 
  getAvailablePlans, 
  createVoucher, 
  getVouchers, 
  switchtoPayedPlan, 
  getAddaccountsInvites, 
  redeemAdditionalCode, 
  removeAdditionalUser, 
  updatePlanOptions, 
  downloadDone, 
  getSignedPrekeyByUserid, 
  updateSignedPrekey, 
  deleteAccount, 
  reportUser, 
  changeUsername, 
  notSet
}

class ApplicationData extends $pb.GeneratedMessage {
  factory ApplicationData({
    ApplicationData_TextMessage? textMessage,
    ApplicationData_GetUserByUsername? getUserByUsername,
    ApplicationData_GetPrekeysByUserId? getPrekeysByUserId,
    ApplicationData_GetUserById? getUserById,
    ApplicationData_UpdateGoogleFcmToken? updateGoogleFcmToken,
    ApplicationData_GetLocation? getLocation,
    ApplicationData_GetCurrentPlanInfos? getCurrentPlanInfos,
    ApplicationData_RedeemVoucher? redeemVoucher,
    ApplicationData_GetAvailablePlans? getAvailablePlans,
    ApplicationData_CreateVoucher? createVoucher,
    ApplicationData_GetVouchers? getVouchers,
    ApplicationData_SwitchToPayedPlan? switchtoPayedPlan,
    ApplicationData_GetAddAccountsInvites? getAddaccountsInvites,
    ApplicationData_RedeemAdditionalCode? redeemAdditionalCode,
    ApplicationData_RemoveAdditionalUser? removeAdditionalUser,
    ApplicationData_UpdatePlanOptions? updatePlanOptions,
    ApplicationData_DownloadDone? downloadDone,
    ApplicationData_GetSignedPreKeyByUserId? getSignedPrekeyByUserid,
    ApplicationData_UpdateSignedPreKey? updateSignedPrekey,
    ApplicationData_DeleteAccount? deleteAccount,
    ApplicationData_ReportUser? reportUser,
    ApplicationData_ChangeUsername? changeUsername,
  }) {
    final $result = create();
    if (textMessage != null) {
      $result.textMessage = textMessage;
    }
    if (getUserByUsername != null) {
      $result.getUserByUsername = getUserByUsername;
    }
    if (getPrekeysByUserId != null) {
      $result.getPrekeysByUserId = getPrekeysByUserId;
    }
    if (getUserById != null) {
      $result.getUserById = getUserById;
    }
    if (updateGoogleFcmToken != null) {
      $result.updateGoogleFcmToken = updateGoogleFcmToken;
    }
    if (getLocation != null) {
      $result.getLocation = getLocation;
    }
    if (getCurrentPlanInfos != null) {
      $result.getCurrentPlanInfos = getCurrentPlanInfos;
    }
    if (redeemVoucher != null) {
      $result.redeemVoucher = redeemVoucher;
    }
    if (getAvailablePlans != null) {
      $result.getAvailablePlans = getAvailablePlans;
    }
    if (createVoucher != null) {
      $result.createVoucher = createVoucher;
    }
    if (getVouchers != null) {
      $result.getVouchers = getVouchers;
    }
    if (switchtoPayedPlan != null) {
      $result.switchtoPayedPlan = switchtoPayedPlan;
    }
    if (getAddaccountsInvites != null) {
      $result.getAddaccountsInvites = getAddaccountsInvites;
    }
    if (redeemAdditionalCode != null) {
      $result.redeemAdditionalCode = redeemAdditionalCode;
    }
    if (removeAdditionalUser != null) {
      $result.removeAdditionalUser = removeAdditionalUser;
    }
    if (updatePlanOptions != null) {
      $result.updatePlanOptions = updatePlanOptions;
    }
    if (downloadDone != null) {
      $result.downloadDone = downloadDone;
    }
    if (getSignedPrekeyByUserid != null) {
      $result.getSignedPrekeyByUserid = getSignedPrekeyByUserid;
    }
    if (updateSignedPrekey != null) {
      $result.updateSignedPrekey = updateSignedPrekey;
    }
    if (deleteAccount != null) {
      $result.deleteAccount = deleteAccount;
    }
    if (reportUser != null) {
      $result.reportUser = reportUser;
    }
    if (changeUsername != null) {
      $result.changeUsername = changeUsername;
    }
    return $result;
  }
  ApplicationData._() : super();
  factory ApplicationData.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ApplicationData.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, ApplicationData_ApplicationData> _ApplicationData_ApplicationDataByTag = {
    1 : ApplicationData_ApplicationData.textMessage,
    2 : ApplicationData_ApplicationData.getUserByUsername,
    3 : ApplicationData_ApplicationData.getPrekeysByUserId,
    6 : ApplicationData_ApplicationData.getUserById,
    8 : ApplicationData_ApplicationData.updateGoogleFcmToken,
    9 : ApplicationData_ApplicationData.getLocation,
    10 : ApplicationData_ApplicationData.getCurrentPlanInfos,
    11 : ApplicationData_ApplicationData.redeemVoucher,
    12 : ApplicationData_ApplicationData.getAvailablePlans,
    13 : ApplicationData_ApplicationData.createVoucher,
    14 : ApplicationData_ApplicationData.getVouchers,
    15 : ApplicationData_ApplicationData.switchtoPayedPlan,
    16 : ApplicationData_ApplicationData.getAddaccountsInvites,
    17 : ApplicationData_ApplicationData.redeemAdditionalCode,
    18 : ApplicationData_ApplicationData.removeAdditionalUser,
    19 : ApplicationData_ApplicationData.updatePlanOptions,
    20 : ApplicationData_ApplicationData.downloadDone,
    22 : ApplicationData_ApplicationData.getSignedPrekeyByUserid,
    23 : ApplicationData_ApplicationData.updateSignedPrekey,
    24 : ApplicationData_ApplicationData.deleteAccount,
    25 : ApplicationData_ApplicationData.reportUser,
    26 : ApplicationData_ApplicationData.changeUsername,
    0 : ApplicationData_ApplicationData.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApplicationData', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 6, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 22, 23, 24, 25, 26])
    ..aOM<ApplicationData_TextMessage>(1, _omitFieldNames ? '' : 'textMessage', protoName: 'textMessage', subBuilder: ApplicationData_TextMessage.create)
    ..aOM<ApplicationData_GetUserByUsername>(2, _omitFieldNames ? '' : 'getUserByUsername', protoName: 'getUserByUsername', subBuilder: ApplicationData_GetUserByUsername.create)
    ..aOM<ApplicationData_GetPrekeysByUserId>(3, _omitFieldNames ? '' : 'getPrekeysByUserId', protoName: 'getPrekeysByUserId', subBuilder: ApplicationData_GetPrekeysByUserId.create)
    ..aOM<ApplicationData_GetUserById>(6, _omitFieldNames ? '' : 'getUserById', protoName: 'getUserById', subBuilder: ApplicationData_GetUserById.create)
    ..aOM<ApplicationData_UpdateGoogleFcmToken>(8, _omitFieldNames ? '' : 'updateGoogleFcmToken', protoName: 'updateGoogleFcmToken', subBuilder: ApplicationData_UpdateGoogleFcmToken.create)
    ..aOM<ApplicationData_GetLocation>(9, _omitFieldNames ? '' : 'getLocation', protoName: 'getLocation', subBuilder: ApplicationData_GetLocation.create)
    ..aOM<ApplicationData_GetCurrentPlanInfos>(10, _omitFieldNames ? '' : 'getCurrentPlanInfos', protoName: 'getCurrentPlanInfos', subBuilder: ApplicationData_GetCurrentPlanInfos.create)
    ..aOM<ApplicationData_RedeemVoucher>(11, _omitFieldNames ? '' : 'redeemVoucher', protoName: 'redeemVoucher', subBuilder: ApplicationData_RedeemVoucher.create)
    ..aOM<ApplicationData_GetAvailablePlans>(12, _omitFieldNames ? '' : 'getAvailablePlans', protoName: 'getAvailablePlans', subBuilder: ApplicationData_GetAvailablePlans.create)
    ..aOM<ApplicationData_CreateVoucher>(13, _omitFieldNames ? '' : 'createVoucher', protoName: 'createVoucher', subBuilder: ApplicationData_CreateVoucher.create)
    ..aOM<ApplicationData_GetVouchers>(14, _omitFieldNames ? '' : 'getVouchers', protoName: 'getVouchers', subBuilder: ApplicationData_GetVouchers.create)
    ..aOM<ApplicationData_SwitchToPayedPlan>(15, _omitFieldNames ? '' : 'switchtoPayedPlan', protoName: 'switchtoPayedPlan', subBuilder: ApplicationData_SwitchToPayedPlan.create)
    ..aOM<ApplicationData_GetAddAccountsInvites>(16, _omitFieldNames ? '' : 'getAddaccountsInvites', protoName: 'getAddaccountsInvites', subBuilder: ApplicationData_GetAddAccountsInvites.create)
    ..aOM<ApplicationData_RedeemAdditionalCode>(17, _omitFieldNames ? '' : 'redeemAdditionalCode', protoName: 'redeemAdditionalCode', subBuilder: ApplicationData_RedeemAdditionalCode.create)
    ..aOM<ApplicationData_RemoveAdditionalUser>(18, _omitFieldNames ? '' : 'removeAdditionalUser', protoName: 'removeAdditionalUser', subBuilder: ApplicationData_RemoveAdditionalUser.create)
    ..aOM<ApplicationData_UpdatePlanOptions>(19, _omitFieldNames ? '' : 'updatePlanOptions', protoName: 'updatePlanOptions', subBuilder: ApplicationData_UpdatePlanOptions.create)
    ..aOM<ApplicationData_DownloadDone>(20, _omitFieldNames ? '' : 'downloadDone', protoName: 'downloadDone', subBuilder: ApplicationData_DownloadDone.create)
    ..aOM<ApplicationData_GetSignedPreKeyByUserId>(22, _omitFieldNames ? '' : 'getSignedPrekeyByUserid', protoName: 'getSignedPrekeyByUserid', subBuilder: ApplicationData_GetSignedPreKeyByUserId.create)
    ..aOM<ApplicationData_UpdateSignedPreKey>(23, _omitFieldNames ? '' : 'updateSignedPrekey', protoName: 'updateSignedPrekey', subBuilder: ApplicationData_UpdateSignedPreKey.create)
    ..aOM<ApplicationData_DeleteAccount>(24, _omitFieldNames ? '' : 'deleteAccount', protoName: 'deleteAccount', subBuilder: ApplicationData_DeleteAccount.create)
    ..aOM<ApplicationData_ReportUser>(25, _omitFieldNames ? '' : 'reportUser', protoName: 'reportUser', subBuilder: ApplicationData_ReportUser.create)
    ..aOM<ApplicationData_ChangeUsername>(26, _omitFieldNames ? '' : 'changeUsername', protoName: 'changeUsername', subBuilder: ApplicationData_ChangeUsername.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ApplicationData clone() => ApplicationData()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ApplicationData copyWith(void Function(ApplicationData) updates) => super.copyWith((message) => updates(message as ApplicationData)) as ApplicationData;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplicationData create() => ApplicationData._();
  ApplicationData createEmptyInstance() => create();
  static $pb.PbList<ApplicationData> createRepeated() => $pb.PbList<ApplicationData>();
  @$core.pragma('dart2js:noInline')
  static ApplicationData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApplicationData>(create);
  static ApplicationData? _defaultInstance;

  ApplicationData_ApplicationData whichApplicationData() => _ApplicationData_ApplicationDataByTag[$_whichOneof(0)]!;
  void clearApplicationData() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  ApplicationData_TextMessage get textMessage => $_getN(0);
  @$pb.TagNumber(1)
  set textMessage(ApplicationData_TextMessage v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasTextMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearTextMessage() => clearField(1);
  @$pb.TagNumber(1)
  ApplicationData_TextMessage ensureTextMessage() => $_ensure(0);

  @$pb.TagNumber(2)
  ApplicationData_GetUserByUsername get getUserByUsername => $_getN(1);
  @$pb.TagNumber(2)
  set getUserByUsername(ApplicationData_GetUserByUsername v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasGetUserByUsername() => $_has(1);
  @$pb.TagNumber(2)
  void clearGetUserByUsername() => clearField(2);
  @$pb.TagNumber(2)
  ApplicationData_GetUserByUsername ensureGetUserByUsername() => $_ensure(1);

  @$pb.TagNumber(3)
  ApplicationData_GetPrekeysByUserId get getPrekeysByUserId => $_getN(2);
  @$pb.TagNumber(3)
  set getPrekeysByUserId(ApplicationData_GetPrekeysByUserId v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasGetPrekeysByUserId() => $_has(2);
  @$pb.TagNumber(3)
  void clearGetPrekeysByUserId() => clearField(3);
  @$pb.TagNumber(3)
  ApplicationData_GetPrekeysByUserId ensureGetPrekeysByUserId() => $_ensure(2);

  @$pb.TagNumber(6)
  ApplicationData_GetUserById get getUserById => $_getN(3);
  @$pb.TagNumber(6)
  set getUserById(ApplicationData_GetUserById v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasGetUserById() => $_has(3);
  @$pb.TagNumber(6)
  void clearGetUserById() => clearField(6);
  @$pb.TagNumber(6)
  ApplicationData_GetUserById ensureGetUserById() => $_ensure(3);

  @$pb.TagNumber(8)
  ApplicationData_UpdateGoogleFcmToken get updateGoogleFcmToken => $_getN(4);
  @$pb.TagNumber(8)
  set updateGoogleFcmToken(ApplicationData_UpdateGoogleFcmToken v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasUpdateGoogleFcmToken() => $_has(4);
  @$pb.TagNumber(8)
  void clearUpdateGoogleFcmToken() => clearField(8);
  @$pb.TagNumber(8)
  ApplicationData_UpdateGoogleFcmToken ensureUpdateGoogleFcmToken() => $_ensure(4);

  @$pb.TagNumber(9)
  ApplicationData_GetLocation get getLocation => $_getN(5);
  @$pb.TagNumber(9)
  set getLocation(ApplicationData_GetLocation v) { setField(9, v); }
  @$pb.TagNumber(9)
  $core.bool hasGetLocation() => $_has(5);
  @$pb.TagNumber(9)
  void clearGetLocation() => clearField(9);
  @$pb.TagNumber(9)
  ApplicationData_GetLocation ensureGetLocation() => $_ensure(5);

  @$pb.TagNumber(10)
  ApplicationData_GetCurrentPlanInfos get getCurrentPlanInfos => $_getN(6);
  @$pb.TagNumber(10)
  set getCurrentPlanInfos(ApplicationData_GetCurrentPlanInfos v) { setField(10, v); }
  @$pb.TagNumber(10)
  $core.bool hasGetCurrentPlanInfos() => $_has(6);
  @$pb.TagNumber(10)
  void clearGetCurrentPlanInfos() => clearField(10);
  @$pb.TagNumber(10)
  ApplicationData_GetCurrentPlanInfos ensureGetCurrentPlanInfos() => $_ensure(6);

  @$pb.TagNumber(11)
  ApplicationData_RedeemVoucher get redeemVoucher => $_getN(7);
  @$pb.TagNumber(11)
  set redeemVoucher(ApplicationData_RedeemVoucher v) { setField(11, v); }
  @$pb.TagNumber(11)
  $core.bool hasRedeemVoucher() => $_has(7);
  @$pb.TagNumber(11)
  void clearRedeemVoucher() => clearField(11);
  @$pb.TagNumber(11)
  ApplicationData_RedeemVoucher ensureRedeemVoucher() => $_ensure(7);

  @$pb.TagNumber(12)
  ApplicationData_GetAvailablePlans get getAvailablePlans => $_getN(8);
  @$pb.TagNumber(12)
  set getAvailablePlans(ApplicationData_GetAvailablePlans v) { setField(12, v); }
  @$pb.TagNumber(12)
  $core.bool hasGetAvailablePlans() => $_has(8);
  @$pb.TagNumber(12)
  void clearGetAvailablePlans() => clearField(12);
  @$pb.TagNumber(12)
  ApplicationData_GetAvailablePlans ensureGetAvailablePlans() => $_ensure(8);

  @$pb.TagNumber(13)
  ApplicationData_CreateVoucher get createVoucher => $_getN(9);
  @$pb.TagNumber(13)
  set createVoucher(ApplicationData_CreateVoucher v) { setField(13, v); }
  @$pb.TagNumber(13)
  $core.bool hasCreateVoucher() => $_has(9);
  @$pb.TagNumber(13)
  void clearCreateVoucher() => clearField(13);
  @$pb.TagNumber(13)
  ApplicationData_CreateVoucher ensureCreateVoucher() => $_ensure(9);

  @$pb.TagNumber(14)
  ApplicationData_GetVouchers get getVouchers => $_getN(10);
  @$pb.TagNumber(14)
  set getVouchers(ApplicationData_GetVouchers v) { setField(14, v); }
  @$pb.TagNumber(14)
  $core.bool hasGetVouchers() => $_has(10);
  @$pb.TagNumber(14)
  void clearGetVouchers() => clearField(14);
  @$pb.TagNumber(14)
  ApplicationData_GetVouchers ensureGetVouchers() => $_ensure(10);

  @$pb.TagNumber(15)
  ApplicationData_SwitchToPayedPlan get switchtoPayedPlan => $_getN(11);
  @$pb.TagNumber(15)
  set switchtoPayedPlan(ApplicationData_SwitchToPayedPlan v) { setField(15, v); }
  @$pb.TagNumber(15)
  $core.bool hasSwitchtoPayedPlan() => $_has(11);
  @$pb.TagNumber(15)
  void clearSwitchtoPayedPlan() => clearField(15);
  @$pb.TagNumber(15)
  ApplicationData_SwitchToPayedPlan ensureSwitchtoPayedPlan() => $_ensure(11);

  @$pb.TagNumber(16)
  ApplicationData_GetAddAccountsInvites get getAddaccountsInvites => $_getN(12);
  @$pb.TagNumber(16)
  set getAddaccountsInvites(ApplicationData_GetAddAccountsInvites v) { setField(16, v); }
  @$pb.TagNumber(16)
  $core.bool hasGetAddaccountsInvites() => $_has(12);
  @$pb.TagNumber(16)
  void clearGetAddaccountsInvites() => clearField(16);
  @$pb.TagNumber(16)
  ApplicationData_GetAddAccountsInvites ensureGetAddaccountsInvites() => $_ensure(12);

  @$pb.TagNumber(17)
  ApplicationData_RedeemAdditionalCode get redeemAdditionalCode => $_getN(13);
  @$pb.TagNumber(17)
  set redeemAdditionalCode(ApplicationData_RedeemAdditionalCode v) { setField(17, v); }
  @$pb.TagNumber(17)
  $core.bool hasRedeemAdditionalCode() => $_has(13);
  @$pb.TagNumber(17)
  void clearRedeemAdditionalCode() => clearField(17);
  @$pb.TagNumber(17)
  ApplicationData_RedeemAdditionalCode ensureRedeemAdditionalCode() => $_ensure(13);

  @$pb.TagNumber(18)
  ApplicationData_RemoveAdditionalUser get removeAdditionalUser => $_getN(14);
  @$pb.TagNumber(18)
  set removeAdditionalUser(ApplicationData_RemoveAdditionalUser v) { setField(18, v); }
  @$pb.TagNumber(18)
  $core.bool hasRemoveAdditionalUser() => $_has(14);
  @$pb.TagNumber(18)
  void clearRemoveAdditionalUser() => clearField(18);
  @$pb.TagNumber(18)
  ApplicationData_RemoveAdditionalUser ensureRemoveAdditionalUser() => $_ensure(14);

  @$pb.TagNumber(19)
  ApplicationData_UpdatePlanOptions get updatePlanOptions => $_getN(15);
  @$pb.TagNumber(19)
  set updatePlanOptions(ApplicationData_UpdatePlanOptions v) { setField(19, v); }
  @$pb.TagNumber(19)
  $core.bool hasUpdatePlanOptions() => $_has(15);
  @$pb.TagNumber(19)
  void clearUpdatePlanOptions() => clearField(19);
  @$pb.TagNumber(19)
  ApplicationData_UpdatePlanOptions ensureUpdatePlanOptions() => $_ensure(15);

  @$pb.TagNumber(20)
  ApplicationData_DownloadDone get downloadDone => $_getN(16);
  @$pb.TagNumber(20)
  set downloadDone(ApplicationData_DownloadDone v) { setField(20, v); }
  @$pb.TagNumber(20)
  $core.bool hasDownloadDone() => $_has(16);
  @$pb.TagNumber(20)
  void clearDownloadDone() => clearField(20);
  @$pb.TagNumber(20)
  ApplicationData_DownloadDone ensureDownloadDone() => $_ensure(16);

  @$pb.TagNumber(22)
  ApplicationData_GetSignedPreKeyByUserId get getSignedPrekeyByUserid => $_getN(17);
  @$pb.TagNumber(22)
  set getSignedPrekeyByUserid(ApplicationData_GetSignedPreKeyByUserId v) { setField(22, v); }
  @$pb.TagNumber(22)
  $core.bool hasGetSignedPrekeyByUserid() => $_has(17);
  @$pb.TagNumber(22)
  void clearGetSignedPrekeyByUserid() => clearField(22);
  @$pb.TagNumber(22)
  ApplicationData_GetSignedPreKeyByUserId ensureGetSignedPrekeyByUserid() => $_ensure(17);

  @$pb.TagNumber(23)
  ApplicationData_UpdateSignedPreKey get updateSignedPrekey => $_getN(18);
  @$pb.TagNumber(23)
  set updateSignedPrekey(ApplicationData_UpdateSignedPreKey v) { setField(23, v); }
  @$pb.TagNumber(23)
  $core.bool hasUpdateSignedPrekey() => $_has(18);
  @$pb.TagNumber(23)
  void clearUpdateSignedPrekey() => clearField(23);
  @$pb.TagNumber(23)
  ApplicationData_UpdateSignedPreKey ensureUpdateSignedPrekey() => $_ensure(18);

  @$pb.TagNumber(24)
  ApplicationData_DeleteAccount get deleteAccount => $_getN(19);
  @$pb.TagNumber(24)
  set deleteAccount(ApplicationData_DeleteAccount v) { setField(24, v); }
  @$pb.TagNumber(24)
  $core.bool hasDeleteAccount() => $_has(19);
  @$pb.TagNumber(24)
  void clearDeleteAccount() => clearField(24);
  @$pb.TagNumber(24)
  ApplicationData_DeleteAccount ensureDeleteAccount() => $_ensure(19);

  @$pb.TagNumber(25)
  ApplicationData_ReportUser get reportUser => $_getN(20);
  @$pb.TagNumber(25)
  set reportUser(ApplicationData_ReportUser v) { setField(25, v); }
  @$pb.TagNumber(25)
  $core.bool hasReportUser() => $_has(20);
  @$pb.TagNumber(25)
  void clearReportUser() => clearField(25);
  @$pb.TagNumber(25)
  ApplicationData_ReportUser ensureReportUser() => $_ensure(20);

  @$pb.TagNumber(26)
  ApplicationData_ChangeUsername get changeUsername => $_getN(21);
  @$pb.TagNumber(26)
  set changeUsername(ApplicationData_ChangeUsername v) { setField(26, v); }
  @$pb.TagNumber(26)
  $core.bool hasChangeUsername() => $_has(21);
  @$pb.TagNumber(26)
  void clearChangeUsername() => clearField(26);
  @$pb.TagNumber(26)
  ApplicationData_ChangeUsername ensureChangeUsername() => $_ensure(21);
}

class Response_PreKey extends $pb.GeneratedMessage {
  factory Response_PreKey({
    $fixnum.Int64? id,
    $core.List<$core.int>? prekey,
  }) {
    final $result = create();
    if (id != null) {
      $result.id = id;
    }
    if (prekey != null) {
      $result.prekey = prekey;
    }
    return $result;
  }
  Response_PreKey._() : super();
  factory Response_PreKey.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Response_PreKey.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Response.PreKey', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'prekey', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Response_PreKey clone() => Response_PreKey()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Response_PreKey copyWith(void Function(Response_PreKey) updates) => super.copyWith((message) => updates(message as Response_PreKey)) as Response_PreKey;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_PreKey create() => Response_PreKey._();
  Response_PreKey createEmptyInstance() => create();
  static $pb.PbList<Response_PreKey> createRepeated() => $pb.PbList<Response_PreKey>();
  @$core.pragma('dart2js:noInline')
  static Response_PreKey getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Response_PreKey>(create);
  static Response_PreKey? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get prekey => $_getN(1);
  @$pb.TagNumber(2)
  set prekey($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasPrekey() => $_has(1);
  @$pb.TagNumber(2)
  void clearPrekey() => clearField(2);
}

class Response_Prekeys extends $pb.GeneratedMessage {
  factory Response_Prekeys({
    $core.Iterable<Response_PreKey>? prekeys,
  }) {
    final $result = create();
    if (prekeys != null) {
      $result.prekeys.addAll(prekeys);
    }
    return $result;
  }
  Response_Prekeys._() : super();
  factory Response_Prekeys.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Response_Prekeys.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Response.Prekeys', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..pc<Response_PreKey>(1, _omitFieldNames ? '' : 'prekeys', $pb.PbFieldType.PM, subBuilder: Response_PreKey.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Response_Prekeys clone() => Response_Prekeys()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Response_Prekeys copyWith(void Function(Response_Prekeys) updates) => super.copyWith((message) => updates(message as Response_Prekeys)) as Response_Prekeys;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_Prekeys create() => Response_Prekeys._();
  Response_Prekeys createEmptyInstance() => create();
  static $pb.PbList<Response_Prekeys> createRepeated() => $pb.PbList<Response_Prekeys>();
  @$core.pragma('dart2js:noInline')
  static Response_Prekeys getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Response_Prekeys>(create);
  static Response_Prekeys? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Response_PreKey> get prekeys => $_getList(0);
}

enum Response_Ok_Ok {
  none, 
  prekeys, 
  notSet
}

class Response_Ok extends $pb.GeneratedMessage {
  factory Response_Ok({
    $core.bool? none,
    Response_Prekeys? prekeys,
  }) {
    final $result = create();
    if (none != null) {
      $result.none = none;
    }
    if (prekeys != null) {
      $result.prekeys = prekeys;
    }
    return $result;
  }
  Response_Ok._() : super();
  factory Response_Ok.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Response_Ok.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, Response_Ok_Ok> _Response_Ok_OkByTag = {
    1 : Response_Ok_Ok.none,
    2 : Response_Ok_Ok.prekeys,
    0 : Response_Ok_Ok.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Response.Ok', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOB(1, _omitFieldNames ? '' : 'None', protoName: 'None')
    ..aOM<Response_Prekeys>(2, _omitFieldNames ? '' : 'prekeys', subBuilder: Response_Prekeys.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Response_Ok clone() => Response_Ok()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Response_Ok copyWith(void Function(Response_Ok) updates) => super.copyWith((message) => updates(message as Response_Ok)) as Response_Ok;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_Ok create() => Response_Ok._();
  Response_Ok createEmptyInstance() => create();
  static $pb.PbList<Response_Ok> createRepeated() => $pb.PbList<Response_Ok>();
  @$core.pragma('dart2js:noInline')
  static Response_Ok getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Response_Ok>(create);
  static Response_Ok? _defaultInstance;

  Response_Ok_Ok whichOk() => _Response_Ok_OkByTag[$_whichOneof(0)]!;
  void clearOk() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.bool get none => $_getBF(0);
  @$pb.TagNumber(1)
  set none($core.bool v) { $_setBool(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasNone() => $_has(0);
  @$pb.TagNumber(1)
  void clearNone() => clearField(1);

  @$pb.TagNumber(2)
  Response_Prekeys get prekeys => $_getN(1);
  @$pb.TagNumber(2)
  set prekeys(Response_Prekeys v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasPrekeys() => $_has(1);
  @$pb.TagNumber(2)
  void clearPrekeys() => clearField(2);
  @$pb.TagNumber(2)
  Response_Prekeys ensurePrekeys() => $_ensure(1);
}

enum Response_Response {
  ok, 
  error, 
  notSet
}

class Response extends $pb.GeneratedMessage {
  factory Response({
    Response_Ok? ok,
    $0.ErrorCode? error,
  }) {
    final $result = create();
    if (ok != null) {
      $result.ok = ok;
    }
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  Response._() : super();
  factory Response.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Response.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, Response_Response> _Response_ResponseByTag = {
    1 : Response_Response.ok,
    2 : Response_Response.error,
    0 : Response_Response.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Response', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<Response_Ok>(1, _omitFieldNames ? '' : 'ok', subBuilder: Response_Ok.create)
    ..e<$0.ErrorCode>(2, _omitFieldNames ? '' : 'error', $pb.PbFieldType.OE, defaultOrMaker: $0.ErrorCode.Unknown, valueOf: $0.ErrorCode.valueOf, enumValues: $0.ErrorCode.values)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Response clone() => Response()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Response copyWith(void Function(Response) updates) => super.copyWith((message) => updates(message as Response)) as Response;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response create() => Response._();
  Response createEmptyInstance() => create();
  static $pb.PbList<Response> createRepeated() => $pb.PbList<Response>();
  @$core.pragma('dart2js:noInline')
  static Response getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Response>(create);
  static Response? _defaultInstance;

  Response_Response whichResponse() => _Response_ResponseByTag[$_whichOneof(0)]!;
  void clearResponse() => clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  Response_Ok get ok => $_getN(0);
  @$pb.TagNumber(1)
  set ok(Response_Ok v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => clearField(1);
  @$pb.TagNumber(1)
  Response_Ok ensureOk() => $_ensure(0);

  @$pb.TagNumber(2)
  $0.ErrorCode get error => $_getN(1);
  @$pb.TagNumber(2)
  set error($0.ErrorCode v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => clearField(2);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
