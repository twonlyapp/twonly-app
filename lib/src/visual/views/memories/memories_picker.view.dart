import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:twonly/src/model/media_enums.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/services/memories/memories.service.dart';
import 'package:twonly/src/services/stickers/sticker.service.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/loader/three_rotating_dots.loader.dart';
import 'package:twonly/src/visual/views/memories/components/memory_thumbnail.comp.dart';

/// Selects full-resolution media from twonly Memories or the device gallery.
/// Pops with the selected path, or null when the user backs out.
class MemoriesPickerView extends StatefulWidget {
  const MemoriesPickerView({
    required this.title,
    this.allowVideos = false,
    super.key,
  });

  static Route<String> route({
    required String title,
    bool allowVideos = false,
  }) {
    return PageRouteBuilder<String>(
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) =>
          MemoriesPickerView(
            title: title,
            allowVideos: allowVideos,
          ),
    );
  }

  /// Names what the media is picked for, such as a sticker or an avatar.
  final String title;
  final bool allowVideos;

  @override
  State<MemoriesPickerView> createState() => _MemoriesPickerViewState();
}

class _MemoriesPickerViewState extends State<MemoriesPickerView> {
  late final MemoriesService _memories = MemoriesService();
  String? _resolvingMediaId;

  @override
  void dispose() {
    _memories.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    if (_resolvingMediaId != null) return;
    final picker = ImagePicker();
    final media = widget.allowVideos
        ? await picker.pickMedia()
        : await picker.pickImage(source: ImageSource.gallery);
    if (!mounted || media == null) return;
    Navigator.pop(context, media.path);
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
          SnackBar(content: Text(context.lang.memoriesLoadFailed)),
        );
        return;
      }
      Navigator.pop(context, path);
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.lang.memoriesLoadFailed)),
      );
    } finally {
      if (mounted) setState(() => _resolvingMediaId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: MyButton(
        variant: MyButtonVariant.secondaryMiddle,
        onPressed: _resolvingMediaId == null ? _pickFromGallery : null,
        child: Text(context.lang.stickerPickFromGallery),
      ),
      body: StreamBuilder<MemoriesState>(
        stream: _memories.watchState,
        initialData: _memories.currentState,
        builder: (context, snapshot) {
          final state = snapshot.data ?? _memories.currentState;
          final items = state.galleryItems
              .where(
                (item) =>
                    item.mediaService.mediaFile.type == MediaType.image ||
                    (widget.allowVideos &&
                        (item.mediaService.mediaFile.type == MediaType.video ||
                            item.mediaService.mediaFile.type == MediaType.gif)),
              )
              .toList(growable: false);

          if (items.isEmpty && state.isLoading) {
            return const Center(child: ThreeRotatingDots(size: 32));
          }
          if (items.isEmpty) {
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
                padding: EdgeInsets.only(
                  top: 8,
                  bottom: 80 + MediaQuery.paddingOf(context).bottom,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                  childAspectRatio: 9 / 16,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return HeroMode(
                    enabled: false,
                    child: MemoriesThumbnailComp(
                      galleryItem: item,
                      index: index,
                      onTap: () => _selectMemory(item),
                    ),
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
