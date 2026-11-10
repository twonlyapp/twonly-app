import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/settings/backup/components/memories_backup_status.comp.dart';
import 'package:twonly/src/visual/views/settings/backup/memories_backup_detail.view.dart';
import 'package:twonly/src/visual/views/settings/components/location_setting.dart';
import 'package:twonly/src/visual/views/settings/components/settings_layout.dart';

/// Every setting that concerns Memories: the cloud backup, how media is
/// saved and how memories are imported.
class MemoriesSettingsView extends StatefulWidget {
  const MemoriesSettingsView({super.key});

  @override
  State<MemoriesSettingsView> createState() => _MemoriesSettingsViewState();
}

class _MemoriesSettingsViewState extends State<MemoriesSettingsView> {
  Key _backupStatusKey = UniqueKey();
  bool _updatingBackup = false;
  bool _updatingLocation = false;

  Future<void> _openBackup() async {
    if (_updatingBackup) return;
    setState(() => _updatingBackup = true);
    try {
      await openMemoriesBackup(context);
    } finally {
      if (mounted) {
        setState(() {
          _updatingBackup = false;
          _backupStatusKey = UniqueKey();
        });
      }
    }
  }

  Future<void> _toggleStoreInGallery() async {
    if (userService.currentUser.storeMediaFilesInGallery) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.lang.galleryDisableWarningTitle),
          content: Text(context.lang.galleryDisableWarningBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.lang.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                context.lang.galleryDisableWarningConfirm,
                style: TextStyle(color: context.color.error),
              ),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }
    await UserService.update(
      (u) => u.storeMediaFilesInGallery = !u.storeMediaFilesInGallery,
    );
  }

  Future<void> _toggleAutoStore() => UserService.update(
    (u) => u.autoStoreAllSendUnlimitedMediaFiles =
        !u.autoStoreAllSendUnlimitedMediaFiles,
  );

  Future<void> _toggleLocation() async {
    if (_updatingLocation) return;
    setState(() => _updatingLocation = true);
    await toggleLocationSetting(
      context,
      enabled: (user) => user.storeLocationInMemories,
      set: (user, value) => user.storeLocationInMemories = value,
    );
    if (mounted) setState(() => _updatingLocation = false);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.lang;
    final subtitleStyle = TextStyle(
      fontSize: 13,
      color: context.color.onSurfaceVariant,
    );

    return Scaffold(
      appBar: AppBar(title: Text(lang.settingsMemories)),
      body: StreamBuilder<void>(
        stream: userService.onUserUpdated,
        builder: (context, _) {
          final user = userService.currentUser;
          return SettingsList(
            children: [
              SettingsSectionTitle(lang.settingsBackup),
              ListTile(
                title: Text(lang.memoriesBackupTitle),
                subtitle: MemoriesBackupStatusText(
                  key: _backupStatusKey,
                  style: subtitleStyle,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: _updatingBackup
                    ? null
                    : _openBackup,
              ),
              const SettingsDivider(),
              SettingsSectionTitle(lang.settingsMemoriesSectionSaving),
              ListTile(
                title: Text(lang.settingsStorageDataStoreInGTitle),
                subtitle: Text(
                  lang.settingsStorageDataStoreInGSubtitle,
                  style: subtitleStyle,
                ),
                onTap: _toggleStoreInGallery,
                trailing: Switch.adaptive(
                  value: user.storeMediaFilesInGallery,
                  onChanged: (_) => _toggleStoreInGallery(),
                ),
              ),
              ListTile(
                title: Text(lang.autoStoreAllSendUnlimitedMediaFiles),
                subtitle: Text(
                  lang.autoStoreAllSendUnlimitedMediaFilesSubtitle,
                  style: subtitleStyle,
                ),
                onTap: _toggleAutoStore,
                trailing: Switch.adaptive(
                  value: user.autoStoreAllSendUnlimitedMediaFiles,
                  onChanged: (_) => _toggleAutoStore(),
                ),
              ),
              ListTile(
                title: Text(lang.memoryLocationTitle),
                subtitle: Text(
                  lang.memoryLocationSubtitle,
                  style: subtitleStyle,
                ),
                onTap: _updatingLocation ? null : _toggleLocation,
                trailing: Switch.adaptive(
                  value: user.storeLocationInMemories,
                  onChanged: _updatingLocation
                      ? null
                      : (_) => _toggleLocation(),
                ),
              ),
              const SettingsDivider(),
              SettingsSectionTitle(lang.memoryImporterTitle),
              ListTile(
                title: Text(lang.settingsStorageScanGalleryTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.settingsMemoriesImportGallery),
              ),
              ListTile(
                title: Text(lang.memoryImporterFromOtherApps),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.settingsMemoriesImporters),
              ),
            ],
          );
        },
      ),
    );
  }
}
