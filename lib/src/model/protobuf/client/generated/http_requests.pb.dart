// This is a generated file - do not edit.
//
// Generated from http_requests.proto.

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

class TextMessage extends $pb.GeneratedMessage {
  factory TextMessage({
    $fixnum.Int64? userId,
    $core.List<$core.int>? body,
    $core.List<$core.int>? pushData,
  }) {
    final result = create();
    if (userId != null) result.userId = userId;
    if (body != null) result.body = body;
    if (pushData != null) result.pushData = pushData;
    return result;
  }

  TextMessage._();

  factory TextMessage.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory TextMessage.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'TextMessage',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'http_requests'),
      createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'userId')
    ..a<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'body', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(
        3, _omitFieldNames ? '' : 'pushData', $pb.PbFieldType.OY)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TextMessage clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  TextMessage copyWith(void Function(TextMessage) updates) =>
      super.copyWith((message) => updates(message as TextMessage))
          as TextMessage;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TextMessage create() => TextMessage._();
  @$core.override
  TextMessage createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static TextMessage getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<TextMessage>(create);
  static TextMessage? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get userId => $_getI64(0);
  @$pb.TagNumber(1)
  set userId($fixnum.Int64 value) => $_setInt64(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get body => $_getN(1);
  @$pb.TagNumber(2)
  set body($core.List<$core.int> value) => $_setBytes(1, value);
  @$pb.TagNumber(2)
  $core.bool hasBody() => $_has(1);
  @$pb.TagNumber(2)
  void clearBody() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get pushData => $_getN(2);
  @$pb.TagNumber(3)
  set pushData($core.List<$core.int> value) => $_setBytes(2, value);
  @$pb.TagNumber(3)
  $core.bool hasPushData() => $_has(2);
  @$pb.TagNumber(3)
  void clearPushData() => $_clearField(3);
}

class UploadRequest extends $pb.GeneratedMessage {
  factory UploadRequest({
    $core.List<$core.int>? encryptedData,
    $core.Iterable<$core.List<$core.int>>? downloadTokens,
    $core.Iterable<TextMessage>? messagesOnSuccess,
  }) {
    final result = create();
    if (encryptedData != null) result.encryptedData = encryptedData;
    if (downloadTokens != null) result.downloadTokens.addAll(downloadTokens);
    if (messagesOnSuccess != null)
      result.messagesOnSuccess.addAll(messagesOnSuccess);
    return result;
  }

  UploadRequest._();

  factory UploadRequest.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory UploadRequest.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'UploadRequest',
      package: const $pb.PackageName(_omitMessageNames ? '' : 'http_requests'),
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'encryptedData', $pb.PbFieldType.OY)
    ..p<$core.List<$core.int>>(
        2, _omitFieldNames ? '' : 'downloadTokens', $pb.PbFieldType.PY)
    ..pPM<TextMessage>(3, _omitFieldNames ? '' : 'messagesOnSuccess',
        subBuilder: TextMessage.create)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadRequest clone() => deepCopy();
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  UploadRequest copyWith(void Function(UploadRequest) updates) =>
      super.copyWith((message) => updates(message as UploadRequest))
          as UploadRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UploadRequest create() => UploadRequest._();
  @$core.override
  UploadRequest createEmptyInstance() => create();
  @$core.pragma('dart2js:noInline')
  static UploadRequest getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<UploadRequest>(create);
  static UploadRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get encryptedData => $_getN(0);
  @$pb.TagNumber(1)
  set encryptedData($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasEncryptedData() => $_has(0);
  @$pb.TagNumber(1)
  void clearEncryptedData() => $_clearField(1);

  @$pb.TagNumber(2)
  $pb.PbList<$core.List<$core.int>> get downloadTokens => $_getList(1);

  @$pb.TagNumber(3)
  $pb.PbList<TextMessage> get messagesOnSuccess => $_getList(2);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
