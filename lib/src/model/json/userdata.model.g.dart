// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'userdata.model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserData _$UserDataFromJson(Map<String, dynamic> json) =>
    UserData(
        userId: (json['userId'] as num).toInt(),
        username: json['username'] as String,
        displayName: json['displayName'] as String,
        subscriptionPlan: json['subscriptionPlan'] as String? ?? 'Free',
        currentSetupPage: json['currentSetupPage'] as String?,
        appVersion: (json['appVersion'] as num?)?.toInt() ?? 0,
      )
      ..avatarSvg = json['avatarSvg'] as String?
      ..avatarJson = json['avatarJson'] as String?
      ..avatarCounter = (json['avatarCounter'] as num?)?.toInt() ?? 0
      ..isDeveloper = json['isDeveloper'] as bool? ?? false
      ..deviceId = (json['deviceId'] as num?)?.toInt() ?? 0
      ..setupProfile =
          $enumDecodeNullable(_$SetupProfileEnumMap, json['setupProfile']) ??
          SetupProfile.standard
      ..securityProfile =
          $enumDecodeNullable(
            _$SecurityProfileEnumMap,
            json['securityProfile'],
          ) ??
          SecurityProfile.normal
      ..subscriptionPlanIdStore = json['subscriptionPlanIdStore'] as String?
      ..lastImageSend = json['lastImageSend'] == null
          ? null
          : DateTime.parse(json['lastImageSend'] as String)
      ..todaysImageCounter = (json['todaysImageCounter'] as num?)?.toInt()
      ..lastPlanBallance = json['lastPlanBallance'] as String?
      ..additionalUserInvites = json['additionalUserInvites'] as String?
      ..themeMode =
          $enumDecodeNullable(_$ThemeModeEnumMap, json['themeMode']) ??
          ThemeMode.system
      ..defaultShowTime = (json['defaultShowTime'] as num?)?.toInt()
      ..requestedAudioPermission =
          json['requestedAudioPermission'] as bool? ?? false
      ..enableDatabaseLogging = json['enableDatabaseLogging'] as bool? ?? false
      ..automaticallyMarkEqualMediaFilesAsOpened =
          json['automaticallyMarkEqualMediaFilesAsOpened'] as bool? ?? false
      ..videoStabilizationEnabled =
          json['videoStabilizationEnabled'] as bool? ?? true
      ..showFeedbackShortcut = json['showFeedbackShortcut'] as bool? ?? true
      ..showShowImagePreviewWhenSending =
          json['showShowImagePreviewWhenSending'] as bool? ?? false
      ..startWithCameraOpen = json['startWithCameraOpen'] as bool? ?? true
      ..preSelectedEmojies = (json['preSelectedEmojies'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList()
      ..autoDownloadOptions =
          (json['autoDownloadOptions'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              (e as List<dynamic>).map((e) => e as String).toList(),
            ),
          )
      ..storeMediaFilesInGallery =
          json['storeMediaFilesInGallery'] as bool? ?? true
      ..autoStoreAllSendUnlimitedMediaFiles =
          json['autoStoreAllSendUnlimitedMediaFiles'] as bool? ?? false
      ..typingIndicators = json['typingIndicators'] as bool? ?? true
      ..myBestFriendGroupId = json['myBestFriendGroupId'] as String?
      ..signalLastSignedPreKeyUpdated =
          json['signalLastSignedPreKeyUpdated'] == null
          ? null
          : DateTime.parse(json['signalLastSignedPreKeyUpdated'] as String)
      ..allowErrorTrackingViaSentry =
          json['allowErrorTrackingViaSentry'] as bool? ?? false
      ..screenLockEnabled = json['screenLockEnabled'] as bool? ?? false
      ..isUserDiscoveryEnabled =
          json['isUserDiscoveryEnabled'] as bool? ?? false
      ..requiredSendImages = (json['requiredSendImages'] as num?)?.toInt() ?? 4
      ..userDiscoveryThreshold =
          (json['userDiscoveryThreshold'] as num?)?.toInt() ?? 3
      ..userDiscoveryRequiresManualApproval =
          json['userDiscoveryRequiresManualApproval'] as bool? ?? false
      ..userDiscoverySharePromotion =
          json['userDiscoverySharePromotion'] as bool? ?? true
      ..userDiscoveryInitializationError =
          json['userDiscoveryInitializationError'] as bool? ?? false
      ..askForFriendPromotions = json['askForFriendPromotions'] as bool? ?? true
      ..currentPreKeyIndexStart =
          (json['currentPreKeyIndexStart'] as num?)?.toInt() ?? 100000
      ..currentSignedPreKeyIndexStart =
          (json['currentSignedPreKeyIndexStart'] as num?)?.toInt() ?? 100000
      ..lastChangeLogHash = (json['lastChangeLogHash'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList()
      ..hideChangeLog = json['hideChangeLog'] as bool? ?? true
      ..updateFCMToken = json['updateFCMToken'] as bool? ?? true
      ..canUseLoginTokenForAuth =
          json['canUseLoginTokenForAuth'] as bool? ?? true
      ..twonlySafeBackup = json['twonlySafeBackup'] == null
          ? null
          : TwonlySafeBackup.fromJson(
              json['twonlySafeBackup'] as Map<String, dynamic>,
            )
      ..isBackupEnabled = json['isBackupEnabled'] as bool? ?? false
      ..passwordLessRecovery = json['passwordLessRecovery'] == null
          ? null
          : PasswordLessRecovery.fromJson(
              json['passwordLessRecovery'] as Map<String, dynamic>,
            )
      ..fcmToken = json['fcmToken'] as String?
      ..askedForUserStudyPermission =
          json['askedForUserStudyPermission'] as bool? ?? false
      ..userStudyParticipantsToken =
          json['userStudyParticipantsToken'] as String?
      ..userStudyCountNewFriendsViaSuggestion =
          (json['userStudyCountNewFriendsViaSuggestion'] as num?)?.toInt() ?? 0
      ..lastUserStudyDataUpload = json['lastUserStudyDataUpload'] == null
          ? null
          : DateTime.parse(json['lastUserStudyDataUpload'] as String)
      ..skipSetupPages = json['skipSetupPages'] as bool? ?? false
      ..hasZoomed = json['hasZoomed'] as bool? ?? false;

Map<String, dynamic> _$UserDataToJson(UserData instance) => <String, dynamic>{
  'userId': instance.userId,
  'username': instance.username,
  'displayName': instance.displayName,
  'avatarSvg': instance.avatarSvg,
  'avatarJson': instance.avatarJson,
  'appVersion': instance.appVersion,
  'avatarCounter': instance.avatarCounter,
  'isDeveloper': instance.isDeveloper,
  'deviceId': instance.deviceId,
  'setupProfile': _$SetupProfileEnumMap[instance.setupProfile]!,
  'securityProfile': _$SecurityProfileEnumMap[instance.securityProfile]!,
  'subscriptionPlan': instance.subscriptionPlan,
  'subscriptionPlanIdStore': instance.subscriptionPlanIdStore,
  'lastImageSend': instance.lastImageSend?.toIso8601String(),
  'todaysImageCounter': instance.todaysImageCounter,
  'lastPlanBallance': instance.lastPlanBallance,
  'additionalUserInvites': instance.additionalUserInvites,
  'themeMode': _$ThemeModeEnumMap[instance.themeMode]!,
  'defaultShowTime': instance.defaultShowTime,
  'requestedAudioPermission': instance.requestedAudioPermission,
  'enableDatabaseLogging': instance.enableDatabaseLogging,
  'automaticallyMarkEqualMediaFilesAsOpened':
      instance.automaticallyMarkEqualMediaFilesAsOpened,
  'videoStabilizationEnabled': instance.videoStabilizationEnabled,
  'showFeedbackShortcut': instance.showFeedbackShortcut,
  'showShowImagePreviewWhenSending': instance.showShowImagePreviewWhenSending,
  'startWithCameraOpen': instance.startWithCameraOpen,
  'preSelectedEmojies': instance.preSelectedEmojies,
  'autoDownloadOptions': instance.autoDownloadOptions,
  'storeMediaFilesInGallery': instance.storeMediaFilesInGallery,
  'autoStoreAllSendUnlimitedMediaFiles':
      instance.autoStoreAllSendUnlimitedMediaFiles,
  'typingIndicators': instance.typingIndicators,
  'myBestFriendGroupId': instance.myBestFriendGroupId,
  'signalLastSignedPreKeyUpdated': instance.signalLastSignedPreKeyUpdated
      ?.toIso8601String(),
  'allowErrorTrackingViaSentry': instance.allowErrorTrackingViaSentry,
  'screenLockEnabled': instance.screenLockEnabled,
  'isUserDiscoveryEnabled': instance.isUserDiscoveryEnabled,
  'requiredSendImages': instance.requiredSendImages,
  'userDiscoveryThreshold': instance.userDiscoveryThreshold,
  'userDiscoveryRequiresManualApproval':
      instance.userDiscoveryRequiresManualApproval,
  'userDiscoverySharePromotion': instance.userDiscoverySharePromotion,
  'userDiscoveryInitializationError': instance.userDiscoveryInitializationError,
  'askForFriendPromotions': instance.askForFriendPromotions,
  'currentPreKeyIndexStart': instance.currentPreKeyIndexStart,
  'currentSignedPreKeyIndexStart': instance.currentSignedPreKeyIndexStart,
  'lastChangeLogHash': instance.lastChangeLogHash,
  'hideChangeLog': instance.hideChangeLog,
  'updateFCMToken': instance.updateFCMToken,
  'canUseLoginTokenForAuth': instance.canUseLoginTokenForAuth,
  'twonlySafeBackup': instance.twonlySafeBackup,
  'isBackupEnabled': instance.isBackupEnabled,
  'passwordLessRecovery': instance.passwordLessRecovery,
  'fcmToken': instance.fcmToken,
  'askedForUserStudyPermission': instance.askedForUserStudyPermission,
  'userStudyParticipantsToken': instance.userStudyParticipantsToken,
  'userStudyCountNewFriendsViaSuggestion':
      instance.userStudyCountNewFriendsViaSuggestion,
  'lastUserStudyDataUpload': instance.lastUserStudyDataUpload
      ?.toIso8601String(),
  'currentSetupPage': instance.currentSetupPage,
  'skipSetupPages': instance.skipSetupPages,
  'hasZoomed': instance.hasZoomed,
};

const _$SetupProfileEnumMap = {
  SetupProfile.standard: 'standard',
  SetupProfile.customized: 'customized',
  SetupProfile.maximum: 'maximum',
};

const _$SecurityProfileEnumMap = {
  SecurityProfile.normal: 'normal',
  SecurityProfile.strict: 'strict',
};

const _$ThemeModeEnumMap = {
  ThemeMode.system: 'system',
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
};

TwonlySafeBackup _$TwonlySafeBackupFromJson(Map<String, dynamic> json) =>
    TwonlySafeBackup(
        backupId: (json['backupId'] as List<dynamic>)
            .map((e) => (e as num).toInt())
            .toList(),
        encryptionKey: (json['encryptionKey'] as List<dynamic>)
            .map((e) => (e as num).toInt())
            .toList(),
      )
      ..lastBackupSize = (json['lastBackupSize'] as num).toInt()
      ..backupUploadState = $enumDecode(
        _$LastBackupUploadStateEnumMap,
        json['backupUploadState'],
      )
      ..lastBackupDone = json['lastBackupDone'] == null
          ? null
          : DateTime.parse(json['lastBackupDone'] as String);

Map<String, dynamic> _$TwonlySafeBackupToJson(TwonlySafeBackup instance) =>
    <String, dynamic>{
      'lastBackupSize': instance.lastBackupSize,
      'backupUploadState':
          _$LastBackupUploadStateEnumMap[instance.backupUploadState]!,
      'lastBackupDone': instance.lastBackupDone?.toIso8601String(),
      'backupId': instance.backupId,
      'encryptionKey': instance.encryptionKey,
    };

const _$LastBackupUploadStateEnumMap = {
  LastBackupUploadState.none: 'none',
  LastBackupUploadState.pending: 'pending',
  LastBackupUploadState.failed: 'failed',
  LastBackupUploadState.success: 'success',
};

PasswordLessRecovery _$PasswordLessRecoveryFromJson(
  Map<String, dynamic> json,
) => PasswordLessRecovery()
  ..email = json['email'] as String?
  ..pinSeed = (json['pinSeed'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList()
  ..pinUnlockToken = (json['pinUnlockToken'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList()
  ..encryptedServerKeyNonce =
      (json['encryptedServerKeyNonce'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList()
  ..lastServerHeartbeat = json['lastServerHeartbeat'] == null
      ? null
      : DateTime.parse(json['lastServerHeartbeat'] as String)
  ..lastContactHeartbeat = json['lastContactHeartbeat'] == null
      ? null
      : DateTime.parse(json['lastContactHeartbeat'] as String)
  ..encryptedServerKey = (json['encryptedServerKey'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList();

Map<String, dynamic> _$PasswordLessRecoveryToJson(
  PasswordLessRecovery instance,
) => <String, dynamic>{
  'email': instance.email,
  'pinSeed': instance.pinSeed,
  'pinUnlockToken': instance.pinUnlockToken,
  'encryptedServerKeyNonce': instance.encryptedServerKeyNonce,
  'lastServerHeartbeat': instance.lastServerHeartbeat?.toIso8601String(),
  'lastContactHeartbeat': instance.lastContactHeartbeat?.toIso8601String(),
  'encryptedServerKey': instance.encryptedServerKey,
};
