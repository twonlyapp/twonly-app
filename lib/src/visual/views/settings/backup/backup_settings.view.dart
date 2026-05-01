import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/model/json/userdata.model.dart';
import 'package:twonly/src/services/backup/create.backup.dart';
import 'package:twonly/src/utils/misc.dart';

class BackupView extends StatefulWidget {
  const BackupView({super.key});

  @override
  State<BackupView> createState() => _BackupViewState();
}

BackupServer _defaultBackupServer = BackupServer(
  serverUrl: 'Default',
  retentionDays: 180,
  maxBackupBytes: 2097152,
);

class _BackupViewState extends State<BackupView> {
  bool _isLoading = false;

  String _backupStatus(LastBackupUploadState status) {
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: userService.onUserUpdated,
      builder: (context, _) {
        final backupServer =
            userService.currentUser.backupServer ?? _defaultBackupServer;
        return Scaffold(
          appBar: AppBar(
            title: Text(context.lang.settingsBackup),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  context.lang.backupTwonlySafeDesc,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (userService.currentUser.twonlySafeBackup != null)
                  Column(
                    children: [
                      const SizedBox(height: 32),
                      Table(
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        children: [
                          ...[
                            (
                              context.lang.backupServer,
                              (backupServer.serverUrl.contains('@'))
                                  ? backupServer.serverUrl.split('@')[1]
                                  : backupServer.serverUrl.replaceAll(
                                      'https://',
                                      '',
                                    ),
                            ),
                            (
                              context.lang.backupMaxBackupSize,
                              formatBytes(backupServer.maxBackupBytes),
                            ),
                            (
                              context.lang.backupStorageRetention,
                              '${backupServer.retentionDays} Days',
                            ),
                            (
                              context.lang.backupLastBackupDate,
                              formatDateTime(
                                context,
                                userService
                                    .currentUser
                                    .twonlySafeBackup!
                                    .lastBackupDone,
                              ),
                            ),
                            (
                              context.lang.backupLastBackupSize,
                              formatBytes(
                                userService
                                    .currentUser
                                    .twonlySafeBackup!
                                    .lastBackupSize,
                              ),
                            ),
                            (
                              context.lang.backupLastBackupResult,
                              _backupStatus(
                                userService
                                    .currentUser
                                    .twonlySafeBackup!
                                    .backupUploadState,
                              ),
                            ),
                          ].map((pair) {
                            return TableRow(
                              children: [
                                TableCell(
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
                        onPressed: _isLoading
                            ? null
                            : () async {
                                setState(() {
                                  _isLoading = true;
                                });
                                await performTwonlySafeBackup(force: true);
                                setState(() {
                                  _isLoading = false;
                                });
                              },
                        child: Text(context.lang.backupTwonlySaveNow),
                      ),
                    ],
                  ),
                const SizedBox(height: 32),
                Center(
                  child: FilledButton(
                    onPressed: () =>
                        context.push(Routes.settingsBackupSetup, extra: true),
                    child: Text(
                      userService.currentUser.twonlySafeBackup == null
                          ? context.lang.backupEnableBackup
                          : context.lang.backupChangePassword,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
