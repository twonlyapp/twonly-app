import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:restart_app/restart_app.dart';
import 'package:twonly/src/services/backup.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/decorations/input_text.decoration.dart';

class BackupRecoveryView extends StatefulWidget {
  const BackupRecoveryView({super.key});

  @override
  State<BackupRecoveryView> createState() => _BackupRecoveryViewState();
}

class _BackupRecoveryViewState extends State<BackupRecoveryView> {
  bool obscureText = true;
  bool isLoading = false;
  final TextEditingController usernameCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();

  Future<void> _recoverTwonlySafe() async {
    setState(() {
      isLoading = true;
    });

    final error = await BackupService.startFullBackupRecovery(
      usernameCtrl.text,
      passwordCtrl.text,
    );
    if (!mounted) return;

    if (error != null) {
      String errorMessage;
      switch (error) {
        case RecoveryError.noInternet:
          errorMessage = context.lang.recoverErrorNoInternet;
        case RecoveryError.usernameNotValid:
          errorMessage = context.lang.recoverErrorUsernameNotValid;
        case RecoveryError.passwordInvalid:
          errorMessage = context.lang.recoverErrorPasswordInvalid;
        case RecoveryError.tryAgainLater:
          errorMessage = context.lang.recoverErrorTryAgainLater;
        case RecoveryError.unkownError:
          errorMessage = context.lang.recoverErrorUnknown;
      }
      setState(() {
        isLoading = false;
      });
      return showSnackbar(context, errorMessage);
    }

    await Restart.restartApp(
      notificationTitle: context.lang.recoverSuccessTitle,
      notificationBody: context.lang.recoverSuccessBody,
      forceKill: true,
    );

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('twonly Backup ${context.lang.twonlySafeRecoverTitle}'),
        actions: [
          IconButton(
            onPressed: () async {
              await showAlertDialog(
                context,
                'twonly Backup',
                context.lang.backupTwonlySafeLongDesc,
              );
            },
            icon: const FaIcon(FontAwesomeIcons.circleInfo),
            iconSize: 18,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsetsGeometry.symmetric(
          vertical: 40,
          horizontal: 40,
        ),
        child: ListView(
          children: [
            Text(
              context.lang.twonlySafeRecoverDesc,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            TextField(
              controller: usernameCtrl,
              onChanged: (value) {
                setState(() {});
              },
              style: const TextStyle(fontSize: 17),
              decoration: getInputDecoration(
                context,
                context.lang.registerUsernameDecoration,
              ),
            ),
            const SizedBox(height: 10),
            Stack(
              children: [
                TextField(
                  controller: passwordCtrl,
                  onChanged: (value) {
                    setState(() {});
                  },
                  style: const TextStyle(fontSize: 17),
                  obscureText: obscureText,
                  decoration: getInputDecoration(
                    context,
                    context.lang.password,
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        obscureText = !obscureText;
                      });
                    },
                    icon: FaIcon(
                      obscureText
                          ? FontAwesomeIcons.eye
                          : FontAwesomeIcons.eyeSlash,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Center(
              child: FilledButton.icon(
                onPressed: (!isLoading) ? _recoverTwonlySafe : null,
                icon: isLoading
                    ? const SizedBox(
                        height: 12,
                        width: 12,
                        child: CircularProgressIndicator(strokeWidth: 1),
                      )
                    : const Icon(Icons.lock_clock_rounded),
                label: Text(context.lang.twonlySafeRecoverBtn),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
