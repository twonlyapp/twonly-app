import 'dart:async';
import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/memories/memories_cloud.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/views/settings/backup/backup_utils.dart';
import 'package:twonly/src/visual/views/settings/data_and_storage/storage_contents.view.dart';

class MemoriesBackupDetailView extends StatefulWidget {
  const MemoriesBackupDetailView({super.key});

  @override
  State<MemoriesBackupDetailView> createState() =>
      _MemoriesBackupDetailViewState();
}

class _MemoriesBackupDetailViewState extends State<MemoriesBackupDetailView> {
  FrbMemoriesUsage? _memoriesUsage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    FrbMemoriesUsage? memoriesUsage;
    try {
      memoriesUsage = await RustApi.getMemoriesUsage();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _memoriesUsage = memoriesUsage;
        _isLoading = false;
      });
    }
  }

  Future<void> _disableBackup() async {
    final disabled = await promptAndDisableMemoriesBackup(context);
    if (disabled && mounted) {
      Navigator.pop(context);
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
                      ? '${formatBytes(_memoriesUsage!.currentBytes)} / ${formatBytes(_memoriesUsage!.maxBytes)}'
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
