import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:intl/intl.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
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
    _mediaFilesStream = twonlyDB.mediaFilesDao.watchAllStoredMediaFiles();
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

        // Sort the files
        switch (_sortOption) {
          case StorageSortOption.size:
            storedFiles.sort(
              (a, b) =>
                  (b.sizeInBytes ?? 0).compareTo(a.sizeInBytes ?? 0),
            );
          case StorageSortOption.newest:
            storedFiles.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          case StorageSortOption.oldest:
            storedFiles.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        }

        final isSelecting = _selectedMediaIds.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            leading: isSelecting
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(_selectedMediaIds.clear);
                    },
                  )
                : null,
            title: isSelecting
                ? Text(
                    context.lang.memoriesSelectedCount(_selectedMediaIds.length),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  )
                : Text(context.lang.settingsStorageContents),
            actions: [
              if (isSelecting)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _batchDelete(context, storedFiles),
                ),
            ],
          ),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : snapshot.hasError
                  ? Center(child: Text('Error: ${snapshot.error}'))
                  : storedFiles.isEmpty
                      ? Center(
                          child: Text(
                            context.lang.settingsStorageNoContents,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(color: Colors.grey),
                          ),
                        )
                      : Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      _buildChip(
                                        StorageSortOption.size,
                                        context.lang.settingsStorageSortStorage,
                                      ),
                                      const SizedBox(width: 8),
                                      _buildChip(
                                        StorageSortOption.newest,
                                        context.lang.settingsStorageSortNewest,
                                      ),
                                      const SizedBox(width: 8),
                                      _buildChip(
                                        StorageSortOption.oldest,
                                        context.lang.settingsStorageSortOldest,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            Expanded(
                              child: ListView.builder(
                                itemCount: storedFiles.length,
                                itemBuilder: (context, index) {
                                  final file = storedFiles[index];
                                  return _buildListItem(context, file);
                                },
                              ),
                            ),
                          ],
                        ),
        );
      },
    );
  }

  Widget _buildChip(StorageSortOption option, String label) {
    final isSelected = _sortOption == option;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _sortOption = option;
          });
        }
      },
    );
  }

  Widget _buildListItem(BuildContext context, MediaFile file) {
    final sizeStr = formatBytes(file.sizeInBytes ?? 0);
    final dateStr = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    ).format(file.createdAt);

    final isSelected = _selectedMediaIds.contains(file.mediaId);
    final isSelecting = _selectedMediaIds.isNotEmpty;

    final ms = MediaFileService(file);
    final hasStored = file.stored ||
        (ms.storedPath.existsSync() && ms.storedPath.lengthSync() > 0);

    final IconData statusIcon;
    final String statusText;

    switch (file.cloudState) {
      case CloudState.none:
        statusIcon = Icons.cloud_off_outlined;
        statusText = context.lang.settingsStorageLocalOnly;
      case CloudState.pending:
        statusIcon = Icons.cloud_upload_outlined;
        statusText = context.lang.settingsStorageLocalOnly;
      case CloudState.uploaded:
        if (hasStored) {
          statusIcon = Icons.cloud_done_outlined;
          statusText = context.lang.settingsStorageLocalAndCloud;
        } else {
          statusIcon = Icons.cloud_outlined;
          statusText = context.lang.settingsStorageCloudOnly;
        }
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minLeadingWidth: 0,
      horizontalTitleGap: 8,
      selected: isSelected,
      onTap: () => _toggleSelection(file.mediaId),
      onLongPress: () => _toggleSelection(file.mediaId),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelecting) ...[
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: isSelected,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (val) => _toggleSelection(file.mediaId),
              ),
            ),
            const SizedBox(width: 8),
          ],
          _buildThumbnail(context, file),
        ],
      ),
      title: Text('$sizeStr • $dateStr'),
      subtitle: Row(
        children: [
          Text(
            file.type.name.toUpperCase(),
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Icon(statusIcon, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
      trailing: isSelecting
          ? null
          : IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _deleteMemory(context, file),
            ),
    );
  }

  Widget _buildThumbnail(BuildContext context, MediaFile file) {
    final ms = MediaFileService(file);
    final isVideo = file.type == MediaType.video;

    final imgFile = ms.thumbnailPath.existsSync() &&
            ms.thumbnailPath.lengthSync() > 0
        ? ms.thumbnailPath
        : ((file.type == MediaType.image || file.type == MediaType.gif) &&
                ms.storedPath.existsSync() &&
                ms.storedPath.lengthSync() > 0)
        ? ms.storedPath
        : (ms.tempPath.existsSync() &&
                ms.tempPath.lengthSync() > 0 &&
                !isVideo)
        ? ms.tempPath
        : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 60,
        height: 60,
        color: Colors.grey.withValues(alpha: 0.1),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: imgFile != null
                  ? Image.file(
                      imgFile,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image_outlined,
                        size: 24,
                        color: Colors.grey,
                      ),
                    )
                  : file.blurhash != null
                      ? BlurHash(
                          hash: file.blurhash!,
                          optimizationMode:
                              BlurHashOptimizationMode.approximation,
                        )
                      : const Icon(
                          Icons.image_outlined,
                          size: 24,
                          color: Colors.grey,
                        ),
            ),
            if (isVideo)
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(4),
                child: const Icon(
                  Icons.play_arrow,
                  size: 16,
                  color: Colors.white,
                ),
              ),
          ],
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
      MediaFileService(file).fullMediaRemoval();
      await twonlyDB.mediaFilesDao.deleteMediaFile(file.mediaId);

      if (deleteCompletely) {
        unawaited(apiService.deleteMemory(file.mediaId));
      }

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

  Future<void> _batchDelete(BuildContext context, List<MediaFile> allFiles) async {
    final selectedCount = _selectedMediaIds.length;
    if (selectedCount == 0) return;

    final selectedFiles = allFiles
        .where((file) => _selectedMediaIds.contains(file.mediaId))
        .toList();
    final hasAnyCloudBackup =
        selectedFiles.any((file) => file.cloudState == CloudState.uploaded);

    final deleteCompletely = await showDeleteMemoriesDialog(
      context: context,
      count: selectedCount,
      hasCloudBackup: hasAnyCloudBackup,
    );

    if (deleteCompletely == null) return;

    try {
      for (final file in selectedFiles) {
        MediaFileService(file).fullMediaRemoval();
        await twonlyDB.mediaFilesDao.deleteMediaFile(file.mediaId);

        if (deleteCompletely) {
          unawaited(apiService.deleteMemory(file.mediaId));
        }
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
