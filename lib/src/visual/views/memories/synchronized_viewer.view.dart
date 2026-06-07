import 'dart:math';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_view/photo_view.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/services/api/mediafiles/upload.api.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/helpers/video_player_file.helper.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor.view.dart';
import 'package:twonly/src/visual/views/memories/components/synchronized_viewer_actions_toolbar.comp.dart';

class SynchronizedImageViewerScreen extends StatefulWidget {
  const SynchronizedImageViewerScreen({
    required this.galleryItems,
    required this.initialIndex,
    required this.activeMediaIdNotifier,
    super.key,
  });

  final List<MemoryItem> galleryItems;
  final int initialIndex;
  final ValueNotifier<String?> activeMediaIdNotifier;

  @override
  State<SynchronizedImageViewerScreen> createState() =>
      _SynchronizedImageViewerScreenState();
}

class _SynchronizedImageViewerScreenState
    extends State<SynchronizedImageViewerScreen> {
  late PageController _verticalPager;
  late PageController _horizontalPager;
  late ValueNotifier<String> _currentlyViewedMediaIdNotifier;
  final ValueNotifier<double> _backdropOpacityNotifier = ValueNotifier(1);

  final Set<String> _favoritedMediaIds = {};
  bool _isSaving = false;
  final Set<String> _storedMediaIds = {};

  late int _currentIndex;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _currentIndex = widget.initialIndex;
    final initialId =
        widget.galleryItems[widget.initialIndex].mediaService.mediaFile.mediaId;
    _currentlyViewedMediaIdNotifier = ValueNotifier(initialId);

    _horizontalPager = PageController(initialPage: widget.initialIndex);
    _verticalPager = PageController(initialPage: 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _verticalPager.addListener(_onVerticalScrollUpdated);
    });

    for (final item in widget.galleryItems) {
      if (item.mediaService.mediaFile.isFavorite) {
        _favoritedMediaIds.add(item.mediaService.mediaFile.mediaId);
      }
      if (item.mediaService.storedPath.existsSync()) {
        _storedMediaIds.add(item.mediaService.mediaFile.mediaId);
      }
    }
  }

  Future<void> _storeMediaFile() async {
    final item = widget.galleryItems[_currentIndex];
    final mediaId = item.mediaService.mediaFile.mediaId;
    setState(() => _isSaving = true);
    try {
      await item.mediaService.storeMediaFile();
      if (mounted) {
        setState(() {
          _storedMediaIds.add(mediaId);
        });
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _toggleFavorite(String mediaId) async {
    final wasFavorite = _favoritedMediaIds.contains(mediaId);
    final isFavoriteNow = !wasFavorite;

    setState(() {
      if (isFavoriteNow) {
        _favoritedMediaIds.add(mediaId);
      } else {
        _favoritedMediaIds.remove(mediaId);
      }
    });

    await twonlyDB.mediaFilesDao.updateMedia(
      mediaId,
      MediaFilesCompanion(isFavorite: Value(isFavoriteNow)),
    );
  }

  void _restoreSystemUI() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  @override
  void dispose() {
    _restoreSystemUI();
    _verticalPager
      ..removeListener(_onVerticalScrollUpdated)
      ..dispose();
    _horizontalPager.dispose();
    _currentlyViewedMediaIdNotifier.dispose();
    _backdropOpacityNotifier.dispose();
    super.dispose();
  }

  void _onVerticalScrollUpdated() {
    if (!_verticalPager.hasClients) return;
    final page = _verticalPager.page ?? 1.0;

    // Map vertical dragging proximity directly to square-root backdrop opacities
    final linearFraction = min(1, max(0, page)).toDouble();
    _backdropOpacityNotifier.value = linearFraction * linearFraction;
  }

  void _onPageSnapped(int index) {
    if (index == 0) {
      _triggerSynchronizedPop();
    }
  }

  void _triggerSynchronizedPop() {
    _restoreSystemUI();
    final targetId = _currentlyViewedMediaIdNotifier.value;

    if (widget.activeMediaIdNotifier.value != targetId) {
      widget.activeMediaIdNotifier.value = targetId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.maybeOf(context)?.pop(true);
      });
    } else {
      Navigator.maybeOf(context)?.pop(true);
    }
  }

  Future<void> _deleteFile() async {
    final confirmed = await showAlertDialog(
      context,
      context.lang.deleteImageTitle,
      context.lang.deleteImageBody,
    );

    if (!confirmed) return;

    widget.galleryItems[_currentIndex].mediaService.fullMediaRemoval();
    await twonlyDB.mediaFilesDao.deleteMediaFile(
      widget.galleryItems[_currentIndex].mediaService.mediaFile.mediaId,
    );

    widget.galleryItems.removeAt(_currentIndex);

    if (widget.galleryItems.isEmpty) {
      if (mounted) Navigator.pop(context, true);
      return;
    }

    if (_currentIndex >= widget.galleryItems.length) {
      _currentIndex = widget.galleryItems.length - 1;
    }

    final newId =
        widget.galleryItems[_currentIndex].mediaService.mediaFile.mediaId;
    _currentlyViewedMediaIdNotifier.value = newId;
    widget.activeMediaIdNotifier.value = newId;

    setState(() {});
  }

  Future<void> _exportFile() async {
    final item = widget.galleryItems[_currentIndex].mediaService;

    try {
      if (item.mediaFile.type == MediaType.video) {
        await saveVideoToGallery(item.storedPath.path);
      } else if (item.mediaFile.type == MediaType.image ||
          item.mediaFile.type == MediaType.gif) {
        final imageBytes = await item.storedPath.readAsBytes();
        await saveImageToGallery(imageBytes, createdAt: item.mediaFile.createdAt);
      }
      if (!mounted) return;
      showSnackbar(
        context,
        context.lang.galleryExportSuccess,
        level: SnackbarLevel.success,
      );
    } catch (e) {
      if (!mounted) return;
      showSnackbar(
        context,
        e.toString(),
        level: SnackbarLevel.success,
      );
    }
  }

  Future<void> _shareMediaFile() async {
    final orgMediaService = widget.galleryItems[_currentIndex].mediaService;

    final newMediaService = await initializeMediaUpload(
      orgMediaService.mediaFile.type,
      userService.currentUser.defaultShowTime,
    );
    if (newMediaService == null) {
      Log.error('Could not create new mediaFile');
      return;
    }

    if (orgMediaService.storedPath.existsSync()) {
      orgMediaService.storedPath.copySync(newMediaService.originalPath.path);
    } else if (orgMediaService.tempPath.existsSync()) {
      orgMediaService.tempPath.copySync(newMediaService.originalPath.path);
    }

    if (!mounted) return;

    await context.navPush(
      ShareImageEditorView(
        mediaFileService: newMediaService,
        sharedFromGallery: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.galleryItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final orgMediaService = widget.galleryItems[_currentIndex].mediaService;
    final currentMediaId = orgMediaService.mediaFile.mediaId;

    return PopScope<Object?>(
      onPopInvokedWithResult: (didPop, result) {
        _restoreSystemUI();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: ValueListenableBuilder<double>(
          valueListenable: _backdropOpacityNotifier,
          builder: (context, opacity, child) {
            return ColoredBox(
              color: Colors.black.withValues(alpha: opacity),
              child: child,
            );
          },
          child: PageView(
            controller: _verticalPager,
            scrollDirection: Axis.vertical,
            physics: _isZoomed
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
            onPageChanged: _onPageSnapped,
            children: [
              //Fully transparent dismissal trigger anchor
              const SizedBox.expand(),

              Stack(
                children: [
                  PageView.builder(
                    controller: _horizontalPager,
                    physics: _isZoomed
                        ? const NeverScrollableScrollPhysics()
                        : const BouncingScrollPhysics(),
                    itemCount: widget.galleryItems.length,
                    onPageChanged: (idx) {
                      setState(() {
                        _currentIndex = idx;
                      });
                      final newMediaId = widget
                          .galleryItems[idx]
                          .mediaService
                          .mediaFile
                          .mediaId;
                      _currentlyViewedMediaIdNotifier.value = newMediaId;
                      widget.activeMediaIdNotifier.value = newMediaId;
                    },
                    itemBuilder: (context, index) {
                      final item = widget.galleryItems[index];
                      final itemMediaId = item.mediaService.mediaFile.mediaId;

                      var filePath = item.mediaService.storedPath;
                      if (!filePath.existsSync()) {
                        filePath = item.mediaService.tempPath;
                      }

                      final isVideo =
                          item.mediaService.mediaFile.type == MediaType.video;

                      return Center(
                        child: ValueListenableBuilder<String>(
                          valueListenable: _currentlyViewedMediaIdNotifier,
                          builder: (context, activeMediaId, childWidget) {
                            // Dynamically resolve Hero tags to prevent layout tree duplicate assertions
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
                          child: !filePath.existsSync()
                              ? const Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.white38,
                                    size: 64,
                                  ),
                                )
                              : isVideo
                              ? VideoPlayerFileHelper(videoPath: filePath)
                              : PhotoView(
                                  imageProvider: FileImage(filePath),
                                  initialScale:
                                      PhotoViewComputedScale.contained,
                                  minScale: PhotoViewComputedScale.contained,
                                  maxScale:
                                      PhotoViewComputedScale.covered * 4.1,
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
                                    final zoomed =
                                        state != PhotoViewScaleState.initial;
                                    if (_isZoomed != zoomed) {
                                      setState(() {
                                        _isZoomed = zoomed;
                                      });
                                    }
                                  },
                                ),
                        ),
                      );
                    },
                  ),

                  SynchronizedViewerActionsToolbarComp(
                    isFavorite: _favoritedMediaIds.contains(currentMediaId),
                    onShare: _shareMediaFile,
                    onExport: _exportFile,
                    onToggleFavorite: () => _toggleFavorite(currentMediaId),
                    onDelete: _deleteFile,
                    showStoreButton: !_storedMediaIds.contains(currentMediaId),
                    onStore: _storeMediaFile,
                    isImageSaving: _isSaving,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
