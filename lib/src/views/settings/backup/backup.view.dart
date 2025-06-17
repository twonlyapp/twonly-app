import 'package:flutter/material.dart';
import 'package:twonly/src/services/backup.identitiy.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/components/alert_dialog.dart';
import 'package:twonly/src/views/settings/backup/twonly_safe_backup.view.dart';

class BackupView extends StatefulWidget {
  const BackupView({super.key});

  @override
  State<BackupView> createState() => _BackupViewState();
}

class _BackupViewState extends State<BackupView> {
  bool _twonlyIdBackupEnabled = false;
  DateTime? _twonlyIdLastBackup;
  bool _dataBackupEnabled = false;
  DateTime? _dataBackupLastBackup;

  @override
  void initState() {
    initAsync();
    super.initState();
  }

  Future initAsync() async {
    final user = await getUser();
    if (user != null) {
      _twonlyIdBackupEnabled = user.identityBackupEnabled;
      _twonlyIdLastBackup = user.identityBackupLastBackupTime;
      _dataBackupEnabled = false;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsBackup),
      ),
      body: ListView(
        children: [
          BackupOption(
            title: 'twonly Safe',
            description:
                'Back up your twonly identity, as this is the only way to restore your account if you uninstall or lose your phone.',
            lastBackup: _twonlyIdLastBackup,
            autoBackupEnabled: _twonlyIdBackupEnabled,
            onTap: () async {
              if (_twonlyIdBackupEnabled) {
                bool disable = await showAlertDialog(context, "Are you sure?",
                    "Without an backup, you can not restore your user account.");
                if (disable) {
                  await disableTwonlySafe();
                }
              } else {
                await Navigator.push(context,
                    MaterialPageRoute(builder: (context) {
                  return TwonlyIdentityBackupView();
                }));
              }
              initAsync();
            },
          ),
          BackupOption(
            title: 'Daten-Backup (Coming Soon)',
            description:
                'This backup contains besides of your twonly-Identity also all of your media files. This backup will also be encrypted using a password chosen by the user but stored locally on the smartphone. You then have to ensure to manually copy it onto your laptop or device of your choice.',
            autoBackupEnabled: _dataBackupEnabled,
            onTap: () {},
            lastBackup: _dataBackupLastBackup,
          ),
        ],
      ),
    );
  }
}

class BackupOption extends StatelessWidget {
  final String title;
  final String description;
  final Widget? child;
  final bool autoBackupEnabled;
  final DateTime? lastBackup;
  final Function() onTap;

  const BackupOption({
    super.key,
    required this.title,
    required this.description,
    required this.autoBackupEnabled,
    required this.lastBackup,
    required this.onTap,
    this.child,
  });

  String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) {
      return "Never";
    }
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays} Days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (autoBackupEnabled) ? null : onTap,
      child: Card(
        margin: EdgeInsets.all(8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              Text(description),
              SizedBox(height: 8.0),
              (child != null) ? child! : Container(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Last backup: ${formatDateTime(lastBackup)}'),
                  (autoBackupEnabled)
                      ? OutlinedButton(
                          onPressed: onTap,
                          child: Text("Disable"),
                        )
                      : FilledButton(
                          onPressed: onTap,
                          child: Text("Enable"),
                        )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
