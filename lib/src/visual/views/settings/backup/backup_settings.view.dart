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
import 'package:twonly/src/visual/views/settings/backup/backup_utils.dart';
import 'package:twonly/src/visual/views/settings/backup/components/recovery_card.comp.dart';
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
    final memoriesUsage = await rustApiProtobuf(RustApi.getMemoriesUsage(), decodeMemoriesUsage);
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
    final hasPasswordless =
        userService.currentUser.passwordLessRecovery != null;
    final hasPassword = userService.currentUser.isBackupEnabled;

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
                // --- BEREICH 1: Konto-Wiederherstellung ---
                Text(
                  context.lang.backupRecoverySectionTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    (!hasPasswordless && !hasPassword)
                        ? context.lang.backupRecoverySectionDescNone
                        : context.lang.backupRecoverySectionDescSome,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: (!hasPasswordless && !hasPassword)
                          ? context.color.error
                          : context.color.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (hasPasswordless)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: PasswordLessRecoveryStatus(),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: RecoveryCard(
                      icon: FontAwesomeIcons.shieldHeart,
                      title: context.lang.backupRecoveryOptionAFriends,
                      subtitle: context.lang.backupRecoveryOptionAMicrocopy,
                      onTap: () =>
                          context.navPush(const PasswordLessRecoverySetup()),
                    ),
                  ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: RecoveryCard(
                    isEnabled: hasPassword,
                    icon: FontAwesomeIcons.key,
                    title: context.lang.backupRecoveryOptionBPassword,
                    subtitle: hasPassword
                        ? context.lang.backupChangePassword
                        : context.lang.backupRecoveryOptionBMicrocopy,
                    onTap: () =>
                        context.push(Routes.settingsBackupSetup, extra: true),
                  ),
                ),

                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 32),

                // --- BEREICH 2: Cloud-Backup ---
                Text(
                  context.lang.backupCloudSectionTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    context.lang.backupCloudSectionDesc,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.color.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Kontakte & Nachrichten
                BetterListTile(
                  icon: FontAwesomeIcons.comments,
                  text: context.lang.backupCloudContactsMessages,
                  subtitle: Text(
                    _buildTileSubtitle(
                      _backupStatus?.archiveLastSuccessFull,
                      _backupStatus?.archiveSize,
                    ),
                  ),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                ),

                // Bilder & Medien
                BetterListTile(
                  icon: FontAwesomeIcons.photoFilm,
                  text: context.lang.backupCloudImagesMedia,
                  subtitle: Text(
                    isFreePlan
                        ? context.lang.backupMemoriesUpgradeRequired
                        : (!userService.currentUser.isCloudBackupEnabled
                              ? context.lang.backupMemoriesNotEnabled
                              : (_memoriesUsage != null
                                    ? '${formatBytes(_memoriesUsage!.currentBytes.toInt())} / ${formatBytes(_memoriesUsage!.maxBytes.toInt())}'
                                    : '-')),
                  ),
                  trailing: isFreePlan
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade700,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.star,
                                    size: 10,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    context.lang.backupCloudProBadge,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Switch(
                              value: false,
                              onChanged: null,
                            ),
                          ],
                        )
                      : Switch(
                          value: userService.currentUser.isCloudBackupEnabled,
                          onChanged: (val) async {
                            if (!val) {
                              final disabled =
                                  await promptAndDisableMemoriesBackup(context);
                              if (disabled && mounted) setState(() {});
                            } else {
                              await UserService.update(
                                (u) => u.isCloudBackupEnabled = val,
                              );
                              if (mounted) setState(() {});
                              unawaited(memoriesCloudService.checkUploads());
                            }
                          },
                        ),
                  onTap: isFreePlan
                      ? () async {
                          await context.push(Routes.settingsSubscription);
                        }
                      : () async {
                          if (userService.currentUser.isCloudBackupEnabled) {
                            await context.navPush(
                              const MemoriesBackupDetailView(),
                            );
                          } else {
                            await UserService.update(
                              (u) => u.isCloudBackupEnabled = true,
                            );
                            if (mounted) setState(() {});
                            unawaited(memoriesCloudService.checkUploads());
                          }
                        },
                ),

                const SizedBox(height: 32),
                Center(
                  child: MyButton(
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
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
