import 'dart:typed_data';
import 'package:json_annotation/json_annotation.dart';
import 'package:twonly/src/model/signal_identity_json.dart';
part 'user_data_json.g.dart';

@JsonSerializable()
class UserData {
  const UserData(
      {required this.userId,
      required this.username,
      required this.displayName});
  final String username;
  final String displayName;

  @Uint8ListConverter()
  final Uint8List userId;
  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);
  Map<String, dynamic> toJson() => _$UserDataToJson(this);
}
