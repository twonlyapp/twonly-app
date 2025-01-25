// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MessageKind _$MessageKindFromJson(Map<String, dynamic> json) => _MessageKind()
  ..kind = $enumDecodeNullable(_$MessageKindEnumMap, json['kind']);

Map<String, dynamic> _$MessageKindToJson(_MessageKind instance) =>
    <String, dynamic>{
      'kind': _$MessageKindEnumMap[instance.kind],
    };

const _$MessageKindEnumMap = {
  MessageKind.textMessage: 'textMessage',
  MessageKind.image: 'image',
  MessageKind.video: 'video',
  MessageKind.contactRequest: 'contactRequest',
  MessageKind.rejectRequest: 'rejectRequest',
};

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      kind: $enumDecode(_$MessageKindEnumMap, json['kind']),
      content: json['content'] == null
          ? null
          : MessageContent.fromJson(json['content'] as Map<String, dynamic>),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'kind': _$MessageKindEnumMap[instance.kind]!,
      'content': instance.content,
      'timestamp': instance.timestamp.toIso8601String(),
    };

TextContent _$TextContentFromJson(Map<String, dynamic> json) => TextContent(
      json['text'] as String,
    );

Map<String, dynamic> _$TextContentToJson(TextContent instance) =>
    <String, dynamic>{
      'text': instance.text,
    };

ImageContent _$ImageContentFromJson(Map<String, dynamic> json) => ImageContent(
      json['imageUrl'] as String,
    );

Map<String, dynamic> _$ImageContentToJson(ImageContent instance) =>
    <String, dynamic>{
      'imageUrl': instance.imageUrl,
    };
