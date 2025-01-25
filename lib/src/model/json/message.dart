import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';
import 'package:twonly/src/utils/json.dart';
part 'message.g.dart';

enum MessageKind { textMessage, image, video, contactRequest }

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
  DateTime timestamp;

  Message({required this.kind, this.content, required this.timestamp});

  @override
  String toString() {
    return 'Message(kind: $kind, content: $content, timestamp: $timestamp)';
  }

  static Message fromJson(String jsonString) {
    Map<String, dynamic> json = jsonDecode(jsonString);
    dynamic content;
    MessageKind kind = $enumDecode(_$MessageKindEnumMap, json['kind']);
    switch (kind) {
      case MessageKind.textMessage:
        content = TextContent.fromJson(json["content"]);
        break;
      case MessageKind.image:
        content = ImageContent.fromJson(json["content"]);
        break;
      default:
    }

    return Message(
      kind: kind,
      timestamp: DateTime.parse(json['timestamp'] as String),
      content: content,
    );
  }

  String toJson() {
    var json = <String, dynamic>{
      'kind': _$MessageKindEnumMap[kind]!,
      'timestamp': timestamp.toIso8601String(),
      'content': content
    };
    return jsonEncode(json);
  }
}

abstract class MessageContent {
  MessageContent();
  factory MessageContent.fromJson(Map<String, dynamic> json) {
    return TextContent("");
  }

  Map<String, dynamic> toJson();
}
// factory MessageContent.fromJson(Map<String, dynamic> json) =>
//     _$MessageContentFromJson(json);

@JsonSerializable()
class TextContent extends MessageContent {
  final String text;

  TextContent(this.text);

  factory TextContent.fromJson(Map<String, dynamic> json) =>
      _$TextContentFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$TextContentToJson(this);
}

@JsonSerializable()
class ImageContent extends MessageContent {
  final String imageUrl;

  ImageContent(this.imageUrl);

  factory ImageContent.fromJson(Map<String, dynamic> json) =>
      _$ImageContentFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$ImageContentToJson(this);
}

// @JsonSerializable()
// class VideoContent extends MessageContent {
//   final String videoUrl;

//   VideoContent(this.videoUrl);
// }
