import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';
import 'dart:typed_data';

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
