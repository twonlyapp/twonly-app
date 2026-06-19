import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart'
    show MediaType;
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:video_player/video_player.dart';

class MediaContentRenderer extends StatelessWidget {
  const MediaContentRenderer({
    required this.currentMedia,
    required this.videoController,
    required this.loader,
    super.key,
  });

  final MediaFileService? currentMedia;
  final VideoPlayerController? videoController;
  final Widget loader;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (videoController != null)
          Positioned.fill(
            child: PhotoView.customChild(
              initialScale: PhotoViewComputedScale.contained,
              minScale: PhotoViewComputedScale.contained,
              backgroundDecoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              child: VideoPlayer(
                videoController!,
              ),
            ),
          )
        else if (currentMedia != null &&
            (currentMedia!.mediaFile.type == MediaType.image ||
                currentMedia!.mediaFile.type == MediaType.gif))
          Positioned.fill(
            child: PhotoView(
              imageProvider: FileImage(
                currentMedia!.tempPath,
              ),
              loadingBuilder: (context, event) => loader,
              backgroundDecoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              initialScale: PhotoViewComputedScale.contained,
              minScale: PhotoViewComputedScale.contained,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white38,
                    size: 64,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
