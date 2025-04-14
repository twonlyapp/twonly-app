// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'userdata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserData _$UserDataFromJson(Map<String, dynamic> json) => UserData(
      userId: (json['userId'] as num).toInt(),
      username: json['username'] as String,
      displayName: json['displayName'] as String,
    )
      ..avatarSvg = json['avatarSvg'] as String?
      ..avatarJson = json['avatarJson'] as String?
      ..avatarCounter = (json['avatarCounter'] as num?)?.toInt()
      ..defaultShowTime = (json['defaultShowTime'] as num?)?.toInt()
      ..useHighQuality = json['useHighQuality'] as bool?
      ..preSelectedEmojies = (json['preSelectedEmojies'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList();

Map<String, dynamic> _$UserDataToJson(UserData instance) => <String, dynamic>{
      'username': instance.username,
      'displayName': instance.displayName,
      'avatarSvg': instance.avatarSvg,
      'avatarJson': instance.avatarJson,
      'avatarCounter': instance.avatarCounter,
      'defaultShowTime': instance.defaultShowTime,
      'useHighQuality': instance.useHighQuality,
      'preSelectedEmojies': instance.preSelectedEmojies,
      'userId': instance.userId,
    };
