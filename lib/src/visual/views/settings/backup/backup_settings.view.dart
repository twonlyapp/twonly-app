import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/model/json/backup.model.dart';
import 'package:twonly/src/model/protobuf/api/websocket/server_to_client.pb.dart'
    as server;
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/services/backup.service.dart';
import 'package:twonly/src/services/memories/memories_cloud.service.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/better_list_title.element.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/views/settings/backup/memories_backup_detail.view.dart';
import 'package:twonly/src/visual/views/settings/backup/passwordless_recovery/components/status.passwordless_recovery.comp.dart';
import 'package:twonly/src/visual/views/settings/backup/passwordless_recovery/setup.passwordless_recovery.view.dart';

class BackupView extends StatefulWidget {
  const BackupView({super.key});

  @override
  State<BackupView> createState() => _BackupViewState();
}

class _BackupViewState extends State<BackupView> {
  bool _isLoading = false;
  CurrentBackupStatus? _backupStatus;
  server.Response_MemoriesUsage? _memoriesUsage;
  StreamSubscription<void>? _backupUpdateSub;

  @override
  void initState() {
    super.initState();
    _loadBackupStatus();
    _backupUpdateSub = BackupService.onBackupUpdated.listen((_) {
      _loadBackupStatus();
    });
  }

  @override
  void dispose() {
    _backupUpdateSub?.cancel();
    super.dispose();
  }

  Future<void> _loadBackupStatus() async {
    setState(() => _isLoading = true);
    final status = await BackupService.getData();
    final memoriesUsage = await apiService.getMemoriesUsage();
    if (!mounted) return;
    setState(() {
      _backupStatus = status;
      _memoriesUsage = memoriesUsage;
      _isLoading = false;
    });
  }

  String _buildTileSubtitle(DateTime? date, int? size) {
    if (date == null) return '-';
    final dateStr = formatRelativeDateTime(context, date);
    if (size != null && size > 0) {
      return '$dateStr • ${formatBytes(size)}';
    }
    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    final currentPlan = context.watch<PurchasesProvider>().plan;
    final isFreePlan = currentPlan == SubscriptionPlan.Free;

    return StreamBuilder<void>(
      stream: userService.onUserUpdated,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(context.lang.settingsBackup),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ListView(
              children: [
                if (userService.currentUser.passwordLessRecovery != null)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: PasswordLessRecoveryStatus(),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: MyButton(
                        variant: MyButtonVariant.primaryMiddle,
                        onPressed: () =>
                            context.navPush(const PasswordLessRecoverySetup()),
                        child: Text(context.lang.passwordlessRecoveryEnableBtn),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    context.lang.backupTwonlySafeDesc,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.color.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 8),

                if (userService.currentUser.isBackupEnabled) ...[
                  // 1. Identity tile
                  BetterListTile(
                    icon: FontAwesomeIcons.userCheck,
                    text: context.lang.backupIdentityHeader,
                    subtitle: Text(
                      _buildTileSubtitle(
                        _backupStatus?.identityLastSuccessFull,
                        _backupStatus?.identitySize,
                      ),
                    ),
                  ),

                  // 2. Contacts & Messages tile
                  BetterListTile(
                    icon: FontAwesomeIcons.comments,
                    text: context.lang.backupArchiveHeader,
                    subtitle: Text(
                      _buildTileSubtitle(
                        _backupStatus?.archiveLastSuccessFull,
                        _backupStatus?.archiveSize,
                      ),
                    ),
                  ),

                  // 3. Memories tile
                  BetterListTile(
                    icon: FontAwesomeIcons.photoFilm,
                    text: context.lang.memoriesBackupTitle,
                    subtitle: Text(
                      isFreePlan
                          ? context.lang.backupMemoriesUpgradeRequired
                          : (!userService.currentUser.isCloudBackupEnabled
                                ? context.lang.backupMemoriesNotEnabled
                                : (_memoriesUsage != null
                                      ? '${formatBytes(_memoriesUsage!.currentBytes.toInt())} / ${formatBytes(_memoriesUsage!.maxBytes.toInt())}'
                                      : '-')),
                    ),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      color: context.color.onSurfaceVariant,
                    ),
                    onTap: () async {
                      if (isFreePlan) {
                        await context.push(Routes.settingsSubscription);
                      } else if (!userService
                          .currentUser
                          .isCloudBackupEnabled) {
                        await UserService.update(
                          (u) => u.isCloudBackupEnabled = true,
                        );
                        if (mounted) setState(() {});
                        unawaited(memoriesCloudService.checkUploads());
                      } else {
                        await context.navPush(const MemoriesBackupDetailView());
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 20),
                ],

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (userService.currentUser.isBackupEnabled) ...[
                        MyButton(
                          variant: MyButtonVariant.secondaryDense,
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  await BackupService.makeBackup(force: true);
                                  await _loadBackupStatus();
                                },
                          child: Text(context.lang.backupTwonlySaveNow),
                        ),
                        const SizedBox(width: 12),
                      ],
                      MyButton(
                        variant: MyButtonVariant.secondaryDense,
                        onPressed: () => context.push(
                          Routes.settingsBackupSetup,
                          extra: true,
                        ),
                        child: Text(
                          !userService.currentUser.isBackupEnabled
                              ? context.lang.backupEnableBackup
                              : context.lang.backupChangePassword,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
