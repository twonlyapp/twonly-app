import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:restart_app/restart_app.dart';
import 'package:twonly/core/bridge/wrapper/key_manager.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/backup.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/storage.dart';

class RecoveryView extends StatefulWidget {
  const RecoveryView({super.key});

  @override
  State<RecoveryView> createState() => _RecoveryViewState();
}

class _RecoveryViewState extends State<RecoveryView> {
  bool _isLoading = false;
  String? _errorMessage;
  bool _showRegisterNewPrompt = false;

  Future<void> _startRestore() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = await BackupService.tryToReinstallTheArchive();
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _isLoading = false;
        _errorMessage = error.toLocalizedString(context);
        _showRegisterNewPrompt = true;
      });
      return;
    }

    final userExists = await userService.tryInit();
    if (userExists && mounted) {
      await Restart.restartApp(
        notificationTitle: context.lang.recoverSuccessTitle,
        notificationBody: context.lang.recoverSuccessBody,
        forceKill: true,
      );
    } else {
      setState(() {
        _isLoading = false;
        _errorMessage = context.lang.recoverErrorUnknown;
        _showRegisterNewPrompt = true;
      });
    }
  }

  Future<void> _registerNewAccount() async {
    try {
      await RustKeyManager.removeKeyManager();
    } catch (e) {
      Log.error('Could not remove KeyManager during account reset: $e');
    }
    await deleteLocalUserData();
    if (!mounted) return;
    await Restart.restartApp(
      notificationTitle: 'twonly',
      notificationBody: context.lang.registeringNewAccount,
      forceKill: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.lang.twonlySafeRecoverTitle),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              const SizedBox(height: 100),
              Center(
                child: FaIcon(
                  FontAwesomeIcons.cloudArrowDown,
                  size: 80,
                  color: context.color.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                context.lang.iosRecoveryWelcomeBack,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                _showRegisterNewPrompt
                    ? context.lang.iosRecoveryNoBackupFound(
                        _errorMessage ?? '',
                      )
                    : context.lang.iosRecoveryPrompt,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 32),
              if (!_showRegisterNewPrompt) ...[
                FilledButton.icon(
                  onPressed: _isLoading ? null : _startRestore,
                  icon: _isLoading
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                        )
                      : const Icon(Icons.restore_rounded),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  label: Text(
                    context.lang.twonlySafeRecoverBtn,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading ? null : _registerNewAccount,
                  child: Text(context.lang.registerNewAccount),
                ),
              ] else ...[
                FilledButton.icon(
                  onPressed: _registerNewAccount,
                  icon: const Icon(Icons.person_add_rounded),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  label: Text(
                    context.lang.registerNewAccount,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _startRestore,
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(context.lang.tryRestoreAgain),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
