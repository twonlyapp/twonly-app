// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signal_identity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SignalIdentity _$SignalIdentityFromJson(Map<String, dynamic> json) =>
    SignalIdentity(
      identityKeyPairU8List: const Uint8ListConverter()
          .fromJson(json['identityKeyPairU8List'] as String),
      registrationId:
          const Int64Converter().fromJson(json['registrationId'] as String),
    );

Map<String, dynamic> _$SignalIdentityToJson(SignalIdentity instance) =>
    <String, dynamic>{
      'registrationId': const Int64Converter().toJson(instance.registrationId),
      'identityKeyPairU8List':
          const Uint8ListConverter().toJson(instance.identityKeyPairU8List),
    };
