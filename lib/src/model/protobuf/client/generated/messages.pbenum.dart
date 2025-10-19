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

import 'package:protobuf/protobuf.dart' as $pb;

class Message_Type extends $pb.ProtobufEnum {
  static const Message_Type SENDER_DELIVERY_RECEIPT = Message_Type._(0, _omitEnumNames ? '' : 'SENDER_DELIVERY_RECEIPT');
  static const Message_Type PLAINTEXT_CONTENT = Message_Type._(1, _omitEnumNames ? '' : 'PLAINTEXT_CONTENT');
  static const Message_Type CIPHERTEXT = Message_Type._(2, _omitEnumNames ? '' : 'CIPHERTEXT');
  static const Message_Type PREKEY_BUNDLE = Message_Type._(3, _omitEnumNames ? '' : 'PREKEY_BUNDLE');
  static const Message_Type TEST_NOTIFICATION = Message_Type._(4, _omitEnumNames ? '' : 'TEST_NOTIFICATION');

  static const $core.List<Message_Type> values = <Message_Type> [
    SENDER_DELIVERY_RECEIPT,
    PLAINTEXT_CONTENT,
    CIPHERTEXT,
    PREKEY_BUNDLE,
    TEST_NOTIFICATION,
  ];

  static final $core.Map<$core.int, Message_Type> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Message_Type? valueOf($core.int value) => _byValue[value];

  const Message_Type._($core.int v, $core.String n) : super(v, n);
}

class PlaintextContent_DecryptionErrorMessage_Type extends $pb.ProtobufEnum {
  static const PlaintextContent_DecryptionErrorMessage_Type UNKNOWN = PlaintextContent_DecryptionErrorMessage_Type._(0, _omitEnumNames ? '' : 'UNKNOWN');
  static const PlaintextContent_DecryptionErrorMessage_Type PREKEY_UNKNOWN = PlaintextContent_DecryptionErrorMessage_Type._(1, _omitEnumNames ? '' : 'PREKEY_UNKNOWN');

  static const $core.List<PlaintextContent_DecryptionErrorMessage_Type> values = <PlaintextContent_DecryptionErrorMessage_Type> [
    UNKNOWN,
    PREKEY_UNKNOWN,
  ];

  static final $core.Map<$core.int, PlaintextContent_DecryptionErrorMessage_Type> _byValue = $pb.ProtobufEnum.initByValue(values);
  static PlaintextContent_DecryptionErrorMessage_Type? valueOf($core.int value) => _byValue[value];

  const PlaintextContent_DecryptionErrorMessage_Type._($core.int v, $core.String n) : super(v, n);
}

class EncryptedContent_MessageUpdate_Type extends $pb.ProtobufEnum {
  static const EncryptedContent_MessageUpdate_Type DELETE = EncryptedContent_MessageUpdate_Type._(0, _omitEnumNames ? '' : 'DELETE');
  static const EncryptedContent_MessageUpdate_Type EDIT_TEXT = EncryptedContent_MessageUpdate_Type._(1, _omitEnumNames ? '' : 'EDIT_TEXT');
  static const EncryptedContent_MessageUpdate_Type OPENED = EncryptedContent_MessageUpdate_Type._(2, _omitEnumNames ? '' : 'OPENED');

  static const $core.List<EncryptedContent_MessageUpdate_Type> values = <EncryptedContent_MessageUpdate_Type> [
    DELETE,
    EDIT_TEXT,
    OPENED,
  ];

  static final $core.Map<$core.int, EncryptedContent_MessageUpdate_Type> _byValue = $pb.ProtobufEnum.initByValue(values);
  static EncryptedContent_MessageUpdate_Type? valueOf($core.int value) => _byValue[value];

  const EncryptedContent_MessageUpdate_Type._($core.int v, $core.String n) : super(v, n);
}

class EncryptedContent_Media_Type extends $pb.ProtobufEnum {
  static const EncryptedContent_Media_Type REUPLOAD = EncryptedContent_Media_Type._(0, _omitEnumNames ? '' : 'REUPLOAD');
  static const EncryptedContent_Media_Type IMAGE = EncryptedContent_Media_Type._(1, _omitEnumNames ? '' : 'IMAGE');
  static const EncryptedContent_Media_Type VIDEO = EncryptedContent_Media_Type._(2, _omitEnumNames ? '' : 'VIDEO');
  static const EncryptedContent_Media_Type GIF = EncryptedContent_Media_Type._(3, _omitEnumNames ? '' : 'GIF');

  static const $core.List<EncryptedContent_Media_Type> values = <EncryptedContent_Media_Type> [
    REUPLOAD,
    IMAGE,
    VIDEO,
    GIF,
  ];

  static final $core.Map<$core.int, EncryptedContent_Media_Type> _byValue = $pb.ProtobufEnum.initByValue(values);
  static EncryptedContent_Media_Type? valueOf($core.int value) => _byValue[value];

  const EncryptedContent_Media_Type._($core.int v, $core.String n) : super(v, n);
}

class EncryptedContent_MediaUpdate_Type extends $pb.ProtobufEnum {
  static const EncryptedContent_MediaUpdate_Type REOPENED = EncryptedContent_MediaUpdate_Type._(0, _omitEnumNames ? '' : 'REOPENED');
  static const EncryptedContent_MediaUpdate_Type STORED = EncryptedContent_MediaUpdate_Type._(1, _omitEnumNames ? '' : 'STORED');
  static const EncryptedContent_MediaUpdate_Type DECRYPTION_ERROR = EncryptedContent_MediaUpdate_Type._(2, _omitEnumNames ? '' : 'DECRYPTION_ERROR');

  static const $core.List<EncryptedContent_MediaUpdate_Type> values = <EncryptedContent_MediaUpdate_Type> [
    REOPENED,
    STORED,
    DECRYPTION_ERROR,
  ];

  static final $core.Map<$core.int, EncryptedContent_MediaUpdate_Type> _byValue = $pb.ProtobufEnum.initByValue(values);
  static EncryptedContent_MediaUpdate_Type? valueOf($core.int value) => _byValue[value];

  const EncryptedContent_MediaUpdate_Type._($core.int v, $core.String n) : super(v, n);
}

class EncryptedContent_ContactRequest_Type extends $pb.ProtobufEnum {
  static const EncryptedContent_ContactRequest_Type REQUEST = EncryptedContent_ContactRequest_Type._(0, _omitEnumNames ? '' : 'REQUEST');
  static const EncryptedContent_ContactRequest_Type REJECT = EncryptedContent_ContactRequest_Type._(1, _omitEnumNames ? '' : 'REJECT');
  static const EncryptedContent_ContactRequest_Type ACCEPT = EncryptedContent_ContactRequest_Type._(2, _omitEnumNames ? '' : 'ACCEPT');

  static const $core.List<EncryptedContent_ContactRequest_Type> values = <EncryptedContent_ContactRequest_Type> [
    REQUEST,
    REJECT,
    ACCEPT,
  ];

  static final $core.Map<$core.int, EncryptedContent_ContactRequest_Type> _byValue = $pb.ProtobufEnum.initByValue(values);
  static EncryptedContent_ContactRequest_Type? valueOf($core.int value) => _byValue[value];

  const EncryptedContent_ContactRequest_Type._($core.int v, $core.String n) : super(v, n);
}

class EncryptedContent_ContactUpdate_Type extends $pb.ProtobufEnum {
  static const EncryptedContent_ContactUpdate_Type REQUEST = EncryptedContent_ContactUpdate_Type._(0, _omitEnumNames ? '' : 'REQUEST');
  static const EncryptedContent_ContactUpdate_Type UPDATE = EncryptedContent_ContactUpdate_Type._(1, _omitEnumNames ? '' : 'UPDATE');

  static const $core.List<EncryptedContent_ContactUpdate_Type> values = <EncryptedContent_ContactUpdate_Type> [
    REQUEST,
    UPDATE,
  ];

  static final $core.Map<$core.int, EncryptedContent_ContactUpdate_Type> _byValue = $pb.ProtobufEnum.initByValue(values);
  static EncryptedContent_ContactUpdate_Type? valueOf($core.int value) => _byValue[value];

  const EncryptedContent_ContactUpdate_Type._($core.int v, $core.String n) : super(v, n);
}

class EncryptedContent_PushKeys_Type extends $pb.ProtobufEnum {
  static const EncryptedContent_PushKeys_Type REQUEST = EncryptedContent_PushKeys_Type._(0, _omitEnumNames ? '' : 'REQUEST');
  static const EncryptedContent_PushKeys_Type UPDATE = EncryptedContent_PushKeys_Type._(1, _omitEnumNames ? '' : 'UPDATE');

  static const $core.List<EncryptedContent_PushKeys_Type> values = <EncryptedContent_PushKeys_Type> [
    REQUEST,
    UPDATE,
  ];

  static final $core.Map<$core.int, EncryptedContent_PushKeys_Type> _byValue = $pb.ProtobufEnum.initByValue(values);
  static EncryptedContent_PushKeys_Type? valueOf($core.int value) => _byValue[value];

  const EncryptedContent_PushKeys_Type._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
