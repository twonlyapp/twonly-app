import 'package:json_annotation/json_annotation.dart';
import 'package:fixnum/fixnum.dart';
import 'package:twonly/src/utils/json.dart';
part 'user_data.g.dart';

@JsonSerializable()
class UserData {
  const UserData(
      {required this.userId,
      required this.username,
      required this.displayName});
  final String username;
  final String displayName;

  @Int64Converter()
  final Int64 userId;

  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);
  Map<String, dynamic> toJson() => _$UserDataToJson(this);
}
