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
  });
  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);

  final int userId;

  // -- USER PROFILE --

  String username;
  String displayName;
  String? avatarSvg;
  String? avatarJson;

  @JsonKey(defaultValue: 0)
  int appVersion = 0;

  @JsonKey(defaultValue: 0)
  int avatarCounter = 0;

  @JsonKey(defaultValue: false)
  bool isDeveloper = false;

  @JsonKey(defaultValue: false)
  bool disableVideoCompression = false;

  @JsonKey(defaultValue: 0)
  int deviceId = 0;

  // --- SUBSCRIPTION DTA ---

  @JsonKey(defaultValue: 'Free')
  String subscriptionPlan;

  String? subscriptionPlanIdStore;
  DateTime? lastImageSend;
  int? todaysImageCounter;

  // --- SETTINGS ---

  @JsonKey(defaultValue: ThemeMode.system)
  ThemeMode themeMode = ThemeMode.system;

  int? defaultShowTime;

  @JsonKey(defaultValue: false)
  bool requestedAudioPermission = false;

  @JsonKey(defaultValue: true)
  bool showFeedbackShortcut = true;

  @JsonKey(defaultValue: true)
  bool startWithCameraOpen = true;

  List<String>? preSelectedEmojies;

  Map<String, List<String>>? autoDownloadOptions;

  @JsonKey(defaultValue: false)
  bool storeMediaFilesInGallery = false;

  String? lastPlanBallance;
  String? additionalUserInvites;

  List<String>? tutorialDisplayed;

  String? myBestFriendGroupId;

  DateTime? signalLastSignedPreKeyUpdated;

  @JsonKey(defaultValue: false)
  bool allowErrorTrackingViaSentry = false;

  //  -- Custom DATA --

  @JsonKey(defaultValue: 100_000)
  int currentPreKeyIndexStart = 100_000;

  @JsonKey(defaultValue: 100_000)
  int currentSignedPreKeyIndexStart = 100_000;

  List<int>? lastChangeLogHash;

  @JsonKey(defaultValue: true)
  bool hideChangeLog = true;

  @JsonKey(defaultValue: true)
  bool updateFCMToken = true;

  // --- BACKUP ---

  DateTime? nextTimeToShowBackupNotice;
  BackupServer? backupServer;
  TwonlySafeBackup? twonlySafeBackup;
  Map<String, dynamic> toJson() => _$UserDataToJson(this);
}

enum LastBackupUploadState { none, pending, failed, success }

@JsonSerializable()
class TwonlySafeBackup {
  TwonlySafeBackup({
    required this.backupId,
    required this.encryptionKey,
  });
  factory TwonlySafeBackup.fromJson(Map<String, dynamic> json) =>
      _$TwonlySafeBackupFromJson(json);

  int lastBackupSize = 0;
  LastBackupUploadState backupUploadState = LastBackupUploadState.none;
  DateTime? lastBackupDone;
  List<int> backupId;
  List<int> encryptionKey;
  Map<String, dynamic> toJson() => _$TwonlySafeBackupToJson(this);
}

@JsonSerializable()
class BackupServer {
  BackupServer({
    required this.serverUrl,
    required this.retentionDays,
    required this.maxBackupBytes,
  });
  factory BackupServer.fromJson(Map<String, dynamic> json) =>
      _$BackupServerFromJson(json);

  String serverUrl;
  int retentionDays;
  int maxBackupBytes;
  Map<String, dynamic> toJson() => _$BackupServerToJson(this);
}
