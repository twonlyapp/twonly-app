// ignore_for_file: strict_raw_type, prefer_constructors_over_static_methods

import 'package:flutter/material.dart';
import 'package:twonly/src/database/tables/messages_table.dart';
import 'package:twonly/src/utils/misc.dart';

Color getMessageColorFromType(MessageContent content, BuildContext context) {
  Color color;

  if (content is TextMessageContent) {
    color = Colors.blueAccent;
  } else {
    if (content is MediaMessageContent) {
      if (content.isRealTwonly) {
        color = context.color.primary;
      } else {
        if (content.isVideo) {
          color = const Color.fromARGB(255, 240, 243, 33);
        } else {
          color = Colors.redAccent;
        }
      }
    } else {
      return (isDarkMode(context)) ? Colors.white : Colors.black;
    }
  }
  return color;
}

extension MessageKindExtension on MessageKind {
  String get name => toString().split('.').last;

  static MessageKind fromString(String name) {
    return MessageKind.values.firstWhere((e) => e.name == name);
  }
}

class MessageJson {
  MessageJson({
    required this.kind,
    required this.content,
    required this.timestamp,
    this.messageReceiverId,
    this.messageSenderId,
    this.retransId,
  });
  final MessageKind kind;
  final MessageContent? content;
  final int? messageReceiverId;
  final int? messageSenderId;
  int? retransId;
  DateTime timestamp;

  @override
  String toString() {
    return 'Message(kind: $kind, content: $content, timestamp: $timestamp)';
  }

  static MessageJson fromJson(Map<String, dynamic> json) {
    final kind = MessageKindExtension.fromString(json['kind'] as String);

    return MessageJson(
      kind: kind,
      messageReceiverId: (json['messageReceiverId'] as num?)?.toInt(),
      messageSenderId: (json['messageSenderId'] as num?)?.toInt(),
      retransId: (json['retransId'] as num?)?.toInt(),
      content: MessageContent.fromJson(
          kind, json['content'] as Map<String, dynamic>),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'kind': kind.name,
        'content': content?.toJson(),
        'messageReceiverId': messageReceiverId,
        'messageSenderId': messageSenderId,
        'retransId': retransId,
        'timestamp': timestamp.toUtc().millisecondsSinceEpoch,
      };
}

class MessageContent {
  MessageContent();

  static MessageContent? fromJson(MessageKind kind, Map json) {
    switch (kind) {
      case MessageKind.media:
        return MediaMessageContent.fromJson(json);
      case MessageKind.textMessage:
        return TextMessageContent.fromJson(json);
      case MessageKind.profileChange:
        return ProfileContent.fromJson(json);
      case MessageKind.pushKey:
        return PushKeyContent.fromJson(json);
      case MessageKind.reopenedMedia:
        return ReopenedMediaFileContent.fromJson(json);
      case MessageKind.flameSync:
        return FlameSyncContent.fromJson(json);
      case MessageKind.ack:
        return AckContent.fromJson(json);
      case MessageKind.signalDecryptError:
        return SignalDecryptErrorContent.fromJson(json);
      case MessageKind.storedMediaFile:
      case MessageKind.contactRequest:
      case MessageKind.rejectRequest:
      case MessageKind.acceptRequest:
      case MessageKind.opened:
      case MessageKind.requestPushKey:
      case MessageKind.receiveMediaError:
    }
    return null;
  }

  Map toJson() {
    return {};
  }
}

class MediaMessageContent extends MessageContent {
  MediaMessageContent({
    required this.maxShowTime,
    required this.isRealTwonly,
    required this.isVideo,
    required this.mirrorVideo,
    this.downloadToken,
    this.encryptionKey,
    this.encryptionMac,
    this.encryptionNonce,
  });
  final int maxShowTime;
  final bool isRealTwonly;
  final bool isVideo;
  final bool mirrorVideo;
  final List<int>? downloadToken;
  final List<int>? encryptionKey;
  final List<int>? encryptionMac;
  final List<int>? encryptionNonce;

  static MediaMessageContent fromJson(Map json) {
    return MediaMessageContent(
      downloadToken: json['downloadToken'] == null
          ? null
          : List<int>.from(json['downloadToken'] as List),
      encryptionKey: json['encryptionKey'] == null
          ? null
          : List<int>.from(json['encryptionKey'] as List),
      encryptionMac: json['encryptionMac'] == null
          ? null
          : List<int>.from(json['encryptionMac'] as List),
      encryptionNonce: json['encryptionNonce'] == null
          ? null
          : List<int>.from(json['encryptionNonce'] as List),
      maxShowTime: json['maxShowTime'] as int,
      isRealTwonly: json['isRealTwonly'] as bool,
      isVideo: json['isVideo'] as bool? ?? false,
      mirrorVideo: json['mirrorVideo'] as bool? ?? false,
    );
  }

  @override
  Map toJson() {
    return {
      'downloadToken': downloadToken,
      'encryptionKey': encryptionKey,
      'encryptionMac': encryptionMac,
      'encryptionNonce': encryptionNonce,
      'isRealTwonly': isRealTwonly,
      'maxShowTime': maxShowTime,
      'isVideo': isVideo,
      'mirrorVideo': mirrorVideo,
    };
  }
}

class TextMessageContent extends MessageContent {
  TextMessageContent({
    required this.text,
    this.responseToMessageId,
    this.responseToOtherMessageId,
  });
  String text;
  int? responseToMessageId;
  int? responseToOtherMessageId;

  static TextMessageContent fromJson(Map json) {
    return TextMessageContent(
        text: json['text'] as String,
        responseToOtherMessageId: json.containsKey('responseToOtherMessageId')
            ? json['responseToOtherMessageId'] as int?
            : null,
        responseToMessageId: json.containsKey('responseToMessageId')
            ? json['responseToMessageId'] as int?
            : null);
  }

  @override
  Map toJson() {
    return {
      'text': text,
      'responseToMessageId': responseToMessageId,
      'responseToOtherMessageId': responseToOtherMessageId,
    };
  }
}

class ReopenedMediaFileContent extends MessageContent {
  ReopenedMediaFileContent({required this.messageId});
  int messageId;

  static ReopenedMediaFileContent fromJson(Map json) {
    return ReopenedMediaFileContent(messageId: json['messageId'] as int);
  }

  @override
  Map toJson() {
    return {'messageId': messageId};
  }
}

class SignalDecryptErrorContent extends MessageContent {
  SignalDecryptErrorContent({required this.encryptedHash});
  List<int> encryptedHash;

  static SignalDecryptErrorContent fromJson(Map json) {
    return SignalDecryptErrorContent(
      encryptedHash: List<int>.from(json['encryptedHash'] as List),
    );
  }

  @override
  Map toJson() {
    return {
      'encryptedHash': encryptedHash,
    };
  }
}

class AckContent extends MessageContent {
  AckContent({required this.messageIdToAck, required this.retransIdToAck});
  int? messageIdToAck;
  int retransIdToAck;

  static AckContent fromJson(Map json) {
    return AckContent(
      messageIdToAck: json['messageIdToAck'] as int?,
      retransIdToAck: json['retransIdToAck'] as int,
    );
  }

  @override
  Map toJson() {
    return {
      'messageIdToAck': messageIdToAck,
      'retransIdToAck': retransIdToAck,
    };
  }
}

class ProfileContent extends MessageContent {
  ProfileContent({required this.avatarSvg, required this.displayName});
  String avatarSvg;
  String displayName;

  static ProfileContent fromJson(Map json) {
    return ProfileContent(
      avatarSvg: json['avatarSvg'] as String,
      displayName: json['displayName'] as String,
    );
  }

  @override
  Map toJson() {
    return {'avatarSvg': avatarSvg, 'displayName': displayName};
  }
}

class PushKeyContent extends MessageContent {
  PushKeyContent({required this.keyId, required this.key});
  int keyId;
  List<int> key;

  static PushKeyContent fromJson(Map json) {
    return PushKeyContent(
      keyId: json['keyId'] as int,
      key: List<int>.from(json['key'] as List),
    );
  }

  @override
  Map toJson() {
    return {
      'keyId': keyId,
      'key': key,
    };
  }
}

class FlameSyncContent extends MessageContent {
  FlameSyncContent(
      {required this.flameCounter,
      required this.bestFriend,
      required this.lastFlameCounterChange});
  int flameCounter;
  DateTime lastFlameCounterChange;
  bool bestFriend;

  static FlameSyncContent fromJson(Map json) {
    return FlameSyncContent(
      flameCounter: json['flameCounter'] as int,
      bestFriend: json['bestFriend'] as bool,
      lastFlameCounterChange: DateTime.fromMillisecondsSinceEpoch(
          json['lastFlameCounterChange'] as int),
    );
  }

  @override
  Map toJson() {
    return {
      'flameCounter': flameCounter,
      'bestFriend': bestFriend,
      'lastFlameCounterChange':
          lastFlameCounterChange.toUtc().millisecondsSinceEpoch,
    };
  }
}
