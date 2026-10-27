import 'dart:convert';

import 'package:twonly/core/database/app/contact_groups/table.dart';
import 'package:twonly/core/database/app/contacts/table.dart';
import 'package:twonly/core/database/app/groups/table.dart';
import 'package:twonly/core/database/app/key_verifications/table.dart';
import 'package:twonly/core/database/app/mediafiles/table.dart';
import 'package:twonly/core/database/app/messages/table.dart';
import 'package:twonly/core/database/app/patch.dart';
import 'package:twonly/core/database/app/reactions/table.dart';
import 'package:twonly/core/database/app/receipts/table.dart';
import 'package:twonly/core/database/app/stickers/table.dart';
import 'package:twonly/core/database/app/user_discovery/table.dart';
import 'package:twonly/src/model/contact_enums.dart';
import 'package:twonly/src/model/group_enums.dart';
import 'package:twonly/src/model/media_enums.dart';
import 'package:twonly/src/model/message_enums.dart';

/// SQLite timestamps are stored in seconds; keep the presentation in local time.
DateTime? databaseDate(int? seconds) => seconds == null
    ? null
    : DateTime.fromMillisecondsSinceEpoch(seconds * 1000);

int databaseSeconds(DateTime value) => value.millisecondsSinceEpoch ~/ 1000;

extension ContactValues on Contact {
  bool? get preferPhotoAvatar =>
      preferPhotoAvatarFlag == null ? null : preferPhotoAvatarFlag != 0;
  bool get accepted => acceptedFlag != 0;
  bool get deletedByUser => deletedByUserFlag != 0;
  bool get requested => requestedFlag != 0;
  bool get blocked => blockedFlag != 0;
  bool get verified => verifiedFlag != 0;
  bool get accountDeleted => accountDeletedFlag != 0;
  DateTime get createdAt => databaseDate(createdAtSeconds)!;
  SignalVersion get signalVersion =>
      SignalVersion.values.byName(signalVersionName);
  bool get userDiscoveryExcluded => userDiscoveryExcludedFlag != 0;
  bool? get userDiscoveryManualApproved =>
      userDiscoveryManualApprovedFlag == null
      ? null
      : userDiscoveryManualApprovedFlag != 0;
  bool get recoveryIsTrustedFriend => recoveryIsTrustedFriendFlag != 0;
  DateTime? get recoveryLastHeartbeat =>
      databaseDate(recoveryLastHeartbeatSeconds);
  DateTime? get recoveryContactsLastHeartbeat =>
      databaseDate(recoveryContactsLastHeartbeatSeconds);
  bool? get askForFriendPromotions => askForFriendPromotionsFlag == null
      ? null
      : askForFriendPromotionsFlag != 0;
  bool get widgetSharingAllowed => widgetSharingAllowedFlag != 0;
  bool get widgetSharingGranted => widgetSharingGrantedFlag != 0;
  DateTime? get joinedAt => databaseDate(joinedAtSeconds);
}

extension GroupValues on Group {
  DateTime get createdAt => databaseDate(createdAtSeconds)!;
  DateTime? get lastMessageSend => databaseDate(lastMessageSendSeconds);
  DateTime? get lastMessageReceived => databaseDate(lastMessageReceivedSeconds);
  DateTime? get lastFlameCounterChange =>
      databaseDate(lastFlameCounterChangeSeconds);
  DateTime? get lastFlameSync => databaseDate(lastFlameSyncSeconds);
  DateTime? get maxFlameCounterFrom => databaseDate(maxFlameCounterFromSeconds);
  DateTime get lastMessageExchange => databaseDate(lastMessageExchangeSeconds)!;
}

extension GroupMemberValues on GroupMember {
  MemberState? get memberState => memberStateName == null
      ? null
      : MemberState.values.byName(memberStateName!);
  DateTime? get lastChatOpened => databaseDate(lastChatOpenedSeconds);
  DateTime? get lastTypeIndicator => databaseDate(lastTypeIndicatorSeconds);
  DateTime? get lastMessage => databaseDate(lastMessageSeconds);
  DateTime get createdAt => databaseDate(createdAtSeconds)!;
}

extension GroupHistoryValues on GroupHistory {
  GroupActionType get type => GroupActionType.values.byName(typeName);
  DateTime get actionAt => databaseDate(actionAtSeconds)!;
}

extension MessageValues on StoredMessage {
  DateTime? get openedAt => databaseDate(openedAtSeconds);
  DateTime? get openedByAll => databaseDate(openedByAllSeconds);
  DateTime get createdAt => databaseDate(createdAtSeconds)!;
  DateTime? get modifiedAt => databaseDate(modifiedAtSeconds);
  DateTime? get ackByUser => databaseDate(ackByUserSeconds);
  DateTime? get ackByServer => databaseDate(ackByServerSeconds);
}

extension MessageActionValues on MessageAction {
  MessageActionType get type => MessageActionType.values.byName(typeName);
  DateTime get actionAt => databaseDate(actionAtSeconds)!;
}

extension MessageHistoryValues on MessageHistory {
  DateTime get createdAt => databaseDate(createdAtSeconds)!;
}

extension MediaFileValues on MediaFile {
  MediaType get type => MediaType.values.byName(typeName);
  UploadState? get uploadState => uploadStateName == null
      ? null
      : UploadState.values.byName(uploadStateName!);
  CloudState get cloudState => CloudState.values.byName(cloudStateName);
  DownloadState? get downloadState => downloadStateName == null
      ? null
      : DownloadState.values.byName(downloadStateName!);
  List<int>? get reuploadRequestedBy => reuploadRequestedByJson == null
      ? null
      : (jsonDecode(reuploadRequestedByJson!) as List<dynamic>).cast<int>();
  DateTime get createdAt => databaseDate(createdAtSeconds)!;
}

extension ReceiptValues on Receipt {
  bool get contactWillSendsReceipt => contactWillSendsReceiptFlag != 0;
  bool get willBeRetriedByMediaUpload => willBeRetriedByMediaUploadFlag != 0;
  DateTime? get markForRetry => databaseDate(markForRetrySeconds);
  DateTime? get markForRetryAfterAccepted =>
      databaseDate(markForRetryAfterAcceptedSeconds);
  DateTime? get ackByServerAt => databaseDate(ackByServerAtSeconds);
  DateTime? get lastRetry => databaseDate(lastRetrySeconds);
  DateTime get createdAt => databaseDate(createdAtSeconds)!;
}

extension ContactGroupValues on ContactGroup {
  DateTime get createdAt => databaseDate(createdAtSeconds)!;
}

extension KeyVerificationValues on KeyVerification {
  VerificationType get type => VerificationType.values.byName(typeName);
  DateTime get createdAt => databaseDate(createdAtSeconds)!;
}

extension ReactionValues on StoredReaction {
  DateTime get createdAt => databaseDate(createdAtSeconds)!;
}

extension UserDiscoveryUserRelationValues on UserDiscoveryUserRelation {
  DateTime? get publicKeyVerifiedTimestamp =>
      databaseDate(publicKeyVerifiedTimestampSeconds);
}

extension UserDiscoveryOtherPromotionValues on UserDiscoveryOtherPromotion {
  DateTime? get publicKeyVerifiedTimestamp =>
      databaseDate(publicKeyVerifiedTimestampSeconds);
}

int? databaseNullableSeconds(DateTime? value) =>
    value == null ? null : databaseSeconds(value);
int? databaseNullableFlag(bool? value) => value == null
    ? null
    : value
    ? 1
    : 0;
String? databaseNullableJson(List<int>? value) =>
    value == null ? null : jsonEncode(value);

/// Local message presentation overrides; persistence uses MessagePatch directly.
extension MessagePresentation on StoredMessage {
  StoredMessage copyWith({
    DateTime? createdAt,
    NullableText? content,
    NullableText? mediaId,
    NullableInt? ackByServer,
    NullableBytes? additionalMessageData,
  }) => StoredMessage(
    groupId: groupId,
    messageId: messageId,
    activityMessageId: activityMessageId,
    originalSenderId: originalSenderId,
    senderId: senderId,
    type: type,
    content: content == null ? this.content : content.value,
    mediaId: mediaId == null ? this.mediaId : mediaId.value,
    additionalMessageData: additionalMessageData == null
        ? this.additionalMessageData
        : additionalMessageData.value,
    mediaStored: mediaStored,
    mediaReopened: mediaReopened,
    downloadToken: downloadToken,
    quotesMessageId: quotesMessageId,
    isDeletedFromSender: isDeletedFromSender,
    isWidgetMedia: isWidgetMedia,
    isStory: isStory,
    openedAtSeconds: openedAtSeconds,
    openedByAllSeconds: openedByAllSeconds,
    createdAtSeconds: createdAt == null
        ? createdAtSeconds
        : databaseSeconds(createdAt),
    modifiedAtSeconds: modifiedAtSeconds,
    ackByUserSeconds: ackByUserSeconds,
    ackByServerSeconds: ackByServer == null
        ? ackByServerSeconds
        : ackByServer.value,
  );
}

extension StickerValues on LocalSticker {
  String get contentHash => metadata.contentHash;
  int get width => metadata.width;
  int get height => metadata.height;
  int get usageCount => metadata.usageCount;
  DateTime get createdAt => databaseDate(metadata.createdAt)!;
  DateTime get lastUsedAt => databaseDate(metadata.lastUsedAt)!;
}
