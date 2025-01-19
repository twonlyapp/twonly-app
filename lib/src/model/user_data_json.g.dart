// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_data_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserData _$UserDataFromJson(Map<String, dynamic> json) => UserData(
      userId: const Uint8ListConverter().fromJson(json['userId'] as String),
      username: json['username'] as String,
      displayName: json['displayName'] as String,
    );

Map<String, dynamic> _$UserDataToJson(UserData instance) => <String, dynamic>{
      'username': instance.username,
      'displayName': instance.displayName,
      'userId': const Uint8ListConverter().toJson(instance.userId),
    };
