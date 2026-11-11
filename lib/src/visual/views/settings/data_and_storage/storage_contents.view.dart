import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:intl/intl.dart';
import 'package:twonly/core/bridge/database/mediafiles.dart' as rust_mediafiles;
import 'package:twonly/core/database/app/mediafiles/table.dart'
    as db_mediafiles;
import 'package:twonly/core/database/app/mediafiles/table.dart' hide MediaQuery;
import 'package:twonly/src/model/database_snapshots.dart';
import 'package:twonly/src/model/media_enums.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/memories/memories.service.dart';
import 'package:twonly/src/utils/database/database_watch.dart';
import 'package:twonly/src/utils/database_values.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/delete_memories_dialog.comp.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';

enum StorageSortOption {
  size,
  newest,
  oldest,
}

/// Which memories to list, by where their copies are kept.
enum StorageFilterOption {
  all,
  localOnly,
  cloudOnly;

  bool matches(MediaFile file) => switch (this) {
    StorageFilterOption.all => true,
    StorageFilterOption.localOnly =>
      file.cloudState != CloudState.uploaded && _hasLocalFile(file),
    StorageFilterOption.cloudOnly =>
      file.cloudState == CloudState.uploaded && !_hasLocalFile(file),
  };
}

class StorageContentsView extends StatefulWidget {
  const StorageContentsView({super.key});

  @override
  State<StorageContentsView> createState() => _StorageContentsViewState();
}

class _StorageContentsViewState extends State<StorageContentsView> {
  StorageSortOption _sortOption = StorageSortOption.size;
  StorageFilterOption _filterOption = StorageFilterOption.all;
  final Set<String> _selectedMediaIds = {};
  late final Stream<List<MediaFile>> _mediaFilesStream;

  @override
  void initState() {
    super.initState();
    _mediaFilesStream = watchRustDatabase(
      (control) => rust_mediafiles
          .watchMediaFiles(
            input: const db_mediafiles.MediaQuery(
              filter: db_mediafiles.MediaFilter.stored,
            ),
            control: control,
          )
          .map(orderedMediaFiles),
    );
  }

  void _toggleSelection(String mediaId) {
    setState(() {
      if (!_selectedMediaIds.remove(mediaId)) {
        _selectedMediaIds.add(mediaId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MediaFile>>(
      stream: _mediaFilesStream,
      builder: (context, snapshot) {
        // Every memory, cloud-only ones included, so space can be freed on
        // this device and in the cloud.
        final storedFiles = [...?snapshot.data];

        switch (_sortOption) {
          case StorageSortOption.size:
            storedFiles.sort(
              (a, b) => (b.sizeInBytes ?? 0).compareTo(a.sizeInBytes ?? 0),
            );
          case StorageSortOption.newest:
            storedFiles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          case StorageSortOption.oldest:
            storedFiles.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        }

        final visibleFiles = storedFiles.where(_filterOption.matches).toList();

        final isSelecting = _selectedMediaIds.isNotEmpty;
        final allSelected =
            visibleFiles.isNotEmpty &&
            _selectedMediaIds.length >= visibleFiles.length;
        final selectedFiles = visibleFiles
            .where((file) => _selectedMediaIds.contains(file.mediaId))
            .toList();
        final selectedBytes = selectedFiles.fold<int>(
          0,
          (sum, file) => sum + (file.sizeInBytes ?? 0),
        );
        // Removing the local copy needs a finished backup for every item and
        // at least one item that still has a local file to remove.
        final canDeleteLocal =
            selectedFiles.every(
              (file) => file.cloudState == CloudState.uploaded,
            ) &&
            selectedFiles.any(_hasLocalFile);

        return Scaffold(
          appBar: AppBar(
            leading: isSelecting
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(_selectedMediaIds.clear),
                  )
                : null,
            title: isSelecting
                ? Text(
                    '${context.lang.memoriesSelectedCount(
                      _selectedMediaIds.length,
                    )} · ${formatBytes(selectedBytes)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                : Text(context.lang.settingsStorageContents),
            actions: [
              if (isSelecting)
                IconButton(
                  tooltip: allSelected
                      ? context.lang.memoriesMenuDeselectAll
                      : context.lang.memoriesMenuSelectAll,
                  icon: Icon(
                    allSelected ? Icons.deselect_rounded : Icons.select_all,
                  ),
                  onPressed: () => setState(() {
                    if (allSelected) {
                      _selectedMediaIds.clear();
                    } else {
                      _selectedMediaIds.addAll(
                        visibleFiles.map((file) => file.mediaId),
                      );
                    }
                  }),
                ),
            ],
          ),
          bottomNavigationBar: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, animation) => SizeTransition(
              sizeFactor: animation,
              alignment: Alignment.topCenter,
              child: child,
            ),
            child: isSelecting
                ? _DeleteBar(
                    onDeleteLocal: canDeleteLocal
                        ? () => _batchDelete(
                            context,
                            selectedFiles,
                            deleteCompletely: false,
                          )
                        : null,
                    onDeleteCompletely: () => _batchDelete(
                      context,
                      selectedFiles,
                      deleteCompletely: true,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator.adaptive())
              : snapshot.hasError
              ? Center(child: Text('Error: ${snapshot.error}'))
              : storedFiles.isEmpty
              ? const _EmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  // Summary, filter and sort rows come first; an empty filter
                  // result keeps them so the filter can be changed back.
                  itemCount:
                      3 + (visibleFiles.isEmpty ? 1 : visibleFiles.length),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: _SummaryCard(files: storedFiles),
                      );
                    }
                    if (index == 1) return _buildFilterChips(context);
                    if (index == 2) return _buildSortChips(context);
                    if (visibleFiles.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          context.lang.settingsStorageNoContents,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.color.onSurfaceVariant,
                          ),
                        ),
                      );
                    }
                    final file = visibleFiles[index - 3];
                    return _buildListItem(context, file, isSelecting);
                  },
                ),
        );
      },
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final options = {
      StorageFilterOption.all: context.lang.settingsStorageFilterAll,
      StorageFilterOption.localOnly: context.lang.settingsStorageLocalOnly,
      StorageFilterOption.cloudOnly: context.lang.settingsStorageCloudOnly,
    };
    return _buildChipRow(
      icon: Icons.filter_list_rounded,
      options: options,
      selected: _filterOption,
      onSelected: (option) => setState(() {
        _filterOption = option;
        // Hidden items must not be deleted along with the visible ones.
        _selectedMediaIds.clear();
      }),
    );
  }

  Widget _buildSortChips(BuildContext context) {
    final options = {
      StorageSortOption.size: context.lang.settingsStorageSortStorage,
      StorageSortOption.newest: context.lang.settingsStorageSortNewest,
      StorageSortOption.oldest: context.lang.settingsStorageSortOldest,
    };
    return _buildChipRow(
      icon: Icons.sort_rounded,
      options: options,
      selected: _sortOption,
      onSelected: (option) => setState(() => _sortOption = option),
    );
  }

  Widget _buildChipRow<T>({
    required IconData icon,
    required Map<T, String> options,
    required T selected,
    required ValueChanged<T> onSelected,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Icon(icon, size: 20, color: context.color.onSurfaceVariant),
          ),
          for (final MapEntry(key: option, value: label) in options.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                showCheckmark: false,
                shape: const StadiumBorder(),
                selected: selected == option,
                onSelected: (isSelected) {
                  if (isSelected) onSelected(option);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListItem(
    BuildContext context,
    MediaFile file,
    bool isSelecting,
  ) {
    final isSelected = _selectedMediaIds.contains(file.mediaId);
    final dateStr = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).format(file.createdAt);
    final muted = TextStyle(
      color: context.color.onSurfaceVariant,
      fontSize: 13,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected
            ? context.color.primaryContainer.withValues(alpha: 0.5)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _toggleSelection(file.mediaId),
          onLongPress: () => _toggleSelection(file.mediaId),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
            child: Row(
              children: [
                _buildThumbnail(
                  context,
                  file,
                  isSelecting: isSelecting,
                  isSelected: isSelected,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatBytes(file.sizeInBytes ?? 0),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$dateStr · ${file.type.name.toUpperCase()}',
                        style: muted,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      _StatusPill(file: file),
                    ],
                  ),
                ),
                if (!isSelecting)
                  IconButton(
                    tooltip: context.lang.delete,
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: context.color.onSurfaceVariant,
                    ),
                    onPressed: () => _deleteMemory(context, file),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(
    BuildContext context,
    MediaFile file, {
    required bool isSelecting,
    required bool isSelected,
  }) {
    final ms = MediaFileService(file);
    final isVideo = file.type == MediaType.video;

    final imgFile =
        ms.thumbnailPath.existsSync() && ms.thumbnailPath.lengthSync() > 0
        ? ms.thumbnailPath
        : ((file.type == MediaType.image || file.type == MediaType.gif) &&
              ms.storedPath.existsSync() &&
              ms.storedPath.lengthSync() > 0)
        ? ms.storedPath
        : (ms.tempPath.existsSync() && ms.tempPath.lengthSync() > 0 && !isVideo)
        ? ms.tempPath
        : null;

    return AnimatedScale(
      scale: isSelected ? 0.9 : 1,
      duration: const Duration(milliseconds: 150),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 64,
          height: 64,
          color: context.color.surfaceContainerHigh,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: imgFile != null
                    ? Image.file(
                        imgFile,
                        fit: BoxFit.cover,
                        cacheWidth: 192,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.broken_image_outlined,
                          size: 24,
                          color: context.color.onSurfaceVariant,
                        ),
                      )
                    : file.blurhash != null
                    ? BlurHash(
                        hash: file.blurhash!,
                        optimizationMode:
                            BlurHashOptimizationMode.approximation,
                      )
                    : Icon(
                        Icons.image_outlined,
                        size: 24,
                        color: context.color.onSurfaceVariant,
                      ),
              ),
              if (isVideo)
                Container(
                  decoration: BoxDecoration(
                    color: context.appColor(AppColor.mediaScrim),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 16,
                    color: context.appColor(AppColor.mediaForeground),
                  ),
                ),
              if (isSelected)
                Positioned.fill(
                  child: ColoredBox(
                    color: context.color.primary.withValues(alpha: 0.25),
                  ),
                ),
              if (isSelecting)
                Positioned(
                  top: 4,
                  right: 4,
                  child: _SelectionDot(selected: isSelected),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteMemory(BuildContext context, MediaFile file) async {
    // A cloud-only memory has no local copy left, so it can only go entirely.
    final hasCloudBackup =
        file.cloudState == CloudState.uploaded && _hasLocalFile(file);

    final deleteCompletely = await showDeleteMemoriesDialog(
      context: context,
      count: 1,
      hasCloudBackup: hasCloudBackup,
    );

    if (deleteCompletely == null) return;

    try {
      await MemoriesService.deleteMemory(
        MediaFileService(file),
        completely: deleteCompletely,
      );

      // The row may be unchanged after a local removal, while the status
      // reads the file system, so rebuild instead of waiting for the stream.
      if (mounted) setState(() {});

      if (context.mounted) {
        showSnackbar(
          context,
          deleteCompletely
              ? context.lang.memoriesDeleteSnackbarSuccess(1)
              : context.lang.memoriesRemovedLocallySnackbar(1),
          level: SnackbarLevel.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackbar(
          context,
          e.toString(),
        );
      }
    }
  }

  Future<void> _batchDelete(
    BuildContext context,
    List<MediaFile> selectedFiles, {
    required bool deleteCompletely,
  }) async {
    final selectedCount = selectedFiles.length;
    if (selectedCount == 0) return;

    // Removing the local copy keeps the cloud backup, so only the
    // irreversible variant asks first.
    if (deleteCompletely) {
      final confirmed = await showDeleteMemoriesDialog(
        context: context,
        count: selectedCount,
        hasCloudBackup: false,
      );
      if (confirmed != true) return;
    }

    try {
      for (final file in selectedFiles) {
        await MemoriesService.deleteMemory(
          MediaFileService(file),
          completely: deleteCompletely,
        );
      }

      setState(_selectedMediaIds.clear);

      if (context.mounted) {
        showSnackbar(
          context,
          deleteCompletely
              ? context.lang.memoriesDeleteSnackbarSuccess(selectedCount)
              : context.lang.memoriesRemovedLocallySnackbar(selectedCount),
          level: SnackbarLevel.success,
        );
      }
    } catch (e) {
      if (context.mounted) {
        showSnackbar(
          context,
          e.toString(),
        );
      }
    }
  }
}

bool _hasLocalFile(MediaFile file) {
  final path = MediaFileService(file).storedPath;
  return path.existsSync() && path.lengthSync() > 0;
}

/// How much the listed memories take up together.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.files});

  final List<MediaFile> files;

  @override
  Widget build(BuildContext context) {
    final totalBytes = files.fold<int>(
      0,
      (sum, file) => sum + (file.sizeInBytes ?? 0),
    );
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: context.color.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.color.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.photo_library_rounded,
                color: context.color.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatBytes(totalBytes),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.lang.settingsStorageStoredMediaCount(files.length),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.color.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Where a memory is kept: only on this device, also in the cloud, or only in
/// the cloud.
class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.file});

  final MediaFile file;

  @override
  Widget build(BuildContext context) {
    final isLocal = _hasLocalFile(file);

    final (IconData icon, String text, Color color) = switch (file.cloudState) {
      CloudState.none => (
        Icons.smartphone_rounded,
        context.lang.settingsStorageLocalOnly,
        context.color.onSurfaceVariant,
      ),
      CloudState.pending => (
        Icons.cloud_upload_rounded,
        context.lang.settingsStorageLocalOnly,
        context.color.onSurfaceVariant,
      ),
      CloudState.uploaded when isLocal => (
        Icons.cloud_done_rounded,
        context.lang.settingsStorageLocalAndCloud,
        context.appColor(AppColor.success),
      ),
      CloudState.uploaded => (
        Icons.cloud_rounded,
        context.lang.settingsStorageCloudOnly,
        context.color.primary,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionDot extends StatelessWidget {
  const _SelectionDot({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected
            ? context.color.primary
            : Colors.black.withValues(alpha: 0.25),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: selected
          ? Icon(Icons.check_rounded, size: 14, color: context.color.onPrimary)
          : null,
    );
  }
}

/// Deletes the selection either from this device only or everywhere.
class _DeleteBar extends StatelessWidget {
  const _DeleteBar({
    required this.onDeleteLocal,
    required this.onDeleteCompletely,
  });

  /// Null when part of the selection has no cloud copy, since removing it
  /// from this device would lose it for good.
  final VoidCallback? onDeleteLocal;
  final VoidCallback onDeleteCompletely;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: MyButton(
                variant: MyButtonVariant.secondaryMiddle,
                onPressed: onDeleteLocal,
                child: Text(
                  context.lang.settingsStorageDeleteLocal,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MyButton(
                variant: MyButtonVariant.errorMiddle,
                onPressed: onDeleteCompletely,
                child: Text(
                  context.lang.settingsStorageDeleteCompletely,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.color.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 36,
                color: context.color.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.lang.settingsStorageNoContents,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: context.color.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
