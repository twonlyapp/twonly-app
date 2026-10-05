/*
 * Modified version of https://github.com/Fintasys/emoji_picker_flutter
 * MIT License
 * Copyright (c) 2024 Stefan Humm
 */

import 'package:flutter/material.dart';
import 'package:twonly/src/visual/components/emoji_picker/emoji_picker.dart';

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
@immutable
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
  bool operator ==(Object other) {
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
    final actionBarConfig = widget.config.bottomActionBarConfig;
    return PickerBottomBar(
      backgroundColor: actionBarConfig.backgroundColor,
      buttonIconColor: actionBarConfig.buttonIconColor,
      selectedTabColor: actionBarConfig.selectedTabColor,
      emojiButtonLabel: actionBarConfig.emojiButtonLabel,
      stickerButtonLabel: actionBarConfig.stickerButtonLabel,
      showStickerButton: actionBarConfig.showStickerButton,
      onStickerButtonPressed: actionBarConfig.onStickerButtonPressed,
      leading: _buildSearchViewButton(),
      trailing: _buildBackspaceButton(),
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

/// Shared shell for emoji and sticker mode. Reserving the same 48 logical
/// pixels on both sides keeps the tabs perfectly stationary while switching.
class PickerBottomBar extends StatelessWidget {
  const PickerBottomBar({
    required this.backgroundColor,
    required this.buttonIconColor,
    required this.emojiButtonLabel,
    required this.stickerButtonLabel,
    required this.showStickerButton,
    this.selectedTabColor,
    this.stickerSelected = false,
    this.onEmojiButtonPressed,
    this.onStickerButtonPressed,
    this.leading,
    this.trailing,
    super.key,
  });

  final Color? backgroundColor;
  final Color buttonIconColor;
  final Color? selectedTabColor;
  final String emojiButtonLabel;
  final String stickerButtonLabel;
  final bool showStickerButton;
  final bool stickerSelected;
  final VoidCallback? onEmojiButtonPressed;
  final VoidCallback? onStickerButtonPressed;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor ?? Colors.transparent,
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            SizedBox(width: 48, child: leading),
            Expanded(
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PickerTab(
                        label: emojiButtonLabel,
                        selected: !stickerSelected,
                        foreground: buttonIconColor,
                        selectedColor: selectedTabColor,
                        onTap: onEmojiButtonPressed,
                      ),
                      if (showStickerButton) ...[
                        const SizedBox(width: 4),
                        _PickerTab(
                          label: stickerButtonLabel,
                          selected: stickerSelected,
                          foreground: buttonIconColor,
                          selectedColor: selectedTabColor,
                          onTap: onStickerButtonPressed,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 48, child: trailing),
          ],
        ),
      ),
    );
  }
}

class _PickerTab extends StatelessWidget {
  const _PickerTab({
    required this.label,
    required this.selected,
    required this.foreground,
    this.selectedColor,
    this.onTap,
  });

  final String label;
  final bool selected;
  final Color foreground;
  final Color? selectedColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? selectedColor ?? foreground.withValues(alpha: 0.14)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: foreground,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
