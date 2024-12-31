import 'dart:typed_data';
import 'package:json_annotation/json_annotation.dart';
part 'user.g.dart';

class Uint8ListConverter implements JsonConverter<Uint8List, List<int>> {
  const Uint8ListConverter();
  @override
  Uint8List fromJson(List<int> json) {
    return Uint8List.fromList(json);
  }

  @override
  List<int> toJson(Uint8List object) {
    return object.toList();
  }
}

@JsonSerializable()
class User {
  const User({required this.username, required this.identityKeyPairU8List, required this.registrationId});
  final String username;
  final int registrationId;
  @Uint8ListConverter()
  final Uint8List identityKeyPairU8List;
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}
