import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:twonly/core/backup/progress.dart';
import 'package:twonly/core/bridge/wrapper/backup.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/model/json/backup.model.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/services/backup.service.dart';
import 'package:twonly/src/services/memories/memories_cloud.service.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/better_list_title.element.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/elements/pro_badge.element.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/settings/backup/backup_utils.dart';
import 'package:twonly/src/visual/views/settings/backup/components/backup_archive_subtitle.comp.dart';
import 'package:twonly/src/visual/views/settings/backup/components/backup_progress.comp.dart';
import 'package:twonly/src/visual/views/settings/backup/components/backup_schedule.comp.dart';
import 'package:twonly/src/visual/views/settings/backup/components/recovery_options.comp.dart';
import 'package:twonly/src/visual/views/settings/backup/memories_backup_detail.view.dart';

class BackupView extends StatefulWidget {
  const BackupView({super.key});

  @override
  State<BackupView> createState() => _BackupViewState();
}

class _BackupViewState extends State<BackupView> {
  bool _isLoading = false;
  CurrentBackupStatus? _backupStatus;
  FrbMemoriesUsage? _memoriesUsage;
  StreamSubscription<void>? _backupUpdateSub;
  StreamSubscription<BackupProgress>? _progressSub;
  BackupProgress? _progress;
  bool _isBackingUp = false;

  @override
  void initState() {
    super.initState();
    _loadBackupStatus();
    _backupUpdateSub = BackupService.onBackupUpdated.listen((_) {
      _loadBackupStatus();
    });
    _progressSub = RustBackupArchive.progress().listen((progress) {
      if (!mounted) return;
      final wasActive =
          _progress?.stage != null && _progress!.stage != BackupStage.idle;
      setState(() => _progress = progress);
      if (wasActive && progress.stage == BackupStage.idle) {
        unawaited(_loadBackupStatus());
      }
    });
  }

  @override
  void dispose() {
    _backupUpdateSub?.cancel();
    _progressSub?.cancel();
    super.dispose();
  }

  Future<void> _loadBackupStatus() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final status = await BackupService.getData();
    if (!mounted) return;
    FrbMemoriesUsage? memoriesUsage;
    try {
      memoriesUsage = await RustApi.getMemoriesUsage();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _backupStatus = status;
      _memoriesUsage = memoriesUsage;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentPlan = context.watch<PurchasesProvider>().plan;
    final isFreePlan = currentPlan == SubscriptionPlan.Free;
    final hasPasswordless =
        userService.currentUser.passwordLessRecovery != null;
    final hasPassword = userService.currentUser.isBackupEnabled;
    final backupActive =
        _isBackingUp ||
        (_progress != null && _progress!.stage != BackupStage.idle);

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

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: RecoveryOptionsComp(),
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
                  subtitle: BackupArchiveSubtitle(
                    date: _backupStatus?.archiveLastSuccessFull,
                    size: _backupStatus?.archiveSize,
                  ),
                  trailing: backupActive
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _backupStatus?.archiveState ==
                                  LastBackupUploadState.success
                              ? Icons.check_circle
                              : Icons.cloud_outlined,
                          color:
                              _backupStatus?.archiveState ==
                                  LastBackupUploadState.success
                              ? defaultPrimaryColor
                              : context.color.onSurfaceVariant,
                        ),
                ),

                if (backupActive)
                  BackupProgressComp(
                    progress:
                        _progress ??
                        const BackupProgress(
                          stage: BackupStage.preparing,
                          completedBytes: 0,
                          totalBytes: 0,
                        ),
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
                                    ? '${formatBytes(_memoriesUsage!.currentBytes)} / ${formatBytes(_memoriesUsage!.maxBytes)}'
                                    : '-')),
                  ),
                  trailing: isFreePlan
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ProBadge(),
                            SizedBox(width: 8),
                            Switch(
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

                if (userService.currentUser.isDeveloper)
                  const BackupScheduleTile(),

                const SizedBox(height: 32),
                Center(
                  child: MyButton(
                    variant: MyButtonVariant.secondaryDense,
                    onPressed: _isLoading || backupActive
                        ? null
                        : () async {
                            setState(() {
                              _isBackingUp = true;
                            });
                            try {
                              await BackupService.makeBackup(force: true);
                              await _loadBackupStatus();
                            } finally {
                              if (mounted) setState(() => _isBackingUp = false);
                            }
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
