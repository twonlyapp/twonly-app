// This is a generated file - do not edit.
//
// Generated from api/websocket/server_to_client.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'error.pbenum.dart' as $0;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

enum ServerToClient_V { v0, notSet }

class ServerToClient extends $pb.GeneratedMessage {
  factory ServerToClient({
    V0? v0,
  }) {
    final result = create();
    if (v0 != null) result.v0 = v0;
    return result;
  }

  ServerToClient._();

  factory ServerToClient.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory ServerToClient.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, ServerToClient_V> _ServerToClient_VByTag = {
    1: ServerToClient_V.v0,
    0: ServerToClient_V.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'ServerToClient',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..oo(0, [1])
    ..aOM<V0>(1, _omitFieldNames ? '' : 'V0',
        protoName: 'V0', subBuilder: V0.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerToClient clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  ServerToClient copyWith(void Function(ServerToClient) updates) =>
      super.copyWith((message) => updates(message as ServerToClient))
          as ServerToClient;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static ServerToClient create() => ServerToClient._();
  @$core.override
  ServerToClient createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static ServerToClient getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ServerToClient>(create);
  static ServerToClient? _defaultInstance;

  @$pb.TagNumber(1)
  ServerToClient_V whichV() => _ServerToClient_VByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  void clearV() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  V0 get v0 => $_getN(0);
  @$pb.TagNumber(1)
  set v0(V0 value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasV0() => $_has(0);
  @$pb.TagNumber(1)
  void clearV0() => $_clearField(1);
  @$pb.TagNumber(1)
  V0 ensureV0() => $_ensure(0);
}

enum V0_Kind {
  response,
  newMessage,
  requestNewPreKeys,
  error,
  newMessages,
  requestNewPqcPreKeys,
  notSet
}

class V0 extends $pb.GeneratedMessage {
  factory V0({
    $fixnum.Int64? seq,
    Response? response,
    NewMessage? newMessage,
    $core.bool? requestNewPreKeys,
    $0.ErrorCode? error,
    NewMessages? newMessages,
    $core.bool? requestNewPqcPreKeys,
  }) {
    final result = create();
    if (seq != null) result.seq = seq;
    if (response != null) result.response = response;
    if (newMessage != null) result.newMessage = newMessage;
    if (requestNewPreKeys != null) result.requestNewPreKeys = requestNewPreKeys;
    if (error != null) result.error = error;
    if (newMessages != null) result.newMessages = newMessages;
    if (requestNewPqcPreKeys != null)
      result.requestNewPqcPreKeys = requestNewPqcPreKeys;
    return result;
  }

  V0._();

  factory V0.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory V0.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, V0_Kind> _V0_KindByTag = {
    2: V0_Kind.response,
    3: V0_Kind.newMessage,
    4: V0_Kind.requestNewPreKeys,
    6: V0_Kind.error,
    7: V0_Kind.newMessages,
    8: V0_Kind.requestNewPqcPreKeys,
    0: V0_Kind.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'V0',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..oo(0, [2, 3, 4, 6, 7, 8])
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'seq', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<Response>(2, _omitFieldNames ? '' : 'response',
        subBuilder: Response.create)
    ..aOM<NewMessage>(3, _omitFieldNames ? '' : 'newMessage',
        protoName: 'newMessage', subBuilder: NewMessage.create)
    ..aOB(4, _omitFieldNames ? '' : 'RequestNewPreKeys',
        protoName: 'RequestNewPreKeys')
    ..aE<$0.ErrorCode>(6, _omitFieldNames ? '' : 'error',
        enumValues: $0.ErrorCode.values)
    ..aOM<NewMessages>(7, _omitFieldNames ? '' : 'newMessages',
        protoName: 'newMessages', subBuilder: NewMessages.create)
    ..aOB(8, _omitFieldNames ? '' : 'RequestNewPqcPreKeys',
        protoName: 'RequestNewPqcPreKeys')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  V0 clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  V0 copyWith(void Function(V0) updates) =>
      super.copyWith((message) => updates(message as V0)) as V0;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static V0 create() => V0._();
  @$core.override
  V0 createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static V0 getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<V0>(create);
  static V0? _defaultInstance;

  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  V0_Kind whichKind() => _V0_KindByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(6)
  @$pb.TagNumber(7)
  @$pb.TagNumber(8)
  void clearKind() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $fixnum.Int64 get seq => $_getI64(0);
  @$pb.TagNumber(1)
  set seq($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSeq() => $_has(0);
  @$pb.TagNumber(1)
  void clearSeq() => $_clearField(1);

  @$pb.TagNumber(2)
  Response get response => $_getN(1);
  @$pb.TagNumber(2)
  set response(Response value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasResponse() => $_has(1);
  @$pb.TagNumber(2)
  void clearResponse() => $_clearField(2);
  @$pb.TagNumber(2)
  Response ensureResponse() => $_ensure(1);

  @$pb.TagNumber(3)
  NewMessage get newMessage => $_getN(2);
  @$pb.TagNumber(3)
  set newMessage(NewMessage value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasNewMessage() => $_has(2);
  @$pb.TagNumber(3)
  void clearNewMessage() => $_clearField(3);
  @$pb.TagNumber(3)
  NewMessage ensureNewMessage() => $_ensure(2);

  @$pb.TagNumber(4)
  $core.bool get requestNewPreKeys => $_getBF(3);
  @$pb.TagNumber(4)
  set requestNewPreKeys($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRequestNewPreKeys() => $_has(3);
  @$pb.TagNumber(4)
  void clearRequestNewPreKeys() => $_clearField(4);

  @$pb.TagNumber(6)
  $0.ErrorCode get error => $_getN(4);
  @$pb.TagNumber(6)
  set error($0.ErrorCode value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasError() => $_has(4);
  @$pb.TagNumber(6)
  void clearError() => $_clearField(6);

  @$pb.TagNumber(7)
  NewMessages get newMessages => $_getN(5);
  @$pb.TagNumber(7)
  set newMessages(NewMessages value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasNewMessages() => $_has(5);
  @$pb.TagNumber(7)
  void clearNewMessages() => $_clearField(7);
  @$pb.TagNumber(7)
  NewMessages ensureNewMessages() => $_ensure(5);

  @$pb.TagNumber(8)
  $core.bool get requestNewPqcPreKeys => $_getBF(6);
  @$pb.TagNumber(8)
  set requestNewPqcPreKeys($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(8)
  $core.bool hasRequestNewPqcPreKeys() => $_has(6);
  @$pb.TagNumber(8)
  void clearRequestNewPqcPreKeys() => $_clearField(8);
}

class NewMessage extends $pb.GeneratedMessage {
  factory NewMessage({
    $core.List<$core.int>? body,
    $fixnum.Int64? fromUserId,
  }) {
    final result = create();
    if (body != null) result.body = body;
    if (fromUserId != null) result.fromUserId = fromUserId;
    return result;
  }

  NewMessage._();

  factory NewMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NewMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NewMessage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'body', $pb.PbFieldType.OY)
    ..aInt64(2, _omitFieldNames ? '' : 'fromUserId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NewMessage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NewMessage copyWith(void Function(NewMessage) updates) =>
      super.copyWith((message) => updates(message as NewMessage)) as NewMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NewMessage create() => NewMessage._();
  @$core.override
  NewMessage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NewMessage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NewMessage>(create);
  static NewMessage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get body => $_getN(0);
  @$pb.TagNumber(1)
  set body($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasBody() => $_has(0);
  @$pb.TagNumber(1)
  void clearBody() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get fromUserId => $_getI64(1);
  @$pb.TagNumber(2)
  set fromUserId($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasFromUserId() => $_has(1);
  @$pb.TagNumber(2)
  void clearFromUserId() => $_clearField(2);
}

class NewMessages extends $pb.GeneratedMessage {
  factory NewMessages({
    $core.Iterable<NewMessage>? newMessages,
  }) {
    final result = create();
    if (newMessages != null) result.newMessages.addAll(newMessages);
    return result;
  }

  NewMessages._();

  factory NewMessages.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory NewMessages.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'NewMessages',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..pPM<NewMessage>(1, _omitFieldNames ? '' : 'newMessages',
        protoName: 'newMessages', subBuilder: NewMessage.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NewMessages clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NewMessages copyWith(void Function(NewMessages) updates) =>
      super.copyWith((message) => updates(message as NewMessages))
          as NewMessages;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NewMessages create() => NewMessages._();
  @$core.override
  NewMessages createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static NewMessages getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<NewMessages>(create);
  static NewMessages? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<NewMessage> get newMessages => $_getList(0);
}

class Response_Authenticated extends $pb.GeneratedMessage {
  factory Response_Authenticated({
    $core.String? plan,
  }) {
    final result = create();
    if (plan != null) result.plan = plan;
    return result;
  }

  Response_Authenticated._();

  factory Response_Authenticated.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Response_Authenticated.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response.Authenticated',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'plan')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_Authenticated clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_Authenticated copyWith(
          void Function(Response_Authenticated) updates) =>
      super.copyWith((message) => updates(message as Response_Authenticated))
          as Response_Authenticated;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_Authenticated create() => Response_Authenticated._();
  @$core.override
  Response_Authenticated createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Response_Authenticated getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Response_Authenticated>(create);
  static Response_Authenticated? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get plan => $_getSZ(0);
  @$pb.TagNumber(1)
  set plan($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPlan() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlan() => $_clearField(1);
}

class Response_Plan extends $pb.GeneratedMessage {
  factory Response_Plan({
    $core.String? planId,
    $fixnum.Int64? uploadSizeLimit,
    $fixnum.Int64? dailyMediaUploadLimit,
    $fixnum.Int64? maximalUploadSizeOfSingleMediaSize,
    $fixnum.Int64? additionalPlusAccounts,
    $fixnum.Int64? monthlyCostsCent,
    $fixnum.Int64? yearlyCostsCent,
    $core.bool? allowedToSendTextMessages,
    $core.bool? isAdditionalAccount,
    $fixnum.Int64? memoriesSizeLimit,
  }) {
    final result = create();
    if (planId != null) result.planId = planId;
    if (uploadSizeLimit != null) result.uploadSizeLimit = uploadSizeLimit;
    if (dailyMediaUploadLimit != null)
      result.dailyMediaUploadLimit = dailyMediaUploadLimit;
    if (maximalUploadSizeOfSingleMediaSize != null)
      result.maximalUploadSizeOfSingleMediaSize =
          maximalUploadSizeOfSingleMediaSize;
    if (additionalPlusAccounts != null)
      result.additionalPlusAccounts = additionalPlusAccounts;
    if (monthlyCostsCent != null) result.monthlyCostsCent = monthlyCostsCent;
    if (yearlyCostsCent != null) result.yearlyCostsCent = yearlyCostsCent;
    if (allowedToSendTextMessages != null)
      result.allowedToSendTextMessages = allowedToSendTextMessages;
    if (isAdditionalAccount != null)
      result.isAdditionalAccount = isAdditionalAccount;
    if (memoriesSizeLimit != null) result.memoriesSizeLimit = memoriesSizeLimit;
    return result;
  }

  Response_Plan._();

  factory Response_Plan.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Response_Plan.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response.Plan',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'planId')
    ..aInt64(2, _omitFieldNames ? '' : 'uploadSizeLimit')
    ..aInt64(3, _omitFieldNames ? '' : 'dailyMediaUploadLimit')
    ..aInt64(4, _omitFieldNames ? '' : 'maximalUploadSizeOfSingleMediaSize')
    ..aInt64(5, _omitFieldNames ? '' : 'additionalPlusAccounts')
    ..aInt64(7, _omitFieldNames ? '' : 'monthlyCostsCent')
    ..aInt64(8, _omitFieldNames ? '' : 'yearlyCostsCent')
    ..aOB(9, _omitFieldNames ? '' : 'allowedToSendTextMessages')
    ..aOB(10, _omitFieldNames ? '' : 'isAdditionalAccount')
    ..aInt64(11, _omitFieldNames ? '' : 'memoriesSizeLimit')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_Plan clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_Plan copyWith(void Function(Response_Plan) updates) =>
      super.copyWith((message) => updates(message as Response_Plan))
          as Response_Plan;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_Plan create() => Response_Plan._();
  @$core.override
  Response_Plan createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Response_Plan getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Response_Plan>(create);
  static Response_Plan? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get planId => $_getSZ(0);
  @$pb.TagNumber(1)
  set planId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPlanId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlanId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get uploadSizeLimit => $_getI64(1);
  @$pb.TagNumber(2)
  set uploadSizeLimit($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUploadSizeLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearUploadSizeLimit() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get dailyMediaUploadLimit => $_getI64(2);
  @$pb.TagNumber(3)
  set dailyMediaUploadLimit($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasDailyMediaUploadLimit() => $_has(2);
  @$pb.TagNumber(3)
  void clearDailyMediaUploadLimit() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get maximalUploadSizeOfSingleMediaSize => $_getI64(3);
  @$pb.TagNumber(4)
  set maximalUploadSizeOfSingleMediaSize($fixnum.Int64 value) =>
      $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMaximalUploadSizeOfSingleMediaSize() => $_has(3);
  @$pb.TagNumber(4)
  void clearMaximalUploadSizeOfSingleMediaSize() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get additionalPlusAccounts => $_getI64(4);
  @$pb.TagNumber(5)
  set additionalPlusAccounts($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasAdditionalPlusAccounts() => $_has(4);
  @$pb.TagNumber(5)
  void clearAdditionalPlusAccounts() => $_clearField(5);

  @$pb.TagNumber(7)
  $fixnum.Int64 get monthlyCostsCent => $_getI64(5);
  @$pb.TagNumber(7)
  set monthlyCostsCent($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(7)
  $core.bool hasMonthlyCostsCent() => $_has(5);
  @$pb.TagNumber(7)
  void clearMonthlyCostsCent() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get yearlyCostsCent => $_getI64(6);
  @$pb.TagNumber(8)
  set yearlyCostsCent($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(8)
  $core.bool hasYearlyCostsCent() => $_has(6);
  @$pb.TagNumber(8)
  void clearYearlyCostsCent() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get allowedToSendTextMessages => $_getBF(7);
  @$pb.TagNumber(9)
  set allowedToSendTextMessages($core.bool value) => $_setBool(7, value);
  @$pb.TagNumber(9)
  $core.bool hasAllowedToSendTextMessages() => $_has(7);
  @$pb.TagNumber(9)
  void clearAllowedToSendTextMessages() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get isAdditionalAccount => $_getBF(8);
  @$pb.TagNumber(10)
  set isAdditionalAccount($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(10)
  $core.bool hasIsAdditionalAccount() => $_has(8);
  @$pb.TagNumber(10)
  void clearIsAdditionalAccount() => $_clearField(10);

  @$pb.TagNumber(11)
  $fixnum.Int64 get memoriesSizeLimit => $_getI64(9);
  @$pb.TagNumber(11)
  set memoriesSizeLimit($fixnum.Int64 value) => $_setInt64(9, value);
  @$pb.TagNumber(11)
  $core.bool hasMemoriesSizeLimit() => $_has(9);
  @$pb.TagNumber(11)
  void clearMemoriesSizeLimit() => $_clearField(11);
}

class Response_Plans extends $pb.GeneratedMessage {
  factory Response_Plans({
    $core.Iterable<Response_Plan>? plans,
  }) {
    final result = create();
    if (plans != null) result.plans.addAll(plans);
    return result;
  }

  Response_Plans._();

  factory Response_Plans.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Response_Plans.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response.Plans',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..pPM<Response_Plan>(1, _omitFieldNames ? '' : 'plans',
        subBuilder: Response_Plan.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_Plans clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_Plans copyWith(void Function(Response_Plans) updates) =>
      super.copyWith((message) => updates(message as Response_Plans))
          as Response_Plans;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_Plans create() => Response_Plans._();
  @$core.override
  Response_Plans createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Response_Plans getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Response_Plans>(create);
  static Response_Plans? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Response_Plan> get plans => $_getList(0);
}

class Response_AddAccountsInvite extends $pb.GeneratedMessage {
  factory Response_AddAccountsInvite({
    $core.String? planId,
    $core.String? inviteCode,
  }) {
    final result = create();
    if (planId != null) result.planId = planId;
    if (inviteCode != null) result.inviteCode = inviteCode;
    return result;
  }

  Response_AddAccountsInvite._();

  factory Response_AddAccountsInvite.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Response_AddAccountsInvite.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response.AddAccountsInvite',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'planId')
    ..aOS(2, _omitFieldNames ? '' : 'inviteCode')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_AddAccountsInvite clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_AddAccountsInvite copyWith(
          void Function(Response_AddAccountsInvite) updates) =>
      super.copyWith(
              (message) => updates(message as Response_AddAccountsInvite))
          as Response_AddAccountsInvite;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_AddAccountsInvite create() => Response_AddAccountsInvite._();
  @$core.override
  Response_AddAccountsInvite createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Response_AddAccountsInvite getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Response_AddAccountsInvite>(create);
  static Response_AddAccountsInvite? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get planId => $_getSZ(0);
  @$pb.TagNumber(1)
  set planId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPlanId() => $_has(0);
  @$pb.TagNumber(1)
  void clearPlanId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get inviteCode => $_getSZ(1);
  @$pb.TagNumber(2)
  set inviteCode($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasInviteCode() => $_has(1);
  @$pb.TagNumber(2)
  void clearInviteCode() => $_clearField(2);
}

class Response_AddAccountsInvites extends $pb.GeneratedMessage {
  factory Response_AddAccountsInvites({
    $core.Iterable<Response_AddAccountsInvite>? invites,
  }) {
    final result = create();
    if (invites != null) result.invites.addAll(invites);
    return result;
  }

  Response_AddAccountsInvites._();

  factory Response_AddAccountsInvites.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Response_AddAccountsInvites.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response.AddAccountsInvites',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..pPM<Response_AddAccountsInvite>(1, _omitFieldNames ? '' : 'invites',
        subBuilder: Response_AddAccountsInvite.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_AddAccountsInvites clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_AddAccountsInvites copyWith(
          void Function(Response_AddAccountsInvites) updates) =>
      super.copyWith(
              (message) => updates(message as Response_AddAccountsInvites))
          as Response_AddAccountsInvites;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_AddAccountsInvites create() =>
      Response_AddAccountsInvites._();
  @$core.override
  Response_AddAccountsInvites createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Response_AddAccountsInvites getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Response_AddAccountsInvites>(create);
  static Response_AddAccountsInvites? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Response_AddAccountsInvite> get invites => $_getList(0);
}

class Response_AdditionalAccount extends $pb.GeneratedMessage {
  factory Response_AdditionalAccount({
    $fixnum.Int64? userId,
    $core.String? planId,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    if (planId != null) result.planId = planId;
    return result;
  }

  Response_AdditionalAccount._();

  factory Response_AdditionalAccount.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Response_AdditionalAccount.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response.AdditionalAccount',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'userId')
    ..aOS(3, _omitFieldNames ? '' : 'planId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_AdditionalAccount clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_AdditionalAccount copyWith(
          void Function(Response_AdditionalAccount) updates) =>
      super.copyWith(
              (message) => updates(message as Response_AdditionalAccount))
          as Response_AdditionalAccount;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_AdditionalAccount create() => Response_AdditionalAccount._();
  @$core.override
  Response_AdditionalAccount createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Response_AdditionalAccount getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Response_AdditionalAccount>(create);
  static Response_AdditionalAccount? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get userId => $_getI64(0);
  @$pb.TagNumber(1)
  set userId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(3)
  $core.String get planId => $_getSZ(1);
  @$pb.TagNumber(3)
  set planId($core.String value) => $_setString(1, value);
  @$pb.TagNumber(3)
  $core.bool hasPlanId() => $_has(1);
  @$pb.TagNumber(3)
  void clearPlanId() => $_clearField(3);
}

class Response_Transaction extends $pb.GeneratedMessage {
  factory Response_Transaction() => create();

  Response_Transaction._();

  factory Response_Transaction.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Response_Transaction.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response.Transaction',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_Transaction clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_Transaction copyWith(void Function(Response_Transaction) updates) =>
      super.copyWith((message) => updates(message as Response_Transaction))
          as Response_Transaction;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_Transaction create() => Response_Transaction._();
  @$core.override
  Response_Transaction createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Response_Transaction getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Response_Transaction>(create);
  static Response_Transaction? _defaultInstance;
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
    final result = create();
    if (usedDailyMediaUploadLimit != null)
      result.usedDailyMediaUploadLimit = usedDailyMediaUploadLimit;
    if (usedUploadMediaSizeLimit != null)
      result.usedUploadMediaSizeLimit = usedUploadMediaSizeLimit;
    if (paymentPeriodDays != null) result.paymentPeriodDays = paymentPeriodDays;
    if (lastPaymentDoneUnixTimestamp != null)
      result.lastPaymentDoneUnixTimestamp = lastPaymentDoneUnixTimestamp;
    if (transactions != null) result.transactions.addAll(transactions);
    if (additionalAccounts != null)
      result.additionalAccounts.addAll(additionalAccounts);
    if (autoRenewal != null) result.autoRenewal = autoRenewal;
    if (additionalAccountOwnerId != null)
      result.additionalAccountOwnerId = additionalAccountOwnerId;
    return result;
  }

  Response_PlanBallance._();

  factory Response_PlanBallance.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Response_PlanBallance.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response.PlanBallance',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'usedDailyMediaUploadLimit')
    ..aInt64(2, _omitFieldNames ? '' : 'usedUploadMediaSizeLimit')
    ..aInt64(3, _omitFieldNames ? '' : 'paymentPeriodDays')
    ..aInt64(4, _omitFieldNames ? '' : 'lastPaymentDoneUnixTimestamp')
    ..pPM<Response_Transaction>(5, _omitFieldNames ? '' : 'transactions',
        subBuilder: Response_Transaction.create)
    ..pPM<Response_AdditionalAccount>(
        6, _omitFieldNames ? '' : 'additionalAccounts',
        subBuilder: Response_AdditionalAccount.create)
    ..aOB(7, _omitFieldNames ? '' : 'autoRenewal')
    ..aInt64(8, _omitFieldNames ? '' : 'additionalAccountOwnerId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_PlanBallance clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_PlanBallance copyWith(
          void Function(Response_PlanBallance) updates) =>
      super.copyWith((message) => updates(message as Response_PlanBallance))
          as Response_PlanBallance;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_PlanBallance create() => Response_PlanBallance._();
  @$core.override
  Response_PlanBallance createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Response_PlanBallance getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Response_PlanBallance>(create);
  static Response_PlanBallance? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get usedDailyMediaUploadLimit => $_getI64(0);
  @$pb.TagNumber(1)
  set usedDailyMediaUploadLimit($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUsedDailyMediaUploadLimit() => $_has(0);
  @$pb.TagNumber(1)
  void clearUsedDailyMediaUploadLimit() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get usedUploadMediaSizeLimit => $_getI64(1);
  @$pb.TagNumber(2)
  set usedUploadMediaSizeLimit($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUsedUploadMediaSizeLimit() => $_has(1);
  @$pb.TagNumber(2)
  void clearUsedUploadMediaSizeLimit() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get paymentPeriodDays => $_getI64(2);
  @$pb.TagNumber(3)
  set paymentPeriodDays($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPaymentPeriodDays() => $_has(2);
  @$pb.TagNumber(3)
  void clearPaymentPeriodDays() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get lastPaymentDoneUnixTimestamp => $_getI64(3);
  @$pb.TagNumber(4)
  set lastPaymentDoneUnixTimestamp($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasLastPaymentDoneUnixTimestamp() => $_has(3);
  @$pb.TagNumber(4)
  void clearLastPaymentDoneUnixTimestamp() => $_clearField(4);

  @$pb.TagNumber(5)
  $pb.PbList<Response_Transaction> get transactions => $_getList(4);

  @$pb.TagNumber(6)
  $pb.PbList<Response_AdditionalAccount> get additionalAccounts => $_getList(5);

  @$pb.TagNumber(7)
  $core.bool get autoRenewal => $_getBF(6);
  @$pb.TagNumber(7)
  set autoRenewal($core.bool value) => $_setBool(6, value);
  @$pb.TagNumber(7)
  $core.bool hasAutoRenewal() => $_has(6);
  @$pb.TagNumber(7)
  void clearAutoRenewal() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get additionalAccountOwnerId => $_getI64(7);
  @$pb.TagNumber(8)
  set additionalAccountOwnerId($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasAdditionalAccountOwnerId() => $_has(7);
  @$pb.TagNumber(8)
  void clearAdditionalAccountOwnerId() => $_clearField(8);
}

class Response_PreKey extends $pb.GeneratedMessage {
  factory Response_PreKey({
    $fixnum.Int64? id,
    $core.List<$core.int>? prekey,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (prekey != null) result.prekey = prekey;
    return result;
  }

  Response_PreKey._();

  factory Response_PreKey.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Response_PreKey.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response.PreKey',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'prekey', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_PreKey clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_PreKey copyWith(void Function(Response_PreKey) updates) =>
      super.copyWith((message) => updates(message as Response_PreKey))
          as Response_PreKey;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_PreKey create() => Response_PreKey._();
  @$core.override
  Response_PreKey createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Response_PreKey getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Response_PreKey>(create);
  static Response_PreKey? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get prekey => $_getN(1);
  @$pb.TagNumber(2)
  set prekey($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasPrekey() => $_has(1);
  @$pb.TagNumber(2)
  void clearPrekey() => $_clearField(2);
}

class Response_SignedPreKey extends $pb.GeneratedMessage {
  factory Response_SignedPreKey({
    $fixnum.Int64? signedPrekeyId,
    $core.List<$core.int>? signedPrekey,
    $core.List<$core.int>? signedPrekeySignature,
  }) {
    final result = create();
    if (signedPrekeyId != null) result.signedPrekeyId = signedPrekeyId;
    if (signedPrekey != null) result.signedPrekey = signedPrekey;
    if (signedPrekeySignature != null)
      result.signedPrekeySignature = signedPrekeySignature;
    return result;
  }

  Response_SignedPreKey._();

  factory Response_SignedPreKey.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Response_SignedPreKey.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response.SignedPreKey',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'signedPrekeyId')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'signedPrekey', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'signedPrekeySignature', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_SignedPreKey clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_SignedPreKey copyWith(
          void Function(Response_SignedPreKey) updates) =>
      super.copyWith((message) => updates(message as Response_SignedPreKey))
          as Response_SignedPreKey;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_SignedPreKey create() => Response_SignedPreKey._();
  @$core.override
  Response_SignedPreKey createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Response_SignedPreKey getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Response_SignedPreKey>(create);
  static Response_SignedPreKey? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get signedPrekeyId => $_getI64(0);
  @$pb.TagNumber(1)
  set signedPrekeyId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSignedPrekeyId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSignedPrekeyId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get signedPrekey => $_getN(1);
  @$pb.TagNumber(2)
  set signedPrekey($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasSignedPrekey() => $_has(1);
  @$pb.TagNumber(2)
  void clearSignedPrekey() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get signedPrekeySignature => $_getN(2);
  @$pb.TagNumber(3)
  set signedPrekeySignature($core.List<$core.int> value) =>
      $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasSignedPrekeySignature() => $_has(2);
  @$pb.TagNumber(3)
  void clearSignedPrekeySignature() => $_clearField(3);
}

class Response_PqcPreKey extends $pb.GeneratedMessage {
  factory Response_PqcPreKey({
    $fixnum.Int64? eccPreKeyId,
    $core.List<$core.int>? eccPreKey,
    $fixnum.Int64? kyberPreKeyId,
    $core.List<$core.int>? kyberPreKey,
    $core.List<$core.int>? kyberPreKeySignature,
  }) {
    final result = create();
    if (eccPreKeyId != null) result.eccPreKeyId = eccPreKeyId;
    if (eccPreKey != null) result.eccPreKey = eccPreKey;
    if (kyberPreKeyId != null) result.kyberPreKeyId = kyberPreKeyId;
    if (kyberPreKey != null) result.kyberPreKey = kyberPreKey;
    if (kyberPreKeySignature != null)
      result.kyberPreKeySignature = kyberPreKeySignature;
    return result;
  }

  Response_PqcPreKey._();

  factory Response_PqcPreKey.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Response_PqcPreKey.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response.PqcPreKey',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'eccPreKeyId')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'eccPreKey', $pb.PbFieldType.OY)
    ..aInt64(3, _omitFieldNames ? '' : 'kyberPreKeyId')
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'kyberPreKey', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'kyberPreKeySignature', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_PqcPreKey clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_PqcPreKey copyWith(void Function(Response_PqcPreKey) updates) =>
      super.copyWith((message) => updates(message as Response_PqcPreKey))
          as Response_PqcPreKey;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_PqcPreKey create() => Response_PqcPreKey._();
  @$core.override
  Response_PqcPreKey createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Response_PqcPreKey getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Response_PqcPreKey>(create);
  static Response_PqcPreKey? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get eccPreKeyId => $_getI64(0);
  @$pb.TagNumber(1)
  set eccPreKeyId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEccPreKeyId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEccPreKeyId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get eccPreKey => $_getN(1);
  @$pb.TagNumber(2)
  set eccPreKey($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEccPreKey() => $_has(1);
  @$pb.TagNumber(2)
  void clearEccPreKey() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get kyberPreKeyId => $_getI64(2);
  @$pb.TagNumber(3)
  set kyberPreKeyId($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasKyberPreKeyId() => $_has(2);
  @$pb.TagNumber(3)
  void clearKyberPreKeyId() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get kyberPreKey => $_getN(3);
  @$pb.TagNumber(4)
  set kyberPreKey($core.List<$core.int> value) => $_setBytes(3, value);
  @$pb.TagNumber(4)
  $core.bool hasKyberPreKey() => $_has(3);
  @$pb.TagNumber(4)
  void clearKyberPreKey() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.int> get kyberPreKeySignature => $_getN(4);
  @$pb.TagNumber(5)
  set kyberPreKeySignature($core.List<$core.int> value) => $_setBytes(4, value);
  @$pb.TagNumber(5)
  $core.bool hasKyberPreKeySignature() => $_has(4);
  @$pb.TagNumber(5)
  void clearKyberPreKeySignature() => $_clearField(5);
}

class Response_PqcBundle extends $pb.GeneratedMessage {
  factory Response_PqcBundle({
    $fixnum.Int64? eccSignedPrekeyId,
    $core.List<$core.int>? eccSignedPrekey,
    $core.List<$core.int>? eccSignedPrekeySignature,
    $fixnum.Int64? kyberSignedPrekeyId,
    $core.List<$core.int>? kyberSignedPrekey,
    $core.List<$core.int>? kyberSignedPrekeySignature,
    Response_PqcPreKey? prekey,
  }) {
    final result = create();
    if (eccSignedPrekeyId != null) result.eccSignedPrekeyId = eccSignedPrekeyId;
    if (eccSignedPrekey != null) result.eccSignedPrekey = eccSignedPrekey;
    if (eccSignedPrekeySignature != null)
      result.eccSignedPrekeySignature = eccSignedPrekeySignature;
    if (kyberSignedPrekeyId != null)
      result.kyberSignedPrekeyId = kyberSignedPrekeyId;
    if (kyberSignedPrekey != null) result.kyberSignedPrekey = kyberSignedPrekey;
    if (kyberSignedPrekeySignature != null)
      result.kyberSignedPrekeySignature = kyberSignedPrekeySignature;
    if (prekey != null) result.prekey = prekey;
    return result;
  }

  Response_PqcBundle._();

  factory Response_PqcBundle.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Response_PqcBundle.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response.PqcBundle',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'eccSignedPrekeyId')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'eccSignedPrekey', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(3,
        _omitFieldNames ? '' : 'eccSignedPrekeySignature', $pb.PbFieldType.OY)
    ..aInt64(4, _omitFieldNames ? '' : 'kyberSignedPrekeyId')
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'kyberSignedPrekey', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(6,
        _omitFieldNames ? '' : 'kyberSignedPrekeySignature', $pb.PbFieldType.OY)
    ..aOM<Response_PqcPreKey>(7, _omitFieldNames ? '' : 'prekey',
        subBuilder: Response_PqcPreKey.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_PqcBundle clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_PqcBundle copyWith(void Function(Response_PqcBundle) updates) =>
      super.copyWith((message) => updates(message as Response_PqcBundle))
          as Response_PqcBundle;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_PqcBundle create() => Response_PqcBundle._();
  @$core.override
  Response_PqcBundle createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Response_PqcBundle getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Response_PqcBundle>(create);
  static Response_PqcBundle? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get eccSignedPrekeyId => $_getI64(0);
  @$pb.TagNumber(1)
  set eccSignedPrekeyId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEccSignedPrekeyId() => $_has(0);
  @$pb.TagNumber(1)
  void clearEccSignedPrekeyId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get eccSignedPrekey => $_getN(1);
  @$pb.TagNumber(2)
  set eccSignedPrekey($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEccSignedPrekey() => $_has(1);
  @$pb.TagNumber(2)
  void clearEccSignedPrekey() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get eccSignedPrekeySignature => $_getN(2);
  @$pb.TagNumber(3)
  set eccSignedPrekeySignature($core.List<$core.int> value) =>
      $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasEccSignedPrekeySignature() => $_has(2);
  @$pb.TagNumber(3)
  void clearEccSignedPrekeySignature() => $_clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get kyberSignedPrekeyId => $_getI64(3);
  @$pb.TagNumber(4)
  set kyberSignedPrekeyId($fixnum.Int64 value) => $_setInt64(3, value);
  @$pb.TagNumber(4)
  $core.bool hasKyberSignedPrekeyId() => $_has(3);
  @$pb.TagNumber(4)
  void clearKyberSignedPrekeyId() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.List<$core.int> get kyberSignedPrekey => $_getN(4);
  @$pb.TagNumber(5)
  set kyberSignedPrekey($core.List<$core.int> value) => $_setBytes(4, value);
  @$pb.TagNumber(5)
  $core.bool hasKyberSignedPrekey() => $_has(4);
  @$pb.TagNumber(5)
  void clearKyberSignedPrekey() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.List<$core.int> get kyberSignedPrekeySignature => $_getN(5);
  @$pb.TagNumber(6)
  set kyberSignedPrekeySignature($core.List<$core.int> value) =>
      $_setBytes(5, value);
  @$pb.TagNumber(6)
  $core.bool hasKyberSignedPrekeySignature() => $_has(5);
  @$pb.TagNumber(6)
  void clearKyberSignedPrekeySignature() => $_clearField(6);

  @$pb.TagNumber(7)
  Response_PqcPreKey get prekey => $_getN(6);
  @$pb.TagNumber(7)
  set prekey(Response_PqcPreKey value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasPrekey() => $_has(6);
  @$pb.TagNumber(7)
  void clearPrekey() => $_clearField(7);
  @$pb.TagNumber(7)
  Response_PqcPreKey ensurePrekey() => $_ensure(6);
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
    $fixnum.Int64? registrationId,
    Response_PqcBundle? pqcBundle,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    if (prekeys != null) result.prekeys.addAll(prekeys);
    if (publicIdentityKey != null) result.publicIdentityKey = publicIdentityKey;
    if (signedPrekey != null) result.signedPrekey = signedPrekey;
    if (signedPrekeySignature != null)
      result.signedPrekeySignature = signedPrekeySignature;
    if (signedPrekeyId != null) result.signedPrekeyId = signedPrekeyId;
    if (username != null) result.username = username;
    if (registrationId != null) result.registrationId = registrationId;
    if (pqcBundle != null) result.pqcBundle = pqcBundle;
    return result;
  }

  Response_UserData._();

  factory Response_UserData.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Response_UserData.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response.UserData',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'userId')
    ..pPM<Response_PreKey>(2, _omitFieldNames ? '' : 'prekeys',
        subBuilder: Response_PreKey.create)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'publicIdentityKey', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        4, _omitFieldNames ? '' : 'signedPrekey', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        5, _omitFieldNames ? '' : 'signedPrekeySignature', $pb.PbFieldType.OY)
    ..aInt64(6, _omitFieldNames ? '' : 'signedPrekeyId')
    ..a<$core.List<$core.int>>(
        7, _omitFieldNames ? '' : 'username', $pb.PbFieldType.OY)
    ..aInt64(8, _omitFieldNames ? '' : 'registrationId')
    ..aOM<Response_PqcBundle>(9, _omitFieldNames ? '' : 'pqcBundle',
        subBuilder: Response_PqcBundle.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_UserData clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_UserData copyWith(void Function(Response_UserData) updates) =>
      super.copyWith((message) => updates(message as Response_UserData))
          as Response_UserData;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_UserData create() => Response_UserData._();
  @$core.override
  Response_UserData createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Response_UserData getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Response_UserData>(create);
  static Response_UserData? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get userId => $_getI64(0);
  @$pb.TagNumber(1)
  set userId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<Response_PreKey> get prekeys => $_getList(1);

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
  $core.List<$core.int> get signedPrekeySignature => $_getN(4);
  @$pb.TagNumber(5)
  set signedPrekeySignature($core.List<$core.int> value) =>
      $_setBytes(4, value);
  @$pb.TagNumber(5)
  $core.bool hasSignedPrekeySignature() => $_has(4);
  @$pb.TagNumber(5)
  void clearSignedPrekeySignature() => $_clearField(5);

  @$pb.TagNumber(6)
  $fixnum.Int64 get signedPrekeyId => $_getI64(5);
  @$pb.TagNumber(6)
  set signedPrekeyId($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasSignedPrekeyId() => $_has(5);
  @$pb.TagNumber(6)
  void clearSignedPrekeyId() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.List<$core.int> get username => $_getN(6);
  @$pb.TagNumber(7)
  set username($core.List<$core.int> value) => $_setBytes(6, value);
  @$pb.TagNumber(7)
  $core.bool hasUsername() => $_has(6);
  @$pb.TagNumber(7)
  void clearUsername() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get registrationId => $_getI64(7);
  @$pb.TagNumber(8)
  set registrationId($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasRegistrationId() => $_has(7);
  @$pb.TagNumber(8)
  void clearRegistrationId() => $_clearField(8);

  @$pb.TagNumber(9)
  Response_PqcBundle get pqcBundle => $_getN(8);
  @$pb.TagNumber(9)
  set pqcBundle(Response_PqcBundle value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasPqcBundle() => $_has(8);
  @$pb.TagNumber(9)
  void clearPqcBundle() => $_clearField(9);
  @$pb.TagNumber(9)
  Response_PqcBundle ensurePqcBundle() => $_ensure(8);
}

class Response_UploadToken extends $pb.GeneratedMessage {
  factory Response_UploadToken({
    $core.List<$core.int>? uploadToken,
    $core.Iterable<$core.List<$core.int>>? downloadTokens,
  }) {
    final result = create();
    if (uploadToken != null) result.uploadToken = uploadToken;
    if (downloadTokens != null) result.downloadTokens.addAll(downloadTokens);
    return result;
  }

  Response_UploadToken._();

  factory Response_UploadToken.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Response_UploadToken.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response.UploadToken',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'uploadToken', $pb.PbFieldType.OY)
    ..p<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'downloadTokens', $pb.PbFieldType.PY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_UploadToken clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_UploadToken copyWith(void Function(Response_UploadToken) updates) =>
      super.copyWith((message) => updates(message as Response_UploadToken))
          as Response_UploadToken;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_UploadToken create() => Response_UploadToken._();
  @$core.override
  Response_UploadToken createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Response_UploadToken getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Response_UploadToken>(create);
  static Response_UploadToken? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get uploadToken => $_getN(0);
  @$pb.TagNumber(1)
  set uploadToken($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUploadToken() => $_has(0);
  @$pb.TagNumber(1)
  void clearUploadToken() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.List<$core.int>> get downloadTokens => $_getList(1);
}

class Response_DownloadTokens extends $pb.GeneratedMessage {
  factory Response_DownloadTokens({
    $core.Iterable<$core.List<$core.int>>? downloadTokens,
  }) {
    final result = create();
    if (downloadTokens != null) result.downloadTokens.addAll(downloadTokens);
    return result;
  }

  Response_DownloadTokens._();

  factory Response_DownloadTokens.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Response_DownloadTokens.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response.DownloadTokens',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..p<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'downloadTokens', $pb.PbFieldType.PY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_DownloadTokens clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_DownloadTokens copyWith(
          void Function(Response_DownloadTokens) updates) =>
      super.copyWith((message) => updates(message as Response_DownloadTokens))
          as Response_DownloadTokens;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_DownloadTokens create() => Response_DownloadTokens._();
  @$core.override
  Response_DownloadTokens createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Response_DownloadTokens getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Response_DownloadTokens>(create);
  static Response_DownloadTokens? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.List<$core.int>> get downloadTokens => $_getList(0);
}

class Response_ProofOfWork extends $pb.GeneratedMessage {
  factory Response_ProofOfWork({
    $core.String? prefix,
    $fixnum.Int64? difficulty,
  }) {
    final result = create();
    if (prefix != null) result.prefix = prefix;
    if (difficulty != null) result.difficulty = difficulty;
    return result;
  }

  Response_ProofOfWork._();

  factory Response_ProofOfWork.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Response_ProofOfWork.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response.ProofOfWork',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'prefix')
    ..aInt64(2, _omitFieldNames ? '' : 'difficulty')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_ProofOfWork clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_ProofOfWork copyWith(void Function(Response_ProofOfWork) updates) =>
      super.copyWith((message) => updates(message as Response_ProofOfWork))
          as Response_ProofOfWork;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_ProofOfWork create() => Response_ProofOfWork._();
  @$core.override
  Response_ProofOfWork createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Response_ProofOfWork getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Response_ProofOfWork>(create);
  static Response_ProofOfWork? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get prefix => $_getSZ(0);
  @$pb.TagNumber(1)
  set prefix($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasPrefix() => $_has(0);
  @$pb.TagNumber(1)
  void clearPrefix() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get difficulty => $_getI64(1);
  @$pb.TagNumber(2)
  set difficulty($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDifficulty() => $_has(1);
  @$pb.TagNumber(2)
  void clearDifficulty() => $_clearField(2);
}

class Response_PasswordlessNotificationMessage extends $pb.GeneratedMessage {
  factory Response_PasswordlessNotificationMessage({
    $fixnum.Int64? id,
    $core.List<$core.int>? encryptedMessage,
  }) {
    final result = create();
    if (id != null) result.id = id;
    if (encryptedMessage != null) result.encryptedMessage = encryptedMessage;
    return result;
  }

  Response_PasswordlessNotificationMessage._();

  factory Response_PasswordlessNotificationMessage.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Response_PasswordlessNotificationMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response.PasswordlessNotificationMessage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'id')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'encryptedMessage', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_PasswordlessNotificationMessage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_PasswordlessNotificationMessage copyWith(
          void Function(Response_PasswordlessNotificationMessage) updates) =>
      super.copyWith((message) =>
              updates(message as Response_PasswordlessNotificationMessage))
          as Response_PasswordlessNotificationMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_PasswordlessNotificationMessage create() =>
      Response_PasswordlessNotificationMessage._();
  @$core.override
  Response_PasswordlessNotificationMessage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Response_PasswordlessNotificationMessage getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          Response_PasswordlessNotificationMessage>(create);
  static Response_PasswordlessNotificationMessage? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get id => $_getI64(0);
  @$pb.TagNumber(1)
  set id($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasId() => $_has(0);
  @$pb.TagNumber(1)
  void clearId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get encryptedMessage => $_getN(1);
  @$pb.TagNumber(2)
  set encryptedMessage($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasEncryptedMessage() => $_has(1);
  @$pb.TagNumber(2)
  void clearEncryptedMessage() => $_clearField(2);
}

class Response_PasswordlessNotificationMessages extends $pb.GeneratedMessage {
  factory Response_PasswordlessNotificationMessages({
    $core.Iterable<Response_PasswordlessNotificationMessage>? messages,
  }) {
    final result = create();
    if (messages != null) result.messages.addAll(messages);
    return result;
  }

  Response_PasswordlessNotificationMessages._();

  factory Response_PasswordlessNotificationMessages.fromBuffer(
          $core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Response_PasswordlessNotificationMessages.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response.PasswordlessNotificationMessages',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..pPM<Response_PasswordlessNotificationMessage>(
        1, _omitFieldNames ? '' : 'messages',
        subBuilder: Response_PasswordlessNotificationMessage.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_PasswordlessNotificationMessages clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_PasswordlessNotificationMessages copyWith(
          void Function(Response_PasswordlessNotificationMessages) updates) =>
      super.copyWith((message) =>
              updates(message as Response_PasswordlessNotificationMessages))
          as Response_PasswordlessNotificationMessages;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_PasswordlessNotificationMessages create() =>
      Response_PasswordlessNotificationMessages._();
  @$core.override
  Response_PasswordlessNotificationMessages createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Response_PasswordlessNotificationMessages getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<
          Response_PasswordlessNotificationMessages>(create);
  static Response_PasswordlessNotificationMessages? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Response_PasswordlessNotificationMessage> get messages =>
      $_getList(0);
}

class Response_PresignedPost extends $pb.GeneratedMessage {
  factory Response_PresignedPost({
    $core.String? url,
    $core.Iterable<$core.MapEntry<$core.String, $core.String>>? fields,
  }) {
    final result = create();
    if (url != null) result.url = url;
    if (fields != null) result.fields.addEntries(fields);
    return result;
  }

  Response_PresignedPost._();

  factory Response_PresignedPost.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Response_PresignedPost.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response.PresignedPost',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'url')
    ..m<$core.String, $core.String>(2, _omitFieldNames ? '' : 'fields',
        entryClassName: 'Response.PresignedPost.FieldsEntry',
        keyFieldType: $pb.PbFieldType.OS,
        valueFieldType: $pb.PbFieldType.OS,
        packageName: const $pb.PackageName('server_to_client'))
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_PresignedPost clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_PresignedPost copyWith(
          void Function(Response_PresignedPost) updates) =>
      super.copyWith((message) => updates(message as Response_PresignedPost))
          as Response_PresignedPost;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_PresignedPost create() => Response_PresignedPost._();
  @$core.override
  Response_PresignedPost createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Response_PresignedPost getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Response_PresignedPost>(create);
  static Response_PresignedPost? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get url => $_getSZ(0);
  @$pb.TagNumber(1)
  set url($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUrl() => $_has(0);
  @$pb.TagNumber(1)
  void clearUrl() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbMap<$core.String, $core.String> get fields => $_getMap(1);
}

class Response_MemoriesUploadUrls extends $pb.GeneratedMessage {
  factory Response_MemoriesUploadUrls({
    $core.String? mediaId,
    Response_PresignedPost? thumbnailUpload,
    Response_PresignedPost? fullUpload,
  }) {
    final result = create();
    if (mediaId != null) result.mediaId = mediaId;
    if (thumbnailUpload != null) result.thumbnailUpload = thumbnailUpload;
    if (fullUpload != null) result.fullUpload = fullUpload;
    return result;
  }

  Response_MemoriesUploadUrls._();

  factory Response_MemoriesUploadUrls.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Response_MemoriesUploadUrls.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response.MemoriesUploadUrls',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'mediaId')
    ..aOM<Response_PresignedPost>(2, _omitFieldNames ? '' : 'thumbnailUpload',
        subBuilder: Response_PresignedPost.create)
    ..aOM<Response_PresignedPost>(3, _omitFieldNames ? '' : 'fullUpload',
        subBuilder: Response_PresignedPost.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_MemoriesUploadUrls clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_MemoriesUploadUrls copyWith(
          void Function(Response_MemoriesUploadUrls) updates) =>
      super.copyWith(
              (message) => updates(message as Response_MemoriesUploadUrls))
          as Response_MemoriesUploadUrls;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_MemoriesUploadUrls create() =>
      Response_MemoriesUploadUrls._();
  @$core.override
  Response_MemoriesUploadUrls createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Response_MemoriesUploadUrls getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Response_MemoriesUploadUrls>(create);
  static Response_MemoriesUploadUrls? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get mediaId => $_getSZ(0);
  @$pb.TagNumber(1)
  set mediaId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMediaId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMediaId() => $_clearField(1);

  @$pb.TagNumber(2)
  Response_PresignedPost get thumbnailUpload => $_getN(1);
  @$pb.TagNumber(2)
  set thumbnailUpload(Response_PresignedPost value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasThumbnailUpload() => $_has(1);
  @$pb.TagNumber(2)
  void clearThumbnailUpload() => $_clearField(2);
  @$pb.TagNumber(2)
  Response_PresignedPost ensureThumbnailUpload() => $_ensure(1);

  @$pb.TagNumber(3)
  Response_PresignedPost get fullUpload => $_getN(2);
  @$pb.TagNumber(3)
  set fullUpload(Response_PresignedPost value) => $_setField(3, value);
  @$pb.TagNumber(3)
  $core.bool hasFullUpload() => $_has(2);
  @$pb.TagNumber(3)
  void clearFullUpload() => $_clearField(3);
  @$pb.TagNumber(3)
  Response_PresignedPost ensureFullUpload() => $_ensure(2);
}

class Response_MediaItem extends $pb.GeneratedMessage {
  factory Response_MediaItem({
    $core.String? mediaId,
    $fixnum.Int64? originalDate,
    $core.String? thumbnailDownloadUrl,
  }) {
    final result = create();
    if (mediaId != null) result.mediaId = mediaId;
    if (originalDate != null) result.originalDate = originalDate;
    if (thumbnailDownloadUrl != null)
      result.thumbnailDownloadUrl = thumbnailDownloadUrl;
    return result;
  }

  Response_MediaItem._();

  factory Response_MediaItem.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Response_MediaItem.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response.MediaItem',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'mediaId')
    ..aInt64(2, _omitFieldNames ? '' : 'originalDate')
    ..aOS(3, _omitFieldNames ? '' : 'thumbnailDownloadUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_MediaItem clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_MediaItem copyWith(void Function(Response_MediaItem) updates) =>
      super.copyWith((message) => updates(message as Response_MediaItem))
          as Response_MediaItem;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_MediaItem create() => Response_MediaItem._();
  @$core.override
  Response_MediaItem createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Response_MediaItem getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Response_MediaItem>(create);
  static Response_MediaItem? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get mediaId => $_getSZ(0);
  @$pb.TagNumber(1)
  set mediaId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMediaId() => $_has(0);
  @$pb.TagNumber(1)
  void clearMediaId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get originalDate => $_getI64(1);
  @$pb.TagNumber(2)
  set originalDate($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasOriginalDate() => $_has(1);
  @$pb.TagNumber(2)
  void clearOriginalDate() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get thumbnailDownloadUrl => $_getSZ(2);
  @$pb.TagNumber(3)
  set thumbnailDownloadUrl($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasThumbnailDownloadUrl() => $_has(2);
  @$pb.TagNumber(3)
  void clearThumbnailDownloadUrl() => $_clearField(3);
}

class Response_MemoriesList extends $pb.GeneratedMessage {
  factory Response_MemoriesList({
    $core.Iterable<Response_MediaItem>? items,
  }) {
    final result = create();
    if (items != null) result.items.addAll(items);
    return result;
  }

  Response_MemoriesList._();

  factory Response_MemoriesList.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Response_MemoriesList.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response.MemoriesList',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..pPM<Response_MediaItem>(1, _omitFieldNames ? '' : 'items',
        subBuilder: Response_MediaItem.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_MemoriesList clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_MemoriesList copyWith(
          void Function(Response_MemoriesList) updates) =>
      super.copyWith((message) => updates(message as Response_MemoriesList))
          as Response_MemoriesList;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_MemoriesList create() => Response_MemoriesList._();
  @$core.override
  Response_MemoriesList createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Response_MemoriesList getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Response_MemoriesList>(create);
  static Response_MemoriesList? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Response_MediaItem> get items => $_getList(0);
}

class Response_MemoriesUrl extends $pb.GeneratedMessage {
  factory Response_MemoriesUrl({
    $core.String? fullDownloadUrl,
  }) {
    final result = create();
    if (fullDownloadUrl != null) result.fullDownloadUrl = fullDownloadUrl;
    return result;
  }

  Response_MemoriesUrl._();

  factory Response_MemoriesUrl.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Response_MemoriesUrl.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response.MemoriesUrl',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'fullDownloadUrl')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_MemoriesUrl clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_MemoriesUrl copyWith(void Function(Response_MemoriesUrl) updates) =>
      super.copyWith((message) => updates(message as Response_MemoriesUrl))
          as Response_MemoriesUrl;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_MemoriesUrl create() => Response_MemoriesUrl._();
  @$core.override
  Response_MemoriesUrl createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Response_MemoriesUrl getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Response_MemoriesUrl>(create);
  static Response_MemoriesUrl? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get fullDownloadUrl => $_getSZ(0);
  @$pb.TagNumber(1)
  set fullDownloadUrl($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasFullDownloadUrl() => $_has(0);
  @$pb.TagNumber(1)
  void clearFullDownloadUrl() => $_clearField(1);
}

class Response_MemoriesUsage extends $pb.GeneratedMessage {
  factory Response_MemoriesUsage({
    $fixnum.Int64? maxBytes,
    $fixnum.Int64? currentBytes,
    $fixnum.Int64? count,
  }) {
    final result = create();
    if (maxBytes != null) result.maxBytes = maxBytes;
    if (currentBytes != null) result.currentBytes = currentBytes;
    if (count != null) result.count = count;
    return result;
  }

  Response_MemoriesUsage._();

  factory Response_MemoriesUsage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Response_MemoriesUsage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response.MemoriesUsage',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'maxBytes')
    ..aInt64(2, _omitFieldNames ? '' : 'currentBytes')
    ..aInt64(3, _omitFieldNames ? '' : 'count')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_MemoriesUsage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_MemoriesUsage copyWith(
          void Function(Response_MemoriesUsage) updates) =>
      super.copyWith((message) => updates(message as Response_MemoriesUsage))
          as Response_MemoriesUsage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_MemoriesUsage create() => Response_MemoriesUsage._();
  @$core.override
  Response_MemoriesUsage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Response_MemoriesUsage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Response_MemoriesUsage>(create);
  static Response_MemoriesUsage? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get maxBytes => $_getI64(0);
  @$pb.TagNumber(1)
  set maxBytes($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMaxBytes() => $_has(0);
  @$pb.TagNumber(1)
  void clearMaxBytes() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get currentBytes => $_getI64(1);
  @$pb.TagNumber(2)
  set currentBytes($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasCurrentBytes() => $_has(1);
  @$pb.TagNumber(2)
  void clearCurrentBytes() => $_clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get count => $_getI64(2);
  @$pb.TagNumber(3)
  set count($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCount() => $_has(2);
  @$pb.TagNumber(3)
  void clearCount() => $_clearField(3);
}

enum Response_Ok_Ok {
  none,
  userid,
  authchallenge,
  uploadtoken,
  userdata,
  authtoken,
  authenticated,
  plans,
  planballance,
  addaccountsinvites,
  downloadtokens,
  signedprekey,
  proofOfWork,
  passwordlessRecoveryServerKey,
  passwordlessNotificationMessages,
  memoriesUploadUrls,
  memoriesList,
  memoriesUrl,
  memoriesUsage,
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
    Response_Authenticated? authenticated,
    Response_Plans? plans,
    Response_PlanBallance? planballance,
    Response_AddAccountsInvites? addaccountsinvites,
    Response_DownloadTokens? downloadtokens,
    Response_SignedPreKey? signedprekey,
    Response_ProofOfWork? proofOfWork,
    $core.List<$core.int>? passwordlessRecoveryServerKey,
    Response_PasswordlessNotificationMessages? passwordlessNotificationMessages,
    Response_MemoriesUploadUrls? memoriesUploadUrls,
    Response_MemoriesList? memoriesList,
    Response_MemoriesUrl? memoriesUrl,
    Response_MemoriesUsage? memoriesUsage,
  }) {
    final result = create();
    if (none != null) result.none = none;
    if (userid != null) result.userid = userid;
    if (authchallenge != null) result.authchallenge = authchallenge;
    if (uploadtoken != null) result.uploadtoken = uploadtoken;
    if (userdata != null) result.userdata = userdata;
    if (authtoken != null) result.authtoken = authtoken;
    if (authenticated != null) result.authenticated = authenticated;
    if (plans != null) result.plans = plans;
    if (planballance != null) result.planballance = planballance;
    if (addaccountsinvites != null)
      result.addaccountsinvites = addaccountsinvites;
    if (downloadtokens != null) result.downloadtokens = downloadtokens;
    if (signedprekey != null) result.signedprekey = signedprekey;
    if (proofOfWork != null) result.proofOfWork = proofOfWork;
    if (passwordlessRecoveryServerKey != null)
      result.passwordlessRecoveryServerKey = passwordlessRecoveryServerKey;
    if (passwordlessNotificationMessages != null)
      result.passwordlessNotificationMessages =
          passwordlessNotificationMessages;
    if (memoriesUploadUrls != null)
      result.memoriesUploadUrls = memoriesUploadUrls;
    if (memoriesList != null) result.memoriesList = memoriesList;
    if (memoriesUrl != null) result.memoriesUrl = memoriesUrl;
    if (memoriesUsage != null) result.memoriesUsage = memoriesUsage;
    return result;
  }

  Response_Ok._();

  factory Response_Ok.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Response_Ok.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, Response_Ok_Ok> _Response_Ok_OkByTag = {
    1: Response_Ok_Ok.none,
    2: Response_Ok_Ok.userid,
    3: Response_Ok_Ok.authchallenge,
    4: Response_Ok_Ok.uploadtoken,
    5: Response_Ok_Ok.userdata,
    6: Response_Ok_Ok.authtoken,
    8: Response_Ok_Ok.authenticated,
    9: Response_Ok_Ok.plans,
    10: Response_Ok_Ok.planballance,
    12: Response_Ok_Ok.addaccountsinvites,
    13: Response_Ok_Ok.downloadtokens,
    14: Response_Ok_Ok.signedprekey,
    15: Response_Ok_Ok.proofOfWork,
    16: Response_Ok_Ok.passwordlessRecoveryServerKey,
    17: Response_Ok_Ok.passwordlessNotificationMessages,
    18: Response_Ok_Ok.memoriesUploadUrls,
    19: Response_Ok_Ok.memoriesList,
    20: Response_Ok_Ok.memoriesUrl,
    21: Response_Ok_Ok.memoriesUsage,
    0: Response_Ok_Ok.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response.Ok',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..oo(
        0, [1, 2, 3, 4, 5, 6, 8, 9, 10, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21])
    ..aOB(1, _omitFieldNames ? '' : 'None', protoName: 'None')
    ..aInt64(2, _omitFieldNames ? '' : 'userid')
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'authchallenge', $pb.PbFieldType.OY)
    ..aOM<Response_UploadToken>(4, _omitFieldNames ? '' : 'uploadtoken',
        subBuilder: Response_UploadToken.create)
    ..aOM<Response_UserData>(5, _omitFieldNames ? '' : 'userdata',
        subBuilder: Response_UserData.create)
    ..a<$core.List<$core.int>>(
        6, _omitFieldNames ? '' : 'authtoken', $pb.PbFieldType.OY)
    ..aOM<Response_Authenticated>(8, _omitFieldNames ? '' : 'authenticated',
        subBuilder: Response_Authenticated.create)
    ..aOM<Response_Plans>(9, _omitFieldNames ? '' : 'plans',
        subBuilder: Response_Plans.create)
    ..aOM<Response_PlanBallance>(10, _omitFieldNames ? '' : 'planballance',
        subBuilder: Response_PlanBallance.create)
    ..aOM<Response_AddAccountsInvites>(
        12, _omitFieldNames ? '' : 'addaccountsinvites',
        subBuilder: Response_AddAccountsInvites.create)
    ..aOM<Response_DownloadTokens>(13, _omitFieldNames ? '' : 'downloadtokens',
        subBuilder: Response_DownloadTokens.create)
    ..aOM<Response_SignedPreKey>(14, _omitFieldNames ? '' : 'signedprekey',
        subBuilder: Response_SignedPreKey.create)
    ..aOM<Response_ProofOfWork>(15, _omitFieldNames ? '' : 'proofOfWork',
        protoName: 'proofOfWork', subBuilder: Response_ProofOfWork.create)
    ..a<$core.List<$core.int>>(
        16,
        _omitFieldNames ? '' : 'passwordlessRecoveryServerKey',
        $pb.PbFieldType.OY)
    ..aOM<Response_PasswordlessNotificationMessages>(
        17, _omitFieldNames ? '' : 'passwordlessNotificationMessages',
        subBuilder: Response_PasswordlessNotificationMessages.create)
    ..aOM<Response_MemoriesUploadUrls>(
        18, _omitFieldNames ? '' : 'memoriesUploadUrls',
        subBuilder: Response_MemoriesUploadUrls.create)
    ..aOM<Response_MemoriesList>(19, _omitFieldNames ? '' : 'memoriesList',
        subBuilder: Response_MemoriesList.create)
    ..aOM<Response_MemoriesUrl>(20, _omitFieldNames ? '' : 'memoriesUrl',
        subBuilder: Response_MemoriesUrl.create)
    ..aOM<Response_MemoriesUsage>(21, _omitFieldNames ? '' : 'memoriesUsage',
        subBuilder: Response_MemoriesUsage.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_Ok clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_Ok copyWith(void Function(Response_Ok) updates) =>
      super.copyWith((message) => updates(message as Response_Ok))
          as Response_Ok;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_Ok create() => Response_Ok._();
  @$core.override
  Response_Ok createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Response_Ok getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Response_Ok>(create);
  static Response_Ok? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  @$pb.TagNumber(18)
  @$pb.TagNumber(19)
  @$pb.TagNumber(20)
  @$pb.TagNumber(21)
  Response_Ok_Ok whichOk() => _Response_Ok_OkByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  @$pb.TagNumber(3)
  @$pb.TagNumber(4)
  @$pb.TagNumber(5)
  @$pb.TagNumber(6)
  @$pb.TagNumber(8)
  @$pb.TagNumber(9)
  @$pb.TagNumber(10)
  @$pb.TagNumber(12)
  @$pb.TagNumber(13)
  @$pb.TagNumber(14)
  @$pb.TagNumber(15)
  @$pb.TagNumber(16)
  @$pb.TagNumber(17)
  @$pb.TagNumber(18)
  @$pb.TagNumber(19)
  @$pb.TagNumber(20)
  @$pb.TagNumber(21)
  void clearOk() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  $core.bool get none => $_getBF(0);
  @$pb.TagNumber(1)
  set none($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasNone() => $_has(0);
  @$pb.TagNumber(1)
  void clearNone() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get userid => $_getI64(1);
  @$pb.TagNumber(2)
  set userid($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasUserid() => $_has(1);
  @$pb.TagNumber(2)
  void clearUserid() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get authchallenge => $_getN(2);
  @$pb.TagNumber(3)
  set authchallenge($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasAuthchallenge() => $_has(2);
  @$pb.TagNumber(3)
  void clearAuthchallenge() => $_clearField(3);

  @$pb.TagNumber(4)
  Response_UploadToken get uploadtoken => $_getN(3);
  @$pb.TagNumber(4)
  set uploadtoken(Response_UploadToken value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasUploadtoken() => $_has(3);
  @$pb.TagNumber(4)
  void clearUploadtoken() => $_clearField(4);
  @$pb.TagNumber(4)
  Response_UploadToken ensureUploadtoken() => $_ensure(3);

  @$pb.TagNumber(5)
  Response_UserData get userdata => $_getN(4);
  @$pb.TagNumber(5)
  set userdata(Response_UserData value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasUserdata() => $_has(4);
  @$pb.TagNumber(5)
  void clearUserdata() => $_clearField(5);
  @$pb.TagNumber(5)
  Response_UserData ensureUserdata() => $_ensure(4);

  @$pb.TagNumber(6)
  $core.List<$core.int> get authtoken => $_getN(5);
  @$pb.TagNumber(6)
  set authtoken($core.List<$core.int> value) => $_setBytes(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAuthtoken() => $_has(5);
  @$pb.TagNumber(6)
  void clearAuthtoken() => $_clearField(6);

  @$pb.TagNumber(8)
  Response_Authenticated get authenticated => $_getN(6);
  @$pb.TagNumber(8)
  set authenticated(Response_Authenticated value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasAuthenticated() => $_has(6);
  @$pb.TagNumber(8)
  void clearAuthenticated() => $_clearField(8);
  @$pb.TagNumber(8)
  Response_Authenticated ensureAuthenticated() => $_ensure(6);

  @$pb.TagNumber(9)
  Response_Plans get plans => $_getN(7);
  @$pb.TagNumber(9)
  set plans(Response_Plans value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasPlans() => $_has(7);
  @$pb.TagNumber(9)
  void clearPlans() => $_clearField(9);
  @$pb.TagNumber(9)
  Response_Plans ensurePlans() => $_ensure(7);

  @$pb.TagNumber(10)
  Response_PlanBallance get planballance => $_getN(8);
  @$pb.TagNumber(10)
  set planballance(Response_PlanBallance value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasPlanballance() => $_has(8);
  @$pb.TagNumber(10)
  void clearPlanballance() => $_clearField(10);
  @$pb.TagNumber(10)
  Response_PlanBallance ensurePlanballance() => $_ensure(8);

  @$pb.TagNumber(12)
  Response_AddAccountsInvites get addaccountsinvites => $_getN(9);
  @$pb.TagNumber(12)
  set addaccountsinvites(Response_AddAccountsInvites value) =>
      $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasAddaccountsinvites() => $_has(9);
  @$pb.TagNumber(12)
  void clearAddaccountsinvites() => $_clearField(12);
  @$pb.TagNumber(12)
  Response_AddAccountsInvites ensureAddaccountsinvites() => $_ensure(9);

  @$pb.TagNumber(13)
  Response_DownloadTokens get downloadtokens => $_getN(10);
  @$pb.TagNumber(13)
  set downloadtokens(Response_DownloadTokens value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasDownloadtokens() => $_has(10);
  @$pb.TagNumber(13)
  void clearDownloadtokens() => $_clearField(13);
  @$pb.TagNumber(13)
  Response_DownloadTokens ensureDownloadtokens() => $_ensure(10);

  @$pb.TagNumber(14)
  Response_SignedPreKey get signedprekey => $_getN(11);
  @$pb.TagNumber(14)
  set signedprekey(Response_SignedPreKey value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasSignedprekey() => $_has(11);
  @$pb.TagNumber(14)
  void clearSignedprekey() => $_clearField(14);
  @$pb.TagNumber(14)
  Response_SignedPreKey ensureSignedprekey() => $_ensure(11);

  @$pb.TagNumber(15)
  Response_ProofOfWork get proofOfWork => $_getN(12);
  @$pb.TagNumber(15)
  set proofOfWork(Response_ProofOfWork value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasProofOfWork() => $_has(12);
  @$pb.TagNumber(15)
  void clearProofOfWork() => $_clearField(15);
  @$pb.TagNumber(15)
  Response_ProofOfWork ensureProofOfWork() => $_ensure(12);

  @$pb.TagNumber(16)
  $core.List<$core.int> get passwordlessRecoveryServerKey => $_getN(13);
  @$pb.TagNumber(16)
  set passwordlessRecoveryServerKey($core.List<$core.int> value) =>
      $_setBytes(13, value);
  @$pb.TagNumber(16)
  $core.bool hasPasswordlessRecoveryServerKey() => $_has(13);
  @$pb.TagNumber(16)
  void clearPasswordlessRecoveryServerKey() => $_clearField(16);

  @$pb.TagNumber(17)
  Response_PasswordlessNotificationMessages
      get passwordlessNotificationMessages => $_getN(14);
  @$pb.TagNumber(17)
  set passwordlessNotificationMessages(
          Response_PasswordlessNotificationMessages value) =>
      $_setField(17, value);
  @$pb.TagNumber(17)
  $core.bool hasPasswordlessNotificationMessages() => $_has(14);
  @$pb.TagNumber(17)
  void clearPasswordlessNotificationMessages() => $_clearField(17);
  @$pb.TagNumber(17)
  Response_PasswordlessNotificationMessages
      ensurePasswordlessNotificationMessages() => $_ensure(14);

  @$pb.TagNumber(18)
  Response_MemoriesUploadUrls get memoriesUploadUrls => $_getN(15);
  @$pb.TagNumber(18)
  set memoriesUploadUrls(Response_MemoriesUploadUrls value) =>
      $_setField(18, value);
  @$pb.TagNumber(18)
  $core.bool hasMemoriesUploadUrls() => $_has(15);
  @$pb.TagNumber(18)
  void clearMemoriesUploadUrls() => $_clearField(18);
  @$pb.TagNumber(18)
  Response_MemoriesUploadUrls ensureMemoriesUploadUrls() => $_ensure(15);

  @$pb.TagNumber(19)
  Response_MemoriesList get memoriesList => $_getN(16);
  @$pb.TagNumber(19)
  set memoriesList(Response_MemoriesList value) => $_setField(19, value);
  @$pb.TagNumber(19)
  $core.bool hasMemoriesList() => $_has(16);
  @$pb.TagNumber(19)
  void clearMemoriesList() => $_clearField(19);
  @$pb.TagNumber(19)
  Response_MemoriesList ensureMemoriesList() => $_ensure(16);

  @$pb.TagNumber(20)
  Response_MemoriesUrl get memoriesUrl => $_getN(17);
  @$pb.TagNumber(20)
  set memoriesUrl(Response_MemoriesUrl value) => $_setField(20, value);
  @$pb.TagNumber(20)
  $core.bool hasMemoriesUrl() => $_has(17);
  @$pb.TagNumber(20)
  void clearMemoriesUrl() => $_clearField(20);
  @$pb.TagNumber(20)
  Response_MemoriesUrl ensureMemoriesUrl() => $_ensure(17);

  @$pb.TagNumber(21)
  Response_MemoriesUsage get memoriesUsage => $_getN(18);
  @$pb.TagNumber(21)
  set memoriesUsage(Response_MemoriesUsage value) => $_setField(21, value);
  @$pb.TagNumber(21)
  $core.bool hasMemoriesUsage() => $_has(18);
  @$pb.TagNumber(21)
  void clearMemoriesUsage() => $_clearField(21);
  @$pb.TagNumber(21)
  Response_MemoriesUsage ensureMemoriesUsage() => $_ensure(18);
}

enum Response_Response { ok, error, notSet }

class Response extends $pb.GeneratedMessage {
  factory Response({
    Response_Ok? ok,
    $0.ErrorCode? error,
  }) {
    final result = create();
    if (ok != null) result.ok = ok;
    if (error != null) result.error = error;
    return result;
  }

  Response._();

  factory Response.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Response.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static const $core.Map<$core.int, Response_Response> _Response_ResponseByTag =
      {
    1: Response_Response.ok,
    2: Response_Response.error,
    0: Response_Response.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..oo(0, [1, 2])
    ..aOM<Response_Ok>(1, _omitFieldNames ? '' : 'ok',
        subBuilder: Response_Ok.create)
    ..aE<$0.ErrorCode>(2, _omitFieldNames ? '' : 'error',
        enumValues: $0.ErrorCode.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response copyWith(void Function(Response) updates) =>
      super.copyWith((message) => updates(message as Response)) as Response;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response create() => Response._();
  @$core.override
  Response createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static Response getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Response>(create);
  static Response? _defaultInstance;

  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  Response_Response whichResponse() =>
      _Response_ResponseByTag[$_whichOneof(0)]!;
  @$pb.TagNumber(1)
  @$pb.TagNumber(2)
  void clearResponse() => $_clearField($_whichOneof(0));

  @$pb.TagNumber(1)
  Response_Ok get ok => $_getN(0);
  @$pb.TagNumber(1)
  set ok(Response_Ok value) => $_setField(1, value);
  @$pb.TagNumber(1)
  $core.bool hasOk() => $_has(0);
  @$pb.TagNumber(1)
  void clearOk() => $_clearField(1);
  @$pb.TagNumber(1)
  Response_Ok ensureOk() => $_ensure(0);

  @$pb.TagNumber(2)
  $0.ErrorCode get error => $_getN(1);
  @$pb.TagNumber(2)
  set error($0.ErrorCode value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasError() => $_has(1);
  @$pb.TagNumber(2)
  void clearError() => $_clearField(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
