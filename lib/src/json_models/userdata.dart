import 'package:json_annotation/json_annotation.dart';
part 'userdata.g.dart';

@JsonSerializable()
class UserData {
  UserData({
    required this.userId,
    required this.username,
    required this.displayName,
  });

  String username;
  String displayName;

  String? avatarSvg;
  String? avatarJson;
  int? avatarCounter;
  int? defaultShowTime;
  bool? useHighQuality;
  List<String>? preSelectedEmojies;

  final int userId;

  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);
  Map<String, dynamic> toJson() => _$UserDataToJson(this);
}
