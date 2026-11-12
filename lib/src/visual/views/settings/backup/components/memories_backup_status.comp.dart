import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';

/// One line on the state of the Memories backup: whether the plan allows it,
/// whether it is on and how much of the cloud storage it uses. Give it a new
/// key to load the usage again.
class MemoriesBackupStatusText extends StatefulWidget {
  const MemoriesBackupStatusText({super.key, this.style});

  final TextStyle? style;

  @override
  State<MemoriesBackupStatusText> createState() =>
      _MemoriesBackupStatusTextState();
}

class _MemoriesBackupStatusTextState extends State<MemoriesBackupStatusText> {
  FrbMemoriesUsage? _usage;

  @override
  void initState() {
    super.initState();
    unawaited(_loadUsage());
  }

  Future<void> _loadUsage() async {
    FrbMemoriesUsage? usage;
    try {
      usage = await RustApi.getMemoriesUsage();
    } catch (error, stackTrace) {
      Log.warn('Could not load Memories usage.', error, stackTrace);
    }
    if (mounted) setState(() => _usage = usage);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    final isFreePlan =
        context.watch<PurchasesProvider>().plan == SubscriptionPlan.Free;
    return StreamBuilder<void>(
      stream: userService.onUserUpdated,
      builder: (context, _) {
        final usage = _usage;
        return Text(
          isFreePlan
              ? lang.backupMemoriesUpgradeRequired
              : !userService.currentUser.isCloudBackupEnabled
              ? lang.settingsMemoriesBackupInactive
              : usage != null
              ? lang.settingsMemoriesBackupActiveUsage(
                  formatBytes(usage.currentBytes),
                  formatBytes(usage.maxBytes),
                )
              : lang.settingsMemoriesBackupActive,
          style: widget.style,
        );
      },
    );
  }
}
