//
//  Generated code. Do not modify.
//  source: api/server_to_client.proto
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

enum ServerToClient_V {
  v0, 
  notSet
}

class ServerToClient extends $pb.GeneratedMessage {
  factory ServerToClient({
    V0? v0,
  }) {
    final $result = create();
    if (v0 != null) {
      $result.v0 = v0;
    }
    return $result;
  }
  ServerToClient._() : super();
  factory ServerToClient.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory ServerToClient.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, ServerToClient_V> _ServerToClient_VByTag = {
    1 : ServerToClient_V.v0,
    0 : ServerToClient_V.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'ServerToClient', package: const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'), createEmptyInstance: create)
    ..oo(0, [1])
    ..aOM<V0>(1, _omitFieldNames ? '' : 'V0', protoName: 'V0', subBuilder: V0.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  ServerToClient clone() => ServerToClient()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  ServerToClient copyWith(void Function(ServerToClient) updates) => super.copyWith((message) => updates(message as ServerToClient)) as ServerToClient;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ServerToClient create() => ServerToClient._();
  ServerToClient createEmptyInstance() => create();
  static $pb.PbList<ServerToClient> createRepeated() => $pb.PbList<ServerToClient>();
  @$core.pragma('dart2js:noInline')
  static ServerToClient getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<ServerToClient>(create);
  static ServerToClient? _defaultInstance;

  ServerToClient_V whichV() => _ServerToClient_VByTag[$_whichOneof(0)]!;
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
  response, 
  newMessage, 
  requestNewPreKeys, 
  downloaddata, 
  error, 
  notSet
}

class V0 extends $pb.GeneratedMessage {
  factory V0({
    $fixnum.Int64? seq,
    Response? response,
    NewMessage? newMessage,
    $core.bool? requestNewPreKeys,
    DownloadData? downloaddata,
    $0.ErrorCode? error,
  }) {
    final $result = create();
    if (seq != null) {
      $result.seq = seq;
    }
    if (response != null) {
      $result.response = response;
    }
    if (newMessage != null) {
      $result.newMessage = newMessage;
    }
    if (requestNewPreKeys != null) {
      $result.requestNewPreKeys = requestNewPreKeys;
    }
    if (downloaddata != null) {
      $result.downloaddata = downloaddata;
    }
    if (error != null) {
      $result.error = error;
    }
    return $result;
  }
  V0._() : super();
  factory V0.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory V0.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, V0_Kind> _V0_KindByTag = {
    2 : V0_Kind.response,
    3 : V0_Kind.newMessage,
    4 : V0_Kind.requestNewPreKeys,
    5 : V0_Kind.downloaddata,
    6 : V0_Kind.error,
    0 : V0_Kind.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'V0', package: const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'), createEmptyInstance: create)
    ..oo(0, [2, 3, 4, 5, 6])
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'seq', $pb.PbFieldType.OU6, defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<Response>(2, _omitFieldNames ? '' : 'response', subBuilder: Response.create)
    ..aOM<NewMessage>(3, _omitFieldNames ? '' : 'newMessage', protoName: 'newMessage', subBuilder: NewMessage.create)
    ..aOB(4, _omitFieldNames ? '' : 'RequestNewPreKeys', protoName: 'RequestNewPreKeys')
    ..aOM<DownloadData>(5, _omitFieldNames ? '' : 'downloaddata', subBuilder: DownloadData.create)
    ..e<$0.ErrorCode>(6, _omitFieldNames ? '' : 'error', $pb.PbFieldType.OE, defaultOrMaker: $0.ErrorCode.Unknown, valueOf: $0.ErrorCode.valueOf, enumValues: $0.ErrorCode.values)
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
  Response get response => $_getN(1);
  @$pb.TagNumber(2)
  set response(Response v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasResponse() => $_has(1);
  @$pb.TagNumber(2)
  void clearResponse() => clearField(2);
  @$pb.TagNumber(2)
  Response ensureResponse() => $_ensure(1);

  @$pb.TagNumber(3)
  NewMessage get newMessage => $_getN(2);
  @$pb.TagNumber(3)
  set newMessage(NewMessage v) { setField(3, v); }
  @$pb.TagNumber(3)
  $core.bool hasNewMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearNewMessage() => clearField(3);
  @$pb.TagNumber(3)
  NewMessage ensureNewMessage() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.bool get requestNewPreKeys => $_getBF(3);
  @$pb.TagNumber(4)
  set requestNewPreKeys($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasRequestNewPreKeys() => $_has(3);
  @$pb.TagNumber(4)
  void clearRequestNewPreKeys() => clearField(4);

  @$pb.TagNumber(5)
  DownloadData get downloaddata => $_getN(4);
  @$pb.TagNumber(5)
  set downloaddata(DownloadData v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasDownloaddata() => $_has(4);
  @$pb.TagNumber(5)
  void clearDownloaddata() => clearField(5);
  @$pb.TagNumber(5)
  DownloadData ensureDownloaddata() => $_ensure(4);

  @$pb.TagNumber(6)
  $0.ErrorCode get error => $_getN(5);
  @$pb.TagNumber(6)
  set error($0.ErrorCode v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasError() => $_has(5);
  @$pb.TagNumber(6)
  void clearError() => clearField(6);
}

class NewMessage extends $pb.GeneratedMessage {
  factory NewMessage({
    $core.List<$core.int>? body,
    $fixnum.Int64? fromUserId,
  }) {
    final $result = create();
    if (body != null) {
      $result.body = body;
    }
    if (fromUserId != null) {
      $result.fromUserId = fromUserId;
    }
    return $result;
  }
  NewMessage._() : super();
  factory NewMessage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory NewMessage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'NewMessage', package: const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'body', $pb.PbFieldType.OY)
    ..aInt64(2, _omitFieldNames ? '' : 'fromUserId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  NewMessage clone() => NewMessage()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  NewMessage copyWith(void Function(NewMessage) updates) => super.copyWith((message) => updates(message as NewMessage)) as NewMessage;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NewMessage create() => NewMessage._();
  NewMessage createEmptyInstance() => create();
  static $pb.PbList<NewMessage> createRepeated() => $pb.PbList<NewMessage>();
  @$core.pragma('dart2js:noInline')
  static NewMessage getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<NewMessage>(create);
  static NewMessage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get body => $_getN(0);
  @$pb.TagNumber(1)
  set body($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasBody() => $_has(0);
  @$pb.TagNumber(1)
  void clearBody() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get fromUserId => $_getI64(1);
  @$pb.TagNumber(2)
  set fromUserId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasFromUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearFromUserId() => clearField(2);
}

class DownloadData extends $pb.GeneratedMessage {
  factory DownloadData({
    $core.List<$core.int>? uploadToken,
    $core.int? offset,
    $core.List<$core.int>? data,
    $core.bool? fin,
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
    if (fin != null) {
      $result.fin = fin;
    }
    return $result;
  }
  DownloadData._() : super();
  factory DownloadData.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory DownloadData.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'DownloadData', package: const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'uploadToken', $pb.PbFieldType.OY)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'offset', $pb.PbFieldType.OU3)
    ..a<$core.List<$core.int>>(3, _omitFieldNames ? '' : 'data', $pb.PbFieldType.OY)
    ..aOB(4, _omitFieldNames ? '' : 'fin')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  DownloadData clone() => DownloadData()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  DownloadData copyWith(void Function(DownloadData) updates) => super.copyWith((message) => updates(message as DownloadData)) as DownloadData;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static DownloadData create() => DownloadData._();
  DownloadData createEmptyInstance() => create();
  static $pb.PbList<DownloadData> createRepeated() => $pb.PbList<DownloadData>();
  @$core.pragma('dart2js:noInline')
  static DownloadData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<DownloadData>(create);
  static DownloadData? _defaultInstance;

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

  @$pb.TagNumber(4)
  $core.bool get fin => $_getBF(3);
  @$pb.TagNumber(4)
  set fin($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasFin() => $_has(3);
  @$pb.TagNumber(4)
  void clearFin() => clearField(4);
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

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Response.PreKey', package: const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'), createEmptyInstance: create)
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

class Response_UserData extends $pb.GeneratedMessage {
  factory Response_UserData({
    $fixnum.Int64? userId,
    $core.Iterable<Response_PreKey>? prekeys,
    $core.List<$core.int>? publicIdentityKey,
    $core.List<$core.int>? signedPrekey,
    $core.List<$core.int>? signedPrekeySignature,
    $fixnum.Int64? signedPrekeyId,
    $core.List<$core.int>? username,
  }) {
    final $result = create();
    if (userId != null) {
      $result.userId = userId;
    }
    if (prekeys != null) {
      $result.prekeys.addAll(prekeys);
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
    if (username != null) {
      $result.username = username;
    }
    return $result;
  }
  Response_UserData._() : super();
  factory Response_UserData.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Response_UserData.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Response.UserData', package: const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'userId')
    ..pc<Response_PreKey>(2, _omitFieldNames ? '' : 'prekeys', $pb.PbFieldType.PM, subBuilder: Response_PreKey.create)
    ..a<$core.List<$core.int>>(3, _omitFieldNames ? '' : 'publicIdentityKey', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(4, _omitFieldNames ? '' : 'signedPrekey', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(5, _omitFieldNames ? '' : 'signedPrekeySignature', $pb.PbFieldType.OY)
    ..aInt64(6, _omitFieldNames ? '' : 'signedPrekeyId')
    ..a<$core.List<$core.int>>(7, _omitFieldNames ? '' : 'username', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Response_UserData clone() => Response_UserData()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Response_UserData copyWith(void Function(Response_UserData) updates) => super.copyWith((message) => updates(message as Response_UserData)) as Response_UserData;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_UserData create() => Response_UserData._();
  Response_UserData createEmptyInstance() => create();
  static $pb.PbList<Response_UserData> createRepeated() => $pb.PbList<Response_UserData>();
  @$core.pragma('dart2js:noInline')
  static Response_UserData getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Response_UserData>(create);
  static Response_UserData? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get userId => $_getI64(0);
  @$pb.TagNumber(1)
  set userId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<Response_PreKey> get prekeys => $_getList(1);

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
  $core.List<$core.int> get username => $_getN(6);
  @$pb.TagNumber(7)
  set username($core.List<$core.int> v) { $_setBytes(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasUsername() => $_has(6);
  @$pb.TagNumber(7)
  void clearUsername() => clearField(7);
}

class Response_UploadToken extends $pb.GeneratedMessage {
  factory Response_UploadToken({
    $core.List<$core.int>? uploadToken,
    $core.Iterable<$core.List<$core.int>>? downloadTokens,
  }) {
    final $result = create();
    if (uploadToken != null) {
      $result.uploadToken = uploadToken;
    }
    if (downloadTokens != null) {
      $result.downloadTokens.addAll(downloadTokens);
    }
    return $result;
  }
  Response_UploadToken._() : super();
  factory Response_UploadToken.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Response_UploadToken.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Response.UploadToken', package: const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'uploadToken', $pb.PbFieldType.OY)
    ..p<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'downloadTokens', $pb.PbFieldType.PY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Response_UploadToken clone() => Response_UploadToken()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Response_UploadToken copyWith(void Function(Response_UploadToken) updates) => super.copyWith((message) => updates(message as Response_UploadToken)) as Response_UploadToken;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_UploadToken create() => Response_UploadToken._();
  Response_UploadToken createEmptyInstance() => create();
  static $pb.PbList<Response_UploadToken> createRepeated() => $pb.PbList<Response_UploadToken>();
  @$core.pragma('dart2js:noInline')
  static Response_UploadToken getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Response_UploadToken>(create);
  static Response_UploadToken? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get uploadToken => $_getN(0);
  @$pb.TagNumber(1)
  set uploadToken($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUploadToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearUploadToken() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.List<$core.int>> get downloadTokens => $_getList(1);
}

enum Response_Ok_Ok {
  none, 
  userid, 
  authchallenge, 
  uploadtoken, 
  userdata, 
  authtoken, 
  notSet
}

class Response_Ok extends $pb.GeneratedMessage {
  factory Response_Ok({
    $core.bool? none,
    $fixnum.Int64? userid,
    $core.List<$core.int>? authchallenge,
    Response_UploadToken? uploadtoken,
    Response_UserData? userdata,
    $core.List<$core.int>? authtoken,
  }) {
    final $result = create();
    if (none != null) {
      $result.none = none;
    }
    if (userid != null) {
      $result.userid = userid;
    }
    if (authchallenge != null) {
      $result.authchallenge = authchallenge;
    }
    if (uploadtoken != null) {
      $result.uploadtoken = uploadtoken;
    }
    if (userdata != null) {
      $result.userdata = userdata;
    }
    if (authtoken != null) {
      $result.authtoken = authtoken;
    }
    return $result;
  }
  Response_Ok._() : super();
  factory Response_Ok.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Response_Ok.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static const $core.Map<$core.int, Response_Ok_Ok> _Response_Ok_OkByTag = {
    1 : Response_Ok_Ok.none,
    2 : Response_Ok_Ok.userid,
    3 : Response_Ok_Ok.authchallenge,
    4 : Response_Ok_Ok.uploadtoken,
    5 : Response_Ok_Ok.userdata,
    6 : Response_Ok_Ok.authtoken,
    0 : Response_Ok_Ok.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Response.Ok', package: const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'), createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6])
    ..aOB(1, _omitFieldNames ? '' : 'None', protoName: 'None')
    ..aInt64(2, _omitFieldNames ? '' : 'userid')
    ..a<$core.List<$core.int>>(3, _omitFieldNames ? '' : 'authchallenge', $pb.PbFieldType.OY)
    ..aOM<Response_UploadToken>(4, _omitFieldNames ? '' : 'uploadtoken', subBuilder: Response_UploadToken.create)
    ..aOM<Response_UserData>(5, _omitFieldNames ? '' : 'userdata', subBuilder: Response_UserData.create)
    ..a<$core.List<$core.int>>(6, _omitFieldNames ? '' : 'authtoken', $pb.PbFieldType.OY)
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
  $fixnum.Int64 get userid => $_getI64(1);
  @$pb.TagNumber(2)
  set userid($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasUserid() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserid() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get authchallenge => $_getN(2);
  @$pb.TagNumber(3)
  set authchallenge($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasAuthchallenge() => $_has(2);
  @$pb.TagNumber(3)
  void clearAuthchallenge() => clearField(3);

  @$pb.TagNumber(4)
  Response_UploadToken get uploadtoken => $_getN(3);
  @$pb.TagNumber(4)
  set uploadtoken(Response_UploadToken v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasUploadtoken() => $_has(3);
  @$pb.TagNumber(4)
  void clearUploadtoken() => clearField(4);
  @$pb.TagNumber(4)
  Response_UploadToken ensureUploadtoken() => $_ensure(3);

  @$pb.TagNumber(5)
  Response_UserData get userdata => $_getN(4);
  @$pb.TagNumber(5)
  set userdata(Response_UserData v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasUserdata() => $_has(4);
  @$pb.TagNumber(5)
  void clearUserdata() => clearField(5);
  @$pb.TagNumber(5)
  Response_UserData ensureUserdata() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.List<$core.int> get authtoken => $_getN(5);
  @$pb.TagNumber(6)
  set authtoken($core.List<$core.int> v) { $_setBytes(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasAuthtoken() => $_has(5);
  @$pb.TagNumber(6)
  void clearAuthtoken() => clearField(6);
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
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Response', package: const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'), createEmptyInstance: create)
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
