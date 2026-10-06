import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/services/memories/memories.service.dart';
import 'package:twonly/src/services/stickers/sticker.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/loader/three_rotating_dots.loader.dart';
import 'package:twonly/src/visual/views/memories/components/memory_thumbnail.comp.dart';

/// Selects a full-resolution image from twonly Memories, with an explicit
/// escape hatch to the device gallery in the top app bar.
class StickerSourcePickerView extends StatefulWidget {
  const StickerSourcePickerView({this.forAvatar = false, super.key});

  final bool forAvatar;

  @override
  State<StickerSourcePickerView> createState() =>
      _StickerSourcePickerViewState();
}

class _StickerSourcePickerViewState extends State<StickerSourcePickerView> {
  late final MemoriesService _memories = MemoriesService();
  String? _resolvingMediaId;

  @override
  void dispose() {
    _memories.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    if (_resolvingMediaId != null) return;
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (!mounted || image == null) return;
    Navigator.pop(context, image.path);
  }

  Future<void> _selectMemory(MemoryItem item) async {
    if (_resolvingMediaId != null) return;
    final mediaId = item.mediaService.mediaFile.mediaId;
    setState(() => _resolvingMediaId = mediaId);
    try {
      final path = await StickerService.resolveMediaPath(item.mediaService);
      if (!mounted) return;
      if (path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.lang.stickerCreateFailed)),
        );
        return;
      }
      Navigator.pop(context, path);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.lang.stickerCreateFailed)),
      );
    } finally {
      if (mounted) setState(() => _resolvingMediaId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.forAvatar
              ? context.lang.customAvatarChooseSource
              : context.lang.createSticker,
        ),
        actions: [
          TextButton.icon(
            onPressed: _resolvingMediaId == null ? _pickFromGallery : null,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(context.lang.stickerPickFromGallery),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<MemoriesState>(
        stream: _memories.watchState,
        initialData: _memories.currentState,
        builder: (context, snapshot) {
          final state = snapshot.data ?? _memories.currentState;
          final images = state.galleryItems
              .where(
                (item) => item.mediaService.mediaFile.type == MediaType.image,
              )
              .toList(growable: false);

          if (images.isEmpty && state.isLoading) {
            return const Center(child: ThreeRotatingDots(size: 32));
          }
          if (images.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  context.lang.memoriesEmpty,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.color.onSurfaceVariant),
                ),
              ),
            );
          }

          return Stack(
            children: [
              GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                  childAspectRatio: 9 / 16,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final item = images[index];
                  return MemoriesThumbnailComp(
                    galleryItem: item,
                    index: index,
                    onTap: () => _selectMemory(item),
                  );
                },
              ),
              if (_resolvingMediaId != null)
                const Positioned.fill(
                  child: ColoredBox(
                    color: Color(0x66000000),
                    child: Center(child: ThreeRotatingDots(size: 32)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
