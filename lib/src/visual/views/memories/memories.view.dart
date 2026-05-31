import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/memory_item.model.dart';
import 'package:twonly/src/services/memories/memories.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/components/draggable_scrollbar.comp.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/views/memories/components/flashback_banner.comp.dart';
import 'package:twonly/src/visual/views/memories/components/memory_thumbnail.comp.dart';
import 'package:twonly/src/visual/views/memories/components/selection_toolbar.comp.dart';
import 'package:twonly/src/visual/views/memories/synchronized_viewer.view.dart';

class MemoriesView extends StatefulWidget {
  const MemoriesView({super.key});

  @override
  State<MemoriesView> createState() => MemoriesViewState();
}

class MemoriesViewState extends State<MemoriesView> {
  late final MemoriesService _service;
  final ValueNotifier<String?> _activeMediaIdNotifier = ValueNotifier(null);
  final ScrollController _scrollController = ScrollController();
  bool _isViewingFlashback = false;

  final Set<String> _selectedMediaIds = {};
  bool _filterFavoritesOnly = false;
  bool get _selectionMode => _selectedMediaIds.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _service = MemoriesService();
    _activeMediaIdNotifier.addListener(_onActiveMediaChanged);
  }

  @override
  void dispose() {
    _activeMediaIdNotifier.removeListener(_onActiveMediaChanged);
    _scrollController.dispose();
    _service.dispose();
    _activeMediaIdNotifier.dispose();
    super.dispose();
  }

  void _onActiveMediaChanged() {
    if (_isViewingFlashback) return;
    final mediaId = _activeMediaIdNotifier.value;
    if (mediaId == null) return;
    final state = _service.currentState;
    if (state.isEmpty) return;

    final index = state.galleryItems.indexWhere(
      (item) => item.mediaService.mediaFile.mediaId == mediaId,
    );
    if (index == -1) return;

    double offset = 56;
    if (state.galleryItemsLastYears.isNotEmpty) {
      offset += 220;
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final itemWidth = (screenWidth - 8) / 4;
    final itemHeight = itemWidth * (16 / 9);
    final rowHeight = itemHeight + 2;

    for (final month in state.months) {
      final indices = state.orderedByMonth[month]!;
      offset += 44;

      if (indices.contains(index)) {
        final localIdx = indices.indexOf(index);
        final row = localIdx ~/ 4;
        offset += row * rowHeight;
        break;
      } else {
        final totalRows = (indices.length + 3) ~/ 4;
        offset += totalRows * rowHeight;
      }
    }

    if (_scrollController.hasClients) {
      final targetOffset = (offset - 100).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.jumpTo(targetOffset);
    }
  }

  Future<void> _openViewer(
    List<MemoryItem> items,
    int index, {
    bool isFlashback = false,
  }) async {
    if (isFlashback) {
      _isViewingFlashback = true;
    }
    _activeMediaIdNotifier.value = items[index].mediaService.mediaFile.mediaId;

    await Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) {
          return SynchronizedImageViewerScreen(
            galleryItems: items,
            initialIndex: index,
            activeMediaIdNotifier: _activeMediaIdNotifier,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );

    if (isFlashback) {
      _isViewingFlashback = false;
    }
  }

  void _toggleSelection(String mediaId) {
    setState(() {
      if (_selectedMediaIds.contains(mediaId)) {
        _selectedMediaIds.remove(mediaId);
      } else {
        _selectedMediaIds.add(mediaId);
      }
    });
  }

  void _onLongPressItem(String mediaId) {
    setState(() {
      _selectedMediaIds.add(mediaId);
    });
  }

  void _onTapItem(String mediaId, int globalIndex) {
    if (_selectionMode) {
      _toggleSelection(mediaId);
    } else {
      final state = _service.currentState;
      var targetItems = state.galleryItems;
      var targetIndex = globalIndex;

      if (_filterFavoritesOnly) {
        targetItems = state.galleryItems
            .where((e) => e.mediaService.mediaFile.isFavorite)
            .toList();
        targetIndex = targetItems.indexWhere(
          (e) => e.mediaService.mediaFile.mediaId == mediaId,
        );
        if (targetIndex == -1) targetIndex = 0;
      }

      _openViewer(targetItems, targetIndex);
    }
  }

  void _selectAll() {
    setState(() {
      final items = _service.currentState.galleryItems;
      final targetIds = <String>{};

      for (final item in items) {
        if (_filterFavoritesOnly) {
          if (item.mediaService.mediaFile.isFavorite) {
            targetIds.add(item.mediaService.mediaFile.mediaId);
          }
        } else {
          targetIds.add(item.mediaService.mediaFile.mediaId);
        }
      }

      final areAllSelected = targetIds.every(_selectedMediaIds.contains);

      if (areAllSelected) {
        _selectedMediaIds.removeAll(targetIds);
      } else {
        _selectedMediaIds.addAll(targetIds);
      }
    });
  }

  Future<void> _batchDelete() async {
    final count = _selectedMediaIds.length;
    final confirmed = await showAlertDialog(
      context,
      context.lang.deleteImageTitle,
      context.lang.deleteMemoriesBody(count),
    );

    if (!confirmed) return;

    final items = _service.currentState.galleryItems;
    for (final mediaId in _selectedMediaIds) {
      final item = items
          .where((e) => e.mediaService.mediaFile.mediaId == mediaId)
          .firstOrNull;
      if (item != null) {
        item.mediaService.fullMediaRemoval();
      }
      await twonlyDB.mediaFilesDao.deleteMediaFile(mediaId);
    }

    setState(_selectedMediaIds.clear);

    if (!mounted) return;
    showSnackbar(
      context,
      context.lang.memoriesDeleteSnackbarSuccess(count),
      level: SnackbarLevel.success,
    );
  }

  Future<void> _batchExport() async {
    final items = _service.currentState.galleryItems;

    try {
      for (final mediaId in _selectedMediaIds) {
        final item = items
            .where((e) => e.mediaService.mediaFile.mediaId == mediaId)
            .firstOrNull;
        if (item != null) {
          final media = item.mediaService;
          if (media.mediaFile.type == MediaType.video) {
            await saveVideoToGallery(media.storedPath.path);
          } else if (media.mediaFile.type == MediaType.image ||
              media.mediaFile.type == MediaType.gif) {
            final imageBytes = await media.storedPath.readAsBytes();
            await saveImageToGallery(imageBytes, createdAt: media.mediaFile.createdAt);
          }
        }
      }

      if (!mounted) return;
      showSnackbar(
        context,
        context.lang.galleryExportSuccess,
        level: SnackbarLevel.success,
      );
    } catch (e) {
      if (!mounted) return;
      showSnackbar(context, e.toString());
    }
  }

  Future<void> _batchFavorite() async {
    final items = _service.currentState.galleryItems;
    var favCount = 0;
    for (final item in items) {
      if (_selectedMediaIds.contains(item.mediaService.mediaFile.mediaId)) {
        if (item.mediaService.mediaFile.isFavorite) {
          favCount++;
        }
      }
    }
    final areAllFav =
        _selectedMediaIds.isNotEmpty && favCount == _selectedMediaIds.length;
    final targetFav = !areAllFav;

    for (final mediaId in _selectedMediaIds) {
      await twonlyDB.mediaFilesDao.updateMedia(
        mediaId,
        MediaFilesCompanion(isFavorite: Value(targetFav)),
      );
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          StreamBuilder<MemoriesState>(
            initialData: _service.currentState,
            stream: _service.watchState,
            builder: (context, snapshot) {
              final state = snapshot.data ?? _service.currentState;

              if (state.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          context.lang.memoriesEmpty,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              var months = state.months;
              var orderedByMonth = state.orderedByMonth;
              final lastYears = state.galleryItemsLastYears;

              if (_filterFavoritesOnly) {
                final filteredOrdered = <String, List<int>>{};
                final filteredMonths = <String>[];

                for (final m in months) {
                  final indices = orderedByMonth[m] ?? [];
                  final favIndices = indices.where((idx) {
                    return state
                        .galleryItems[idx]
                        .mediaService
                        .mediaFile
                        .isFavorite;
                  }).toList();

                  if (favIndices.isNotEmpty) {
                    filteredOrdered[m] = favIndices;
                    filteredMonths.add(m);
                  }
                }

                months = filteredMonths;
                orderedByMonth = filteredOrdered;
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  return DraggableScrollbar(
                    controller: _scrollController,
                    labelBuilder: (offset) {
                      final state = _service.currentState;
                      if (state.isEmpty || state.months.isEmpty) return null;

                      // Simple heuristic to find month by offset
                      double currentOffset = 56;
                      if (state.galleryItemsLastYears.isNotEmpty) {
                        currentOffset += 220;
                      }

                      final screenWidth = MediaQuery.sizeOf(context).width;
                      final itemWidth = (screenWidth - 8) / 4;
                      final itemHeight = itemWidth * (16 / 9);
                      final rowHeight = itemHeight + 2;

                      for (final month in state.months) {
                        final indices = state.orderedByMonth[month]!;
                        final totalRows = (indices.length + 3) ~/ 4;
                        final monthHeight = 44 + (totalRows * rowHeight);

                        if (offset < currentOffset + monthHeight) {
                          return month;
                        }
                        currentOffset += monthHeight;
                      }
                      return state.months.last;
                    },
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        SliverAppBar(
                          title: const Text(
                            'Memories',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          floating: true,
                          snap: true,
                          elevation: 0,
                          backgroundColor: context.color.surface,
                          actions: [
                            if (state.isLoading)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Center(
                                  child: Tooltip(
                                    message: context.lang.migrationOfMemories(
                                      state.filesToMigrate,
                                    ),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        value: state.migrationProgress,
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation(
                                          context.color.primary,
                                        ),
                                        backgroundColor: context.color.primary
                                            .withValues(alpha: 0.2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            IconButton(
                              icon: Icon(
                                _filterFavoritesOnly
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                color: _filterFavoritesOnly
                                    ? Colors.redAccent
                                    : null,
                              ),
                              onPressed: () {
                                setState(() {
                                  _filterFavoritesOnly = !_filterFavoritesOnly;
                                });
                              },
                              tooltip: _filterFavoritesOnly
                                  ? 'Show all'
                                  : 'Show favorites only',
                            ),
                          ],
                        ),
                        MemoriesFlashbackBannerComp(
                          lastYears: lastYears,
                          onOpenFlashback: (items, idx) =>
                              _openViewer(items, idx, isFlashback: true),
                        ),
                        for (final month in months) ...[
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(8, 12, 8, 6),
                            sliver: SliverToBoxAdapter(
                              child: Text(
                                month,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  mainAxisSpacing: 2,
                                  crossAxisSpacing: 2,
                                  childAspectRatio: 9 / 16,
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (context, idx) {
                                final globalIndex = orderedByMonth[month]![idx];
                                final item = state.galleryItems[globalIndex];
                                final mediaId =
                                    item.mediaService.mediaFile.mediaId;
                                final isSelected = _selectedMediaIds.contains(
                                  mediaId,
                                );

                                return MemoriesThumbnailComp(
                                  galleryItem: item,
                                  index: globalIndex,
                                  selectionMode: _selectionMode,
                                  isSelected: isSelected,
                                  activeMediaIdNotifier: _activeMediaIdNotifier,
                                  onLongPress: () => _onLongPressItem(mediaId),
                                  onTap: () => _onTapItem(mediaId, globalIndex),
                                );
                              },
                              childCount: orderedByMonth[month]!.length,
                            ),
                          ),
                        ],
                        SliverPadding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).padding.bottom + 150,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),

          if (_selectionMode)
            Builder(
              builder: (context) {
                final items = _service.currentState.galleryItems;
                var visibleCount = 0;
                var favCount = 0;

                for (final item in items) {
                  final isFav = item.mediaService.mediaFile.isFavorite;
                  if (!_filterFavoritesOnly || isFav) {
                    visibleCount++;
                  }
                  if (_selectedMediaIds.contains(
                    item.mediaService.mediaFile.mediaId,
                  )) {
                    if (isFav) {
                      favCount++;
                    }
                  }
                }

                final areAllSelected =
                    visibleCount > 0 &&
                    _selectedMediaIds.length >= visibleCount;
                final areAllFav =
                    _selectedMediaIds.isNotEmpty &&
                    favCount == _selectedMediaIds.length;

                return MemoriesSelectionToolbarComp(
                  selectedCount: _selectedMediaIds.length,
                  areAllSelected: areAllSelected,
                  areAllFav: areAllFav,
                  onSelectAll: _selectAll,
                  onExport: _batchExport,
                  onFavorite: _batchFavorite,
                  onDelete: _batchDelete,
                  onClear: () => setState(_selectedMediaIds.clear),
                );
              },
            ),
        ],
      ),
    );
  }
}
