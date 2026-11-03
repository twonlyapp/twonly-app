// ignore_for_file: avoid_dynamic_calls

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:twonly/core/bridge/user_config.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/services/notifications/fcm.notifications.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/utils/pow.dart';
import 'package:twonly/src/visual/components/alert.dialog.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/elements/my_input.element.dart';
import 'package:twonly/src/visual/release_notes/release_notes_0_6_0.dart';
import 'package:twonly/src/visual/views/groups/group.view.dart';
import 'package:twonly/src/visual/views/onboarding/components/onboarding_brand.comp.dart';
import 'package:twonly/src/visual/views/onboarding/setup.view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({
    required this.callbackOnSuccess,
    required this.proofOfWork,
    super.key,
  });

  final Function callbackOnSuccess;
  final (Future<int>?, bool) proofOfWork;
  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final TextEditingController usernameController = TextEditingController();

  bool _registrationDisabled = false;
  bool _isTryingToRegister = false;
  bool _isValidUserName = false;

  bool _showProofOfWorkError = false;
  String? _usernameErrorText;

  late Future<int>? proofOfWork;

  @override
  void initState() {
    super.initState();
    proofOfWork = widget.proofOfWork.$1;
    _registrationDisabled = widget.proofOfWork.$2;
  }

  Future<void> createNewUser({bool retryInvalidProofOfWork = true}) async {
    if (!_isValidUserName) {
      setState(() {
        _usernameErrorText = context.lang.registerUsernameLimits;
      });
      return;
    }
    final username = usernameController.text;

    setState(() {
      _isTryingToRegister = true;
      _usernameErrorText = null;
      _showProofOfWorkError = false;
    });

    try {
      late int proof;

      if (proofOfWork != null) {
        proof = await proofOfWork!;
      } else {
        final proofResult = await rustApiResult(RustApi.getProofOfWork());
        final pow = proofResult.value;
        final registrationDisabled =
            proofResult.error == ErrorCode.RegistrationDisabled;
        if (pow == null) {
          setState(() {
            _registrationDisabled = registrationDisabled;
            _isTryingToRegister = false;
          });
          if (mounted && !registrationDisabled) {
            showNetworkIssue(context);
          }
          return;
        }
        proof = await calculatePoW(pow.prefix, pow.difficulty);
      }

      Log.info('The result of the POW is $proof');

      var userId = 0;

      final res = await rustApiResult(
        RustApi.register(
          username: username,
          proofOfWork: proof,
          langCode: ui.PlatformDispatcher.instance.locale.languageCode,
          isIos: Platform.isIOS,
        ),
      );
      if (res.isSuccess) {
        Log.info('Got user_id ${res.value} from server');
        userId = res.value!;
      } else {
        proofOfWork = null;
        if (res.error == ErrorCode.RegistrationDisabled) {
          setState(() {
            _registrationDisabled = true;
            _isTryingToRegister = false;
          });
          return;
        }
        if (res.error == ErrorCode.UserIdAlreadyTaken) {
          Log.error('User ID already token. Tying again.');
          return await createNewUser();
        }
        if (res.error == ErrorCode.UsernameAlreadyTaken ||
            res.error == ErrorCode.UsernameNotValid) {
          setState(() {
            _usernameErrorText = errorCodeToText(
              context,
              res.error!,
            );
            _isTryingToRegister = false;
          });
          return;
        }
        if (res.error == ErrorCode.InvalidProofOfWork) {
          // The challenge is bound to the server connection, so a reconnect
          // invalidates it. Only a new one is needed; deleting local data
          // here would unlink the databases Rust still has open and fail
          // the retry with SQLite code 1032 (read-only, database moved).
          if (retryInvalidProofOfWork) {
            Log.warn(
              'Proof of work was invalid. Requesting a new challenge and '
              'retrying registration.',
            );
            return await createNewUser(retryInvalidProofOfWork: false);
          }
          setState(() {
            _showProofOfWorkError = true;
            _isTryingToRegister = false;
          });
          return;
        }
        if (mounted) {
          setState(() {
            _isTryingToRegister = false;
          });
          final cause = res.cause;
          if (cause != null && isConnectionError(cause)) {
            showNetworkIssue(context);
          } else {
            // A failure inside the app is not the server being down; show
            // what failed so it can be reported.
            await showAlertDialog(
              context,
              'Oh no!',
              cause?.toString() ?? errorCodeToText(context, res.error!),
            );
          }
        }
        return;
      }

      setState(() {
        _isTryingToRegister = false;
      });

      final userData = await UserConfigApi.create(
        userId: userId,
        username: username,
        displayName: username,
        currentSetupPage: SetupPages.profile.name,
        appVersion: AppState.latestAppVersionId,
      );
      // These features are already part of the version this account starts on.
      userData.lastReleaseNotesVersion = releaseNotes060Version;

      await UserService.save(userData);

      unawaited(FcmNotificationService.initAfterUserLoaded());

      await RustApi.reloadConfiguration();
      widget.callbackOnSuccess();
    } catch (e, stack) {
      Log.error('Error creating new user', error: e, stackTrace: stack);
      if (mounted) {
        setState(() {
          _isTryingToRegister = false;
        });
        await showAlertDialog(
          context,
          'Error',
          e.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mutedStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: context.color.onSurfaceVariant,
    );

    return PopScope(
      canPop: !_isTryingToRegister,
      child: GestureDetector(
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
                              Align(
                                alignment: AlignmentDirectional.centerStart,
                                child: IconButton(
                                  // Lines the arrow up with the text below.
                                  padding: EdgeInsets.zero,
                                  alignment: AlignmentDirectional.centerStart,
                                  icon: const BackButtonIcon(),
                                  tooltip: MaterialLocalizations.of(
                                    context,
                                  ).backButtonTooltip,
                                  onPressed: _isTryingToRegister
                                      ? null
                                      : () => Navigator.of(context).pop(),
                                ),
                              ),
                              const Spacer(),
                              const SizedBox(height: 24),
                              const OnboardingHeadline(fontSize: 36),
                              const SizedBox(height: 40),
                              if (_registrationDisabled)
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: context.color.errorContainer,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.hourglass_top_rounded,
                                        color: context.color.onErrorContainer,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          context.lang.registrationClosed,
                                          style: TextStyle(
                                            fontSize: 15,
                                            height: 1.4,
                                            color:
                                                context.color.onErrorContainer,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else ...[
                                Text(
                                  context.lang.registerUsernameSlogan,
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: context.color.onSurface,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                MyInput(
                                  controller: usernameController,
                                  errorText: _usernameErrorText,
                                  onChanged: (value) {
                                    usernameController.text = value
                                        .toLowerCase();
                                    usernameController
                                        .selection = TextSelection.fromPosition(
                                      TextPosition(
                                        offset: usernameController.text.length,
                                      ),
                                    );
                                    setState(() {
                                      _isValidUserName =
                                          usernameController.text.length >= 3;
                                      _usernameErrorText = null;
                                    });
                                  },
                                  onSubmitted: (_) {
                                    if (!_isTryingToRegister) createNewUser();
                                  },
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(12),
                                    FilteringTextInputFormatter.allow(
                                      RegExp('[a-z0-9A-Z._]'),
                                    ),
                                  ],
                                  hintText:
                                      context.lang.registerUsernameDecoration,
                                  prefixIcon: const Icon(
                                    Icons.alternate_email,
                                  ),
                                ),
                                if (_usernameErrorText == null) ...[
                                  const SizedBox(height: 10),
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      start: 4,
                                    ),
                                    child: Text(
                                      context.lang.registerUsernameLimits,
                                      style: mutedStyle,
                                    ),
                                  ),
                                ],
                                if (_showProofOfWorkError) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    context.lang.registerProofOfWorkFailed,
                                    style: mutedStyle.copyWith(
                                      color: context.color.error,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 28),
                                MyButton(
                                  onPressed: _isTryingToRegister
                                      ? null
                                      : createNewUser,
                                  child: _isTryingToRegister
                                      ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child:
                                              CircularProgressIndicator.adaptive(
                                                valueColor:
                                                    AlwaysStoppedAnimation(
                                                      context.color.onPrimary,
                                                    ),
                                                strokeWidth: 3,
                                              ),
                                        )
                                      : Text(
                                          context.lang.registerSubmitButton,
                                        ),
                                ),
                              ],
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
      ),
    );
  }
}
