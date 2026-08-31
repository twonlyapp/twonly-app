import 'dart:math';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/delete_memories_dialog.comp.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/views/camera/share_image_editor.view.dart';
import 'package:twonly/src/visual/views/memories/components/synchronized_viewer_actions_toolbar.comp.dart';
import 'package:twonly/src/visual/views/memories/components/synchronized_viewer_item.comp.dart';

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
  final Set<String> _precachedMediaIds = {};

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
    _precachedMediaIds.add(initialId);

    _horizontalPager = PageController(initialPage: widget.initialIndex);
    _verticalPager = PageController(initialPage: 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _verticalPager.addListener(_onVerticalScrollUpdated);
        _precacheNeighbours(_currentIndex);
      }
    });

    for (final item in widget.galleryItems) {
      if (item.mediaService.mediaFile.isFavorite) {
        _favoritedMediaIds.add(item.mediaService.mediaFile.mediaId);
      }
      if (item.mediaService.mediaFile.stored ||
          (item.mediaService.storedPath.existsSync() &&
              item.mediaService.storedPath.lengthSync() > 0)) {
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
    final item = widget.galleryItems[_currentIndex];
    final mediaId = item.mediaService.mediaFile.mediaId;
    final hasCloudBackup =
        item.mediaService.mediaFile.cloudState != CloudState.none;

    final deleteCompletely = await showDeleteMemoriesDialog(
      context: context,
      count: 1,
      hasCloudBackup: hasCloudBackup,
    );

    if (deleteCompletely == null) return;

    if (deleteCompletely) {
      await item.mediaService.fullMediaRemoval();
      await RustApi.deleteMemory(mediaId: mediaId);
      await twonlyDB.mediaFilesDao.deleteMediaFile(mediaId);

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
    } else {
      if (item.mediaService.storedPath.existsSync()) {
        item.mediaService.storedPath.deleteSync();
      }
    }
  }

  Future<void> _exportFile() async {
    final item = widget.galleryItems[_currentIndex].mediaService;

    if (!item.storedPath.existsSync()) {
      await item.storeMediaFile();
      if (!mounted) return;
      if (userService.currentUser.storeMediaFilesInGallery) {
        showSnackbar(
          context,
          context.lang.galleryExportSuccess,
          level: SnackbarLevel.success,
        );
        return;
      }
    }

    try {
      await item.saveToGallery();
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

    final mediaId = await RustApi.initializeMediaUpload(
      mediaType: orgMediaService.mediaFile.type.name,
      displayLimitInMilliseconds: userService.currentUser.defaultShowTime,
      isDraftMedia: false,
    );
    final newMediaService = await MediaFileService.fromMediaId(mediaId);
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
                      _precachedMediaIds.add(newMediaId);
                      _precacheNeighbours(idx);
                    },
                    itemBuilder: (context, index) {
                      return SynchronizedViewerItemComp(
                        item: widget.galleryItems[index],
                        currentlyViewedMediaIdNotifier:
                            _currentlyViewedMediaIdNotifier,
                        onZoomChanged: (zoomed) {
                          if (_isZoomed != zoomed) {
                            setState(() {
                              _isZoomed = zoomed;
                            });
                          }
                        },
                      );
                    },
                  ),

                  Positioned(
                    bottom: MediaQuery.paddingOf(context).bottom + 16,
                    left: 0,
                    right: 0,
                    child: AnimatedOpacity(
                      opacity: _isZoomed ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: IgnorePointer(
                        ignoring: _isZoomed,
                        child: Center(
                          child: SynchronizedViewerActionsToolbarComp(
                            isFavorite: _favoritedMediaIds.contains(
                              currentMediaId,
                            ),
                            onShare: _shareMediaFile,
                            onExport: _exportFile,
                            onToggleFavorite: () =>
                                _toggleFavorite(currentMediaId),
                            onDelete: _deleteFile,
                            showStoreButton: !_storedMediaIds.contains(
                              currentMediaId,
                            ),
                            onStore: _storeMediaFile,
                            isImageSaving: _isSaving,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _precacheNeighbours(int index) {
    if (!mounted) return;

    final indicesToPrecache = [index - 5, index + 5];

    for (final idx in indicesToPrecache) {
      if (idx >= 0 && idx < widget.galleryItems.length) {
        final item = widget.galleryItems[idx];
        if (item.mediaService.mediaFile.type == MediaType.video) {
          continue;
        }

        final mediaId = item.mediaService.mediaFile.mediaId;
        if (_precachedMediaIds.contains(mediaId)) {
          continue;
        }

        final filePath =
            item.mediaService.storedPath.existsSync() &&
                item.mediaService.storedPath.lengthSync() > 0
            ? item.mediaService.storedPath
            : item.mediaService.tempPath.existsSync() &&
                  item.mediaService.tempPath.lengthSync() > 0
            ? item.mediaService.tempPath
            : item.mediaService.thumbnailPath;

        if (filePath.existsSync() && filePath.lengthSync() > 0) {
          _precachedMediaIds.add(mediaId);
          precacheImage(FileImage(filePath), context).onError((e, s) {
            _precachedMediaIds.remove(mediaId);
          });
        }
      }
    }
  }
}
