import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/utils/misc.dart';

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
          Text(
            context.lang.settingsStorageUsed,
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
