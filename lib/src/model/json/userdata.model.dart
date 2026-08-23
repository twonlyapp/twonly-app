import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:twonly/src/services/profile.service.dart';
part 'userdata.model.g.dart';

@JsonSerializable()
class UserData {
  UserData({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.subscriptionPlan,
    required this.currentSetupPage,
    required this.appVersion,
  });
  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);

  final int userId;

  // -- USER PROFILE --

  String username;
  String displayName;
  String? avatarSvg;

  @JsonKey(defaultValue: 0)
  int appVersion = 0;

  @JsonKey(defaultValue: 0)
  int avatarCounter = 0;

  @JsonKey(defaultValue: false)
  bool isDeveloper = false;

  @JsonKey(defaultValue: 0)
  int deviceId = 0;

  @JsonKey(defaultValue: SetupProfile.standard)
  SetupProfile setupProfile = SetupProfile.standard;

  // --- SUBSCRIPTION DTA ---

  @JsonKey(defaultValue: 'Free')
  String subscriptionPlan;

  String? subscriptionPlanIdStore;
  DateTime? lastImageSend;
  int? todaysImageCounter;

  String? lastPlanBallance;
  String? additionalUserInvites;

  // --- SETTINGS ---

  @JsonKey(defaultValue: ThemeMode.system)
  ThemeMode themeMode = ThemeMode.system;

  int? primaryColorValue;

  Color get primaryColor => primaryColorValue != null
      ? Color(primaryColorValue!)
      : const Color(0xFF57CC99);

  int? defaultShowTime;

  @JsonKey(defaultValue: false)
  bool requestedAudioPermission = false;

  @JsonKey(defaultValue: false)
  bool enableDatabaseLogging = false;

  @JsonKey(defaultValue: false)
  bool automaticallyMarkEqualMediaFilesAsOpened = false;

  @JsonKey(defaultValue: true)
  bool videoStabilizationEnabled = true;

  @JsonKey(defaultValue: true)
  bool showNewsShortcut = true;

  @JsonKey(defaultValue: false)
  bool showShowImagePreviewWhenSending = false;

  @JsonKey(defaultValue: true)
  bool startWithCameraOpen = true;

  List<String>? preSelectedEmojies;

  Map<String, List<String>>? autoDownloadOptions;

  @JsonKey(defaultValue: true)
  bool storeMediaFilesInGallery = true;

  @JsonKey(defaultValue: false)
  bool autoStoreAllSendUnlimitedMediaFiles = false;

  @JsonKey(defaultValue: true)
  bool typingIndicators = true;

  @JsonKey(defaultValue: true)
  bool showRestoreFlame = true;

  String? myBestFriendGroupId;

  DateTime? signalLastSignedPreKeyUpdated;

  DateTime? signalLastPqcPreKeysUploaded;

  @JsonKey(defaultValue: false)
  bool allowErrorTrackingViaSentry = false;

  @JsonKey(defaultValue: false)
  bool screenLockEnabled = false;

  @JsonKey(defaultValue: false)
  bool isCloudBackupEnabled = false;

  // > User Discovery Configurations

  @JsonKey(defaultValue: false)
  bool isUserDiscoveryEnabled = false;

  @JsonKey(defaultValue: 4)
  int requiredSendImages = 4;

  @JsonKey(defaultValue: 3)
  int userDiscoveryThreshold = 3;

  @JsonKey(defaultValue: false)
  bool userDiscoveryRequiresManualApproval = false;

  @JsonKey(defaultValue: true)
  bool userDiscoverySharePromotion = true;

  @JsonKey(defaultValue: false)
  bool userDiscoveryInitializationError = false;

  //  -- Custom DATA --

  @JsonKey(defaultValue: true)
  bool askForFriendPromotions = true;

  @JsonKey(defaultValue: 100_000)
  int currentPreKeyIndexStart = 100_000;

  @JsonKey(defaultValue: 100_000)
  int currentSignedPreKeyIndexStart = 100_000;

  List<int>? lastChangeLogHash;

  @JsonKey(defaultValue: true)
  bool hideChangeLog = true;

  @JsonKey(defaultValue: false)
  bool hideMemoriesBackupPromo = false;

  @JsonKey(defaultValue: true)
  bool updateFCMToken = true;

  @JsonKey(defaultValue: true)
  bool canUseLoginTokenForAuth = true;

  // --- BACKUP ---

  @Deprecated('Use the secure storage in rust')
  TwonlySafeBackup? twonlySafeBackup;

  @JsonKey(defaultValue: false)
  bool isBackupEnabled = false;

  PasswordLessRecovery? passwordLessRecovery;

  // Used for push notifcation via FCM.
  String? fcmToken;

  String? currentSetupPage;

  @JsonKey(defaultValue: false)
  bool skipSetupPages = false;

  @JsonKey(defaultValue: false)
  bool hasZoomed = false;

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

  @JsonKey(defaultValue: 0)
  int lastBackupSize = 0;

  @JsonKey(defaultValue: LastBackupUploadState.none)
  LastBackupUploadState backupUploadState = LastBackupUploadState.none;

  DateTime? lastBackupDone;
  List<int> backupId;
  List<int> encryptionKey;
  Map<String, dynamic> toJson() => _$TwonlySafeBackupToJson(this);
}

@JsonSerializable()
class PasswordLessRecovery {
  PasswordLessRecovery(this.threshold);

  factory PasswordLessRecovery.fromJson(Map<String, dynamic> json) =>
      _$PasswordLessRecoveryFromJson(json);

  // Only stored, so the user can see his deposit email address...
  String? email;

  // Data shared with trusted friends

  @JsonKey(defaultValue: 2)
  int threshold;
  // Used to derive the key from the email/pin
  List<int>? serverKeyProtection;
  List<int>? pinUnlockToken;
  // --->

  // Checking with the server that the server data is valid and not delted throug the pin protection for example.
  DateTime? lastServerHeartbeat;
  DateTime? lastContactHeartbeat;
  List<int>? encryptedServerKey;

  Map<String, dynamic> toJson() => _$PasswordLessRecoveryToJson(this);
}
