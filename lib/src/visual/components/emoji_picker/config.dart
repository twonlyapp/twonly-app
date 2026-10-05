// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes, prefer_asserts_with_message

/*
 * Modified version of https://github.com/Fintasys/emoji_picker_flutter
 * MIT License
 * Copyright (c) 2024 Stefan Humm
 */

import 'package:flutter/material.dart';
import 'package:twonly/src/visual/components/emoji_picker/emoji_picker.dart';
import 'package:twonly/src/visual/components/emoji_picker/locales/default_emoji_set_locale.dart';

/// Number of skin tone icons
const kSkinToneCount = 6;

/// Config for customizations
class Config {
  /// Constructor
  const Config({
    this.height = 256,
    this.checkPlatformCompatibility = true,
    this.emojiSet = getDefaultEmojiLocale,
    this.locale = const Locale('en'),
    this.emojiTextStyle,
    this.customBackspaceIcon,
    this.customSearchIcon,
    this.viewOrderConfig = const ViewOrderConfig(),
    this.emojiViewConfig = const EmojiViewConfig(),
    this.skinToneConfig = const SkinToneConfig(),
    this.categoryViewConfig = const CategoryViewConfig(),
    this.bottomActionBarConfig = const BottomActionBarConfig(),
    this.searchViewConfig = const SearchViewConfig(),
    this.resizeConfig = const ResizeConfig(),
  });

  /// Initial height of the emoji view
  /// If explicitly set to null, the emoji view will not be constrained by
  /// height
  final double? height;

  /// Verify that emoji glyph is supported by the platform (Android only)
  final bool checkPlatformCompatibility;

  /// Useful to provide a customized list of Emoji or add/remove the support
  /// for specific locales (create similar method as in
  /// default_emoji_set_locale.dart).
  /// If not provided, the default emoji set will be used based on the
  /// locales that are available in the package.
  final List<CategoryEmoji> Function(Locale locale)? emojiSet;

  /// Locale to choose the fitting language for the emoji set
  /// This will affect the emoji search results
  final Locale locale;

  /// Custom emoji text style to apply to emoji characters in the grid
  ///
  /// If you define a custom fontFamily or use GoogleFonts to set this property
  /// you can consider to set [checkPlatformCompatibility] to false. It will
  /// improve initalization performance and prevent technically supported glyphs
  /// from being filtered out.
  ///
  /// This has priority over [EmojiViewConfig.emojiSizeMax] if font size is set.
  final TextStyle? emojiTextStyle;

  ///  Custom backspace icon
  final Icon? customBackspaceIcon;

  /// Custom search icon
  final Icon? customSearchIcon;

  /// Config the order of the views displayed in the UI
  /// (category bar, emoji view, search bar)
  final ViewOrderConfig viewOrderConfig;

  /// Emoji view config
  final EmojiViewConfig emojiViewConfig;

  /// Skin tone config
  final SkinToneConfig skinToneConfig;

  /// Category view config
  final CategoryViewConfig categoryViewConfig;

  /// Search bar config
  final BottomActionBarConfig bottomActionBarConfig;

  /// Search View config
  final SearchViewConfig searchViewConfig;

  /// Vertical resize behavior and drag handle appearance
  final ResizeConfig resizeConfig;

  @override
  bool operator ==(Object other) {
    return (other is Config) &&
        other.height == height &&
        other.viewOrderConfig == viewOrderConfig &&
        other.checkPlatformCompatibility == checkPlatformCompatibility &&
        other.emojiSet == emojiSet &&
        other.locale == locale &&
        other.emojiTextStyle == emojiTextStyle &&
        other.customBackspaceIcon == customBackspaceIcon &&
        other.customSearchIcon == customSearchIcon &&
        other.categoryViewConfig == categoryViewConfig &&
        other.emojiViewConfig == emojiViewConfig &&
        other.skinToneConfig == skinToneConfig &&
        other.bottomActionBarConfig == bottomActionBarConfig &&
        other.searchViewConfig == searchViewConfig &&
        other.resizeConfig == resizeConfig;
  }

  @override
  int get hashCode =>
      (height?.hashCode ?? 0) ^
      viewOrderConfig.hashCode ^
      checkPlatformCompatibility.hashCode ^
      emojiSet.hashCode ^
      locale.hashCode ^
      (emojiTextStyle?.hashCode ?? 0) ^
      customBackspaceIcon.hashCode ^
      customSearchIcon.hashCode ^
      categoryViewConfig.hashCode ^
      emojiViewConfig.hashCode ^
      skinToneConfig.hashCode ^
      bottomActionBarConfig.hashCode ^
      searchViewConfig.hashCode ^
      resizeConfig.hashCode;
}

/// Controls the order of the picker sections.
class ViewOrderConfig {
  /// Constructor.
  const ViewOrderConfig({
    this.top = EmojiPickerItem.searchBar,
    this.middle = EmojiPickerItem.emojiView,
    this.bottom = EmojiPickerItem.categoryBar,
  }) : assert(
         !identical(top, middle) &&
             !identical(top, bottom) &&
             !identical(middle, bottom),
       );

  final EmojiPickerItem top;
  final EmojiPickerItem middle;
  final EmojiPickerItem bottom;

  @override
  bool operator ==(Object other) {
    return other is ViewOrderConfig &&
        other.top == top &&
        other.middle == middle &&
        other.bottom == bottom;
  }

  @override
  int get hashCode => Object.hash(top, middle, bottom);
}

/// Sections shown in the emoji picker.
enum EmojiPickerItem {
  categoryBar,
  emojiView,
  searchBar,
}

/// Configuration for resizing the emoji picker vertically.
class ResizeConfig {
  /// Constructor.
  const ResizeConfig({
    this.enabled = true,
    this.showDragHandle = true,
    this.maxHeight,
    this.maxHeightFactor = 0.85,
    this.handleColor,
    this.handleWidth = 60,
    this.handleHeight = 3,
    this.handleHitAreaHeight = 23,
    this.handleBorderRadius = 32,
    this.topBorderRadius = 18,
  }) : assert(maxHeightFactor > 0 && maxHeightFactor <= 1),
       assert(handleWidth > 0),
       assert(handleHeight > 0),
       assert(handleHitAreaHeight >= handleHeight),
       assert(handleBorderRadius >= 0),
       assert(topBorderRadius >= 0);

  final bool enabled;

  /// Whether the drag indicator and its resize gesture are shown.
  final bool showDragHandle;

  final double? maxHeight;
  final double maxHeightFactor;

  /// Defaults to the current theme's outline color.
  final Color? handleColor;

  final double handleWidth;
  final double handleHeight;
  final double handleHitAreaHeight;
  final double handleBorderRadius;
  final double topBorderRadius;

  @override
  bool operator ==(Object other) {
    return other is ResizeConfig &&
        other.enabled == enabled &&
        other.showDragHandle == showDragHandle &&
        other.maxHeight == maxHeight &&
        other.maxHeightFactor == maxHeightFactor &&
        other.handleColor == handleColor &&
        other.handleWidth == handleWidth &&
        other.handleHeight == handleHeight &&
        other.handleHitAreaHeight == handleHitAreaHeight &&
        other.handleBorderRadius == handleBorderRadius &&
        other.topBorderRadius == topBorderRadius;
  }

  @override
  int get hashCode => Object.hash(
    enabled,
    showDragHandle,
    maxHeight,
    maxHeightFactor,
    handleColor,
    handleWidth,
    handleHeight,
    handleHitAreaHeight,
    handleBorderRadius,
    topBorderRadius,
  );
}
