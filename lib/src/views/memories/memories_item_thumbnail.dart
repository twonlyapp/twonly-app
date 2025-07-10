import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/model/memory_item.model.dart';

class MemoriesItemThumbnail extends StatefulWidget {
  const MemoriesItemThumbnail({
    super.key,
    required this.galleryItem,
    required this.onTap,
  });

  final MemoryItem galleryItem;
  final GestureTapCallback onTap;

  @override
  State<MemoriesItemThumbnail> createState() => _MemoriesItemThumbnailState();
}

class _MemoriesItemThumbnailState extends State<MemoriesItemThumbnail> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Hero(
        tag: widget.galleryItem.id.toString(),
        child: Stack(
          children: [
            Image.file(widget.galleryItem.thumbnailPath),
            if (widget.galleryItem.videoPath != null)
              Positioned.fill(
                child: Center(
                  child: FaIcon(FontAwesomeIcons.circlePlay),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
