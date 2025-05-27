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
import 'server_to_client.pbenum.dart';

export 'server_to_client.pbenum.dart';

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
    $core.List<$core.int>? downloadToken,
    $core.int? offset,
    $core.List<$core.int>? data,
    $core.bool? fin,
  }) {
    final $result = create();
    if (downloadToken != null) {
      $result.downloadToken = downloadToken;
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
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'downloadToken', $pb.PbFieldType.OY)
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
  $core.List<$core.int> get downloadToken => $_getN(0);
  @$pb.TagNumber(1)
  set downloadToken($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDownloadToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearDownloadToken() => clearField(1);

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

class Response_Authenticated extends $pb.GeneratedMessage {
  factory Response_Authenticated({
    $core.String? plan,
  }) {
    final $result = create();
    if (plan != null) {
      $result.plan = plan;
    }
    return $result;
  }
  Response_Authenticated._() : super();
  factory Response_Authenticated.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Response_Authenticated.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Response.Authenticated', package: const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'plan')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Response_Authenticated clone() => Response_Authenticated()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Response_Authenticated copyWith(void Function(Response_Authenticated) updates) => super.copyWith((message) => updates(message as Response_Authenticated)) as Response_Authenticated;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_Authenticated create() => Response_Authenticated._();
  Response_Authenticated createEmptyInstance() => create();
  static $pb.PbList<Response_Authenticated> createRepeated() => $pb.PbList<Response_Authenticated>();
  @$core.pragma('dart2js:noInline')
  static Response_Authenticated getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Response_Authenticated>(create);
  static Response_Authenticated? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get plan => $_getSZ(0);
  @$pb.TagNumber(1)
  set plan($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPlan() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlan() => clearField(1);
}

class Response_Plan extends $pb.GeneratedMessage {
  factory Response_Plan({
    $core.String? planId,
    $fixnum.Int64? uploadSizeLimit,
    $fixnum.Int64? dailyMediaUploadLimit,
    $fixnum.Int64? maximalUploadSizeOfSingleMediaSize,
    $fixnum.Int64? additionalPlusAccounts,
    $fixnum.Int64? additionalFreeAccounts,
    $fixnum.Int64? monthlyCostsCent,
    $fixnum.Int64? yearlyCostsCent,
    $core.bool? allowedToSendTextMessages,
    $core.bool? isAdditionalAccount,
  }) {
    final $result = create();
    if (planId != null) {
      $result.planId = planId;
    }
    if (uploadSizeLimit != null) {
      $result.uploadSizeLimit = uploadSizeLimit;
    }
    if (dailyMediaUploadLimit != null) {
      $result.dailyMediaUploadLimit = dailyMediaUploadLimit;
    }
    if (maximalUploadSizeOfSingleMediaSize != null) {
      $result.maximalUploadSizeOfSingleMediaSize = maximalUploadSizeOfSingleMediaSize;
    }
    if (additionalPlusAccounts != null) {
      $result.additionalPlusAccounts = additionalPlusAccounts;
    }
    if (additionalFreeAccounts != null) {
      $result.additionalFreeAccounts = additionalFreeAccounts;
    }
    if (monthlyCostsCent != null) {
      $result.monthlyCostsCent = monthlyCostsCent;
    }
    if (yearlyCostsCent != null) {
      $result.yearlyCostsCent = yearlyCostsCent;
    }
    if (allowedToSendTextMessages != null) {
      $result.allowedToSendTextMessages = allowedToSendTextMessages;
    }
    if (isAdditionalAccount != null) {
      $result.isAdditionalAccount = isAdditionalAccount;
    }
    return $result;
  }
  Response_Plan._() : super();
  factory Response_Plan.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Response_Plan.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Response.Plan', package: const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'planId')
    ..aInt64(2, _omitFieldNames ? '' : 'uploadSizeLimit')
    ..aInt64(3, _omitFieldNames ? '' : 'dailyMediaUploadLimit')
    ..aInt64(4, _omitFieldNames ? '' : 'maximalUploadSizeOfSingleMediaSize')
    ..aInt64(5, _omitFieldNames ? '' : 'additionalPlusAccounts')
    ..aInt64(6, _omitFieldNames ? '' : 'additionalFreeAccounts')
    ..aInt64(7, _omitFieldNames ? '' : 'monthlyCostsCent')
    ..aInt64(8, _omitFieldNames ? '' : 'yearlyCostsCent')
    ..aOB(9, _omitFieldNames ? '' : 'allowedToSendTextMessages')
    ..aOB(10, _omitFieldNames ? '' : 'isAdditionalAccount')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Response_Plan clone() => Response_Plan()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Response_Plan copyWith(void Function(Response_Plan) updates) => super.copyWith((message) => updates(message as Response_Plan)) as Response_Plan;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_Plan create() => Response_Plan._();
  Response_Plan createEmptyInstance() => create();
  static $pb.PbList<Response_Plan> createRepeated() => $pb.PbList<Response_Plan>();
  @$core.pragma('dart2js:noInline')
  static Response_Plan getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Response_Plan>(create);
  static Response_Plan? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get planId => $_getSZ(0);
  @$pb.TagNumber(1)
  set planId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPlanId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlanId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get uploadSizeLimit => $_getI64(1);
  @$pb.TagNumber(2)
  set uploadSizeLimit($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasUploadSizeLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearUploadSizeLimit() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get dailyMediaUploadLimit => $_getI64(2);
  @$pb.TagNumber(3)
  set dailyMediaUploadLimit($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDailyMediaUploadLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearDailyMediaUploadLimit() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get maximalUploadSizeOfSingleMediaSize => $_getI64(3);
  @$pb.TagNumber(4)
  set maximalUploadSizeOfSingleMediaSize($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasMaximalUploadSizeOfSingleMediaSize() => $_has(3);
  @$pb.TagNumber(4)
  void clearMaximalUploadSizeOfSingleMediaSize() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get additionalPlusAccounts => $_getI64(4);
  @$pb.TagNumber(5)
  set additionalPlusAccounts($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasAdditionalPlusAccounts() => $_has(4);
  @$pb.TagNumber(5)
  void clearAdditionalPlusAccounts() => clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get additionalFreeAccounts => $_getI64(5);
  @$pb.TagNumber(6)
  set additionalFreeAccounts($fixnum.Int64 v) { $_setInt64(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasAdditionalFreeAccounts() => $_has(5);
  @$pb.TagNumber(6)
  void clearAdditionalFreeAccounts() => clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get monthlyCostsCent => $_getI64(6);
  @$pb.TagNumber(7)
  set monthlyCostsCent($fixnum.Int64 v) { $_setInt64(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasMonthlyCostsCent() => $_has(6);
  @$pb.TagNumber(7)
  void clearMonthlyCostsCent() => clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get yearlyCostsCent => $_getI64(7);
  @$pb.TagNumber(8)
  set yearlyCostsCent($fixnum.Int64 v) { $_setInt64(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasYearlyCostsCent() => $_has(7);
  @$pb.TagNumber(8)
  void clearYearlyCostsCent() => clearField(8);

  @$pb.TagNumber(9)
  $core.bool get allowedToSendTextMessages => $_getBF(8);
  @$pb.TagNumber(9)
  set allowedToSendTextMessages($core.bool v) { $_setBool(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasAllowedToSendTextMessages() => $_has(8);
  @$pb.TagNumber(9)
  void clearAllowedToSendTextMessages() => clearField(9);

  @$pb.TagNumber(10)
  $core.bool get isAdditionalAccount => $_getBF(9);
  @$pb.TagNumber(10)
  set isAdditionalAccount($core.bool v) { $_setBool(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasIsAdditionalAccount() => $_has(9);
  @$pb.TagNumber(10)
  void clearIsAdditionalAccount() => clearField(10);
}

class Response_Plans extends $pb.GeneratedMessage {
  factory Response_Plans({
    $core.Iterable<Response_Plan>? plans,
  }) {
    final $result = create();
    if (plans != null) {
      $result.plans.addAll(plans);
    }
    return $result;
  }
  Response_Plans._() : super();
  factory Response_Plans.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Response_Plans.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Response.Plans', package: const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'), createEmptyInstance: create)
    ..pc<Response_Plan>(1, _omitFieldNames ? '' : 'plans', $pb.PbFieldType.PM, subBuilder: Response_Plan.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Response_Plans clone() => Response_Plans()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Response_Plans copyWith(void Function(Response_Plans) updates) => super.copyWith((message) => updates(message as Response_Plans)) as Response_Plans;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_Plans create() => Response_Plans._();
  Response_Plans createEmptyInstance() => create();
  static $pb.PbList<Response_Plans> createRepeated() => $pb.PbList<Response_Plans>();
  @$core.pragma('dart2js:noInline')
  static Response_Plans getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Response_Plans>(create);
  static Response_Plans? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Response_Plan> get plans => $_getList(0);
}

class Response_AddAccountsInvite extends $pb.GeneratedMessage {
  factory Response_AddAccountsInvite({
    $core.String? planId,
    $core.String? inviteCode,
  }) {
    final $result = create();
    if (planId != null) {
      $result.planId = planId;
    }
    if (inviteCode != null) {
      $result.inviteCode = inviteCode;
    }
    return $result;
  }
  Response_AddAccountsInvite._() : super();
  factory Response_AddAccountsInvite.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Response_AddAccountsInvite.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Response.AddAccountsInvite', package: const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'planId')
    ..aOS(2, _omitFieldNames ? '' : 'inviteCode')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Response_AddAccountsInvite clone() => Response_AddAccountsInvite()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Response_AddAccountsInvite copyWith(void Function(Response_AddAccountsInvite) updates) => super.copyWith((message) => updates(message as Response_AddAccountsInvite)) as Response_AddAccountsInvite;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_AddAccountsInvite create() => Response_AddAccountsInvite._();
  Response_AddAccountsInvite createEmptyInstance() => create();
  static $pb.PbList<Response_AddAccountsInvite> createRepeated() => $pb.PbList<Response_AddAccountsInvite>();
  @$core.pragma('dart2js:noInline')
  static Response_AddAccountsInvite getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Response_AddAccountsInvite>(create);
  static Response_AddAccountsInvite? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get planId => $_getSZ(0);
  @$pb.TagNumber(1)
  set planId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasPlanId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlanId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get inviteCode => $_getSZ(1);
  @$pb.TagNumber(2)
  set inviteCode($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasInviteCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearInviteCode() => clearField(2);
}

class Response_AddAccountsInvites extends $pb.GeneratedMessage {
  factory Response_AddAccountsInvites({
    $core.Iterable<Response_AddAccountsInvite>? invites,
  }) {
    final $result = create();
    if (invites != null) {
      $result.invites.addAll(invites);
    }
    return $result;
  }
  Response_AddAccountsInvites._() : super();
  factory Response_AddAccountsInvites.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Response_AddAccountsInvites.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Response.AddAccountsInvites', package: const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'), createEmptyInstance: create)
    ..pc<Response_AddAccountsInvite>(1, _omitFieldNames ? '' : 'invites', $pb.PbFieldType.PM, subBuilder: Response_AddAccountsInvite.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Response_AddAccountsInvites clone() => Response_AddAccountsInvites()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Response_AddAccountsInvites copyWith(void Function(Response_AddAccountsInvites) updates) => super.copyWith((message) => updates(message as Response_AddAccountsInvites)) as Response_AddAccountsInvites;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_AddAccountsInvites create() => Response_AddAccountsInvites._();
  Response_AddAccountsInvites createEmptyInstance() => create();
  static $pb.PbList<Response_AddAccountsInvites> createRepeated() => $pb.PbList<Response_AddAccountsInvites>();
  @$core.pragma('dart2js:noInline')
  static Response_AddAccountsInvites getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Response_AddAccountsInvites>(create);
  static Response_AddAccountsInvites? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Response_AddAccountsInvite> get invites => $_getList(0);
}

class Response_Transaction extends $pb.GeneratedMessage {
  factory Response_Transaction({
    $fixnum.Int64? depositCents,
    Response_TransactionTypes? transactionType,
    $fixnum.Int64? createdAtUnixTimestamp,
  }) {
    final $result = create();
    if (depositCents != null) {
      $result.depositCents = depositCents;
    }
    if (transactionType != null) {
      $result.transactionType = transactionType;
    }
    if (createdAtUnixTimestamp != null) {
      $result.createdAtUnixTimestamp = createdAtUnixTimestamp;
    }
    return $result;
  }
  Response_Transaction._() : super();
  factory Response_Transaction.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Response_Transaction.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Response.Transaction', package: const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'depositCents')
    ..e<Response_TransactionTypes>(2, _omitFieldNames ? '' : 'transactionType', $pb.PbFieldType.OE, defaultOrMaker: Response_TransactionTypes.Refund, valueOf: Response_TransactionTypes.valueOf, enumValues: Response_TransactionTypes.values)
    ..aInt64(3, _omitFieldNames ? '' : 'createdAtUnixTimestamp')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Response_Transaction clone() => Response_Transaction()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Response_Transaction copyWith(void Function(Response_Transaction) updates) => super.copyWith((message) => updates(message as Response_Transaction)) as Response_Transaction;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_Transaction create() => Response_Transaction._();
  Response_Transaction createEmptyInstance() => create();
  static $pb.PbList<Response_Transaction> createRepeated() => $pb.PbList<Response_Transaction>();
  @$core.pragma('dart2js:noInline')
  static Response_Transaction getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Response_Transaction>(create);
  static Response_Transaction? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get depositCents => $_getI64(0);
  @$pb.TagNumber(1)
  set depositCents($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasDepositCents() => $_has(0);
  @$pb.TagNumber(1)
  void clearDepositCents() => clearField(1);

  @$pb.TagNumber(2)
  Response_TransactionTypes get transactionType => $_getN(1);
  @$pb.TagNumber(2)
  set transactionType(Response_TransactionTypes v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasTransactionType() => $_has(1);
  @$pb.TagNumber(2)
  void clearTransactionType() => clearField(2);

  /// Represents seconds of UTC time since Unix epoch
  /// 1970-01-01T00:00:00Z. Must be from 0001-01-01T00:00:00Z to
  /// 9999-12-31T23:59:59Z inclusive.
  @$pb.TagNumber(3)
  $fixnum.Int64 get createdAtUnixTimestamp => $_getI64(2);
  @$pb.TagNumber(3)
  set createdAtUnixTimestamp($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasCreatedAtUnixTimestamp() => $_has(2);
  @$pb.TagNumber(3)
  void clearCreatedAtUnixTimestamp() => clearField(3);
}

class Response_AdditionalAccount extends $pb.GeneratedMessage {
  factory Response_AdditionalAccount({
    $fixnum.Int64? userId,
    $core.String? planId,
  }) {
    final $result = create();
    if (userId != null) {
      $result.userId = userId;
    }
    if (planId != null) {
      $result.planId = planId;
    }
    return $result;
  }
  Response_AdditionalAccount._() : super();
  factory Response_AdditionalAccount.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Response_AdditionalAccount.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Response.AdditionalAccount', package: const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'userId')
    ..aOS(3, _omitFieldNames ? '' : 'planId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Response_AdditionalAccount clone() => Response_AdditionalAccount()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Response_AdditionalAccount copyWith(void Function(Response_AdditionalAccount) updates) => super.copyWith((message) => updates(message as Response_AdditionalAccount)) as Response_AdditionalAccount;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_AdditionalAccount create() => Response_AdditionalAccount._();
  Response_AdditionalAccount createEmptyInstance() => create();
  static $pb.PbList<Response_AdditionalAccount> createRepeated() => $pb.PbList<Response_AdditionalAccount>();
  @$core.pragma('dart2js:noInline')
  static Response_AdditionalAccount getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Response_AdditionalAccount>(create);
  static Response_AdditionalAccount? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get userId => $_getI64(0);
  @$pb.TagNumber(1)
  set userId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => clearField(1);

  @$pb.TagNumber(3)
  $core.String get planId => $_getSZ(1);
  @$pb.TagNumber(3)
  set planId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(3)
  $core.bool hasPlanId() => $_has(1);
  @$pb.TagNumber(3)
  void clearPlanId() => clearField(3);
}

class Response_Voucher extends $pb.GeneratedMessage {
  factory Response_Voucher({
    $core.String? voucherId,
    $fixnum.Int64? valueCents,
    $core.bool? redeemed,
    $core.bool? requested,
    $fixnum.Int64? createdAtUnixTimestamp,
  }) {
    final $result = create();
    if (voucherId != null) {
      $result.voucherId = voucherId;
    }
    if (valueCents != null) {
      $result.valueCents = valueCents;
    }
    if (redeemed != null) {
      $result.redeemed = redeemed;
    }
    if (requested != null) {
      $result.requested = requested;
    }
    if (createdAtUnixTimestamp != null) {
      $result.createdAtUnixTimestamp = createdAtUnixTimestamp;
    }
    return $result;
  }
  Response_Voucher._() : super();
  factory Response_Voucher.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Response_Voucher.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Response.Voucher', package: const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'voucherId')
    ..aInt64(2, _omitFieldNames ? '' : 'valueCents')
    ..aOB(3, _omitFieldNames ? '' : 'redeemed')
    ..aOB(4, _omitFieldNames ? '' : 'requested')
    ..aInt64(5, _omitFieldNames ? '' : 'createdAtUnixTimestamp')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Response_Voucher clone() => Response_Voucher()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Response_Voucher copyWith(void Function(Response_Voucher) updates) => super.copyWith((message) => updates(message as Response_Voucher)) as Response_Voucher;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_Voucher create() => Response_Voucher._();
  Response_Voucher createEmptyInstance() => create();
  static $pb.PbList<Response_Voucher> createRepeated() => $pb.PbList<Response_Voucher>();
  @$core.pragma('dart2js:noInline')
  static Response_Voucher getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Response_Voucher>(create);
  static Response_Voucher? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get voucherId => $_getSZ(0);
  @$pb.TagNumber(1)
  set voucherId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasVoucherId() => $_has(0);
  @$pb.TagNumber(1)
  void clearVoucherId() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get valueCents => $_getI64(1);
  @$pb.TagNumber(2)
  set valueCents($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasValueCents() => $_has(1);
  @$pb.TagNumber(2)
  void clearValueCents() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get redeemed => $_getBF(2);
  @$pb.TagNumber(3)
  set redeemed($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasRedeemed() => $_has(2);
  @$pb.TagNumber(3)
  void clearRedeemed() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get requested => $_getBF(3);
  @$pb.TagNumber(4)
  set requested($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasRequested() => $_has(3);
  @$pb.TagNumber(4)
  void clearRequested() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get createdAtUnixTimestamp => $_getI64(4);
  @$pb.TagNumber(5)
  set createdAtUnixTimestamp($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasCreatedAtUnixTimestamp() => $_has(4);
  @$pb.TagNumber(5)
  void clearCreatedAtUnixTimestamp() => clearField(5);
}

class Response_Vouchers extends $pb.GeneratedMessage {
  factory Response_Vouchers({
    $core.Iterable<Response_Voucher>? vouchers,
  }) {
    final $result = create();
    if (vouchers != null) {
      $result.vouchers.addAll(vouchers);
    }
    return $result;
  }
  Response_Vouchers._() : super();
  factory Response_Vouchers.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Response_Vouchers.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Response.Vouchers', package: const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'), createEmptyInstance: create)
    ..pc<Response_Voucher>(1, _omitFieldNames ? '' : 'vouchers', $pb.PbFieldType.PM, subBuilder: Response_Voucher.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Response_Vouchers clone() => Response_Vouchers()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Response_Vouchers copyWith(void Function(Response_Vouchers) updates) => super.copyWith((message) => updates(message as Response_Vouchers)) as Response_Vouchers;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_Vouchers create() => Response_Vouchers._();
  Response_Vouchers createEmptyInstance() => create();
  static $pb.PbList<Response_Vouchers> createRepeated() => $pb.PbList<Response_Vouchers>();
  @$core.pragma('dart2js:noInline')
  static Response_Vouchers getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Response_Vouchers>(create);
  static Response_Vouchers? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<Response_Voucher> get vouchers => $_getList(0);
}

class Response_PlanBallance extends $pb.GeneratedMessage {
  factory Response_PlanBallance({
    $fixnum.Int64? usedDailyMediaUploadLimit,
    $fixnum.Int64? usedUploadMediaSizeLimit,
    $fixnum.Int64? paymentPeriodDays,
    $fixnum.Int64? lastPaymentDoneUnixTimestamp,
    $core.Iterable<Response_Transaction>? transactions,
    $core.Iterable<Response_AdditionalAccount>? additionalAccounts,
    $core.bool? autoRenewal,
    $fixnum.Int64? additionalAccountOwnerId,
  }) {
    final $result = create();
    if (usedDailyMediaUploadLimit != null) {
      $result.usedDailyMediaUploadLimit = usedDailyMediaUploadLimit;
    }
    if (usedUploadMediaSizeLimit != null) {
      $result.usedUploadMediaSizeLimit = usedUploadMediaSizeLimit;
    }
    if (paymentPeriodDays != null) {
      $result.paymentPeriodDays = paymentPeriodDays;
    }
    if (lastPaymentDoneUnixTimestamp != null) {
      $result.lastPaymentDoneUnixTimestamp = lastPaymentDoneUnixTimestamp;
    }
    if (transactions != null) {
      $result.transactions.addAll(transactions);
    }
    if (additionalAccounts != null) {
      $result.additionalAccounts.addAll(additionalAccounts);
    }
    if (autoRenewal != null) {
      $result.autoRenewal = autoRenewal;
    }
    if (additionalAccountOwnerId != null) {
      $result.additionalAccountOwnerId = additionalAccountOwnerId;
    }
    return $result;
  }
  Response_PlanBallance._() : super();
  factory Response_PlanBallance.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Response_PlanBallance.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Response.PlanBallance', package: const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'usedDailyMediaUploadLimit')
    ..aInt64(2, _omitFieldNames ? '' : 'usedUploadMediaSizeLimit')
    ..aInt64(3, _omitFieldNames ? '' : 'paymentPeriodDays')
    ..aInt64(4, _omitFieldNames ? '' : 'lastPaymentDoneUnixTimestamp')
    ..pc<Response_Transaction>(5, _omitFieldNames ? '' : 'transactions', $pb.PbFieldType.PM, subBuilder: Response_Transaction.create)
    ..pc<Response_AdditionalAccount>(6, _omitFieldNames ? '' : 'additionalAccounts', $pb.PbFieldType.PM, subBuilder: Response_AdditionalAccount.create)
    ..aOB(7, _omitFieldNames ? '' : 'autoRenewal')
    ..aInt64(8, _omitFieldNames ? '' : 'additionalAccountOwnerId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Response_PlanBallance clone() => Response_PlanBallance()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Response_PlanBallance copyWith(void Function(Response_PlanBallance) updates) => super.copyWith((message) => updates(message as Response_PlanBallance)) as Response_PlanBallance;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_PlanBallance create() => Response_PlanBallance._();
  Response_PlanBallance createEmptyInstance() => create();
  static $pb.PbList<Response_PlanBallance> createRepeated() => $pb.PbList<Response_PlanBallance>();
  @$core.pragma('dart2js:noInline')
  static Response_PlanBallance getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Response_PlanBallance>(create);
  static Response_PlanBallance? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get usedDailyMediaUploadLimit => $_getI64(0);
  @$pb.TagNumber(1)
  set usedDailyMediaUploadLimit($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUsedDailyMediaUploadLimit() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsedDailyMediaUploadLimit() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get usedUploadMediaSizeLimit => $_getI64(1);
  @$pb.TagNumber(2)
  set usedUploadMediaSizeLimit($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasUsedUploadMediaSizeLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsedUploadMediaSizeLimit() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get paymentPeriodDays => $_getI64(2);
  @$pb.TagNumber(3)
  set paymentPeriodDays($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasPaymentPeriodDays() => $_has(2);
  @$pb.TagNumber(3)
  void clearPaymentPeriodDays() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get lastPaymentDoneUnixTimestamp => $_getI64(3);
  @$pb.TagNumber(4)
  set lastPaymentDoneUnixTimestamp($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasLastPaymentDoneUnixTimestamp() => $_has(3);
  @$pb.TagNumber(4)
  void clearLastPaymentDoneUnixTimestamp() => clearField(4);

  @$pb.TagNumber(5)
  $core.List<Response_Transaction> get transactions => $_getList(4);

  @$pb.TagNumber(6)
  $core.List<Response_AdditionalAccount> get additionalAccounts => $_getList(5);

  @$pb.TagNumber(7)
  $core.bool get autoRenewal => $_getBF(6);
  @$pb.TagNumber(7)
  set autoRenewal($core.bool v) { $_setBool(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasAutoRenewal() => $_has(6);
  @$pb.TagNumber(7)
  void clearAutoRenewal() => clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get additionalAccountOwnerId => $_getI64(7);
  @$pb.TagNumber(8)
  set additionalAccountOwnerId($fixnum.Int64 v) { $_setInt64(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasAdditionalAccountOwnerId() => $_has(7);
  @$pb.TagNumber(8)
  void clearAdditionalAccountOwnerId() => clearField(8);
}

class Response_Location extends $pb.GeneratedMessage {
  factory Response_Location({
    $core.String? county,
    $core.String? region,
    $core.String? city,
  }) {
    final $result = create();
    if (county != null) {
      $result.county = county;
    }
    if (region != null) {
      $result.region = region;
    }
    if (city != null) {
      $result.city = city;
    }
    return $result;
  }
  Response_Location._() : super();
  factory Response_Location.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Response_Location.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Response.Location', package: const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'county')
    ..aOS(2, _omitFieldNames ? '' : 'region')
    ..aOS(3, _omitFieldNames ? '' : 'city')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Response_Location clone() => Response_Location()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Response_Location copyWith(void Function(Response_Location) updates) => super.copyWith((message) => updates(message as Response_Location)) as Response_Location;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_Location create() => Response_Location._();
  Response_Location createEmptyInstance() => create();
  static $pb.PbList<Response_Location> createRepeated() => $pb.PbList<Response_Location>();
  @$core.pragma('dart2js:noInline')
  static Response_Location getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Response_Location>(create);
  static Response_Location? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get county => $_getSZ(0);
  @$pb.TagNumber(1)
  set county($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasCounty() => $_has(0);
  @$pb.TagNumber(1)
  void clearCounty() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get region => $_getSZ(1);
  @$pb.TagNumber(2)
  set region($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasRegion() => $_has(1);
  @$pb.TagNumber(2)
  void clearRegion() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get city => $_getSZ(2);
  @$pb.TagNumber(3)
  set city($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasCity() => $_has(2);
  @$pb.TagNumber(3)
  void clearCity() => clearField(3);
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

class Response_DownloadTokens extends $pb.GeneratedMessage {
  factory Response_DownloadTokens({
    $core.Iterable<$core.List<$core.int>>? downloadTokens,
  }) {
    final $result = create();
    if (downloadTokens != null) {
      $result.downloadTokens.addAll(downloadTokens);
    }
    return $result;
  }
  Response_DownloadTokens._() : super();
  factory Response_DownloadTokens.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Response_DownloadTokens.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Response.DownloadTokens', package: const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'), createEmptyInstance: create)
    ..p<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'downloadTokens', $pb.PbFieldType.PY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Response_DownloadTokens clone() => Response_DownloadTokens()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Response_DownloadTokens copyWith(void Function(Response_DownloadTokens) updates) => super.copyWith((message) => updates(message as Response_DownloadTokens)) as Response_DownloadTokens;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_DownloadTokens create() => Response_DownloadTokens._();
  Response_DownloadTokens createEmptyInstance() => create();
  static $pb.PbList<Response_DownloadTokens> createRepeated() => $pb.PbList<Response_DownloadTokens>();
  @$core.pragma('dart2js:noInline')
  static Response_DownloadTokens getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Response_DownloadTokens>(create);
  static Response_DownloadTokens? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.List<$core.int>> get downloadTokens => $_getList(0);
}

enum Response_Ok_Ok {
  none, 
  userid, 
  authchallenge, 
  uploadtoken, 
  userdata, 
  authtoken, 
  location, 
  authenticated, 
  plans, 
  planballance, 
  vouchers, 
  addaccountsinvites, 
  downloadtokens, 
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
    Response_Location? location,
    Response_Authenticated? authenticated,
    Response_Plans? plans,
    Response_PlanBallance? planballance,
    Response_Vouchers? vouchers,
    Response_AddAccountsInvites? addaccountsinvites,
    Response_DownloadTokens? downloadtokens,
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
    if (location != null) {
      $result.location = location;
    }
    if (authenticated != null) {
      $result.authenticated = authenticated;
    }
    if (plans != null) {
      $result.plans = plans;
    }
    if (planballance != null) {
      $result.planballance = planballance;
    }
    if (vouchers != null) {
      $result.vouchers = vouchers;
    }
    if (addaccountsinvites != null) {
      $result.addaccountsinvites = addaccountsinvites;
    }
    if (downloadtokens != null) {
      $result.downloadtokens = downloadtokens;
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
    7 : Response_Ok_Ok.location,
    8 : Response_Ok_Ok.authenticated,
    9 : Response_Ok_Ok.plans,
    10 : Response_Ok_Ok.planballance,
    11 : Response_Ok_Ok.vouchers,
    12 : Response_Ok_Ok.addaccountsinvites,
    13 : Response_Ok_Ok.downloadtokens,
    0 : Response_Ok_Ok.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Response.Ok', package: const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'), createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13])
    ..aOB(1, _omitFieldNames ? '' : 'None', protoName: 'None')
    ..aInt64(2, _omitFieldNames ? '' : 'userid')
    ..a<$core.List<$core.int>>(3, _omitFieldNames ? '' : 'authchallenge', $pb.PbFieldType.OY)
    ..aOM<Response_UploadToken>(4, _omitFieldNames ? '' : 'uploadtoken', subBuilder: Response_UploadToken.create)
    ..aOM<Response_UserData>(5, _omitFieldNames ? '' : 'userdata', subBuilder: Response_UserData.create)
    ..a<$core.List<$core.int>>(6, _omitFieldNames ? '' : 'authtoken', $pb.PbFieldType.OY)
    ..aOM<Response_Location>(7, _omitFieldNames ? '' : 'location', subBuilder: Response_Location.create)
    ..aOM<Response_Authenticated>(8, _omitFieldNames ? '' : 'authenticated', subBuilder: Response_Authenticated.create)
    ..aOM<Response_Plans>(9, _omitFieldNames ? '' : 'plans', subBuilder: Response_Plans.create)
    ..aOM<Response_PlanBallance>(10, _omitFieldNames ? '' : 'planballance', subBuilder: Response_PlanBallance.create)
    ..aOM<Response_Vouchers>(11, _omitFieldNames ? '' : 'vouchers', subBuilder: Response_Vouchers.create)
    ..aOM<Response_AddAccountsInvites>(12, _omitFieldNames ? '' : 'addaccountsinvites', subBuilder: Response_AddAccountsInvites.create)
    ..aOM<Response_DownloadTokens>(13, _omitFieldNames ? '' : 'downloadtokens', subBuilder: Response_DownloadTokens.create)
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

  @$pb.TagNumber(7)
  Response_Location get location => $_getN(6);
  @$pb.TagNumber(7)
  set location(Response_Location v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasLocation() => $_has(6);
  @$pb.TagNumber(7)
  void clearLocation() => clearField(7);
  @$pb.TagNumber(7)
  Response_Location ensureLocation() => $_ensure(6);

  @$pb.TagNumber(8)
  Response_Authenticated get authenticated => $_getN(7);
  @$pb.TagNumber(8)
  set authenticated(Response_Authenticated v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasAuthenticated() => $_has(7);
  @$pb.TagNumber(8)
  void clearAuthenticated() => clearField(8);
  @$pb.TagNumber(8)
  Response_Authenticated ensureAuthenticated() => $_ensure(7);

  @$pb.TagNumber(9)
  Response_Plans get plans => $_getN(8);
  @$pb.TagNumber(9)
  set plans(Response_Plans v) { setField(9, v); }
  @$pb.TagNumber(9)
  $core.bool hasPlans() => $_has(8);
  @$pb.TagNumber(9)
  void clearPlans() => clearField(9);
  @$pb.TagNumber(9)
  Response_Plans ensurePlans() => $_ensure(8);

  @$pb.TagNumber(10)
  Response_PlanBallance get planballance => $_getN(9);
  @$pb.TagNumber(10)
  set planballance(Response_PlanBallance v) { setField(10, v); }
  @$pb.TagNumber(10)
  $core.bool hasPlanballance() => $_has(9);
  @$pb.TagNumber(10)
  void clearPlanballance() => clearField(10);
  @$pb.TagNumber(10)
  Response_PlanBallance ensurePlanballance() => $_ensure(9);

  @$pb.TagNumber(11)
  Response_Vouchers get vouchers => $_getN(10);
  @$pb.TagNumber(11)
  set vouchers(Response_Vouchers v) { setField(11, v); }
  @$pb.TagNumber(11)
  $core.bool hasVouchers() => $_has(10);
  @$pb.TagNumber(11)
  void clearVouchers() => clearField(11);
  @$pb.TagNumber(11)
  Response_Vouchers ensureVouchers() => $_ensure(10);

  @$pb.TagNumber(12)
  Response_AddAccountsInvites get addaccountsinvites => $_getN(11);
  @$pb.TagNumber(12)
  set addaccountsinvites(Response_AddAccountsInvites v) { setField(12, v); }
  @$pb.TagNumber(12)
  $core.bool hasAddaccountsinvites() => $_has(11);
  @$pb.TagNumber(12)
  void clearAddaccountsinvites() => clearField(12);
  @$pb.TagNumber(12)
  Response_AddAccountsInvites ensureAddaccountsinvites() => $_ensure(11);

  @$pb.TagNumber(13)
  Response_DownloadTokens get downloadtokens => $_getN(12);
  @$pb.TagNumber(13)
  set downloadtokens(Response_DownloadTokens v) { setField(13, v); }
  @$pb.TagNumber(13)
  $core.bool hasDownloadtokens() => $_has(12);
  @$pb.TagNumber(13)
  void clearDownloadtokens() => clearField(13);
  @$pb.TagNumber(13)
  Response_DownloadTokens ensureDownloadtokens() => $_ensure(12);
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
