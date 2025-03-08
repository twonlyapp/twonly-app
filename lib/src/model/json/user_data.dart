import 'package:json_annotation/json_annotation.dart';
part 'user_data.g.dart';

@JsonSerializable()
class UserData {
  const UserData(
      {required this.userId,
      required this.username,
      required this.displayName});
  final String username;
  final String displayName;

  final int userId;

  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);
  Map<String, dynamic> toJson() => _$UserDataToJson(this);
}
