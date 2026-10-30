import 'package:flutter/material.dart';
import 'package:twonly/src/utils/misc.dart';

class BackupArchiveSubtitle extends StatelessWidget {
  const BackupArchiveSubtitle({
    required this.date,
    required this.size,
    super.key,
  });

  final DateTime? date;
  final int? size;

  @override
  Widget build(BuildContext context) {
    if (date == null) return const Text('-');
    final localDate = formatRelativeDateTime(context, date!.toLocal());
    return Text(
      size != null && size! > 0
          ? '$localDate • ${formatBytes(size!)}'
          : localDate,
    );
  }
}
