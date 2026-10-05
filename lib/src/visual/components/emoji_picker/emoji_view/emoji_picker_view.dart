/*
 * Modified version of https://github.com/Fintasys/emoji_picker_flutter
 * MIT License
 * Copyright (c) 2024 Stefan Humm
 */

import 'package:flutter/material.dart';
import 'package:twonly/src/visual/components/emoji_picker/emoji_picker.dart';

/// Template class for custom implementation
/// Inhert this class to create your own EmojiPicker
abstract class EmojiPickerView extends StatefulWidget {
  /// Constructor
  const EmojiPickerView(
    this.config,
    this.state,
    this.showSearchBar, {
    super.key,
  });

  /// Config for customizations
  final Config config;

  /// State that holds current emoji data
  final EmojiViewState state;

  /// Show Search Bar
  final VoidCallback showSearchBar;
}

/// A wrapper that provides the requested emoji-cell button behavior.
class EmojiContainer extends StatelessWidget {
  /// Constructor.
  const EmojiContainer({
    required this.color,
    required this.buttonMode,
    required this.child,
    super.key,
    this.padding,
  });

  final Color color;
  final ButtonMode buttonMode;
  final EdgeInsets? padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (buttonMode == ButtonMode.MATERIAL) {
      return Material(
        color: color,
        child: padding == null
            ? child
            : Padding(padding: padding!, child: child),
      );
    }
    return Container(color: color, padding: padding, child: child);
  }
}

/// State shared by the picker views.
class EmojiViewState {
  /// Constructor.
  EmojiViewState(
    this.categoryEmoji,
    this.onEmojiSelected,
    this.onBackspacePressed,
    this.onBackspaceLongPressed,
    this.onShowSearchView,
    this.onCategoryChanged, {
    this.currentCategory,
  });

  final List<CategoryEmoji> categoryEmoji;
  final OnEmojiSelected onEmojiSelected;
  final OnBackspacePressed? onBackspacePressed;
  final OnBackspaceLongPressed onBackspaceLongPressed;
  final VoidCallback onShowSearchView;
  final OnCategoryChanged? onCategoryChanged;
  final Category? currentCategory;

  /// Notifies the tab bar about programmatic category changes.
  final ValueNotifier<Category?> categoryNavigationNotifier =
      ValueNotifier<Category?>(null);
}
