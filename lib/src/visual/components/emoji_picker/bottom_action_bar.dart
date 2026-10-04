/*
 * Modified version of https://github.com/Fintasys/emoji_picker_flutter
 * MIT License
 * Copyright (c) 2024 Stefan Humm
 */

import 'package:twonly/src/visual/components/emoji_picker/emoji_picker.dart';
import 'package:flutter/material.dart';

/// Template class for custom implementation
abstract class BottomActionBar extends StatefulWidget {
  /// Constructor
  const BottomActionBar(
    this.config,
    this.state,
    this.showSearchView, {
    super.key,
  });

  /// Config for customizations
  final Config config;

  /// State that holds current emoji data
  final EmojiViewState state;

  /// Show Search Bar
  final VoidCallback showSearchView;
}

/// Callback for a custom bottom action bar.
typedef BottomActionBarBuilder =
    Widget Function(
      Config config,
      EmojiViewState state,
      VoidCallback showSearchView,
    );

/// Configuration for the bottom action bar.
class BottomActionBarConfig {
  /// Constructor.
  const BottomActionBarConfig({
    this.enabled = true,
    this.showBackspaceButton = true,
    this.showSearchViewButton = true,
    this.backgroundColor = Colors.blue,
    this.buttonColor = Colors.blue,
    this.buttonIconColor = Colors.white,
    this.showStickerButton = true,
    this.emojiButtonLabel = 'Emoji',
    this.stickerButtonLabel = 'Sticker',
    this.selectedTabColor,
    this.onStickerButtonPressed,
    this.customBottomActionBar,
  });

  final bool enabled;
  final bool showBackspaceButton;
  final bool showSearchViewButton;
  final Color? backgroundColor;
  final Color buttonColor;
  final Color buttonIconColor;
  final bool showStickerButton;
  final String emojiButtonLabel;
  final String stickerButtonLabel;
  final Color? selectedTabColor;
  final VoidCallback? onStickerButtonPressed;

  /// Custom action bar. Hot reload is not supported.
  final BottomActionBarBuilder? customBottomActionBar;

  @override
  bool operator ==(other) {
    return other is BottomActionBarConfig &&
        other.enabled == enabled &&
        other.showBackspaceButton == showBackspaceButton &&
        other.showSearchViewButton == showSearchViewButton &&
        other.backgroundColor == backgroundColor &&
        other.buttonColor == buttonColor &&
        other.buttonIconColor == buttonIconColor &&
        other.showStickerButton == showStickerButton &&
        other.emojiButtonLabel == emojiButtonLabel &&
        other.stickerButtonLabel == stickerButtonLabel &&
        other.selectedTabColor == selectedTabColor &&
        other.onStickerButtonPressed == onStickerButtonPressed &&
        other.customBottomActionBar == customBottomActionBar;
  }

  @override
  int get hashCode => Object.hash(
    enabled,
    showBackspaceButton,
    showSearchViewButton,
    backgroundColor,
    buttonColor,
    buttonIconColor,
    showStickerButton,
    emojiButtonLabel,
    stickerButtonLabel,
    selectedTabColor,
    onStickerButtonPressed,
    customBottomActionBar,
  );
}

/// Default bottom action bar implementation.
class DefaultBottomActionBar extends BottomActionBar {
  /// Constructor.
  const DefaultBottomActionBar(
    super.config,
    super.state,
    super.showSearchView, {
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _DefaultBottomActionBarState();
}

class _DefaultBottomActionBarState extends State<DefaultBottomActionBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.config.bottomActionBarConfig.backgroundColor,
      child: Row(
        children: [
          SizedBox(width: 48, child: _buildSearchViewButton()),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _buildPickerTabs(),
              ),
            ),
          ),
          SizedBox(width: 48, child: _buildBackspaceButton()),
        ],
      ),
    );
  }

  Widget _buildPickerTabs() {
    final actionBarConfig = widget.config.bottomActionBarConfig;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPickerTab(
          label: actionBarConfig.emojiButtonLabel,
          selected: true,
        ),
        if (actionBarConfig.showStickerButton) ...[
          const SizedBox(width: 4),
          _buildPickerTab(
            label: actionBarConfig.stickerButtonLabel,
            onTap: actionBarConfig.onStickerButtonPressed,
          ),
        ],
      ],
    );
  }

  Widget _buildPickerTab({
    required String label,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    final actionBarConfig = widget.config.bottomActionBarConfig;
    final selectedColor =
        actionBarConfig.selectedTabColor ??
        actionBarConfig.buttonIconColor.withValues(alpha: 0.14);
    return Material(
      color: selected ? selectedColor : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              color: actionBarConfig.buttonIconColor,
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchViewButton() {
    if (!widget.config.bottomActionBarConfig.showSearchViewButton) {
      return const SizedBox.shrink();
    }
    return CircleAvatar(
      backgroundColor: widget.config.bottomActionBarConfig.buttonColor,
      child: SearchButton(
        widget.config,
        widget.showSearchView,
        widget.config.bottomActionBarConfig.buttonIconColor,
      ),
    );
  }

  Widget _buildBackspaceButton() {
    if (!widget.config.bottomActionBarConfig.showBackspaceButton) {
      return const SizedBox.shrink();
    }
    return BackspaceButton(
      widget.config,
      widget.state.onBackspacePressed,
      widget.state.onBackspaceLongPressed,
      widget.config.bottomActionBarConfig.buttonIconColor,
    );
  }
}
