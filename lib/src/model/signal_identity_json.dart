import 'dart:convert';
import 'dart:typed_data';
import 'package:fixnum/fixnum.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:twonly/src/model/user_data_json.dart';
part 'signal_identity_json.g.dart';

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

@JsonSerializable()
class SignalIdentity {
  const SignalIdentity(
      {required this.identityKeyPairU8List, required this.registrationId});

  @Int64Converter()
  final Int64 registrationId;

  @Uint8ListConverter()
  final Uint8List identityKeyPairU8List;
  factory SignalIdentity.fromJson(Map<String, dynamic> json) =>
      _$SignalIdentityFromJson(json);
  Map<String, dynamic> toJson() => _$SignalIdentityToJson(this);
}
