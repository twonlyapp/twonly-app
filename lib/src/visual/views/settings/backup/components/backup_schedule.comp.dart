import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:twonly/src/services/backup/native_backup_schedule.dart';
import 'package:twonly/src/visual/elements/better_list_title.element.dart';

/// Developer diagnostics for the native automatic backup reservation.
class BackupScheduleTile extends StatefulWidget {
  const BackupScheduleTile({super.key});

  @override
  State<BackupScheduleTile> createState() => _BackupScheduleTileState();
}

class _BackupScheduleTileState extends State<BackupScheduleTile>
    with WidgetsBindingObserver {
  late Future<NativeBackupSchedule> _schedule;

  @override
  void initState() {
    super.initState();
    _schedule = NativeBackupScheduler.getSchedule();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _refresh() {
    setState(() => _schedule = NativeBackupScheduler.getSchedule());
  }

  String _description(NativeBackupSchedule schedule) {
    if (!schedule.executionAllowed) {
      return 'Background execution is disabled by the system.';
    }
    switch (schedule.state) {
      case NativeBackupScheduleState.scheduled:
        final next = schedule.earliestStart;
        if (next == null) return 'Scheduled; waiting for the system.';
        final locale = Localizations.localeOf(context).toString();
        final date = DateFormat.yMd(locale).add_Hms().format(next);
        if (next.isBefore(DateTime.now())) {
          return 'Eligible since: $date\nWaiting for the system to run.';
        }
        return 'Earliest start: $date\nThe system chooses the actual run time.';
      case NativeBackupScheduleState.running:
        return 'Running now.';
      case NativeBackupScheduleState.notScheduled:
        return 'No background backup check is scheduled.';
      case NativeBackupScheduleState.unavailable:
        return 'Background schedule unavailable.';
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<NativeBackupSchedule>(
    future: _schedule,
    builder: (context, snapshot) => BetterListTile(
      icon: Icons.schedule,
      text: 'Next background backup check',
      subtitle: Text(
        snapshot.connectionState == ConnectionState.waiting
            ? 'Checking schedule…'
            : _description(
                snapshot.data ??
                    const NativeBackupSchedule(
                      state: NativeBackupScheduleState.unavailable,
                    ),
              ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.refresh),
        tooltip: 'Refresh schedule',
        onPressed: _refresh,
      ),
    ),
  );
}
