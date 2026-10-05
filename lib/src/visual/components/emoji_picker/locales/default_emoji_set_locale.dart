/*
 * Modified version of https://github.com/Fintasys/emoji_picker_flutter
 * MIT License
 * Copyright (c) 2024 Stefan Humm
 */

import 'package:flutter/material.dart';
import 'package:twonly/src/visual/components/emoji_picker/emoji_picker.dart';

/// Default method for locale selection
List<CategoryEmoji> getDefaultEmojiLocale(Locale locale) {
  switch (locale.languageCode) {
    case 'de':
      return emojiSetGerman;
    case 'en':
      return emojiSetEnglish;
    case 'es':
      return emojiSetSpanish;
    case 'fr':
      return emojiSetFrance;
    case 'hi':
      return emojiSetHindi;
    case 'it':
      return emojiSetItalian;
    case 'ja':
      return emojiSetJapanese;
    case 'nl':
      return emojiSetDutch;
    case 'pt':
      return emojiSetPortuguese;
    case 'ru':
      return emojiSetRussian;
    case 'zh':
      return emojiSetChinese;
    default:
      return emojiSetEnglish;
  }
}
