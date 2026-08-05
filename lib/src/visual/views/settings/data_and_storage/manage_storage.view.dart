import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/views/settings/data_and_storage/storage_contents.view.dart';

class ManageStorageView extends StatefulWidget {
  const ManageStorageView({super.key});

  @override
  State<ManageStorageView> createState() => _ManageStorageViewState();
}

class _ManageStorageViewState extends State<ManageStorageView> {
  Map<MediaType, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await twonlyDB.mediaFilesDao.getStorageStats();
    if (mounted) {
      setState(() {
        _stats = stats;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPlan = context.watch<PurchasesProvider>().plan;
    final isFreePlan = currentPlan == SubscriptionPlan.Free;

    final totalBytes = _stats.entries
        .where((e) => e.key != MediaType.audio)
        .fold<int>(0, (a, b) => a + b.value);
    final imageBytes = _stats[MediaType.image] ?? 0;
    final videoBytes = _stats[MediaType.video] ?? 0;
    final gifBytes = _stats[MediaType.gif] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsStorageManageTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (isFreePlan || !userService.currentUser.isCloudBackupEnabled) ...[
            Card(
              elevation: 0,
              color: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: InkWell(
                onTap: () {
                  if (isFreePlan) {
                    context.push(Routes.settingsSubscription);
                  } else {
                    context.push(Routes.settingsBackup);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.cloud_queue_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          context.lang.backupFreeSpaceWithCloud,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
          ],
          Text(
            isFreePlan
                ? context.lang.settingsStorageUsed
                : context.lang.settingsStorageLocal,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            formatBytes(totalBytes),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
                  if (totalBytes == 0) return const SizedBox.shrink();

                  final maxWidth = constraints.maxWidth;
                  final imageWidth = (imageBytes / totalBytes) * maxWidth;
                  final videoWidth = (videoBytes / totalBytes) * maxWidth;
                  final gifWidth = (gifBytes / totalBytes) * maxWidth;

                  return Row(
                    children: [
                      if (imageBytes > 0)
                        Container(width: imageWidth, color: Colors.blue),
                      if (videoBytes > 0)
                        Container(width: videoWidth, color: Colors.green),
                      if (gifBytes > 0)
                        Container(width: gifWidth, color: Colors.orange),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          _StorageCategoryTile(
            title: context.lang.settingsStorageImages,
            size: formatBytes(imageBytes),
            color: Colors.blue,
          ),
          _StorageCategoryTile(
            title: context.lang.settingsStorageVideos,
            size: formatBytes(videoBytes),
            color: Colors.green,
          ),
          _StorageCategoryTile(
            title: context.lang.settingsStorageGifs,
            size: formatBytes(gifBytes),
            color: Colors.orange,
          ),
          const SizedBox(height: 32),
          Align(
            child: MyButton(
              variant: MyButtonVariant.primaryMiddle,
              onPressed: () => context.navPush(const StorageContentsView()),
              child: Text(context.lang.settingsStorageContents),
            ),
          ),
        ],
      ),
    );
  }
}

class _StorageCategoryTile extends StatelessWidget {
  const _StorageCategoryTile({
    required this.title,
    required this.size,
    required this.color,
  });
  final String title;
  final String size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            size,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
