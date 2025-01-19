//
//  Generated code. Do not modify.
//  source: api/error.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class ErrorCode extends $pb.ProtobufEnum {
  static const ErrorCode Unknown = ErrorCode._(0, _omitEnumNames ? '' : 'Unknown');
  static const ErrorCode BadRequest = ErrorCode._(400, _omitEnumNames ? '' : 'BadRequest');
  static const ErrorCode TooManyRequests = ErrorCode._(429, _omitEnumNames ? '' : 'TooManyRequests');
  static const ErrorCode InternalError = ErrorCode._(500, _omitEnumNames ? '' : 'InternalError');
  static const ErrorCode InvalidInvitationCode = ErrorCode._(1002, _omitEnumNames ? '' : 'InvalidInvitationCode');
  static const ErrorCode UsernameAlreadyTaken = ErrorCode._(1003, _omitEnumNames ? '' : 'UsernameAlreadyTaken');
  static const ErrorCode SignatureNotValid = ErrorCode._(1004, _omitEnumNames ? '' : 'SignatureNotValid');
  static const ErrorCode UsernameNotFound = ErrorCode._(1005, _omitEnumNames ? '' : 'UsernameNotFound');
  static const ErrorCode UsernameNotValid = ErrorCode._(1006, _omitEnumNames ? '' : 'UsernameNotValid');
  static const ErrorCode InvalidPublicKey = ErrorCode._(1007, _omitEnumNames ? '' : 'InvalidPublicKey');
  static const ErrorCode SessionAlreadyAuthenticated = ErrorCode._(1008, _omitEnumNames ? '' : 'SessionAlreadyAuthenticated');
  static const ErrorCode SessionNotAuthenticated = ErrorCode._(1009, _omitEnumNames ? '' : 'SessionNotAuthenticated');
  static const ErrorCode OnlyOneSessionAllowed = ErrorCode._(1010, _omitEnumNames ? '' : 'OnlyOneSessionAllowed');

  static const $core.List<ErrorCode> values = <ErrorCode> [
    Unknown,
    BadRequest,
    TooManyRequests,
    InternalError,
    InvalidInvitationCode,
    UsernameAlreadyTaken,
    SignatureNotValid,
    UsernameNotFound,
    UsernameNotValid,
    InvalidPublicKey,
    SessionAlreadyAuthenticated,
    SessionNotAuthenticated,
    OnlyOneSessionAllowed,
  ];

  static final $core.Map<$core.int, ErrorCode> _byValue = $pb.ProtobufEnum.initByValue(values);
  static ErrorCode? valueOf($core.int value) => _byValue[value];

  const ErrorCode._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
