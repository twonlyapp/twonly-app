import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:twonly/src/constants/keyvalue.keys.dart';
import 'package:twonly/src/constants/routes.keys.dart';
import 'package:twonly/src/model/json/onboarding_state.model.dart';
import 'package:twonly/src/services/backup.service.dart';
import 'package:twonly/src/utils/keyvalue.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/elements/my_input.element.dart';
import 'package:twonly/src/visual/views/onboarding/components/onboarding_brand.comp.dart';
import 'package:twonly/src/visual/views/onboarding/recovery_progress.view.dart';
import 'package:twonly/src/visual/views/settings/backup/components/backup_setup.comp.dart';

class BackupRecoveryView extends StatefulWidget {
  const BackupRecoveryView({super.key});

  @override
  State<BackupRecoveryView> createState() => _BackupRecoveryViewState();
}

class _BackupRecoveryViewState extends State<BackupRecoveryView> {
  bool obscureText = true;
  final TextEditingController usernameCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();

  @override
  void dispose() {
    usernameCtrl.dispose();
    passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _recoverTwonlySafe() async {
    final username = usernameCtrl.text;
    final password = passwordCtrl.text;

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RecoveryProgressView(
          username: username,
          steps: const [
            RecoveryProgress.resolvingAccount,
            RecoveryProgress.restoringIdentity,
            RecoveryProgress.downloadingArchive,
            RecoveryProgress.extractingData,
          ],
          runRecovery: (onProgress) => BackupService.startFullBackupRecovery(
            username,
            password,
            onProgress: onProgress,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = context.color.onSurfaceVariant;

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            const OnboardingBackgroundGlow(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                IconButton(
                                  // Lines the arrow up with the text below.
                                  padding: EdgeInsets.zero,
                                  alignment: AlignmentDirectional.centerStart,
                                  icon: const BackButtonIcon(),
                                  tooltip: MaterialLocalizations.of(
                                    context,
                                  ).backButtonTooltip,
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                const Spacer(),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  alignment: AlignmentDirectional.centerEnd,
                                  onPressed: () =>
                                      showBackupExplanation(context),
                                  icon: const Icon(Icons.info_outline_rounded),
                                  color: iconColor,
                                ),
                              ],
                            ),
                            const Spacer(),
                            const SizedBox(height: 24),
                            Text(
                              context.lang.twonlySafeRecoverTitle,
                              style: TextStyle(
                                fontSize: 32,
                                height: 1.15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                                color: context.color.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              context.lang.twonlySafeRecoverDesc,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.45,
                                color: iconColor,
                              ),
                            ),
                            const SizedBox(height: 32),
                            MyInput(
                              controller: usernameCtrl,
                              onChanged: (value) => setState(() {}),
                              hintText: context.lang.registerUsernameDecoration,
                              prefixIcon: const Icon(Icons.alternate_email),
                            ),
                            const SizedBox(height: 14),
                            MyInput(
                              controller: passwordCtrl,
                              onChanged: (value) => setState(() {}),
                              onSubmitted: (_) => _recoverTwonlySafe(),
                              obscureText: obscureText,
                              hintText: context.lang.password,
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
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
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            MyButton(
                              onPressed: _recoverTwonlySafe,
                              child: Text(context.lang.twonlySafeRecoverBtn),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                const Expanded(child: Divider()),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  child: Text(
                                    context.lang.twonlySafeRecoverOr,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: iconColor,
                                    ),
                                  ),
                                ),
                                const Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 24),
                            MyButton(
                              variant: MyButtonVariant.secondary,
                              onPressed: () async {
                                await KeyValueStore.update<OnboardingState>(
                                  key: KeyValueKeys.onboardingState,
                                  update: (state) =>
                                      state.hasStartedPasswordlessRecovery =
                                          true,
                                );
                                if (context.mounted) {
                                  await context.push(
                                    Routes.recoverPasswordless,
                                  );
                                }
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.group_outlined, size: 22),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      context
                                          .lang
                                          .passwordlessRecoveryRecoverBtn,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(flex: 3),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
