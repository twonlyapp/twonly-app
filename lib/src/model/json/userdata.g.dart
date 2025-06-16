// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'userdata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserData _$UserDataFromJson(Map<String, dynamic> json) => UserData(
      userId: (json['userId'] as num).toInt(),
      username: json['username'] as String,
      displayName: json['displayName'] as String,
      subscriptionPlan: json['subscriptionPlan'] as String? ?? 'Preview',
      isDemoUser: json['isDemoUser'] as bool? ?? false,
    )
      ..avatarSvg = json['avatarSvg'] as String?
      ..avatarJson = json['avatarJson'] as String?
      ..avatarCounter = (json['avatarCounter'] as num?)?.toInt()
      ..defaultShowTime = (json['defaultShowTime'] as num?)?.toInt()
      ..useHighQuality = json['useHighQuality'] as bool?
      ..preSelectedEmojies = (json['preSelectedEmojies'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList()
      ..themeMode = $enumDecodeNullable(_$ThemeModeEnumMap, json['themeMode'])
      ..autoDownloadOptions =
          (json['autoDownloadOptions'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      )
      ..storeMediaFilesInGallery = json['storeMediaFilesInGallery'] as bool?
      ..lastUsedEditorEmojis = (json['lastUsedEditorEmojis'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList()
      ..lastPlanBallance = json['lastPlanBallance'] as String?
      ..additionalUserInvites = json['additionalUserInvites'] as String?
      ..lastImageSend = json['lastImageSend'] == null
          ? null
          : DateTime.parse(json['lastImageSend'] as String)
      ..todaysImageCounter = (json['todaysImageCounter'] as num?)?.toInt()
      ..tutorialDisplayed = (json['tutorialDisplayed'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList()
      ..myBestFriendContactId = (json['myBestFriendContactId'] as num?)?.toInt()
      ..signalLastSignedPreKeyUpdated =
          json['signalLastSignedPreKeyUpdated'] == null
              ? null
              : DateTime.parse(json['signalLastSignedPreKeyUpdated'] as String)
      ..identityBackupEnabled = json['identityBackupEnabled'] as bool? ?? false
      ..identityBackupLastBackupTime =
          json['identityBackupLastBackupTime'] == null
              ? null
              : DateTime.parse(json['identityBackupLastBackupTime'] as String)
      ..identityBackupLastBackupSize =
          (json['identityBackupLastBackupSize'] as num?)?.toInt() ?? 0
      ..nextTimeToShowBackupNotice = json['nextTimeToShowBackupNotice'] == null
          ? null
          : DateTime.parse(json['nextTimeToShowBackupNotice'] as String)
      ..backupServer = json['backupServer'] == null
          ? null
          : BackupServer.fromJson(json['backupServer'] as Map<String, dynamic>)
      ..twonlySafeEncryptionKey =
          (json['twonlySafeEncryptionKey'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList()
      ..twonlySafeBackupId = (json['twonlySafeBackupId'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList();

Map<String, dynamic> _$UserDataToJson(UserData instance) => <String, dynamic>{
      'userId': instance.userId,
      'isDemoUser': instance.isDemoUser,
      'username': instance.username,
      'displayName': instance.displayName,
      'avatarSvg': instance.avatarSvg,
      'avatarJson': instance.avatarJson,
      'avatarCounter': instance.avatarCounter,
      'defaultShowTime': instance.defaultShowTime,
      'subscriptionPlan': instance.subscriptionPlan,
      'useHighQuality': instance.useHighQuality,
      'preSelectedEmojies': instance.preSelectedEmojies,
      'themeMode': _$ThemeModeEnumMap[instance.themeMode],
      'autoDownloadOptions': instance.autoDownloadOptions,
      'storeMediaFilesInGallery': instance.storeMediaFilesInGallery,
      'lastUsedEditorEmojis': instance.lastUsedEditorEmojis,
      'lastPlanBallance': instance.lastPlanBallance,
      'additionalUserInvites': instance.additionalUserInvites,
      'lastImageSend': instance.lastImageSend?.toIso8601String(),
      'todaysImageCounter': instance.todaysImageCounter,
      'tutorialDisplayed': instance.tutorialDisplayed,
      'myBestFriendContactId': instance.myBestFriendContactId,
      'signalLastSignedPreKeyUpdated':
          instance.signalLastSignedPreKeyUpdated?.toIso8601String(),
      'identityBackupEnabled': instance.identityBackupEnabled,
      'identityBackupLastBackupTime':
          instance.identityBackupLastBackupTime?.toIso8601String(),
      'identityBackupLastBackupSize': instance.identityBackupLastBackupSize,
      'nextTimeToShowBackupNotice':
          instance.nextTimeToShowBackupNotice?.toIso8601String(),
      'backupServer': instance.backupServer,
      'twonlySafeEncryptionKey': instance.twonlySafeEncryptionKey,
      'twonlySafeBackupId': instance.twonlySafeBackupId,
    };

const _$ThemeModeEnumMap = {
  ThemeMode.system: 'system',
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
};

BackupServer _$BackupServerFromJson(Map<String, dynamic> json) => BackupServer(
      serverUrl: json['serverUrl'] as String,
      retentionDays: (json['retentionDays'] as num).toInt(),
      maxBackupBytes: (json['maxBackupBytes'] as num).toInt(),
    );

Map<String, dynamic> _$BackupServerToJson(BackupServer instance) =>
    <String, dynamic>{
      'serverUrl': instance.serverUrl,
      'retentionDays': instance.retentionDays,
      'maxBackupBytes': instance.maxBackupBytes,
    };
