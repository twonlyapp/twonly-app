import 'package:json_annotation/json_annotation.dart';

part 'onboarding_state.model.g.dart';

/// Holds information about a single trusted friend who has already shared their
/// recovery part.
@JsonSerializable()
class ReceivedRecoveryShare {
  ReceivedRecoveryShare({
    required this.messageId,
    required this.trustedFriendDisplayName,
    required this.myDisplayName,
    required this.myUserId,
    required this.myAvatarSvg,
    required this.threshold,
    required this.sharedSecretDataBytes,
  });

  factory ReceivedRecoveryShare.fromJson(Map<String, dynamic> json) =>
      _$ReceivedRecoveryShareFromJson(json);

  final int messageId;

  final String trustedFriendDisplayName;

  final String myDisplayName;
  final int myUserId;
  final List<int>? myAvatarSvg;

  final int threshold;

  final List<int> sharedSecretDataBytes;

  Map<String, dynamic> toJson() => _$ReceivedRecoveryShareToJson(this);
}

@JsonSerializable()
class OnboardingState {
  OnboardingState({
    this.hasOnboardingFinished = false,
    this.hasStartedPasswordlessRecovery = false,
    this.notificationId,
    this.downloadAuthToken,
    this.serverRegistered = false,
    this.encryptionKey,
  });

  factory OnboardingState.fromJson(Map<String, dynamic> json) =>
      _$OnboardingStateFromJson(json);

  bool hasOnboardingFinished;
  bool hasStartedPasswordlessRecovery;

  String? notificationId;
  List<int>? downloadAuthToken;
  bool serverRegistered;
  List<int>? encryptionKey;

  List<ReceivedRecoveryShare> receivedShares = [];

  Map<String, dynamic> toJson() => _$OnboardingStateToJson(this);
}
