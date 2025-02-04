import 'package:flutter/material.dart';

enum MessageKind {
  textMessage,
  image,
  video,
  contactRequest,
  rejectRequest,
  acceptRequest,
  opened,
  ack
}

extension MessageKindExtension on MessageKind {
  String get name => toString().split('.').last;

  static MessageKind fromString(String name) {
    return MessageKind.values.firstWhere((e) => e.name == name);
  }

  int get index => this.index;

  static MessageKind fromIndex(int index) {
    return MessageKind.values[index];
  }

  Color getColor(Color primary) {
    Color color = primary;
    if (this == MessageKind.textMessage) {
      color = Colors.lightBlue;
    } else if (this == MessageKind.video) {
      color = Colors.deepPurple;
    }
    return color;
  }
}

// TODO: use message as base class, remove kind and flatten content
class Message {
  final MessageKind kind;
  final MessageContent content;
  final int? messageId;
  DateTime timestamp;

  Message(
      {required this.kind,
      this.messageId,
      required this.content,
      required this.timestamp});

  @override
  String toString() {
    return 'Message(kind: $kind, content: $content, timestamp: $timestamp)';
  }

  static Message fromJson(Map<String, dynamic> json) => Message(
        kind: MessageKindExtension.fromString(json["kind"]),
        messageId: (json['messageId'] as num?)?.toInt(),
        content:
            MessageContent.fromJson(json['content'] as Map<String, dynamic>),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'kind': kind.name,
        'content': content.toJson(),
        'messageId': messageId,
        'timestamp': timestamp.toIso8601String(),
      };
}

class MessageContent {
  MessageContent();

  static MessageContent fromJson(Map json) {
    switch (json['type']) {
      case 'MediaMessageContent':
        return MediaMessageContent.fromJson(json);
      case 'TextMessageContent':
        return TextMessageContent.fromJson(json);
      default:
        return MessageContent();
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
  MediaMessageContent({
    required this.downloadToken,
    required this.maxShowTime,
    required this.isRealTwonly,
  });

  static MediaMessageContent fromJson(Map json) {
    return MediaMessageContent(
      downloadToken: List<int>.from(json['downloadToken']),
      maxShowTime: json['maxShowTime'],
      isRealTwonly: json['isRealTwonly'],
    );
  }

  @override
  Map toJson() {
    return {
      'type': 'MediaMessageContent',
      'downloadToken': downloadToken,
      'isRealTwonly': isRealTwonly,
      'maxShowTime': maxShowTime,
    };
  }
}

class TextMessageContent extends MessageContent {
  final String text;
  TextMessageContent({required this.text});

  static TextMessageContent fromJson(Map json) {
    return TextMessageContent(
      text: json['text'],
    );
  }

  @override
  Map toJson() {
    return {
      'type': 'TextMessageContent',
      'text': text,
    };
  }
}
