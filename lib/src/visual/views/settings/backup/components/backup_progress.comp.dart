import 'package:flutter/material.dart';
import 'package:twonly/core/backup/progress.dart';
import 'package:twonly/src/utils/misc.dart';

class BackupProgressComp extends StatelessWidget {
  const BackupProgressComp({required this.progress, super.key});

  final BackupProgress progress;

  @override
  Widget build(BuildContext context) {
    final label = switch (progress.stage) {
      BackupStage.idle ||
      BackupStage.preparing => context.lang.backupProgressPreparing,
      BackupStage.snapshotting => context.lang.backupProgressSnapshotting,
      BackupStage.exporting => context.lang.backupProgressExporting,
      BackupStage.compressing => context.lang.backupProgressCompressing,
      BackupStage.encrypting => context.lang.backupProgressEncrypting,
      BackupStage.uploadingIdentity =>
        context.lang.backupProgressUploadingIdentity,
      BackupStage.uploadingArchive =>
        context.lang.backupProgressUploadingArchive,
    };
    final fraction = progress.totalBytes > 0
        ? (progress.completedBytes / progress.totalBytes).clamp(0.0, 1.0)
        : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fraction == null ? label : '$label · ${(fraction * 100).floor()}%',
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: fraction),
          if (fraction != null) ...[
            const SizedBox(height: 4),
            Text(
              '${formatBytes(progress.completedBytes)} / ${formatBytes(progress.totalBytes)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
