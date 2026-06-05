import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/model/json/backup.model.dart';
import 'package:twonly/src/services/backup.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';

class BackupView extends StatefulWidget {
  const BackupView({super.key});

  @override
  State<BackupView> createState() => _BackupViewState();
}

class _BackupViewState extends State<BackupView> {
  bool _isLoading = false;
  CurrentBackupStatus? _backupStatus;
  StreamSubscription<void>? _backupUpdateSub;

  @override
  void initState() {
    super.initState();
    _loadBackupStatus();
    _backupUpdateSub = BackupService.onBackupUpdated.listen((_) {
      _loadBackupStatus();
    });
  }

  @override
  void dispose() {
    _backupUpdateSub?.cancel();
    super.dispose();
  }

  Future<void> _loadBackupStatus() async {
    setState(() => _isLoading = true);
    final status = await BackupService.getData();
    if (!mounted) return;
    setState(() {
      _backupStatus = status;
      _isLoading = false;
    });
  }

  String _getBackupStatusString(LastBackupUploadState status) {
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

  List<TableRow> _buildTableRows(List<(String, String)> rows) {
    return rows.map((pair) {
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
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: userService.onUserUpdated,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: Text(context.lang.settingsBackup),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                const SizedBox(height: 8),
                Text(
                  context.lang.backupTwonlySafeDesc,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                if (userService.currentUser.isBackupEnabled)
                  Column(
                    children: [
                      const SizedBox(height: 32),
                      Center(
                        child: Text(
                          context.lang.backupIdentityHeader,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Table(
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        children: _buildTableRows([
                          (
                            context.lang.backupLastBackupDate,
                            _backupStatus?.identityLastSuccessFull != null
                                ? formatDateTime(
                                    context,
                                    _backupStatus!.identityLastSuccessFull,
                                  )
                                : '-',
                          ),
                          (
                            context.lang.backupLastBackupSize,
                            _backupStatus?.identitySize != null
                                ? formatBytes(_backupStatus!.identitySize!)
                                : '-',
                          ),
                          (
                            context.lang.backupLastBackupResult,
                            _getBackupStatusString(
                              _backupStatus?.identityState ??
                                  LastBackupUploadState.none,
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          context.lang.backupArchiveHeader,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Table(
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        children: _buildTableRows([
                          (
                            context.lang.backupLastBackupDate,
                            _backupStatus?.archiveLastSuccessFull != null
                                ? formatDateTime(
                                    context,
                                    _backupStatus!.archiveLastSuccessFull,
                                  )
                                : '-',
                          ),
                          (
                            context.lang.backupLastBackupSize,
                            _backupStatus?.archiveSize != null
                                ? formatBytes(_backupStatus!.archiveSize!)
                                : '-',
                          ),
                          (
                            context.lang.backupLastBackupResult,
                            _getBackupStatusString(
                              _backupStatus?.archiveState ??
                                  LastBackupUploadState.none,
                            ),
                          ),
                        ]),
                      ),
                      const SizedBox(height: 10),
                      MyButton(
                        variant: MyButtonVariant.primaryMiddle,
                        onPressed: _isLoading
                            ? null
                            : () async {
                                setState(() {
                                  _isLoading = true;
                                });
                                await BackupService.makeBackup(force: true);
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
                  child: MyButton(
                    variant: MyButtonVariant.secondaryDense,
                    onPressed: () =>
                        context.push(Routes.settingsBackupSetup, extra: true),
                    child: Text(
                      !userService.currentUser.isBackupEnabled
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
