// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      username: json['username'] as String,
      identityKeyPairU8List: const Uint8ListConverter()
          .fromJson(json['identityKeyPairU8List'] as List<int>),
      registrationId: (json['registrationId'] as num).toInt(),
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'username': instance.username,
      'registrationId': instance.registrationId,
      'identityKeyPairU8List':
          const Uint8ListConverter().toJson(instance.identityKeyPairU8List),
    };
