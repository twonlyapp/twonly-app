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
              : DateTime.parse(json['signalLastSignedPreKeyUpdated'] as String);

Map<String, dynamic> _$UserDataToJson(UserData instance) => <String, dynamic>{
      'username': instance.username,
      'displayName': instance.displayName,
      'avatarSvg': instance.avatarSvg,
      'avatarJson': instance.avatarJson,
      'avatarCounter': instance.avatarCounter,
      'isDemoUser': instance.isDemoUser,
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
      'userId': instance.userId,
    };

const _$ThemeModeEnumMap = {
  ThemeMode.system: 'system',
  ThemeMode.light: 'light',
  ThemeMode.dark: 'dark',
};
