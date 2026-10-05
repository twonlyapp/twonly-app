import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/stickers/sticker.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/emoji_picker/bottom_action_bar.dart';
import 'package:twonly/src/visual/components/sticker_preview.dialog.dart';
import 'package:twonly/src/visual/loader/three_rotating_dots.loader.dart';

class StickerPicker extends StatefulWidget {
  const StickerPicker({
    required this.onEmojiPressed,
    required this.onStickerSelected,
    this.selectCreatedSticker = false,
    super.key,
  });

  final VoidCallback onEmojiPressed;
  final ValueChanged<LocalSticker> onStickerSelected;
  final bool selectCreatedSticker;

  @override
  State<StickerPicker> createState() => _StickerPickerState();
}

class _StickerPickerState extends State<StickerPicker> {
  late final Stream<List<LocalSticker>> _stickers = twonlyDB.stickersDao
      .watchAll();
  bool _creating = false;

  Future<void> _createSticker() async {
    if (_creating) return;
    setState(() => _creating = true);
    try {
      final sticker = await StickerService.createFromGallery();
      if (!mounted || sticker == null) return;
      if (widget.selectCreatedSticker) widget.onStickerSelected(sticker);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.lang.stickerCreateFailed)),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = context.color;
    return ColoredBox(
      color: color.surfaceContainer,
      child: Column(
        children: [
          PickerBottomBar(
            backgroundColor: color.surfaceContainer,
            buttonIconColor: color.secondary,
            emojiButtonLabel: 'Emoji',
            stickerButtonLabel: context.lang.sticker,
            showStickerButton: true,
            stickerSelected: true,
            onEmojiButtonPressed: widget.onEmojiPressed,
          ),
          Expanded(
            child: StreamBuilder<List<LocalSticker>>(
              stream: _stickers,
              builder: (context, snapshot) {
                if (!snapshot.hasData && !snapshot.hasError) {
                  return const Center(child: ThreeRotatingDots(size: 26));
                }
                final stickers = snapshot.data ?? const <LocalSticker>[];
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 104,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: stickers.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Semantics(
                        button: true,
                        label: context.lang.createSticker,
                        child: Material(
                          color: color.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(16),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: _creating ? null : _createSticker,
                            child: Center(
                              child: _creating
                                  ? const ThreeRotatingDots(size: 26)
                                  : Icon(
                                      Icons.add_photo_alternate_outlined,
                                      color: color.primary,
                                      size: 32,
                                    ),
                            ),
                          ),
                        ),
                      );
                    }
                    final sticker = stickers[index - 1];
                    return Semantics(
                      button: true,
                      label: context.lang.sticker,
                      child: InkWell(
                        key: ValueKey(sticker.contentHash),
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => widget.onStickerSelected(sticker),
                        onLongPress: () => showStickerPreview(
                          context,
                          StickerService.fromLocal(sticker),
                          collectionOnly: true,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(5),
                          child: Image.memory(
                            sticker.webp,
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
