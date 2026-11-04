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
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/elements/better_list_title.element.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/views/settings/backup/backup_utils.dart';
import 'package:twonly/src/visual/views/settings/backup/components/backup_archive_subtitle.comp.dart';
import 'package:twonly/src/visual/views/settings/backup/components/backup_progress.comp.dart';
import 'package:twonly/src/visual/views/settings/backup/components/backup_schedule.comp.dart';
import 'package:twonly/src/visual/views/settings/backup/components/recovery_options.comp.dart';
import 'package:twonly/src/visual/views/settings/backup/memories_backup_detail.view.dart';
import 'package:twonly/src/visual/views/settings/components/settings_layout.dart';

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
  bool _updatingMemories = false;
  bool _loadingMemoriesUsage = false;

  @override
  void initState() {
    super.initState();
    _loadBackupStatus();
    _backupUpdateSub = BackupService.onBackupUpdated.listen(
      (_) => _loadBackupStatus(),
    );
    _progressSub = RustBackupArchive.progress().listen((progress) {
      if (!mounted) return;
      final wasActive =
          _progress != null && _progress!.stage != BackupStage.idle;
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
    CurrentBackupStatus? status;
    try {
      status = await BackupService.getData();
    } catch (error, stackTrace) {
      Log.warn('Could not load backup status.', error, stackTrace);
    }
    if (!mounted) return;
    setState(() {
      _backupStatus = status;
      _isLoading = false;
    });
    unawaited(_loadMemoriesUsage());
  }

  Future<void> _loadMemoriesUsage() async {
    if (_loadingMemoriesUsage) return;
    _loadingMemoriesUsage = true;
    FrbMemoriesUsage? memoriesUsage;
    try {
      memoriesUsage = await RustApi.getMemoriesUsage();
    } catch (error, stackTrace) {
      Log.warn('Could not load Memories usage.', error, stackTrace);
    } finally {
      _loadingMemoriesUsage = false;
    }
    if (!mounted) return;
    setState(() {
      _memoriesUsage = memoriesUsage;
    });
  }

  Future<void> _backUpNow() async {
    setState(() => _isBackingUp = true);
    try {
      await BackupService.makeBackup(force: true);
      await _loadBackupStatus();
    } catch (error, stackTrace) {
      Log.warn('Could not start backup.', error, stackTrace);
      if (mounted) showSnackbar(context, context.lang.settingsBackupFailed);
    } finally {
      if (mounted) setState(() => _isBackingUp = false);
    }
  }

  Future<void> _toggleMemories(bool enabled) async {
    if (_updatingMemories) return;
    setState(() => _updatingMemories = true);
    try {
      if (enabled) {
        await UserService.update((user) => user.isCloudBackupEnabled = true);
        unawaited(memoriesCloudService.checkUploads());
      } else {
        await promptAndDisableMemoriesBackup(context);
      }
      if (mounted) await _loadBackupStatus();
    } catch (error, stackTrace) {
      Log.warn('Could not update Memories backup.', error, stackTrace);
      if (mounted) showSnackbar(context, context.lang.recoverErrorUnknown);
    } finally {
      if (mounted) setState(() => _updatingMemories = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFreePlan =
        context.watch<PurchasesProvider>().plan == SubscriptionPlan.Free;
    final lang = context.lang;
    final backupActive =
        _isBackingUp ||
        (_progress != null && _progress!.stage != BackupStage.idle);

    return StreamBuilder<void>(
      stream: userService.onUserUpdated,
      builder: (context, _) {
        final user = userService.currentUser;
        final hasRecovery =
            user.passwordLessRecovery != null || user.isBackupEnabled;
        final passwordStatus = switch (_backupStatus?.identityState) {
          _ when _isLoading => lang.settingsStatusLoading,
          LastBackupUploadState.failed => lang.settingsBackupFailed,
          LastBackupUploadState.pending => lang.settingsBackupPending,
          LastBackupUploadState.success
              when _backupStatus?.identityLastSuccessFull == null =>
            lang.settingsBackupPending,
          LastBackupUploadState.success => lang.settingsPasswordConfigured,
          LastBackupUploadState.none => lang.settingsBackupPending,
          null => lang.settingsStatusUnavailable,
        };
        return Scaffold(
          appBar: AppBar(title: Text(lang.settingsBackup)),
          body: SettingsList(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(lang.settingsBackupIntro),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SectionHeader(
                    title: lang.backupRecoverySectionTitle,
                    description: hasRecovery
                        ? lang.backupRecoverySectionDescSome
                        : lang.backupRecoverySectionDescNone,
                    warning: !hasRecovery,
                  ),
                  if (!hasRecovery)
                    BetterListTile(
                      icon: FontAwesomeIcons.circleExclamation,
                      text: lang.settingsRecoveryMissing,
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: RecoveryOptionsComp(
                      passwordStatus: passwordStatus,
                      onReturn: _loadBackupStatus,
                    ),
                  ),
                ],
              ),
              const SettingsDivider(),
              _SectionHeader(
                title: lang.backupCloudSectionTitle,
                description: lang.backupCloudSectionDesc,
              ),
              BetterListTile(
                icon: FontAwesomeIcons.comments,
                text: lang.backupCloudContactsMessages,
                subtitle: BackupArchiveSubtitle(
                  date: _backupStatus?.archiveLastSuccessFull,
                  size: _backupStatus?.archiveSize,
                  state: _backupStatus?.archiveState,
                  loading: _isLoading,
                ),
                trailing: Icon(
                  _backupStatus?.archiveState ==
                              LastBackupUploadState.success &&
                          _backupStatus?.archiveLastSuccessFull != null
                      ? Icons.check_circle_outline
                      : _backupStatus?.archiveState ==
                            LastBackupUploadState.failed
                      ? Icons.error_outline
                      : Icons.cloud_outlined,
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
              if (!user.isBackupEnabled)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Text(lang.settingsArchiveNeedsPassword),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: MyButton(
                    variant: MyButtonVariant.secondaryMiddle,
                    onPressed:
                        _isLoading || backupActive || !user.isBackupEnabled
                        ? null
                        : _backUpNow,
                    child: Text(lang.backupTwonlySaveNow),
                  ),
                ),
              ),
              Column(
                children: [
                  BetterListTile(
                    icon: FontAwesomeIcons.photoFilm,
                    text: lang.backupCloudImagesMedia,
                    subtitle: Text(
                      isFreePlan
                          ? lang.backupMemoriesUpgradeRequired
                          : user.isCloudBackupEnabled
                          ? lang.settingsMemoriesBackupActive
                          : lang.settingsMemoriesBackupInactive,
                    ),
                    trailing: isFreePlan
                        ? const Icon(Icons.chevron_right)
                        : Switch.adaptive(
                            value: user.isCloudBackupEnabled,
                            onChanged: _updatingMemories
                                ? null
                                : _toggleMemories,
                          ),
                    onTap: _updatingMemories
                        ? null
                        : () async {
                            if (isFreePlan) {
                              await context.push(Routes.settingsSubscription);
                            } else if (user.isCloudBackupEnabled) {
                              await context.navPush(
                                const MemoriesBackupDetailView(),
                              );
                            } else {
                              await _toggleMemories(true);
                            }
                            if (mounted) await _loadBackupStatus();
                          },
                  ),
                  if (!isFreePlan &&
                      user.isCloudBackupEnabled &&
                      _memoriesUsage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          '${formatBytes(_memoriesUsage!.currentBytes)} / ${formatBytes(_memoriesUsage!.maxBytes)}',
                        ),
                      ),
                    ),
                ],
              ),
              if (user.isDeveloper) const BackupScheduleTile(),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.description,
    this.warning = false,
  });

  final String title;
  final String description;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Column(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: warning
                  ? context.color.error
                  : context.color.onSurfaceVariant,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
