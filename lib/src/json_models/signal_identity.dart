import 'dart:typed_data';
import 'package:json_annotation/json_annotation.dart';
import 'package:twonly/src/utils/json.dart';
part 'signal_identity.g.dart';

@JsonSerializable()
class SignalIdentity {
  const SignalIdentity(
      {required this.identityKeyPairU8List, required this.registrationId});

  final int registrationId;

  @Uint8ListConverter()
  final Uint8List identityKeyPairU8List;
  factory SignalIdentity.fromJson(Map<String, dynamic> json) =>
      _$SignalIdentityFromJson(json);
  Map<String, dynamic> toJson() => _$SignalIdentityToJson(this);
}
