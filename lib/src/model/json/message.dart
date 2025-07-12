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
  final MessageKind kind;
  final MessageContent? content;
  final int? messageReceiverId;
  final int? messageSenderId;
  int? retransId;
  DateTime timestamp;

  MessageJson({
    required this.kind,
    this.messageReceiverId,
    this.messageSenderId,
    this.retransId,
    required this.content,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'Message(kind: $kind, content: $content, timestamp: $timestamp)';
  }

  static MessageJson fromJson(Map<String, dynamic> json) {
    final kind = MessageKindExtension.fromString(json["kind"]);

    return MessageJson(
      kind: kind,
      messageReceiverId: (json['messageReceiverId'] as num?)?.toInt(),
      messageSenderId: (json['messageSenderId'] as num?)?.toInt(),
      retransId: (json['retransId'] as num?)?.toInt(),
      content: MessageContent.fromJson(
          kind, json['content'] as Map<String, dynamic>),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
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
      default:
        return null;
    }
  }

  Map toJson() {
    return {};
  }
}

class MediaMessageContent extends MessageContent {
  final int maxShowTime;
  final bool isRealTwonly;
  final bool isVideo;
  final bool mirrorVideo;
  final List<int>? downloadToken;
  final List<int>? encryptionKey;
  final List<int>? encryptionMac;
  final List<int>? encryptionNonce;

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

  static MediaMessageContent fromJson(Map json) {
    return MediaMessageContent(
      downloadToken: json['downloadToken'] == null
          ? null
          : List<int>.from(json['downloadToken']),
      encryptionKey: json['encryptionKey'] == null
          ? null
          : List<int>.from(json['encryptionKey']),
      encryptionMac: json['encryptionMac'] == null
          ? null
          : List<int>.from(json['encryptionMac']),
      encryptionNonce: json['encryptionNonce'] == null
          ? null
          : List<int>.from(json['encryptionNonce']),
      maxShowTime: json['maxShowTime'],
      isRealTwonly: json['isRealTwonly'],
      isVideo: json['isVideo'] ?? false,
      mirrorVideo: json['mirrorVideo'] ?? false,
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
  String text;
  int? responseToMessageId;
  int? responseToOtherMessageId;
  TextMessageContent({
    required this.text,
    this.responseToMessageId,
    this.responseToOtherMessageId,
  });

  static TextMessageContent fromJson(Map json) {
    return TextMessageContent(
        text: json['text'],
        responseToOtherMessageId: json.containsKey('responseToOtherMessageId')
            ? json['responseToOtherMessageId']
            : null,
        responseToMessageId: json.containsKey('responseToMessageId')
            ? json['responseToMessageId']
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
  int messageId;
  ReopenedMediaFileContent({required this.messageId});

  static ReopenedMediaFileContent fromJson(Map json) {
    return ReopenedMediaFileContent(messageId: json['messageId']);
  }

  @override
  Map toJson() {
    return {'messageId': messageId};
  }
}

class SignalDecryptErrorContent extends MessageContent {
  List<int> encryptedHash;
  SignalDecryptErrorContent({required this.encryptedHash});

  static SignalDecryptErrorContent fromJson(Map json) {
    return SignalDecryptErrorContent(
      encryptedHash: List<int>.from(json['encryptedHash']),
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
  int? messageIdToAck;
  int retransIdToAck;
  AckContent({required this.messageIdToAck, required this.retransIdToAck});

  static AckContent fromJson(Map json) {
    return AckContent(
      messageIdToAck: json['messageIdToAck'],
      retransIdToAck: json['retransIdToAck'],
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
  String avatarSvg;
  String displayName;
  ProfileContent({required this.avatarSvg, required this.displayName});

  static ProfileContent fromJson(Map json) {
    return ProfileContent(
      avatarSvg: json['avatarSvg'],
      displayName: json['displayName'],
    );
  }

  @override
  Map toJson() {
    return {'avatarSvg': avatarSvg, 'displayName': displayName};
  }
}

class PushKeyContent extends MessageContent {
  int keyId;
  List<int> key;
  PushKeyContent({required this.keyId, required this.key});

  static PushKeyContent fromJson(Map json) {
    return PushKeyContent(
      keyId: json['keyId'],
      key: List<int>.from(json['key']),
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
  int flameCounter;
  DateTime lastFlameCounterChange;
  bool bestFriend;

  FlameSyncContent(
      {required this.flameCounter,
      required this.bestFriend,
      required this.lastFlameCounterChange});

  static FlameSyncContent fromJson(Map json) {
    return FlameSyncContent(
      flameCounter: json['flameCounter'],
      bestFriend: json['bestFriend'],
      lastFlameCounterChange:
          DateTime.fromMillisecondsSinceEpoch(json['lastFlameCounterChange']),
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
