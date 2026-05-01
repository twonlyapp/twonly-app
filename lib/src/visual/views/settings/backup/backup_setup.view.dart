import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/services/backup/common.backup.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/views/settings/backup/components/backup_setup.comp.dart';

class SetupBackupView extends StatefulWidget {
  const SetupBackupView({
    this.callBack,
    super.key,
  });

  // in case a callback is defined the callback
  // is called instead of the Navigator.pop()
  final VoidCallback? callBack;

  @override
  State<SetupBackupView> createState() => _SetupBackupViewState();
}

class _SetupBackupViewState extends State<SetupBackupView> {
  bool isLoading = false;
  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController repeatedPasswordCtrl = TextEditingController();

  Future<void> onPressedEnableTwonlySafe() async {
    setState(() {
      isLoading = true;
    });
    if (!await isSecurePassword(passwordCtrl.text)) {
      if (!mounted) return;
      final ignore = await showAlertDialog(
        context,
        context.lang.backupInsecurePassword,
        context.lang.backupInsecurePasswordDesc,
        customCancel: context.lang.backupInsecurePasswordOk,
        customOk: context.lang.backupInsecurePasswordCancel,
      );
      if (ignore) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
        return;
      }
    }

    await Future.delayed(const Duration(milliseconds: 100));
    await enableTwonlySafe(passwordCtrl.text);

    if (!mounted) return;
    setState(() {
      isLoading = false;
    });

    if (widget.callBack != null) {
      widget.callBack!();
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('twonly Backup'),
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
                context.lang.backupSelectStrongPassword,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              BackupPasswordTextField(
                controller: passwordCtrl,
                labelText: context.lang.password,
                onChanged: (value) => setState(() {}),
              ),
              PasswordRequirementText(
                text: context.lang.backupPasswordRequirement,
                showError:
                    passwordCtrl.text.length < 8 &&
                    passwordCtrl.text.isNotEmpty,
              ),
              const SizedBox(height: 5),
              BackupPasswordTextField(
                controller: repeatedPasswordCtrl,
                labelText: context.lang.passwordRepeated,
                onChanged: (value) => setState(() {}),
              ),
              PasswordRequirementText(
                text: context.lang.passwordRepeatedNotEqual,
                showError:
                    passwordCtrl.text != repeatedPasswordCtrl.text &&
                    repeatedPasswordCtrl.text.isNotEmpty,
              ),
              const SizedBox(height: 10),
              Center(
                child: OutlinedButton(
                  onPressed: () => context.push(Routes.settingsBackupServer),
                  child: Text(context.lang.backupExpertSettings),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.lang.backupNoPasswordRecovery,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 10),
              Center(
                child: FilledButton.icon(
                  onPressed:
                      (!isLoading &&
                          (passwordCtrl.text == repeatedPasswordCtrl.text &&
                                  passwordCtrl.text.length >= 8 ||
                              !kReleaseMode))
                      ? onPressedEnableTwonlySafe
                      : null,
                  icon: isLoading
                      ? const SizedBox(
                          height: 12,
                          width: 12,
                          child: CircularProgressIndicator(strokeWidth: 1),
                        )
                      : const Icon(Icons.lock_clock_rounded),
                  label: Text(
                    userService.currentUser.twonlySafeBackup == null
                        ? context.lang.backupEnableBackup
                        : context.lang.backupChangePassword,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {
                  if (widget.callBack != null) {
                    widget.callBack!();
                  } else {
                    Navigator.pop(context);
                  }
                },
                child: Text(
                  context.lang.skipForNow,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 8, color: Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
