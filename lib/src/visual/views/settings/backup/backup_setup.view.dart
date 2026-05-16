import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/backup.service.dart';
import 'package:twonly/src/services/user.service.dart';
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
  bool _isLoading = false;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repeadedController = TextEditingController();

  Future<void> _updateBackupPassword() async {
    setState(() {
      _isLoading = true;
    });

    if (!await isSecurePassword(_passwordController.text)) {
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
            _isLoading = false;
          });
        }
        return;
      }
    }

    await Future.delayed(const Duration(milliseconds: 100));
    await BackupService.updateBackupPassword(_passwordController.text);
    await UserService.update((u) => u.isBackupEnabled = true);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
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
                controller: _passwordController,
                labelText: context.lang.password,
                onChanged: (value) => setState(() {}),
              ),
              PasswordRequirementText(
                text: context.lang.backupPasswordRequirement,
                showError:
                    _passwordController.text.length < 8 &&
                    _passwordController.text.isNotEmpty,
              ),
              const SizedBox(height: 5),
              BackupPasswordTextField(
                controller: _repeadedController,
                labelText: context.lang.passwordRepeated,
                onChanged: (value) => setState(() {}),
              ),
              PasswordRequirementText(
                text: context.lang.passwordRepeatedNotEqual,
                showError:
                    _passwordController.text != _repeadedController.text &&
                    _repeadedController.text.isNotEmpty,
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
                      (!_isLoading &&
                          (_passwordController.text ==
                                      _repeadedController.text &&
                                  _passwordController.text.length >= 8 ||
                              !kReleaseMode))
                      ? _updateBackupPassword
                      : null,
                  icon: _isLoading
                      ? const SizedBox(
                          height: 12,
                          width: 12,
                          child: CircularProgressIndicator(strokeWidth: 1),
                        )
                      : const Icon(Icons.lock_clock_rounded),
                  label: Text(
                    userService.currentUser.isBackupEnabled
                        ? context.lang.backupEnableBackup
                        : context.lang.backupChangePassword,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
