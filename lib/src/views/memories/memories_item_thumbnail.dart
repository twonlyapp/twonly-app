import 'package:flutter/material.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:video_player/video_player.dart';

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
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();

    if (widget.galleryItem.videoPath != null) {
      _controller = VideoPlayerController.file(widget.galleryItem.videoPath!)
        ..initialize().then((_) {
          setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
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
        tag: widget.galleryItem.id,
        child: (widget.galleryItem.imagePath != null)
            ? Image.file(widget.galleryItem.imagePath!)
            : Stack(
                children: [
                  if (_controller != null && _controller!.value.isInitialized)
                    Positioned.fill(
                        child: AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    )),
                  if (_controller != null && _controller!.value.isInitialized)
                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: Text(
                        _controller!.value.isInitialized
                            ? formatDuration(_controller!.value.duration)
                            : '...',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    )
                ],
              ),
      ),
    );
  }
}
