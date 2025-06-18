import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/model/json/userdata.dart';
import 'package:twonly/src/services/backup.identitiy.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/views/components/alert_dialog.dart';
import 'package:twonly/src/views/settings/backup/twonly_safe_backup.view.dart';

Function() gUpdateBackupView = () {};

class BackupView extends StatefulWidget {
  const BackupView({super.key});

  @override
  State<BackupView> createState() => _BackupViewState();
}

BackupServer defaultBackupServer = BackupServer(
  serverUrl: "Default",
  retentionDays: 180,
  maxBackupBytes: 2097152,
);

class _BackupViewState extends State<BackupView> {
  TwonlySafeBackup? twonlySafeBackup;
  BackupServer backupServer = defaultBackupServer;

  int activePageIdx = 0;

  final PageController pageController =
      PageController(keepPage: true, initialPage: 0);

  @override
  void initState() {
    initAsync();
    super.initState();
    gUpdateBackupView = initAsync;
  }

  @override
  void dispose() {
    gUpdateBackupView = () {};
    super.dispose();
  }

  Future initAsync() async {
    final user = await getUser();
    twonlySafeBackup = user?.twonlySafeBackup;
    backupServer = defaultBackupServer;
    if (user?.backupServer != null) {
      backupServer = user!.backupServer!;
    }
    setState(() {});
  }

  String backupStatus(LastBackupUploadState status) {
    switch (status) {
      case LastBackupUploadState.none:
        return '-';
      case LastBackupUploadState.pending:
        return 'Pending';
      case LastBackupUploadState.failed:
        return 'Failed';
      case LastBackupUploadState.success:
        return 'Success';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.settingsBackup),
      ),
      body: PageView(
        controller: pageController,
        onPageChanged: (index) {
          setState(() {
            activePageIdx = index;
          });
        },
        children: [
          BackupOption(
            title: 'twonly Safe',
            description:
                'Back up your twonly identity, as this is the only way to restore your account if you uninstall or lose your phone.',
            autoBackupEnabled: twonlySafeBackup != null,
            child: (twonlySafeBackup != null)
                ? Table(
                    defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                    children: [
                      ...[
                        (
                          "Server",
                          (backupServer.serverUrl.contains("@"))
                              ? backupServer.serverUrl.split("@")[1]
                              : backupServer.serverUrl
                                  .replaceAll("https://", "")
                        ),
                        (
                          "Max. Backup-Größe",
                          formatBytes(backupServer.maxBackupBytes)
                        ),
                        ("Speicherdauer", "${backupServer.retentionDays} Days"),
                        (
                          "Letztes Backup",
                          formatDateTime(
                              context, twonlySafeBackup!.lastBackupDone)
                        ),
                        (
                          "Backup-Größe",
                          formatBytes(twonlySafeBackup!.lastBackupSize)
                        ),
                        (
                          "Ergebnis",
                          backupStatus(twonlySafeBackup!.backupUploadState)
                        )
                      ].map((pair) {
                        return TableRow(
                          children: [
                            TableCell(
                              // padding: EdgeInsets.all(4),
                              child: Text(pair.$1),
                            ),
                            TableCell(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  pair.$2,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  )
                : null,
            onTap: () async {
              if (twonlySafeBackup != null) {
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
            autoBackupEnabled: false,
            onTap: null,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: true,
        showUnselectedLabels: true,
        unselectedIconTheme: IconThemeData(
            color: Theme.of(context).colorScheme.inverseSurface.withAlpha(150)),
        selectedIconTheme:
            IconThemeData(color: Theme.of(context).colorScheme.inverseSurface),
        items: [
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.vault, size: 17),
            label: "twonly Safe",
          ),
          BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.boxArchive, size: 17),
            label: "Daten-Backup",
          ),
        ],
        onTap: (int index) {
          activePageIdx = index;
          setState(() {
            pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 100),
              curve: Curves.bounceIn,
            );
          });
        },
        currentIndex: activePageIdx,
        // ),
      ),
    );
  }
}

class BackupOption extends StatelessWidget {
  final String title;
  final String description;
  final Widget? child;
  final bool autoBackupEnabled;
  final Function()? onTap;

  const BackupOption({
    super.key,
    required this.title,
    required this.description,
    required this.autoBackupEnabled,
    required this.onTap,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (autoBackupEnabled) ? null : onTap,
      child: Card(
        margin: EdgeInsets.all(16.0),
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
              Expanded(child: Container()),
              Center(
                child: (autoBackupEnabled)
                    ? OutlinedButton(
                        onPressed: onTap,
                        child: Text("Disable"),
                      )
                    : FilledButton(
                        onPressed: onTap,
                        child: Text("Enable"),
                      ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
