import 'package:flutter/material.dart';

enum MessageKind {
  textMessage,
  media,
  contactRequest,
  rejectRequest,
  acceptRequest,
  opened,
  ack
}

Map<String, Color> messageKindColors = {
  "video": Colors.deepPurple,
  "text": Colors.lightBlue,
  "image": Color.fromARGB(255, 214, 47, 47),
};

Color getMessageColorFromType(MessageContent content, Color primary) {
  Color color;

  if (content is TextMessageContent) {
    color = messageKindColors["text"]!;
  } else {
    if (content is MediaMessageContent) {
      if (content.isRealTwonly) {
        color = primary;
      } else {
        if (content.isVideo) {
          color = messageKindColors["video"]!;
        } else {
          color = messageKindColors["image"]!;
        }
      }
    } else {
      return Colors.black;
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
  final int? messageId;
  DateTime timestamp;

  MessageJson(
      {required this.kind,
      this.messageId,
      required this.content,
      required this.timestamp});

  @override
  String toString() {
    return 'Message(kind: $kind, content: $content, timestamp: $timestamp)';
  }

  static MessageJson fromJson(Map<String, dynamic> json) {
    final kind = MessageKindExtension.fromString(json["kind"]);

    return MessageJson(
      kind: kind,
      messageId: (json['messageId'] as num?)?.toInt(),
      content: MessageContent.fromJson(
          kind, json['content'] as Map<String, dynamic>),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'kind': kind.name,
        'content': content?.toJson(),
        'messageId': messageId,
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
  final List<int>? downloadToken;
  final List<int>? encryptionKey;
  final List<int>? encryptionMac;
  final List<int>? encryptionNonce;

  MediaMessageContent({
    required this.maxShowTime,
    required this.isRealTwonly,
    required this.isVideo,
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
    };
  }
}

class TextMessageContent extends MessageContent {
  String text;
  TextMessageContent({required this.text});

  static TextMessageContent fromJson(Map json) {
    return TextMessageContent(
      text: json['text'],
    );
  }

  @override
  Map toJson() {
    return {
      'text': text,
    };
  }
}
