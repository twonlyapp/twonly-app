import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:restart_app/restart_app.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/views/onboarding/recover_password.view.dart';
import 'package:twonly/src/visual/views/settings/help/contact_us.view.dart';

class CriticalErrorView extends StatefulWidget {
  const CriticalErrorView({super.key});

  @override
  State<CriticalErrorView> createState() => _CriticalErrorViewState();
}

class _CriticalErrorViewState extends State<CriticalErrorView> {
  bool _isResetting = false;

  Future<void> _registerNewAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.lang.registerNewAccount),
        content: const Text(
          'This will delete all local account data, including messages, media, '
          'and saved credentials. You can then register a new account. '
          'Your current account will remain on the server.',
        ),
        actions: [
          MyButton(
            variant: MyButtonVariant.text,
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.lang.cancel),
          ),
          MyButton(
            variant: MyButtonVariant.error,
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.lang.registerNewAccount),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isResetting = true);
    try {
      await deleteLocalUserData(removeCredentials: true);
      if (!mounted) return;
      final restarted = await Restart.restartApp(
        notificationTitle: 'twonly',
        notificationBody: context.lang.registeringNewAccount,
        forceKill: true,
      );
      if (!restarted) throw StateError('Could not restart twonly');
    } catch (error, stackTrace) {
      Log.error(
        'Could not reset local account data',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) return;
      setState(() => _isResetting = false);
      showSnackbar(
        context,
        'Could not reset twonly. Please try again or restart the app.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              const SizedBox(height: 48),
              Center(
                child: FaIcon(
                  FontAwesomeIcons.triangleExclamation,
                  size: 80,
                  color: context.color.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Critical Error',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Please try restarting twonly. If the error persists, please contact our support and upload your debug log so we can troubleshoot the issue.\n\nYou can restore your account from a backup or delete your local data and register a new account.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              MyButton(
                onPressed: _isResetting
                    ? null
                    : () async {
                        await Restart.restartApp(
                          notificationTitle: 'App restarted',
                          notificationBody: 'Click here to open the app again',
                          forceKill: true,
                        );
                      },
                child: const Text('Try Again'),
              ),
              const SizedBox(height: 12),
              MyButton(
                variant: MyButtonVariant.secondary,
                onPressed: _isResetting
                    ? null
                    : () async {
                        await context.navPush(const BackupRecoveryView());
                      },
                child: const Text('Recovery from backup'),
              ),
              const SizedBox(height: 12),
              MyButton(
                variant: MyButtonVariant.errorMiddle,
                onPressed: _isResetting ? null : _registerNewAccount,
                child: Text(
                  _isResetting
                      ? context.lang.registeringNewAccount
                      : context.lang.registerNewAccount,
                ),
              ),
              const SizedBox(height: 12),
              MyButton(
                variant: MyButtonVariant.text,
                onPressed: _isResetting
                    ? null
                    : () => context.navPush(const ContactUsView()),
                child: const Text('Contact Support'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
