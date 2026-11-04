import 'package:flutter/material.dart';
import 'package:twonly/src/model/json/backup.model.dart';
import 'package:twonly/src/utils/misc.dart';

class BackupArchiveSubtitle extends StatelessWidget {
  const BackupArchiveSubtitle({
    required this.date,
    required this.size,
    required this.state,
    this.loading = false,
    super.key,
  });

  final DateTime? date;
  final int? size;
  final LastBackupUploadState? state;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    final status = switch (state) {
      _ when loading => lang.settingsStatusLoading,
      null => lang.settingsStatusUnavailable,
      LastBackupUploadState.none => lang.settingsBackupNever,
      LastBackupUploadState.pending => lang.settingsBackupPending,
      LastBackupUploadState.failed => lang.settingsBackupFailed,
      LastBackupUploadState.success when date == null =>
        lang.settingsBackupNever,
      LastBackupUploadState.success => lang.settingsBackupSaved,
    };
    final localDate = date == null
        ? null
        : formatRelativeDateTime(context, date!.toLocal());
    final details = localDate == null
        ? null
        : (size != null && size! > 0
              ? '$localDate • ${formatBytes(size!)}'
              : localDate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(status),
        if (details != null)
          Text(
            state == LastBackupUploadState.success
                ? details
                : '${lang.settingsBackupSaved}: $details',
          ),
      ],
    );
  }
}
