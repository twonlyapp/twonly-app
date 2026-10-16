/*
 * Modified version of https://github.com/Fintasys/emoji_picker_flutter
 * MIT License
 * Copyright (c) 2024 Stefan Humm
 */

/// Alternative skin tones of Emoji
class SkinTone {
  SkinTone._();

  /// Light Skin Tone
  static const String light = '🏻';

  /// Medium-Light Skin Tone
  static const String mediumLight = '🏼';

  /// Medium Skin Tone
  static const String medium = '🏽';

  /// Medium-Dark Skin Tone
  static const String mediumDark = '🏾';

  /// Dark Skin Tone
  static const String dark = '🏿';

  /// Return all values as Array
  static const List<String> values = [
    light,
    mediumLight,
    medium,
    mediumDark,
    dark,
  ];
}
