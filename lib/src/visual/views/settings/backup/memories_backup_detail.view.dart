import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:twonly/core/bridge/database/mediafiles.dart' as rust_mediafiles;
import 'package:twonly/core/database/app/mediafiles/table.dart'
    as db_mediafiles;
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/services/memories/memories_cloud.service.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/elements/better_list_title.element.dart';
import 'package:twonly/src/visual/views/settings/backup/backup_utils.dart';
import 'package:twonly/src/visual/views/settings/components/settings_layout.dart';
import 'package:twonly/src/visual/views/settings/data_and_storage/storage_contents.view.dart';

/// Opens the Memories backup from any settings entry point: the
/// subscription page on the free plan, turns the backup on when it is off,
/// and otherwise opens [MemoriesBackupDetailView].
Future<void> openMemoriesBackup(BuildContext context) async {
  final isFreePlan =
      context.read<PurchasesProvider>().plan == SubscriptionPlan.Free;
  if (isFreePlan) {
    await context.push(Routes.settingsSubscription);
  } else if (!userService.currentUser.isCloudBackupEnabled) {
    try {
      await UserService.update((user) => user.isCloudBackupEnabled = true);
      unawaited(memoriesCloudService.checkUploads());
    } catch (error, stackTrace) {
      Log.warn('Could not update Memories backup.', error, stackTrace);
      if (context.mounted) {
        showSnackbar(context, context.lang.recoverErrorUnknown);
      }
    }
  } else {
    await context.navPush(const MemoriesBackupDetailView());
  }
}

class MemoriesBackupDetailView extends StatefulWidget {
  const MemoriesBackupDetailView({super.key});

  @override
  State<MemoriesBackupDetailView> createState() =>
      _MemoriesBackupDetailViewState();
}

class _MemoriesBackupDetailViewState extends State<MemoriesBackupDetailView> {
  FrbMemoriesUsage? _memoriesUsage;
  bool _isLoading = true;
  StreamSubscription<MemoriesBackupProgress?>? _progressSub;
  bool _wasSyncing = _isSyncing(memoriesCloudService.currentProgress);

  static bool _isSyncing(MemoriesBackupProgress? progress) =>
      progress != null && progress.totalPending > 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
    // Once an upload run finishes, the cloud holds more than before.
    _progressSub = memoriesCloudService.progressStream.listen((progress) {
      final syncing = _isSyncing(progress);
      if (_wasSyncing && !syncing) unawaited(_loadStats());
      _wasSyncing = syncing;
    });
  }

  @override
  void dispose() {
    _progressSub?.cancel();
    super.dispose();
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

  Future<void> _syncNow() async {
    final memories = await rust_mediafiles.listMediaFiles(
      input: const db_mediafiles.MediaQuery(
        filter: db_mediafiles.MediaFilter.memoriesToBackup,
      ),
      transaction: currentDatabaseSession(),
    );
    if (memories.isEmpty) {
      if (mounted) {
        showSnackbar(
          context,
          context.lang.settingsStorageSyncUpToDate,
          level: SnackbarLevel.success,
        );
      }
    } else {
      unawaited(memoriesCloudService.checkUploads());
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
    final lang = context.lang;
    return Scaffold(
      appBar: AppBar(title: Text(lang.memoriesBackupTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : StreamBuilder<MemoriesBackupProgress?>(
              initialData: memoriesCloudService.currentProgress,
              stream: memoriesCloudService.progressStream,
              builder: (context, snapshot) {
                final progress = snapshot.data;
                final syncing = _isSyncing(progress);
                return SettingsList(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: _UsageCard(
                        usage: _memoriesUsage,
                        progress: syncing ? progress : null,
                      ),
                    ),
                    BetterListTile(
                      icon: Icons.sync_rounded,
                      text: lang.settingsStorageSyncNow,
                      onTap: syncing ? null : _syncNow,
                      trailing: syncing
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator.adaptive(
                                strokeWidth: 2.5,
                              ),
                            )
                          : null,
                    ),
                    BetterListTile(
                      icon: Icons.folder_open_rounded,
                      text: lang.settingsStorageContents,
                      onTap: () => context.navPush(const StorageContentsView()),
                    ),
                    const SettingsDivider(),
                    BetterListTile(
                      icon: Icons.cloud_off_rounded,
                      color: context.color.error,
                      text: lang.settingsStorageDisableBackupAction,
                      subtitle: Text(
                        lang.memoriesBackupDisableSubtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: context.color.onSurfaceVariant,
                        ),
                      ),
                      onTap: _disableBackup,
                    ),
                  ],
                );
              },
            ),
    );
  }
}

/// How much of the cloud storage the backed up memories take, and the
/// running upload if there is one.
class _UsageCard extends StatelessWidget {
  const _UsageCard({required this.usage, required this.progress});

  final FrbMemoriesUsage? usage;

  /// Only set while memories are being uploaded.
  final MemoriesBackupProgress? progress;

  /// From this share on the bar warns that the storage is nearly full.
  static const _nearlyFull = 0.9;

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    final textTheme = Theme.of(context).textTheme;
    final mutedStyle = textTheme.bodyMedium?.copyWith(
      color: context.color.onSurfaceVariant,
    );
    final usage = this.usage;
    final ratio = usage == null || usage.maxBytes <= 0
        ? 0.0
        : (usage.currentBytes / usage.maxBytes).clamp(0.0, 1.0);
    final barColor = ratio >= _nearlyFull
        ? context.appColor(AppColor.warning)
        : context.color.primary;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: context.color.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.color.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.cloud_done_rounded,
                    color: context.color.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: usage == null
                              ? '–'
                              : formatBytes(usage.currentBytes),
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (usage != null)
                          TextSpan(
                            text:
                                '  ${lang.memoriesBackupUsageOf(formatBytes(usage.maxBytes))}',
                            style: mutedStyle,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TweenAnimationBuilder<double>(
              tween: Tween(end: ratio),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
                color: barColor,
                backgroundColor: context.color.surfaceContainerHighest,
              ),
            ),
            if (usage != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lang.memoriesBackupCount(usage.count),
                      style: mutedStyle,
                    ),
                  ),
                  Text(
                    lang.memoriesBackupPercentUsed(
                      (ratio * 100).round().toString(),
                    ),
                    style: mutedStyle,
                  ),
                ],
              ),
            ],
            if (progress case final progress?) ...[
              const SizedBox(height: 20),
              _UploadProgress(progress: progress),
            ],
          ],
        ),
      ),
    );
  }
}

class _UploadProgress extends StatelessWidget {
  const _UploadProgress({required this.progress});

  final MemoriesBackupProgress progress;

  @override
  Widget build(BuildContext context) {
    final total = progress.totalPending;
    final done =
        ((progress.currentUploaded + progress.currentUploadProgress) / total)
            .clamp(0.0, 1.0);
    final current = progress.currentUploaded + 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.cloud_upload_rounded,
              size: 18,
              color: context.color.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.lang.memoriesBackupUploading(
                  current > total ? total : current,
                  total,
                ),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Text(
              NumberFormat.percentPattern(
                Localizations.localeOf(context).toLanguageTag(),
              ).format(done),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.color.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: done,
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
          backgroundColor: context.color.surfaceContainerHighest,
        ),
      ],
    );
  }
}
