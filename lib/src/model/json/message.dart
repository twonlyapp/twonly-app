import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:twonly/src/utils/json.dart';
part 'message.g.dart';

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

// so _$MessageKindEnumMap gets generated
@JsonSerializable()
class _MessageKind {
  MessageKind? kind;
}

@JsonSerializable()
class Message {
  @Int64Converter()
  final MessageKind kind;
  final MessageContent? content;
  final int? messageId;
  DateTime timestamp;

  Message(
      {required this.kind,
      this.messageId,
      this.content,
      required this.timestamp});

  @override
  String toString() {
    return 'Message(kind: $kind, content: $content, timestamp: $timestamp)';
  }

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);
}

@JsonSerializable()
class MessageContent {
  final String? text;
  final List<int>? downloadToken;

  MessageContent({required this.text, required this.downloadToken});

  factory MessageContent.fromJson(Map<String, dynamic> json) =>
      _$MessageContentFromJson(json);
  Map<String, dynamic> toJson() => _$MessageContentToJson(this);
}
