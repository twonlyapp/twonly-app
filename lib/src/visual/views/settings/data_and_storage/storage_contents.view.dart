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

enum StorageSortOption {
  size,
  newest,
  oldest,
}

class StorageContentsView extends StatefulWidget {
  const StorageContentsView({super.key});

  @override
  State<StorageContentsView> createState() => _StorageContentsViewState();
}

class _StorageContentsViewState extends State<StorageContentsView> {
  StorageSortOption _sortOption = StorageSortOption.size;
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
        final allFiles = snapshot.data ?? [];
        final storedFiles = allFiles.where((file) {
          final ms = MediaFileService(file);
          return file.stored ||
              (ms.storedPath.existsSync() && ms.storedPath.lengthSync() > 0);
        }).toList();

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

        final isSelecting = _selectedMediaIds.isNotEmpty;
        final allSelected =
            storedFiles.isNotEmpty &&
            _selectedMediaIds.length >= storedFiles.length;
        final selectedBytes = storedFiles
            .where((file) => _selectedMediaIds.contains(file.mediaId))
            .fold<int>(0, (sum, file) => sum + (file.sizeInBytes ?? 0));

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
                    context.lang.memoriesSelectedCount(
                      _selectedMediaIds.length,
                    ),
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
                        storedFiles.map((file) => file.mediaId),
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
                    selectedBytes: selectedBytes,
                    onDelete: () => _batchDelete(context, storedFiles),
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
                  itemCount: storedFiles.length + 2,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: _SummaryCard(files: storedFiles),
                      );
                    }
                    if (index == 1) return _buildSortChips(context);
                    final file = storedFiles[index - 2];
                    return _buildListItem(context, file, isSelecting);
                  },
                ),
        );
      },
    );
  }

  Widget _buildSortChips(BuildContext context) {
    final options = {
      StorageSortOption.size: context.lang.settingsStorageSortStorage,
      StorageSortOption.newest: context.lang.settingsStorageSortNewest,
      StorageSortOption.oldest: context.lang.settingsStorageSortOldest,
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          for (final MapEntry(key: option, value: label) in options.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                showCheckmark: false,
                shape: const StadiumBorder(),
                selected: _sortOption == option,
                onSelected: (selected) {
                  if (selected) setState(() => _sortOption = option);
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
    final hasCloudBackup = file.cloudState == CloudState.uploaded;

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

      if (context.mounted) {
        showSnackbar(
          context,
          context.lang.memoriesDeleteSnackbarSuccess(1),
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
    List<MediaFile> allFiles,
  ) async {
    final selectedCount = _selectedMediaIds.length;
    if (selectedCount == 0) return;

    final selectedFiles = allFiles
        .where((file) => _selectedMediaIds.contains(file.mediaId))
        .toList();
    final hasAnyCloudBackup = selectedFiles.any(
      (file) => file.cloudState == CloudState.uploaded,
    );

    final deleteCompletely = await showDeleteMemoriesDialog(
      context: context,
      count: selectedCount,
      hasCloudBackup: hasAnyCloudBackup,
    );

    if (deleteCompletely == null) return;

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
          context.lang.memoriesDeleteSnackbarSuccess(selectedCount),
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
    final ms = MediaFileService(file);
    final isLocal =
        ms.storedPath.existsSync() && ms.storedPath.lengthSync() > 0;

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

/// Deletes the selection and says how much space that frees.
class _DeleteBar extends StatelessWidget {
  const _DeleteBar({required this.selectedBytes, required this.onDelete});

  final int selectedBytes;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: context.color.error,
            foregroundColor: context.color.onError,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded),
          label: Text(
            '${context.lang.delete} · ${formatBytes(selectedBytes)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
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
