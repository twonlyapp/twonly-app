import 'dart:async';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart'
    as server;
import 'package:twonly/src/services/mediafiles/mediafile.service.dart';
import 'package:twonly/src/services/memories/memories_cloud.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/views/settings/data_and_storage/storage_contents.view.dart';

class MemoriesBackupDetailView extends StatefulWidget {
  const MemoriesBackupDetailView({super.key});

  @override
  State<MemoriesBackupDetailView> createState() =>
      _MemoriesBackupDetailViewState();
}

class _MemoriesBackupDetailViewState extends State<MemoriesBackupDetailView> {
  server.Response_MemoriesUsage? _memoriesUsage;
  int _cloudOnlyCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final memoriesUsage = await apiService.getMemoriesUsage();
    final cloudOnlyCount = await twonlyDB.mediaFilesDao
        .getCloudOnlyMemoriesCount();
    if (mounted) {
      setState(() {
        _memoriesUsage = memoriesUsage;
        _cloudOnlyCount = cloudOnlyCount;
        _isLoading = false;
      });
    }
  }

  Future<void> _disableBackup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.lang.settingsStorageDisableBackupTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  children: formattedText(
                    context,
                    context.lang.settingsStorageDisableBackupBody(
                      _cloudOnlyCount,
                    ),
                    textColor: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: MyButton(
                      variant: MyButtonVariant.secondaryMiddle,
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(context.lang.galleryCancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MyButton(
                      variant: MyButtonVariant.errorMiddle,
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        context.lang.settingsStorageDisableBackupBtn,
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

    if (confirmed == true) {
      try {
        await apiService.disableMemoriesBackup();
        final allMedias = await (twonlyDB.select(
          twonlyDB.mediaFiles,
        )..where((t) => t.stored.equals(true))).get();
        for (final media in allMedias) {
          final ms = MediaFileService(media);
          if (!ms.storedPath.existsSync()) {
            ms.fullMediaRemoval();
            await twonlyDB.mediaFilesDao.deleteMediaFile(media.mediaId);
          }
        }
        await twonlyDB.mediaFilesDao.updateAllMediaFiles(
          const MediaFilesCompanion(
            cloudState: Value(CloudState.none),
          ),
        );
        await UserService.update((u) => u.isCloudBackupEnabled = false);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          showSnackbar(context, e.toString());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.memoriesBackupTitle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  _memoriesUsage != null
                      ? '${formatBytes(_memoriesUsage!.currentBytes.toInt())} / ${formatBytes(_memoriesUsage!.maxBytes.toInt())}'
                      : '-',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  height: 24,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (_memoriesUsage == null ||
                            _memoriesUsage!.maxBytes == 0) {
                          return const SizedBox.shrink();
                        }

                        final maxWidth = constraints.maxWidth;
                        final current = _memoriesUsage!.currentBytes.toDouble();
                        final max = _memoriesUsage!.maxBytes.toDouble();
                        final usageWidth =
                            ((current / max).clamp(0.0, 1.0)) * maxWidth;

                        return Row(
                          children: [
                            if (usageWidth > 0)
                              Container(
                                width: usageWidth,
                                color: Colors.blue,
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                StreamBuilder<MemoriesBackupProgress?>(
                  initialData: memoriesCloudService.currentProgress,
                  stream: memoriesCloudService.progressStream,
                  builder: (context, snapshot) {
                    final progress = snapshot.data;
                    final isSyncing =
                        progress != null && progress.totalPending > 0;
                    final percent = isSyncing
                        ? ((progress.currentUploaded / progress.totalPending) +
                                  (progress.currentUploadProgress /
                                      progress.totalPending))
                              .clamp(0.0, 1.0)
                        : 0.0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (isSyncing) ...[
                          Text(
                            'Syncing: ${progress.currentUploaded} / ${progress.totalPending} files (${(percent * 100).toStringAsFixed(1)}%)',
                            style: const TextStyle(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: percent,
                          ),
                          const SizedBox(height: 24),
                        ],
                        Center(
                          child: MyButton(
                            variant: MyButtonVariant.primaryMiddle,
                            onPressed: () =>
                                context.navPush(const StorageContentsView()),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.folder_open_outlined,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(context.lang.settingsStorageContents),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: MyButton(
                            variant: MyButtonVariant.secondaryDense,
                            onPressed: isSyncing
                                ? null
                                : () async {
                                    final memories = await twonlyDB
                                        .mediaFilesDao
                                        .getMemoriesToBackup();
                                    if (memories.isEmpty) {
                                      if (context.mounted) {
                                        showSnackbar(
                                          context,
                                          context
                                              .lang
                                              .settingsStorageSyncUpToDate,
                                          level: SnackbarLevel.success,
                                        );
                                      }
                                    } else {
                                      unawaited(
                                        memoriesCloudService.checkUploads(),
                                      );
                                    }
                                  },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.sync, size: 18),
                                const SizedBox(width: 8),
                                Text(context.lang.settingsStorageSyncNow),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: MyButton(
                            variant: MyButtonVariant.secondaryDense,
                            onPressed: _disableBackup,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.cloud_off_outlined, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  context
                                      .lang
                                      .settingsStorageDisableBackupAction,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
    );
  }
}
