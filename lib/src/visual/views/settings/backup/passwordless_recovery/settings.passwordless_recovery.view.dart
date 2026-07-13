import 'package:flutter/material.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/database/twonly.db.dart';
import 'package:twonly/src/services/passwordless_recovery.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/elements/contact_chip.element.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/elements/my_input.element.dart';
import 'package:twonly/src/visual/views/settings/backup/passwordless_recovery/components/passwordless_recovery_info_sheet.comp.dart';
import 'package:twonly/src/visual/views/settings/backup/passwordless_recovery/setup.passwordless_recovery.view.dart';

class PasswordLessRecoverySettings extends StatelessWidget {
  const PasswordLessRecoverySettings({super.key});

  Future<void> _testPin(
    BuildContext context,
  ) async {
    final pinController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.lang.passwordlessRecoveryTestPinTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                MyInput(
                  controller: pinController,
                  obscureText: true,
                  hintText: context.lang.passwordlessRecoveryTestPinHint,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: MyButton(
                        variant: MyButtonVariant.secondary,
                        onPressed: () => Navigator.pop(context),
                        child: Text(context.lang.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MyButton(
                        onPressed: () =>
                            Navigator.pop(context, pinController.text),
                        child: Text(context.lang.passwordlessRecoveryTest),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == null || result.isEmpty) return;

    if (!context.mounted) return;

    final success = await PasswordlessRecoveryService.testPin(result);

    if (!context.mounted) return;

    if (success) {
      showSnackbar(
        context,
        context.lang.passwordlessRecoveryTestPinCorrect,
        level: SnackbarLevel.success,
      );
    } else {
      showSnackbar(context, context.lang.passwordlessRecoveryTestPinIncorrect);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = userService.currentUser.passwordLessRecovery;

    if (config == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.lang.passwordlessRecovery)),
        body: Center(
          child: Text(context.lang.passwordlessRecoveryNotConfigured),
        ),
      );
    }

    var secondFactorLabel = context.lang.passwordlessRecoverySecondFactorNone;
    var secondFactorIcon = Icons.lock_outline_rounded;
    Widget? actionButton;

    if (config.email != null) {
      secondFactorLabel = context.lang
          .passwordlessRecoverySecondFactorEmailLabel(config.email!);
      secondFactorIcon = Icons.email_outlined;
    } else if (config.pinSeed != null) {
      secondFactorLabel = context.lang.passwordlessRecoverySecondFactorPin;
      secondFactorIcon = Icons.pin_outlined;
      actionButton = MyButton(
        variant: MyButtonVariant.secondaryDense,
        onPressed: () => _testPin(context),
        child: Text(context.lang.passwordlessRecoveryTestPin),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.passwordlessRecovery),
        actions: [
          IconButton(
            onPressed: () => showPasswordlessRecoveryInfoSheet(context),
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MyButton(
            variant: MyButtonVariant.secondary,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const PasswordLessRecoverySetup(),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.manage_accounts_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      context.lang.passwordlessRecoveryModify,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  context.lang.passwordlessRecoveryModifyDesc,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.color.onSurfaceVariant,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildInfoCard(
            context,
            title: context.lang.passwordlessRecoverySecondFactor,
            value: secondFactorLabel,
            icon: secondFactorIcon,
            action: actionButton,
          ),
          const SizedBox(height: 24),
          StreamBuilder<List<Contact>>(
            stream: (twonlyDB.select(
              twonlyDB.contacts,
            )..where((t) => t.recoveryIsTrustedFriend.equals(true))).watch(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator.adaptive(),
                );
              }

              final friends = snapshot.data!;
              if (friends.isEmpty) {
                return Text(context.lang.passwordlessRecoveryNoFriendsFound);
              }

              final activeFriends = friends.where((c) {
                final lastHeartbeat = c.recoveryLastHeartbeat;
                if (lastHeartbeat == null) return false;
                return DateTime.now().difference(lastHeartbeat).inDays <= 14;
              }).toList();

              final inactiveFriends = friends.where((c) {
                final lastHeartbeat = c.recoveryLastHeartbeat;
                if (lastHeartbeat == null) return true;
                return DateTime.now().difference(lastHeartbeat).inDays > 14;
              }).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (activeFriends.isNotEmpty) ...[
                    Text(
                      context.lang.passwordlessRecoveryActiveFriends,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.lang.passwordlessRecoveryActiveFriendsDesc,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.color.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFriendsGridCard(
                      context,
                      friends: activeFriends,
                      isActive: true,
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (inactiveFriends.isNotEmpty) ...[
                    Text(
                      context.lang.passwordlessRecoveryInactiveFriends,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.lang.passwordlessRecoveryInactiveFriendsDesc,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.color.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFriendsGridCard(
                      context,
                      friends: inactiveFriends,
                      isActive: false,
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    Widget? action,
  }) {
    return Card(
      elevation: 0,
      color: context.color.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: context.color.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.color.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            ?action,
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsGridCard(
    BuildContext context, {
    required List<Contact> friends,
    required bool isActive,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: friends.map((contact) {
          return Opacity(
            opacity: isActive ? 1.0 : 0.5,
            child: ContactChip(
              contact: contact,
            ),
          );
        }).toList(),
      ),
    );
  }
}
