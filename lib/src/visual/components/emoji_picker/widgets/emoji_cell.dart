/*
 * Modified version of https://github.com/Fintasys/emoji_picker_flutter
 * MIT License
 * Copyright (c) 2024 Stefan Humm
 */

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/visual/components/emoji_picker/emoji_picker.dart';

/// A widget that represents an individual clickable emoji cell.
/// Can have a long pressed listener [onSkinToneDialogRequested] that
/// provides necessary data to show a skin tone popup.
class EmojiCell extends StatelessWidget {
  /// Constructor for manually setting all properties
  const EmojiCell({
    required this.emoji,
    required this.emojiSize,
    required this.emojiBoxSize,
    required this.buttonMode,
    required this.enableSkinTones,
    required this.textStyle,
    required this.skinToneIndicatorColor,
    required this.onEmojiSelected,
    super.key,
    this.categoryEmoji,
    this.onSkinToneDialogRequested,
  });

  /// Constructor that can retrieve as much information as possible from
  /// [Config]
  EmojiCell.fromConfig({
    required this.emoji,
    required this.emojiSize,
    required this.emojiBoxSize,
    required this.onEmojiSelected,
    required Config config,
    super.key,
    this.categoryEmoji,
    this.onSkinToneDialogRequested,
  }) : buttonMode = config.emojiViewConfig.buttonMode,
       enableSkinTones = config.skinToneConfig.enabled,
       textStyle = config.emojiTextStyle,
       skinToneIndicatorColor = config.skinToneConfig.indicatorColor;

  /// Emoji to display as the cell content
  final Emoji emoji;

  /// Font size for the emoji
  final double emojiSize;

  /// Hitbox of emoji cell
  final double emojiBoxSize;

  /// Optinonal category that will be passed through to callbacks
  final CategoryEmoji? categoryEmoji;

  /// Visual tap feedback, see [ButtonMode] for options
  final ButtonMode buttonMode;

  /// Whether to show skin popup indicator if emoji supports skin colors
  final bool enableSkinTones;

  /// Custom text style to use on emoji
  final TextStyle? textStyle;

  /// Color for skin color indicator triangle
  final Color skinToneIndicatorColor;

  /// Callback triggered on long press. Will be called regardless
  /// whether [enableSkinTones] is set or not and for any emoji to
  /// give a way for the caller to dismiss any existing overlays.
  final OnSkinToneDialogRequested? onSkinToneDialogRequested;

  /// Callback for a single tap on the cell.
  final OnEmojiSelected onEmojiSelected;

  @override
  Widget build(BuildContext context) {
    void onPressed() {
      onEmojiSelected(categoryEmoji?.category, emoji);
    }

    void onLongPressed() {
      final renderBox = context.findRenderObject()! as RenderBox;
      final emojiBoxPosition = renderBox.localToGlobal(Offset.zero);
      onSkinToneDialogRequested?.call(
        emojiBoxPosition,
        emoji,
        emojiSize,
        categoryEmoji,
      );
    }

    return SizedBox(
      width: emojiBoxSize,
      height: emojiBoxSize,
      child: _buildButtonWidget(
        onPressed: onPressed,
        onLongPressed: onLongPressed,
        child: FittedBox(fit: BoxFit.scaleDown, child: _buildEmoji()),
      ),
    );
  }

  /// Build different Button based on ButtonMode
  Widget _buildButtonWidget({
    required VoidCallback onPressed,
    required Widget child,
    VoidCallback? onLongPressed,
  }) {
    if (buttonMode == ButtonMode.MATERIAL) {
      return MaterialButton(
        onPressed: onPressed,
        onLongPress: onLongPressed,
        elevation: 0,
        highlightElevation: 0,
        padding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(),
        child: child,
      );
    }
    if (buttonMode == ButtonMode.CUPERTINO) {
      return GestureDetector(
        onLongPress: onLongPressed,
        child: CupertinoButton(
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          child: child,
        ),
      );
    }
    return GestureDetector(
      onLongPress: onLongPressed,
      onTap: onPressed,
      child: Center(child: child),
    );
  }

  /// Build and display Emoji centered of its parent
  Widget _buildEmoji() {
    final emojiText = Text(
      emoji.emoji,
      textScaler: TextScaler.noScaling,
      style: _getEmojiTextStyle(),
    );

    return emoji.hasSkinTone &&
            enableSkinTones &&
            onSkinToneDialogRequested != null
        ? Container(
            decoration: TriangleDecoration(
              color: skinToneIndicatorColor,
              size: 8,
            ),
            child: emojiText,
          )
        : emojiText;
  }

  TextStyle _getEmojiTextStyle() {
    final defaultStyle = DefaultEmojiTextStyle.copyWith(
      fontSize: emojiSize,
      inherit: true,
    );
    // textStyle properties have priority over defaultStyle
    return textStyle == null ? defaultStyle : defaultStyle.merge(textStyle);
  }
}
