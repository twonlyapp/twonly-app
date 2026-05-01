import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:restart_app/restart_app.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/onboarding/recover.view.dart';
import 'package:twonly/src/visual/views/settings/help/contact_us.view.dart';

class CriticalErrorView extends StatelessWidget {
  const CriticalErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(
                FontAwesomeIcons.triangleExclamation,
                size: 80,
                color: Colors.redAccent,
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
                'Please try restarting twonly. If the error persists, please contact our support and upload your debug log so we can troubleshoot the issue.\n\nYou can restore your account using the button below. If you have forgotten your password, you will need to reinstall twonly and then register with a new account.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: () async {
                  await Restart.restartApp(
                    notificationTitle: 'App restarted',
                    notificationBody: 'Click here to open the app again',
                    forceKill: true,
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await context.navPush(const BackupRecoveryView());
                },
                icon: const Icon(Icons.backup_rounded),
                label: const Text('Recovery from backup'),
              ),
              TextButton(
                onPressed: () => context.navPush(const ContactUsView()),
                child: const Text('Contact Support'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
