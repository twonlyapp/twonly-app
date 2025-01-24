import 'package:json_annotation/json_annotation.dart';
import 'package:fixnum/fixnum.dart';
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
  final Int64 fromUserId;
  final MessageKind kind;
  final MessageContent? content;
  DateTime timestamp;

  Message(
      {required this.fromUserId,
      required this.kind,
      this.content,
      required this.timestamp});

  @override
  String toString() {
    return 'Message(kind: $kind, content: $content, timestamp: $timestamp)';
  }

  Message fromJson(Map<String, dynamic> json) {
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
      fromUserId: const Int64Converter().fromJson(json['fromUserId'] as String),
      kind: kind,
      timestamp: DateTime.parse(json['timestamp'] as String),
      content: content,
    );
  }

  Map<String, dynamic> toJson(Message instance) {
    var json = <String, dynamic>{
      'fromUserId': const Int64Converter().toJson(instance.fromUserId),
      'kind': _$MessageKindEnumMap[instance.kind]!,
      'timestamp': instance.timestamp.toIso8601String(),
      'content': instance.content
    };

    return json;
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
