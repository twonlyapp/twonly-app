// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signal_identity_json.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignalIdentity _$SignalIdentityFromJson(Map<String, dynamic> json) =>
    SignalIdentity(
      identityKeyPairU8List: const Uint8ListConverter()
          .fromJson(json['identityKeyPairU8List'] as String),
      registrationId: (json['registrationId'] as num).toInt(),
    );

Map<String, dynamic> _$SignalIdentityToJson(SignalIdentity instance) =>
    <String, dynamic>{
      'registrationId': instance.registrationId,
      'identityKeyPairU8List':
          const Uint8ListConverter().toJson(instance.identityKeyPairU8List),
    };
