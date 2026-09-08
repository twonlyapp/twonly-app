import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/services/memories/memories_cloud.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/visual/components/selectable_thumbnail.comp.dart';
import 'package:twonly/src/visual/views/memories/components/memory_transition_painter.dart';

class MemoriesThumbnailComp extends StatefulWidget {
  const MemoriesThumbnailComp({
    required this.galleryItem,
    required this.onTap,
    this.index = 0,
    this.onLongPress,
    this.selectionMode = false,
    this.isSelected = false,
    this.activeMediaIdNotifier,
    super.key,
  });

  final MemoryItem galleryItem;
  final int index;
  final GestureTapCallback onTap;
  final GestureLongPressCallback? onLongPress;
  final bool selectionMode;
  final bool isSelected;
  final ValueNotifier<String?>? activeMediaIdNotifier;

  @override
  State<MemoriesThumbnailComp> createState() => _MemoriesThumbnailCompState();
}

class _MemoriesThumbnailCompState extends State<MemoriesThumbnailComp> {
  ImageProvider? _imageProvider;
  File? _selectedImageFile;
  ImageStream? _imageStream;
  ImageInfo? _imageInfo;
  int _retries = 0;
  bool _hasStoredFile = false;

  /// A tile asks for a missing thumbnail once. Retrying whenever the attempt
  /// finishes would spin forever for media whose thumbnail cannot be produced,
  /// and every one of those turns is a database round trip on the UI isolate.
  bool _recoveryRequested = false;
  late final ImageStreamListener _listener;

  @override
  void initState() {
    super.initState();

    _listener = ImageStreamListener(
      (info, _) {
        if (mounted) {
          setState(() {
            _imageInfo = info;
          });
        }
      },
      onError: (exception, stackTrace) {
        if (mounted) {
          setState(() {
            _imageProvider = null;
            _imageInfo = null;
            _selectedImageFile = null;
          });
        }
      },
    );
    _resolveImage();
  }

  /// Whether a file is there and has content, in a single stat call. This runs
  /// synchronously for every tile the grid builds, so the probe stays cheap.
  static bool _isReadable(File file) {
    final stat = file.statSync();
    return stat.type != FileSystemEntityType.notFound && stat.size > 0;
  }

  void _resolveImage() {
    if (_retries > 3) return;
    final media = widget.galleryItem.mediaService;
    final hasThumbnail = _isReadable(media.thumbnailPath);
    final hasStored = _isReadable(media.storedPath);
    _hasStoredFile = hasStored;
    final isImageOrGif =
        media.mediaFile.type == MediaType.image ||
        media.mediaFile.type == MediaType.gif;

    _selectedImageFile = null;

    if (hasThumbnail) {
      _imageProvider = FileImage(media.thumbnailPath);
      _selectedImageFile = media.thumbnailPath;
    } else if (hasStored && isImageOrGif) {
      _imageProvider = FileImage(media.storedPath);
      _selectedImageFile = media.storedPath;
    }

    if (!hasThumbnail && !_recoveryRequested) {
      _recoveryRequested = true;
      // Either source may come back without having written anything, so the
      // result is judged by the file itself and the tile falls back to the
      // blurhash rather than asking again.
      final recovery = hasStored
          ? media.createThumbnail()
          : MemoriesCloudService.downloadFromCloud(media, isThumbnail: true);
      unawaited(
        recovery.then((_) {
          if (mounted && _isReadable(media.thumbnailPath)) {
            _resolveImage();
          }
        }),
      );
    }

    if (_imageProvider != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final provider = _imageProvider;
        if (provider == null) return;
        final stream = provider.resolve(createLocalImageConfiguration(context));
        // Swapping only on a different key keeps the listener count at one:
        // dropping the old stream before the new one is resolved would leave
        // the listener attached to a completer nothing removes it from, and a
        // completer with listeners keeps its decoded image alive.
        if (stream.key == _imageStream?.key) return;
        _imageStream?.removeListener(_listener);
        _imageStream = stream;
        stream.addListener(_listener);
      });
      // A post-frame callback only runs once a frame is coming, and a preview
      // that arrived late resolves while the app is sitting idle.
      WidgetsBinding.instance.ensureVisualUpdate();
    }
  }

  @override
  void didUpdateWidget(covariant MemoriesThumbnailComp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.galleryItem.mediaService.mediaFile.mediaId !=
        widget.galleryItem.mediaService.mediaFile.mediaId) {
      _imageStream?.removeListener(_listener);
      _imageStream = null;
      _imageProvider = null;
      _imageInfo = null;
      _retries = 0;
      _recoveryRequested = false;
      _selectedImageFile = null;
      _resolveImage();
    }
  }

  @override
  void dispose() {
    _imageStream?.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.galleryItem.mediaService;
    final isVideo = media.mediaFile.type == MediaType.video;
    final cachedInfo = _imageInfo;
    final mediaId = media.mediaFile.mediaId;

    Widget buildHero(String tag) {
      return Hero(
        key: ValueKey(tag),
        tag: tag,
        transitionOnUserGestures: true,
        flightShuttleBuilder: cachedInfo != null
            ? (
                flightContext,
                animation,
                flightDirection,
                fromHeroContext,
                toHeroContext,
              ) {
                return TransitionImage(
                  imageInfo: cachedInfo,
                  animation: animation,
                  thumbnailFit: BoxFit.cover,
                  viewerFit: BoxFit.contain,
                );
              }
            : null,
        child: SelectableThumbnailComp(
          isSelected: widget.isSelected,
          selectionMode: widget.selectionMode,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (cachedInfo != null)
                RawImage(
                  image: cachedInfo.image,
                  fit: BoxFit.cover,
                )
              else if (_imageProvider != null)
                Image(
                  image: _imageProvider!,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (context, error, stackTrace) {
                    if (error.toString().contains('Invalid image data')) {
                      final fileToDelete = _selectedImageFile;
                      _selectedImageFile = null;
                      if (fileToDelete != null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          try {
                            if (fileToDelete.existsSync()) {
                              fileToDelete.deleteSync();
                            }
                          } catch (_) {}
                          if (_retries < 3) {
                            _retries++;
                            // The broken file is gone, so fetching it again is
                            // a new attempt rather than the one already made.
                            _recoveryRequested = false;
                            _resolveImage();
                          }
                        });
                      }
                    }
                    Log.warn(error);
                    return ColoredBox(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: FaIcon(
                          FontAwesomeIcons.image,
                          color: Colors.black26,
                        ),
                      ),
                    );
                  },
                )
              else if (media.mediaFile.blurhash != null)
                BlurHash(
                  hash: media.mediaFile.blurhash!,
                  optimizationMode: BlurHashOptimizationMode.approximation,
                )
              else
                ColoredBox(
                  color: Colors.grey.shade200,
                  child: const Center(
                    child: FaIcon(
                      FontAwesomeIcons.image,
                      color: Colors.black26,
                    ),
                  ),
                ),
              if (isVideo)
                const Positioned.fill(
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.circlePlay,
                      color: Colors.white,
                      size: 32,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 6),
                      ],
                    ),
                  ),
                ),
              if (media.mediaFile.isFavorite)
                const Positioned(
                  bottom: 6,
                  left: 6,
                  child: Icon(
                    Icons.favorite,
                    color: Colors.redAccent,
                    size: 16,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 4),
                    ],
                  ),
                ),
              Builder(
                builder: (context) {
                  final hasStored = _hasStoredFile;
                  final IconData iconData;
                  final Color color;

                  switch (media.mediaFile.cloudState) {
                    case CloudState.none:
                      iconData = Icons.cloud_off_outlined;
                      color = Colors.white54;
                    case CloudState.pending:
                      iconData = Icons.cloud_upload_outlined;
                      color = Colors.white70;
                    case CloudState.uploaded:
                      if (hasStored) {
                        iconData = Icons.cloud_done_outlined;
                        color = Colors.white;
                      } else {
                        iconData = Icons.cloud_outlined;
                        color = Colors.white;
                      }
                  }

                  return Positioned(
                    bottom: 6,
                    right: 6,
                    child: Icon(
                      iconData,
                      color: color,
                      size: 16,
                      shadows: const [
                        Shadow(color: Colors.black54, blurRadius: 4),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: widget.activeMediaIdNotifier != null
          ? ValueListenableBuilder<String?>(
              valueListenable: widget.activeMediaIdNotifier!,
              builder: (context, activeId, _) {
                final isActive = activeId == null || activeId == mediaId;
                return buildHero(
                  isActive ? mediaId : '${mediaId}_grid_inactive',
                );
              },
            )
          : buildHero(mediaId),
    );
  }
}
