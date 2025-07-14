import 'package:flutter/material.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/settings/backup/backup.view.dart';

class BackupNoticeCard extends StatefulWidget {
  const BackupNoticeCard({super.key});

  @override
  State<BackupNoticeCard> createState() => _BackupNoticeCardState();
}

class _BackupNoticeCardState extends State<BackupNoticeCard> {
  bool showBackupNotice = false;

  @override
  void initState() {
    initAsync();
    super.initState();
  }

  Future<void> initAsync() async {
    final user = await getUser();
    showBackupNotice = false;
    if (user != null &&
        (user.nextTimeToShowBackupNotice == null ||
            DateTime.now().isAfter(user.nextTimeToShowBackupNotice!))) {
      if (!gIsDemoUser && (user.twonlySafeBackup == null)) {
        showBackupNotice = true;
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!showBackupNotice) return Container();

    return Card(
      elevation: 4,
      margin: EdgeInsets.all(10),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.lang.backupNoticeTitle,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 5),
            Text(
              context.lang.backupNoticeDesc,
              style: const TextStyle(fontSize: 14),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await updateUserdata((user) {
                      user.nextTimeToShowBackupNotice =
                          DateTime.now().add(Duration(days: 7));
                      return user;
                    });
                    initAsync();
                  },
                  child: Text(context.lang.backupNoticeLater),
                ),
                SizedBox(width: 10),
                FilledButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BackupView(),
                      ),
                    );
                  },
                  child: Text(context.lang.backupNoticeOpenBackup),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
