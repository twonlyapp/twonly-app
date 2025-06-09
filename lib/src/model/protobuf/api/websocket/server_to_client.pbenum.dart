//
//  Generated code. Do not modify.
//  source: api/websocket/server_to_client.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class Response_TransactionTypes extends $pb.ProtobufEnum {
  static const Response_TransactionTypes Refund = Response_TransactionTypes._(0, _omitEnumNames ? '' : 'Refund');
  static const Response_TransactionTypes VoucherRedeemed = Response_TransactionTypes._(1, _omitEnumNames ? '' : 'VoucherRedeemed');
  static const Response_TransactionTypes VoucherCreated = Response_TransactionTypes._(2, _omitEnumNames ? '' : 'VoucherCreated');
  static const Response_TransactionTypes Cash = Response_TransactionTypes._(3, _omitEnumNames ? '' : 'Cash');
  static const Response_TransactionTypes PlanUpgrade = Response_TransactionTypes._(4, _omitEnumNames ? '' : 'PlanUpgrade');
  static const Response_TransactionTypes Unknown = Response_TransactionTypes._(5, _omitEnumNames ? '' : 'Unknown');
  static const Response_TransactionTypes ThanksForTesting = Response_TransactionTypes._(6, _omitEnumNames ? '' : 'ThanksForTesting');
  static const Response_TransactionTypes AutoRenewal = Response_TransactionTypes._(7, _omitEnumNames ? '' : 'AutoRenewal');

  static const $core.List<Response_TransactionTypes> values = <Response_TransactionTypes> [
    Refund,
    VoucherRedeemed,
    VoucherCreated,
    Cash,
    PlanUpgrade,
    Unknown,
    ThanksForTesting,
    AutoRenewal,
  ];

  static final $core.Map<$core.int, Response_TransactionTypes> _byValue = $pb.ProtobufEnum.initByValue(values);
  static Response_TransactionTypes? valueOf($core.int value) => _byValue[value];

  const Response_TransactionTypes._($core.int v, $core.String n) : super(v, n);
}


const _omitEnumNames = $core.bool.fromEnvironment('protobuf.omit_enum_names');
