import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:twonly/src/services/backup.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/views/onboarding/setup.view.dart';
import 'package:twonly/src/visual/views/onboarding/setup/components/next_button.comp.dart';
import 'package:twonly/src/visual/views/settings/backup/components/backup_setup.comp.dart';

class BackupSetupPage extends StatefulWidget {
  const BackupSetupPage({super.key});

  @override
  State<BackupSetupPage> createState() => _BackupSetupPageState();
}

class _BackupSetupPageState extends State<BackupSetupPage> {
  bool _isLoading = false;
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _repeatedPasswordCtrl = TextEditingController();

  Future<bool> onPressedEnableTwonlySafe() async {
    setState(() {
      _isLoading = true;
    });

    if (!await isSecurePassword(_passwordCtrl.text)) {
      if (!mounted) return true;
      final ignore = await showAlertDialog(
        context,
        context.lang.backupInsecurePassword,
        context.lang.backupInsecurePasswordDesc,
        customCancel: context.lang.backupInsecurePasswordOk,
        customOk: context.lang.backupInsecurePasswordCancel,
      );
      if (!mounted) return true;
      if (ignore) {
        setState(() {
          _isLoading = false;
        });
        return true;
      }
    }

    await Future.delayed(const Duration(milliseconds: 100));
    await BackupService.updateBackupPassword(_passwordCtrl.text);

    await UserService.update((user) {
      user.currentSetupPage = SetupPages.backup.next()?.name;
    });

    if (!mounted) return true;
    setState(() {
      _isLoading = false;
    });
    return false;
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _repeatedPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPasswordValid = _passwordCtrl.text.length >= 10;
    final isRepeatedPasswordValid =
        _passwordCtrl.text == _repeatedPasswordCtrl.text;
    final canSubmit =
        !_isLoading &&
        (isPasswordValid && isRepeatedPasswordValid || !kReleaseMode);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'twonly Backup',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.lang.onboardingBackupBody,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.color.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        BackupPasswordTextField(
          controller: _passwordCtrl,
          labelText: context.lang.password,
          onChanged: (_) => setState(() {}),
        ),
        PasswordRequirementText(
          text: context.lang.backupPasswordRequirement,
          showError: _passwordCtrl.text.isNotEmpty && !isPasswordValid,
        ),
        const SizedBox(height: 8),
        BackupPasswordTextField(
          controller: _repeatedPasswordCtrl,
          labelText: context.lang.passwordRepeated,
          onChanged: (_) => setState(() {}),
        ),
        PasswordRequirementText(
          text: context.lang.passwordRepeatedNotEqual,
          showError:
              _repeatedPasswordCtrl.text.isNotEmpty && !isRepeatedPasswordValid,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const FaIcon(
              FontAwesomeIcons.circleInfo,
              size: 14,
              color: Colors.grey,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.lang.backupNoPasswordRecovery,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        NextButtonComp(
          isLoading: _isLoading,
          canSubmit: canSubmit,
          onPressed: onPressedEnableTwonlySafe,
        ),
      ],
    );
  }
}
