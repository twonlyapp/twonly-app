//
//  Generated code. Do not modify.
//  source: api/http/http_requests.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

class TextMessage extends $pb.GeneratedMessage {
  factory TextMessage({
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
  TextMessage._() : super();
  factory TextMessage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory TextMessage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'TextMessage', package: const $pb.PackageName(_omitMessageNames ? '' : 'http_requests'), createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'userId')
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'body', $pb.PbFieldType.OY)
    ..a<$core.List<$core.int>>(3, _omitFieldNames ? '' : 'pushData', $pb.PbFieldType.OY)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  TextMessage clone() => TextMessage()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  TextMessage copyWith(void Function(TextMessage) updates) => super.copyWith((message) => updates(message as TextMessage)) as TextMessage;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static TextMessage create() => TextMessage._();
  TextMessage createEmptyInstance() => create();
  static $pb.PbList<TextMessage> createRepeated() => $pb.PbList<TextMessage>();
  @$core.pragma('dart2js:noInline')
  static TextMessage getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<TextMessage>(create);
  static TextMessage? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get userId => $_getI64(0);
  @$pb.TagNumber(1)
  set userId($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasUserId() => $_has(0);
  @$pb.TagNumber(1)
  void clearUserId() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get body => $_getN(1);
  @$pb.TagNumber(2)
  set body($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasBody() => $_has(1);
  @$pb.TagNumber(2)
  void clearBody() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get pushData => $_getN(2);
  @$pb.TagNumber(3)
  set pushData($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasPushData() => $_has(2);
  @$pb.TagNumber(3)
  void clearPushData() => clearField(3);
}

class UploadRequest extends $pb.GeneratedMessage {
  factory UploadRequest({
    $core.List<$core.int>? encryptedData,
    $core.Iterable<$core.List<$core.int>>? downloadTokens,
    $core.Iterable<TextMessage>? messagesOnSuccess,
  }) {
    final $result = create();
    if (encryptedData != null) {
      $result.encryptedData = encryptedData;
    }
    if (downloadTokens != null) {
      $result.downloadTokens.addAll(downloadTokens);
    }
    if (messagesOnSuccess != null) {
      $result.messagesOnSuccess.addAll(messagesOnSuccess);
    }
    return $result;
  }
  UploadRequest._() : super();
  factory UploadRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory UploadRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'UploadRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'http_requests'), createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'encryptedData', $pb.PbFieldType.OY)
    ..p<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'downloadTokens', $pb.PbFieldType.PY)
    ..pc<TextMessage>(3, _omitFieldNames ? '' : 'messagesOnSuccess', $pb.PbFieldType.PM, subBuilder: TextMessage.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  UploadRequest clone() => UploadRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  UploadRequest copyWith(void Function(UploadRequest) updates) => super.copyWith((message) => updates(message as UploadRequest)) as UploadRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static UploadRequest create() => UploadRequest._();
  UploadRequest createEmptyInstance() => create();
  static $pb.PbList<UploadRequest> createRepeated() => $pb.PbList<UploadRequest>();
  @$core.pragma('dart2js:noInline')
  static UploadRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<UploadRequest>(create);
  static UploadRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get encryptedData => $_getN(0);
  @$pb.TagNumber(1)
  set encryptedData($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasEncryptedData() => $_has(0);
  @$pb.TagNumber(1)
  void clearEncryptedData() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.List<$core.int>> get downloadTokens => $_getList(1);

  @$pb.TagNumber(3)
  $core.List<TextMessage> get messagesOnSuccess => $_getList(2);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
