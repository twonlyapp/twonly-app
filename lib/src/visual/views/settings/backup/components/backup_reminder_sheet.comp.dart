import 'package:flutter/material.dart';
import 'package:twonly/core/bridge/database/recovery.dart' as rust_recovery;
import 'package:twonly/core/database/app/recovery/table.dart' as db_recovery;
import 'package:twonly/core/user_config.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/database/session.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/views/settings/backup/components/recovery_options.comp.dart';
import 'package:twonly/src/visual/views/settings/backup/passwordless_recovery/setup.passwordless_recovery.view.dart';

enum BackupReminder {
  /// No recovery option at all: offers both.
  missingBackup,

  /// Only a password: offers trusted friends for a forgotten password.
  /// The user can turn this one off for good.
  passwordlessRecovery;

  static BackupReminder? forUser(UserConfig user) {
    if (user.currentSetupPage != null || user.passwordLessRecovery != null) {
      return null;
    }
    if (!user.isBackupEnabled) return missingBackup;
    if (user.hidePasswordlessRecoveryReminder) return null;
    return passwordlessRecovery;
  }
}

/// Reminds users to set up account recovery, once per app start, as soon as
/// they have enough verified friends for passwordless recovery.
class BackupReminderPresenter {
  BackupReminderPresenter._();

  static const int _minEligibleFriends = 4;

  static bool _handledThisSession = false;

  /// Leaves the reminder for the next app start, e.g. because another sheet
  /// already took this one.
  static void skipThisSession() => _handledThisSession = true;

  static Future<void> showIfNeeded(BuildContext context) async {
    if (_handledThisSession) return;
    final reminder = BackupReminder.forUser(userService.currentUser);
    if (reminder == null) return;
    _handledThisSession = true;

    final eligible = await rust_recovery.recoveryContacts(
      selection: db_recovery.RecoveryContacts.eligible,
      limit: _minEligibleFriends,
      transaction: currentDatabaseSession(),
    );
    if (eligible.length < _minEligibleFriends) return;
    if (!context.mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) {
      return;
    }
    await showBackupReminderSheet(context, reminder);
  }
}

Future<void> showBackupReminderSheet(
  BuildContext context,
  BackupReminder reminder,
) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => FractionallySizedBox(
      heightFactor: 0.7,
      child: BackupReminderSheet(reminder: reminder),
    ),
  );
}

class BackupReminderSheet extends StatelessWidget {
  const BackupReminderSheet({required this.reminder, super.key});

  final BackupReminder reminder;

  void _closeIfDone(BuildContext context) {
    if (!context.mounted) return;
    if (BackupReminder.forUser(userService.currentUser) != reminder) {
      Navigator.pop(context);
    }
  }

  Future<void> _hideForever(BuildContext context) async {
    final hide = await _confirmHide(context);
    if (hide == null || !context.mounted) return;
    if (!hide) {
      await context.navPush(const PasswordLessRecoverySetup());
      if (context.mounted) _closeIfDone(context);
      return;
    }
    await UserService.update((u) => u.hidePasswordlessRecoveryReminder = true);
    if (context.mounted) Navigator.pop(context);
  }

  /// True hides the reminder, false opens the setup, null keeps the sheet.
  Future<bool?> _confirmHide(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: context.color.surface,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.lang.passwordlessRecoveryReminderHideTitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.lang.passwordlessRecoveryReminderHideDesc,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: context.color.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: MyButton(
                      variant: MyButtonVariant.errorMiddle,
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        context.lang.passwordlessRecoveryReminderHide,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MyButton(
                      variant: MyButtonVariant.primaryMiddle,
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        context.lang.passwordlessRecoveryReminderEnable,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMissingBackup = reminder == BackupReminder.missingBackup;
    final accent = isMissingBackup
        ? context.color.error
        : context.color.primary;
    return Material(
      color: context.color.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: context.color.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shield_rounded,
                        size: 32,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isMissingBackup
                        ? context.lang.backupReminderTitle
                        : context.lang.passwordlessRecoveryReminderTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isMissingBackup
                        ? context.lang.backupReminderDesc
                        : context.lang.passwordlessRecoveryReminderDesc,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.color.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 24),
                  RecoveryOptionsComp(
                    showPassword: isMissingBackup,
                    onReturn: () => _closeIfDone(context),
                  ),
                ],
              ),
            ),
            if (!isMissingBackup)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Center(
                  child: MyButton(
                    variant: MyButtonVariant.secondaryMiddle,
                    onPressed: () => _hideForever(context),
                    child: Text(context.lang.passwordlessRecoveryReminderHide),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
