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
  MessageKind.acceptRequest: 'acceptRequest',
  MessageKind.ack: 'ack',
};

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      kind: $enumDecode(_$MessageKindEnumMap, json['kind']),
      messageId: (json['messageId'] as num?)?.toInt(),
      content: json['content'] == null
          ? null
          : MessageContent.fromJson(json['content'] as Map<String, dynamic>),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'kind': _$MessageKindEnumMap[instance.kind]!,
      'content': instance.content,
      'messageId': instance.messageId,
      'timestamp': instance.timestamp.toIso8601String(),
    };

MessageContent _$MessageContentFromJson(Map<String, dynamic> json) =>
    MessageContent(
      text: json['text'] as String?,
      downloadToken: (json['downloadToken'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
    );

Map<String, dynamic> _$MessageContentToJson(MessageContent instance) =>
    <String, dynamic>{
      'text': instance.text,
      'downloadToken': instance.downloadToken,
    };
