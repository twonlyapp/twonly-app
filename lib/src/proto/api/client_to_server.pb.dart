//
//  Generated code. Do not modify.
//  source: api/client_to_server.proto
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
}

class Handshake_GetChallenge extends $pb.GeneratedMessage {
  factory Handshake_GetChallenge() => create();
  Handshake_GetChallenge._() : super();
  factory Handshake_GetChallenge.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Handshake_GetChallenge.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Handshake.GetChallenge', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Handshake_GetChallenge clone() => Handshake_GetChallenge()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Handshake_GetChallenge copyWith(void Function(Handshake_GetChallenge) updates) => super.copyWith((message) => updates(message as Handshake_GetChallenge)) as Handshake_GetChallenge;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Handshake_GetChallenge create() => Handshake_GetChallenge._();
  Handshake_GetChallenge createEmptyInstance() => create();
  static $pb.PbList<Handshake_GetChallenge> createRepeated() => $pb.PbList<Handshake_GetChallenge>();
  @$core.pragma('dart2js:noInline')
  static Handshake_GetChallenge getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Handshake_GetChallenge>(create);
  static Handshake_GetChallenge? _defaultInstance;
}

class Handshake_OpenSession extends $pb.GeneratedMessage {
  factory Handshake_OpenSession({
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
  Handshake_OpenSession._() : super();
  factory Handshake_OpenSession.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Handshake_OpenSession.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Handshake.OpenSession', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'userId')
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'response', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Handshake_OpenSession clone() => Handshake_OpenSession()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Handshake_OpenSession copyWith(void Function(Handshake_OpenSession) updates) => super.copyWith((message) => updates(message as Handshake_OpenSession)) as Handshake_OpenSession;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Handshake_OpenSession create() => Handshake_OpenSession._();
  Handshake_OpenSession createEmptyInstance() => create();
  static $pb.PbList<Handshake_OpenSession> createRepeated() => $pb.PbList<Handshake_OpenSession>();
  @$core.pragma('dart2js:noInline')
  static Handshake_OpenSession getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Handshake_OpenSession>(create);
  static Handshake_OpenSession? _defaultInstance;

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

enum Handshake_Handshake {
  register, 
  getchallenge, 
  opensession, 
  notSet
}

class Handshake extends $pb.GeneratedMessage {
  factory Handshake({
    Handshake_Register? register,
    Handshake_GetChallenge? getchallenge,
    Handshake_OpenSession? opensession,
  }) {
    final $result = create();
    if (register != null) {
      $result.register = register;
    }
    if (getchallenge != null) {
      $result.getchallenge = getchallenge;
    }
    if (opensession != null) {
      $result.opensession = opensession;
    }
    return $result;
  }
  Handshake._() : super();
  factory Handshake.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Handshake.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, Handshake_Handshake> _Handshake_HandshakeByTag = {
    1 : Handshake_Handshake.register,
    2 : Handshake_Handshake.getchallenge,
    3 : Handshake_Handshake.opensession,
    0 : Handshake_Handshake.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Handshake', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..oo(0, [1, 2, 3])
    ..aOM<Handshake_Register>(1, _omitFieldNames ? '' : 'register', subBuilder: Handshake_Register.create)
    ..aOM<Handshake_GetChallenge>(2, _omitFieldNames ? '' : 'getchallenge', subBuilder: Handshake_GetChallenge.create)
    ..aOM<Handshake_OpenSession>(3, _omitFieldNames ? '' : 'opensession', subBuilder: Handshake_OpenSession.create)
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
  Handshake_GetChallenge get getchallenge => $_getN(1);
  @$pb.TagNumber(2)
  set getchallenge(Handshake_GetChallenge v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasGetchallenge() => $_has(1);
  @$pb.TagNumber(2)
  void clearGetchallenge() => clearField(2);
  @$pb.TagNumber(2)
  Handshake_GetChallenge ensureGetchallenge() => $_ensure(1);

  @$pb.TagNumber(3)
  Handshake_OpenSession get opensession => $_getN(2);
  @$pb.TagNumber(3)
  set opensession(Handshake_OpenSession v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasOpensession() => $_has(2);
  @$pb.TagNumber(3)
  void clearOpensession() => clearField(3);
  @$pb.TagNumber(3)
  Handshake_OpenSession ensureOpensession() => $_ensure(2);
}

class ApplicationData_TextMessage extends $pb.GeneratedMessage {
  factory ApplicationData_TextMessage({
    $fixnum.Int64? userId,
    $core.List<$core.int>? body,
  }) {
    final $result = create();
    if (userId != null) {
      $result.userId = userId;
    }
    if (body != null) {
      $result.body = body;
    }
    return $result;
  }
  ApplicationData_TextMessage._() : super();
  factory ApplicationData_TextMessage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ApplicationData_TextMessage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApplicationData.TextMessage', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'userId')
    ..a<$core.List<$core.int>>(3, _omitFieldNames ? '' : 'body', $pb.PbFieldType.OY)
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

class ApplicationData_GetUploadToken extends $pb.GeneratedMessage {
  factory ApplicationData_GetUploadToken({
    $core.int? len,
  }) {
    final $result = create();
    if (len != null) {
      $result.len = len;
    }
    return $result;
  }
  ApplicationData_GetUploadToken._() : super();
  factory ApplicationData_GetUploadToken.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ApplicationData_GetUploadToken.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApplicationData.GetUploadToken', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..a<$core.int>(1, _omitFieldNames ? '' : 'len', $pb.PbFieldType.OU3)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ApplicationData_GetUploadToken clone() => ApplicationData_GetUploadToken()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ApplicationData_GetUploadToken copyWith(void Function(ApplicationData_GetUploadToken) updates) => super.copyWith((message) => updates(message as ApplicationData_GetUploadToken)) as ApplicationData_GetUploadToken;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplicationData_GetUploadToken create() => ApplicationData_GetUploadToken._();
  ApplicationData_GetUploadToken createEmptyInstance() => create();
  static $pb.PbList<ApplicationData_GetUploadToken> createRepeated() => $pb.PbList<ApplicationData_GetUploadToken>();
  @$core.pragma('dart2js:noInline')
  static ApplicationData_GetUploadToken getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApplicationData_GetUploadToken>(create);
  static ApplicationData_GetUploadToken? _defaultInstance;

  @$pb.TagNumber(1)
  $core.int get len => $_getIZ(0);
  @$pb.TagNumber(1)
  set len($core.int v) { $_setUnsignedInt32(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasLen() => $_has(0);
  @$pb.TagNumber(1)
  void clearLen() => clearField(1);
}

class ApplicationData_UploadData extends $pb.GeneratedMessage {
  factory ApplicationData_UploadData({
    $core.List<$core.int>? uploadToken,
    $core.int? offset,
    $core.List<$core.int>? data,
  }) {
    final $result = create();
    if (uploadToken != null) {
      $result.uploadToken = uploadToken;
    }
    if (offset != null) {
      $result.offset = offset;
    }
    if (data != null) {
      $result.data = data;
    }
    return $result;
  }
  ApplicationData_UploadData._() : super();
  factory ApplicationData_UploadData.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ApplicationData_UploadData.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApplicationData.UploadData', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'uploadToken', $pb.PbFieldType.OY)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'offset', $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(3, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ApplicationData_UploadData clone() => ApplicationData_UploadData()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ApplicationData_UploadData copyWith(void Function(ApplicationData_UploadData) updates) => super.copyWith((message) => updates(message as ApplicationData_UploadData)) as ApplicationData_UploadData;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ApplicationData_UploadData create() => ApplicationData_UploadData._();
  ApplicationData_UploadData createEmptyInstance() => create();
  static $pb.PbList<ApplicationData_UploadData> createRepeated() => $pb.PbList<ApplicationData_UploadData>();
  @$core.pragma('dart2js:noInline')
  static ApplicationData_UploadData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ApplicationData_UploadData>(create);
  static ApplicationData_UploadData? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get uploadToken => $_getN(0);
  @$pb.TagNumber(1)
  set uploadToken($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUploadToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearUploadToken() => clearField(1);

  @$pb.TagNumber(2)
  $core.int get offset => $_getIZ(1);
  @$pb.TagNumber(2)
  set offset($core.int v) { $_setUnsignedInt32(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasOffset() => $_has(1);
  @$pb.TagNumber(2)
  void clearOffset() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get data => $_getN(2);
  @$pb.TagNumber(3)
  set data($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasData() => $_has(2);
  @$pb.TagNumber(3)
  void clearData() => clearField(3);
}

enum ApplicationData_ApplicationData {
  textmessage, 
  getuserbyusername, 
  getprekeysbyuserid, 
  getuploadtoken, 
  uploaddata, 
  getuserbyid, 
  notSet
}

class ApplicationData extends $pb.GeneratedMessage {
  factory ApplicationData({
    ApplicationData_TextMessage? textmessage,
    ApplicationData_GetUserByUsername? getuserbyusername,
    ApplicationData_GetPrekeysByUserId? getprekeysbyuserid,
    ApplicationData_GetUploadToken? getuploadtoken,
    ApplicationData_UploadData? uploaddata,
    ApplicationData_GetUserById? getuserbyid,
  }) {
    final $result = create();
    if (textmessage != null) {
      $result.textmessage = textmessage;
    }
    if (getuserbyusername != null) {
      $result.getuserbyusername = getuserbyusername;
    }
    if (getprekeysbyuserid != null) {
      $result.getprekeysbyuserid = getprekeysbyuserid;
    }
    if (getuploadtoken != null) {
      $result.getuploadtoken = getuploadtoken;
    }
    if (uploaddata != null) {
      $result.uploaddata = uploaddata;
    }
    if (getuserbyid != null) {
      $result.getuserbyid = getuserbyid;
    }
    return $result;
  }
  ApplicationData._() : super();
  factory ApplicationData.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ApplicationData.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, ApplicationData_ApplicationData> _ApplicationData_ApplicationDataByTag = {
    1 : ApplicationData_ApplicationData.textmessage,
    2 : ApplicationData_ApplicationData.getuserbyusername,
    3 : ApplicationData_ApplicationData.getprekeysbyuserid,
    4 : ApplicationData_ApplicationData.getuploadtoken,
    5 : ApplicationData_ApplicationData.uploaddata,
    6 : ApplicationData_ApplicationData.getuserbyid,
    0 : ApplicationData_ApplicationData.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ApplicationData', package: const $pb.PackageName(_omitMessageNames ? '' : 'client_to_server'), createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6])
    ..aOM<ApplicationData_TextMessage>(1, _omitFieldNames ? '' : 'textmessage', subBuilder: ApplicationData_TextMessage.create)
    ..aOM<ApplicationData_GetUserByUsername>(2, _omitFieldNames ? '' : 'getuserbyusername', subBuilder: ApplicationData_GetUserByUsername.create)
    ..aOM<ApplicationData_GetPrekeysByUserId>(3, _omitFieldNames ? '' : 'getprekeysbyuserid', subBuilder: ApplicationData_GetPrekeysByUserId.create)
    ..aOM<ApplicationData_GetUploadToken>(4, _omitFieldNames ? '' : 'getuploadtoken', subBuilder: ApplicationData_GetUploadToken.create)
    ..aOM<ApplicationData_UploadData>(5, _omitFieldNames ? '' : 'uploaddata', subBuilder: ApplicationData_UploadData.create)
    ..aOM<ApplicationData_GetUserById>(6, _omitFieldNames ? '' : 'getuserbyid', subBuilder: ApplicationData_GetUserById.create)
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
  ApplicationData_TextMessage get textmessage => $_getN(0);
  @$pb.TagNumber(1)
  set textmessage(ApplicationData_TextMessage v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasTextmessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearTextmessage() => clearField(1);
  @$pb.TagNumber(1)
  ApplicationData_TextMessage ensureTextmessage() => $_ensure(0);

  @$pb.TagNumber(2)
  ApplicationData_GetUserByUsername get getuserbyusername => $_getN(1);
  @$pb.TagNumber(2)
  set getuserbyusername(ApplicationData_GetUserByUsername v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasGetuserbyusername() => $_has(1);
  @$pb.TagNumber(2)
  void clearGetuserbyusername() => clearField(2);
  @$pb.TagNumber(2)
  ApplicationData_GetUserByUsername ensureGetuserbyusername() => $_ensure(1);

  @$pb.TagNumber(3)
  ApplicationData_GetPrekeysByUserId get getprekeysbyuserid => $_getN(2);
  @$pb.TagNumber(3)
  set getprekeysbyuserid(ApplicationData_GetPrekeysByUserId v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasGetprekeysbyuserid() => $_has(2);
  @$pb.TagNumber(3)
  void clearGetprekeysbyuserid() => clearField(3);
  @$pb.TagNumber(3)
  ApplicationData_GetPrekeysByUserId ensureGetprekeysbyuserid() => $_ensure(2);

  @$pb.TagNumber(4)
  ApplicationData_GetUploadToken get getuploadtoken => $_getN(3);
  @$pb.TagNumber(4)
  set getuploadtoken(ApplicationData_GetUploadToken v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasGetuploadtoken() => $_has(3);
  @$pb.TagNumber(4)
  void clearGetuploadtoken() => clearField(4);
  @$pb.TagNumber(4)
  ApplicationData_GetUploadToken ensureGetuploadtoken() => $_ensure(3);

  @$pb.TagNumber(5)
  ApplicationData_UploadData get uploaddata => $_getN(4);
  @$pb.TagNumber(5)
  set uploaddata(ApplicationData_UploadData v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasUploaddata() => $_has(4);
  @$pb.TagNumber(5)
  void clearUploaddata() => clearField(5);
  @$pb.TagNumber(5)
  ApplicationData_UploadData ensureUploaddata() => $_ensure(4);

  @$pb.TagNumber(6)
  ApplicationData_GetUserById get getuserbyid => $_getN(5);
  @$pb.TagNumber(6)
  set getuserbyid(ApplicationData_GetUserById v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasGetuserbyid() => $_has(5);
  @$pb.TagNumber(6)
  void clearGetuserbyid() => clearField(6);
  @$pb.TagNumber(6)
  ApplicationData_GetUserById ensureGetuserbyid() => $_ensure(5);
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
