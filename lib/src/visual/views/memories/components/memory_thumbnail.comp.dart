import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/model/memory_item.model.dart';
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

final Set<String> _alreadyAnimatedIds = {};

class _MemoriesThumbnailCompState extends State<MemoriesThumbnailComp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final Animation<double> _scaleAnimation;
  late final Animation<Offset> _slideAnimation;

  ImageProvider? _imageProvider;
  ImageStream? _imageStream;
  ImageInfo? _imageInfo;
  late final ImageStreamListener _listener;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnimation = Tween<double>(begin: 0.94, end: 1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );
    _slideAnimation =
        Tween<Offset>(
          begin: const Offset(0, 0.125),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
        );

    final mediaId = widget.galleryItem.mediaService.mediaFile.mediaId;
    final shouldAnimate =
        widget.index < 20 && !_alreadyAnimatedIds.contains(mediaId);

    if (shouldAnimate) {
      _alreadyAnimatedIds.add(mediaId);
      final delayMs = widget.index * 10;
      if (delayMs > 0) {
        Future.delayed(Duration(milliseconds: delayMs), () {
          if (mounted) {
            _scaleController.forward();
          }
        });
      } else {
        _scaleController.forward();
      }
    } else {
      _scaleController.value = 1.0;
    }

    _listener = ImageStreamListener((info, _) {
      if (mounted) {
        setState(() {
          _imageInfo = info;
        });
      }
    });
    _resolveImage();
  }

  void _resolveImage() {
    final media = widget.galleryItem.mediaService;
    final hasThumbnail = media.thumbnailPath.existsSync();
    final hasStored = media.storedPath.existsSync();
    final isImageOrGif =
        media.mediaFile.type == MediaType.image ||
        media.mediaFile.type == MediaType.gif;

    if (hasThumbnail) {
      _imageProvider = FileImage(media.thumbnailPath);
    } else if (hasStored && isImageOrGif) {
      _imageProvider = FileImage(media.storedPath);
    }

    if (_imageProvider != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final config = createLocalImageConfiguration(context);
        _imageStream = _imageProvider!.resolve(config);
        _imageStream!.addListener(_listener);
      });
    }
  }

  @override
  void didUpdateWidget(covariant MemoriesThumbnailComp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.galleryItem.mediaService.mediaFile.mediaId !=
        widget.galleryItem.mediaService.mediaFile.mediaId) {
      _imageStream?.removeListener(_listener);
      _imageInfo = null;
      _resolveImage();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
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
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: FadeTransition(
              opacity: _scaleController,
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
                  ],
                ),
              ),
            ),
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
