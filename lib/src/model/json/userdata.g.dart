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
      ..avatarCounter = (json['avatarCounter'] as num?)?.toInt() ?? 0
      ..lastImageSend = json['lastImageSend'] == null
          ? null
          : DateTime.parse(json['lastImageSend'] as String)
      ..todaysImageCounter = (json['todaysImageCounter'] as num?)?.toInt()
      ..themeMode =
          $enumDecodeNullable(_$ThemeModeEnumMap, json['themeMode']) ??
              ThemeMode.system
      ..defaultShowTime = (json['defaultShowTime'] as num?)?.toInt()
      ..useHighQuality = json['useHighQuality'] as bool? ?? true
      ..preSelectedEmojies = (json['preSelectedEmojies'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList()
      ..autoDownloadOptions =
          (json['autoDownloadOptions'] as Map<String, dynamic>?)?.map(
        (k, e) =>
            MapEntry(k, (e as List<dynamic>).map((e) => e as String).toList()),
      )
      ..storeMediaFilesInGallery =
          json['storeMediaFilesInGallery'] as bool? ?? false
      ..lastUsedEditorEmojis = (json['lastUsedEditorEmojis'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList()
      ..lastPlanBallance = json['lastPlanBallance'] as String?
      ..additionalUserInvites = json['additionalUserInvites'] as String?
      ..tutorialDisplayed = (json['tutorialDisplayed'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList()
      ..myBestFriendContactId = (json['myBestFriendContactId'] as num?)?.toInt()
      ..signalLastSignedPreKeyUpdated =
          json['signalLastSignedPreKeyUpdated'] == null
              ? null
              : DateTime.parse(json['signalLastSignedPreKeyUpdated'] as String)
      ..currentPreKeyIndexStart =
          (json['currentPreKeyIndexStart'] as num?)?.toInt() ?? 100000
      ..currentSignedPreKeyIndexStart =
          (json['currentSignedPreKeyIndexStart'] as num?)?.toInt() ?? 100000
      ..nextTimeToShowBackupNotice = json['nextTimeToShowBackupNotice'] == null
          ? null
          : DateTime.parse(json['nextTimeToShowBackupNotice'] as String)
      ..backupServer = json['backupServer'] == null
          ? null
          : BackupServer.fromJson(json['backupServer'] as Map<String, dynamic>)
      ..twonlySafeBackup = json['twonlySafeBackup'] == null
          ? null
          : TwonlySafeBackup.fromJson(
              json['twonlySafeBackup'] as Map<String, dynamic>);

Map<String, dynamic> _$UserDataToJson(UserData instance) => <String, dynamic>{
      'userId': instance.userId,
      'isDemoUser': instance.isDemoUser,
      'username': instance.username,
      'displayName': instance.displayName,
      'avatarSvg': instance.avatarSvg,
      'avatarJson': instance.avatarJson,
      'avatarCounter': instance.avatarCounter,
      'subscriptionPlan': instance.subscriptionPlan,
      'lastImageSend': instance.lastImageSend?.toIso8601String(),
      'todaysImageCounter': instance.todaysImageCounter,
      'themeMode': _$ThemeModeEnumMap[instance.themeMode]!,
      'defaultShowTime': instance.defaultShowTime,
      'useHighQuality': instance.useHighQuality,
      'preSelectedEmojies': instance.preSelectedEmojies,
      'autoDownloadOptions': instance.autoDownloadOptions,
      'storeMediaFilesInGallery': instance.storeMediaFilesInGallery,
      'lastUsedEditorEmojis': instance.lastUsedEditorEmojis,
      'lastPlanBallance': instance.lastPlanBallance,
      'additionalUserInvites': instance.additionalUserInvites,
      'tutorialDisplayed': instance.tutorialDisplayed,
      'myBestFriendContactId': instance.myBestFriendContactId,
      'signalLastSignedPreKeyUpdated':
          instance.signalLastSignedPreKeyUpdated?.toIso8601String(),
      'currentPreKeyIndexStart': instance.currentPreKeyIndexStart,
      'currentSignedPreKeyIndexStart': instance.currentSignedPreKeyIndexStart,
      'nextTimeToShowBackupNotice':
          instance.nextTimeToShowBackupNotice?.toIso8601String(),
      'backupServer': instance.backupServer,
      'twonlySafeBackup': instance.twonlySafeBackup,
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
      ..backupUploadState =
          $enumDecode(_$LastBackupUploadStateEnumMap, json['backupUploadState'])
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
