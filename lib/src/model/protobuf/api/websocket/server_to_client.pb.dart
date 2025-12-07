// This is a generated file - do not edit.
//
// Generated from api/websocket/server_to_client.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'error.pbenum.dart' as $0;
import 'server_to_client.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'server_to_client.pbenum.dart';

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
  ServerToClient clone() => ServerToClient()..mergeFromMessage(this);
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
  static $pb.PbList<ServerToClient> createRepeated() =>
      $pb.PbList<ServerToClient>();
  @$core.pragma('dart2js:noInline')
  static ServerToClient getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<ServerToClient>(create);
  static ServerToClient? _defaultInstance;

  ServerToClient_V whichV() => _ServerToClient_VByTag[$_whichOneof(0)]!;
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

enum V0_Kind { response, newMessage, requestNewPreKeys, error, notSet }

class V0 extends $pb.GeneratedMessage {
  factory V0({
    $fixnum.Int64? seq,
    Response? response,
    NewMessage? newMessage,
    $core.bool? requestNewPreKeys,
    $0.ErrorCode? error,
  }) {
    final result = create();
    if (seq != null) result.seq = seq;
    if (response != null) result.response = response;
    if (newMessage != null) result.newMessage = newMessage;
    if (requestNewPreKeys != null) result.requestNewPreKeys = requestNewPreKeys;
    if (error != null) result.error = error;
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
    0: V0_Kind.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'V0',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..oo(0, [2, 3, 4, 6])
    ..a<$fixnum.Int64>(1, _omitFieldNames ? '' : 'seq', $pb.PbFieldType.OU6,
        defaultOrMaker: $fixnum.Int64.ZERO)
    ..aOM<Response>(2, _omitFieldNames ? '' : 'response',
        subBuilder: Response.create)
    ..aOM<NewMessage>(3, _omitFieldNames ? '' : 'newMessage',
        protoName: 'newMessage', subBuilder: NewMessage.create)
    ..aOB(4, _omitFieldNames ? '' : 'RequestNewPreKeys',
        protoName: 'RequestNewPreKeys')
    ..e<$0.ErrorCode>(6, _omitFieldNames ? '' : 'error', $pb.PbFieldType.OE,
        defaultOrMaker: $0.ErrorCode.Unknown,
        valueOf: $0.ErrorCode.valueOf,
        enumValues: $0.ErrorCode.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  V0 clone() => V0()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  V0 copyWith(void Function(V0) updates) =>
      super.copyWith((message) => updates(message as V0)) as V0;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static V0 create() => V0._();
  @$core.override
  V0 createEmptyInstance() => create();
  static $pb.PbList<V0> createRepeated() => $pb.PbList<V0>();
  @$core.pragma('dart2js:noInline')
  static V0 getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<V0>(create);
  static V0? _defaultInstance;

  V0_Kind whichKind() => _V0_KindByTag[$_whichOneof(0)]!;
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
  NewMessage clone() => NewMessage()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  NewMessage copyWith(void Function(NewMessage) updates) =>
      super.copyWith((message) => updates(message as NewMessage)) as NewMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static NewMessage create() => NewMessage._();
  @$core.override
  NewMessage createEmptyInstance() => create();
  static $pb.PbList<NewMessage> createRepeated() => $pb.PbList<NewMessage>();
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
  Response_Authenticated clone() =>
      Response_Authenticated()..mergeFromMessage(this);
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
  static $pb.PbList<Response_Authenticated> createRepeated() =>
      $pb.PbList<Response_Authenticated>();
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
    $fixnum.Int64? additionalFreeAccounts,
    $fixnum.Int64? monthlyCostsCent,
    $fixnum.Int64? yearlyCostsCent,
    $core.bool? allowedToSendTextMessages,
    $core.bool? isAdditionalAccount,
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
    if (additionalFreeAccounts != null)
      result.additionalFreeAccounts = additionalFreeAccounts;
    if (monthlyCostsCent != null) result.monthlyCostsCent = monthlyCostsCent;
    if (yearlyCostsCent != null) result.yearlyCostsCent = yearlyCostsCent;
    if (allowedToSendTextMessages != null)
      result.allowedToSendTextMessages = allowedToSendTextMessages;
    if (isAdditionalAccount != null)
      result.isAdditionalAccount = isAdditionalAccount;
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
    ..aInt64(6, _omitFieldNames ? '' : 'additionalFreeAccounts')
    ..aInt64(7, _omitFieldNames ? '' : 'monthlyCostsCent')
    ..aInt64(8, _omitFieldNames ? '' : 'yearlyCostsCent')
    ..aOB(9, _omitFieldNames ? '' : 'allowedToSendTextMessages')
    ..aOB(10, _omitFieldNames ? '' : 'isAdditionalAccount')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_Plan clone() => Response_Plan()..mergeFromMessage(this);
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
  static $pb.PbList<Response_Plan> createRepeated() =>
      $pb.PbList<Response_Plan>();
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

  @$pb.TagNumber(6)
  $fixnum.Int64 get additionalFreeAccounts => $_getI64(5);
  @$pb.TagNumber(6)
  set additionalFreeAccounts($fixnum.Int64 value) => $_setInt64(5, value);
  @$pb.TagNumber(6)
  $core.bool hasAdditionalFreeAccounts() => $_has(5);
  @$pb.TagNumber(6)
  void clearAdditionalFreeAccounts() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get monthlyCostsCent => $_getI64(6);
  @$pb.TagNumber(7)
  set monthlyCostsCent($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasMonthlyCostsCent() => $_has(6);
  @$pb.TagNumber(7)
  void clearMonthlyCostsCent() => $_clearField(7);

  @$pb.TagNumber(8)
  $fixnum.Int64 get yearlyCostsCent => $_getI64(7);
  @$pb.TagNumber(8)
  set yearlyCostsCent($fixnum.Int64 value) => $_setInt64(7, value);
  @$pb.TagNumber(8)
  $core.bool hasYearlyCostsCent() => $_has(7);
  @$pb.TagNumber(8)
  void clearYearlyCostsCent() => $_clearField(8);

  @$pb.TagNumber(9)
  $core.bool get allowedToSendTextMessages => $_getBF(8);
  @$pb.TagNumber(9)
  set allowedToSendTextMessages($core.bool value) => $_setBool(8, value);
  @$pb.TagNumber(9)
  $core.bool hasAllowedToSendTextMessages() => $_has(8);
  @$pb.TagNumber(9)
  void clearAllowedToSendTextMessages() => $_clearField(9);

  @$pb.TagNumber(10)
  $core.bool get isAdditionalAccount => $_getBF(9);
  @$pb.TagNumber(10)
  set isAdditionalAccount($core.bool value) => $_setBool(9, value);
  @$pb.TagNumber(10)
  $core.bool hasIsAdditionalAccount() => $_has(9);
  @$pb.TagNumber(10)
  void clearIsAdditionalAccount() => $_clearField(10);
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
    ..pc<Response_Plan>(1, _omitFieldNames ? '' : 'plans', $pb.PbFieldType.PM,
        subBuilder: Response_Plan.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_Plans clone() => Response_Plans()..mergeFromMessage(this);
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
  static $pb.PbList<Response_Plans> createRepeated() =>
      $pb.PbList<Response_Plans>();
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
  Response_AddAccountsInvite clone() =>
      Response_AddAccountsInvite()..mergeFromMessage(this);
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
  static $pb.PbList<Response_AddAccountsInvite> createRepeated() =>
      $pb.PbList<Response_AddAccountsInvite>();
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
    ..pc<Response_AddAccountsInvite>(
        1, _omitFieldNames ? '' : 'invites', $pb.PbFieldType.PM,
        subBuilder: Response_AddAccountsInvite.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_AddAccountsInvites clone() =>
      Response_AddAccountsInvites()..mergeFromMessage(this);
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
  static $pb.PbList<Response_AddAccountsInvites> createRepeated() =>
      $pb.PbList<Response_AddAccountsInvites>();
  @$core.pragma('dart2js:noInline')
  static Response_AddAccountsInvites getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Response_AddAccountsInvites>(create);
  static Response_AddAccountsInvites? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Response_AddAccountsInvite> get invites => $_getList(0);
}

class Response_Transaction extends $pb.GeneratedMessage {
  factory Response_Transaction({
    $fixnum.Int64? depositCents,
    Response_TransactionTypes? transactionType,
    $fixnum.Int64? createdAtUnixTimestamp,
  }) {
    final result = create();
    if (depositCents != null) result.depositCents = depositCents;
    if (transactionType != null) result.transactionType = transactionType;
    if (createdAtUnixTimestamp != null)
      result.createdAtUnixTimestamp = createdAtUnixTimestamp;
    return result;
  }

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
    ..aInt64(1, _omitFieldNames ? '' : 'depositCents')
    ..e<Response_TransactionTypes>(
        2, _omitFieldNames ? '' : 'transactionType', $pb.PbFieldType.OE,
        defaultOrMaker: Response_TransactionTypes.Refund,
        valueOf: Response_TransactionTypes.valueOf,
        enumValues: Response_TransactionTypes.values)
    ..aInt64(3, _omitFieldNames ? '' : 'createdAtUnixTimestamp')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_Transaction clone() =>
      Response_Transaction()..mergeFromMessage(this);
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
  static $pb.PbList<Response_Transaction> createRepeated() =>
      $pb.PbList<Response_Transaction>();
  @$core.pragma('dart2js:noInline')
  static Response_Transaction getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Response_Transaction>(create);
  static Response_Transaction? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get depositCents => $_getI64(0);
  @$pb.TagNumber(1)
  set depositCents($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasDepositCents() => $_has(0);
  @$pb.TagNumber(1)
  void clearDepositCents() => $_clearField(1);

  @$pb.TagNumber(2)
  Response_TransactionTypes get transactionType => $_getN(1);
  @$pb.TagNumber(2)
  set transactionType(Response_TransactionTypes value) => $_setField(2, value);
  @$pb.TagNumber(2)
  $core.bool hasTransactionType() => $_has(1);
  @$pb.TagNumber(2)
  void clearTransactionType() => $_clearField(2);

  /// Represents seconds of UTC time since Unix epoch
  /// 1970-01-01T00:00:00Z. Must be from 0001-01-01T00:00:00Z to
  /// 9999-12-31T23:59:59Z inclusive.
  @$pb.TagNumber(3)
  $fixnum.Int64 get createdAtUnixTimestamp => $_getI64(2);
  @$pb.TagNumber(3)
  set createdAtUnixTimestamp($fixnum.Int64 value) => $_setInt64(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCreatedAtUnixTimestamp() => $_has(2);
  @$pb.TagNumber(3)
  void clearCreatedAtUnixTimestamp() => $_clearField(3);
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
  Response_AdditionalAccount clone() =>
      Response_AdditionalAccount()..mergeFromMessage(this);
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
  static $pb.PbList<Response_AdditionalAccount> createRepeated() =>
      $pb.PbList<Response_AdditionalAccount>();
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

class Response_Voucher extends $pb.GeneratedMessage {
  factory Response_Voucher({
    $core.String? voucherId,
    $fixnum.Int64? valueCents,
    $core.bool? redeemed,
    $core.bool? requested,
    $fixnum.Int64? createdAtUnixTimestamp,
  }) {
    final result = create();
    if (voucherId != null) result.voucherId = voucherId;
    if (valueCents != null) result.valueCents = valueCents;
    if (redeemed != null) result.redeemed = redeemed;
    if (requested != null) result.requested = requested;
    if (createdAtUnixTimestamp != null)
      result.createdAtUnixTimestamp = createdAtUnixTimestamp;
    return result;
  }

  Response_Voucher._();

  factory Response_Voucher.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Response_Voucher.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response.Voucher',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'voucherId')
    ..aInt64(2, _omitFieldNames ? '' : 'valueCents')
    ..aOB(3, _omitFieldNames ? '' : 'redeemed')
    ..aOB(4, _omitFieldNames ? '' : 'requested')
    ..aInt64(5, _omitFieldNames ? '' : 'createdAtUnixTimestamp')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_Voucher clone() => Response_Voucher()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_Voucher copyWith(void Function(Response_Voucher) updates) =>
      super.copyWith((message) => updates(message as Response_Voucher))
          as Response_Voucher;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_Voucher create() => Response_Voucher._();
  @$core.override
  Response_Voucher createEmptyInstance() => create();
  static $pb.PbList<Response_Voucher> createRepeated() =>
      $pb.PbList<Response_Voucher>();
  @$core.pragma('dart2js:noInline')
  static Response_Voucher getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Response_Voucher>(create);
  static Response_Voucher? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get voucherId => $_getSZ(0);
  @$pb.TagNumber(1)
  set voucherId($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasVoucherId() => $_has(0);
  @$pb.TagNumber(1)
  void clearVoucherId() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get valueCents => $_getI64(1);
  @$pb.TagNumber(2)
  set valueCents($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasValueCents() => $_has(1);
  @$pb.TagNumber(2)
  void clearValueCents() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.bool get redeemed => $_getBF(2);
  @$pb.TagNumber(3)
  set redeemed($core.bool value) => $_setBool(2, value);
  @$pb.TagNumber(3)
  $core.bool hasRedeemed() => $_has(2);
  @$pb.TagNumber(3)
  void clearRedeemed() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.bool get requested => $_getBF(3);
  @$pb.TagNumber(4)
  set requested($core.bool value) => $_setBool(3, value);
  @$pb.TagNumber(4)
  $core.bool hasRequested() => $_has(3);
  @$pb.TagNumber(4)
  void clearRequested() => $_clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get createdAtUnixTimestamp => $_getI64(4);
  @$pb.TagNumber(5)
  set createdAtUnixTimestamp($fixnum.Int64 value) => $_setInt64(4, value);
  @$pb.TagNumber(5)
  $core.bool hasCreatedAtUnixTimestamp() => $_has(4);
  @$pb.TagNumber(5)
  void clearCreatedAtUnixTimestamp() => $_clearField(5);
}

class Response_Vouchers extends $pb.GeneratedMessage {
  factory Response_Vouchers({
    $core.Iterable<Response_Voucher>? vouchers,
  }) {
    final result = create();
    if (vouchers != null) result.vouchers.addAll(vouchers);
    return result;
  }

  Response_Vouchers._();

  factory Response_Vouchers.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Response_Vouchers.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response.Vouchers',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..pc<Response_Voucher>(
        1, _omitFieldNames ? '' : 'vouchers', $pb.PbFieldType.PM,
        subBuilder: Response_Voucher.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_Vouchers clone() => Response_Vouchers()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_Vouchers copyWith(void Function(Response_Vouchers) updates) =>
      super.copyWith((message) => updates(message as Response_Vouchers))
          as Response_Vouchers;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_Vouchers create() => Response_Vouchers._();
  @$core.override
  Response_Vouchers createEmptyInstance() => create();
  static $pb.PbList<Response_Vouchers> createRepeated() =>
      $pb.PbList<Response_Vouchers>();
  @$core.pragma('dart2js:noInline')
  static Response_Vouchers getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Response_Vouchers>(create);
  static Response_Vouchers? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<Response_Voucher> get vouchers => $_getList(0);
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
    ..pc<Response_Transaction>(
        5, _omitFieldNames ? '' : 'transactions', $pb.PbFieldType.PM,
        subBuilder: Response_Transaction.create)
    ..pc<Response_AdditionalAccount>(
        6, _omitFieldNames ? '' : 'additionalAccounts', $pb.PbFieldType.PM,
        subBuilder: Response_AdditionalAccount.create)
    ..aOB(7, _omitFieldNames ? '' : 'autoRenewal')
    ..aInt64(8, _omitFieldNames ? '' : 'additionalAccountOwnerId')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_PlanBallance clone() =>
      Response_PlanBallance()..mergeFromMessage(this);
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
  static $pb.PbList<Response_PlanBallance> createRepeated() =>
      $pb.PbList<Response_PlanBallance>();
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

class Response_Location extends $pb.GeneratedMessage {
  factory Response_Location({
    $core.String? county,
    $core.String? region,
    $core.String? city,
  }) {
    final result = create();
    if (county != null) result.county = county;
    if (region != null) result.region = region;
    if (city != null) result.city = city;
    return result;
  }

  Response_Location._();

  factory Response_Location.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory Response_Location.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response.Location',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'county')
    ..aOS(2, _omitFieldNames ? '' : 'region')
    ..aOS(3, _omitFieldNames ? '' : 'city')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_Location clone() => Response_Location()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_Location copyWith(void Function(Response_Location) updates) =>
      super.copyWith((message) => updates(message as Response_Location))
          as Response_Location;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response_Location create() => Response_Location._();
  @$core.override
  Response_Location createEmptyInstance() => create();
  static $pb.PbList<Response_Location> createRepeated() =>
      $pb.PbList<Response_Location>();
  @$core.pragma('dart2js:noInline')
  static Response_Location getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Response_Location>(create);
  static Response_Location? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get county => $_getSZ(0);
  @$pb.TagNumber(1)
  set county($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCounty() => $_has(0);
  @$pb.TagNumber(1)
  void clearCounty() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get region => $_getSZ(1);
  @$pb.TagNumber(2)
  set region($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasRegion() => $_has(1);
  @$pb.TagNumber(2)
  void clearRegion() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get city => $_getSZ(2);
  @$pb.TagNumber(3)
  set city($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasCity() => $_has(2);
  @$pb.TagNumber(3)
  void clearCity() => $_clearField(3);
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
  Response_PreKey clone() => Response_PreKey()..mergeFromMessage(this);
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
  static $pb.PbList<Response_PreKey> createRepeated() =>
      $pb.PbList<Response_PreKey>();
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
  Response_SignedPreKey clone() =>
      Response_SignedPreKey()..mergeFromMessage(this);
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
  static $pb.PbList<Response_SignedPreKey> createRepeated() =>
      $pb.PbList<Response_SignedPreKey>();
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
    final result = create();
    if (userId != null) result.userId = userId;
    if (prekeys != null) result.prekeys.addAll(prekeys);
    if (publicIdentityKey != null) result.publicIdentityKey = publicIdentityKey;
    if (signedPrekey != null) result.signedPrekey = signedPrekey;
    if (signedPrekeySignature != null)
      result.signedPrekeySignature = signedPrekeySignature;
    if (signedPrekeyId != null) result.signedPrekeyId = signedPrekeyId;
    if (username != null) result.username = username;
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
    ..pc<Response_PreKey>(
        2, _omitFieldNames ? '' : 'prekeys', $pb.PbFieldType.PM,
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
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_UserData clone() => Response_UserData()..mergeFromMessage(this);
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
  static $pb.PbList<Response_UserData> createRepeated() =>
      $pb.PbList<Response_UserData>();
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
  Response_UploadToken clone() =>
      Response_UploadToken()..mergeFromMessage(this);
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
  static $pb.PbList<Response_UploadToken> createRepeated() =>
      $pb.PbList<Response_UploadToken>();
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
  Response_DownloadTokens clone() =>
      Response_DownloadTokens()..mergeFromMessage(this);
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
  static $pb.PbList<Response_DownloadTokens> createRepeated() =>
      $pb.PbList<Response_DownloadTokens>();
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
  Response_ProofOfWork clone() =>
      Response_ProofOfWork()..mergeFromMessage(this);
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
  static $pb.PbList<Response_ProofOfWork> createRepeated() =>
      $pb.PbList<Response_ProofOfWork>();
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
  signedprekey,
  proofOfWork,
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
    Response_SignedPreKey? signedprekey,
    Response_ProofOfWork? proofOfWork,
  }) {
    final result = create();
    if (none != null) result.none = none;
    if (userid != null) result.userid = userid;
    if (authchallenge != null) result.authchallenge = authchallenge;
    if (uploadtoken != null) result.uploadtoken = uploadtoken;
    if (userdata != null) result.userdata = userdata;
    if (authtoken != null) result.authtoken = authtoken;
    if (location != null) result.location = location;
    if (authenticated != null) result.authenticated = authenticated;
    if (plans != null) result.plans = plans;
    if (planballance != null) result.planballance = planballance;
    if (vouchers != null) result.vouchers = vouchers;
    if (addaccountsinvites != null)
      result.addaccountsinvites = addaccountsinvites;
    if (downloadtokens != null) result.downloadtokens = downloadtokens;
    if (signedprekey != null) result.signedprekey = signedprekey;
    if (proofOfWork != null) result.proofOfWork = proofOfWork;
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
    7: Response_Ok_Ok.location,
    8: Response_Ok_Ok.authenticated,
    9: Response_Ok_Ok.plans,
    10: Response_Ok_Ok.planballance,
    11: Response_Ok_Ok.vouchers,
    12: Response_Ok_Ok.addaccountsinvites,
    13: Response_Ok_Ok.downloadtokens,
    14: Response_Ok_Ok.signedprekey,
    15: Response_Ok_Ok.proofOfWork,
    0: Response_Ok_Ok.notSet
  };
  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'Response.Ok',
      package:
          const $pb.PackageName(_omitMessageNames ? '' : 'server_to_client'),
      createEmptyInstance: create)
    ..oo(0, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15])
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
    ..aOM<Response_Location>(7, _omitFieldNames ? '' : 'location',
        subBuilder: Response_Location.create)
    ..aOM<Response_Authenticated>(8, _omitFieldNames ? '' : 'authenticated',
        subBuilder: Response_Authenticated.create)
    ..aOM<Response_Plans>(9, _omitFieldNames ? '' : 'plans',
        subBuilder: Response_Plans.create)
    ..aOM<Response_PlanBallance>(10, _omitFieldNames ? '' : 'planballance',
        subBuilder: Response_PlanBallance.create)
    ..aOM<Response_Vouchers>(11, _omitFieldNames ? '' : 'vouchers',
        subBuilder: Response_Vouchers.create)
    ..aOM<Response_AddAccountsInvites>(
        12, _omitFieldNames ? '' : 'addaccountsinvites',
        subBuilder: Response_AddAccountsInvites.create)
    ..aOM<Response_DownloadTokens>(13, _omitFieldNames ? '' : 'downloadtokens',
        subBuilder: Response_DownloadTokens.create)
    ..aOM<Response_SignedPreKey>(14, _omitFieldNames ? '' : 'signedprekey',
        subBuilder: Response_SignedPreKey.create)
    ..aOM<Response_ProofOfWork>(15, _omitFieldNames ? '' : 'proofOfWork',
        protoName: 'proofOfWork', subBuilder: Response_ProofOfWork.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response_Ok clone() => Response_Ok()..mergeFromMessage(this);
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
  static $pb.PbList<Response_Ok> createRepeated() => $pb.PbList<Response_Ok>();
  @$core.pragma('dart2js:noInline')
  static Response_Ok getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<Response_Ok>(create);
  static Response_Ok? _defaultInstance;

  Response_Ok_Ok whichOk() => _Response_Ok_OkByTag[$_whichOneof(0)]!;
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

  @$pb.TagNumber(7)
  Response_Location get location => $_getN(6);
  @$pb.TagNumber(7)
  set location(Response_Location value) => $_setField(7, value);
  @$pb.TagNumber(7)
  $core.bool hasLocation() => $_has(6);
  @$pb.TagNumber(7)
  void clearLocation() => $_clearField(7);
  @$pb.TagNumber(7)
  Response_Location ensureLocation() => $_ensure(6);

  @$pb.TagNumber(8)
  Response_Authenticated get authenticated => $_getN(7);
  @$pb.TagNumber(8)
  set authenticated(Response_Authenticated value) => $_setField(8, value);
  @$pb.TagNumber(8)
  $core.bool hasAuthenticated() => $_has(7);
  @$pb.TagNumber(8)
  void clearAuthenticated() => $_clearField(8);
  @$pb.TagNumber(8)
  Response_Authenticated ensureAuthenticated() => $_ensure(7);

  @$pb.TagNumber(9)
  Response_Plans get plans => $_getN(8);
  @$pb.TagNumber(9)
  set plans(Response_Plans value) => $_setField(9, value);
  @$pb.TagNumber(9)
  $core.bool hasPlans() => $_has(8);
  @$pb.TagNumber(9)
  void clearPlans() => $_clearField(9);
  @$pb.TagNumber(9)
  Response_Plans ensurePlans() => $_ensure(8);

  @$pb.TagNumber(10)
  Response_PlanBallance get planballance => $_getN(9);
  @$pb.TagNumber(10)
  set planballance(Response_PlanBallance value) => $_setField(10, value);
  @$pb.TagNumber(10)
  $core.bool hasPlanballance() => $_has(9);
  @$pb.TagNumber(10)
  void clearPlanballance() => $_clearField(10);
  @$pb.TagNumber(10)
  Response_PlanBallance ensurePlanballance() => $_ensure(9);

  @$pb.TagNumber(11)
  Response_Vouchers get vouchers => $_getN(10);
  @$pb.TagNumber(11)
  set vouchers(Response_Vouchers value) => $_setField(11, value);
  @$pb.TagNumber(11)
  $core.bool hasVouchers() => $_has(10);
  @$pb.TagNumber(11)
  void clearVouchers() => $_clearField(11);
  @$pb.TagNumber(11)
  Response_Vouchers ensureVouchers() => $_ensure(10);

  @$pb.TagNumber(12)
  Response_AddAccountsInvites get addaccountsinvites => $_getN(11);
  @$pb.TagNumber(12)
  set addaccountsinvites(Response_AddAccountsInvites value) =>
      $_setField(12, value);
  @$pb.TagNumber(12)
  $core.bool hasAddaccountsinvites() => $_has(11);
  @$pb.TagNumber(12)
  void clearAddaccountsinvites() => $_clearField(12);
  @$pb.TagNumber(12)
  Response_AddAccountsInvites ensureAddaccountsinvites() => $_ensure(11);

  @$pb.TagNumber(13)
  Response_DownloadTokens get downloadtokens => $_getN(12);
  @$pb.TagNumber(13)
  set downloadtokens(Response_DownloadTokens value) => $_setField(13, value);
  @$pb.TagNumber(13)
  $core.bool hasDownloadtokens() => $_has(12);
  @$pb.TagNumber(13)
  void clearDownloadtokens() => $_clearField(13);
  @$pb.TagNumber(13)
  Response_DownloadTokens ensureDownloadtokens() => $_ensure(12);

  @$pb.TagNumber(14)
  Response_SignedPreKey get signedprekey => $_getN(13);
  @$pb.TagNumber(14)
  set signedprekey(Response_SignedPreKey value) => $_setField(14, value);
  @$pb.TagNumber(14)
  $core.bool hasSignedprekey() => $_has(13);
  @$pb.TagNumber(14)
  void clearSignedprekey() => $_clearField(14);
  @$pb.TagNumber(14)
  Response_SignedPreKey ensureSignedprekey() => $_ensure(13);

  @$pb.TagNumber(15)
  Response_ProofOfWork get proofOfWork => $_getN(14);
  @$pb.TagNumber(15)
  set proofOfWork(Response_ProofOfWork value) => $_setField(15, value);
  @$pb.TagNumber(15)
  $core.bool hasProofOfWork() => $_has(14);
  @$pb.TagNumber(15)
  void clearProofOfWork() => $_clearField(15);
  @$pb.TagNumber(15)
  Response_ProofOfWork ensureProofOfWork() => $_ensure(14);
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
    ..e<$0.ErrorCode>(2, _omitFieldNames ? '' : 'error', $pb.PbFieldType.OE,
        defaultOrMaker: $0.ErrorCode.Unknown,
        valueOf: $0.ErrorCode.valueOf,
        enumValues: $0.ErrorCode.values)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response clone() => Response()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Response copyWith(void Function(Response) updates) =>
      super.copyWith((message) => updates(message as Response)) as Response;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Response create() => Response._();
  @$core.override
  Response createEmptyInstance() => create();
  static $pb.PbList<Response> createRepeated() => $pb.PbList<Response>();
  @$core.pragma('dart2js:noInline')
  static Response getDefault() =>
      _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Response>(create);
  static Response? _defaultInstance;

  Response_Response whichResponse() =>
      _Response_ResponseByTag[$_whichOneof(0)]!;
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
