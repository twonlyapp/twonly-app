import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:restart_app/restart_app.dart';
import 'package:twonly/src/constants/keyvalue.keys.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/model/json/onboarding_state.model.dart';
import 'package:twonly/src/services/backup.service.dart';
import 'package:twonly/src/utils/keyvalue.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/components/snackbar.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/elements/my_input.element.dart';
import 'package:twonly/src/visual/views/onboarding/components/link_logo_animation.dart';
import 'package:twonly/src/visual/views/settings/backup/components/backup_setup.comp.dart';

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
      setState(() {
        isLoading = false;
      });
      return showSnackbar(context, error.toLocalizedString(context));
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
    final titleColor = isDark ? Colors.white : Colors.black87;
    final iconColor = isDark ? Colors.white70 : Colors.black54;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                              ),
                              color: iconColor,
                              iconSize: 20,
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => showBackupExplanation(context),
                              icon: const FaIcon(FontAwesomeIcons.circleInfo),
                              color: iconColor,
                              iconSize: 20,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: LinkLogoAnimation(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            context.lang.twonlySafeRecoverTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: titleColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),
                        MyInput(
                          controller: usernameCtrl,
                          onChanged: (value) => setState(() {}),
                          hintText: context.lang.registerUsernameDecoration,
                          prefixIcon: const Icon(Icons.alternate_email),
                        ),
                        const SizedBox(height: 16),
                        MyInput(
                          controller: passwordCtrl,
                          onChanged: (value) => setState(() {}),
                          obscureText: obscureText,
                          hintText: context.lang.password,
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
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
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        MyButton(
                          onPressed: (!isLoading) ? _recoverTwonlySafe : null,
                          child: isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator.adaptive(
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                    strokeWidth: 3,
                                  ),
                                )
                              : Text(context.lang.twonlySafeRecoverBtn),
                        ),
                        const SizedBox(height: 16),
                        MyButton(
                          variant: MyButtonVariant.secondary,
                          onPressed: () async {
                            await KeyValueStore.update<OnboardingState>(
                              key: KeyValueKeys.onboardingState,
                              update: (state) =>
                                  state.hasStartedPasswordlessRecovery = true,
                            );
                            if (context.mounted) {
                              await context.push(Routes.recoverPasswordless);
                            }
                          },
                          child: Text(
                            context.lang.passwordlessRecoveryRecoverBtn,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
