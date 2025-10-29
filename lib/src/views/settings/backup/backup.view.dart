import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/model/json/userdata.dart';
import 'package:twonly/src/services/twonly_safe/create_backup.twonly_safe.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/views/settings/backup/twonly_safe_backup.view.dart';

void Function() gUpdateBackupView = () {};

class BackupView extends StatefulWidget {
  const BackupView({super.key});

  @override
  State<BackupView> createState() => _BackupViewState();
}

BackupServer defaultBackupServer = BackupServer(
  serverUrl: 'Default',
  retentionDays: 180,
  maxBackupBytes: 2097152,
);

class _BackupViewState extends State<BackupView> {
  bool isLoading = false;

  int activePageIdx = 0;

  final PageController pageController = PageController();

  @override
  void initState() {
    super.initState();
    unawaited(initAsync());
    gUpdateBackupView = initAsync;
  }

  @override
  void dispose() {
    gUpdateBackupView = () {};
    super.dispose();
  }

  Future<void> initAsync() async {
    setState(() {});
  }

  String backupStatus(LastBackupUploadState status) {
    switch (status) {
      case LastBackupUploadState.none:
        return context.lang.backupPending;
      case LastBackupUploadState.pending:
        return context.lang.backupPending;
      case LastBackupUploadState.failed:
        return context.lang.backupFailed;
      case LastBackupUploadState.success:
        return context.lang.backupSuccess;
    }
  }

  Future<void> changeTwonlySafePassword() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return const TwonlyIdentityBackupView(
            isPasswordChangeOnly: true,
          );
        },
      ),
    );
    setState(() {
      // gUser was updated
    });
  }

  @override
  Widget build(BuildContext context) {
    final backupServer = gUser.backupServer ?? defaultBackupServer;
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
            title: 'twonly Backup',
            description: context.lang.backupTwonlySafeDesc,
            bottomButton: FilledButton(
              onPressed: changeTwonlySafePassword,
              child: Text(context.lang.backupChangePassword),
            ),
            child: (gUser.twonlySafeBackup == null)
                ? null
                : Column(
                    children: [
                      Table(
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        children: [
                          ...[
                            (
                              context.lang.backupServer,
                              (backupServer.serverUrl.contains('@'))
                                  ? backupServer.serverUrl.split('@')[1]
                                  : backupServer.serverUrl
                                      .replaceAll('https://', '')
                            ),
                            (
                              context.lang.backupMaxBackupSize,
                              formatBytes(backupServer.maxBackupBytes)
                            ),
                            (
                              context.lang.backupStorageRetention,
                              '${backupServer.retentionDays} Days'
                            ),
                            (
                              context.lang.backupLastBackupDate,
                              formatDateTime(
                                context,
                                gUser.twonlySafeBackup!.lastBackupDone,
                              )
                            ),
                            (
                              context.lang.backupLastBackupSize,
                              formatBytes(
                                gUser.twonlySafeBackup!.lastBackupSize,
                              )
                            ),
                            (
                              context.lang.backupLastBackupResult,
                              backupStatus(
                                gUser.twonlySafeBackup!.backupUploadState,
                              )
                            ),
                          ].map((pair) {
                            return TableRow(
                              children: [
                                TableCell(
                                  // padding: EdgeInsets.all(4),
                                  child: Text(pair.$1),
                                ),
                                TableCell(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
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
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                setState(() {
                                  isLoading = true;
                                });
                                await performTwonlySafeBackup(force: true);
                                setState(() {
                                  isLoading = false;
                                });
                              },
                        child: Text(context.lang.backupTwonlySaveNow),
                      ),
                    ],
                  ),
          ),
          BackupOption(
            title: '${context.lang.backupData} (Coming Soon)',
            description: context.lang.backupDataDesc,
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: true,
        showUnselectedLabels: true,
        unselectedIconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.inverseSurface.withAlpha(150),
        ),
        selectedIconTheme:
            IconThemeData(color: Theme.of(context).colorScheme.inverseSurface),
        items: [
          const BottomNavigationBarItem(
            icon: FaIcon(FontAwesomeIcons.vault, size: 17),
            label: 'twonly Backup',
          ),
          BottomNavigationBarItem(
            icon: const FaIcon(FontAwesomeIcons.boxArchive, size: 17),
            label: context.lang.backupData,
          ),
        ],
        onTap: (int index) async {
          activePageIdx = index;
          await pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 100),
            curve: Curves.bounceIn,
          );
          if (mounted) setState(() {});
        },
        currentIndex: activePageIdx,
        // ),
      ),
    );
  }
}

class BackupOption extends StatelessWidget {
  const BackupOption({
    required this.title,
    required this.description,
    this.bottomButton,
    super.key,
    this.child,
  });
  final String title;
  final String description;
  final Widget? child;
  final Widget? bottomButton;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(description),
            const SizedBox(height: 8),
            if (child != null) child! else Container(),
            Expanded(child: Container()),
            if (bottomButton != null) Center(child: bottomButton),
          ],
        ),
      ),
    );
  }
}
