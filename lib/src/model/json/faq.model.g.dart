// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'faq.model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FaqData _$FaqDataFromJson(Map<String, dynamic> json) => FaqData(
  languages: (json['languages'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(
      k,
      (e as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, FaqCategory.fromJson(e as Map<String, dynamic>)),
      ),
    ),
  ),
);

Map<String, dynamic> _$FaqDataToJson(FaqData instance) => <String, dynamic>{
  'languages': instance.languages,
};

FaqCategory _$FaqCategoryFromJson(Map<String, dynamic> json) => FaqCategory(
  meta: FaqMeta.fromJson(json['meta'] as Map<String, dynamic>),
  questions: (json['questions'] as List<dynamic>)
      .map((e) => FaqQuestion.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$FaqCategoryToJson(FaqCategory instance) =>
    <String, dynamic>{'meta': instance.meta, 'questions': instance.questions};

FaqMeta _$FaqMetaFromJson(Map<String, dynamic> json) => FaqMeta(
  title: json['title'] as String,
  desc: json['desc'] as String,
  priority: (json['priority'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$FaqMetaToJson(FaqMeta instance) => <String, dynamic>{
  'title': instance.title,
  'desc': instance.desc,
  'priority': instance.priority,
};

FaqQuestion _$FaqQuestionFromJson(Map<String, dynamic> json) => FaqQuestion(
  id: json['id'] as String,
  title: json['title'] as String,
  body: json['body'] as String,
  path: json['path'] as String,
);

Map<String, dynamic> _$FaqQuestionToJson(FaqQuestion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'body': instance.body,
      'path': instance.path,
    };
