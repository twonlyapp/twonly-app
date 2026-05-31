import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/database/tables/mediafiles.table.dart';
import 'package:twonly/src/services/api/mediafiles/download.api.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';

class DataAndStorageView extends StatefulWidget {
  const DataAndStorageView({super.key});

  @override
  State<DataAndStorageView> createState() => _DataAndStorageViewState();
}

class _DataAndStorageViewState extends State<DataAndStorageView> {
  Future<void> showAutoDownloadOptions(
    BuildContext context,
    ConnectivityResult connectionMode,
  ) async {
    // ignore: inference_failure_on_function_invocation
    await showDialog(
      context: context,
      builder: (context) {
        return AutoDownloadOptionsDialog(
          autoDownloadOptions:
              userService.currentUser.autoDownloadOptions ??
              defaultAutoDownloadOptions,
          connectionMode: connectionMode,
          onUpdate: () {},
        );
      },
    );
  }

  Future<void> toggleStoreInGallery() async {
    final currentlyEnabled = userService.currentUser.storeMediaFilesInGallery;
    if (currentlyEnabled) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
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
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          );
        },
      );
      if (confirm != true) {
        return;
      }
    }

    await UserService.update((u) {
      u.storeMediaFilesInGallery = !u.storeMediaFilesInGallery;
    });
  }

  Future<void> toggleAutoStoreMediaFiles() async {
    await UserService.update((u) {
      u.autoStoreAllSendUnlimitedMediaFiles =
          !u.autoStoreAllSendUnlimitedMediaFiles;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsStorageData),
      ),
      body: StreamBuilder<void>(
        stream: userService.onUserUpdated,
        builder: (context, _) {
          final autoDownloadOptions =
              userService.currentUser.autoDownloadOptions ??
              defaultAutoDownloadOptions;
          return ListView(
            children: [
              FutureBuilder<Map<MediaType, int>>(
                future: twonlyDB.mediaFilesDao.getStorageStats(),
                builder: (context, snapshot) {
                  final stats = snapshot.data ?? {};
                  final totalBytes = stats.values.fold<int>(0, (a, b) => a + b);
                  final sizeStr = formatBytes(totalBytes);

                  return ListTile(
                    title: Text(context.lang.settingsStorageManageTitle),
                    subtitle: Text(sizeStr),
                    onTap: () => context.push(Routes.settingsStorageManage),
                    trailing: const Icon(Icons.chevron_right),
                  );
                },
              ),
              const Divider(),
              ListTile(
                title: Text(context.lang.settingsStorageDataStoreInGTitle),
                onTap: toggleStoreInGallery,
                trailing: Switch.adaptive(
                  value: userService.currentUser.storeMediaFilesInGallery,
                  onChanged: (a) => toggleStoreInGallery(),
                ),
              ),
              ListTile(
                title: Text(context.lang.autoStoreAllSendUnlimitedMediaFiles),
                subtitle: Text(
                  context.lang.autoStoreAllSendUnlimitedMediaFilesSubtitle,
                  style: const TextStyle(fontSize: 9),
                ),
                onTap: toggleAutoStoreMediaFiles,
                trailing: Switch.adaptive(
                  value: userService
                      .currentUser
                      .autoStoreAllSendUnlimitedMediaFiles,
                  onChanged: (a) => toggleAutoStoreMediaFiles(),
                ),
              ),
              ListTile(
                title: Text(context.lang.settingsStorageScanGalleryTitle),
                onTap: () {
                  context.push(Routes.settingsStorageImportGallery);
                },
              ),
              const Divider(),
              ListTile(
                title: Text(
                  context.lang.settingsStorageDataMediaAutoDownload,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              ListTile(
                title: Text(context.lang.settingsStorageDataAutoDownMobile),
                subtitle: Text(
                  autoDownloadOptions[ConnectivityResult.mobile.name]!
                      .where((e) => e != 'audio')
                      .join(', '),
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: () async {
                  await showAutoDownloadOptions(
                    context,
                    ConnectivityResult.mobile,
                  );
                },
              ),
              ListTile(
                title: Text(context.lang.settingsStorageDataAutoDownWifi),
                subtitle: Text(
                  autoDownloadOptions[ConnectivityResult.wifi.name]!
                      .where((e) => e != 'audio')
                      .join(', '),
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: () async {
                  await showAutoDownloadOptions(
                    context,
                    ConnectivityResult.wifi,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class AutoDownloadOptionsDialog extends StatefulWidget {
  const AutoDownloadOptionsDialog({
    required this.autoDownloadOptions,
    required this.connectionMode,
    required this.onUpdate,
    super.key,
  });
  final Map<String, List<String>> autoDownloadOptions;
  final ConnectivityResult connectionMode;
  final void Function() onUpdate;

  @override
  State<AutoDownloadOptionsDialog> createState() =>
      _AutoDownloadOptionsDialogState();
}

class _AutoDownloadOptionsDialogState extends State<AutoDownloadOptionsDialog> {
  late Map<String, List<String>> autoDownloadOptions;

  @override
  void initState() {
    super.initState();
    autoDownloadOptions = widget.autoDownloadOptions;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.lang.settingsStorageDataMediaAutoDownload),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CheckboxListTile(
            title: const Text('Image'),
            value: autoDownloadOptions[widget.connectionMode.name]!.contains(
              DownloadMediaTypes.image.name,
            ),
            onChanged: (value) async {
              await _updateAutoDownloadSetting(DownloadMediaTypes.image, value);
            },
          ),
          CheckboxListTile(
            title: const Text('Video'),
            value: autoDownloadOptions[widget.connectionMode.name]!.contains(
              DownloadMediaTypes.video.name,
            ),
            onChanged: (value) async {
              await _updateAutoDownloadSetting(DownloadMediaTypes.video, value);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(context.lang.close),
        ),
      ],
    );
  }

  Future<void> _updateAutoDownloadSetting(
    DownloadMediaTypes type,
    bool? value,
  ) async {
    if (value == null) return;

    // Update the autoDownloadOptions based on the checkbox state
    autoDownloadOptions[widget.connectionMode.name]!.removeWhere(
      (element) => element == type.name,
    );
    if (value) {
      autoDownloadOptions[widget.connectionMode.name]!.add(type.name);
    }

    // Call the onUpdate callback to notify the parent widget

    await UserService.update((u) {
      u.autoDownloadOptions = autoDownloadOptions;
    });

    widget.onUpdate();
    setState(() {});
  }
}
