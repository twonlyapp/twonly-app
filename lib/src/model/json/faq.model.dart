import 'package:json_annotation/json_annotation.dart';

part 'faq.model.g.dart';

@JsonSerializable()
class FaqData {
  const FaqData({required this.languages});

  factory FaqData.fromJson(Map<String, dynamic> json) {
    return FaqData(
      languages: json.map(
        (key, value) => MapEntry(
          key,
          (value as Map<String, dynamic>).map(
            (catKey, catValue) => MapEntry(
              catKey,
              FaqCategory.fromJson(catValue as Map<String, dynamic>),
            ),
          ),
        ),
      ),
    );
  }

  final Map<String, Map<String, FaqCategory>> languages;

  Map<String, dynamic> toJson() => languages.map(
    (key, value) => MapEntry(
      key,
      value.map((catKey, catValue) => MapEntry(catKey, catValue.toJson())),
    ),
  );
}

@JsonSerializable()
class FaqCategory {
  const FaqCategory({
    required this.meta,
    required this.questions,
  });

  factory FaqCategory.fromJson(Map<String, dynamic> json) =>
      _$FaqCategoryFromJson(json);

  final FaqMeta meta;
  final List<FaqQuestion> questions;

  Map<String, dynamic> toJson() => _$FaqCategoryToJson(this);
}

@JsonSerializable()
class FaqMeta {
  const FaqMeta({
    required this.title,
    required this.desc,
    this.priority = 0,
  });

  factory FaqMeta.fromJson(Map<String, dynamic> json) =>
      _$FaqMetaFromJson(json);

  final String title;
  final String desc;

  @JsonKey(defaultValue: 0)
  final int priority;

  Map<String, dynamic> toJson() => _$FaqMetaToJson(this);
}

@JsonSerializable()
class FaqQuestion {
  const FaqQuestion({
    required this.id,
    required this.title,
    required this.body,
    required this.path,
  });

  factory FaqQuestion.fromJson(Map<String, dynamic> json) =>
      _$FaqQuestionFromJson(json);

  final String id;
  final String title;
  final String body;
  final String path;

  Map<String, dynamic> toJson() => _$FaqQuestionToJson(this);
}
