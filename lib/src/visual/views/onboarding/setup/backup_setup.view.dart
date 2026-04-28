import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/services/backup/common.backup.dart';
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
  bool isLoading = false;
  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController repeatedPasswordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (userService.currentUser.twonlySafeBackup != null) {
        // twonly safe is already configured...
        UserService.update((user) {
          user.currentSetupPage = SetupPages.backup.next()?.name;
        });
      }
    });
  }

  Future<bool> onPressedEnableTwonlySafe() async {
    setState(() {
      isLoading = true;
    });

    if (!await isSecurePassword(passwordCtrl.text)) {
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
          isLoading = false;
        });
        return true;
      }
    }

    await Future.delayed(const Duration(milliseconds: 100));
    await enableTwonlySafe(passwordCtrl.text);

    await UserService.update((user) {
      user.currentSetupPage = SetupPages.backup.next()?.name;
    });

    if (!mounted) return true;
    setState(() {
      isLoading = false;
    });
    return false;
  }

  @override
  void dispose() {
    passwordCtrl.dispose();
    repeatedPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPasswordValid = passwordCtrl.text.length >= 10;
    final isRepeatedPasswordValid =
        passwordCtrl.text == repeatedPasswordCtrl.text;
    final canSubmit =
        !isLoading &&
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
          controller: passwordCtrl,
          labelText: context.lang.password,
          onChanged: (_) => setState(() {}),
        ),
        PasswordRequirementText(
          text: context.lang.backupPasswordRequirement,
          showError: passwordCtrl.text.isNotEmpty && !isPasswordValid,
        ),
        const SizedBox(height: 8),
        BackupPasswordTextField(
          controller: repeatedPasswordCtrl,
          labelText: context.lang.passwordRepeated,
          onChanged: (_) => setState(() {}),
        ),
        PasswordRequirementText(
          text: context.lang.passwordRepeatedNotEqual,
          showError:
              repeatedPasswordCtrl.text.isNotEmpty && !isRepeatedPasswordValid,
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
        const SizedBox(height: 20),
        Center(
          child: TextButton(
            onPressed: () => context.push(Routes.settingsBackupServer),
            child: Text(context.lang.backupExpertSettings),
          ),
        ),
        const SizedBox(height: 40),
        NextButtonComp(
          isLoading: isLoading,
          canSubmit: canSubmit,
          onPressed: onPressedEnableTwonlySafe,
        ),
      ],
    );
  }
}
