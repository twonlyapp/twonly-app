import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:twonly/src/services/api/media_received.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/utils/misc.dart';

class DataAndStorageView extends StatefulWidget {
  const DataAndStorageView({super.key});

  @override
  State<DataAndStorageView> createState() => _DataAndStorageViewState();
}

class _DataAndStorageViewState extends State<DataAndStorageView> {
  Map<String, List<String>> autoDownloadOptions = defaultAutoDownloadOptions;
  bool storeMediaFilesInGallery = true;

  @override
  void initState() {
    super.initState();
    initAsync();
  }

  Future initAsync() async {
    final user = await getUser();
    if (user == null) return;
    setState(() {
      autoDownloadOptions =
          user.autoDownloadOptions ?? defaultAutoDownloadOptions;
      storeMediaFilesInGallery = user.storeMediaFilesInGallery ?? true;
    });
  }

  void showAutoDownloadOptions(
      BuildContext context, ConnectivityResult connectionMode) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AutoDownloadOptionsDialog(
          autoDownloadOptions: autoDownloadOptions,
          connectionMode: connectionMode,
          onUpdate: () async {
            await initAsync();
          },
        );
      },
    );
  }

  void toggleStoreInGallery() async {
    await updateUserdata((u) {
      u.storeMediaFilesInGallery = !storeMediaFilesInGallery;
      return u;
    });
    initAsync();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsStorageData),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(context.lang.settingsStorageDataStoreInGTitle),
            subtitle: Text(context.lang.settingsStorageDataStoreInGSubtitle),
            onTap: toggleStoreInGallery,
            trailing: Checkbox(
              value: storeMediaFilesInGallery,
              onChanged: (a) => toggleStoreInGallery(),
            ),
          ),
          Divider(),
          ListTile(
            title: Text(
              context.lang.settingsStorageDataMediaAutoDownload,
              style: TextStyle(fontSize: 13),
            ),
          ),
          ListTile(
            title: Text(context.lang.settingsStorageDataAutoDownMobile),
            subtitle: Text(
              autoDownloadOptions[ConnectivityResult.mobile.name]!.join(", "),
              style: TextStyle(color: Colors.grey),
            ),
            onTap: () {
              showAutoDownloadOptions(context, ConnectivityResult.mobile);
            },
          ),
          ListTile(
            title: Text(context.lang.settingsStorageDataAutoDownWifi),
            subtitle: Text(
              autoDownloadOptions[ConnectivityResult.wifi.name]!.join(", "),
              style: TextStyle(color: Colors.grey),
            ),
            onTap: () {
              showAutoDownloadOptions(context, ConnectivityResult.wifi);
            },
          ),
        ],
      ),
    );
  }
}

class AutoDownloadOptionsDialog extends StatefulWidget {
  final Map<String, List<String>> autoDownloadOptions;
  final ConnectivityResult connectionMode;
  final Function() onUpdate;

  const AutoDownloadOptionsDialog({
    super.key,
    required this.autoDownloadOptions,
    required this.connectionMode,
    required this.onUpdate,
  });

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
            title: Text('Image'),
            value: autoDownloadOptions[widget.connectionMode.name]!
                .contains(DownloadMediaTypes.image.name),
            onChanged: (bool? value) async {
              await _updateAutoDownloadSetting(DownloadMediaTypes.image, value);
            },
          ),
          CheckboxListTile(
            title: Text('Video'),
            value: autoDownloadOptions[widget.connectionMode.name]!
                .contains(DownloadMediaTypes.video.name),
            onChanged: (bool? value) async {
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
      DownloadMediaTypes type, bool? value) async {
    if (value == null) return;

    // Update the autoDownloadOptions based on the checkbox state
    autoDownloadOptions[widget.connectionMode.name]!
        .removeWhere((element) => element == type.name);
    if (value) {
      autoDownloadOptions[widget.connectionMode.name]!.add(type.name);
    }

    // Call the onUpdate callback to notify the parent widget

    await updateUserdata((u) {
      u.autoDownloadOptions = autoDownloadOptions;
      return u;
    });

    widget.onUpdate();
    setState(() {});
  }
}
