import 'package:json_annotation/json_annotation.dart';
import 'package:fixnum/fixnum.dart';
part 'user_data_json.g.dart';

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
