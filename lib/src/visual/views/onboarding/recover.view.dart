import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:restart_app/restart_app.dart';
import 'package:twonly/src/services/backup.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/themes/light.dart';
import 'package:twonly/src/visual/views/onboarding/components/link_logo_animation.dart';
import 'package:twonly/src/visual/views/onboarding/components/onboarding_wrapper.dart';

class BackupRecoveryView extends StatefulWidget {
  const BackupRecoveryView({super.key});

  @override
  State<BackupRecoveryView> createState() => _BackupRecoveryViewState();
}

class _BackupRecoveryViewState extends State<BackupRecoveryView> {
  bool obscureText = true;
  bool isLoading = false;
  final TextEditingController usernameCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();

  Future<void> _recoverTwonlySafe() async {
    setState(() {
      isLoading = true;
    });

    final error = await BackupService.startFullBackupRecovery(
      usernameCtrl.text,
      passwordCtrl.text,
    );
    if (!mounted) return;

    if (error != null) {
      String errorMessage;
      switch (error) {
        case RecoveryError.noInternet:
          errorMessage = context.lang.recoverErrorNoInternet;
        case RecoveryError.usernameNotValid:
          errorMessage = context.lang.recoverErrorUsernameNotValid;
        case RecoveryError.passwordInvalid:
          errorMessage = context.lang.recoverErrorPasswordInvalid;
        case RecoveryError.tryAgainLater:
          errorMessage = context.lang.recoverErrorTryAgainLater;
        case RecoveryError.unkownError:
          errorMessage = context.lang.recoverErrorUnknown;
      }
      setState(() {
        isLoading = false;
      });
      return showSnackbar(context, errorMessage);
    }

    await Restart.restartApp(
      notificationTitle: context.lang.recoverSuccessTitle,
      notificationBody: context.lang.recoverSuccessBody,
      forceKill: true,
    );

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode(context);
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final inputColor = isDark ? const Color(0xFF0F172A) : Colors.grey[100];

    return OnboardingWrapper(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
              ),
              color: Colors.white,
              iconSize: 20,
            ),
            const Spacer(),
            IconButton(
              onPressed: () async {
                await showAlertDialog(
                  context,
                  'twonly Backup',
                  context.lang.backupTwonlySafeLongDesc,
                );
              },
              icon: const FaIcon(FontAwesomeIcons.circleInfo),
              color: Colors.white,
              iconSize: 20,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: LinkLogoAnimation(),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            context.lang.twonlySafeRecoverTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 48),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: usernameCtrl,
                onChanged: (value) => setState(() {}),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: context.lang.registerUsernameDecoration,
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                  filled: true,
                  fillColor: inputColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(
                    Icons.alternate_email,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordCtrl,
                onChanged: (value) => setState(() {}),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                ),
                obscureText: obscureText,
                decoration: InputDecoration(
                  hintText: context.lang.password,
                  hintStyle: TextStyle(
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                  filled: true,
                  fillColor: inputColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  prefixIcon: Icon(
                    Icons.lock_outline_rounded,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        obscureText = !obscureText;
                      });
                    },
                    icon: FaIcon(
                      obscureText
                          ? FontAwesomeIcons.eye
                          : FontAwesomeIcons.eyeSlash,
                      size: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: (!isLoading) ? _recoverTwonlySafe : null,
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Text(
                        context.lang.twonlySafeRecoverBtn,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
        const Spacer(),
        const SizedBox(height: 40),
      ],
    );
  }
}
