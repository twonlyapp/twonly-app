//
//  Generated code. Do not modify.
//  source: messages.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'messages.pbenum.dart';

export 'messages.pbenum.dart';

class Message extends $pb.GeneratedMessage {
  factory Message({
    Message_Type? type,
    $core.String? receiptId,
    $core.List<$core.int>? encryptedContent,
    PlaintextContent? plaintextContent,
  }) {
    final $result = create();
    if (type != null) {
      $result.type = type;
    }
    if (receiptId != null) {
      $result.receiptId = receiptId;
    }
    if (encryptedContent != null) {
      $result.encryptedContent = encryptedContent;
    }
    if (plaintextContent != null) {
      $result.plaintextContent = plaintextContent;
    }
    return $result;
  }
  Message._() : super();
  factory Message.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory Message.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Message', createEmptyInstance: create)
    ..e<Message_Type>(1, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE, defaultOrMaker: Message_Type.SENDER_DELIVERY_RECEIPT, valueOf: Message_Type.valueOf, enumValues: Message_Type.values)
    ..aOS(2, _omitFieldNames ? '' : 'receiptId', protoName: 'receiptId')
    ..a<$core.List<$core.int>>(3, _omitFieldNames ? '' : 'encryptedContent', $pb.PbFieldType.OY, protoName: 'encryptedContent')
    ..aOM<PlaintextContent>(4, _omitFieldNames ? '' : 'plaintextContent', protoName: 'plaintextContent', subBuilder: PlaintextContent.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  Message clone() => Message()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  Message copyWith(void Function(Message) updates) => super.copyWith((message) => updates(message as Message)) as Message;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Message create() => Message._();
  Message createEmptyInstance() => create();
  static $pb.PbList<Message> createRepeated() => $pb.PbList<Message>();
  @$core.pragma('dart2js:noInline')
  static Message getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Message>(create);
  static Message? _defaultInstance;

  @$pb.TagNumber(1)
  Message_Type get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(Message_Type v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get receiptId => $_getSZ(1);
  @$pb.TagNumber(2)
  set receiptId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasReceiptId() => $_has(1);
  @$pb.TagNumber(2)
  void clearReceiptId() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get encryptedContent => $_getN(2);
  @$pb.TagNumber(3)
  set encryptedContent($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasEncryptedContent() => $_has(2);
  @$pb.TagNumber(3)
  void clearEncryptedContent() => clearField(3);

  @$pb.TagNumber(4)
  PlaintextContent get plaintextContent => $_getN(3);
  @$pb.TagNumber(4)
  set plaintextContent(PlaintextContent v) { setField(4, v); }
  @$pb.TagNumber(4)
  $core.bool hasPlaintextContent() => $_has(3);
  @$pb.TagNumber(4)
  void clearPlaintextContent() => clearField(4);
  @$pb.TagNumber(4)
  PlaintextContent ensurePlaintextContent() => $_ensure(3);
}

class PlaintextContent_RetryErrorMessage extends $pb.GeneratedMessage {
  factory PlaintextContent_RetryErrorMessage() => create();
  PlaintextContent_RetryErrorMessage._() : super();
  factory PlaintextContent_RetryErrorMessage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PlaintextContent_RetryErrorMessage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'PlaintextContent.RetryErrorMessage', createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PlaintextContent_RetryErrorMessage clone() => PlaintextContent_RetryErrorMessage()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PlaintextContent_RetryErrorMessage copyWith(void Function(PlaintextContent_RetryErrorMessage) updates) => super.copyWith((message) => updates(message as PlaintextContent_RetryErrorMessage)) as PlaintextContent_RetryErrorMessage;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PlaintextContent_RetryErrorMessage create() => PlaintextContent_RetryErrorMessage._();
  PlaintextContent_RetryErrorMessage createEmptyInstance() => create();
  static $pb.PbList<PlaintextContent_RetryErrorMessage> createRepeated() => $pb.PbList<PlaintextContent_RetryErrorMessage>();
  @$core.pragma('dart2js:noInline')
  static PlaintextContent_RetryErrorMessage getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PlaintextContent_RetryErrorMessage>(create);
  static PlaintextContent_RetryErrorMessage? _defaultInstance;
}

class PlaintextContent_DecryptionErrorMessage extends $pb.GeneratedMessage {
  factory PlaintextContent_DecryptionErrorMessage({
    PlaintextContent_DecryptionErrorMessage_Type? type,
  }) {
    final $result = create();
    if (type != null) {
      $result.type = type;
    }
    return $result;
  }
  PlaintextContent_DecryptionErrorMessage._() : super();
  factory PlaintextContent_DecryptionErrorMessage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PlaintextContent_DecryptionErrorMessage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'PlaintextContent.DecryptionErrorMessage', createEmptyInstance: create)
    ..e<PlaintextContent_DecryptionErrorMessage_Type>(1, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE, defaultOrMaker: PlaintextContent_DecryptionErrorMessage_Type.UNKNOWN, valueOf: PlaintextContent_DecryptionErrorMessage_Type.valueOf, enumValues: PlaintextContent_DecryptionErrorMessage_Type.values)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PlaintextContent_DecryptionErrorMessage clone() => PlaintextContent_DecryptionErrorMessage()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PlaintextContent_DecryptionErrorMessage copyWith(void Function(PlaintextContent_DecryptionErrorMessage) updates) => super.copyWith((message) => updates(message as PlaintextContent_DecryptionErrorMessage)) as PlaintextContent_DecryptionErrorMessage;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PlaintextContent_DecryptionErrorMessage create() => PlaintextContent_DecryptionErrorMessage._();
  PlaintextContent_DecryptionErrorMessage createEmptyInstance() => create();
  static $pb.PbList<PlaintextContent_DecryptionErrorMessage> createRepeated() => $pb.PbList<PlaintextContent_DecryptionErrorMessage>();
  @$core.pragma('dart2js:noInline')
  static PlaintextContent_DecryptionErrorMessage getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PlaintextContent_DecryptionErrorMessage>(create);
  static PlaintextContent_DecryptionErrorMessage? _defaultInstance;

  @$pb.TagNumber(1)
  PlaintextContent_DecryptionErrorMessage_Type get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(PlaintextContent_DecryptionErrorMessage_Type v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);
}

class PlaintextContent extends $pb.GeneratedMessage {
  factory PlaintextContent({
    PlaintextContent_DecryptionErrorMessage? decryptionErrorMessage,
    PlaintextContent_RetryErrorMessage? retryControlError,
  }) {
    final $result = create();
    if (decryptionErrorMessage != null) {
      $result.decryptionErrorMessage = decryptionErrorMessage;
    }
    if (retryControlError != null) {
      $result.retryControlError = retryControlError;
    }
    return $result;
  }
  PlaintextContent._() : super();
  factory PlaintextContent.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory PlaintextContent.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'PlaintextContent', createEmptyInstance: create)
    ..aOM<PlaintextContent_DecryptionErrorMessage>(1, _omitFieldNames ? '' : 'decryptionErrorMessage', protoName: 'decryptionErrorMessage', subBuilder: PlaintextContent_DecryptionErrorMessage.create)
    ..aOM<PlaintextContent_RetryErrorMessage>(2, _omitFieldNames ? '' : 'retryControlError', protoName: 'retryControlError', subBuilder: PlaintextContent_RetryErrorMessage.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  PlaintextContent clone() => PlaintextContent()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  PlaintextContent copyWith(void Function(PlaintextContent) updates) => super.copyWith((message) => updates(message as PlaintextContent)) as PlaintextContent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PlaintextContent create() => PlaintextContent._();
  PlaintextContent createEmptyInstance() => create();
  static $pb.PbList<PlaintextContent> createRepeated() => $pb.PbList<PlaintextContent>();
  @$core.pragma('dart2js:noInline')
  static PlaintextContent getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PlaintextContent>(create);
  static PlaintextContent? _defaultInstance;

  @$pb.TagNumber(1)
  PlaintextContent_DecryptionErrorMessage get decryptionErrorMessage => $_getN(0);
  @$pb.TagNumber(1)
  set decryptionErrorMessage(PlaintextContent_DecryptionErrorMessage v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasDecryptionErrorMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearDecryptionErrorMessage() => clearField(1);
  @$pb.TagNumber(1)
  PlaintextContent_DecryptionErrorMessage ensureDecryptionErrorMessage() => $_ensure(0);

  @$pb.TagNumber(2)
  PlaintextContent_RetryErrorMessage get retryControlError => $_getN(1);
  @$pb.TagNumber(2)
  set retryControlError(PlaintextContent_RetryErrorMessage v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasRetryControlError() => $_has(1);
  @$pb.TagNumber(2)
  void clearRetryControlError() => clearField(2);
  @$pb.TagNumber(2)
  PlaintextContent_RetryErrorMessage ensureRetryControlError() => $_ensure(1);
}

class EncryptedContent_GroupCreate extends $pb.GeneratedMessage {
  factory EncryptedContent_GroupCreate({
    $core.List<$core.int>? stateKey,
    $core.List<$core.int>? groupPublicKey,
  }) {
    final $result = create();
    if (stateKey != null) {
      $result.stateKey = stateKey;
    }
    if (groupPublicKey != null) {
      $result.groupPublicKey = groupPublicKey;
    }
    return $result;
  }
  EncryptedContent_GroupCreate._() : super();
  factory EncryptedContent_GroupCreate.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EncryptedContent_GroupCreate.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EncryptedContent.GroupCreate', createEmptyInstance: create)
    ..a<$core.List<$core.int>>(3, _omitFieldNames ? '' : 'stateKey', $pb.PbFieldType.OY, protoName: 'stateKey')
    ..a<$core.List<$core.int>>(4, _omitFieldNames ? '' : 'groupPublicKey', $pb.PbFieldType.OY, protoName: 'groupPublicKey')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EncryptedContent_GroupCreate clone() => EncryptedContent_GroupCreate()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EncryptedContent_GroupCreate copyWith(void Function(EncryptedContent_GroupCreate) updates) => super.copyWith((message) => updates(message as EncryptedContent_GroupCreate)) as EncryptedContent_GroupCreate;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EncryptedContent_GroupCreate create() => EncryptedContent_GroupCreate._();
  EncryptedContent_GroupCreate createEmptyInstance() => create();
  static $pb.PbList<EncryptedContent_GroupCreate> createRepeated() => $pb.PbList<EncryptedContent_GroupCreate>();
  @$core.pragma('dart2js:noInline')
  static EncryptedContent_GroupCreate getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EncryptedContent_GroupCreate>(create);
  static EncryptedContent_GroupCreate? _defaultInstance;

  /// key for the state stored on the server
  @$pb.TagNumber(3)
  $core.List<$core.int> get stateKey => $_getN(0);
  @$pb.TagNumber(3)
  set stateKey($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(3)
  $core.bool hasStateKey() => $_has(0);
  @$pb.TagNumber(3)
  void clearStateKey() => clearField(3);

  @$pb.TagNumber(4)
  $core.List<$core.int> get groupPublicKey => $_getN(1);
  @$pb.TagNumber(4)
  set groupPublicKey($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(4)
  $core.bool hasGroupPublicKey() => $_has(1);
  @$pb.TagNumber(4)
  void clearGroupPublicKey() => clearField(4);
}

class EncryptedContent_GroupJoin extends $pb.GeneratedMessage {
  factory EncryptedContent_GroupJoin({
    $core.List<$core.int>? groupPublicKey,
  }) {
    final $result = create();
    if (groupPublicKey != null) {
      $result.groupPublicKey = groupPublicKey;
    }
    return $result;
  }
  EncryptedContent_GroupJoin._() : super();
  factory EncryptedContent_GroupJoin.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EncryptedContent_GroupJoin.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EncryptedContent.GroupJoin', createEmptyInstance: create)
    ..a<$core.List<$core.int>>(1, _omitFieldNames ? '' : 'groupPublicKey', $pb.PbFieldType.OY, protoName: 'groupPublicKey')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EncryptedContent_GroupJoin clone() => EncryptedContent_GroupJoin()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EncryptedContent_GroupJoin copyWith(void Function(EncryptedContent_GroupJoin) updates) => super.copyWith((message) => updates(message as EncryptedContent_GroupJoin)) as EncryptedContent_GroupJoin;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EncryptedContent_GroupJoin create() => EncryptedContent_GroupJoin._();
  EncryptedContent_GroupJoin createEmptyInstance() => create();
  static $pb.PbList<EncryptedContent_GroupJoin> createRepeated() => $pb.PbList<EncryptedContent_GroupJoin>();
  @$core.pragma('dart2js:noInline')
  static EncryptedContent_GroupJoin getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EncryptedContent_GroupJoin>(create);
  static EncryptedContent_GroupJoin? _defaultInstance;

  /// key for the state stored on the server
  @$pb.TagNumber(1)
  $core.List<$core.int> get groupPublicKey => $_getN(0);
  @$pb.TagNumber(1)
  set groupPublicKey($core.List<$core.int> v) { $_setBytes(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGroupPublicKey() => $_has(0);
  @$pb.TagNumber(1)
  void clearGroupPublicKey() => clearField(1);
}

class EncryptedContent_ResendGroupPublicKey extends $pb.GeneratedMessage {
  factory EncryptedContent_ResendGroupPublicKey() => create();
  EncryptedContent_ResendGroupPublicKey._() : super();
  factory EncryptedContent_ResendGroupPublicKey.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EncryptedContent_ResendGroupPublicKey.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EncryptedContent.ResendGroupPublicKey', createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EncryptedContent_ResendGroupPublicKey clone() => EncryptedContent_ResendGroupPublicKey()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EncryptedContent_ResendGroupPublicKey copyWith(void Function(EncryptedContent_ResendGroupPublicKey) updates) => super.copyWith((message) => updates(message as EncryptedContent_ResendGroupPublicKey)) as EncryptedContent_ResendGroupPublicKey;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EncryptedContent_ResendGroupPublicKey create() => EncryptedContent_ResendGroupPublicKey._();
  EncryptedContent_ResendGroupPublicKey createEmptyInstance() => create();
  static $pb.PbList<EncryptedContent_ResendGroupPublicKey> createRepeated() => $pb.PbList<EncryptedContent_ResendGroupPublicKey>();
  @$core.pragma('dart2js:noInline')
  static EncryptedContent_ResendGroupPublicKey getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EncryptedContent_ResendGroupPublicKey>(create);
  static EncryptedContent_ResendGroupPublicKey? _defaultInstance;
}

class EncryptedContent_GroupUpdate extends $pb.GeneratedMessage {
  factory EncryptedContent_GroupUpdate({
    $core.String? groupActionType,
    $fixnum.Int64? affectedContactId,
    $core.String? newGroupName,
    $fixnum.Int64? newDeleteMessagesAfterMilliseconds,
  }) {
    final $result = create();
    if (groupActionType != null) {
      $result.groupActionType = groupActionType;
    }
    if (affectedContactId != null) {
      $result.affectedContactId = affectedContactId;
    }
    if (newGroupName != null) {
      $result.newGroupName = newGroupName;
    }
    if (newDeleteMessagesAfterMilliseconds != null) {
      $result.newDeleteMessagesAfterMilliseconds = newDeleteMessagesAfterMilliseconds;
    }
    return $result;
  }
  EncryptedContent_GroupUpdate._() : super();
  factory EncryptedContent_GroupUpdate.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EncryptedContent_GroupUpdate.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EncryptedContent.GroupUpdate', createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'groupActionType', protoName: 'groupActionType')
    ..aInt64(2, _omitFieldNames ? '' : 'affectedContactId', protoName: 'affectedContactId')
    ..aOS(3, _omitFieldNames ? '' : 'newGroupName', protoName: 'newGroupName')
    ..aInt64(4, _omitFieldNames ? '' : 'newDeleteMessagesAfterMilliseconds', protoName: 'newDeleteMessagesAfterMilliseconds')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EncryptedContent_GroupUpdate clone() => EncryptedContent_GroupUpdate()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EncryptedContent_GroupUpdate copyWith(void Function(EncryptedContent_GroupUpdate) updates) => super.copyWith((message) => updates(message as EncryptedContent_GroupUpdate)) as EncryptedContent_GroupUpdate;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EncryptedContent_GroupUpdate create() => EncryptedContent_GroupUpdate._();
  EncryptedContent_GroupUpdate createEmptyInstance() => create();
  static $pb.PbList<EncryptedContent_GroupUpdate> createRepeated() => $pb.PbList<EncryptedContent_GroupUpdate>();
  @$core.pragma('dart2js:noInline')
  static EncryptedContent_GroupUpdate getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EncryptedContent_GroupUpdate>(create);
  static EncryptedContent_GroupUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get groupActionType => $_getSZ(0);
  @$pb.TagNumber(1)
  set groupActionType($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasGroupActionType() => $_has(0);
  @$pb.TagNumber(1)
  void clearGroupActionType() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get affectedContactId => $_getI64(1);
  @$pb.TagNumber(2)
  set affectedContactId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAffectedContactId() => $_has(1);
  @$pb.TagNumber(2)
  void clearAffectedContactId() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get newGroupName => $_getSZ(2);
  @$pb.TagNumber(3)
  set newGroupName($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasNewGroupName() => $_has(2);
  @$pb.TagNumber(3)
  void clearNewGroupName() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get newDeleteMessagesAfterMilliseconds => $_getI64(3);
  @$pb.TagNumber(4)
  set newDeleteMessagesAfterMilliseconds($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasNewDeleteMessagesAfterMilliseconds() => $_has(3);
  @$pb.TagNumber(4)
  void clearNewDeleteMessagesAfterMilliseconds() => clearField(4);
}

class EncryptedContent_TextMessage extends $pb.GeneratedMessage {
  factory EncryptedContent_TextMessage({
    $core.String? senderMessageId,
    $core.String? text,
    $fixnum.Int64? timestamp,
    $core.String? quoteMessageId,
  }) {
    final $result = create();
    if (senderMessageId != null) {
      $result.senderMessageId = senderMessageId;
    }
    if (text != null) {
      $result.text = text;
    }
    if (timestamp != null) {
      $result.timestamp = timestamp;
    }
    if (quoteMessageId != null) {
      $result.quoteMessageId = quoteMessageId;
    }
    return $result;
  }
  EncryptedContent_TextMessage._() : super();
  factory EncryptedContent_TextMessage.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EncryptedContent_TextMessage.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EncryptedContent.TextMessage', createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'senderMessageId', protoName: 'senderMessageId')
    ..aOS(2, _omitFieldNames ? '' : 'text')
    ..aInt64(3, _omitFieldNames ? '' : 'timestamp')
    ..aOS(4, _omitFieldNames ? '' : 'quoteMessageId', protoName: 'quoteMessageId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EncryptedContent_TextMessage clone() => EncryptedContent_TextMessage()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EncryptedContent_TextMessage copyWith(void Function(EncryptedContent_TextMessage) updates) => super.copyWith((message) => updates(message as EncryptedContent_TextMessage)) as EncryptedContent_TextMessage;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EncryptedContent_TextMessage create() => EncryptedContent_TextMessage._();
  EncryptedContent_TextMessage createEmptyInstance() => create();
  static $pb.PbList<EncryptedContent_TextMessage> createRepeated() => $pb.PbList<EncryptedContent_TextMessage>();
  @$core.pragma('dart2js:noInline')
  static EncryptedContent_TextMessage getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EncryptedContent_TextMessage>(create);
  static EncryptedContent_TextMessage? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get senderMessageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set senderMessageId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSenderMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSenderMessageId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get text => $_getSZ(1);
  @$pb.TagNumber(2)
  set text($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasText() => $_has(1);
  @$pb.TagNumber(2)
  void clearText() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get timestamp => $_getI64(2);
  @$pb.TagNumber(3)
  set timestamp($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasTimestamp() => $_has(2);
  @$pb.TagNumber(3)
  void clearTimestamp() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get quoteMessageId => $_getSZ(3);
  @$pb.TagNumber(4)
  set quoteMessageId($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasQuoteMessageId() => $_has(3);
  @$pb.TagNumber(4)
  void clearQuoteMessageId() => clearField(4);
}

class EncryptedContent_Reaction extends $pb.GeneratedMessage {
  factory EncryptedContent_Reaction({
    $core.String? targetMessageId,
    $core.String? emoji,
    $core.bool? remove,
  }) {
    final $result = create();
    if (targetMessageId != null) {
      $result.targetMessageId = targetMessageId;
    }
    if (emoji != null) {
      $result.emoji = emoji;
    }
    if (remove != null) {
      $result.remove = remove;
    }
    return $result;
  }
  EncryptedContent_Reaction._() : super();
  factory EncryptedContent_Reaction.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EncryptedContent_Reaction.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EncryptedContent.Reaction', createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'targetMessageId', protoName: 'targetMessageId')
    ..aOS(2, _omitFieldNames ? '' : 'emoji')
    ..aOB(3, _omitFieldNames ? '' : 'remove')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EncryptedContent_Reaction clone() => EncryptedContent_Reaction()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EncryptedContent_Reaction copyWith(void Function(EncryptedContent_Reaction) updates) => super.copyWith((message) => updates(message as EncryptedContent_Reaction)) as EncryptedContent_Reaction;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EncryptedContent_Reaction create() => EncryptedContent_Reaction._();
  EncryptedContent_Reaction createEmptyInstance() => create();
  static $pb.PbList<EncryptedContent_Reaction> createRepeated() => $pb.PbList<EncryptedContent_Reaction>();
  @$core.pragma('dart2js:noInline')
  static EncryptedContent_Reaction getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EncryptedContent_Reaction>(create);
  static EncryptedContent_Reaction? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get targetMessageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set targetMessageId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasTargetMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearTargetMessageId() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get emoji => $_getSZ(1);
  @$pb.TagNumber(2)
  set emoji($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasEmoji() => $_has(1);
  @$pb.TagNumber(2)
  void clearEmoji() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get remove => $_getBF(2);
  @$pb.TagNumber(3)
  set remove($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasRemove() => $_has(2);
  @$pb.TagNumber(3)
  void clearRemove() => clearField(3);
}

class EncryptedContent_MessageUpdate extends $pb.GeneratedMessage {
  factory EncryptedContent_MessageUpdate({
    EncryptedContent_MessageUpdate_Type? type,
    $core.String? senderMessageId,
    $core.Iterable<$core.String>? multipleTargetMessageIds,
    $core.String? text,
    $fixnum.Int64? timestamp,
  }) {
    final $result = create();
    if (type != null) {
      $result.type = type;
    }
    if (senderMessageId != null) {
      $result.senderMessageId = senderMessageId;
    }
    if (multipleTargetMessageIds != null) {
      $result.multipleTargetMessageIds.addAll(multipleTargetMessageIds);
    }
    if (text != null) {
      $result.text = text;
    }
    if (timestamp != null) {
      $result.timestamp = timestamp;
    }
    return $result;
  }
  EncryptedContent_MessageUpdate._() : super();
  factory EncryptedContent_MessageUpdate.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EncryptedContent_MessageUpdate.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EncryptedContent.MessageUpdate', createEmptyInstance: create)
    ..e<EncryptedContent_MessageUpdate_Type>(1, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE, defaultOrMaker: EncryptedContent_MessageUpdate_Type.DELETE, valueOf: EncryptedContent_MessageUpdate_Type.valueOf, enumValues: EncryptedContent_MessageUpdate_Type.values)
    ..aOS(2, _omitFieldNames ? '' : 'senderMessageId', protoName: 'senderMessageId')
    ..pPS(3, _omitFieldNames ? '' : 'multipleTargetMessageIds', protoName: 'multipleTargetMessageIds')
    ..aOS(4, _omitFieldNames ? '' : 'text')
    ..aInt64(5, _omitFieldNames ? '' : 'timestamp')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EncryptedContent_MessageUpdate clone() => EncryptedContent_MessageUpdate()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EncryptedContent_MessageUpdate copyWith(void Function(EncryptedContent_MessageUpdate) updates) => super.copyWith((message) => updates(message as EncryptedContent_MessageUpdate)) as EncryptedContent_MessageUpdate;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EncryptedContent_MessageUpdate create() => EncryptedContent_MessageUpdate._();
  EncryptedContent_MessageUpdate createEmptyInstance() => create();
  static $pb.PbList<EncryptedContent_MessageUpdate> createRepeated() => $pb.PbList<EncryptedContent_MessageUpdate>();
  @$core.pragma('dart2js:noInline')
  static EncryptedContent_MessageUpdate getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EncryptedContent_MessageUpdate>(create);
  static EncryptedContent_MessageUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  EncryptedContent_MessageUpdate_Type get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(EncryptedContent_MessageUpdate_Type v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get senderMessageId => $_getSZ(1);
  @$pb.TagNumber(2)
  set senderMessageId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasSenderMessageId() => $_has(1);
  @$pb.TagNumber(2)
  void clearSenderMessageId() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.String> get multipleTargetMessageIds => $_getList(2);

  @$pb.TagNumber(4)
  $core.String get text => $_getSZ(3);
  @$pb.TagNumber(4)
  set text($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasText() => $_has(3);
  @$pb.TagNumber(4)
  void clearText() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get timestamp => $_getI64(4);
  @$pb.TagNumber(5)
  set timestamp($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasTimestamp() => $_has(4);
  @$pb.TagNumber(5)
  void clearTimestamp() => clearField(5);
}

class EncryptedContent_Media extends $pb.GeneratedMessage {
  factory EncryptedContent_Media({
    $core.String? senderMessageId,
    EncryptedContent_Media_Type? type,
    $fixnum.Int64? displayLimitInMilliseconds,
    $core.bool? requiresAuthentication,
    $fixnum.Int64? timestamp,
    $core.String? quoteMessageId,
    $core.List<$core.int>? downloadToken,
    $core.List<$core.int>? encryptionKey,
    $core.List<$core.int>? encryptionMac,
    $core.List<$core.int>? encryptionNonce,
  }) {
    final $result = create();
    if (senderMessageId != null) {
      $result.senderMessageId = senderMessageId;
    }
    if (type != null) {
      $result.type = type;
    }
    if (displayLimitInMilliseconds != null) {
      $result.displayLimitInMilliseconds = displayLimitInMilliseconds;
    }
    if (requiresAuthentication != null) {
      $result.requiresAuthentication = requiresAuthentication;
    }
    if (timestamp != null) {
      $result.timestamp = timestamp;
    }
    if (quoteMessageId != null) {
      $result.quoteMessageId = quoteMessageId;
    }
    if (downloadToken != null) {
      $result.downloadToken = downloadToken;
    }
    if (encryptionKey != null) {
      $result.encryptionKey = encryptionKey;
    }
    if (encryptionMac != null) {
      $result.encryptionMac = encryptionMac;
    }
    if (encryptionNonce != null) {
      $result.encryptionNonce = encryptionNonce;
    }
    return $result;
  }
  EncryptedContent_Media._() : super();
  factory EncryptedContent_Media.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EncryptedContent_Media.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EncryptedContent.Media', createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'senderMessageId', protoName: 'senderMessageId')
    ..e<EncryptedContent_Media_Type>(2, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE, defaultOrMaker: EncryptedContent_Media_Type.REUPLOAD, valueOf: EncryptedContent_Media_Type.valueOf, enumValues: EncryptedContent_Media_Type.values)
    ..aInt64(3, _omitFieldNames ? '' : 'displayLimitInMilliseconds', protoName: 'displayLimitInMilliseconds')
    ..aOB(4, _omitFieldNames ? '' : 'requiresAuthentication', protoName: 'requiresAuthentication')
    ..aInt64(5, _omitFieldNames ? '' : 'timestamp')
    ..aOS(6, _omitFieldNames ? '' : 'quoteMessageId', protoName: 'quoteMessageId')
    ..a<$core.List<$core.int>>(7, _omitFieldNames ? '' : 'downloadToken', $pb.PbFieldType.OY, protoName: 'downloadToken')
    ..a<$core.List<$core.int>>(8, _omitFieldNames ? '' : 'encryptionKey', $pb.PbFieldType.OY, protoName: 'encryptionKey')
    ..a<$core.List<$core.int>>(9, _omitFieldNames ? '' : 'encryptionMac', $pb.PbFieldType.OY, protoName: 'encryptionMac')
    ..a<$core.List<$core.int>>(10, _omitFieldNames ? '' : 'encryptionNonce', $pb.PbFieldType.OY, protoName: 'encryptionNonce')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EncryptedContent_Media clone() => EncryptedContent_Media()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EncryptedContent_Media copyWith(void Function(EncryptedContent_Media) updates) => super.copyWith((message) => updates(message as EncryptedContent_Media)) as EncryptedContent_Media;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EncryptedContent_Media create() => EncryptedContent_Media._();
  EncryptedContent_Media createEmptyInstance() => create();
  static $pb.PbList<EncryptedContent_Media> createRepeated() => $pb.PbList<EncryptedContent_Media>();
  @$core.pragma('dart2js:noInline')
  static EncryptedContent_Media getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EncryptedContent_Media>(create);
  static EncryptedContent_Media? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get senderMessageId => $_getSZ(0);
  @$pb.TagNumber(1)
  set senderMessageId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasSenderMessageId() => $_has(0);
  @$pb.TagNumber(1)
  void clearSenderMessageId() => clearField(1);

  @$pb.TagNumber(2)
  EncryptedContent_Media_Type get type => $_getN(1);
  @$pb.TagNumber(2)
  set type(EncryptedContent_Media_Type v) { setField(2, v); }
  @$pb.TagNumber(2)
  $core.bool hasType() => $_has(1);
  @$pb.TagNumber(2)
  void clearType() => clearField(2);

  @$pb.TagNumber(3)
  $fixnum.Int64 get displayLimitInMilliseconds => $_getI64(2);
  @$pb.TagNumber(3)
  set displayLimitInMilliseconds($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasDisplayLimitInMilliseconds() => $_has(2);
  @$pb.TagNumber(3)
  void clearDisplayLimitInMilliseconds() => clearField(3);

  @$pb.TagNumber(4)
  $core.bool get requiresAuthentication => $_getBF(3);
  @$pb.TagNumber(4)
  set requiresAuthentication($core.bool v) { $_setBool(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasRequiresAuthentication() => $_has(3);
  @$pb.TagNumber(4)
  void clearRequiresAuthentication() => clearField(4);

  @$pb.TagNumber(5)
  $fixnum.Int64 get timestamp => $_getI64(4);
  @$pb.TagNumber(5)
  set timestamp($fixnum.Int64 v) { $_setInt64(4, v); }
  @$pb.TagNumber(5)
  $core.bool hasTimestamp() => $_has(4);
  @$pb.TagNumber(5)
  void clearTimestamp() => clearField(5);

  @$pb.TagNumber(6)
  $core.String get quoteMessageId => $_getSZ(5);
  @$pb.TagNumber(6)
  set quoteMessageId($core.String v) { $_setString(5, v); }
  @$pb.TagNumber(6)
  $core.bool hasQuoteMessageId() => $_has(5);
  @$pb.TagNumber(6)
  void clearQuoteMessageId() => clearField(6);

  @$pb.TagNumber(7)
  $core.List<$core.int> get downloadToken => $_getN(6);
  @$pb.TagNumber(7)
  set downloadToken($core.List<$core.int> v) { $_setBytes(6, v); }
  @$pb.TagNumber(7)
  $core.bool hasDownloadToken() => $_has(6);
  @$pb.TagNumber(7)
  void clearDownloadToken() => clearField(7);

  @$pb.TagNumber(8)
  $core.List<$core.int> get encryptionKey => $_getN(7);
  @$pb.TagNumber(8)
  set encryptionKey($core.List<$core.int> v) { $_setBytes(7, v); }
  @$pb.TagNumber(8)
  $core.bool hasEncryptionKey() => $_has(7);
  @$pb.TagNumber(8)
  void clearEncryptionKey() => clearField(8);

  @$pb.TagNumber(9)
  $core.List<$core.int> get encryptionMac => $_getN(8);
  @$pb.TagNumber(9)
  set encryptionMac($core.List<$core.int> v) { $_setBytes(8, v); }
  @$pb.TagNumber(9)
  $core.bool hasEncryptionMac() => $_has(8);
  @$pb.TagNumber(9)
  void clearEncryptionMac() => clearField(9);

  @$pb.TagNumber(10)
  $core.List<$core.int> get encryptionNonce => $_getN(9);
  @$pb.TagNumber(10)
  set encryptionNonce($core.List<$core.int> v) { $_setBytes(9, v); }
  @$pb.TagNumber(10)
  $core.bool hasEncryptionNonce() => $_has(9);
  @$pb.TagNumber(10)
  void clearEncryptionNonce() => clearField(10);
}

class EncryptedContent_MediaUpdate extends $pb.GeneratedMessage {
  factory EncryptedContent_MediaUpdate({
    EncryptedContent_MediaUpdate_Type? type,
    $core.String? targetMessageId,
  }) {
    final $result = create();
    if (type != null) {
      $result.type = type;
    }
    if (targetMessageId != null) {
      $result.targetMessageId = targetMessageId;
    }
    return $result;
  }
  EncryptedContent_MediaUpdate._() : super();
  factory EncryptedContent_MediaUpdate.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EncryptedContent_MediaUpdate.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EncryptedContent.MediaUpdate', createEmptyInstance: create)
    ..e<EncryptedContent_MediaUpdate_Type>(1, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE, defaultOrMaker: EncryptedContent_MediaUpdate_Type.REOPENED, valueOf: EncryptedContent_MediaUpdate_Type.valueOf, enumValues: EncryptedContent_MediaUpdate_Type.values)
    ..aOS(2, _omitFieldNames ? '' : 'targetMessageId', protoName: 'targetMessageId')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EncryptedContent_MediaUpdate clone() => EncryptedContent_MediaUpdate()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EncryptedContent_MediaUpdate copyWith(void Function(EncryptedContent_MediaUpdate) updates) => super.copyWith((message) => updates(message as EncryptedContent_MediaUpdate)) as EncryptedContent_MediaUpdate;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EncryptedContent_MediaUpdate create() => EncryptedContent_MediaUpdate._();
  EncryptedContent_MediaUpdate createEmptyInstance() => create();
  static $pb.PbList<EncryptedContent_MediaUpdate> createRepeated() => $pb.PbList<EncryptedContent_MediaUpdate>();
  @$core.pragma('dart2js:noInline')
  static EncryptedContent_MediaUpdate getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EncryptedContent_MediaUpdate>(create);
  static EncryptedContent_MediaUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  EncryptedContent_MediaUpdate_Type get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(EncryptedContent_MediaUpdate_Type v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $core.String get targetMessageId => $_getSZ(1);
  @$pb.TagNumber(2)
  set targetMessageId($core.String v) { $_setString(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasTargetMessageId() => $_has(1);
  @$pb.TagNumber(2)
  void clearTargetMessageId() => clearField(2);
}

class EncryptedContent_ContactRequest extends $pb.GeneratedMessage {
  factory EncryptedContent_ContactRequest({
    EncryptedContent_ContactRequest_Type? type,
  }) {
    final $result = create();
    if (type != null) {
      $result.type = type;
    }
    return $result;
  }
  EncryptedContent_ContactRequest._() : super();
  factory EncryptedContent_ContactRequest.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EncryptedContent_ContactRequest.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EncryptedContent.ContactRequest', createEmptyInstance: create)
    ..e<EncryptedContent_ContactRequest_Type>(1, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE, defaultOrMaker: EncryptedContent_ContactRequest_Type.REQUEST, valueOf: EncryptedContent_ContactRequest_Type.valueOf, enumValues: EncryptedContent_ContactRequest_Type.values)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EncryptedContent_ContactRequest clone() => EncryptedContent_ContactRequest()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EncryptedContent_ContactRequest copyWith(void Function(EncryptedContent_ContactRequest) updates) => super.copyWith((message) => updates(message as EncryptedContent_ContactRequest)) as EncryptedContent_ContactRequest;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EncryptedContent_ContactRequest create() => EncryptedContent_ContactRequest._();
  EncryptedContent_ContactRequest createEmptyInstance() => create();
  static $pb.PbList<EncryptedContent_ContactRequest> createRepeated() => $pb.PbList<EncryptedContent_ContactRequest>();
  @$core.pragma('dart2js:noInline')
  static EncryptedContent_ContactRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EncryptedContent_ContactRequest>(create);
  static EncryptedContent_ContactRequest? _defaultInstance;

  @$pb.TagNumber(1)
  EncryptedContent_ContactRequest_Type get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(EncryptedContent_ContactRequest_Type v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);
}

class EncryptedContent_ContactUpdate extends $pb.GeneratedMessage {
  factory EncryptedContent_ContactUpdate({
    EncryptedContent_ContactUpdate_Type? type,
    $core.List<$core.int>? avatarSvgCompressed,
    $core.String? username,
    $core.String? displayName,
  }) {
    final $result = create();
    if (type != null) {
      $result.type = type;
    }
    if (avatarSvgCompressed != null) {
      $result.avatarSvgCompressed = avatarSvgCompressed;
    }
    if (username != null) {
      $result.username = username;
    }
    if (displayName != null) {
      $result.displayName = displayName;
    }
    return $result;
  }
  EncryptedContent_ContactUpdate._() : super();
  factory EncryptedContent_ContactUpdate.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EncryptedContent_ContactUpdate.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EncryptedContent.ContactUpdate', createEmptyInstance: create)
    ..e<EncryptedContent_ContactUpdate_Type>(1, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE, defaultOrMaker: EncryptedContent_ContactUpdate_Type.REQUEST, valueOf: EncryptedContent_ContactUpdate_Type.valueOf, enumValues: EncryptedContent_ContactUpdate_Type.values)
    ..a<$core.List<$core.int>>(2, _omitFieldNames ? '' : 'avatarSvgCompressed', $pb.PbFieldType.OY, protoName: 'avatarSvgCompressed')
    ..aOS(3, _omitFieldNames ? '' : 'username')
    ..aOS(4, _omitFieldNames ? '' : 'displayName', protoName: 'displayName')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EncryptedContent_ContactUpdate clone() => EncryptedContent_ContactUpdate()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EncryptedContent_ContactUpdate copyWith(void Function(EncryptedContent_ContactUpdate) updates) => super.copyWith((message) => updates(message as EncryptedContent_ContactUpdate)) as EncryptedContent_ContactUpdate;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EncryptedContent_ContactUpdate create() => EncryptedContent_ContactUpdate._();
  EncryptedContent_ContactUpdate createEmptyInstance() => create();
  static $pb.PbList<EncryptedContent_ContactUpdate> createRepeated() => $pb.PbList<EncryptedContent_ContactUpdate>();
  @$core.pragma('dart2js:noInline')
  static EncryptedContent_ContactUpdate getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EncryptedContent_ContactUpdate>(create);
  static EncryptedContent_ContactUpdate? _defaultInstance;

  @$pb.TagNumber(1)
  EncryptedContent_ContactUpdate_Type get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(EncryptedContent_ContactUpdate_Type v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $core.List<$core.int> get avatarSvgCompressed => $_getN(1);
  @$pb.TagNumber(2)
  set avatarSvgCompressed($core.List<$core.int> v) { $_setBytes(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasAvatarSvgCompressed() => $_has(1);
  @$pb.TagNumber(2)
  void clearAvatarSvgCompressed() => clearField(2);

  @$pb.TagNumber(3)
  $core.String get username => $_getSZ(2);
  @$pb.TagNumber(3)
  set username($core.String v) { $_setString(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasUsername() => $_has(2);
  @$pb.TagNumber(3)
  void clearUsername() => clearField(3);

  @$pb.TagNumber(4)
  $core.String get displayName => $_getSZ(3);
  @$pb.TagNumber(4)
  set displayName($core.String v) { $_setString(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasDisplayName() => $_has(3);
  @$pb.TagNumber(4)
  void clearDisplayName() => clearField(4);
}

class EncryptedContent_PushKeys extends $pb.GeneratedMessage {
  factory EncryptedContent_PushKeys({
    EncryptedContent_PushKeys_Type? type,
    $fixnum.Int64? keyId,
    $core.List<$core.int>? key,
    $fixnum.Int64? createdAt,
  }) {
    final $result = create();
    if (type != null) {
      $result.type = type;
    }
    if (keyId != null) {
      $result.keyId = keyId;
    }
    if (key != null) {
      $result.key = key;
    }
    if (createdAt != null) {
      $result.createdAt = createdAt;
    }
    return $result;
  }
  EncryptedContent_PushKeys._() : super();
  factory EncryptedContent_PushKeys.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EncryptedContent_PushKeys.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EncryptedContent.PushKeys', createEmptyInstance: create)
    ..e<EncryptedContent_PushKeys_Type>(1, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE, defaultOrMaker: EncryptedContent_PushKeys_Type.REQUEST, valueOf: EncryptedContent_PushKeys_Type.valueOf, enumValues: EncryptedContent_PushKeys_Type.values)
    ..aInt64(2, _omitFieldNames ? '' : 'keyId', protoName: 'keyId')
    ..a<$core.List<$core.int>>(3, _omitFieldNames ? '' : 'key', $pb.PbFieldType.OY)
    ..aInt64(4, _omitFieldNames ? '' : 'createdAt', protoName: 'createdAt')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EncryptedContent_PushKeys clone() => EncryptedContent_PushKeys()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EncryptedContent_PushKeys copyWith(void Function(EncryptedContent_PushKeys) updates) => super.copyWith((message) => updates(message as EncryptedContent_PushKeys)) as EncryptedContent_PushKeys;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EncryptedContent_PushKeys create() => EncryptedContent_PushKeys._();
  EncryptedContent_PushKeys createEmptyInstance() => create();
  static $pb.PbList<EncryptedContent_PushKeys> createRepeated() => $pb.PbList<EncryptedContent_PushKeys>();
  @$core.pragma('dart2js:noInline')
  static EncryptedContent_PushKeys getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EncryptedContent_PushKeys>(create);
  static EncryptedContent_PushKeys? _defaultInstance;

  @$pb.TagNumber(1)
  EncryptedContent_PushKeys_Type get type => $_getN(0);
  @$pb.TagNumber(1)
  set type(EncryptedContent_PushKeys_Type v) { setField(1, v); }
  @$pb.TagNumber(1)
  $core.bool hasType() => $_has(0);
  @$pb.TagNumber(1)
  void clearType() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get keyId => $_getI64(1);
  @$pb.TagNumber(2)
  set keyId($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasKeyId() => $_has(1);
  @$pb.TagNumber(2)
  void clearKeyId() => clearField(2);

  @$pb.TagNumber(3)
  $core.List<$core.int> get key => $_getN(2);
  @$pb.TagNumber(3)
  set key($core.List<$core.int> v) { $_setBytes(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasKey() => $_has(2);
  @$pb.TagNumber(3)
  void clearKey() => clearField(3);

  @$pb.TagNumber(4)
  $fixnum.Int64 get createdAt => $_getI64(3);
  @$pb.TagNumber(4)
  set createdAt($fixnum.Int64 v) { $_setInt64(3, v); }
  @$pb.TagNumber(4)
  $core.bool hasCreatedAt() => $_has(3);
  @$pb.TagNumber(4)
  void clearCreatedAt() => clearField(4);
}

class EncryptedContent_FlameSync extends $pb.GeneratedMessage {
  factory EncryptedContent_FlameSync({
    $fixnum.Int64? flameCounter,
    $fixnum.Int64? lastFlameCounterChange,
    $core.bool? bestFriend,
  }) {
    final $result = create();
    if (flameCounter != null) {
      $result.flameCounter = flameCounter;
    }
    if (lastFlameCounterChange != null) {
      $result.lastFlameCounterChange = lastFlameCounterChange;
    }
    if (bestFriend != null) {
      $result.bestFriend = bestFriend;
    }
    return $result;
  }
  EncryptedContent_FlameSync._() : super();
  factory EncryptedContent_FlameSync.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EncryptedContent_FlameSync.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EncryptedContent.FlameSync', createEmptyInstance: create)
    ..aInt64(1, _omitFieldNames ? '' : 'flameCounter', protoName: 'flameCounter')
    ..aInt64(2, _omitFieldNames ? '' : 'lastFlameCounterChange', protoName: 'lastFlameCounterChange')
    ..aOB(3, _omitFieldNames ? '' : 'bestFriend', protoName: 'bestFriend')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EncryptedContent_FlameSync clone() => EncryptedContent_FlameSync()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EncryptedContent_FlameSync copyWith(void Function(EncryptedContent_FlameSync) updates) => super.copyWith((message) => updates(message as EncryptedContent_FlameSync)) as EncryptedContent_FlameSync;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EncryptedContent_FlameSync create() => EncryptedContent_FlameSync._();
  EncryptedContent_FlameSync createEmptyInstance() => create();
  static $pb.PbList<EncryptedContent_FlameSync> createRepeated() => $pb.PbList<EncryptedContent_FlameSync>();
  @$core.pragma('dart2js:noInline')
  static EncryptedContent_FlameSync getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EncryptedContent_FlameSync>(create);
  static EncryptedContent_FlameSync? _defaultInstance;

  @$pb.TagNumber(1)
  $fixnum.Int64 get flameCounter => $_getI64(0);
  @$pb.TagNumber(1)
  set flameCounter($fixnum.Int64 v) { $_setInt64(0, v); }
  @$pb.TagNumber(1)
  $core.bool hasFlameCounter() => $_has(0);
  @$pb.TagNumber(1)
  void clearFlameCounter() => clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get lastFlameCounterChange => $_getI64(1);
  @$pb.TagNumber(2)
  set lastFlameCounterChange($fixnum.Int64 v) { $_setInt64(1, v); }
  @$pb.TagNumber(2)
  $core.bool hasLastFlameCounterChange() => $_has(1);
  @$pb.TagNumber(2)
  void clearLastFlameCounterChange() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get bestFriend => $_getBF(2);
  @$pb.TagNumber(3)
  set bestFriend($core.bool v) { $_setBool(2, v); }
  @$pb.TagNumber(3)
  $core.bool hasBestFriend() => $_has(2);
  @$pb.TagNumber(3)
  void clearBestFriend() => clearField(3);
}

class EncryptedContent extends $pb.GeneratedMessage {
  factory EncryptedContent({
    $core.String? groupId,
    $core.bool? isDirectChat,
    $fixnum.Int64? senderProfileCounter,
    EncryptedContent_MessageUpdate? messageUpdate,
    EncryptedContent_Media? media,
    EncryptedContent_MediaUpdate? mediaUpdate,
    EncryptedContent_ContactUpdate? contactUpdate,
    EncryptedContent_ContactRequest? contactRequest,
    EncryptedContent_FlameSync? flameSync,
    EncryptedContent_PushKeys? pushKeys,
    EncryptedContent_Reaction? reaction,
    EncryptedContent_TextMessage? textMessage,
    EncryptedContent_GroupCreate? groupCreate,
    EncryptedContent_GroupJoin? groupJoin,
    EncryptedContent_GroupUpdate? groupUpdate,
    EncryptedContent_ResendGroupPublicKey? resendGroupPublicKey,
  }) {
    final $result = create();
    if (groupId != null) {
      $result.groupId = groupId;
    }
    if (isDirectChat != null) {
      $result.isDirectChat = isDirectChat;
    }
    if (senderProfileCounter != null) {
      $result.senderProfileCounter = senderProfileCounter;
    }
    if (messageUpdate != null) {
      $result.messageUpdate = messageUpdate;
    }
    if (media != null) {
      $result.media = media;
    }
    if (mediaUpdate != null) {
      $result.mediaUpdate = mediaUpdate;
    }
    if (contactUpdate != null) {
      $result.contactUpdate = contactUpdate;
    }
    if (contactRequest != null) {
      $result.contactRequest = contactRequest;
    }
    if (flameSync != null) {
      $result.flameSync = flameSync;
    }
    if (pushKeys != null) {
      $result.pushKeys = pushKeys;
    }
    if (reaction != null) {
      $result.reaction = reaction;
    }
    if (textMessage != null) {
      $result.textMessage = textMessage;
    }
    if (groupCreate != null) {
      $result.groupCreate = groupCreate;
    }
    if (groupJoin != null) {
      $result.groupJoin = groupJoin;
    }
    if (groupUpdate != null) {
      $result.groupUpdate = groupUpdate;
    }
    if (resendGroupPublicKey != null) {
      $result.resendGroupPublicKey = resendGroupPublicKey;
    }
    return $result;
  }
  EncryptedContent._() : super();
  factory EncryptedContent.fromBuffer($core.List<$core.int> i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(i, r);
  factory EncryptedContent.fromJson($core.String i, [$pb.ExtensionRegistry r = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(i, r);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'EncryptedContent', createEmptyInstance: create)
    ..aOS(2, _omitFieldNames ? '' : 'groupId', protoName: 'groupId')
    ..aOB(3, _omitFieldNames ? '' : 'isDirectChat', protoName: 'isDirectChat')
    ..aInt64(4, _omitFieldNames ? '' : 'senderProfileCounter', protoName: 'senderProfileCounter')
    ..aOM<EncryptedContent_MessageUpdate>(5, _omitFieldNames ? '' : 'messageUpdate', protoName: 'messageUpdate', subBuilder: EncryptedContent_MessageUpdate.create)
    ..aOM<EncryptedContent_Media>(6, _omitFieldNames ? '' : 'media', subBuilder: EncryptedContent_Media.create)
    ..aOM<EncryptedContent_MediaUpdate>(7, _omitFieldNames ? '' : 'mediaUpdate', protoName: 'mediaUpdate', subBuilder: EncryptedContent_MediaUpdate.create)
    ..aOM<EncryptedContent_ContactUpdate>(8, _omitFieldNames ? '' : 'contactUpdate', protoName: 'contactUpdate', subBuilder: EncryptedContent_ContactUpdate.create)
    ..aOM<EncryptedContent_ContactRequest>(9, _omitFieldNames ? '' : 'contactRequest', protoName: 'contactRequest', subBuilder: EncryptedContent_ContactRequest.create)
    ..aOM<EncryptedContent_FlameSync>(10, _omitFieldNames ? '' : 'flameSync', protoName: 'flameSync', subBuilder: EncryptedContent_FlameSync.create)
    ..aOM<EncryptedContent_PushKeys>(11, _omitFieldNames ? '' : 'pushKeys', protoName: 'pushKeys', subBuilder: EncryptedContent_PushKeys.create)
    ..aOM<EncryptedContent_Reaction>(12, _omitFieldNames ? '' : 'reaction', subBuilder: EncryptedContent_Reaction.create)
    ..aOM<EncryptedContent_TextMessage>(13, _omitFieldNames ? '' : 'textMessage', protoName: 'textMessage', subBuilder: EncryptedContent_TextMessage.create)
    ..aOM<EncryptedContent_GroupCreate>(14, _omitFieldNames ? '' : 'groupCreate', protoName: 'groupCreate', subBuilder: EncryptedContent_GroupCreate.create)
    ..aOM<EncryptedContent_GroupJoin>(15, _omitFieldNames ? '' : 'groupJoin', protoName: 'groupJoin', subBuilder: EncryptedContent_GroupJoin.create)
    ..aOM<EncryptedContent_GroupUpdate>(16, _omitFieldNames ? '' : 'groupUpdate', protoName: 'groupUpdate', subBuilder: EncryptedContent_GroupUpdate.create)
    ..aOM<EncryptedContent_ResendGroupPublicKey>(17, _omitFieldNames ? '' : 'resendGroupPublicKey', protoName: 'resendGroupPublicKey', subBuilder: EncryptedContent_ResendGroupPublicKey.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.deepCopy] instead. '
  'Will be removed in next major version')
  EncryptedContent clone() => EncryptedContent()..mergeFromMessage(this);
  @$core.Deprecated(
  'Using this can add significant overhead to your binary. '
  'Use [GeneratedMessageGenericExtensions.rebuild] instead. '
  'Will be removed in next major version')
  EncryptedContent copyWith(void Function(EncryptedContent) updates) => super.copyWith((message) => updates(message as EncryptedContent)) as EncryptedContent;

  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static EncryptedContent create() => EncryptedContent._();
  EncryptedContent createEmptyInstance() => create();
  static $pb.PbList<EncryptedContent> createRepeated() => $pb.PbList<EncryptedContent>();
  @$core.pragma('dart2js:noInline')
  static EncryptedContent getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<EncryptedContent>(create);
  static EncryptedContent? _defaultInstance;

  @$pb.TagNumber(2)
  $core.String get groupId => $_getSZ(0);
  @$pb.TagNumber(2)
  set groupId($core.String v) { $_setString(0, v); }
  @$pb.TagNumber(2)
  $core.bool hasGroupId() => $_has(0);
  @$pb.TagNumber(2)
  void clearGroupId() => clearField(2);

  @$pb.TagNumber(3)
  $core.bool get isDirectChat => $_getBF(1);
  @$pb.TagNumber(3)
  set isDirectChat($core.bool v) { $_setBool(1, v); }
  @$pb.TagNumber(3)
  $core.bool hasIsDirectChat() => $_has(1);
  @$pb.TagNumber(3)
  void clearIsDirectChat() => clearField(3);

  /// / This can be added, so the receiver can check weather he is up to date with the current profile
  @$pb.TagNumber(4)
  $fixnum.Int64 get senderProfileCounter => $_getI64(2);
  @$pb.TagNumber(4)
  set senderProfileCounter($fixnum.Int64 v) { $_setInt64(2, v); }
  @$pb.TagNumber(4)
  $core.bool hasSenderProfileCounter() => $_has(2);
  @$pb.TagNumber(4)
  void clearSenderProfileCounter() => clearField(4);

  @$pb.TagNumber(5)
  EncryptedContent_MessageUpdate get messageUpdate => $_getN(3);
  @$pb.TagNumber(5)
  set messageUpdate(EncryptedContent_MessageUpdate v) { setField(5, v); }
  @$pb.TagNumber(5)
  $core.bool hasMessageUpdate() => $_has(3);
  @$pb.TagNumber(5)
  void clearMessageUpdate() => clearField(5);
  @$pb.TagNumber(5)
  EncryptedContent_MessageUpdate ensureMessageUpdate() => $_ensure(3);

  @$pb.TagNumber(6)
  EncryptedContent_Media get media => $_getN(4);
  @$pb.TagNumber(6)
  set media(EncryptedContent_Media v) { setField(6, v); }
  @$pb.TagNumber(6)
  $core.bool hasMedia() => $_has(4);
  @$pb.TagNumber(6)
  void clearMedia() => clearField(6);
  @$pb.TagNumber(6)
  EncryptedContent_Media ensureMedia() => $_ensure(4);

  @$pb.TagNumber(7)
  EncryptedContent_MediaUpdate get mediaUpdate => $_getN(5);
  @$pb.TagNumber(7)
  set mediaUpdate(EncryptedContent_MediaUpdate v) { setField(7, v); }
  @$pb.TagNumber(7)
  $core.bool hasMediaUpdate() => $_has(5);
  @$pb.TagNumber(7)
  void clearMediaUpdate() => clearField(7);
  @$pb.TagNumber(7)
  EncryptedContent_MediaUpdate ensureMediaUpdate() => $_ensure(5);

  @$pb.TagNumber(8)
  EncryptedContent_ContactUpdate get contactUpdate => $_getN(6);
  @$pb.TagNumber(8)
  set contactUpdate(EncryptedContent_ContactUpdate v) { setField(8, v); }
  @$pb.TagNumber(8)
  $core.bool hasContactUpdate() => $_has(6);
  @$pb.TagNumber(8)
  void clearContactUpdate() => clearField(8);
  @$pb.TagNumber(8)
  EncryptedContent_ContactUpdate ensureContactUpdate() => $_ensure(6);

  @$pb.TagNumber(9)
  EncryptedContent_ContactRequest get contactRequest => $_getN(7);
  @$pb.TagNumber(9)
  set contactRequest(EncryptedContent_ContactRequest v) { setField(9, v); }
  @$pb.TagNumber(9)
  $core.bool hasContactRequest() => $_has(7);
  @$pb.TagNumber(9)
  void clearContactRequest() => clearField(9);
  @$pb.TagNumber(9)
  EncryptedContent_ContactRequest ensureContactRequest() => $_ensure(7);

  @$pb.TagNumber(10)
  EncryptedContent_FlameSync get flameSync => $_getN(8);
  @$pb.TagNumber(10)
  set flameSync(EncryptedContent_FlameSync v) { setField(10, v); }
  @$pb.TagNumber(10)
  $core.bool hasFlameSync() => $_has(8);
  @$pb.TagNumber(10)
  void clearFlameSync() => clearField(10);
  @$pb.TagNumber(10)
  EncryptedContent_FlameSync ensureFlameSync() => $_ensure(8);

  @$pb.TagNumber(11)
  EncryptedContent_PushKeys get pushKeys => $_getN(9);
  @$pb.TagNumber(11)
  set pushKeys(EncryptedContent_PushKeys v) { setField(11, v); }
  @$pb.TagNumber(11)
  $core.bool hasPushKeys() => $_has(9);
  @$pb.TagNumber(11)
  void clearPushKeys() => clearField(11);
  @$pb.TagNumber(11)
  EncryptedContent_PushKeys ensurePushKeys() => $_ensure(9);

  @$pb.TagNumber(12)
  EncryptedContent_Reaction get reaction => $_getN(10);
  @$pb.TagNumber(12)
  set reaction(EncryptedContent_Reaction v) { setField(12, v); }
  @$pb.TagNumber(12)
  $core.bool hasReaction() => $_has(10);
  @$pb.TagNumber(12)
  void clearReaction() => clearField(12);
  @$pb.TagNumber(12)
  EncryptedContent_Reaction ensureReaction() => $_ensure(10);

  @$pb.TagNumber(13)
  EncryptedContent_TextMessage get textMessage => $_getN(11);
  @$pb.TagNumber(13)
  set textMessage(EncryptedContent_TextMessage v) { setField(13, v); }
  @$pb.TagNumber(13)
  $core.bool hasTextMessage() => $_has(11);
  @$pb.TagNumber(13)
  void clearTextMessage() => clearField(13);
  @$pb.TagNumber(13)
  EncryptedContent_TextMessage ensureTextMessage() => $_ensure(11);

  @$pb.TagNumber(14)
  EncryptedContent_GroupCreate get groupCreate => $_getN(12);
  @$pb.TagNumber(14)
  set groupCreate(EncryptedContent_GroupCreate v) { setField(14, v); }
  @$pb.TagNumber(14)
  $core.bool hasGroupCreate() => $_has(12);
  @$pb.TagNumber(14)
  void clearGroupCreate() => clearField(14);
  @$pb.TagNumber(14)
  EncryptedContent_GroupCreate ensureGroupCreate() => $_ensure(12);

  @$pb.TagNumber(15)
  EncryptedContent_GroupJoin get groupJoin => $_getN(13);
  @$pb.TagNumber(15)
  set groupJoin(EncryptedContent_GroupJoin v) { setField(15, v); }
  @$pb.TagNumber(15)
  $core.bool hasGroupJoin() => $_has(13);
  @$pb.TagNumber(15)
  void clearGroupJoin() => clearField(15);
  @$pb.TagNumber(15)
  EncryptedContent_GroupJoin ensureGroupJoin() => $_ensure(13);

  @$pb.TagNumber(16)
  EncryptedContent_GroupUpdate get groupUpdate => $_getN(14);
  @$pb.TagNumber(16)
  set groupUpdate(EncryptedContent_GroupUpdate v) { setField(16, v); }
  @$pb.TagNumber(16)
  $core.bool hasGroupUpdate() => $_has(14);
  @$pb.TagNumber(16)
  void clearGroupUpdate() => clearField(16);
  @$pb.TagNumber(16)
  EncryptedContent_GroupUpdate ensureGroupUpdate() => $_ensure(14);

  @$pb.TagNumber(17)
  EncryptedContent_ResendGroupPublicKey get resendGroupPublicKey => $_getN(15);
  @$pb.TagNumber(17)
  set resendGroupPublicKey(EncryptedContent_ResendGroupPublicKey v) { setField(17, v); }
  @$pb.TagNumber(17)
  $core.bool hasResendGroupPublicKey() => $_has(15);
  @$pb.TagNumber(17)
  void clearResendGroupPublicKey() => clearField(17);
  @$pb.TagNumber(17)
  EncryptedContent_ResendGroupPublicKey ensureResendGroupPublicKey() => $_ensure(15);
}


const _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
