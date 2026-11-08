import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:twonly/core/bridge/database/stickers.dart' as rust_stickers;
import 'package:twonly/locator.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/emoji_picker/emoji_picker.dart';
import 'package:twonly/src/visual/components/sticker_picker.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor_components/layer_data.dart';

class EmojiPickerBottom extends StatefulWidget {
  const EmojiPickerBottom({
    this.allowStickers = false,
    super.key,
  });

  final bool allowStickers;

  @override
  State<EmojiPickerBottom> createState() => _EmojiPickerBottomState();
}

class _EmojiPickerBottomState extends State<EmojiPickerBottom> {
  bool _showStickers = false;

  static const double _defaultHeight = 480;
  static const double _minHeight = 320;

  /// Null until the drag line was used; then the height the user chose.
  double? _height;
  bool _dragging = false;

  /// Up to just below the status bar. The sheet has to be opened with
  /// `isScrollControlled: true` to grow past 9/16 of the screen.
  double _maxHeight(BuildContext context) {
    final media = MediaQuery.of(context);
    return math.max(_minHeight, media.size.height - media.padding.top - 24);
  }

  double _currentHeight(BuildContext context) {
    final max = _maxHeight(context);
    return (_height ?? math.min(_defaultHeight, max)).clamp(_minHeight, max);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final max = _maxHeight(context);
    setState(() {
      _dragging = true;
      _height = (_currentHeight(context) - details.delta.dy).clamp(
        _minHeight,
        max,
      );
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final speed = details.velocity.pixelsPerSecond.dy;
    final height = _currentHeight(context);
    setState(() => _dragging = false);
    if (speed < -700) {
      // Flicked up: all the way open.
      setState(() => _height = _maxHeight(context));
    } else if (speed > 700) {
      if (height > _defaultHeight + 1) {
        // Flicked down from a taller sheet: back to the usual height.
        setState(() => _height = _defaultHeight);
      } else {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: AnimatedContainer(
        duration: _dragging ? Duration.zero : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.zero,
        height: _currentHeight(context),
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
          color: context.color.surfaceContainer,
          boxShadow: [
            BoxShadow(
              blurRadius: 10.9,
              color: context.color.surfaceContainer.withAlpha(25),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            children: [
              // The drag line resizes the sheet; the hit area spans the
              // whole width so it is easy to grab.
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragUpdate: _onDragUpdate,
                onVerticalDragEnd: _onDragEnd,
                child: SizedBox(
                  width: double.infinity,
                  height: 23,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        color: context.color.outline,
                      ),
                      height: 3,
                      width: 60,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: EmojiPicker(
                  alternateView: _showStickers
                      ? StickerPicker(
                          selectCreatedSticker: true,
                          onEmojiPressed: () {
                            setState(() => _showStickers = false);
                          },
                          onStickerSelected: (sticker) {
                            unawaitedRustCall(
                              rust_stickers.recordStickerUse(
                                hash: sticker.contentHash,
                                transaction: currentDatabaseSession(),
                              ),
                              'recordStickerUse',
                            );
                            Navigator.pop(
                              context,
                              StickerLayerData(
                                key: GlobalKey(),
                                webp: sticker.webp,
                                contentHash: sticker.contentHash,
                                width: sticker.width,
                                height: sticker.height,
                              ),
                            );
                          },
                        )
                      : null,
                  onEmojiSelected: (category, emoji) {
                    Navigator.pop(
                      context,
                      EmojiLayerData(
                        key: GlobalKey(),
                        text: emoji.emoji,
                      ),
                    );
                  },
                  // textEditingController: _textFieldController,
                  config: Config(
                    height: 400,
                    locale: Localizations.localeOf(context),
                    checkPlatformCompatibility: false,
                    resizeConfig: const ResizeConfig(
                      showDragHandle: false,
                    ),
                    emojiTextStyle: TextStyle(
                      fontSize: 24 * (Platform.isIOS ? 1.2 : 1),
                      fontFamilyFallback: Platform.isAndroid
                          ? const ['NotoColorEmoji']
                          : null,
                    ),
                    emojiViewConfig: EmojiViewConfig(
                      backgroundColor: context.color.surfaceContainer,
                      recentsLimit: 40,
                    ),
                    searchViewConfig: SearchViewConfig(
                      backgroundColor: context.color.surfaceContainer,
                      buttonIconColor: context.color.onSurface,
                    ),
                    categoryViewConfig: CategoryViewConfig(
                      backgroundColor: context.color.surfaceContainer,
                      dividerColor: context.color.surfaceContainerHigh,
                      indicatorColor: context.color.primary,
                      iconColorSelected: context.color.primary,
                      iconColor: context.color.secondary,
                    ),
                    bottomActionBarConfig: BottomActionBarConfig(
                      backgroundColor: context.color.surfaceContainer,
                      buttonColor: context.color.surfaceContainer,
                      buttonIconColor: context.color.secondary,
                      stickerButtonLabel: context.lang.sticker,
                      showStickerButton: widget.allowStickers,
                      onStickerButtonPressed: widget.allowStickers
                          ? () => setState(() => _showStickers = true)
                          : null,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
