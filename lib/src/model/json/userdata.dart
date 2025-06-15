import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
part 'userdata.g.dart';

@JsonSerializable()
class UserData {
  UserData({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.subscriptionPlan,
    required this.isDemoUser,
  });

  String username;
  String displayName;

  String? avatarSvg;
  String? avatarJson;
  int? avatarCounter;

  @JsonKey(defaultValue: false)
  bool isDemoUser = false;

  // settings
  int? defaultShowTime;
  @JsonKey(defaultValue: "Preview")
  String subscriptionPlan;
  bool? useHighQuality;
  List<String>? preSelectedEmojies;
  ThemeMode? themeMode;
  Map<String, List<String>>? autoDownloadOptions;
  bool? storeMediaFilesInGallery;
  List<String>? lastUsedEditorEmojis;

  String? lastPlanBallance;
  String? additionalUserInvites;

  DateTime? lastImageSend;
  int? todaysImageCounter;
  List<String>? tutorialDisplayed;

  int? myBestFriendContactId;

  DateTime? signalLastSignedPreKeyUpdated;

  @JsonKey(defaultValue: false)
  bool identityBackupEnabled = false;
  DateTime? identityBackupLastBackupTime;

  final int userId;

  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);
  Map<String, dynamic> toJson() => _$UserDataToJson(this);
}
