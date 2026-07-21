import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:photo_view/photo_view.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/services/memories/memories_cloud.service.dart';
import 'package:twonly/src/visual/helpers/video_player_file.helper.dart';

class SynchronizedViewerItemComp extends StatefulWidget {
  const SynchronizedViewerItemComp({
    required this.item,
    required this.currentlyViewedMediaIdNotifier,
    required this.onZoomChanged,
    super.key,
  });

  final MemoryItem item;
  final ValueNotifier<String> currentlyViewedMediaIdNotifier;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<SynchronizedViewerItemComp> createState() =>
      _SynchronizedViewerItemCompState();
}

class _SynchronizedViewerItemCompState
    extends State<SynchronizedViewerItemComp> {
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _checkAndDownload();
  }

  @override
  void didUpdateWidget(covariant SynchronizedViewerItemComp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.mediaService.mediaFile.mediaId !=
        widget.item.mediaService.mediaFile.mediaId) {
      _checkAndDownload();
    }
  }

  void _checkAndDownload() {
    final media = widget.item.mediaService;
    final hasStored =
        media.storedPath.existsSync() && media.storedPath.lengthSync() > 0;

    if (!hasStored &&
        media.mediaFile.cloudState == CloudState.uploaded &&
        !_isDownloading) {
      _isDownloading = true;
      unawaited(
        MemoriesCloudService.downloadFromCloud(
          media,
          isThumbnail: false,
        ).then((success) async {
          if (success && mounted) {
            final fullPath = media.storedPath;
            if (media.mediaFile.type == MediaType.image ||
                media.mediaFile.type == MediaType.gif) {
              if (fullPath.existsSync()) {
                try {
                  await precacheImage(FileImage(fullPath), context);
                } catch (e) {
                  // Ignore precache errors
                }
              }
            }
          }
          if (mounted) {
            setState(() {
              _isDownloading = false;
            });
          }
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final itemMediaId = item.mediaService.mediaFile.mediaId;

    var filePath = item.mediaService.storedPath;
    final hasStored = filePath.existsSync() && filePath.lengthSync() > 0;
    if (!hasStored) {
      filePath = item.mediaService.tempPath;
      final hasTemp = filePath.existsSync() && filePath.lengthSync() > 0;
      if (!hasTemp) {
        filePath = item.mediaService.thumbnailPath;
      }
    }

    final isVideo = item.mediaService.mediaFile.type == MediaType.video;
    final hasVideoFile =
        isVideo &&
        (item.mediaService.storedPath.existsSync() &&
                item.mediaService.storedPath.lengthSync() > 0 ||
            item.mediaService.tempPath.existsSync() &&
                item.mediaService.tempPath.lengthSync() > 0);

    return Center(
      child: ValueListenableBuilder<String>(
        valueListenable: widget.currentlyViewedMediaIdNotifier,
        builder: (context, activeMediaId, childWidget) {
          final isActiveTarget = activeMediaId == itemMediaId;

          if (isActiveTarget) {
            return Hero(
              tag: itemMediaId,
              transitionOnUserGestures: true,
              child: childWidget!,
            );
          }
          return childWidget!;
        },
        child: !filePath.existsSync() || filePath.lengthSync() == 0
            ? item.mediaService.mediaFile.blurhash != null
                  ? BlurHash(
                      hash: item.mediaService.mediaFile.blurhash!,
                      optimizationMode: BlurHashOptimizationMode.approximation,
                    )
                  : const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white38,
                        size: 64,
                      ),
                    )
            : hasVideoFile
            ? VideoPlayerFileHelper(videoPath: filePath)
            : PhotoView(
                key: ValueKey(filePath.path),
                imageProvider: FileImage(filePath),
                initialScale: PhotoViewComputedScale.contained,
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 4.1,
                backgroundDecoration: const BoxDecoration(
                  color: Colors.transparent,
                ),
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white38,
                      size: 64,
                    ),
                  );
                },
                scaleStateChangedCallback: (state) {
                  final zoomed = state != PhotoViewScaleState.initial;
                  widget.onZoomChanged(zoomed);
                },
              ),
      ),
    );
  }
}
