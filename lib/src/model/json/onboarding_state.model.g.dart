// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_state.model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReceivedRecoveryShare _$ReceivedRecoveryShareFromJson(
  Map<String, dynamic> json,
) => ReceivedRecoveryShare(
  messageId: (json['messageId'] as num).toInt(),
  trustedFriendDisplayName: json['trustedFriendDisplayName'] as String,
  myDisplayName: json['myDisplayName'] as String,
  myUserId: (json['myUserId'] as num).toInt(),
  myAvatarSvg: (json['myAvatarSvg'] as List<dynamic>?)
      ?.map((e) => (e as num).toInt())
      .toList(),
  threshold: (json['threshold'] as num).toInt(),
  sharedSecretDataBytes: (json['sharedSecretDataBytes'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$ReceivedRecoveryShareToJson(
  ReceivedRecoveryShare instance,
) => <String, dynamic>{
  'messageId': instance.messageId,
  'trustedFriendDisplayName': instance.trustedFriendDisplayName,
  'myDisplayName': instance.myDisplayName,
  'myUserId': instance.myUserId,
  'myAvatarSvg': instance.myAvatarSvg,
  'threshold': instance.threshold,
  'sharedSecretDataBytes': instance.sharedSecretDataBytes,
};

OnboardingState _$OnboardingStateFromJson(Map<String, dynamic> json) =>
    OnboardingState(
        hasOnboardingFinished: json['hasOnboardingFinished'] as bool? ?? false,
        hasStartedPasswordlessRecovery:
            json['hasStartedPasswordlessRecovery'] as bool? ?? false,
        notificationId: json['notificationId'] as String?,
        downloadAuthToken: (json['downloadAuthToken'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList(),
        serverRegistered: json['serverRegistered'] as bool? ?? false,
        encryptionKey: (json['encryptionKey'] as List<dynamic>?)
            ?.map((e) => (e as num).toInt())
            .toList(),
      )
      ..receivedShares = (json['receivedShares'] as List<dynamic>)
          .map((e) => ReceivedRecoveryShare.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$OnboardingStateToJson(OnboardingState instance) =>
    <String, dynamic>{
      'hasOnboardingFinished': instance.hasOnboardingFinished,
      'hasStartedPasswordlessRecovery': instance.hasStartedPasswordlessRecovery,
      'notificationId': instance.notificationId,
      'downloadAuthToken': instance.downloadAuthToken,
      'serverRegistered': instance.serverRegistered,
      'encryptionKey': instance.encryptionKey,
      'receivedShares': instance.receivedShares,
    };
