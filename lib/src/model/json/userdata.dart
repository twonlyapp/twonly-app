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

  final int userId;

  @JsonKey(defaultValue: false)
  bool isDemoUser = false;

  // -- USER PROFILE --

  String username;
  String displayName;
  String? avatarSvg;
  String? avatarJson;
  int? avatarCounter;

  // --- SETTINGS ---

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

  // --- BACKUP ---

  @JsonKey(defaultValue: false)
  bool identityBackupEnabled = false;
  DateTime? identityBackupLastBackupTime;

  @JsonKey(defaultValue: 0)
  int identityBackupLastBackupSize = 0;
  DateTime? nextTimeToShowBackupNotice;
  BackupServer? backupServer;
  List<int>? twonlySafeEncryptionKey;
  List<int>? twonlySafeBackupId;

  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);
  Map<String, dynamic> toJson() => _$UserDataToJson(this);
}

@JsonSerializable()
class BackupServer {
  BackupServer({
    required this.serverUrl,
    required this.retentionDays,
    required this.maxBackupBytes,
  });

  String serverUrl;
  int retentionDays;
  int maxBackupBytes;

  factory BackupServer.fromJson(Map<String, dynamic> json) =>
      _$BackupServerFromJson(json);
  Map<String, dynamic> toJson() => _$BackupServerToJson(this);
}
