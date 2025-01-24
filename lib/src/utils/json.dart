import 'package:json_annotation/json_annotation.dart';
import 'package:fixnum/fixnum.dart';
import 'dart:convert';
import 'dart:typed_data';

class Int64Converter implements JsonConverter<Int64, String> {
  const Int64Converter();

  @override
  Int64 fromJson(String json) {
    return Int64.parseInt(json);
  }

  @override
  String toJson(Int64 object) {
    return object.toString();
  }
}

class Uint8ListConverter implements JsonConverter<Uint8List, String> {
  const Uint8ListConverter();
  @override
  Uint8List fromJson(String json) {
    return base64Decode(json);
  }

  @override
  String toJson(Uint8List object) {
    return base64Encode(object);
  }
}
