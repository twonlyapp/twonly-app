// ignore_for_file: avoid_dynamic_calls, prefer_constructors_over_static_methods

/*
 * Modified version of https://github.com/Fintasys/emoji_picker_flutter
 * MIT License
 * Copyright (c) 2024 Stefan Humm
 */

import 'package:flutter/material.dart';

/// Delimiter for keywords
const _keywordDelimiter = ' | ';

/// A class to store data for each individual emoji
@immutable
class Emoji {
  /// Emoji constructor
  const Emoji(this.emoji, this.name, {this.hasSkinTone = false});

  /// The unicode string for this emoji
  ///
  /// This is the string that should be displayed to view the emoji
  final String emoji;

  /// The name or description for this emoji
  final String name;

  /// Flag if emoji supports multiple skin tones
  final bool hasSkinTone;

  /// List of keywords that describe the emoji
  List<String> get keywords => name.split(_keywordDelimiter);

  @override
  String toString() {
    return 'Emoji: $emoji, Name: $name, HasSkinTone: $hasSkinTone';
  }

  /// Parse Emoji from json
  static Emoji fromJson(Map<String, dynamic> json) {
    return Emoji(
      json['emoji'] as String,
      json['name'] as String,
      hasSkinTone: json['hasSkinTone'] != null && json['hasSkinTone'] as bool,
    );
  }

  ///  Encode Emoji to json
  Map<String, dynamic> toJson() {
    return {'emoji': emoji, 'name': name, 'hasSkinTone': hasSkinTone};
  }

  /// Copy method
  Emoji copyWith({String? name, String? emoji, bool? hasSkinTone}) {
    return Emoji(
      emoji ?? this.emoji,
      name ?? this.name,
      hasSkinTone: hasSkinTone ?? this.hasSkinTone,
    );
  }
}

/// An emoji stored in the recent list together with its use count.
class RecentEmoji {
  /// Constructor.
  RecentEmoji(this.emoji, this.counter);

  final Emoji emoji;
  int counter;

  /// Parses a recent emoji from JSON.
  static RecentEmoji fromJson(dynamic json) {
    return RecentEmoji(
      Emoji.fromJson(json['emoji'] as Map<String, dynamic>),
      json['counter'] as int,
    );
  }

  /// Encodes this recent emoji as JSON.
  Map<String, dynamic> toJson() => {'emoji': emoji, 'counter': counter};
}
