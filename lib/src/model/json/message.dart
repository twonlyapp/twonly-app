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

Color getMessageColorFromType(MessageContent content, Color primary) {
  Color color;

  if (content is TextMessageContent) {
    color = Colors.lightBlue;
  } else {
    if (content is MediaMessageContent) {
      if (content.isRealTwonly) {
        color = primary;
      } else {
        if (content.isVideo) {
          color = Colors.deepPurple;
        } else {
          color = const Color.fromARGB(255, 214, 47, 47);
        }
      }
    } else {
      return Colors.black; // this should not happen
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
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'kind': kind.name,
        'content': content?.toJson(),
        'messageId': messageId,
        'timestamp': timestamp.toIso8601String(),
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
  final List<int> downloadToken;
  final int maxShowTime;
  final bool isRealTwonly;
  final bool isVideo;
  MediaMessageContent({
    required this.downloadToken,
    required this.maxShowTime,
    required this.isRealTwonly,
    required this.isVideo,
  });

  static MediaMessageContent fromJson(Map json) {
    return MediaMessageContent(
      downloadToken: List<int>.from(json['downloadToken']),
      maxShowTime: json['maxShowTime'],
      isRealTwonly: json['isRealTwonly'],
      isVideo: json['isVideo'] ?? false,
    );
  }

  @override
  Map toJson() {
    return {
      'downloadToken': downloadToken,
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
