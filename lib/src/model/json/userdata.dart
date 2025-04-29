import 'package:flutter/material.dart';
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

  // settings
  int? defaultShowTime;
  bool? useHighQuality;
  List<String>? preSelectedEmojies;
  ThemeMode? themeMode;
  Map<String, List<String>>? autoDownloadOptions;
  bool? storeMediaFilesInGallery;
  List<String>? lastUsedEditorEmojis;

  final int userId;

  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);
  Map<String, dynamic> toJson() => _$UserDataToJson(this);
}
