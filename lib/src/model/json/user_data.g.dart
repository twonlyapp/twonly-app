// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserData _$UserDataFromJson(Map<String, dynamic> json) => UserData(
      userId: (json['userId'] as num).toInt(),
      username: json['username'] as String,
      displayName: json['displayName'] as String,
    );

Map<String, dynamic> _$UserDataToJson(UserData instance) => <String, dynamic>{
      'username': instance.username,
      'displayName': instance.displayName,
      'userId': instance.userId,
    };
