import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/views/settings/backup/components/recovery_card.comp.dart';
import 'package:twonly/src/visual/views/settings/backup/passwordless_recovery/components/status.passwordless_recovery.comp.dart';
import 'package:twonly/src/visual/views/settings/backup/passwordless_recovery/setup.passwordless_recovery.view.dart';

/// The two ways to recover the account: trusted friends and a password.
class RecoveryOptionsComp extends StatelessWidget {
  const RecoveryOptionsComp({
    this.onReturn,
    this.showPassword = true,
    super.key,
  });

  /// Called once the user comes back from setting up one of the options.
  final VoidCallback? onReturn;

  /// Whether to offer the password next to the trusted friends.
  final bool showPassword;

  Future<void> _open(Future<void> Function() navigate) async {
    await navigate();
    onReturn?.call();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: userService.onUserUpdated,
      builder: (context, _) {
        final hasPasswordless =
            userService.currentUser.passwordLessRecovery != null;
        final hasPassword = userService.currentUser.isBackupEnabled;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasPasswordless)
              const PasswordLessRecoveryStatus()
            else
              RecoveryCard(
                icon: FontAwesomeIcons.shieldHeart,
                title: context.lang.backupRecoveryOptionAFriends,
                subtitle: context.lang.backupRecoveryOptionAMicrocopy,
                onTap: () => _open(
                  () => context.navPush(const PasswordLessRecoverySetup()),
                ),
              ),
            if (showPassword) ...[
              const SizedBox(height: 12),
              RecoveryCard(
                isEnabled: hasPassword,
                icon: FontAwesomeIcons.key,
                title: context.lang.backupRecoveryOptionBPassword,
                subtitle: hasPassword
                    ? context.lang.backupChangePassword
                    : context.lang.backupRecoveryOptionBMicrocopy,
                onTap: () => _open(
                  () => context.push(Routes.settingsBackupSetup, extra: true),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
