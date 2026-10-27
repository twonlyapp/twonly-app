import 'package:flutter/material.dart';
import 'package:twonly/core/database/app/stickers/table.dart';
import 'package:twonly/src/services/stickers/sticker.service.dart';
import 'package:twonly/src/services/stickers/sticker_cache.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/emoji_picker/bottom_action_bar.dart';
import 'package:twonly/src/visual/components/sticker_preview.dialog.dart';
import 'package:twonly/src/visual/loader/three_rotating_dots.loader.dart';
import 'package:twonly/src/visual/views/memories/memories_picker.view.dart';

class StickerPicker extends StatefulWidget {
  const StickerPicker({
    required this.onStickerSelected,
    this.onEmojiPressed,
    this.selectCreatedSticker = false,
    super.key,
  });

  final VoidCallback? onEmojiPressed;
  final ValueChanged<LocalSticker> onStickerSelected;
  final bool selectCreatedSticker;

  @override
  State<StickerPicker> createState() => _StickerPickerState();
}

class _StickerPickerState extends State<StickerPicker> {
  late final Stream<List<LocalSticker>> _stickers = watchCachedStickers();
  bool _creating = false;

  Future<void> _createSticker() async {
    if (_creating) return;
    setState(() => _creating = true);
    try {
      final imagePath = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (context) =>
              MemoriesPickerView(title: context.lang.createSticker),
        ),
      );
      if (!mounted || imagePath == null) return;
      final sticker = await StickerService.createFromPath(imagePath);
      if (!mounted) return;
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
      child: StreamBuilder<List<LocalSticker>>(
        stream: _stickers,
        builder: (context, snapshot) {
          final isLoading = !snapshot.hasData && !snapshot.hasError;
          final stickers = snapshot.data ?? const <LocalSticker>[];
          final hasStickers = stickers.isNotEmpty;
          final addButton = hasStickers
              ? IconButton(
                  key: const Key('stickerPickerHeaderAdd'),
                  tooltip: context.lang.createSticker,
                  padding: const EdgeInsets.only(bottom: 2),
                  onPressed: _creating ? null : _createSticker,
                  icon: _creating
                      ? const ThreeRotatingDots(size: 22)
                      : Icon(
                          Icons.add_photo_alternate_outlined,
                          color: color.secondary,
                        ),
                )
              : null;
          return Column(
            children: [
              if (widget.onEmojiPressed != null)
                PickerBottomBar(
                  backgroundColor: color.surfaceContainer,
                  buttonIconColor: color.secondary,
                  emojiButtonLabel: 'Emoji',
                  stickerButtonLabel: context.lang.sticker,
                  showStickerButton: true,
                  stickerSelected: true,
                  onEmojiButtonPressed: widget.onEmojiPressed,
                  trailing: addButton,
                )
              else
                SizedBox(
                  height: 48,
                  child: Row(
                    children: [
                      const SizedBox(width: 48),
                      Expanded(
                        child: Text(
                          context.lang.stickers,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      SizedBox(width: 48, child: addButton),
                    ],
                  ),
                ),
              Expanded(
                child: isLoading
                    ? const Center(child: ThreeRotatingDots(size: 26))
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 104,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                            ),
                        itemCount: stickers.length + (hasStickers ? 0 : 1),
                        itemBuilder: (context, index) {
                          if (!hasStickers) {
                            return Semantics(
                              key: const Key('stickerPickerEmptyAdd'),
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
                          final sticker = stickers[index];
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
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
